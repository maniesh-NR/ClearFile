// SPDX-License-Identifier: GPL-3.0-only
/**
 * Experimental .tax file support — honest best-effort, clearly labeled.
 *
 * Reality (documented in the blueprint): Intuit's TurboTax ".tax" container
 * is undocumented. Without Intuit's format specification or an authorized
 * reverse-engineering workstream, no exporter can claim real .tax
 * compatibility. What this module does instead:
 *
 *  1. analyzeTaxFile(buf): inspects any ".tax" file the user already has.
 *     - Detects ZIP containers (PK\x03\x04) — the most common wrapper family
 *       for modern desktop tax files — and lists/extracts stored entries.
 *     - Recognizes ClearFile's own exchange container and imports it fully.
 *     - Reports an honest "unrecognized container" for anything else.
 *  2. exportTaxContainer(filing): writes a ZIP container using the .tax
 *     extension containing openreturn.json + README.txt. It is NOT the
 *     Intuit format — the README inside says so explicitly — it exists so
 *     users can keep one ".tax" file per year and re-import here.
 *
 * ZIP support is a minimal, dependency-free implementation: STORE method
 * only (no compression) for writing; STORE + Deflate detection for reading.
 */

import type { TaxReturnData } from '../tax/engine'
import { serializeCfr, parseCfr, CfrParseError } from './cfr'

export interface ZipEntry {
  name: string
  data: Uint8Array
}

export interface ZipEntryMeta {
  name: string
  /** ZIP compression method (0 stored / 8 deflate / other). */
  method: number
  /** Uncompressed size from the central directory. */
  uncompressedSize: number
  /** Extracted data — present only for STORE-method entries. */
  data: Uint8Array | null
}

export interface TaxAnalysis {
  isZip: boolean
  clearfileContainer: boolean
  /** True when the entries match the modern Intuit container shape
   * (`manifest.xml` + a `tax:<uuid>` data entry — public write-up, RE
   * protocol §5). Nothing is decrypted; the summary says so. */
  intuitModernContainer: boolean
  filing?: TaxReturnData
  warnings: string[]
  entries: {
    name: string
    size: number
    method?: number
    /** Shannon entropy in bits/byte over stored data (stored entries
     * with ≥128 bytes only). */
    entropy?: number
    /** Entropy ≥ 7.5 — the signature of encrypted/compressed content. */
    likelyEncrypted?: boolean
    preview?: string
  }[]
  summary: string
}

/* ---------------- CRC32 ---------------- */

const CRC_TABLE = (() => {
  const table = new Uint32Array(256)
  for (let i = 0; i < 256; i++) {
    let c = i
    for (let k = 0; k < 8; k++) {
      c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1
    }
    table[i] = c >>> 0
  }
  return table
})()

function crc32(buf: Uint8Array): number {
  let c = 0xffffffff
  for (let i = 0; i < buf.length; i++) {
    c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8)
  }
  return (c ^ 0xffffffff) >>> 0
}

/* ---------------- ZIP writer (STORE only) ---------------- */

const enc = new TextEncoder()
const dec = new TextDecoder()

function dosDateTime(): { time: number; date: number } {
  const d = new Date()
  const time = ((d.getHours() & 0x1f) << 11) | ((d.getMinutes() & 0x3f) << 5) | ((d.getSeconds() / 2) & 0x1f)
  const date = (((d.getFullYear() - 1980) & 0x7f) << 9) | (((d.getMonth() + 1) & 0xf) << 5) | (d.getDate() & 0x1f)
  return { time, date }
}

export function makeZip(entries: ZipEntry[]): Uint8Array {
  const { time, date } = dosDateTime()
  const locals: Uint8Array[] = []
  const centrals: Uint8Array[] = []
  let offset = 0

  for (const entry of entries) {
    const nameBytes = enc.encode(entry.name)
    const crc = crc32(entry.data)
    const size = entry.data.length

    const local = new Uint8Array(30 + nameBytes.length + size)
    const lv = new DataView(local.buffer)
    lv.setUint32(0, 0x04034b50, true) // local file header signature
    lv.setUint16(4, 20, true) // version needed
    lv.setUint16(6, 0x0800, true) // flags: UTF-8 names
    lv.setUint16(8, 0, true) // method: store
    lv.setUint16(10, time, true)
    lv.setUint16(12, date, true)
    lv.setUint32(14, crc, true)
    lv.setUint32(18, size, true) // compressed size
    lv.setUint32(22, size, true) // uncompressed size
    lv.setUint16(26, nameBytes.length, true)
    lv.setUint16(28, 0, true) // extra length
    local.set(nameBytes, 30)
    local.set(entry.data, 30 + nameBytes.length)
    locals.push(local)

    const central = new Uint8Array(46 + nameBytes.length)
    const cv = new DataView(central.buffer)
    cv.setUint32(0, 0x02014b50, true) // central directory signature
    cv.setUint16(4, 20, true) // version made by
    cv.setUint16(6, 20, true) // version needed
    cv.setUint16(8, 0x0800, true) // flags
    cv.setUint16(10, 0, true) // method
    cv.setUint16(12, time, true)
    cv.setUint16(14, date, true)
    cv.setUint32(16, crc, true)
    cv.setUint32(20, size, true)
    cv.setUint32(24, size, true)
    cv.setUint16(28, nameBytes.length, true)
    cv.setUint16(30, 0, true) // extra
    cv.setUint16(32, 0, true) // comment
    cv.setUint16(34, 0, true) // disk number
    cv.setUint16(36, 0, true) // internal attrs
    cv.setUint32(38, 0, true) // external attrs
    cv.setUint32(42, offset, true) // local header offset
    central.set(nameBytes, 46)
    centrals.push(central)

    offset += local.length
  }

  const centralSize = centrals.reduce((s, c) => s + c.length, 0)
  const end = new Uint8Array(22)
  const ev = new DataView(end.buffer)
  ev.setUint32(0, 0x06054b50, true) // EOCD signature
  ev.setUint16(4, 0, true)
  ev.setUint16(6, 0, true)
  ev.setUint16(8, entries.length, true)
  ev.setUint16(10, entries.length, true)
  ev.setUint32(12, centralSize, true)
  ev.setUint32(16, offset, true)
  ev.setUint16(20, 0, true)

  const total = offset + centralSize + end.length
  const out = new Uint8Array(total)
  let pos = 0
  for (const l of locals) {
    out.set(l, pos)
    pos += l.length
  }
  for (const c of centrals) {
    out.set(c, pos)
    pos += c.length
  }
  out.set(end, pos)
  return out
}

/* ---------------- ZIP reader (central-directory scan) ---------------- */

export function readZip(buf: Uint8Array): {
  entries: ZipEntryMeta[]
  notes: string[]
} {
  const notes: string[] = []
  const entries: ZipEntryMeta[] = []
  const view = new DataView(buf.buffer, buf.byteOffset, buf.byteLength)

  // Locate End of Central Directory from the tail (bounded to the last
  // 64 KiB — the spec's maximum comment length — with a whole-buffer
  // fallback for tiny malformed inputs).
  let eocd = -1
  const scanFrom = buf.length >= 66000 ? buf.length - 66000 : 0
  for (let i = buf.length - 22; i >= scanFrom; i--) {
    if (view.getUint32(i, true) === 0x06054b50) {
      eocd = i
      break
    }
  }
  if (eocd === -1) {
    notes.push('No ZIP end-of-central-directory record found.')
    return { entries, notes }
  }

  const count = view.getUint16(eocd + 10, true)
  const maxEntries = 4096 // parser-hardening cap (untrusted input)
  let ptr = view.getUint32(eocd + 16, true)

  for (let n = 0; n < count && entries.length < maxEntries; n++) {
    if (ptr + 46 > buf.length || view.getUint32(ptr, true) !== 0x02014b50) {
      notes.push('Central directory truncated or corrupt; stopped early.')
      break
    }
    const method = view.getUint16(ptr + 10, true)
    const compSize = view.getUint32(ptr + 20, true)
    const uncompSize = view.getUint32(ptr + 24, true)
    const nameLen = view.getUint16(ptr + 28, true)
    const extraLen = view.getUint16(ptr + 30, true)
    const commentLen = view.getUint16(ptr + 32, true)
    const localOffset = view.getUint32(ptr + 42, true)
    const name = dec.decode(buf.slice(ptr + 46, ptr + 46 + nameLen))

    let data: Uint8Array | null = null
    if (method === 0 && localOffset + 30 <= buf.length) {
      const lNameLen = view.getUint16(localOffset + 26, true)
      const lExtraLen = view.getUint16(localOffset + 28, true)
      const dataStart = localOffset + 30 + lNameLen + lExtraLen
      const dataEnd = dataStart + compSize
      if (dataEnd <= buf.length) {
        data = buf.slice(dataStart, dataEnd)
      } else {
        notes.push(`Entry "${name}" extends past end of file; skipped.`)
      }
    } else if (method === 8) {
      notes.push(
        `Entry "${name}" is deflate-compressed; not extracted (shown only).`,
      )
    } else if (method !== 0) {
      notes.push(
        `Entry "${name}" uses unsupported compression method ${method}; skipped.`,
      )
    }

    entries.push({ name, method, uncompressedSize: uncompSize, data })
    ptr += 46 + nameLen + extraLen + commentLen
  }

  return { entries, notes }
}

/* ---------------- entropy (RE protocol Phase 1) ------------------------ */

export function shannonEntropy(data: Uint8Array): number {
  if (data.length === 0) return 0
  const counts = new Uint32Array(256)
  for (let i = 0; i < data.length; i++) counts[data[i]]++
  let h = 0
  for (let i = 0; i < 256; i++) {
    if (counts[i] === 0) continue
    const p = counts[i] / data.length
    h -= p * Math.log2(p)
  }
  return h
}

/* ---------------- .tax analysis & container ---------------- */

function isZip(buf: Uint8Array): boolean {
  return buf.length > 4 && buf[0] === 0x50 && buf[1] === 0x4b && (buf[2] === 0x03 || buf[2] === 0x05 || buf[2] === 0x07)
}

function looksTextual(name: string): boolean {
  return /\.(json|txt|xml|csv|md)$/i.test(name)
}

/** Entropy threshold (bits/byte) for flagging encrypted/compressed content. */
const LIKELY_ENCRYPTED_ENTROPY = 7.5
const ENTROPY_MIN_BYTES = 128

export function analyzeTaxFile(buf: Uint8Array): TaxAnalysis {
  const warnings: string[] = []

  if (!isZip(buf)) {
    const entropy = shannonEntropy(buf)
    return {
      isZip: false,
      clearfileContainer: false,
      intuitModernContainer: false,
      warnings,
      entries: [],
      summary:
        buf.length === 0
          ? 'The file is empty.'
          : `Unrecognized container (no ZIP signature). Whole-file entropy is ${entropy.toFixed(2)} bits/byte (${entropy >= LIKELY_ENCRYPTED_ENTROPY ? 'encrypted/compressed-looking' : 'not high-entropy'}) — either a legacy binary tax format or an unknown container. The proprietary TurboTax .tax format is undocumented; ClearFile imports TurboTax data through the documented TXF export and printed PDFs (the safe bridges; see the reverse-engineering protocol).`,
    }
  }

  const { entries: dir, notes } = readZip(buf)
  const listed = dir.map((e) => {
    const item: TaxAnalysis['entries'][number] = {
      name: e.name,
      size: e.data ? e.data.length : e.uncompressedSize,
      method: e.method,
    }
    if (e.data && e.data.length >= ENTROPY_MIN_BYTES) {
      const entropy = shannonEntropy(e.data)
      item.entropy = entropy
      item.likelyEncrypted = entropy >= LIKELY_ENCRYPTED_ENTROPY
    }
    if (e.data && looksTextual(e.name) && e.data.length < 200_000) {
      item.preview = dec.decode(e.data.slice(0, 300))
    }
    return item
  })

  const clearfileEntry = dir.find((e) => e.name === 'clearfile.json' && e.data)
  if (clearfileEntry && clearfileEntry.data) {
    try {
      const { filing } = parseCfr(dec.decode(clearfileEntry.data))
      return {
        isZip: true,
        clearfileContainer: true,
        intuitModernContainer: false,
        filing,
        warnings: notes,
        entries: listed,
        summary:
          'This is a ClearFile exchange container (.tax extension, open ZIP format). The full return can be imported.',
      }
    } catch (err) {
      warnings.push(
        `clearfile.json could not be parsed: ${err instanceof CfrParseError ? err.message : String(err)}`,
      )
    }
  }

  // Modern Intuit container shape: manifest.xml + a tax:<uuid> data entry
  // (public write-up, RE protocol §5). Report the shape; decrypt nothing
  // (protocol §2.2/§7 — no keys, no ready-made decryptors).
  const hasManifest = dir.some((e) => e.name === 'manifest.xml')
  const hasTaxData = dir.some((e) => e.name.startsWith('tax:'))
  if (hasManifest && hasTaxData) {
    return {
      isZip: true,
      clearfileContainer: false,
      intuitModernContainer: true,
      warnings: notes,
      entries: listed,
      summary:
        'This matches the modern TurboTax .tax container shape (ZIP with a manifest.xml plus a tax:<uuid> data entry). The entries are AES-encrypted with per-year key/IV constants embedded in the TurboTax binary (public write-up; RE protocol §5). ClearFile does not decrypt Intuit files and ships no key material (protocol §2.2/§7) — import this return via TurboTax\'s own TXF export or the printed PDF, both of which are the documented safe bridges.',
    }
  }

  const deflateCount = buf.length && notes.filter((n) => n.includes('deflate-compressed')).length
  return {
    isZip: true,
    clearfileContainer: false,
    intuitModernContainer: false,
    warnings: notes,
    entries: listed,
    summary: deflateCount
      ? 'ZIP container detected. Some entries are compressed and could not be extracted in-browser; stored entries are listed below. No ClearFile return payload was found, so nothing can be imported.'
      : 'ZIP container detected with the entries listed below. No ClearFile return payload was found, so nothing can be imported automatically.',
  }
}

export const TAX_CONTAINER_README = `ClearFile exchange container
================================

This file uses the .tax extension but it is NOT Intuit's proprietary
TurboTax .tax format. It is an open ZIP container written by the ClearFile
prototype containing:

  - clearfile.json  ClearFile Return (open JSON schema, documented)

Why: Intuit's .tax internals are undocumented; writing a genuinely
compatible file requires a separately-scoped reverse-engineering effort
(see the engineering blueprint). This container keeps one ".tax" file per
year for your own records and can be re-imported here at any time.

Generated by ClearFile prototype 0.1 — demo software, not for filing.
`

export function exportTaxContainer(filing: TaxReturnData): Uint8Array {
  return makeZip([
    { name: 'clearfile.json', data: new TextEncoder().encode(serializeCfr(filing)) },
    { name: 'README.txt', data: new TextEncoder().encode(TAX_CONTAINER_README) },
  ])
}

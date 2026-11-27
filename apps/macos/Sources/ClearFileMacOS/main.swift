// SPDX-License-Identifier: GPL-3.0-only
// The ClearFile macOS native UI (N5, the ADR-017 epilogue): a Swift +
// AppKit viewer demo consuming the COMMITTED core-ffi/clearfile.h
// through the ClearFileFFI wrapper target (the wrapper umbrella header
// — the symlink shape was rejected at the N5 gate: both sandbox probe
// findings recorded). ZERO external dependencies — the platform
// frameworks only (AppKit + Foundation, both under the GPLv3 §1
// system-library carve-out, both dynamic from the OS).
//
// The shape mirrors the Windows app (N4) exactly: the argv modes
// (--headless <path> / a bare path / no argument), the ONE shared
// pipeline (read -> the 512 MiB pre-read bound -> the composed
// clearfile_load_and_compute -> the text summary), the SAME text family
// (the byte-parity headless output the CI smoke diffs against the
// Linux app's committed expected text — one canonical expected text,
// three platforms), the MD3-from-seed theme via the palette FFI (the
// same corpus seed), and the full honesty set (the three-fact demo
// disclaimer, the IRS/Intuit non-affiliation line, the prototype
// labels, the no-AI/no-network note — no network code exists anywhere
// in the app or the core; the otool -L direct-linkage guard is the
// mechanical proof).
//
// ZERO engine logic (the ADR-017 core boundary): every number flows
// from the Rust core through the flat C ABI; the JSON reading below is
// display glue over the boundary's own payload (Foundation's
// JSONSerialization — a system framework), nothing more.

import AppKit
import ClearFileFFI
import Foundation

// ---------------------------------------------------------------------------
// The consumption discipline (the N5 gate's ledger): every owned char*
// is copied into a Swift String and freed ONLY by clearfile_free (defer
// at the tightest scope); the borrowed thread-local
// clearfile_last_error() is copied out immediately (valid only until
// the next call on this thread); the app is single-threaded (the
// headless path never touches AppKit; the window mode runs the main
// thread only).
// ---------------------------------------------------------------------------

/// The borrowed last error, copied out of the thread-local ("" when
/// the last call succeeded — the header's documented contract).
func lastErrorText() -> String {
    guard let borrowed = clearfile_last_error() else { return "" }
    return String(cString: borrowed)
}

/// The app's own version plane (apps/macos 0.1.0, the
/// one-plane-per-native-app rule; the record-side marker — the
/// source-side constant).
let kAppVersion = "0.1.0"

/// The MD3-from-seed theme (the corpus's recorded app seed, 0xFF00696E
/// — the same seed the Linux, Android, and Windows apps use).
let kThemeSeed: UInt32 = 0xFF00696E

/// One scheme role color (ARGB, opaque) through the palette FFI.
func roleColor(_ dark: Bool, _ role: String) -> UInt32 {
    var color: UInt32 = 0
    role.withCString { cString in
        color = clearfile_palette_scheme_role(kThemeSeed, dark, cString, UInt(strlen(cString)))
    }
    return color
}

/// An AppKit color from an opaque ARGB role color.
func nsColor(_ argb: UInt32) -> NSColor {
    return NSColor(srgbRed: CGFloat((argb >> 16) & 0xFF) / 255.0,
                   green: CGFloat((argb >> 8) & 0xFF) / 255.0,
                   blue: CGFloat(argb & 0xFF) / 255.0,
                   alpha: CGFloat((argb >> 24) & 0xFF) / 255.0)
}

// ---------------------------------------------------------------------------
// The display glue: Foundation JSON reading over the boundary's own
// payload (the core's writer emits well-formed compact JSON; this
// reads the display fields only). No engine logic, no general parsing.
// ---------------------------------------------------------------------------

func string(_ object: [String: Any], _ key: String) -> String {
    return (object[key] as? String) ?? ""
}

func number(_ object: [String: Any], _ key: String) -> Double {
    return (object[key] as? NSNumber)?.doubleValue ?? 0.0
}

/// The lossless integer read (`as? Int` — no double-to-Int truncation
/// drift; nil-coalesced to 0 exactly like the other display fields).
func integer(_ object: [String: Any], _ key: String) -> Int {
    return (object[key] as? Int) ?? 0
}

func stringArray(_ object: [String: Any], _ key: String) -> [String] {
    guard let array = object[key] as? [Any] else { return [] }
    return array.compactMap { $0 as? String }
}

func objectValue(_ object: [String: Any], _ key: String) -> [String: Any] {
    return (object[key] as? [String: Any]) ?? [:]
}

// ---------------------------------------------------------------------------
// The text summary — the byte-exact port of the Linux/Windows app's
// text_summary (the same groups, labels, formats, and footer; the CI
// smoke diffs this stdout against the Linux app's committed expected
// text — String(format:) is the printf family: non-localized, always
// '.' for the decimal separator).
// ---------------------------------------------------------------------------

func fmtMoney(_ value: Double) -> String {
    var magnitude = value
    if magnitude == 0.0 { magnitude = 0.0 }  // normalize -0.0 (the Linux app's note)
    let negative = magnitude < 0.0
    if negative { magnitude = -magnitude }
    let cents = String(format: "%.2f", magnitude)
    var intPart = cents
    var frac = "00"
    if let dot = cents.firstIndex(of: ".") {
        intPart = String(cents[..<dot])
        frac = String(cents[cents.index(after: dot)...])
    }
    var grouped = ""
    let digits = Array(intPart)  // no String integer subscripts (the ENG-3 discipline)
    let count = digits.count
    for index in 0..<count {
        if index > 0 && (count - index) % 3 == 0 { grouped += "," }
        grouped.append(digits[index])
    }
    return (negative ? "-$" : "$") + grouped + "." + frac
}

func fmtRate(_ value: Double) -> String {
    return String(format: "%.1f%%", value)
}

func resultRowsGroup(_ result: [String: Any], _ group: Int) -> [(label: String, value: String)] {
    func money(_ key: String) -> String { return fmtMoney(number(result, key)) }
    switch group {
    case 0:
        return [("Total income", money("totalIncome")),
                ("Student loan interest deduction", money("studentLoanDeduction")),
                ("Adjusted gross income", money("agi"))]
    case 1:
        return [("Basic standard deduction", money("basicStandardDeduction")),
                ("Additional standard deduction", money("additionalStandardDeduction")),
                ("Senior deduction", money("seniorDeduction")),
                ("Standard deduction total", money("standardDeductionTotal")),
                ("SALT paid", money("saltPaid")),
                ("SALT cap", money("saltCap")),
                ("SALT allowed", money("saltAllowed")),
                ("Itemized deductions total", money("itemizedDeductionTotal")),
                ("Method used", string(result, "deductionMethodUsed") == "itemized" ? "Itemized deductions" : "Standard deduction"),
                ("Deduction used", money("deductionUsed")),
                ("Taxable income", money("taxableIncome"))]
    case 2:
        return [("Ordinary tax", money("ordinaryTax")),
                ("Preferential income", money("preferentialIncome")),
                ("Preferential tax", money("preferentialTax")),
                ("NIIT", money("niit"))]
    case 3:
        return [("Qualifying children", String(integer(result, "qualifyingChildren"))),
                ("Non-refundable credits", money("nonRefundableCredits")),
                ("Refundable credits", money("refundableCredits")),
                ("Total tax (after non-refundable credits)", money("totalTax"))]
    default:
        return [("Total payments", money("totalPayments")),
                ("Refund", money("refund")),
                ("Amount owed", money("amountOwed")),
                ("Effective tax rate", fmtRate(number(result, "effectiveRate"))),
                ("Marginal tax rate", fmtRate(number(result, "marginalRate")))]
    }
}

func statusLabel(_ status: String) -> String {
    switch status {
    case "single": return "Single"
    case "marriedJoint": return "Married filing jointly"
    case "marriedSeparate": return "Married filing separately"
    case "headOfHousehold": return "Head of household"
    case "survivingSpouse": return "Qualifying surviving spouse"
    default: return "Single"
    }
}

/// The loaded payload (the display model).
struct Loaded {
    var path = ""
    var source = ""
    var displayName = ""
    var status = ""
    var taxYear = 2025
    var filing: [String: Any] = [:]
    var result: [String: Any] = [:]
    var warnings: [String] = []
}

func textSummary(_ loaded: Loaded) -> String {
    var out = ""
    out += "ClearFile — TY2025 federal summary (demonstration prototype)\n"
    out += "File: " + loaded.path + "\n"
    out += "Return: " + loaded.displayName + " (" + statusLabel(loaded.status) + ", TY" + String(loaded.taxYear) + ")\n"
    out += "Imported from " + loaded.source + ".\n"
    let groupTitles = ["Income", "Deduction", "Tax", "Credits", "Refund / amount owed"]
    for group in 0..<5 {
        out += groupTitles[group] + "\n"
        for row in resultRowsGroup(loaded.result, group) {
            out += "  " + row.label + ": " + row.value + "\n"
        }
    }
    if loaded.warnings.isEmpty {
        out += "Import warnings: none.\n"
    } else {
        out += "Import warnings (" + String(loaded.warnings.count) + ")\n"
        for warning in loaded.warnings {
            out += "  - " + warning + "\n"
        }
    }
    // The headless footer carries the three demo-disclaimer facts (the
    // welcome.dart fact family) + the qualified-professional line.
    out += "ClearFile prepares a simplified 2025 US federal return for study and demonstration. It is not IRS-authorized, cannot e-file, and must not be used to file a real tax return.\nDemonstration prototype — not tax advice; check with a qualified tax professional.\n"
    return out
}

// ---------------------------------------------------------------------------
// The ONE shared pipeline: read the file (the platform API + the 512 MiB
// pre-read bound with the core's own named message family), then the
// composed C-ABI pipeline, then the display model.
// ---------------------------------------------------------------------------

let kMaxInputFileBytes: UInt64 = 512 * 1024 * 1024

func loadAndCompute(_ path: String) -> Result<Loaded, String> {
    // The SEC-R2 hardening platform-side: the shared 512 MiB core bound
    // (2x the 256 MiB STORE cap) refused BEFORE the read, by metadata
    // alone — the same named message family every platform surfaces.
    let size: UInt64
    do {
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        guard let sizeNumber = attributes[.size] as? NSNumber else {
            return .failure("The file could not be read: the platform reports no size.")
        }
        size = sizeNumber.uint64Value
    } catch {
        return .failure("The file could not be read: the platform reports the item is unavailable.")
    }
    if size > kMaxInputFileBytes {
        return .failure("The file is too large to open — the limit is 512 MiB.")
    }
    let bytes: Data
    do {
        bytes = try Data(contentsOf: URL(fileURLWithPath: path))
    } catch {
        return .failure("The file could not be read: the platform reports the item is unreadable.")
    }
    // The owned payload with the ownership discipline inline (the input
    // borrow must stay inside the withUnsafeBytes scope): NULL is the
    // error path — guard-let, never force-unwrap; the copy-out precedes
    // the free (defer at the tightest scope).
    let payload: String
    do {
        guard let owned = bytes.withUnsafeBytes({ (raw: UnsafeRawBufferPointer) -> UnsafeMutablePointer<CChar>? in
            clearfile_load_and_compute(raw.bindMemory(to: CChar.self).baseAddress, UInt(raw.count))
        }) else {
            return .failure(lastErrorText())
        }
        defer { clearfile_free(owned) }
        payload = String(cString: owned)
    }
    guard let payloadData = payload.data(using: .utf8),
          let object = (try? JSONSerialization.jsonObject(with: payloadData)) as? [String: Any] else {
        return .failure("The file could not be opened as a ClearFile return.")
    }
    var loaded = Loaded()
    loaded.path = path
    loaded.source = string(object, "source")
    loaded.filing = objectValue(object, "filing")
    loaded.result = objectValue(object, "result")
    loaded.displayName = string(loaded.filing, "displayName")
    loaded.status = string(loaded.filing, "filingStatus")
    loaded.taxYear = integer(loaded.filing, "taxYear")
    loaded.warnings = stringArray(object, "warnings")
    return .success(loaded)
}

// ---------------------------------------------------------------------------
// The byte-exact output surfaces (FileHandle writes carry no newline
// translation; UTF-8 + LF exactly — the CI smoke diffs the full stdout
// against the committed expected text).
// ---------------------------------------------------------------------------

func writeOut(_ text: String) {
    if let data = text.data(using: .utf8) {
        try? FileHandle.standardOutput.write(contentsOf: data)
    }
}

func writeErr(_ text: String) {
    if let data = text.data(using: .utf8) {
        try? FileHandle.standardError.write(contentsOf: data)
    }
}

// ---------------------------------------------------------------------------
// The window mode (AppKit; the named non-verification: CI never runs
// this path — the hosted runner has no interactive desktop; the
// headless mode is the verifiable surface). The custom view mirrors
// the Direct2D app: one direct-draw text rect at (24, 24),
// click-to-open anywhere (the GetOpenFileNameW analogue), the palette
// theme, no scrolling chrome.
// ---------------------------------------------------------------------------

final class SummaryView: NSView {
    var text: String = ""
    var textColor: NSColor = .black
    var backgroundColor: NSColor = .white
    var onOpen: (() -> Void)?

    /// The flipped coordinate system: the text rect's origin sits at the
    /// top-left, exactly like the Direct2D app's (24, 24, 776, 576) rect.
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        backgroundColor.setFill()
        bounds.fill()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: textColor,
        ]
        NSAttributedString(string: text, attributes: attributes)
            .draw(in: NSRect(x: 24, y: 24, width: bounds.width - 48, height: bounds.height - 48))
    }

    override func mouseDown(with event: NSEvent) {
        onOpen?()
    }
}

/// Terminates when the window closes (the PostQuitMessage analogue).
final class WindowCloseDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
}

func runWindow(_ path: String?) {
    var loaded: Loaded? = nil
    var loadError: String? = nil
    if let filePath = path {
        switch loadAndCompute(filePath) {
        case .success(let value): loaded = value
        case .failure(let message): loadError = message
        }
    }

    let app = NSApplication.shared
    app.setActivationPolicy(.regular)  // the non-bundle executable's activation

    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
    window.title = "ClearFile (prototype) — TY2025 federal summary"

    // The MD3-from-seed theme (the palette FFI — the same corpus seed as
    // every other lane).
    let background = nsColor(roleColor(false, "surface"))
    let foreground = nsColor(roleColor(false, "onSurface"))

    let view = SummaryView()
    view.textColor = foreground
    view.backgroundColor = background
    if let message = loadError {
        view.text = "ClearFile (prototype) — TY2025 federal summary\n\nThe file could not be opened as a ClearFile return.\n\n" + message
    } else if let value = loaded {
        view.text = textSummary(value)
    } else {
        view.text = "ClearFile (prototype) — TY2025 federal summary\n\n"
            + "No file open. Click the window to open a .clearfile.json envelope or a .tax container.\n\n"
            + "ClearFile prepares a simplified 2025 US federal return for study and demonstration. "
            + "It is not IRS-authorized, cannot e-file, and must not be used to file a real tax return.\n"
            + "No AI: this app makes no network connections, stores no keys, and sends no data anywhere.\n"
            + "ClearFile is an independent study project. It is not affiliated with or endorsed by the IRS, Intuit, or TurboTax."
    }

    let closeDelegate = WindowCloseDelegate()
    window.delegate = closeDelegate
    window.contentView = view
    view.onOpen = {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Open a .clearfile.json envelope or a .tax container"
        if panel.runModal() == .OK, let url = panel.url {
            switch loadAndCompute(url.path) {
            case .success(let value):
                view.text = textSummary(value)
            case .failure(let message):
                view.text = "ClearFile (prototype) — TY2025 federal summary\n\nThe file could not be opened as a ClearFile return.\n\n" + message
            }
            view.needsDisplay = true
        }
    }

    window.center()
    window.makeKeyAndOrderFront(nil)
    app.run()
}

// ---------------------------------------------------------------------------
// The argv modes (the Linux/Windows apps' exact surface).
// ---------------------------------------------------------------------------

func usageError(_ message: String) -> Never {
    writeErr(message + "\nusage: clearfile-macos [--headless] <file> | (no argument for the window)\n")
    exit(2)
}

let arguments = CommandLine.arguments
var headless = false
var path: String? = nil
if arguments.count >= 2 && arguments[1] == "--headless" {
    headless = true
    if arguments.count < 3 {
        usageError("--headless needs a file path")
    }
    path = arguments[2]
} else if arguments.count == 2 {
    path = arguments[1]
} else if arguments.count > 2 {
    usageError("too many arguments")
}

if headless {
    guard let filePath = path else {
        usageError("--headless needs a file path")
    }
    switch loadAndCompute(filePath) {
    case .failure(let message):
        writeErr(message + "\n")
        exit(1)
    case .success(let loaded):
        // The byte-exact UTF-8 + LF stdout (the CI smoke diffs the full
        // stdout against the Linux app's committed expected text — one
        // canonical text family, three platforms).
        writeOut(textSummary(loaded))
        exit(0)
    }
}
runWindow(path)

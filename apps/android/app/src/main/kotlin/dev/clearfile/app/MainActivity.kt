// SPDX-License-Identifier: GPL-3.0-only
// The MainActivity (the N3 Android Views viewer demo): plain
// android.app.Activity + platform Views (no Compose, no AndroidX — the
// recorded zero-AndroidX posture), the MD3-from-seed theme via the
// palette FFI (the same corpus seed as the Linux app), and the two data
// paths: the bundled example (PULLED from the shared fixtures/tax/
// family by the gradle task) + the SAF open (.clearfile.json / .tax).
//
// The honesty surfaces (strings.xml is the single source): the
// three-fact demo disclaimer, the no-AI/no-network note (OS-enforced —
// the manifest requests no permissions at all), the non-affiliation
// line, and the prototype label (the launcher name + the header).
//
// ZERO engine logic: every displayed value flows from the Rust core
// through the thin JNI seam (Native.loadAndCompute — the same composed
// pipeline the Linux app runs).

package dev.clearfile.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.text.method.ScrollingMovementMethod
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import dev.clearfile.ffi.LoadedReturn
import dev.clearfile.ffi.ensureLoaded
import dev.clearfile.ffi.Roles
import dev.clearfile.ffi.loadAndDisplay
import dev.clearfile.ffi.roleColor

class MainActivity : Activity() {

    private lateinit var content: LinearLayout
    private var dark = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The single library load (the app owns it; the JVM host test
        // instead System.load's the host-built .so).
        ensureLoaded()
        buildUi()
    }

    private fun buildUi() {
        content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(48, 64, 48, 64)
            setBackgroundColor(roleColor(dark, Roles.SURFACE))
        }
        val scroll = ScrollView(this).apply { addView(content) }
        setContentView(scroll)

        content.addView(
            TextView(this).apply {
                text = getString(R.string.app_name)
                textSize = 28f
                setTextColor(roleColor(dark, Roles.PRIMARY))
            },
        )
        content.addView(
            TextView(this).apply {
                text = "TY2025 federal summary — demonstration viewer"
                textSize = 14f
                setTextColor(roleColor(dark, Roles.ON_SURFACE_VARIANT))
            },
        )

        fun button(label: Int, onClick: (View) -> Unit): Button =
            Button(this).apply {
                setText(label)
                setTextColor(roleColor(dark, Roles.ON_PRIMARY))
                setBackgroundColor(roleColor(dark, Roles.PRIMARY))
                setOnClickListener(onClick)
            }

        content.addView(
            button(R.string.load_bundled) {
                runCatching { loadAndDisplay(assets.open("clearfile-fixture.json").readBytes()) }
                    .onSuccess(::showLoaded)
                    .onFailure { showError(it.message ?: getString(R.string.load_failed)) }
            },
        )
        content.addView(
            button(R.string.open_file) {
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                }
                @Suppress("DEPRECATION") // the platform API — no AndroidX result API (the recorded posture)
                startActivityForResult(intent, 1)
            },
        )

        // The honesty surfaces: the disclaimer, the no-network note, the
        // non-affiliation line (strings.xml is the single source).
        content.addView(
            TextView(this).apply {
                text = getString(R.string.disclaimer)
                textSize = 12f
                setTextColor(roleColor(dark, Roles.ON_SURFACE_VARIANT))
                setPadding(0, 48, 0, 0)
            },
        )
        content.addView(
            TextView(this).apply {
                text = getString(R.string.no_network_note)
                textSize = 12f
                setTextColor(roleColor(dark, Roles.ON_SURFACE_VARIANT))
            },
        )
        content.addView(
            TextView(this).apply {
                text = getString(R.string.non_affiliation)
                textSize = 12f
                setTextColor(roleColor(dark, Roles.ON_SURFACE_VARIANT))
            },
        )
    }

    @Deprecated("Deprecated in Java")
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 1 || resultCode != RESULT_OK) return
        val uri = data?.data ?: return
        // The SAF pre-read size query (the SEC-R2 hardening's Android
        // enforcement): refuse a document beyond the shared 512 MiB core
        // constant BEFORE the stream read — the same named message family
        // (the boundary re-checks; this avoids reading it into RAM first).
        val descriptor = runCatching { contentResolver.openAssetFileDescriptor(uri, "r") }
        descriptor.getOrNull()?.use { fd ->
            val length = fd.length
            if (length > 512L * 1024 * 1024) {
                showError(getString(R.string.file_too_large))
                return
            }
        }
        runCatching {
            loadAndDisplay(contentResolver.openInputStream(uri)!!.use { it.readBytes() })
        }
            .onSuccess(::showLoaded)
            .onFailure { showError(it.message ?: getString(R.string.load_failed)) }
    }

    private fun showLoaded(loaded: LoadedReturn) {
        content.removeAllViews()
        fun row(label: String, value: String): TextView =
            TextView(this).apply {
                text = "$label  $value"
                textSize = 16f
                setTextColor(roleColor(dark, Roles.ON_SURFACE))
                setPadding(0, 16, 0, 16)
            }
        content.addView(
            TextView(this).apply {
                text = "Imported from ${loaded.source}"
                textSize = 14f
                setTextColor(roleColor(dark, Roles.ON_SURFACE_VARIANT))
                setPadding(0, 16, 0, 16)
            },
        )
        content.addView(row("Total income:", loaded.totalIncome))
        content.addView(row("Taxable income:", loaded.taxableIncome))
        content.addView(row("Total tax:", loaded.totalTax))
        content.addView(row("", loaded.refundOrOwed))
        if (loaded.warnings.isNotEmpty()) {
            content.addView(
                TextView(this).apply {
                    text = "Import warnings (${loaded.warnings.size})"
                    textSize = 14f
                    setTextColor(roleColor(dark, Roles.ON_SURFACE_VARIANT))
                    setPadding(0, 32, 0, 8)
                },
            )
            for (warning in loaded.warnings) {
                content.addView(
                    TextView(this).apply {
                        text = "  - $warning"
                        textSize = 12f
                        setTextColor(roleColor(dark, Roles.ON_SURFACE_VARIANT))
                        setPadding(0, 4, 0, 4)
                    },
                )
            }
        }
        // The theme toggle: light/dark via the palette FFI (the scheme
        // colors recompute from the same seed for both brightnesses).
        content.addView(
            Button(this).apply {
                text = if (dark) "Switch to light theme" else "Switch to dark theme"
                setTextColor(roleColor(dark, Roles.ON_PRIMARY))
                setBackgroundColor(roleColor(dark, Roles.PRIMARY))
                setOnClickListener {
                    dark = !dark
                    buildUi()
                    // Re-display the last payload? The bundled example is
                    // always available; re-load it for the fresh theme.
                    runCatching { loadAndDisplay(assets.open("clearfile-fixture.json").readBytes()) }
                        .onSuccess(::showLoaded)
                }
            },
        )
    }

    private fun showError(message: String) {
        content.removeAllViews()
        content.addView(
            TextView(this).apply {
                text = getString(R.string.load_failed)
                textSize = 18f
                setTextColor(roleColor(dark, Roles.ERROR))
                setPadding(0, 16, 0, 16)
            },
        )
        content.addView(
            TextView(this).apply {
                text = message
                textSize = 14f
                setTextColor(roleColor(dark, Roles.ON_SURFACE))
                movementMethod = ScrollingMovementMethod()
            },
        )
    }
}

// SPDX-License-Identifier: GPL-3.0-only
// The ClearFile Windows native UI (N4, the ADR-017 epilogue): a C++17
// Win32 + Direct2D viewer demo consuming the COMMITTED core-ffi/clearfile.h
// (the first C++ consumer; the header's config-emitted extern "C" guards
// make the flat C ABI linkable unmangled). ZERO external dependencies —
// the platform libs only (user32, gdi32, comdlg32, d2d1, dwrite).
//
// The shape mirrors the Linux app (N2) exactly: the argv modes
// (--headless <path> / a bare path / no argument), the ONE shared
// pipeline (read -> the 512 MiB pre-read bound -> the composed
// clearfile_load_and_compute -> the text summary), the SAME text family
// (the byte-parity headless output the CI smoke diffs against the Linux
// app's committed expected text — one canonical expected text, two
// platforms), the MD3-from-seed theme via the palette FFI (the same
// corpus seed), and the full honesty set (the three-fact demo
// disclaimer, the IRS/Intuit non-affiliation line, the prototype
// labels, the no-AI/no-network note — no network code exists anywhere
// in the app or the core; the PE import-table guard is the mechanical
// proof).
//
// ZERO engine logic (the ADR-017 core boundary): every number flows
// from the Rust core through the flat C ABI; the JSON scanning below
// is display glue over the boundary's own payload, nothing more.

// wmain: the Unicode argv (the GetOpenFileNameW paths stay lossless).
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif

#include <windows.h>
#include <commdlg.h>
#include <d2d1.h>
#include <d2d1helper.h>
#include <dwrite.h>
#include <fcntl.h>
#include <io.h>
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#include "clearfile.h" // the committed flat C ABI (config-emitted extern "C")

// ---------------------------------------------------------------------------
// The consumption discipline (the N4 gate's ledger, SEC-1/ENG-7): the RAII
// wrapper owns clearfile_free; the borrowed last_error is copied out
// immediately (valid only until the next call on this thread); the app is
// single-threaded (the message loop + the headless path never race the
// thread-local).
// ---------------------------------------------------------------------------

/// An owned C-ABI return buffer (freed ONLY by clearfile_free — the ABI's
/// one correct release path; the destructor is the whole point).
struct OwnedBuffer {
    char *p = nullptr;
    explicit OwnedBuffer(char *ptr) : p(ptr) {}
    ~OwnedBuffer() { clearfile_free(p); }
    OwnedBuffer(const OwnedBuffer &) = delete;
    OwnedBuffer &operator=(const OwnedBuffer &) = delete;
    bool ok() const { return p != nullptr; }
    const char *get() const { return p; }
};

/// The current last error, copied out of the borrowed thread-local
/// ("" when the last call succeeded — the header's documented contract).
std::string last_error_text() {
    const char *borrowed = clearfile_last_error();
    return borrowed ? std::string(borrowed) : std::string();
}

/// The app's own version plane (apps/windows 0.1.0, the one-plane-per-
/// native-app rule; the record-side marker — the source-side constant).
constexpr const char *kAppVersion = "0.1.0";

/// The MD3-from-seed theme (the corpus's recorded app seed, 0xFF00696E —
/// the same seed the Linux and Android apps use).
constexpr uint32_t kThemeSeed = 0xFF00696Eu;

/// One scheme role color (ARGB) through the palette FFI.
uint32_t role_color(bool dark, const char *role) {
    return clearfile_palette_scheme_role(kThemeSeed, dark ? 1 : 0, role, std::strlen(role));
}

// ---------------------------------------------------------------------------
// The display glue: a minimal JSON field scanner over the boundary's own
// payload (the core's writer emits well-formed compact JSON; this scans
// for the display fields only — strings, numbers, and the warnings array
// of strings). No engine logic, no general parsing — display glue.
// ---------------------------------------------------------------------------

static void skip_ws(const std::string &s, size_t &i) {
    while (i < s.size() && (s[i] == ' ' || s[i] == '\n' || s[i] == '\r' || s[i] == '\t')) i++;
}

/// Parse a JSON string body (post-opening-quote); handles the standard
/// escapes + the BMP \uXXXX (the payload's em-dashes).
static std::string parse_string_body(const std::string &s, size_t &i) {
    std::string out;
    while (i < s.size() && s[i] != '"') {
        if (s[i] == '\\' && i + 1 < s.size()) {
            i++;
            switch (s[i]) {
                case 'n': out += '\n'; i++; break;
                case 't': out += '\t'; i++; break;
                case 'r': out += '\r'; i++; break;
                case '"': out += '"'; i++; break;
                case '\\': out += '\\'; i++; break;
                case '/': out += '/'; i++; break;
                case 'u': {
                    if (i + 4 < s.size()) {
                        unsigned cp = 0;
                        for (int k = 1; k <= 4; k++) {
                            char h = s[i + (size_t)k];
                            cp <<= 4;
                            if (h >= '0' && h <= '9') cp |= (unsigned)(h - '0');
                            else if (h >= 'a' && h <= 'f') cp |= (unsigned)(h - 'a' + 10);
                            else if (h >= 'A' && h <= 'F') cp |= (unsigned)(h - 'A' + 10);
                        }
                        i += 5;
                        if (cp < 0x80) {
                            out += (char)cp;
                        } else if (cp < 0x800) {
                            out += (char)(0xC0 | (cp >> 6));
                            out += (char)(0x80 | (cp & 0x3F));
                        } else {
                            out += (char)(0xE0 | (cp >> 12));
                            out += (char)(0x80 | ((cp >> 6) & 0x3F));
                            out += (char)(0x80 | (cp & 0x3F));
                        }
                    } else {
                        out += s[i++];
                    }
                    break;
                }
                default: out += s[i++]; break;
            }
        } else {
            out += s[i++];
        }
    }
    if (i < s.size()) i++; // the closing quote
    return out;
}

/// Find the object member `key` (a shallow scan; nested objects are not
/// entered — the payload's top level is flat). Returns the value's start.
static size_t find_member(const std::string &s, const std::string &key) {
    std::string needle = "\"" + key + "\":";
    size_t pos = s.find(needle);
    if (pos == std::string::npos) return std::string::npos;
    size_t v = pos + needle.size();
    skip_ws(s, v);
    return v;
}

static std::string get_string(const std::string &s, const std::string &key) {
    size_t v = find_member(s, key);
    if (v == std::string::npos || v >= s.size() || s[v] != '"') return "";
    v++;
    return parse_string_body(s, v);
}

static double get_number(const std::string &s, const std::string &key) {
    size_t v = find_member(s, key);
    if (v == std::string::npos || v >= s.size()) return 0.0;
    return strtod(s.c_str() + v, nullptr);
}

static std::vector<std::string> get_string_array(const std::string &s, const std::string &key) {
    std::vector<std::string> out;
    size_t v = find_member(s, key);
    if (v == std::string::npos || v >= s.size() || s[v] != '[') return out;
    v++;
    skip_ws(s, v);
    if (v < s.size() && s[v] == ']') return out;
    while (v < s.size()) {
        skip_ws(s, v);
        if (v < s.size() && s[v] == '"') {
            v++;
            out.push_back(parse_string_body(s, v));
        }
        skip_ws(s, v);
        if (v < s.size() && s[v] == ',') { v++; continue; }
        break;
    }
    return out;
}

/// The bracket-balanced subtree at `key` (for the nested filing/result).
static std::string get_object(const std::string &s, const std::string &key) {
    size_t v = find_member(s, key);
    if (v == std::string::npos || v >= s.size() || s[v] != '{') return "{}";
    size_t start = v;
    int depth = 0;
    bool in_string = false;
    while (v < s.size()) {
        char c = s[v];
        if (in_string) {
            if (c == '\\') { v += 2; continue; }
            if (c == '"') in_string = false;
        } else if (c == '"') {
            in_string = true;
        } else if (c == '{') {
            depth++;
        } else if (c == '}') {
            depth--;
            if (depth == 0) return s.substr(start, v - start + 1);
        }
        v++;
    }
    return "{}";
}

// ---------------------------------------------------------------------------
// The text summary — the byte-exact port of the Linux app's text_summary
// (the same groups, labels, formats, and footer; the CI smoke diffs this
// stdout against the Linux app's committed expected text).
// ---------------------------------------------------------------------------

static std::string fmt_money(double value) {
    if (value == 0.0) value = 0.0; // normalize -0.0 (the Linux app's note)
    bool negative = value < 0.0;
    double a = value < 0.0 ? -value : value;
    char cents[64];
    snprintf(cents, sizeof(cents), "%.2f", a);
    std::string int_part = cents, frac = "00";
    size_t dot = int_part.find('.');
    if (dot != std::string::npos) {
        frac = int_part.substr(dot + 1);
        int_part = int_part.substr(0, dot);
    }
    std::string grouped;
    size_t digits = int_part.size();
    for (size_t index = 0; index < digits; index++) {
        if (index > 0 && (digits - index) % 3 == 0) grouped += ',';
        grouped += int_part[index];
    }
    return (negative ? "-$" : "$") + grouped + "." + frac;
}

static std::string fmt_rate(double value) {
    char buf[32];
    snprintf(buf, sizeof(buf), "%.1f%%", value);
    return buf;
}

struct Row { std::string label, value; };

static std::vector<Row> result_rows_group(const std::string &result, int group) {
    std::vector<Row> r;
    switch (group) {
        case 0:
            r.push_back({"Total income", fmt_money(get_number(result, "totalIncome"))});
            r.push_back({"Student loan interest deduction", fmt_money(get_number(result, "studentLoanDeduction"))});
            r.push_back({"Adjusted gross income", fmt_money(get_number(result, "agi"))});
            break;
        case 1:
            r.push_back({"Basic standard deduction", fmt_money(get_number(result, "basicStandardDeduction"))});
            r.push_back({"Additional standard deduction", fmt_money(get_number(result, "additionalStandardDeduction"))});
            r.push_back({"Senior deduction", fmt_money(get_number(result, "seniorDeduction"))});
            r.push_back({"Standard deduction total", fmt_money(get_number(result, "standardDeductionTotal"))});
            r.push_back({"SALT paid", fmt_money(get_number(result, "saltPaid"))});
            r.push_back({"SALT cap", fmt_money(get_number(result, "saltCap"))});
            r.push_back({"SALT allowed", fmt_money(get_number(result, "saltAllowed"))});
            r.push_back({"Itemized deductions total", fmt_money(get_number(result, "itemizedDeductionTotal"))});
            r.push_back({"Method used", get_string(result, "deductionMethodUsed") == "itemized" ? "Itemized deductions" : "Standard deduction"});
            r.push_back({"Deduction used", fmt_money(get_number(result, "deductionUsed"))});
            r.push_back({"Taxable income", fmt_money(get_number(result, "taxableIncome"))});
            break;
        case 2:
            r.push_back({"Ordinary tax", fmt_money(get_number(result, "ordinaryTax"))});
            r.push_back({"Preferential income", fmt_money(get_number(result, "preferentialIncome"))});
            r.push_back({"Preferential tax", fmt_money(get_number(result, "preferentialTax"))});
            r.push_back({"NIIT", fmt_money(get_number(result, "niit"))});
            break;
        case 3:
            r.push_back({"Qualifying children", std::to_string((long long)get_number(result, "qualifyingChildren"))});
            r.push_back({"Non-refundable credits", fmt_money(get_number(result, "nonRefundableCredits"))});
            r.push_back({"Refundable credits", fmt_money(get_number(result, "refundableCredits"))});
            r.push_back({"Total tax (after non-refundable credits)", fmt_money(get_number(result, "totalTax"))});
            break;
        default:
            r.push_back({"Total payments", fmt_money(get_number(result, "totalPayments"))});
            r.push_back({"Refund", fmt_money(get_number(result, "refund"))});
            r.push_back({"Amount owed", fmt_money(get_number(result, "amountOwed"))});
            r.push_back({"Effective tax rate", fmt_rate(get_number(result, "effectiveRate"))});
            r.push_back({"Marginal tax rate", fmt_rate(get_number(result, "marginalRate"))});
            break;
    }
    return r;
}

static std::string status_label(const std::string &status) {
    if (status == "single") return "Single";
    if (status == "marriedJoint") return "Married filing jointly";
    if (status == "marriedSeparate") return "Married filing separately";
    if (status == "headOfHousehold") return "Head of household";
    if (status == "survivingSpouse") return "Qualifying surviving spouse";
    return "Single";
}

/// The loaded payload (the display model).
struct Loaded {
    std::string path, source, display_name, status;
    long long tax_year = 2025;
    std::string filing, result;
    std::vector<std::string> warnings;
};

static std::string text_summary(const Loaded &loaded) {
    std::string out;
    out += "ClearFile \xE2\x80\x94 TY2025 federal summary (demonstration prototype)\n";
    out += "File: " + loaded.path + "\n";
    out += "Return: " + loaded.display_name + " (" + status_label(loaded.status) + ", TY" + std::to_string(loaded.tax_year) + ")\n";
    out += "Imported from " + loaded.source + ".\n";
    static const char *group_titles[5] = {
        "Income", "Deduction", "Tax", "Credits", "Refund / amount owed"};
    for (int g = 0; g < 5; g++) {
        out += std::string(group_titles[g]) + "\n";
        for (const Row &r : result_rows_group(loaded.result, g)) {
            out += "  " + r.label + ": " + r.value + "\n";
        }
    }
    if (loaded.warnings.empty()) {
        out += "Import warnings: none.\n";
    } else {
        out += "Import warnings (" + std::to_string(loaded.warnings.size()) + ")\n";
        for (const std::string &w : loaded.warnings) out += "  - " + w + "\n";
    }
    // The headless footer carries the three demo-disclaimer facts (the
    // welcome.dart fact family) + the qualified-professional line.
    out += "ClearFile prepares a simplified 2025 US federal return for study and "
           "demonstration. It is not IRS-authorized, cannot e-file, and must not "
           "be used to file a real tax return.\nDemonstration prototype \xE2\x80\x94 not "
           "tax advice; check with a qualified tax professional.\n";
    return out;
}

// ---------------------------------------------------------------------------
// The ONE shared pipeline: read the file (the platform API + the 512 MiB
// pre-read bound with the core's own named message family), then the
// composed C-ABI pipeline, then the display model.
// ---------------------------------------------------------------------------

static std::string utf8_of_wide(const std::wstring &w) {
    if (w.empty()) return "";
    int n = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), nullptr, 0, nullptr, nullptr);
    std::string out((size_t)n, '\0');
    WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), &out[0], n, nullptr, nullptr);
    return out;
}

static std::wstring wide_of_utf8(const std::string &s) {
    if (s.empty()) return L"";
    int n = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), nullptr, 0);
    std::wstring out((size_t)n, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), &out[0], n);
    return out;
}

static bool read_file(const std::wstring &path, std::vector<char> &bytes, std::string &error) {
    HANDLE file = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
                              OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) {
        error = "The file could not be read: the platform reports error " + std::to_string((long long)GetLastError()) + ".";
        return false;
    }
    LARGE_INTEGER size{};
    if (!GetFileSizeEx(file, &size)) {
        error = "The file could not be read: the platform reports error " + std::to_string((long long)GetLastError()) + ".";
        CloseHandle(file);
        return false;
    }
    // The SEC-R2 hardening platform-side: the shared 512 MiB core bound
    // (2x the 256 MiB STORE cap) refused BEFORE the read, by metadata
    // alone — the same named message family every platform surfaces.
    constexpr uint64_t kMaxInputFileBytes = 512ull * 1024 * 1024;
    if ((uint64_t)size.QuadPart > kMaxInputFileBytes) {
        CloseHandle(file);
        error = "The file is too large to open \xE2\x80\x94 the limit is 512 MiB.";
        return false;
    }
    bytes.resize((size_t)size.QuadPart);
    DWORD read_n = 0;
    if (size.QuadPart > 0 && !ReadFile(file, bytes.data(), (DWORD)bytes.size(), &read_n, nullptr)) {
        error = "The file could not be read: the platform reports error " + std::to_string((long long)GetLastError()) + ".";
        CloseHandle(file);
        return false;
    }
    CloseHandle(file);
    return true;
}

static bool load_and_compute(const std::wstring &path, Loaded &loaded, std::string &error) {
    std::vector<char> bytes;
    if (!read_file(path, bytes, error)) return false;
    OwnedBuffer payload(clearfile_load_and_compute(bytes.data(), bytes.size()));
    if (!payload.ok()) {
        error = last_error_text();
        return false;
    }
    std::string text(payload.get());
    loaded = Loaded{};
    loaded.path = utf8_of_wide(path);
    loaded.source = get_string(text, "source");
    loaded.filing = get_object(text, "filing");
    loaded.result = get_object(text, "result");
    loaded.display_name = get_string(loaded.filing, "displayName");
    loaded.status = get_string(loaded.filing, "filingStatus");
    loaded.tax_year = (long long)get_number(loaded.filing, "taxYear");
    loaded.warnings = get_string_array(text, "warnings");
    return true;
}

// ---------------------------------------------------------------------------
// The window mode (Direct2D + DirectWrite; the named non-verification: the
// hosted runner has no interactive desktop — CI never runs this path; the
// headless mode is the verifiable surface).
// ---------------------------------------------------------------------------

static ID2D1Factory *d2d_factory = nullptr;
static IDWriteFactory *dwrite_factory = nullptr;
static ID2D1HwndRenderTarget *target = nullptr;
static IDWriteTextFormat *format = nullptr;
static Loaded g_loaded;
static std::string g_error;
static bool g_has_loaded = false;

static D2D1_COLOR_F d2d_of(uint32_t argb) {
    return D2D1::ColorF((argb >> 16 & 0xFF) / 255.0f, (argb >> 8 & 0xFF) / 255.0f,
                        (argb & 0xFF) / 255.0f, (argb >> 24 & 0xFF) / 255.0f);
}

static void render(HWND hwnd) {
    if (!target) return;
    uint32_t bg = role_color(false, "surface");
    uint32_t fg = role_color(false, "onSurface");
    target->BeginDraw();
    target->Clear(d2d_of(bg));
    ID2D1SolidColorBrush *brush = nullptr;
    target->CreateSolidColorBrush(d2d_of(fg), &brush);
    std::string text;
    if (!g_error.empty()) {
        text = "ClearFile (prototype) \xE2\x80\x94 TY2025 federal summary\n\nThe file could not be opened as a ClearFile return.\n\n" + g_error;
    } else if (g_has_loaded) {
        text = text_summary(g_loaded);
    } else {
        text = "ClearFile (prototype) \xE2\x80\x94 TY2025 federal summary\n\n"
               "No file open. Click the window to open a .clearfile.json envelope or a .tax container.\n\n"
               "ClearFile prepares a simplified 2025 US federal return for study and demonstration. "
               "It is not IRS-authorized, cannot e-file, and must not be used to file a real tax return.\n"
               "No AI: this app makes no network connections, stores no keys, and sends no data anywhere.\n"
               "ClearFile is an independent study project. It is not affiliated with or endorsed by the IRS, Intuit, or TurboTax.";
    }
    std::wstring wtext = wide_of_utf8(text);
    D2D1_RECT_F rect = D2D1::RectF(24.0f, 24.0f, 776.0f, 576.0f);
    if (brush) {
        target->DrawTextW(wtext.c_str(), (UINT32)wtext.size(), format, rect,
                         brush, D2D1_DRAW_TEXT_OPTIONS_NONE);
        brush->Release();
    }
    target->EndDraw();
}

static void open_dialog(HWND hwnd) {
    wchar_t file[MAX_PATH] = L"";
    OPENFILENAMEW ofn{};
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = hwnd;
    ofn.lpstrFile = file;
    ofn.nMaxFile = MAX_PATH;
    ofn.lpstrFilter = L"ClearFile returns\0*.clearfile.json;*.tax\0All files\0*.*\0";
    ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST;
    if (GetOpenFileNameW(&ofn)) {
        Loaded loaded;
        std::string error;
        if (load_and_compute(ofn.lpstrFile, loaded, error)) {
            g_loaded = loaded;
            g_has_loaded = true;
            g_error.clear();
        } else {
            g_error = error;
            g_has_loaded = false;
        }
        InvalidateRect(hwnd, nullptr, TRUE);
    }
}

static LRESULT CALLBACK wndproc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
        case WM_PAINT: {
            PAINTSTRUCT ps;
            BeginPaint(hwnd, &ps);
            render(hwnd);
            EndPaint(hwnd, &ps);
            return 0;
        }
        case WM_LBUTTONUP:
            open_dialog(hwnd);
            return 0;
        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
    }
    return DefWindowProcW(hwnd, msg, wp, lp);
}

static int run_window(const wchar_t *path) {
    if (path) {
        Loaded loaded;
        std::string error;
        if (load_and_compute(path, loaded, error)) {
            g_loaded = loaded;
            g_has_loaded = true;
        } else {
            g_error = error;
        }
    }
    if (FAILED(D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &d2d_factory))) return 2;
    if (FAILED(DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory), (IUnknown **)&dwrite_factory))) return 2;
    WNDCLASSW wc{};
    wc.lpfnWndProc = wndproc;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = L"ClearFileWindow";
    wc.hCursor = LoadCursorW(nullptr, (LPCWSTR)IDC_ARROW);
    RegisterClassW(&wc);
    HWND hwnd = CreateWindowExW(0, L"ClearFileWindow",
                                L"ClearFile (prototype) \x2014 TY2025 federal summary",
                                WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 800, 600,
                                nullptr, nullptr, wc.hInstance, nullptr);
    if (!hwnd) return 2;
    D2D1_RENDER_TARGET_PROPERTIES props = D2D1::RenderTargetProperties();
    D2D1_HWND_RENDER_TARGET_PROPERTIES hwnd_props =
        D2D1::HwndRenderTargetProperties(hwnd, D2D1::SizeU(800, 600));
    if (FAILED(d2d_factory->CreateHwndRenderTarget(props, hwnd_props, &target))) return 2;
    dwrite_factory->CreateTextFormat(L"Segoe UI", nullptr, DWRITE_FONT_WEIGHT_NORMAL,
                                     DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL,
                                     16.0f, L"en-US", &format);
    ShowWindow(hwnd, SW_SHOW);
    UpdateWindow(hwnd);
    MSG msg{};
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    if (format) format->Release();
    if (target) target->Release();
    if (dwrite_factory) dwrite_factory->Release();
    if (d2d_factory) d2d_factory->Release();
    return 0;
}

// ---------------------------------------------------------------------------
// The argv modes (the Linux app's exact surface).
// ---------------------------------------------------------------------------

static int usage_error(const wchar_t *message) {
    fwprintf(stderr, L"%s\nusage: clearfile-windows [--headless] <file> | (no argument for the window)\n", message);
    return 2;
}

int wmain(int argc, wchar_t **argv) {
    bool headless = false;
    const wchar_t *path = nullptr;
    if (argc >= 2 && wcscmp(argv[1], L"--headless") == 0) {
        headless = true;
        if (argc < 3) return usage_error(L"--headless needs a file path");
        path = argv[2];
    } else if (argc == 2) {
        path = argv[1];
    } else if (argc > 2) {
        return usage_error(L"too many arguments");
    }
    if (headless) {
        Loaded loaded;
        std::string error;
        if (!load_and_compute(path, loaded, error)) {
            fwprintf(stderr, L"%s\n", wide_of_utf8(error).c_str());
            return 1;
        }
        // The binary-mode stdout: the byte-exact UTF-8 + LF text (the CI
        // smoke diffs the full stdout against the Linux app's committed
        // expected text — one canonical text family, two platforms).
        _setmode(_fileno(stdout), _O_BINARY);
        std::string text = text_summary(loaded);
        fwrite(text.data(), 1, text.size(), stdout);
        return 0;
    }
    return run_window(path);
}

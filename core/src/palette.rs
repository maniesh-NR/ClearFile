// SPDX-License-Identifier: GPL-3.0-only
//! D44 chunk 1: the HCT color math — a translation (derived, not vendored)
//! of Google's Apache-2.0 Dart package `material_color_utilities` 0.13.0.
//! Ported sources: `utils/math_utils.dart`, `utils/color_utils.dart`,
//! `hct/viewing_conditions.dart`, `hct/cam16.dart`, `hct/hct.dart`,
//! `hct/src/hct_solver.dart` — only the pieces the Cam16/HctSolver/Hct
//! chain uses, math verbatim (operation order preserved; Dart `%` keeps the
//! source's own sign fix-up (or `rem_euclid` where the source relies on
//! Dart's euclidean `%`), and `signum` keeps 0 at zero). `Hct::from_int`
//! stores the solver's canonical sRGB argb for the color's coordinates
//! (the Dart class resynchronizes `_argb` through the solver in every
//! setter) — that equals the input for every 8-bit sRGB color, so the
//! corpus seeds round-trip exactly (alpha becomes 0xFF, as in every
//! solver result). See THIRD-PARTY-NOTICES.md — the notice entry itself
//! lands with the chunk-2 palette close (D44 chunk 2 of 2).

use std::f64::consts::PI;

// --- MathUtils subset (utils/math_utils.dart) ---

/// `MathUtils.signum` (utils/math_utils.dart): 1 / 0 / -1, zero at zero.
fn signum(num: f64) -> f64 {
    if num < 0.0 {
        -1.0
    } else if num == 0.0 {
        0.0
    } else {
        1.0
    }
}

/// `MathUtils.lerp` (utils/math_utils.dart).
fn lerp(start: f64, stop: f64, amount: f64) -> f64 {
    (1.0 - amount) * start + amount * stop
}

/// `MathUtils.clampInt` (utils/math_utils.dart).
fn clamp_int(min: i32, max: i32, input: i32) -> i32 {
    if input < min {
        min
    } else if input > max {
        max
    } else {
        input
    }
}

/// `MathUtils.sanitizeDegreesDouble` (utils/math_utils.dart).
fn sanitize_degrees_double(degrees: f64) -> f64 {
    let mut degrees = degrees % 360.0;
    if degrees < 0.0 {
        degrees += 360.0;
    }
    degrees
}

/// `MathUtils.matrixMultiply` (utils/math_utils.dart): 1x3 row · 3x3 matrix.
fn matrix_multiply(row: [f64; 3], matrix: [[f64; 3]; 3]) -> [f64; 3] {
    [
        row[0] * matrix[0][0] + row[1] * matrix[0][1] + row[2] * matrix[0][2],
        row[0] * matrix[1][0] + row[1] * matrix[1][1] + row[2] * matrix[1][2],
        row[0] * matrix[2][0] + row[1] * matrix[2][1] + row[2] * matrix[2][2],
    ]
}

// --- ColorUtils subset (utils/color_utils.dart) ---

/// `ColorUtils._srgbToXyz` (utils/color_utils.dart).
const SRGB_TO_XYZ: [[f64; 3]; 3] = [
    [0.41233895, 0.35762064, 0.18051042],
    [0.2126, 0.7152, 0.0722],
    [0.01932141, 0.11916382, 0.95034478],
];

/// `ColorUtils.redFromArgb` (utils/color_utils.dart).
fn red_from_argb(argb: u32) -> i32 {
    ((argb >> 16) & 255) as i32
}

/// `ColorUtils.greenFromArgb` (utils/color_utils.dart).
fn green_from_argb(argb: u32) -> i32 {
    ((argb >> 8) & 255) as i32
}

/// `ColorUtils.blueFromArgb` (utils/color_utils.dart).
fn blue_from_argb(argb: u32) -> i32 {
    (argb & 255) as i32
}

/// `ColorUtils.argbFromRgb` (utils/color_utils.dart).
fn argb_from_rgb(red: i32, green: i32, blue: i32) -> u32 {
    255u32 << 24 | (((red as u32) & 255) << 16) | (((green as u32) & 255) << 8) | ((blue as u32) & 255)
}

/// `ColorUtils.linearized` (utils/color_utils.dart).
fn linearized(rgb_component: i32) -> f64 {
    let normalized = rgb_component as f64 / 255.0;
    if normalized <= 0.040449936 {
        normalized / 12.92 * 100.0
    } else {
        ((normalized + 0.055) / 1.055).powf(2.4) * 100.0
    }
}

/// `ColorUtils.delinearized` (utils/color_utils.dart).
fn delinearized(rgb_component: f64) -> i32 {
    let normalized = rgb_component / 100.0;
    let delinearized = if normalized <= 0.0031308 {
        normalized * 12.92
    } else {
        1.055 * normalized.powf(1.0 / 2.4) - 0.055
    };
    clamp_int(0, 255, (delinearized * 255.0).round() as i32)
}

/// `ColorUtils.xyzFromArgb` (utils/color_utils.dart).
fn xyz_from_argb(argb: u32) -> [f64; 3] {
    let r = linearized(red_from_argb(argb));
    let g = linearized(green_from_argb(argb));
    let b = linearized(blue_from_argb(argb));
    matrix_multiply([r, g, b], SRGB_TO_XYZ)
}

/// `ColorUtils.argbFromLinrgb` (utils/color_utils.dart).
fn argb_from_linrgb(linrgb: [f64; 3]) -> u32 {
    let r = delinearized(linrgb[0]);
    let g = delinearized(linrgb[1]);
    let b = delinearized(linrgb[2]);
    argb_from_rgb(r, g, b)
}

/// `ColorUtils._labF` (utils/color_utils.dart).
fn lab_f(t: f64) -> f64 {
    let e = 216.0 / 24389.0;
    let kappa = 24389.0 / 27.0;
    if t > e {
        t.powf(1.0 / 3.0)
    } else {
        (kappa * t + 16.0) / 116.0
    }
}

/// `ColorUtils._labInvf` (utils/color_utils.dart).
fn lab_invf(ft: f64) -> f64 {
    let e = 216.0 / 24389.0;
    let kappa = 24389.0 / 27.0;
    let ft3 = ft * ft * ft;
    if ft3 > e {
        ft3
    } else {
        (116.0 * ft - 16.0) / kappa
    }
}

/// `ColorUtils.yFromLstar` (utils/color_utils.dart).
fn y_from_lstar(lstar: f64) -> f64 {
    100.0 * lab_invf((lstar + 16.0) / 116.0)
}

/// `ColorUtils.lstarFromArgb` (utils/color_utils.dart).
fn lstar_from_argb(argb: u32) -> f64 {
    let y = xyz_from_argb(argb)[1];
    116.0 * lab_f(y / 100.0) - 16.0
}

/// `ColorUtils.argbFromLstar` (utils/color_utils.dart).
fn argb_from_lstar(lstar: f64) -> u32 {
    let y = y_from_lstar(lstar);
    let component = delinearized(y);
    argb_from_rgb(component, component, component)
}

// --- ViewingConditions (hct/viewing_conditions.dart) ---

/// `ViewingConditions` (hct/viewing_conditions.dart) — only the derived
/// fields the Cam16/HctSolver chain reads (`make()`'s inputs are resolved
/// into the computation below; Dart's always-zero `drgbInverse` is unused).
struct ViewingConditions {
    background_y_to_white_point_y: f64,
    aw: f64,
    nbb: f64,
    ncb: f64,
    c: f64,
    n_c: f64,
    rgb_d: [f64; 3],
    fl: f64,
    f_l_root: f64,
    z: f64,
}

/// `ViewingConditions.make()` (hct/viewing_conditions.dart) at the sRGB
/// defaults HctSolver and Cam16 use (`ViewingConditions.sRgb`): D65 white
/// point (`ColorUtils.whitePointD65`), default adapting luminance,
/// background L* 50, surround 2.0, no discounting.
fn viewing_conditions_make() -> ViewingConditions {
    let white_point: [f64; 3] = [95.047, 100.0, 108.883];
    let adapting_luminance = 200.0 / PI * y_from_lstar(50.0) / 100.0;
    let background_lstar = f64::max(0.1, 50.0);
    let surround = 2.0;

    // Transform test illuminant white in XYZ to 'cone'/'rgb' responses
    let xyz = white_point;
    let r_w = xyz[0] * 0.401288 + xyz[1] * 0.650173 + xyz[2] * -0.051461;
    let g_w = xyz[0] * -0.250268 + xyz[1] * 1.204414 + xyz[2] * 0.045854;
    let b_w = xyz[0] * -0.002079 + xyz[1] * 0.048952 + xyz[2] * 0.953127;

    // Scale input surround, domain (0, 2), to CAM16 surround, domain (0.8, 1.0)
    let f = 0.8 + (surround / 10.0);
    // "Exponential non-linearity"
    let c = if f >= 0.9 {
        lerp(0.59, 0.69, (f - 0.9) * 10.0)
    } else {
        lerp(0.525, 0.59, (f - 0.8) * 10.0)
    };
    // Calculate degree of adaptation to illuminant
    let mut d = f * (1.0 - ((1.0 / 3.6) * ((-adapting_luminance - 42.0) / 92.0).exp()));
    // Per Li et al, if D is greater than 1 or less than 0, set it to 1 or 0.
    if d > 1.0 {
        d = 1.0;
    } else if d < 0.0 {
        d = 0.0;
    }
    // chromatic induction factor
    let nc = f;

    let rgb_d = [
        d * (100.0 / r_w) + 1.0 - d,
        d * (100.0 / g_w) + 1.0 - d,
        d * (100.0 / b_w) + 1.0 - d,
    ];

    let k = 1.0 / (5.0 * adapting_luminance + 1.0);
    let k4 = k * k * k * k;
    let k4_f = 1.0 - k4;

    // Luminance-level adaptation factor
    let fl = (k4 * adapting_luminance)
        + (0.1 * k4_f * k4_f * (5.0 * adapting_luminance).powf(1.0 / 3.0));
    // Intermediate factor, ratio of background relative luminance to white
    let n = y_from_lstar(background_lstar) / white_point[1];

    // Base exponential nonlinearity
    let z = 1.48 + n.sqrt();

    // Luminance-level induction factors
    let nbb = 0.725 / n.powf(0.2);
    let ncb = nbb;

    let rgb_a_factors = [
        (fl * rgb_d[0] * r_w / 100.0).powf(0.42),
        (fl * rgb_d[1] * g_w / 100.0).powf(0.42),
        (fl * rgb_d[2] * b_w / 100.0).powf(0.42),
    ];
    let rgb_a = [
        (400.0 * rgb_a_factors[0]) / (rgb_a_factors[0] + 27.13),
        (400.0 * rgb_a_factors[1]) / (rgb_a_factors[1] + 27.13),
        (400.0 * rgb_a_factors[2]) / (rgb_a_factors[2] + 27.13),
    ];
    let aw = (40.0 * rgb_a[0] + 20.0 * rgb_a[1] + rgb_a[2]) / 20.0 * nbb;

    ViewingConditions {
        background_y_to_white_point_y: n, aw, nbb, ncb, c, n_c: nc, rgb_d, fl,
        f_l_root: fl.powf(0.25), z,
    }
}

/// `ViewingConditions.sRgb` / `ViewingConditions.standard`
/// (hct/viewing_conditions.dart) — the same object in Dart, built once.
fn s_rgb() -> &'static ViewingConditions {
    static S_RGB: std::sync::OnceLock<ViewingConditions> = std::sync::OnceLock::new();
    S_RGB.get_or_init(viewing_conditions_make)
}

// --- Cam16 (hct/cam16.dart) ---

/// `Cam16` (hct/cam16.dart). `hue`/`chroma` feed Hct; the remaining
/// coordinates come out of the full fromArgb path and are pinned by the
/// in-file tests (chunk 2's roles build on them).
#[allow(dead_code)]
struct Cam16 {
    hue: f64,
    chroma: f64,
    j: f64,
    q: f64,
    m: f64,
    s: f64,
    jstar: f64,
    astar: f64,
    bstar: f64,
}

impl Cam16 {
    /// `Cam16.fromInt` (hct/cam16.dart).
    fn from_int(argb: u32) -> Cam16 {
        Cam16::from_int_in_viewing_conditions(argb, s_rgb())
    }

    /// `Cam16.fromIntInViewingConditions` (hct/cam16.dart).
    fn from_int_in_viewing_conditions(argb: u32, viewing_conditions: &ViewingConditions) -> Cam16 {
        // Transform ARGB int to XYZ
        let xyz = xyz_from_argb(argb);
        Cam16::from_xyz_in_viewing_conditions(xyz[0], xyz[1], xyz[2], viewing_conditions)
    }

    /// `Cam16.fromXyzInViewingConditions` (hct/cam16.dart).
    fn from_xyz_in_viewing_conditions(x: f64, y: f64, z: f64, viewing_conditions: &ViewingConditions) -> Cam16 {
        // Transform XYZ to 'cone'/'rgb' responses
        let r_c = 0.401288 * x + 0.650173 * y - 0.051461 * z;
        let g_c = -0.250268 * x + 1.204414 * y + 0.045854 * z;
        let b_c = -0.002079 * x + 0.048952 * y + 0.953127 * z;

        // Discount illuminant
        let r_d = viewing_conditions.rgb_d[0] * r_c;
        let g_d = viewing_conditions.rgb_d[1] * g_c;
        let b_d = viewing_conditions.rgb_d[2] * b_c;

        // chromatic adaptation
        let r_af = (viewing_conditions.fl * r_d.abs() / 100.0).powf(0.42);
        let g_af = (viewing_conditions.fl * g_d.abs() / 100.0).powf(0.42);
        let b_af = (viewing_conditions.fl * b_d.abs() / 100.0).powf(0.42);
        let r_a = signum(r_d) * 400.0 * r_af / (r_af + 27.13);
        let g_a = signum(g_d) * 400.0 * g_af / (g_af + 27.13);
        let b_a = signum(b_d) * 400.0 * b_af / (b_af + 27.13);

        // redness-greenness
        let a = (11.0 * r_a + -12.0 * g_a + b_a) / 11.0;
        // yellowness-blueness
        let b = (r_a + g_a - 2.0 * b_a) / 9.0;

        // auxiliary components
        let u = (20.0 * r_a + 20.0 * g_a + 21.0 * b_a) / 20.0;
        let p2 = (40.0 * r_a + 20.0 * g_a + b_a) / 20.0;

        // hue
        let atan2 = b.atan2(a);
        let atan_degrees = atan2 * 180.0 / PI;
        let hue = if atan_degrees < 0.0 {
            atan_degrees + 360.0
        } else if atan_degrees >= 360.0 {
            atan_degrees - 360.0
        } else {
            atan_degrees
        };
        let hue_radians = hue * PI / 180.0;

        // achromatic response to color
        let ac = p2 * viewing_conditions.nbb;

        // CAM16 lightness and brightness
        let j = 100.0 * (ac / viewing_conditions.aw).powf(viewing_conditions.c * viewing_conditions.z);
        let q = (4.0 / viewing_conditions.c) * (j / 100.0).sqrt()
            * (viewing_conditions.aw + 4.0) * viewing_conditions.f_l_root;

        let hue_prime = if hue < 20.14 { hue + 360.0 } else { hue };
        let e_hue = (1.0 / 4.0) * ((hue_prime * PI / 180.0 + 2.0).cos() + 3.8);
        let p1 = 50000.0 / 13.0 * e_hue * viewing_conditions.n_c * viewing_conditions.ncb;
        let t = p1 * (a * a + b * b).sqrt() / (u + 0.305);
        let alpha = t.powf(0.9)
            * (1.64 - 0.29_f64.powf(viewing_conditions.background_y_to_white_point_y)).powf(0.73);
        // CAM16 chroma, colorfulness, chroma
        let c = alpha * (j / 100.0).sqrt();
        let m = c * viewing_conditions.f_l_root;
        let s = 50.0 * ((alpha * viewing_conditions.c) / (viewing_conditions.aw + 4.0)).sqrt();

        // CAM16-UCS components
        let jstar = (1.0 + 100.0 * 0.007) * j / (1.0 + 0.007 * j);
        let mstar = (1.0 + 0.0228 * m).ln() / 0.0228;
        let astar = mstar * hue_radians.cos();
        let bstar = mstar * hue_radians.sin();
        Cam16 { hue, chroma: c, j, q, m, s, jstar, astar, bstar }
    }
}

// --- HctSolver (hct/src/hct_solver.dart) ---

/// `HctSolver._scaledDiscountFromLinrgb` (hct/src/hct_solver.dart).
const SCALED_DISCOUNT_FROM_LINRGB: [[f64; 3]; 3] = [
    [0.001200833568784504, 0.002389694492170889, 0.0002795742885861124],
    [0.0005891086651375999, 0.0029785502573438758, 0.0003270666104008398],
    [0.00010146692491640572, 0.0005364214359186694, 0.0032979401770712076],
];

/// `HctSolver._linrgbFromScaledDiscount` (hct/src/hct_solver.dart).
const LINRGB_FROM_SCALED_DISCOUNT: [[f64; 3]; 3] = [
    [1373.2198709594231, -1100.4251190754821, -7.278681089101213],
    [-271.815969077903, 559.6580465940733, -32.46047482791194],
    [1.9622899599665666, -57.173814538844006, 308.7233197812385],
];

/// `HctSolver._yFromLinrgb` (hct/src/hct_solver.dart).
const Y_FROM_LINRGB: [f64; 3] = [0.2126, 0.7152, 0.0722];

/// `HctSolver._criticalPlanes` (hct/src/hct_solver.dart).
const CRITICAL_PLANES: [f64; 255] = [
    0.015176349177441876, 0.045529047532325624, 0.07588174588720938, 0.10623444424209313, 0.13658714259697685, 0.16693984095186062, 0.19729253930674434, 0.2276452376616281,
    0.2579979360165119, 0.28835063437139563, 0.3188300904430532, 0.350925934958123, 0.3848314933096426, 0.42057480301049466, 0.458183274052838, 0.4976837250274023,
    0.5391024159806381, 0.5824650784040898, 0.6277969426914107, 0.6751227633498623, 0.7244668422128921, 0.775853049866786, 0.829304845476233, 0.8848452951698498,
    0.942497089126609, 1.0022825574869039, 1.0642236851973577, 1.1283421258858297, 1.1946592148522128, 1.2631959812511864, 1.3339731595349034, 1.407011200216447,
    1.4823302800086415, 1.5599503113873272, 1.6398909516233677, 1.7221716113234105, 1.8068114625156377, 1.8938294463134073, 1.9832442801866852, 2.075074464868551,
    2.1693382909216234, 2.2660538449872063, 2.36523901573795, 2.4669114995532007, 2.5710888059345764, 2.6777882626779785, 2.7870270208169257, 2.898822059350997,
    3.0131901897720907, 3.1301480604002863, 3.2497121605402226, 3.3718988244681087, 3.4967242352587946, 3.624204428461639, 3.754355295633311, 3.887192587735158,
    4.022731918402185, 4.160988767090289, 4.301978482107941, 4.445716283538092, 4.592217266055746, 4.741496401646282, 4.893568542229298, 5.048448422192488,
    5.20615066083972, 5.3666897647573375, 5.5300801301023865, 5.696336044816294, 5.865471690767354, 6.037501145825082, 6.212438385869475, 6.390297286737924,
    6.571091626112461, 6.7548350853498045, 6.941541251256611, 7.131223617812143, 7.323895587840543, 7.5195704746346665, 7.7182615035334345, 7.919981813454504,
    8.124744458384042, 8.332562408825165, 8.543448553206703, 8.757415699253682, 8.974476575321063, 9.194643831691977, 9.417930041841839, 9.644347703669503,
    9.873909240696694, 10.106627003236781, 10.342513269534024, 10.58158024687427, 10.8238400726681, 11.069304815507364, 11.317986476196008, 11.569896988756009,
    11.825048221409341, 12.083451977536606, 12.345119996613247, 12.610063955123938, 12.878295467455942, 13.149826086772048, 13.42466730586372, 13.702830557985108,
    13.984327217668513, 14.269168601521828, 14.55736596900856, 14.848930523210871, 15.143873411576273, 15.44220572664832, 15.743938506781891, 16.04908273684337,
    16.35764934889634, 16.66964922287304, 16.985093187232053, 17.30399201960269, 17.62635644741625, 17.95219714852476, 18.281524751807332, 18.614349837764564,
    18.95068293910138, 19.290534541298456, 19.633915083172692, 19.98083495742689, 20.331304511189067, 20.685334046541502, 21.042933821039977, 21.404114048223256,
    21.76888489811322, 22.137256497705877, 22.50923893145328, 22.884842241736916, 23.264076429332462, 23.6469514538663, 24.033477234264016, 24.42366364919083,
    24.817520537484558, 25.21505769858089, 25.61628489293138, 26.021211842414342, 26.429848230738664, 26.842203703840827, 27.258287870275353, 27.678110301598522,
    28.10168053274597, 28.529008062403893, 28.96010235337422, 29.39497283293396, 29.83362889318845, 30.276079891419332, 30.722335150426627, 31.172403958865512,
    31.62629557157785, 32.08401920991837, 32.54558406207592, 33.010999283389665, 33.4802739966603, 33.953417292456834, 34.430438229418264, 34.911345834551085,
    35.39614910352207, 35.88485700094671, 36.37747846067349, 36.87402238606382, 37.37449765026789, 37.87891309649659, 38.38727753828926, 38.89959975977785,
    39.41588851594697, 39.93615253289054, 40.460400508064545, 40.98864111053629, 41.520882981230194, 42.05713473317016, 42.597404951718396, 43.141702194811224,
    43.6900349931913, 44.24241185063697, 44.798841244188324, 45.35933162437017, 45.92389141541209, 46.49252901546552, 47.065252796817916, 47.64207110610409,
    48.22299226451468, 48.808024568002054, 49.3971762874833, 49.9904556690408, 50.587870934119984, 51.189430279724725, 51.79514187861014, 52.40501387947288,
    53.0190544071392, 53.637271562750364, 54.259673423945976, 54.88626804504493, 55.517063457223934, 56.15206766869424, 56.79128866487574, 57.43473440856916,
    58.08241284012621, 58.734331877617365, 59.39049941699807, 60.05092333227251, 60.715611475655585, 61.38457167773311, 62.057811747619894, 62.7353394731159,
    63.417162620860914, 64.10328893648692, 64.79372614476921, 65.48848194977529, 66.18756403501224, 66.89098006357258, 67.59873767827808, 68.31084450182222,
    69.02730813691093, 69.74813616640164, 70.47333615344107, 71.20291564160104, 71.93688215501312, 72.67524319850172, 73.41800625771542, 74.16517879925733,
    74.9167682708136, 75.67278210128072, 76.43322770089146, 77.1981124613393, 77.96744375590167, 78.74122893956174, 79.51947534912904, 80.30219030335869,
    81.08938110306934, 81.88105503125999, 82.67721935322541, 83.4778813166706, 84.28304815182372, 85.09272707154808, 85.90692527145302, 86.72564993000343,
    87.54890820862819, 88.3767072518277, 89.2090541872801, 90.04595612594655, 90.88742016217518, 91.73345337380438, 92.58406282226491, 93.43925555268066,
    94.29903859396902, 95.16341895893969, 96.03240364439274, 96.9059996312159, 97.78421388448044, 98.6670533535366, 99.55452497210776
];

/// `HctSolver._sanitizeRadians` (hct/src/hct_solver.dart) — Dart's `%` is
/// the euclidean remainder, so `rem_euclid` is the exact translation.
fn sanitize_radians(angle: f64) -> f64 {
    (angle + PI * 8.0).rem_euclid(PI * 2.0)
}

/// `HctSolver._trueDelinearized` (hct/src/hct_solver.dart).
fn true_delinearized(rgb_component: f64) -> f64 {
    let normalized = rgb_component / 100.0;
    let delinearized = if normalized <= 0.0031308 {
        normalized * 12.92
    } else {
        1.055 * normalized.powf(1.0 / 2.4) - 0.055
    };
    delinearized * 255.0
}

/// `HctSolver._chromaticAdaptation` (hct/src/hct_solver.dart).
fn chromatic_adaptation(component: f64) -> f64 {
    let af = component.abs().powf(0.42);
    signum(component) * 400.0 * af / (af + 27.13)
}

/// `HctSolver._hueOf` (hct/src/hct_solver.dart): hue of a linear RGB color
/// in CAM16, in radians.
fn hue_of(linrgb: [f64; 3]) -> f64 {
    let scaled_discount = matrix_multiply(linrgb, SCALED_DISCOUNT_FROM_LINRGB);
    let r_a = chromatic_adaptation(scaled_discount[0]);
    let g_a = chromatic_adaptation(scaled_discount[1]);
    let b_a = chromatic_adaptation(scaled_discount[2]);
    // redness-greenness
    let a = (11.0 * r_a + -12.0 * g_a + b_a) / 11.0;
    // yellowness-blueness
    let b = (r_a + g_a - 2.0 * b_a) / 9.0;
    b.atan2(a)
}

/// `HctSolver._areInCyclicOrder` (hct/src/hct_solver.dart).
fn are_in_cyclic_order(a: f64, b: f64, c: f64) -> bool {
    let delta_ab = sanitize_radians(b - a);
    let delta_ac = sanitize_radians(c - a);
    delta_ab < delta_ac
}

/// `HctSolver._intercept` (hct/src/hct_solver.dart).
fn intercept(source: f64, mid: f64, target: f64) -> f64 {
    (mid - source) / (target - source)
}

/// `HctSolver._lerpPoint` (hct/src/hct_solver.dart).
fn lerp_point(source: [f64; 3], t: f64, target: [f64; 3]) -> [f64; 3] {
    [
        source[0] + (target[0] - source[0]) * t,
        source[1] + (target[1] - source[1]) * t,
        source[2] + (target[2] - source[2]) * t,
    ]
}

/// `HctSolver._setCoordinate` (hct/src/hct_solver.dart).
fn set_coordinate(source: [f64; 3], coordinate: f64, target: [f64; 3], axis: usize) -> [f64; 3] {
    let t = intercept(source[axis], coordinate, target[axis]);
    lerp_point(source, t, target)
}

/// `HctSolver._isBounded` (hct/src/hct_solver.dart).
fn is_bounded(x: f64) -> bool {
    0.0 <= x && x <= 100.0
}

/// `HctSolver._nthVertex` (hct/src/hct_solver.dart): the nth possible
/// vertex of the Y-plane/cube intersection, or [-1, -1, -1] if outside.
fn nth_vertex(y: f64, n: i32) -> [f64; 3] {
    let k_r = Y_FROM_LINRGB[0];
    let k_g = Y_FROM_LINRGB[1];
    let k_b = Y_FROM_LINRGB[2];
    let coord_a = if n % 4 <= 1 { 0.0 } else { 100.0 };
    let coord_b = if n % 2 == 0 { 0.0 } else { 100.0 };
    if n < 4 {
        let g = coord_a;
        let b = coord_b;
        let r = (y - g * k_g - b * k_b) / k_r;
        if is_bounded(r) {
            [r, g, b]
        } else {
            [-1.0, -1.0, -1.0]
        }
    } else if n < 8 {
        let b = coord_a;
        let r = coord_b;
        let g = (y - r * k_r - b * k_b) / k_g;
        if is_bounded(g) {
            [r, g, b]
        } else {
            [-1.0, -1.0, -1.0]
        }
    } else {
        let r = coord_a;
        let g = coord_b;
        let b = (y - r * k_r - g * k_g) / k_b;
        if is_bounded(b) {
            [r, g, b]
        } else {
            [-1.0, -1.0, -1.0]
        }
    }
}

/// `HctSolver._bisectToSegment` (hct/src/hct_solver.dart): the segment
/// (two endpoints) containing the desired color.
fn bisect_to_segment(y: f64, target_hue: f64) -> [[f64; 3]; 2] {
    let mut left = [-1.0, -1.0, -1.0];
    let mut right = left;
    let mut left_hue = 0.0;
    let mut right_hue = 0.0;
    let mut initialized = false;
    let mut uncut = true;
    for n in 0..12 {
        let mid = nth_vertex(y, n);
        if mid[0] < 0.0 {
            continue;
        }
        let mid_hue = hue_of(mid);
        if !initialized {
            left = mid;
            right = mid;
            left_hue = mid_hue;
            right_hue = mid_hue;
            initialized = true;
            continue;
        }
        if uncut || are_in_cyclic_order(left_hue, mid_hue, right_hue) {
            uncut = false;
            if are_in_cyclic_order(left_hue, target_hue, mid_hue) {
                right = mid;
                right_hue = mid_hue;
            } else {
                left = mid;
                left_hue = mid_hue;
            }
        }
    }
    [left, right]
}

/// `HctSolver._midpoint` (hct/src/hct_solver.dart).
fn midpoint(a: [f64; 3], b: [f64; 3]) -> [f64; 3] {
    [(a[0] + b[0]) / 2.0, (a[1] + b[1]) / 2.0, (a[2] + b[2]) / 2.0]
}

/// `HctSolver._criticalPlaneBelow` (hct/src/hct_solver.dart).
fn critical_plane_below(x: f64) -> i32 {
    (x - 0.5).floor() as i32
}

/// `HctSolver._criticalPlaneAbove` (hct/src/hct_solver.dart).
fn critical_plane_above(x: f64) -> i32 {
    (x - 0.5).ceil() as i32
}

/// `HctSolver._bisectToLimit` (hct/src/hct_solver.dart): the color with the
/// given Y and hue on the boundary of the cube. The Dart source's `-1` /
/// `255` plane sentinels are vestigial (both branches assign), so the
/// initializations are allowed to go unread.
#[allow(unused_assignments)]
fn bisect_to_limit(y: f64, target_hue: f64) -> [f64; 3] {
    let segment = bisect_to_segment(y, target_hue);
    let mut left = segment[0];
    let mut left_hue = hue_of(left);
    let mut right = segment[1];
    for axis in 0..3 {
        if left[axis] != right[axis] {
            let mut l_plane = -1;
            let mut r_plane = 255;
            if left[axis] < right[axis] {
                l_plane = critical_plane_below(true_delinearized(left[axis]));
                r_plane = critical_plane_above(true_delinearized(right[axis]));
            } else {
                l_plane = critical_plane_above(true_delinearized(left[axis]));
                r_plane = critical_plane_below(true_delinearized(right[axis]));
            }
            for _i in 0..8 {
                if (r_plane - l_plane).abs() <= 1 {
                    break;
                } else {
                    let m_plane = ((l_plane + r_plane) as f64 / 2.0).floor() as i32;
                    let mid_plane_coordinate = CRITICAL_PLANES[m_plane as usize];
                    let mid = set_coordinate(left, mid_plane_coordinate, right, axis);
                    let mid_hue = hue_of(mid);
                    if are_in_cyclic_order(left_hue, target_hue, mid_hue) {
                        right = mid;
                        r_plane = m_plane;
                    } else {
                        left = mid;
                        left_hue = mid_hue;
                        l_plane = m_plane;
                    }
                }
            }
        }
    }
    midpoint(left, right)
}

/// `HctSolver._inverseChromaticAdaptation` (hct/src/hct_solver.dart).
fn inverse_chromatic_adaptation(adapted: f64) -> f64 {
    let adapted_abs = adapted.abs();
    let base = f64::max(0.0, 27.13 * adapted_abs / (400.0 - adapted_abs));
    signum(adapted) * base.powf(1.0 / 0.42)
}

/// `HctSolver._findResultByJ` (hct/src/hct_solver.dart): Newton iteration
/// on j (at most 5 rounds, |fn(j) - y| < 0.002 to accept), with the Cam16
/// inversion inlined; returns 0 when the result is not in the cube.
fn find_result_by_j(hue_radians: f64, chroma: f64, y: f64) -> u32 {
    // Initial estimate of j.
    let mut j = y.sqrt() * 11.0;
    let viewing_conditions = s_rgb();
    let t_inner_coeff =
        1.0 / (1.64 - 0.29_f64.powf(viewing_conditions.background_y_to_white_point_y)).powf(0.73);
    let e_hue = 0.25 * ((hue_radians + 2.0).cos() + 3.8);
    let p1 = e_hue * (50000.0 / 13.0) * viewing_conditions.n_c * viewing_conditions.ncb;
    let h_sin = hue_radians.sin();
    let h_cos = hue_radians.cos();
    for iteration_round in 0..5 {
        let j_normalized = j / 100.0;
        let alpha = if chroma == 0.0 || j == 0.0 {
            0.0
        } else {
            chroma / j_normalized.sqrt()
        };
        let t = (alpha * t_inner_coeff).powf(1.0 / 0.9);
        let ac = viewing_conditions.aw
            * j_normalized.powf(1.0 / viewing_conditions.c / viewing_conditions.z);
        let p2 = ac / viewing_conditions.nbb;
        let gamma = 23.0 * (p2 + 0.305) * t / (23.0 * p1 + 11.0 * t * h_cos + 108.0 * t * h_sin);
        let a = gamma * h_cos;
        let b = gamma * h_sin;
        let r_a = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0;
        let g_a = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0;
        let b_a = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0;
        let r_c_scaled = inverse_chromatic_adaptation(r_a);
        let g_c_scaled = inverse_chromatic_adaptation(g_a);
        let b_c_scaled = inverse_chromatic_adaptation(b_a);
        let linrgb = matrix_multiply(
            [r_c_scaled, g_c_scaled, b_c_scaled],
            LINRGB_FROM_SCALED_DISCOUNT,
        );
        if linrgb[0] < 0.0 || linrgb[1] < 0.0 || linrgb[2] < 0.0 {
            return 0;
        }
        let k_r = Y_FROM_LINRGB[0];
        let k_g = Y_FROM_LINRGB[1];
        let k_b = Y_FROM_LINRGB[2];
        let fnj = k_r * linrgb[0] + k_g * linrgb[1] + k_b * linrgb[2];
        if fnj <= 0.0 {
            return 0;
        }
        if iteration_round == 4 || (fnj - y).abs() < 0.002 {
            if linrgb[0] > 100.01 || linrgb[1] > 100.01 || linrgb[2] > 100.01 {
                return 0;
            }
            return argb_from_linrgb(linrgb);
        }
        // Iterates with Newton method,
        // Using 2 * fn(j) / j as the approximation of fn'(j)
        j = j - (fnj - y) * j / (2.0 * fnj);
    }
    0
}

/// `HctSolver.solveToInt` (hct/src/hct_solver.dart): the achromatic /
/// out-of-tone-range short-circuit, then `_findResultByJ`, then the
/// `_bisectToLimit` fallback with chroma maximized.
fn solve_to_int(hue_degrees: f64, chroma: f64, lstar: f64) -> u32 {
    if chroma < 0.0001 || lstar < 0.0001 || lstar > 99.9999 {
        return argb_from_lstar(lstar);
    }
    let hue_degrees = sanitize_degrees_double(hue_degrees);
    let hue_radians = hue_degrees / 180.0 * PI;
    let y = y_from_lstar(lstar);
    let exact_answer = find_result_by_j(hue_radians, chroma, y);
    if exact_answer != 0 {
        return exact_answer;
    }
    let linrgb = bisect_to_limit(y, hue_radians);
    argb_from_linrgb(linrgb)
}

/// `HctSolver.solveToCam` (hct/src/hct_solver.dart) — chunk 2's
/// TonalPalette/scheme code builds on it; pinned by the tests below.
#[allow(dead_code)]
fn solve_to_cam(hue_degrees: f64, chroma: f64, lstar: f64) -> Cam16 {
    Cam16::from_int(solve_to_int(hue_degrees, chroma, lstar))
}

// --- Hct (hct/hct.dart) ---

/// `Hct` (hct/hct.dart): the integer plus its cached hue/chroma/tone.
#[derive(Clone, Copy, Debug)]
pub struct Hct {
    argb: u32,
    hue: f64,
    chroma: f64,
    tone: f64,
}

impl Hct {
    /// `Hct.from` (hct/hct.dart): solve, then cache the coordinates the
    /// returned color actually has (`Hct._(argb)`).
    fn from_hue_chroma_tone(hue: f64, chroma: f64, tone: f64) -> Hct {
        let argb = solve_to_int(hue, chroma, tone);
        let cam16 = Cam16::from_int(argb);
        Hct { argb, hue: cam16.hue, chroma: cam16.chroma, tone: lstar_from_argb(argb) }
    }

    /// `Hct.fromInt` (hct/hct.dart): the color's coordinates via Cam16/L*,
    /// then the solver's canonical argb for them (see the module note).
    pub fn from_int(argb: u32) -> Hct {
        let cam16 = Cam16::from_int(argb);
        Hct::from_hue_chroma_tone(cam16.hue, cam16.chroma, lstar_from_argb(argb))
    }

    /// `Hct.toInt` (hct/hct.dart).
    pub fn to_int(&self) -> u32 {
        self.argb
    }

    /// `Hct.hue` (hct/hct.dart): 0 <= hue < 360.
    pub fn hue(&self) -> f64 {
        self.hue
    }

    /// `Hct.chroma` (hct/hct.dart).
    pub fn chroma(&self) -> f64 {
        self.chroma
    }

    /// `Hct.tone` (hct/hct.dart): L*, 0 <= tone <= 100.
    pub fn tone(&self) -> f64 {
        self.tone
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The 33 seeds of the palette differential corpus, read straight out of
    /// fixtures/palette/cases.json (every expected value there is the
    /// reference implementation's own output; parity admits no tolerance).
    fn corpus_seeds() -> Vec<u32> {
        let text = std::fs::read_to_string("../fixtures/palette/cases.json")
            .expect("fixtures/palette/cases.json readable");
        let mut rest = text.as_str();
        let mut seeds = Vec::new();
        while let Some(i) = rest.find("\"seed\":") {
            rest = rest[i + 7..].trim_start();
            let end = rest
                .find(|c: char| !c.is_ascii_digit())
                .unwrap_or(rest.len());
            seeds.push(rest[..end].parse().unwrap());
            rest = &rest[end..];
        }
        seeds
    }

    #[test]
    fn hct_round_trip_corpus_seeds() {
        let seeds = corpus_seeds();
        assert_eq!(seeds.len(), 33, "corpus seed count");
        for &seed in &seeds {
            assert_eq!(Hct::from_int(seed).to_int(), seed, "round trip {seed:#010x}");
        }
    }

    #[test]
    fn hct_round_trip_primaries() {
        for argb in [0xFF000000, 0xFFFFFFFF, 0xFFFF0000, 0xFF00FF00, 0xFF0000FF] {
            assert_eq!(Hct::from_int(argb).to_int(), argb, "round trip {argb:#010x}");
        }
    }

    #[test]
    fn hct_coordinates_match_reference() {
        // Dart Hct.fromInt at 0xFF00696E (17 significant digits round-trip
        // an f64 exactly).
        let hct = Hct::from_int(0xFF00696E);
        assert_eq!(hct.hue(), 202.23562745518413);
        assert_eq!(hct.chroma(), 34.539780767652616);
        assert_eq!(hct.tone(), 39.963418907273351);

        let black = Hct::from_int(0xFF000000);
        assert_eq!((black.hue(), black.chroma(), black.tone()), (0.0, 0.0, 0.0));

        let white = Hct::from_int(0xFFFFFFFF);
        assert_eq!(white.hue(), 209.49195947383808);
        assert_eq!(white.chroma(), 2.8690352036773992);
        assert_eq!(white.tone(), 100.0);
    }

    #[test]
    fn cam16_full_coordinates_match_reference() {
        // Dart Cam16.fromInt(0xFF00696E) — all nine coordinates.
        let cam = Cam16::from_int(0xFF00696E);
        assert_eq!(cam.hue, 202.23562745518413);
        assert_eq!(cam.chroma, 34.539780767652616);
        assert_eq!(cam.j, 29.520338843833528);
        assert_eq!(cam.q, 84.498745560581042);
        assert_eq!(cam.m, 27.268556543191703);
        assert_eq!(cam.s, 56.807534881128916);
        assert_eq!(cam.jstar, 41.590265022113584);
        assert_eq!(cam.astar, -19.628717765017093);
        assert_eq!(cam.bstar, -8.0245731070684219);
    }

    #[test]
    fn viewing_conditions_defaults_match_reference() {
        // The derived defaults of Dart ViewingConditions.sRgb.
        let vc = s_rgb();
        assert_eq!(vc.background_y_to_white_point_y, 0.18418651851244416);
        assert_eq!(vc.aw, 29.980997194447337);
        assert_eq!(vc.nbb, 1.0169191804458755);
        assert_eq!(vc.ncb, 1.0169191804458755);
        assert_eq!(vc.c, 0.69);
        assert_eq!(vc.n_c, 1.0);
        assert_eq!(vc.rgb_d, [1.02117770275752, 0.9863077294280124, 0.9339605082802299]);
        assert_eq!(vc.fl, 0.38848145378003529);
        assert_eq!(vc.f_l_root, 0.78948261793049368);
        assert_eq!(vc.z, 1.9091695684836520);
    }

    #[test]
    fn solver_matches_reference() {
        // In-gamut solve is exact (the teal seed's own coordinates).
        assert_eq!(solve_to_int(202.23562745518413, 34.539780767652616, 39.963418907273351), 0xFF00696E);
        // Out-of-gamut chroma falls back to the gamut-boundary bisector.
        assert_eq!(solve_to_int(202.23562745518413, 120.0, 50.0), 0xFF00848A);
        // Hues are sanitized into [0, 360).
        assert_eq!(solve_to_int(360.5, 48.0, 60.0), 0xFFD57193);
        assert_eq!(solve_to_int(0.5, 48.0, 60.0), 0xFFD57193);
        // Achromatic / out-of-range tones short-circuit to the L* gray ramp.
        assert_eq!(solve_to_int(180.0, 0.0, 50.0), 0xFF777777);
        assert_eq!(solve_to_int(140.0, 52.0, 100.0), 0xFFFFFFFF);
    }

    #[test]
    fn solve_to_cam_matches_reference() {
        // Dart HctSolver.solveToCam(202.23562745518413, 120.0, 50.0).
        let cam = solve_to_cam(202.23562745518413, 120.0, 50.0);
        assert_eq!(cam.hue, 202.10446137969467);
        assert_eq!(cam.chroma, 39.583168300938880);
        assert_eq!(cam.j, 38.610298138059335);
        assert_eq!(cam.q, 96.636495084068315);
        assert_eq!(cam.m, 31.250223336208560);
        assert_eq!(cam.s, 56.866431703749697);
        assert_eq!(cam.jstar, 51.672005949097318);
        assert_eq!(cam.astar, -21.860396793468663);
        assert_eq!(cam.bstar, -8.8785695491172500);
    }
}

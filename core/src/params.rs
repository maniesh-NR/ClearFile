// SPDX-License-Identifier: GPL-3.0-only
//! TY2025 parameter tables, ported EXACTLY from the Dart reference
//! `clearfile/lib/models/tax_year.dart` (all double-typed values as `f64`,
//! same values, same names in snake_case).
//!
//! Slot order for the per-filing-status tables is the canonical status list
//! also used by the Python oracle (`single`, `marriedJoint`,
//! `marriedSeparate`, `headOfHousehold`, `survivingSpouse`); index with
//! [`FilingStatus::slot`]. The final bracket rung keeps the Dart
//! `double.infinity` upper bound.
//!
//! Sources cross-checked by the reference (see tax_year.dart): IRS VITA
//! standard-deduction page, Tax Foundation 2025 brackets, IRS newsroom
//! senior deduction (P.L. 119-21 / OBBBA), Instructions for Form 1040
//! (2025) qualified-dividend breakpoints, Instructions for Form 8960
//! (2025), Schedule 8812 (2025), student-loan phaseout tables.
//!
//! DEMONSTRATION SOFTWARE: verify every number against official IRS tables
//! before relying on any calculation produced with this module.

/// One rung of a progressive rate schedule (Dart `Bracket`).
///
/// `up_to` is the upper bound of taxable income for this rung (INCLUSIVE in
/// both reference engines); the final rung uses [`f64::INFINITY`], matching
/// the Dart `double.infinity`.
#[derive(Clone, Copy, Debug)]
pub struct Bracket {
    /// Marginal rate, e.g. `0.10` for 10%.
    pub rate: f64,
    /// Upper bound of taxable income for this rung (inclusive).
    pub up_to: f64,
}

/// All federal parameters the demo engine needs for one tax year
/// (Dart `TaxYearParameters`), with the `saltCapFor` /
/// `studentLoanPhaseoutWidth` helpers ported alongside.
#[derive(Clone, Copy, Debug)]
pub struct TaxYearParameters {
    pub year: i64,

    /// Basic standard deduction by filing status (OBBBA amounts for 2025).
    pub standard_deduction: [f64; 5],

    /// Additional standard deduction per person who is 65+ or blind
    /// (standard-deduction route only). IRS VITA: $2,000 single/HoH,
    /// $1,600 married per person for 2025.
    pub additional_per_aged_or_blind_person: [f64; 5],

    /// OBBBA "senior deduction": $6,000 per person 65+ for 2025-2028, usable
    /// with the standard deduction OR itemizing, phased out at 6% of MAGI
    /// over the phaseout start.
    pub senior_deduction_per_person: f64,
    pub senior_phaseout_start: [f64; 5],
    pub senior_phaseout_rate: f64,

    /// Ordinary income rate schedules, by filing status slot.
    pub ordinary_brackets: [[Bracket; 7]; 5],

    /// Qualified dividends / net long-term capital gains: top of the 0% band
    /// and top of the 15% band, by filing status (stacked on ordinary
    /// income). Breakpoints are the Qualified Dividends and Capital Gain Tax
    /// Worksheet lines 6 and 13 in the Instructions for Form 1040 (2025).
    /// NOTE the MFS 15% cap is a flat $300,000 by statute — NOT half of the
    /// $600,050 MFJ breakpoint (a previous 300,025 value was corrected by
    /// the golden fixtures, 2026-11-14).
    pub qdi_zero_cap: [f64; 5],
    pub qdi_fifteen_cap: [f64; 5],

    /// SALT cap (OBBBA): $40,000 for 2025 ($20,000 MFS), reduced by 30% of
    /// MAGI over the phaseout start, never below the floor.
    pub salt_base_cap: [f64; 5],
    pub salt_phaseout_start: [f64; 5],
    pub salt_phaseout_rate: f64,
    pub salt_floor: [f64; 5],

    /// Net investment income tax (simplified: applied to interest, dividends
    /// and capital gains). Thresholds per the Instructions for Form 8960
    /// (2025): $250,000 MFJ/QSS, $200,000 single/HoH, $125,000 MFS.
    pub niit_rate: f64,
    pub niit_threshold: [f64; 5],

    /// Child Tax Credit / Additional Child Tax Credit (OBBBA: $2,200 per
    /// child for 2025, up to $1,700 per child refundable).
    pub ctc_per_child: f64,
    pub actc_per_child: f64,
    pub actc_rate: f64,
    pub actc_earned_income_floor: f64,
    pub ctc_phaseout_start: [f64; 5],
    pub ctc_phaseout_rate: f64,

    /// Credit for other dependents.
    pub odc_per_dependent: f64,

    /// Student loan interest deduction. MFS is not eligible; that is encoded
    /// as start=1.0 > end=0.0 exactly as in the Dart table (the engine
    /// treats `end <= start` as ineligible).
    pub student_loan_max: f64,
    pub student_loan_phaseout_start: [f64; 5],
    pub student_loan_phaseout_end: [f64; 5],

    /// Charitable deduction AGI ceilings (simplified).
    pub charitable_cash_agi_limit: f64,
    pub charitable_non_cash_agi_limit: f64,
}

impl TaxYearParameters {
    /// The JSON serialization (the N6 wasm lane's parameter-table service:
    /// `clearfile_params_json` — the table's ONE true source, the TS config
    /// table's retirement channel). The field names + the per-status keys
    /// mirror the TS `TaxYearParameters` interface exactly (config.ts);
    /// the last bracket rung's infinite `up_to` serializes as `null` (the
    /// TS `Bracket.upTo: number | null`; strict JSON cannot carry
    /// Infinity).
    pub fn to_json(&self) -> crate::json::Json {
        use crate::json::Json;
        const STATUS_KEYS: [&str; 5] = [
            "single",
            "marriedJoint",
            "marriedSeparate",
            "headOfHousehold",
            "survivingSpouse",
        ];
        fn by_status(values: &[f64; 5]) -> Json {
            use crate::json::Json;
            Json::Obj(
                (0..5)
                    .map(|i| {
                        (
                            ["single", "marriedJoint", "marriedSeparate", "headOfHousehold", "survivingSpouse"][i].to_string(),
                            Json::Num(values[i]),
                        )
                    })
                    .collect(),
            )
        }
        fn brackets_by_status(schedules: &[[Bracket; 7]; 5]) -> Json {
            use crate::json::Json;
            Json::Obj(
                (0..5)
                    .map(|i| {
                        (
                            ["single", "marriedJoint", "marriedSeparate", "headOfHousehold", "survivingSpouse"][i].to_string(),
                            Json::Arr(
                                schedules[i]
                                    .iter()
                                    .map(|br| {
                                        Json::Obj(vec![
                                            ("rate".to_string(), Json::Num(br.rate)),
                                            (
                                                "upTo".to_string(),
                                                if br.up_to.is_finite() {
                                                    Json::Num(br.up_to)
                                                } else {
                                                    Json::Null
                                                },
                                            ),
                                        ])
                                    })
                                    .collect(),
                            ),
                        )
                    })
                    .collect(),
            )
        }
        let _ = STATUS_KEYS;
        Json::Obj(vec![
            ("year".to_string(), Json::Num(self.year as f64)),
            ("standardDeduction".to_string(), by_status(&self.standard_deduction)),
            (
                "additionalPerAgedOrBlindPerson".to_string(),
                by_status(&self.additional_per_aged_or_blind_person),
            ),
            ("seniorDeductionPerPerson".to_string(), Json::Num(self.senior_deduction_per_person)),
            ("seniorPhaseoutStart".to_string(), by_status(&self.senior_phaseout_start)),
            ("seniorPhaseoutRate".to_string(), Json::Num(self.senior_phaseout_rate)),
            ("ordinaryBrackets".to_string(), brackets_by_status(&self.ordinary_brackets)),
            ("qdiZeroCap".to_string(), by_status(&self.qdi_zero_cap)),
            ("qdiFifteenCap".to_string(), by_status(&self.qdi_fifteen_cap)),
            ("saltBaseCap".to_string(), by_status(&self.salt_base_cap)),
            ("saltPhaseoutStart".to_string(), by_status(&self.salt_phaseout_start)),
            ("saltPhaseoutRate".to_string(), Json::Num(self.salt_phaseout_rate)),
            ("saltFloor".to_string(), by_status(&self.salt_floor)),
            ("niitRate".to_string(), Json::Num(self.niit_rate)),
            ("niitThreshold".to_string(), by_status(&self.niit_threshold)),
            ("ctcPerChild".to_string(), Json::Num(self.ctc_per_child)),
            ("actcPerChild".to_string(), Json::Num(self.actc_per_child)),
            ("actcRate".to_string(), Json::Num(self.actc_rate)),
            ("actcEarnedIncomeFloor".to_string(), Json::Num(self.actc_earned_income_floor)),
            ("ctcPhaseoutStart".to_string(), by_status(&self.ctc_phaseout_start)),
            ("ctcPhaseoutRate".to_string(), Json::Num(self.ctc_phaseout_rate)),
            ("odcPerDependent".to_string(), Json::Num(self.odc_per_dependent)),
            ("studentLoanMax".to_string(), Json::Num(self.student_loan_max)),
            ("studentLoanPhaseoutStart".to_string(), by_status(&self.student_loan_phaseout_start)),
            ("studentLoanPhaseoutEnd".to_string(), by_status(&self.student_loan_phaseout_end)),
            ("charitableCashAgiLimit".to_string(), Json::Num(self.charitable_cash_agi_limit)),
            ("charitableNonCashAgiLimit".to_string(), Json::Num(self.charitable_non_cash_agi_limit)),
        ])
    }

    /// Dart `saltCapFor`: the OBBBA SALT cap for `status` at MAGI `magi` —
    /// base cap, reduced by 30% of MAGI over the phaseout start, floored.
    /// The comparison structure is ported verbatim (`reduced < floor` picks
    /// the floor; no `max` call, so NaN semantics cannot sneak in here).
    pub fn salt_cap_for(&self, status: crate::FilingStatus, magi: f64) -> f64 {
        let slot = status.slot();
        let base = self.salt_base_cap[slot];
        let start = self.salt_phaseout_start[slot];
        let floor = self.salt_floor[slot];
        if magi <= start {
            return base;
        }
        let reduced = base - self.salt_phaseout_rate * (magi - start);
        if reduced < floor {
            floor
        } else {
            reduced
        }
    }

    /// Width of the student loan interest phase-out band (0 means
    /// ineligible). Ported from Dart `studentLoanPhaseoutWidth`.
    pub fn student_loan_phaseout_width(&self, status: crate::FilingStatus) -> f64 {
        let slot = status.slot();
        self.student_loan_phaseout_end[slot] - self.student_loan_phaseout_start[slot]
    }
}

/// The TY2025 parameter set (Dart `TaxYearParameters.ty2025`).
///
/// Values transcribed 1:1 from `tax_year.dart:154-301`.
pub const TY2025: TaxYearParameters = TaxYearParameters {
    year: 2025,
    standard_deduction: [15750.0, 31500.0, 15750.0, 23625.0, 31500.0],
    additional_per_aged_or_blind_person: [2000.0, 1600.0, 1600.0, 2000.0, 1600.0],
    senior_deduction_per_person: 6000.0,
    senior_phaseout_start: [75000.0, 150000.0, 75000.0, 75000.0, 150000.0],
    senior_phaseout_rate: 0.06,
    ordinary_brackets: [
        // single
        [
            Bracket { rate: 0.10, up_to: 11925.0 },
            Bracket { rate: 0.12, up_to: 48475.0 },
            Bracket { rate: 0.22, up_to: 103350.0 },
            Bracket { rate: 0.24, up_to: 197300.0 },
            Bracket { rate: 0.32, up_to: 250525.0 },
            Bracket { rate: 0.35, up_to: 626350.0 },
            Bracket { rate: 0.37, up_to: f64::INFINITY },
        ],
        // marriedJoint
        [
            Bracket { rate: 0.10, up_to: 23850.0 },
            Bracket { rate: 0.12, up_to: 96950.0 },
            Bracket { rate: 0.22, up_to: 206700.0 },
            Bracket { rate: 0.24, up_to: 394600.0 },
            Bracket { rate: 0.32, up_to: 501050.0 },
            Bracket { rate: 0.35, up_to: 751600.0 },
            Bracket { rate: 0.37, up_to: f64::INFINITY },
        ],
        // marriedSeparate
        [
            Bracket { rate: 0.10, up_to: 11925.0 },
            Bracket { rate: 0.12, up_to: 48475.0 },
            Bracket { rate: 0.22, up_to: 103350.0 },
            Bracket { rate: 0.24, up_to: 197300.0 },
            Bracket { rate: 0.32, up_to: 250525.0 },
            Bracket { rate: 0.35, up_to: 375800.0 },
            Bracket { rate: 0.37, up_to: f64::INFINITY },
        ],
        // headOfHousehold
        [
            Bracket { rate: 0.10, up_to: 17000.0 },
            Bracket { rate: 0.12, up_to: 64850.0 },
            Bracket { rate: 0.22, up_to: 103350.0 },
            Bracket { rate: 0.24, up_to: 197300.0 },
            Bracket { rate: 0.32, up_to: 250500.0 },
            Bracket { rate: 0.35, up_to: 626350.0 },
            Bracket { rate: 0.37, up_to: f64::INFINITY },
        ],
        // survivingSpouse
        [
            Bracket { rate: 0.10, up_to: 23850.0 },
            Bracket { rate: 0.12, up_to: 96950.0 },
            Bracket { rate: 0.22, up_to: 206700.0 },
            Bracket { rate: 0.24, up_to: 394600.0 },
            Bracket { rate: 0.32, up_to: 501050.0 },
            Bracket { rate: 0.35, up_to: 751600.0 },
            Bracket { rate: 0.37, up_to: f64::INFINITY },
        ],
    ],
    qdi_zero_cap: [48350.0, 96700.0, 48350.0, 64750.0, 96700.0],
    qdi_fifteen_cap: [533400.0, 600050.0, 300000.0, 566700.0, 600050.0],
    salt_base_cap: [40000.0, 40000.0, 20000.0, 40000.0, 40000.0],
    salt_phaseout_start: [500000.0, 500000.0, 250000.0, 500000.0, 500000.0],
    salt_phaseout_rate: 0.30,
    salt_floor: [10000.0, 10000.0, 5000.0, 10000.0, 10000.0],
    niit_rate: 0.038,
    niit_threshold: [200000.0, 250000.0, 125000.0, 200000.0, 250000.0],
    ctc_per_child: 2200.0,
    actc_per_child: 1700.0,
    actc_rate: 0.15,
    actc_earned_income_floor: 2500.0,
    // Schedule 8812 (2025) line 9: "Married filing jointly—$400,000 / All
    // other filing statuses—$200,000" — a qualifying surviving spouse is an
    // other filing status (corrected by the QSS golden fixture 2026-11-22).
    ctc_phaseout_start: [200000.0, 400000.0, 200000.0, 200000.0, 200000.0],
    ctc_phaseout_rate: 0.05,
    odc_per_dependent: 500.0,
    student_loan_max: 2500.0,
    student_loan_phaseout_start: [85000.0, 170000.0, 1.0, 85000.0, 85000.0],
    student_loan_phaseout_end: [100000.0, 200000.0, 0.0, 100000.0, 100000.0],
    charitable_cash_agi_limit: 0.60,
    charitable_non_cash_agi_limit: 0.30,
};

#[cfg(test)]
mod tests {
    use super::*;
    use crate::FilingStatus;

    /// Guard the transcribed tables against silent edits: a handful of
    /// spot values read straight off tax_year.dart.
    #[test]
    fn ty2025_tables_match_the_dart_reference() {
        assert_eq!(TY2025.year, 2025);
        assert_eq!(TY2025.standard_deduction[FilingStatus::Single.slot()], 15750.0);
        assert_eq!(TY2025.standard_deduction[FilingStatus::HeadOfHousehold.slot()], 23625.0);
        assert_eq!(TY2025.additional_per_aged_or_blind_person[FilingStatus::MarriedJoint.slot()], 1600.0);
        assert_eq!(TY2025.senior_deduction_per_person, 6000.0);
        // MFS QDI 15% cap is a flat $300,000 (golden-fixture correction).
        assert_eq!(TY2025.qdi_fifteen_cap[FilingStatus::MarriedSeparate.slot()], 300000.0);
        // MFS NIIT threshold $125,000 (golden-fixture correction).
        assert_eq!(TY2025.niit_threshold[FilingStatus::MarriedSeparate.slot()], 125000.0);
        // QSS CTC phase-out start is $200,000, NOT the MFJ $400,000.
        assert_eq!(TY2025.ctc_phaseout_start[FilingStatus::SurvivingSpouse.slot()], 200000.0);
        // MFS SALT cap $20,000 / floor $5,000.
        assert_eq!(TY2025.salt_base_cap[FilingStatus::MarriedSeparate.slot()], 20000.0);
        assert_eq!(TY2025.salt_floor[FilingStatus::MarriedSeparate.slot()], 5000.0);
        // MFS student-loan ineligibility encoded as start=1 > end=0.
        assert_eq!(TY2025.student_loan_phaseout_start[FilingStatus::MarriedSeparate.slot()], 1.0);
        assert_eq!(TY2025.student_loan_phaseout_end[FilingStatus::MarriedSeparate.slot()], 0.0);
        // Final rungs are infinite, like the Dart double.infinity.
        for row in &TY2025.ordinary_brackets {
            assert_eq!(row[6].up_to, f64::INFINITY);
            assert_eq!(row[6].rate, 0.37);
        }
        // Single 10% rung upper bound (the ENG-adv boundary bracket).
        assert_eq!(TY2025.ordinary_brackets[FilingStatus::Single.slot()][0].up_to, 11925.0);
        assert_eq!(TY2025.ordinary_brackets[FilingStatus::Single.slot()][0].rate, 0.10);
    }

    #[test]
    fn salt_cap_for_matches_the_dart_structure() {
        // At/below the phaseout start: the plain base cap.
        assert_eq!(TY2025.salt_cap_for(FilingStatus::Single, 500000.0), 40000.0);
        // Above it: reduced 30%-per-dollar, never below the floor.
        // 40000 - 0.30 * (500100 - 500000) = 40000 - 30 = 39970.
        assert_eq!(TY2025.salt_cap_for(FilingStatus::Single, 500100.0), 39970.0);
        // MFJ deep past the start: floored at $10,000.
        assert_eq!(TY2025.salt_cap_for(FilingStatus::MarriedJoint, 600000.0), 10000.0);
        // MFS floor is $5,000.
        assert_eq!(TY2025.salt_cap_for(FilingStatus::MarriedSeparate, 300000.0), 5000.0);
    }

    #[test]
    fn student_loan_phaseout_width_zero_for_mfs() {
        assert_eq!(TY2025.student_loan_phaseout_width(FilingStatus::MarriedSeparate), -1.0);
        assert_eq!(TY2025.student_loan_phaseout_width(FilingStatus::Single), 15000.0);
    }
}

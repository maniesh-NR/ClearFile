// SPDX-License-Identifier: GPL-3.0-only
//! ClearFile core: a std-only Rust port of the TY2025 demo tax engine's
//! ordinary-income path, ported whole from the Dart reference
//! (`clearfile/lib/tax/calculator.dart`, 325 lines — SLI, SALT,
//! deduction-choice, QDI/LTCG stacking, NIIT, CTC/ACTC/ODC and payments
//! are ALL included, per the N1 entry gate ENG-4).
//!
//! Module layout (no I/O anywhere in the library — pure functions only):
//! - [`params`]: the TY2025 parameter tables (`tax_year.dart`).
//! - [`engine`]: the compute pipeline (`calculator.dart`).
//!
//! The input model mirrors the golden-fixture input schema exactly (the
//! `TaxReturnData` JSON shape in `fixtures/tax/*.json`); the result struct
//! carries every field the fixtures' `expected` objects can pin, named
//! like the fixture keys in snake_case.
//!
//! Semantics notes the port must preserve (N1 entry gate):
//! - `hasSpouse` is NOT a generic spouse flag: it is exactly
//!   `status == MarriedJoint` (Dart `tax_return.dart:107`, the oracle's
//!   `status == "marriedJoint"`). See [`FilingStatus::has_spouse`].
//! - The effective rate keeps the Dart `agi > 0` guard
//!   (`calculator.dart:155`): zero/negative AGI yields `0.0`, never NaN
//!   (fixture 00 pins `effectiveRate: 0`).

pub mod engine;
pub mod params;

pub use engine::{compute, compute_ty2025};
pub use params::{Bracket, TaxYearParameters, TY2025};

/// Federal filing statuses (Dart `FilingStatus`).
///
/// Slot order is the canonical status list shared by the parameter tables
/// and the Python oracle's `STATUS_LIST`: single, marriedJoint,
/// marriedSeparate, headOfHousehold, survivingSpouse.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum FilingStatus {
    Single = 0,
    MarriedJoint = 1,
    MarriedSeparate = 2,
    HeadOfHousehold = 3,
    SurvivingSpouse = 4,
}

impl FilingStatus {
    /// Index into the per-status parameter tables.
    pub fn slot(self) -> usize {
        self as usize
    }

    /// The JSON/Dart enum name used by the fixtures (`jsonName == name`).
    pub fn name(self) -> &'static str {
        match self {
            FilingStatus::Single => "single",
            FilingStatus::MarriedJoint => "marriedJoint",
            FilingStatus::MarriedSeparate => "marriedSeparate",
            FilingStatus::HeadOfHousehold => "headOfHousehold",
            FilingStatus::SurvivingSpouse => "survivingSpouse",
        }
    }

    /// Dart `TaxReturnData.hasSpouse`: EXACTLY `status == marriedJoint` —
    /// not a generic spouse flag. Qualifying surviving spouse does NOT
    /// count as having a spouse for the senior/aged-or-blind additions.
    pub fn has_spouse(self) -> bool {
        self == FilingStatus::MarriedJoint
    }

    /// Strict parse of the fixture's `filingStatus` value. Unlike the Dart
    /// loader (which silently defaults unknown names to `single`), unknown
    /// names are an error; the strictness lives in the test harness reader
    /// (`core/tests/`), which calls this.
    pub fn from_json_name(value: &str) -> Option<FilingStatus> {
        match value {
            "single" => Some(FilingStatus::Single),
            "marriedJoint" => Some(FilingStatus::MarriedJoint),
            "marriedSeparate" => Some(FilingStatus::MarriedSeparate),
            "headOfHousehold" => Some(FilingStatus::HeadOfHousehold),
            "survivingSpouse" => Some(FilingStatus::SurvivingSpouse),
            _ => None,
        }
    }
}

/// How the taxpayer wants their deduction determined (Dart
/// `DeductionMethod`). `Auto` compares both totals and picks itemized only
/// when itemized is STRICTLY greater.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum DeductionMethod {
    Auto,
    Standard,
    Itemized,
}

impl DeductionMethod {
    /// The JSON/Dart enum name used by the fixtures.
    pub fn name(self) -> &'static str {
        match self {
            DeductionMethod::Auto => "auto",
            DeductionMethod::Standard => "standard",
            DeductionMethod::Itemized => "itemized",
        }
    }

    /// Strict parse of the fixture's `deductionMethod` value. Unlike the
    /// Dart loader (which silently defaults unknown names to `auto`),
    /// unknown names are an error in the test harness reader.
    pub fn from_json_name(value: &str) -> Option<DeductionMethod> {
        match value {
            "auto" => Some(DeductionMethod::Auto),
            "standard" => Some(DeductionMethod::Standard),
            "itemized" => Some(DeductionMethod::Itemized),
            _ => None,
        }
    }
}

/// One W-2 wage statement: only the boxes the demo engine consumes
/// (Dart `W2Entry`: Box 1 wages, Box 2 federal income tax withheld).
#[derive(Clone, Debug, PartialEq)]
pub struct W2Entry {
    pub employer: String,
    pub wages: f64,
    pub withholding: f64,
}

/// A person claimed as a dependent (Dart `Dependent`): the two
/// plain-language credit questions the demo engine asks.
#[derive(Clone, Debug, PartialEq)]
pub struct Dependent {
    pub name: String,
    pub age: i64,
    pub relationship: String,
    /// Qualifying child under 17 (Child Tax Credit, $2,200 per child).
    pub qualifying_child: bool,
    /// Credit for Other Dependents ($500).
    pub other_dependent_credit: bool,
}

/// Everything one taxpayer's return contains for the engine — the Rust
/// mirror of the golden fixtures' `input` object (the `TaxReturnData`
/// JSON schema, minus the serialization-only fields the compute path
/// ignores: `id`, `displayName`, timestamps).
#[derive(Clone, Debug, PartialEq)]
pub struct TaxReturnInput {
    pub tax_year: i64,
    pub filing_status: FilingStatus,

    // --- About you ---------------------------------------------------------
    pub taxpayer_65_or_older: bool,
    pub spouse_65_or_older: bool,
    pub taxpayer_blind: bool,
    pub spouse_blind: bool,

    // --- Income ------------------------------------------------------------
    pub w2s: Vec<W2Entry>,
    pub interest_income: f64,
    /// Dividends that are NOT qualified (taxed as ordinary income).
    pub ordinary_dividends: f64,
    pub qualified_dividends: f64,
    pub long_term_capital_gains: f64,
    pub other_income: f64,

    // --- Adjustments -------------------------------------------------------
    pub student_loan_interest: f64,

    // --- Deductions --------------------------------------------------------
    pub deduction_method: DeductionMethod,
    pub state_local_income_or_sales_tax: f64,
    pub real_estate_tax: f64,
    pub mortgage_interest: f64,
    pub charitable_cash: f64,
    pub charitable_non_cash: f64,

    // --- Payments ----------------------------------------------------------
    pub estimated_payments: f64,

    // --- Dependents --------------------------------------------------------
    pub dependents: Vec<Dependent>,
}

impl TaxReturnInput {
    /// Dart `totalWages`: `w2s.fold(0, (sum, w) => sum + w.wages)` — a LEFT
    /// fold in the Dart list order. The fold's operation order is
    /// load-bearing (f64 non-associativity, gate trap ENG-5a).
    pub fn total_wages(&self) -> f64 {
        self.w2s.iter().fold(0.0, |sum, w| sum + w.wages)
    }

    /// Dart `totalWithholding`: same left fold over withholding.
    pub fn total_withholding(&self) -> f64 {
        self.w2s.iter().fold(0.0, |sum, w| sum + w.withholding)
    }

    /// Dart `totalIncome`: wages + interest + ordinary dividends +
    /// qualified dividends + LTCG + other income, left-associated in
    /// exactly that order.
    pub fn total_income(&self) -> f64 {
        self.total_wages()
            + self.interest_income
            + self.ordinary_dividends
            + self.qualified_dividends
            + self.long_term_capital_gains
            + self.other_income
    }
}

/// Outcome of running [`compute`] — the Rust mirror of Dart `TaxResult`,
/// with fields named like the golden fixtures' `expected` keys in
/// snake_case. Every field any fixture pins is present.
#[derive(Clone, Debug, PartialEq)]
pub struct TaxResult {
    pub total_income: f64,
    pub student_loan_deduction: f64,
    pub agi: f64,

    pub basic_standard_deduction: f64,
    pub additional_standard_deduction: f64,
    pub senior_deduction: f64,
    pub standard_deduction_total: f64,

    pub salt_paid: f64,
    pub salt_cap: f64,
    pub salt_allowed: f64,
    pub itemized_deduction_total: f64,

    /// Enum name compared by EXACT STRING against a fixture pin
    /// (`"standard"` / `"itemized"` — `auto` never survives the choice).
    pub deduction_method_used: DeductionMethod,
    pub deduction_used: f64,

    pub taxable_income: f64,
    pub ordinary_tax: f64,
    pub preferential_income: f64,
    pub preferential_tax: f64,
    pub niit: f64,

    pub non_refundable_credits: f64,
    pub refundable_credits: f64,
    pub total_tax: f64,
    pub total_payments: f64,

    pub refund: f64,
    pub amount_owed: f64,
    pub effective_rate: f64,
    pub marginal_rate: f64,
    pub qualifying_children: i64,
}

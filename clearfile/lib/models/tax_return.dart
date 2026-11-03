import 'dart:math';

import 'dependent.dart';
import 'filing_status.dart';
import 'json_codec.dart';
import 'w2.dart';

/// How the taxpayer wants their deduction determined.
///
/// [auto] lets ClearFile pick whichever produces the lower tax, mirroring the
/// "we'll compare for you" behaviour people liked in IRS DirectFile.
enum DeductionMethod {
  auto('Compare and pick the better one'),
  standard('Use the standard deduction'),
  itemized('Itemize my deductions');

  const DeductionMethod(this.label);
  final String label;

  static DeductionMethod fromJsonName(String? value) {
    for (final m in DeductionMethod.values) {
      if (m.name == value) return m;
    }
    return DeductionMethod.auto;
  }
}

/// Everything one taxpayer's return contains. This is the object that is
/// serialized to ClearFile's open JSON file format and autosaved locally.
class TaxReturnData {
  TaxReturnData({
    String? id,
    this.displayName = 'My 2025 return',
    this.taxYear = 2025,
    this.filingStatus = FilingStatus.single,
    this.taxpayer65OrOlder = false,
    this.spouse65OrOlder = false,
    this.taxpayerBlind = false,
    this.spouseBlind = false,
    List<W2Entry>? w2s,
    this.interestIncome = 0,
    this.ordinaryDividends = 0,
    this.qualifiedDividends = 0,
    this.longTermCapitalGains = 0,
    this.otherIncome = 0,
    this.studentLoanInterest = 0,
    this.deductionMethod = DeductionMethod.auto,
    this.stateLocalIncomeOrSalesTax = 0,
    this.realEstateTax = 0,
    this.mortgageInterest = 0,
    this.charitableCash = 0,
    this.charitableNonCash = 0,
    this.estimatedPayments = 0,
    List<Dependent>? dependents,
    DateTime? created,
    DateTime? modified,
  })  : id = id ??
            DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
                Random().nextInt(0xffff).toRadixString(36),
        w2s = w2s ?? [],
        dependents = dependents ?? [],
        created = created ?? DateTime.now(),
        modified = modified ?? DateTime.now();

  final String id;
  String displayName;
  int taxYear;
  FilingStatus filingStatus;

  // --- About you -----------------------------------------------------------
  bool taxpayer65OrOlder;
  bool spouse65OrOlder;
  bool taxpayerBlind;
  bool spouseBlind;

  // --- Income --------------------------------------------------------------
  List<W2Entry> w2s;
  double interestIncome;

  /// Dividends that are NOT qualified (taxed as ordinary income). Qualified
  /// dividends are captured separately to avoid double counting.
  double ordinaryDividends;
  double qualifiedDividends;
  double longTermCapitalGains;
  double otherIncome;

  // --- Adjustments ---------------------------------------------------------
  double studentLoanInterest;

  // --- Deductions ----------------------------------------------------------
  DeductionMethod deductionMethod;
  double stateLocalIncomeOrSalesTax;
  double realEstateTax;
  double mortgageInterest;
  double charitableCash;
  double charitableNonCash;

  // --- Payments ------------------------------------------------------------
  double estimatedPayments;

  List<Dependent> dependents;

  final DateTime created;
  DateTime modified;

  bool get hasSpouse => filingStatus == FilingStatus.marriedJoint;

  double get totalWages => w2s.fold(0, (sum, w) => sum + w.wages);

  double get totalWithholding => w2s.fold(0, (sum, w) => sum + w.withholding);

  double get totalIncome => totalWages +
      interestIncome +
      ordinaryDividends +
      qualifiedDividends +
      longTermCapitalGains +
      otherIncome;

  Map<String, dynamic> toJson() => {
        'format': 'clearfile.return',
        'formatVersion': 1,
        'id': id,
        'displayName': displayName,
        'taxYear': taxYear,
        'filingStatus': filingStatus.jsonName,
        'taxpayer65OrOlder': taxpayer65OrOlder,
        'spouse65OrOlder': spouse65OrOlder,
        'taxpayerBlind': taxpayerBlind,
        'spouseBlind': spouseBlind,
        'w2s': w2s.map((w) => w.toJson()).toList(),
        'interestIncome': interestIncome,
        'ordinaryDividends': ordinaryDividends,
        'qualifiedDividends': qualifiedDividends,
        'longTermCapitalGains': longTermCapitalGains,
        'otherIncome': otherIncome,
        'studentLoanInterest': studentLoanInterest,
        'deductionMethod': deductionMethod.name,
        'stateLocalIncomeOrSalesTax': stateLocalIncomeOrSalesTax,
        'realEstateTax': realEstateTax,
        'mortgageInterest': mortgageInterest,
        'charitableCash': charitableCash,
        'charitableNonCash': charitableNonCash,
        'estimatedPayments': estimatedPayments,
        'dependents': dependents.map((d) => d.toJson()).toList(),
        'created': created.toIso8601String(),
        'modified': modified.toIso8601String(),
      };

  static TaxReturnData fromJson(Map<String, dynamic> json) => TaxReturnData(
        id: readString(json, 'id'),
        displayName: readString(json, 'displayName', 'Imported return'),
        taxYear: readInt(json, 'taxYear', 2025),
        filingStatus: FilingStatus.fromJsonName(json['filingStatus'] as String?),
        taxpayer65OrOlder: readBool(json, 'taxpayer65OrOlder'),
        spouse65OrOlder: readBool(json, 'spouse65OrOlder'),
        taxpayerBlind: readBool(json, 'taxpayerBlind'),
        spouseBlind: readBool(json, 'spouseBlind'),
        w2s: (json['w2s'] as List? ?? [])
            .whereType<Map>()
            .map((w) => W2Entry.fromJson(Map<String, dynamic>.from(w)))
            .toList(),
        interestIncome: readDouble(json, 'interestIncome'),
        ordinaryDividends: readDouble(json, 'ordinaryDividends'),
        qualifiedDividends: readDouble(json, 'qualifiedDividends'),
        longTermCapitalGains: readDouble(json, 'longTermCapitalGains'),
        otherIncome: readDouble(json, 'otherIncome'),
        studentLoanInterest: readDouble(json, 'studentLoanInterest'),
        deductionMethod:
            DeductionMethod.fromJsonName(json['deductionMethod'] as String?),
        stateLocalIncomeOrSalesTax:
            readDouble(json, 'stateLocalIncomeOrSalesTax'),
        realEstateTax: readDouble(json, 'realEstateTax'),
        mortgageInterest: readDouble(json, 'mortgageInterest'),
        charitableCash: readDouble(json, 'charitableCash'),
        charitableNonCash: readDouble(json, 'charitableNonCash'),
        estimatedPayments: readDouble(json, 'estimatedPayments'),
        dependents: (json['dependents'] as List? ?? [])
            .whereType<Map>()
            .map((d) => Dependent.fromJson(Map<String, dynamic>.from(d)))
            .toList(),
        created: readDate(json, 'created'),
        modified: readDate(json, 'modified'),
      );

  TaxReturnData clone() => TaxReturnData.fromJson(toJson());

  @override
  bool operator ==(Object other) =>
      other is TaxReturnData && other.toJson().toString() == toJson().toString();

  @override
  int get hashCode => toJson().toString().hashCode;
}

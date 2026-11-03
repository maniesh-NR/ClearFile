import 'json_codec.dart';

/// One W-2 wage statement (or an equivalent manual wage entry).
///
/// Only the two boxes needed by the demo calculation engine are captured:
/// Box 1 (wages) and Box 2 (federal income tax withheld).
class W2Entry {
  W2Entry({this.employer = '', this.wages = 0, this.withholding = 0});

  /// Employer name as printed on the W-2.
  String employer;

  /// Box 1 - wages, tips, other compensation.
  double wages;

  /// Box 2 - federal income tax withheld.
  double withholding;

  W2Entry copyWith({String? employer, double? wages, double? withholding}) =>
      W2Entry(
        employer: employer ?? this.employer,
        wages: wages ?? this.wages,
        withholding: withholding ?? this.withholding,
      );

  Map<String, dynamic> toJson() => {
        'employer': employer,
        'wages': wages,
        'withholding': withholding,
      };

  static W2Entry fromJson(Map<String, dynamic> json) => W2Entry(
        employer: readString(json, 'employer'),
        wages: readDouble(json, 'wages'),
        withholding: readDouble(json, 'withholding'),
      );

  @override
  bool operator ==(Object other) =>
      other is W2Entry &&
      other.employer == employer &&
      other.wages == wages &&
      other.withholding == withholding;

  @override
  int get hashCode => Object.hash(employer, wages, withholding);
}

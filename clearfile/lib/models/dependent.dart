import 'json_codec.dart';

/// A person claimed as a dependent on the return.
///
/// The demo engine asks two plain-language questions per dependent instead of
/// running the full IRS dependency tests: whether the person is a qualifying
/// child under 17 (Child Tax Credit) and whether the person otherwise qualifies
/// for the $500 Credit for Other Dependents.
class Dependent {
  Dependent({
    this.name = '',
    this.age = 0,
    this.relationship = '',
    this.qualifyingChild = false,
    this.otherDependentCredit = false,
  });

  String name;
  int age;

  /// Free-text relationship, e.g. "son", "parent", "niece".
  String relationship;

  /// True when this person is a qualifying child under age 17 at the end of
  /// the tax year (Child Tax Credit, $2,200 per child for 2025).
  bool qualifyingChild;

  /// True when this person qualifies for the $500 Credit for Other Dependents
  /// (for example a parent or a child age 17+).
  bool otherDependentCredit;

  Dependent copyWith({
    String? name,
    int? age,
    String? relationship,
    bool? qualifyingChild,
    bool? otherDependentCredit,
  }) =>
      Dependent(
        name: name ?? this.name,
        age: age ?? this.age,
        relationship: relationship ?? this.relationship,
        qualifyingChild: qualifyingChild ?? this.qualifyingChild,
        otherDependentCredit: otherDependentCredit ?? this.otherDependentCredit,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'relationship': relationship,
        'qualifyingChild': qualifyingChild,
        'otherDependentCredit': otherDependentCredit,
      };

  static Dependent fromJson(Map<String, dynamic> json) => Dependent(
        name: readString(json, 'name'),
        age: readInt(json, 'age'),
        relationship: readString(json, 'relationship'),
        qualifyingChild: readBool(json, 'qualifyingChild'),
        otherDependentCredit: readBool(json, 'otherDependentCredit'),
      );

  @override
  bool operator ==(Object other) =>
      other is Dependent &&
      other.name == name &&
      other.age == age &&
      other.relationship == relationship &&
      other.qualifyingChild == qualifyingChild &&
      other.otherDependentCredit == otherDependentCredit;

  @override
  int get hashCode =>
      Object.hash(name, age, relationship, qualifyingChild, otherDependentCredit);
}

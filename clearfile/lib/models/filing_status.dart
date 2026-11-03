/// Federal filing statuses, each paired with the plain-language explanation
/// style popularized by the IRS DirectFile pilot (discontinued after the 2025
/// filing season): short, jargon-free sentences that help people pick correctly.
enum FilingStatus {
  single(
    'Single',
    'You were unmarried or legally separated as of December 31, 2025.',
  ),
  marriedJoint(
    'Married filing jointly',
    'You were married and are reporting both spouses\u2019 income on one return. '
    'This is usually (not always) the lower-tax option.',
  ),
  marriedSeparate(
    'Married filing separately',
    'You were married but each spouse files their own return. Some credits and '
    'deductions are limited or unavailable with this status.',
  ),
  headOfHousehold(
    'Head of household',
    'You were unmarried on December 31, 2025, paid more than half the cost of '
    'keeping up a home, and can claim a qualifying person such as a child.',
  ),
  survivingSpouse(
    'Qualifying surviving spouse',
    'Your spouse died in 2023 or 2024, you have a dependent child, and you have '
    'not remarried. You use the married-jointly rates.',
  );

  const FilingStatus(this.label, this.plainExplanation);

  /// Short label shown in summaries and pickers.
  final String label;

  /// Plain-language explanation shown when the user is choosing.
  final String plainExplanation;

  String get jsonName => name;

  static FilingStatus fromJsonName(String? value) {
    for (final status in FilingStatus.values) {
      if (status.name == value) return status;
    }
    return FilingStatus.single;
  }
}

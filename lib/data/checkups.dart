/// Check-ups and vaccines worth asking a doctor about, by age and sex.
///
/// Drawn from widely used guidance (US Preventive Services Task Force
/// grade A/B recommendations and the CDC adult immunisation schedule).
/// Countries differ, and a person's history changes what fits — so ONO
/// only ever shows these as questions to ask, never as "you are due".
/// General content: names no person or employer (tested).
class Checkup {
  final String id;
  final String name;

  /// One line on what it is for.
  final String why;
  final int minAge;
  final int maxAge;

  /// 'any', 'female' or 'male'.
  final String sex;

  /// A common interval in days, offered when it is added to Care; the
  /// person changes it with their doctor. 0 = usually once.
  final int every;

  /// Who it is mainly for, when that isn't everyone of that age.
  final String only;

  const Checkup(this.id, this.name, this.why, this.minAge, this.maxAge,
      {this.sex = 'any', this.every = 365, this.only = ''});
}

const sexOptions = {'female': 'Woman', 'male': 'Man'};

const List<Checkup> checkups = [
  Checkup('bp', 'Blood pressure check', 'High blood pressure has no symptoms until it does damage.', 18, 120,
      every: 365),
  Checkup('lipids', 'Cholesterol and heart risk', 'Your doctor can estimate heart risk and whether to act on it.', 40, 75,
      every: 1825),
  Checkup('sugar', 'Blood sugar (diabetes) test', 'Type 2 diabetes is often found years late.', 35, 70,
      every: 1095, only: 'especially if you carry extra weight'),
  Checkup('bowel', 'Bowel cancer screening', 'Finds bowel cancer early, when it is most treatable.', 45, 75,
      every: 365, only: 'how often depends on the test'),
  Checkup('cervical', 'Cervical screening', 'Finds changes before they become cancer.', 21, 65,
      sex: 'female', every: 1095),
  Checkup('breast', 'Breast screening (mammogram)', 'Finds breast cancer early.', 40, 74, sex: 'female', every: 730),
  Checkup('lung', 'Lung cancer screening', 'A low-dose scan finds lung cancer early.', 50, 80,
      every: 365, only: 'if you smoke or smoked a lot'),
  Checkup('prostate', 'Whether a PSA test is right for you', 'A test with real trade-offs — worth a conversation.', 55, 69,
      sex: 'male', every: 730),
  Checkup('aorta', 'Abdominal aortic aneurysm scan', 'A one-time scan.', 65, 75,
      sex: 'male', every: 0, only: 'if you have ever smoked'),
  Checkup('bones', 'Bone density (osteoporosis) scan', 'Weak bones break easily, with no warning.', 65, 120,
      sex: 'female', every: 730),
  Checkup('hepc', 'Hepatitis C test', 'Recommended once for adults; it is curable.', 18, 79, every: 0),
  Checkup('hiv', 'HIV test', 'Recommended at least once; more often if at risk.', 15, 65, every: 0),
  Checkup('flu', 'Flu vaccine', 'Every year, before winter.', 18, 120, every: 365),
  Checkup('tetanus', 'Tetanus booster', 'Every ten years.', 18, 120, every: 3650),
  Checkup('shingles', 'Shingles vaccine', 'Two doses protect for years.', 50, 120, every: 0),
  Checkup('pneumo', 'Pneumonia vaccine', 'Protects against a common, serious pneumonia.', 65, 120, every: 0),
];

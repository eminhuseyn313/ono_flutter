/// The life wheel: eight areas anyone can rate 1–10 each quarter. The
/// lowest suggests where to grow next, via a matching template.
class LifeArea {
  final String id;
  final String name;
  final String prompt;

  /// The growth-area template (lib/data/growth_templates.dart) that fits.
  final String template;
  const LifeArea(this.id, this.name, this.prompt, this.template);
}

const List<LifeArea> lifeAreas = [
  LifeArea('career', 'Career & work', 'Progress, meaning and respect in your work', 't_career_change'),
  LifeArea('health', 'Health & body', 'Energy, strength, sleep, how your body feels', 't_health'),
  LifeArea('relationships', 'Partner & close relationships', 'Closeness, support, time together', 't_relationships'),
  LifeArea('family', 'Family & friends', 'Being there for the people who matter', 't_friendship'),
  LifeArea('money', 'Money', 'Security, savings, freedom from money worry', 't_money'),
  LifeArea('mind', 'Mind & calm', 'Stress, mood, how you recover from hard days', 't_calm'),
  LifeArea('growth', 'Learning & growth', 'Getting better at things you care about', 't_learning'),
  LifeArea('meaning', 'Meaning & rest', 'Purpose, faith or reflection, play and real rest', 't_meaning'),
];

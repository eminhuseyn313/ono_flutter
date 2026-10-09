/// Small daily actions anyone can pick when building a plan, grouped by
/// life area (lib/data/life_wheel.dart). Each comes with an if–then cue,
/// because a plan tied to a moment is far more likely to happen
/// (implementation intentions, Gollwitzer & Sheeran 2006).
class DailyIdea {
  final String title;
  final String lane;

  /// 'morning' | 'day' | 'evening'.
  final String when;

  /// The life area it serves.
  final String area;
  final String cue;
  const DailyIdea(this.title, this.lane, this.when, this.area, this.cue);
}

const List<DailyIdea> dailyLibrary = [
  DailyIdea('Write today\'s three priorities', 'skill', 'morning', 'career',
      'When I sit down to start work, I write my three before opening messages.'),
  DailyIdea('One focused block on the most important work', 'skill', 'day', 'career',
      'When the first meeting-free hour starts, I close everything but one document.'),
  DailyIdea('Close the day: tomorrow\'s three on paper', 'skill', 'evening', 'career',
      'When I shut the laptop, I write tomorrow\'s three first.'),
  DailyIdea('Move for 30 minutes', 'body', 'day', 'health',
      'When I finish lunch, I walk or train for 30 minutes.'),
  DailyIdea('Protein with every meal', 'body', 'day', 'health',
      'When I plan a meal, I start with the protein.'),
  DailyIdea('In bed by a fixed time', 'body', 'evening', 'health',
      'When my wind-down alarm rings, the phone goes outside the bedroom.'),
  DailyIdea('Ten minutes of full attention for my partner', 'social', 'evening', 'relationships',
      'When we sit down in the evening, phones go in another room.'),
  DailyIdea('Say one specific thank-you', 'social', 'day', 'relationships',
      'When someone helps me, I name exactly what they did.'),
  DailyIdea('Reach out to one person who matters', 'social', 'day', 'family',
      'When I take my afternoon break, I send one message to someone I care about.'),
  DailyIdea('Undistracted time with the kids', 'social', 'evening', 'family',
      'When I get home, the phone stays in my bag for the first 30 minutes.'),
  DailyIdea('Log what I spent today', 'mind', 'evening', 'money',
      'When I brush my teeth, I log today\'s spending first.'),
  DailyIdea('A 24-hour pause before any non-essential buy', 'mind', 'day', 'money',
      'When I want to buy something I don\'t need, I put it on a list for tomorrow.'),
  DailyIdea('Three slow breaths before hard moments', 'mind', 'day', 'mind',
      'When I feel my chest tighten, I take three slow breaths before I answer.'),
  DailyIdea('Ten minutes outside without the phone', 'mind', 'day', 'mind',
      'When I finish lunch, I step outside with the phone left behind.'),
  DailyIdea('Write three lines about the day', 'mind', 'evening', 'mind',
      'When I get into bed, I write three lines before anything else.'),
  DailyIdea('Read 20 pages', 'skill', 'evening', 'growth',
      'When I get into bed, I read before I touch the phone.'),
  DailyIdea('Practise the skill I\'m building for 20 minutes', 'skill', 'day', 'growth',
      'When I finish my last meeting, I practise before anything else.'),
  DailyIdea('Explain one new idea in my own words', 'skill', 'evening', 'growth',
      'When I finish reading, I write the idea from memory in five lines.'),
  DailyIdea('Five quiet minutes: prayer, reflection or stillness', 'mind', 'morning', 'meaning',
      'When I wake up, I sit for five minutes before looking at the phone.'),
  DailyIdea('Do one thing just for joy', 'mind', 'evening', 'meaning',
      'When the work day ends, I do one thing only because I enjoy it.'),
  DailyIdea('Name what mattered today', 'mind', 'evening', 'meaning',
      'When I turn off the light, I name one thing that mattered today.'),
];

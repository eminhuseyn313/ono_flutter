// The prompt a person copies into any AI tool (ChatGPT, Claude, Gemini…)
// to have a full ONO plan written for them, and the format it must answer
// in. General content: it never names anyone; the person's own answers are
// added by [planPrompt] only when they copy it.
//
// The format is documented for people in docs/PLAN_FORMAT.md; the
// importer (plan_import.dart) also accepts looser shapes.

/// What the AI must answer with. Kept short enough to paste, complete
/// enough to fill every part of ONO.
const planFormatSpec = r'''
Answer with ONE JSON object inside a single ```json code block, nothing after it. Shape (every section but "profile" is optional; leave out what doesn't fit the person rather than inventing filler):

{
  "ono_plan_version": 1,
  "profile": {
    "name": "Full Name", "first_name": "First",
    "current_role": "where they are now", "target_role": "who they are becoming",
    "organisation": "", "focus": "", "domain": "", "location": "",
    "identity_statement": "one line in their voice, present tense",
    "archetype": "", "tagline": "",
    "path": ["now", "next step", "the step after"],
    "key_people": [{"name": "First name", "relation": "manager / partner / friend", "every": 7, "primary": true}],
    "context": "3-6 sentences a coach should know: situation, strengths, patterns, constraints, health limits to respect"
  },
  "daily_items": [
    {"id": "short_id", "title": "Specific action, done daily", "lane": "mind|body|skill|social",
     "when": "morning|day|evening", "cue": "When I …, I …", "minimum": "the 2-minute version for hard days"}
  ],
  "schedule": [{"time": "07:00", "title": "Block name", "detail": "what happens", "lane": "body"}],
  "training": [{"name": "Day A · Push", "day": "Monday", "finisher": "10 min easy cardio",
                "exercises": [{"name": "Goblet squat", "sets": "3×10", "key_lift": true, "note": ""}]}],
  "growth_areas": [{"name": "Area to get better at", "bar": "what good looks like",
                    "ask": "feedback question to ask someone who sees it",
                    "levels": ["1 …", "2 …", "3 …", "4 …", "5 …"],
                    "drills": [{"title": "Drill", "how": "how to practise it this week", "signal": "how you know it worked"}]}],
  "books": [{"title": "", "author": "", "month": 1, "chapters": "what to read", "why": "why this person, now", "kind": "nonfiction|novel"}],
  "films": [{"title": "", "year": 2015, "when": "Month 2", "why": ""}],
  "podcasts": [{"day": "Monday", "title": "Show", "detail": "start with this episode"}],
  "daily_reads": [{"day": "Monday", "title": "Source", "detail": "what to look for", "url": ""}],
  "practices": [{"name": "Practice", "lane": "mind", "what": "exact steps", "when": "when to use it",
                 "why": "why it works", "source": "research or author"}],
  "reminders": [{"label": "Text of the notification", "time": "21:30", "days": ["Mon", "Wed"], "route": "/shutdown"}],
  "month_themes": [{"month": 1, "theme": "what this month is for"}],
  "month_artifacts": [{"month": 1, "artifact": "one thing to make or finish this month"}],
  "unlocks": [{"month": 2, "kind": "book|film|habit|milestone|style|skill", "title": "", "detail": ""}],
  "milestones": [{"month": 6, "targets": ["measurable outcome"]}],
  "ritual": [{"title": "Morning step", "minutes": 2, "instruction": "", "lane": "body"}],
  "coach_tips": [{"title": "", "content": "one short note for a day, in order (30 is ideal)", "lane": "mind"}],
  "cards": [{"front": "question to remember", "back": "answer"}],
  "weekly_review_questions": ["question for each Sunday"]
}

Rules:
- Write for this one person: their goals, job, body, family, money and time. Specific beats generic ("Read 20 pages of the month's book at lunch", not "Read more").
- Daily items: 4 to 10, small enough to do on a bad day; each with a cue ("When I …, I …") and a minimum.
- Respect health limits they mention; no medication or supplement doses; say "ask your doctor" where it matters.
- Books, films, podcasts and practices should be real and well regarded; say why each fits them now.
- Months count from the plan's start (month 1 = the first 30 days). Cover the length they chose.
- Links ("route") are optional; use only: /home /checkin /shutdown /week /growth /goals /learning /focus /move /people /gym /review /weekly-coaching /library /daily /values /manifesto.
- Use the person's own words where they gave them.
''';

/// The prompt for one person, built from what they already told ONO.
/// [about] holds lines like "Name: …"; empty lines are left out.
String planPrompt({required List<String> about, int programDays = 90, List<String> record = const []}) {
  final lines = [for (final l in about) if (l.trim().isNotEmpty) '- ${l.trim()}'];
  final done = [for (final l in record) if (l.trim().isNotEmpty) '- ${l.trim()}'];
  return '''You are an expert coach and planner. Build me a complete personal development plan for the app ONO: my daily habits, the shape of my day, training, what to read, watch and listen to, practices for hard moments, the skills I'm growing, monthly themes and milestones, and short coach notes.

What I've told ONO so far:
${lines.isEmpty ? '- (nothing yet)' : lines.join('\n')}
- Plan length: $programDays days (${(programDays / 30).round()} months).
${done.isEmpty ? '' : '''
What actually happened so far (from what I logged):
${done.join('\n')}
Keep what is working. Make what keeps slipping smaller, or give it a better time and cue. Build on the lessons.
'''}
Before writing the plan, ask me up to 6 short questions about anything you need (for example: my work and what success looks like, my health and any limits, my mornings and evenings, family, money, what I've tried before). Wait for my answers. Then write the plan.

$planFormatSpec''';
}

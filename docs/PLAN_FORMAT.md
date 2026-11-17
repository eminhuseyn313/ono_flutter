# The ONO plan format

A full plan is one JSON file. Anyone can have one written by an AI tool (ChatGPT, Claude, Gemini…): in ONO, open **Me → Settings → Get a full plan, made for you**, tap **Copy the prompt**, paste it into the AI, answer its few questions, then load the answer with **Choose a file** or paste it.

The prompt already carries what the person told ONO (name, roles, life wheel, goals, this month's growth area, daily items, the shape of their day and the plan's length). Nothing is sent from ONO: the person pastes it themselves.

## What ONO does with it
- The plan becomes theirs: its profile is used, its daily items join the daily list, the day's blocks draw the dial, training days fill the gym screen, books, films and podcasts the library, practices the tools, growth areas the growth plan, month themes, unlocks and milestones the Program, the ritual the morning ritual, coach notes Today, cards the review deck, reminders the notifications.
- Nothing they logged changes. **Undo** puts back the plan and profile from before; **Save the plan as a file** and **Copy** keep a copy; the plan also syncs with their account and travels in backups.

## The importer is forgiving
The answer can be pasted with chat around it and code fences. ONO also accepts:
- times as `"07:30"`, `"7.30"` or `"7:30 pm"`, or `"h"`/`"m"` numbers;
- weekdays as `"Monday"`, `"mon"` or 1–7;
- lanes in plain words (`career` → skill, `fitness` → body, `family` → social, …);
- ids missing (made from titles), daily items or drills given as plain strings, exercises as `"Goblet squat 3×12"`;
- other names for sections (`training`/`gym`, `movies`/`films`, `practices`/`protocols`, `cards`/`seed_cards`, `milestones`/`career_milestones`).

It refuses only a file with no plan or no name, and says why. It drops links to screens ONO doesn't have, schedule blocks or reminders without a time, and daily items past 15, and lists each adjustment after loading.

## The format (the same text the prompt gives the AI)

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

## Other sections
Files saved from ONO also carry sections an AI rarely writes: `lane_focus`, `evening_focus` (weekday → text), `shoulder_sparing`, `avoid_lifts`, `lift_swaps`, `supplements_morning`/`supplements_night`, `bloodwork`, `face_notes`, `beard_spec`, `wardrobe`, `outfits`, `watch_rule`, `grooming_routine`, `skincare_plan`, `linkedin_*`, `domain_thesis`, `key_data`, `certificates`, `evidence_sections`, `evidence_seeds`, `path_steps`, `work_day_only_items`, `item_reminder`, `manifesto`. They load as they are (see `PlanContent.fromJson` in `lib/data/plan_content.dart`).

Any other section (say `nutrition` or `weekly_rituals`) is kept exactly as written, saved again with the plan, named in the load report and shown on **More from your plan** (`/plan-more`) as lists and titled entries, so nothing an AI writes is lost.

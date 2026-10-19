# ONO — product research (October 2026)

**Vision (Emin):** first make ONO genuinely useful for Emin, then configure it for anyone who wants to grow, whether a leader, an athlete, a CEO or a parent. Every feature must pass two tests:
1. **Useful to Emin now**, in his real work and life.
2. **Useful to anyone**: no feature exists only for one job, company or person.

## 1. The market: what exists, where it fails

**Fragmented by dimension.** Apps cover one slice each: habit trackers (Streaks, Habitica, Fabulous), meditation (Calm, Headspace), fitness, journaling, and AI or human coaching (BetterUp and CoachHub for enterprises; Rocky.ai for consumers at about $10–13 a month). Nobody runs one plan across career, body, relationships, money and mind. That is ONO's opening.

**Retention collapses in the first weeks.** Rigorous data is scarce (no habit app publishes retention). The best study, Baumel et al. 2019 on mental-health apps, found more than 80% of users lost within 10 days and a median 30-day retention of 3.3%. Industry reports put day-30 retention in the low single digits. The recurring causes:
- streaks that punish a missed day, with guilt and abandonment as the result;
- friction: the time from unlock to the first useful action;
- generic content and choice overload;
- notification fatigue;
- no value felt in the first session.

**AI coaches are chat-first and generic.** Reviewers find them repetitive. Enterprise coaching is effective but expensive and only reaches employees.

## 2. The evidence: what actually changes people

| Mechanism | Effect | ONO today |
|---|---|---|
| Implementation intentions (if–then plans) | d = 0.65 across 94 tests (Gollwitzer & Sheeran 2006) | ✓ cues on Daily items, the GROW "will" |
| Monitoring progress | d = 0.40 across 138 RCTs; stronger when **physically recorded** and **reported to someone** (Harkin et al. 2016) | ✓ recorded; ✓ reported — progress note, partner check-in, coach report |
| Mental contrasting (WOOP) | g ≈ 0.28 at 4 weeks, rising to 0.38 at 3 months (Cross & Sheffield 2019) | ✓ goals: wish, outcome, obstacle, plan |
| Coaching | g = 0.43–0.74, smaller in controlled designs (Theeboom et al. 2014) | ✓ self-coaching (GROW), weekly brief |
| Deliberate practice with feedback | the core of expertise (Ericsson 1993) | ✓ growth plan: drills, reps, feedback |
| Forgiving streaks | missing one day doesn't break habit formation (Lally 2010) | ✓ "never miss twice" |

Several popular figures, such as "95% success with an accountability partner", have no traceable primary source, so ONO does not rely on them.

## 3. The gap that matters most

ONO has **daily** practice (Daily 10), **weekly** outcomes (Big 3) and **monthly** growth areas. It has no **goal**: the 6–18-month outcome all of that serves. "Head of Product by month 9", "a sub-4-hour marathon", "three months' expenses saved" and "my team's engagement at 4/5" are goals. Without them:
- progress can't be measured against anything that matters;
- the weekly and monthly layers aren't visibly connected to a destination;
- a new user (an athlete or a CEO) has nowhere to state what they're working towards.

## 4. Recommended roadmap

**Status (12 Oct 2026):** steps 1–6 are built, as are the "Suggested order" items in section 5 except F5 languages (paused by Emin). Coach mode and partners work offline (copy and paste); sharing through the cloud waits for the Supabase deploy.

Each step is useful to Emin now and becomes part of the general product.

1. **Goals with WOOP and a measure.**
   - A goal holds: the outcome, why it matters, a measurable number with start, target and deadline, the main obstacle and an if–then plan (WOOP), and links to growth areas.
   - Progress is recorded as numbers over time, with a trend line.
   - Today shows the goal's next step; the Big 3 and the growth area show which goal they serve; the brief reviews goal progress.
   - For Emin: Head of Product, body composition, public voice. For anyone: whatever they're becoming.
2. **Report progress to someone.** A weekly progress note to one chosen person (a manager, coach, partner or friend), generated from real data and sent by the user. Reported monitoring roughly doubles the effect of private monitoring (Harkin et al.).
3. **Profile editor.** Emin edits his own roles, key people, path and coach context in the app instead of in code. The same screen becomes step one of onboarding.
4. **Configurable Daily items.** Add, remove and retire items as they become automatic. Today the Daily 10 is fixed, which a general app can't be.
5. **Onboarding that builds a plan.** Profile, then goals, then growth areas (from templates), then Daily items, then schedule, producing a first useful Today within 5 minutes. This answers the "no value in the first session" failure.
6. **A calmer Today.** Today has grown dense. Rank the cards so the first screen shows the one to three actions that matter most now, and put the rest behind it. This reduces choice overload, a known cause of churn.

**Deliberately not recommended:** points, leaderboards and badges (they reward looking busy); notification-heavy designs (fatigue is a top churn cause); a generic AI chat coach (reviewed as repetitive; ONO's coach works from the person's real data instead).

## 5. Expanded feature list

Every item passes both tests: useful to Emin now, and useful to anyone. Effort: S = days, M = a week, L = several weeks. ✓ = already in ONO.

### A. Direction: where you're going
| # | Feature | For Emin now | For anyone | Evidence | Effort |
|---|---|---|---|---|---|
| A1 | **Goals with WOOP and a measure** (outcome, why, number, deadline, obstacle → if–then plan, trend) | Head of Product, body composition, public voice | Marathon time, savings, team engagement | Goal setting (Locke & Latham 2002); WOOP g ≈ 0.3 | M |
| A2 | **Quarterly review and plan** (12 weeks: wins, lessons, goals kept or dropped, next quarter's 1–3 goals) | Natural rhythm for an 18-month program | Same | Fresh-start effect (Dai, Milkman & Riis 2014) | S |
| A3 | **Life wheel** (rate 8 life areas 1–10 each quarter; the lowest suggests the next growth area) | Keeps work from crowding out body, home and meaning | The standard coaching entry point | Common coaching practice; ties to basic needs (self-determination theory) | S |
| A4 | **Identity statement per goal** ("I am someone who…") | Extends the manifesto beyond one line | Athlete: "I'm someone who never skips recovery" | Identity-based motivation (Oyserman 2007) | S |
| A5 | **Stop-doing list** (what you give up to make room) | Trade-offs as he takes on more scope | Everyone over-commits | Opportunity cost; goal conflict reduces attainment | S |

### B. Practice and learning
| # | Feature | For Emin now | For anyone | Evidence | Effort |
|---|---|---|---|---|---|
| B1 | **Level descriptions per growth area** (what levels 1–5 look like, so ratings mean something) | Readiness ratings become honest | Every area and template gets a rubric | Behaviourally anchored scales are more reliable than bare numbers | M |
| B2 | **Learning queue with "apply it"** (books, courses, talks → one principle → one experiment at work or home) | Generalises the lunch read and Feynman | Any learner | Transfer of training (Baldwin & Ford 1988) | M |
| B3 | **Personal experiments** ("For 2 weeks I'll try X and watch Y" → result → keep or drop) | Turns patterns into decisions | Self-experimentation for anyone | Builds on Patterns ✓; n-of-1 method | S |
| B4 | **Role models** (people one step ahead: what to learn from each, one question to ask them) | Path to Head of Product, then CPO | Any field | Learning by modelling (Bandura) | S |
| B5 | **Review deck from any learning** ✓ (cards from notes, spaced) | Already in use | Generalise the seed cards | Testing effect (Roediger & Karpicke 2006) | S |

### C. Feedback and accountability
| # | Feature | For Emin now | For anyone | Evidence | Effort |
|---|---|---|---|---|---|
| C1 | **Weekly progress note to one chosen person** | Manager, mentor or wife | Coach, partner, friend | Reported monitoring is stronger than private (Harkin et al. 2016) | S |
| C2 | **Quarterly 360-lite** (the same question to 3 people; themes tracked over time) | Evidence for the promotion case | Any role, any team | Multisource feedback (London & Smither 1995) | M |
| C3 | **Accountability partners in the app** (two users share goals and weekly notes) | Later, with a peer | Core of the mass version | Social support for goal pursuit | L |

### D. The foundation: energy, recovery and setbacks
| # | Feature | For Emin now | For anyone | Evidence | Effort |
|---|---|---|---|---|---|
| D1 | **Setback protocol** (after a missed day or a bad week: self-compassion, what happened, the smallest next step) | The impostor pattern punishes misses | Everyone has setbacks | Self-compassion increases the motivation to improve (Breines & Chen 2012) | S |
| D2 | **Recovery planning** (rest days, deload weeks, holidays planned in advance; detachment checks) | RA, beta thalassemia, a demanding job | Athletes, founders, parents | Psychological detachment and recovery (Sonnentag & Fritz 2007) | S |
| D3 | **Energy map** (when check-ins show he is sharpest; hardest work goes there) | Uses check-in data he already has | Anyone who checks in | Chronotype and time-of-day performance | M |

### G. Direction and self-knowledge (second research pass)
| # | Feature | For Emin now | For anyone | Evidence | Effort |
|---|---|---|---|---|---|
| G1 | **Odyssey plan** (three five-year lives rated on resources, liking, confidence, coherence; one prototype) | Head of Product vs. other paths, chosen on purpose | A student, a parent returning to work, an athlete after sport | Burnett & Evans, *Designing Your Life* (2016) | M |
| G2 | **Energy audit and one job-crafting move** (rate a normal week's activities; do more, less, or reshape one) | Shape the PO role towards what energises him | Home and family work too | Wrzesniewski & Dutton 2001; Rudolph et al. 2017 (meta-analysis: job crafting ↔ engagement, performance) | S |
| G3 | **Reflected best self** (stories of you at your best from people in different parts of life → themes → portrait) | Self-trust, one of his three personal areas | Anyone who doubts their strengths | Roberts, Spreitzer, Dutton et al., HBR 2005 | S |

### H. Third pass: the whole person, for anyone (built overnight, 11–12 Oct 2026)
| # | Feature | For Emin now | For anyone | Evidence | Status |
|---|---|---|---|---|---|
| H1 | **Movement minutes** (vigorous ×2) and strength days | Walking and running count, not only gym | Every adult | WHO 2020 physical activity guidelines | ✅ |
| H2 | **Hard conversations** (wants for me/them/us, facts vs story, their story, first sentence, ask, debrief) | Feedback and stakeholder moments | Partners, parents, leaders | Patterson et al., *Crucial Conversations*; Stone, Patton & Heen, *Difficult Conversations* | ✅ |
| H3 | **People you're helping grow** | Developing his team | Mentors, parents, coaches | Protégé effect (Nestojko et al. 2014) | ✅ |
| H4 | **Look back when a goal closes** | Turns wins into lessons | Anyone | After-action reviews; testing effect for the resulting card | ✅ |
| H5 | **Money check-in** (savings rate, buffer, one decision) | Household finance | Anyone | Self-monitoring (Harkin et al. 2016) | ✅ |
| H6 | **Health upkeep** (checkups with intervals you set) | Bloodwork and checkups with RA | Anyone | Preventive care adherence improves with reminders; no medical advice given | ✅ |
| H7 | **Three good things** at shutdown | Evening reflection | Anyone | Seligman et al. 2005 | ✅ |
| H8 | **Step back** (self-distanced talk) | Composure under pressure | Anyone in a hard moment | Kross et al. 2014; temporal distancing (Bruehlman-Senecal & Ayduk 2015) | ✅ |
| H9 | **Decide with your values** (+10/10/10, premortem) | Life and career choices | Anyone | Values clarification; premortem (Klein 2007) | ✅ |
| H10 | **Month review for anyone** | — (has his own) | Monthly loop for every plan | Reflection in Kolb's cycle; fresh-start effect | ✅ |
| H11 | **Journal export** | Owns his reflections | Data ownership | Trust and portability | ✅ |
| H12 | **How to work with me** (user manual) | His team | Teams, partners | Common leadership practice; psychological safety | ✅ |
| H13 | **A check-in for two** | Marriage | Couples | Gottman & Silver 1999 (rituals of connection, appreciation) | ✅ |
| H14 | **Question of the day** | — (has coach tips) | Daily reflection for anyone | Expressive writing and reflection literature | ✅ |
| H15 | **Stake on the partner pact** | Optional | Anyone with a partner | Commitment contracts (Giné, Karlan & Zinman 2010) | ✅ |

Also overnight: anyone but the built-in person now sees a general app (Today, Program, growth areas, check-in, brief, reminders, welcome), with a test that fails if the built-in plan's specifics leak.

### I. Fourth pass: the inner life (12 Oct 2026)
Mind and meaning had the fewest tools. Each item below is short, has good evidence, works for anyone, and serves Emin's personal areas now (self-trust, composure under pressure, public voice).

| # | Feature | For Emin now | For anyone | Evidence | Status |
|---|---|---|---|---|---|
| I1 | **Thought check** (situation, thought, feeling 0–100, evidence for/against, balanced thought, re-rate) | The impostor voice before reviews | Anxiety, self-doubt, anger | Beck 1979; Hofmann et al. 2012 (meta-analysis of CBT) | ✅ |
| I2 | **Best possible future** (write it as already true, then one step this week) | Hope on hard weeks; links to goals | Anyone | King 2001; Meevissen et al. 2011; Carrillo et al. 2019 (meta-analysis) | ✅ |
| I3 | **Kindness day** (five acts on one day a week) | Team and family | Anyone | Lyubomirsky, Sheldon & Schkade 2005 | ✅ |
| I4 | **Worry time** (park, then one daily slot: next step or let go) | Composure; evenings free | Chronic worriers | Borkovec et al. 1983; McGowan & Behar 2013 (RCT) | ✅ |
| I5 | **Life chapters** (high, low, lesson; now; the next chapter's title) | Meaning, identity in transition | Anyone at a turning point | McAdams & McLean 2013; Adler 2012 | ✅ |

All five are private: the coach gets only how many thoughts were checked and kind acts logged.

### J. Fifth pass: strengths and the people who grow you (12 Oct 2026)
| # | Feature | For Emin now | For anyone | Evidence | Status |
|---|---|---|---|---|---|
| J1 | **Signature strengths** (top five of 24, a new use each week) | Self-trust: build on what is already strong | Anyone | Seligman, Steen, Park & Peterson 2005 (effects for six months); Peterson & Seligman 2004 (VIA) | ✅ |
| J2 | **Personal board** (roles across your network, gaps) | A sponsor for the Head of Product move | Career changers, founders, parents returning to work | Higgins & Kram 2001; Cummings & Higgins 2006 (developmental networks) | ✅ |
| J3 | **After-action review** (successes too; "change" becomes a card) | Launches, presentations, hard 1:1s | Athletes, teams, parents after a hard evening | Ellis & Davidi 2005; Tannenbaum & Cerasoli 2013 (debriefs improve performance ~25%) | ✅ |

Emin's answers (12 Oct 2026): at the end, a closing review and a new program that keeps all history; anyone can choose 90 days, 6, 12 or 18 months, with the four phases scaled. Built.

### K. Sixth pass: your word and your stories (12 Oct 2026)
| # | Feature | For Emin now | For anyone | Evidence | Status |
|---|---|---|---|---|---|
| K1 | **Promises** (kept / renegotiated in time / missed; say–do record) | Stakeholder trust as a product leader | Parents, partners, team members | Behavioural integrity: Simons 2002; Palanski & Yammarino 2011 | ✅ |
| K2 | **Story bank** (situation, task, action, result; tagged by skill; gaps) | The Head of Product case and interviews | Anyone facing an interview, review or promotion | Behavioural interviews reward prepared, concrete examples (Maurer, Solamon & Troxtel 1998; Maurer et al. 2001) | ✅ |

### L. Seventh pass: the year and asking (12 Oct 2026)
| # | Feature | For Emin now | For anyone | Evidence | Status |
|---|---|---|---|---|---|
| L1 | **Year in review** (the year's numbers first, then six questions and a word for the next) | Closing 2026 with real data, not memory | The ritual many people already do at New Year | Recall is biased to recent and negative events (peak–end, Kahneman et al. 1993); structured reflection beats unstructured (Di Stefano et al. 2016) | ✅ |
| L2 | **Ask for help** (guess the chance of a yes, ask, note the answer) | Asking stakeholders and peers sooner | Anyone who'd rather struggle than ask | People underestimate compliance by about half (Flynn & Lake 2008; Bohns 2016) | ✅ |

### M. Eighth pass: care, and the whole person (19 Oct 2026)
Asked by Emin: "the care part — healthcare, nails, the barber". Researched against Finch, Routinery, Tiimo, How We Feel, Paired, Day One, Oura/Whoop and the evidence. Most of it extends what exists rather than adding screens.

| # | Feature | Extends | Evidence | Effort | Status |
|---|---|---|---|---|---|
| M1 | **Care**: health, grooming, home & things — booking, your real rhythm, documents with expiry dates | `/upkeep` | Reminders raise preventive uptake modestly (meta-analysis of 25 RCTs, RR 1.09 vaccination; SMS +5 pts breast screening) | S–M | Built |
| M2 | **Checkups to ask your doctor about by age and sex** (USPSTF A/B, vaccine schedules; questions, never "you are due") | M1 | USPSTF; CDC adult schedule; national schedules differ | M | Needs Emin: store sex and birth year? Review for Azerbaijan |
| M3 | **Care routines with steps** (one daily item, stepped through calmly; e.g. evening care) | Daily items, ritual flow | Daily sunscreen RCT (Hughes 2013); interdental cleaning, low certainty (Cochrane CD012018); implementation intentions | M | Built |
| M4 | **In my care** (a parent, a child, an ill partner: their care items, questions to ask while you can, a caregiver check) | People, M1 | Caregiver-app scoping reviews (small studies, burden ↓) | M | Built |
| M5 | **Self-compassion break** (notice, common humanity, kindness) | `/need`, setback | Ferrari et al. 2019, 27 RCTs | S | Built |
| M6 | **Name the feeling** (feeling words after the check-in mood) | Check-in, patterns | Affect labelling (Lieberman et al. 2007) | S | Built |
| M7 | **On this day** (one past entry from 1, 6 or 12 months ago, at most weekly) | Logs, review cards | Rediscovery underestimated (Zhang et al. 2014) | S | Built |
| M8 | **Time outside** (outdoor movement, minutes a week; optional awe walk) | `/move` | White et al. 2019 (120 min/week, association); Sturm et al. 2020 awe walks | S | Built |
| M9 | **Break the sitting after focus** (stand and walk at the end of a block) | `/focus` | Buffey et al. 2022 meta-analysis | S | Built |
| M10 | **Time together** (how long a contact lasted; hours with the closest people) | People touches | Hall 2018 (≈50/90/200 hours to casual/friend/close friend) | S | Built |
| M11 | **A daily question for two** (answers revealed after both answer) | `/us` | Paired observational study 2025; Gottman rituals | M–L | Needs the shared cloud |
| M12 | **Space reset with the Sunday review** | Sunday report, M1 | Saxbe & Repetti 2010 (weak) | S | Built |

Placed lower: appearance-for-confidence claims (no peer-reviewed support; power posing didn't replicate), hydration/posture reminders (weak evidence, nagging), proprietary readiness scores (would be fake numbers), pets and points (gamification).

### N. Ninth pass: beyond care (19 Oct 2026)
| # | Feature | Extends | Evidence | Effort | Status |
|---|---|---|---|---|---|
| N1 | **Steady sleep**: one wake time, wake-time spread from real data, if-then rules; never time-in-bed limits | `/day`, Health sleep, plans | dCBT-I (29 RCTs); sleep regularity (Windred 2024); caffeine (Drake 2013) | M | Built (no restriction) |
| N2 | **Recall before you review**: guesses before reading, one principle recalled a day, mixed deck | Review deck, learning | Testing effect (Adesope 2017, Dunlosky 2013); interleaving (Brunmair 2019) | S | Built |
| N3 | **Visibility and deciders**: what the people who decide your next step have seen in 90 days; 1:1 agenda | Board, brag, cockpit | Upward influence (Higgins 2003); self-assessment gap (Exley & Kessler) | M | Built (private) |
| N4 | **Negotiation planner** (want, walk-away, bottom line, first offer and why) | New, like conversations | First-offer meta-analysis (OBHDP 2025) | S | Built |
| N5 | **Values in action**: one small act of a value each week, checked next Sunday | `/values` | Values-consistent living (Tunç 2023) | S | Built |
| N6 | **Reconnect**: one lost-touch person a week; the liking gap | People | Liu et al. 2022; Boothby 2018 | S | Built |
| N7 | **Advice to a friend after a miss** | After-action review | Eskreis-Winkler & Fishbach 2019; PNAS 2019 | S | Built |
| N8 | **Your phone, on your terms** (batched checks, weekly typed Screen Time) | Daily items, patterns | Fitz 2019; Burnell 2025 | S–M | Needs Emin |
| N9 | **Practice design for drills** (sub-skill, feedback source, beyond comfort) | Growth drills | Debriefs (Tannenbaum 2013) | S–M | Built |
| N10 | **Money over time** (net worth, true costs, giving) | Money check-in | Vanguard 2025; prosocial spending | M | Needs Emin |
| N11 | **Rehearse a big moment** (random question, 2-minute timer, STAR check) | Story bank | Weak | S | Built |
| N12 | **Make and play** (weekly line, template) | Daily library, growth | Conner 2018; Proyer 2020 | S | Built |

Rejected: brain games (no transfer), readiness scores and energy curves (invented numbers), app blocking (phone plumbing). Nutrition only as a plan pack, if at all (Emin to decide).

### O. Tenth pass: the whole of life (19 Oct 2026)
Ranked by value for effort. Effect sizes marked (abstract) were read from abstracts only.

| # | Idea | Evidence | Status |
|---|---|---|---|
| O1 | **Someone you lost**: stop nudging about a person who has died; a place to remember them | Web grief interventions, meta-analysis 2025: grief SMD −0.30 (abstract); structured writing works best (Wagner et al. 2020) | Built: `/remember`, "Remember them" |
| O2 | **Load check** (burnout before the crash): one item a month, where the load comes from | Single-item burnout measure r ≈ 0.8 with exhaustion (Dolan et al. 2015; Hansen & Pit 2016); prevention evidence mixed | Built: month reviews, brief |
| O3 | **Savour a good thing**: once a week, stay with one win; who you told | Savouring RCTs meta-analysis 2026, g = 0.51 (abstract); capitalization (Gable et al. 2004) | Built: Sunday report |
| O4 | **Your tools first**: fight tool overload | App engagement meta-analysis (JAMA Psychiatry 2025): retention, not uptake, is the failure | Built: Me groups fold, "Used lately" |
| O5 | **Something changed** (moving, new job, baby, breakup): 90 days of re-cueing | Habit discontinuity (Verplanken & Roy 2016) | Proposed |
| O6 | **Giving time**: contribution beyond your circle, inside kindness | Volunteering and mortality in cohorts (Okun et al. 2013; Jenkinson et al. 2013); RCT in teens (Schreier et al. 2013) | Proposed |
| O7 | **A practice of your own**: prayer, meditation, a day of rest — named in your words; loving-kindness timer | Loving-kindness meta-analysis (Zeng et al. 2015); meaning interventions (Manco & Hamby 2021) | Proposed |
| O8 | **Parent and child**: child-appropriate questions, "10 minutes they lead" ritual | Parenting programme components (Leijten et al. 2018/2019) | Proposed |
| O9 | Phone on your terms (= N8) | Mixed (Radtke et al. 2022) | Waiting on Emin |
| O10 | Two more portions of fruit and vegetables, one daily idea | Conner et al. 2017 (proof of concept) | Proposed, low value |

To reduce load: merge brag document, the case for the target role and the coach report into one "Your record"; fold role models into the personal board; keep rehearse inside the story bank only. These remove tools people may use, so they wait for Emin's decision.

### E. Relationships
| # | Feature | For Emin now | For anyone | Evidence | Effort |
|---|---|---|---|---|---|
| E1 | **Relationship rituals** in People (a weekly date, family time, a monthly call; quality, not just contact) | Home, not only work contacts | Partners, parents, friends | Rituals and "turning toward" (Gottman) | S |
| E2 | **Gratitude letter** (write it, deliver it, note what happened) | Ali, a mentor, family | Anyone | Strongest short-term effect in Seligman et al. 2005 | S |

### F. Foundations for the general product
| # | Feature | For Emin now | For anyone | Effort |
|---|---|---|---|---|
| F1 | **Profile editor** (roles, organisation, key people, path, coach context) | Change details without code | Step 1 of onboarding | M |
| F2 | **Configurable Daily items** (add, remove, retire when automatic, with cues) | Adjust as habits stick | Required for a general app | M |
| F3 | **Onboarding that builds a plan in 5 minutes** (profile → goal → growth area from a template → 3–5 Daily items) | — | Solves the "no value in the first session" churn | L |
| F4 | **A calmer Today** (rank cards; show the 1–3 that matter now, the rest behind "More") | Today is crowded | Reduces choice overload | M |
| F5 | **Languages** (English, Azerbaijani, Russian) | Native-language reflection is deeper | His home market first | M |
| F6 | **Plan packs** (shareable plans: "First-time manager, 90 days", "16-week marathon", "New parent") | Share his own plan | Growth engine for the mass version | L |
| F7 | **Coach mode** (a human coach sees a client's plan, with consent) | — | A future B2B2C model | L |
| F8 | **Privacy and data ownership** (export, delete, on-device by default, clear sync consent) | His health data | Trust is a precondition for adoption | M |

### Suggested order
1. **Now (useful to Emin, foundation for everyone):** A1 Goals → C1 progress note → D1 setback protocol → A2 quarterly review → F1 profile editor.
2. **Next:** F4 calmer Today → F2 configurable Daily items → B1 level descriptions → B2 learning queue → E1 relationship rituals.
3. **For the mass version:** F3 onboarding → F5 languages → F8 privacy → F6 plan packs → C3 partners → F7 coach mode.

## Sources
- [Baumel et al. 2019, mental-health app engagement (JMIR)](https://www.textbookofdigitalhealth.com/references/baumel2019engagement.html)
- [Habit tracking in 2026: trends and data](https://habit-streak.com/en/blog/habit-tracking/state-of-habit-tracking-2026)
- [Best habit apps ranked by how long people stay](https://www.routinery.app/blog/best-habit-apps-ranked-by-how-long-people-stay)
- [Why users stop using productivity apps](https://foxdata.com/en/blogs/why-users-stop-using-productivity-apps-and-how-to-fix-it)
- [Braze: mobile app retention](https://www.braze.com/resources/articles/mobile-app-retention-10-tip.md)
- [Harkin et al. 2016, monitoring goal progress (White Rose eprints)](https://eprints.whiterose.ac.uk/91437/)
- [Gollwitzer & Sheeran 2006, implementation intentions](https://stafforini.com/works/gollwitzer-2006-implementation-intentions-and/)
- [Cross & Sheffield, mental contrasting meta-analysis (EHPS)](https://ehps.net/ehp/index.php/contents/article/view/2884)
- [Theeboom et al. 2014, does coaching work? (VU Amsterdam)](https://research.vu.nl/en/publications/does-coaching-work-a-meta-analysis-on-the-effects-of-coaching-on-/)
- [Accountability psychology: when it works and backfires](https://goalsandprogress.com/accountability-psychology-research/)
- [AI coaching platforms compared (Risely, a competitor)](https://risely.me/compare/best-ai-coaching-platforms/)
- [Rocky.ai on the App Store](https://apps.apple.com/app/id1492680249)
- [Personal development market (Mordor Intelligence)](https://www.mordorintelligence.com/industry-reports/personal-development-market)
- Academic references in section 5 (not linked):
  - Locke & Latham 2002, *American Psychologist*.
  - Dai, Milkman & Riis 2014, *Management Science*.
  - Oyserman 2007, identity-based motivation.
  - Baldwin & Ford 1988, *Personnel Psychology*.
  - Roediger & Karpicke 2006, *Psychological Science*.
  - London & Smither 1995, *Personnel Psychology*.
  - Breines & Chen 2012, *Personality and Social Psychology Bulletin*.
  - Sonnentag & Fritz 2007, *Journal of Occupational Health Psychology*.
  - Seligman et al. 2005, *American Psychologist*.

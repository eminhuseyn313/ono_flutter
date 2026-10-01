import 'dart:math';

import '../models/council.dart';
import 'council_gateway.dart';

class MockCouncilGateway implements CouncilGateway {
  final List<CouncilSession> _sessions = [];
  int _questionsToday = 1;
  final _random = Random();

  MockCouncilGateway() {
    _seedHistory();
  }

  // ─── RESPONSE TEMPLATES ─────────────────────────────────────────────────

  static const Map<String, _MemberTemplates> _templates = {
    'kobe': _MemberTemplates(
      tone: CouncilTone.motivational,
      responses: [
        'The answer to your question is in the work you haven\'t done yet. I used to shoot 800 jump shots before the sun came up while others slept. You\'re asking "{q}" — but have you put in the hours that earn you the right to ask? Stop looking for the shortcut. Fall in love with the process, and the results will chase you.',
        'I hear your question about {q}, and here\'s the Mamba Mentality take: obsess over the details. When I studied every single opponent\'s move, I wasn\'t being paranoid — I was being prepared. Break your challenge into micro-skills. Master each one. The big picture takes care of itself when the small pieces are perfect.',
        'You want to know about {q}? Let me tell you something — the separation is in the preparation. Everyone wants the highlight reel. Nobody wants the 4 AM gym sessions. Your answer isn\'t in some strategy or hack. It\'s in doing the work nobody else is willing to do, every single day, when nobody is watching.',
        'Regarding {q} — I never feared failure. I feared being mediocre. Every miss was data, every loss was a lesson. You\'re overthinking this. Take the shot. Miss. Adjust. Take it again. The only way you truly fail is if you stop shooting.',
        'Listen, {q} comes down to one thing: how bad do you want it? I didn\'t become who I was because I was the most talented. I became who I was because while everyone else was sleeping, partying, or making excuses, I was in the gym. Your move.',
        'Here\'s what I learned about {q}: rest is a weapon, not a weakness. I trained harder than anyone — but I also recovered harder. Study, prepare, execute, rest, repeat. It\'s not complicated. It\'s just not easy. And that\'s exactly why most people will never do it.',
      ],
    ),
    'goggins': _MemberTemplates(
      tone: CouncilTone.toughLove,
      responses: [
        'You\'re asking about {q}? Let me be real with you — you already know the answer. You\'re just looking for someone to tell you it\'s going to be comfortable. It won\'t be. The path forward is through the pain you\'re trying to avoid. Get off the couch. Stop negotiating with yourself. Start doing the thing that scares you most.',
        'When it comes to {q}, here\'s the truth nobody wants to hear: you\'re not even close to your potential. That voice telling you to quit, to take the easy road, to play it safe — that\'s the governor. Override it. You\'ve got 60% left in the tank that you haven\'t even touched. Go find out who you really are.',
        '{q}? I was 300 pounds, broken, going nowhere. You know what changed? I stopped making excuses and started making myself uncomfortable on purpose. Your situation isn\'t worse than mine was. You\'re just more committed to your comfort than your growth. Change that today. Not tomorrow. Today.',
        'Here\'s my answer on {q}: suffering is the real currency of growth. Every time life gets hard, that\'s the universe handing you a callus-building opportunity. Don\'t run from it. Run toward it. The person you need to become is on the other side of the thing you don\'t want to do.',
        'Stop asking about {q} and start doing something about it. I don\'t care if you\'re tired. I don\'t care if you\'re scared. I don\'t care if people doubt you. The only opinion that matters is the one you see in the accountability mirror. Look yourself in the eyes and ask: "Am I giving everything I have?" You know the answer.',
        'About {q} — go write it on your accountability mirror right now. Look at it every morning. Then go do the hardest thing on your list first. Not the easiest. The hardest. That\'s how you build an unbreakable mind. Comfort is a slow death. Choose the hard path.',
      ],
    ),
    'aurelius': _MemberTemplates(
      tone: CouncilTone.philosophical,
      responses: [
        'Regarding {q} — remember this: you have power over your mind, not outside events. The obstacle you face is not the circumstance itself but your perception of it. Strip away your judgment of the situation and see it plainly. What remains is simply what is. And what is can be worked with.',
        'On the matter of {q}: how much time have you wasted on things outside your control? The weather of fortune changes constantly — this is its nature. Your task is not to calm the storm but to build a steady ship. Focus only on your character, your choices, your response. Everything else is smoke.',
        'You ask about {q}, and I will tell you what I told myself each morning: today you will meet interference, ingratitude, and difficulty. But none of these can truly harm you unless you decide they can. The impediment to action advances action. What stands in the way becomes the way.',
        'Consider this about {q}: death stands beside you every moment. Not to frighten, but to clarify. With your remaining time, will you spend it worrying about what others think? Chasing approval? Or will you do the work that your nature demands? Time is the one resource you cannot earn back. Act accordingly.',
        '{q} — the Stoic answer is this: amor fati. Love your fate. Not merely bear it, but love it. Everything that happens to you is material for your growth. The fire that melts butter forges steel. Decide which one you are.',
        'On {q}: look inward. The happiness and peace you seek are not in external achievement or the opinions of others. They reside in the quality of your thoughts. Begin each morning reminding yourself what is truly in your control. End each evening asking whether you acted with virtue. The rest is noise.',
      ],
    ),
    'naval': _MemberTemplates(
      tone: CouncilTone.practical,
      responses: [
        'On {q} — the real question is whether you\'re building specific knowledge or generic skills. Specific knowledge is found by pursuing your genuine curiosity. It\'s the thing that feels like play to you but looks like work to others. That\'s your unfair advantage. Stop trying to compete where everyone else is competing.',
        'Regarding {q}: leverage is the key. There are three kinds — labor, capital, and products with no marginal cost of replication (code and media). The last one is the great equalizer. You don\'t need permission or money to start. Build something once that works while you sleep.',
        '{q} — here\'s what I\'d think about: desire is a contract you make with yourself to be unhappy until you get what you want. Can you reframe this so you\'re playing a game you enjoy, regardless of the outcome? The people who do the best work are the ones who\'d do it for free.',
        'Let me address {q} this way: wealth isn\'t about money. It\'s about having assets that earn while you sleep. If you\'re trading time for money, you\'re on a treadmill. Figure out how to productize yourself. Turn your unique skills into something that can scale without your direct time.',
        'About {q}: read more, especially foundational texts. Read what you love until you love to read. The best returns in life come from compound knowledge. One good mental model applied consistently beats a hundred tactics you read in a blog post.',
        'My perspective on {q}: happiness is a skill, not a circumstance. It\'s the absence of desire, the state of not wanting anything else. If your answer to this question requires something external to change, you\'re already on the wrong track. Work on your internal state first, then the external game becomes much clearer.',
      ],
    ),
    'huberman': _MemberTemplates(
      tone: CouncilTone.scientific,
      responses: [
        'From a neuroscience perspective on {q}: your brain\'s anterior mid-cingulate cortex grows when you do things you don\'t want to do. This is literally the brain region associated with tenacity and willpower. Every time you push through resistance, you\'re physically building this structure. The science supports doing hard things — it rewires you for resilience.',
        'Regarding {q}, let me share the science: dopamine is not about reward — it\'s about pursuit. The anticipation of the goal releases more dopamine than achieving it. So structure your approach in milestones. Create checkpoints. Your neurochemistry will keep you motivated if you give it regular "wins" along the way.',
        'On {q}: there\'s a protocol for this. First, get your morning sunlight — 10 minutes within the first hour of waking. This sets your circadian rhythm and cortisol peak properly. When your biology is optimized, your decision-making and focus improve dramatically. Solve the foundation before you tackle the complex problem.',
        'Here\'s what the research says about {q}: deliberate cold exposure (1-3 minutes in cold water) increases norepinephrine by 200-300%. This enhances focus, mood, and resilience for hours afterward. Before tackling your challenge, give your system a neurochemical advantage. Stack the biological deck in your favor.',
        'Concerning {q}: the key mechanism is neuroplasticity — your brain\'s ability to rewire. This requires focus, repetition, and crucially, deep sleep. You cannot learn or adapt without quality sleep. Whatever strategy you pursue, protect your 7-9 hours. Growth happens during rest, not during the grind.',
        'Let me reframe {q} through a biological lens: stress is not inherently bad. Short-term stress (eustress) activates your sympathetic nervous system and sharpens performance. The problem is chronic stress without recovery. Use the physiological sigh — double inhale through the nose, long exhale through the mouth — to shift your state in real time. Then approach your challenge from a place of calm focus.',
      ],
    ),
    'hormozi': _MemberTemplates(
      tone: CouncilTone.practical,
      responses: [
        'On {q}: volume negates luck. Most people fail because they don\'t do enough reps. They send 10 emails and wonder why nobody responds. Send 1,000. They make 5 offers and think the market is dead. Make 500. The math is simple — the more attempts you make, the more you learn, and the luckier you get.',
        'About {q} — here\'s the framework: make your offer so good people feel stupid saying no. Whatever you\'re trying to achieve, ask yourself: "How can I make this a no-brainer?" Stack so much value that the cost becomes irrelevant. That\'s how you win in any arena.',
        'Regarding {q}: skills are the real asset. They can\'t be taken from you, they compound over time, and they make you more valuable every year. Stop optimizing for short-term gains. Invest the next 12 months in becoming undeniable at one thing. The money follows competence.',
        'Let me be direct about {q}: you\'re probably overthinking and underexecuting. I\'ve seen it a thousand times. The person who takes imperfect action beats the person with the perfect plan every single time. Ship it. Get feedback. Iterate. Speed of implementation is your competitive advantage.',
        '{q} — the answer is in your price. Most people undercharge because they\'re scared of rejection. But low price attracts bad clients and burns you out. Charge what you\'re worth, deliver 10x that value, and you\'ll never worry about competition again. The premium market is less crowded than you think.',
        'Here\'s my take on {q}: track everything. What gets measured gets managed. If you can\'t tell me your numbers — conversion rate, response rate, hours invested, output per day — you\'re flying blind. Get the data first. Feelings lie. Numbers don\'t.',
      ],
    ),
    'cr7': _MemberTemplates(
      tone: CouncilTone.motivational,
      responses: [
        'About {q}: talent is nothing without hard work. I wasn\'t born the best — I made myself the best. While others left training, I stayed. While others partied, I recovered. While others were satisfied, I wanted more. Your talent is your starting point, not your ceiling. The ceiling is set by your work ethic.',
        '{q}? Let me tell you — I was a skinny kid from Madeira with a funny accent. People laughed at me. I didn\'t argue. I let my work speak. Today, nobody is laughing. Whatever doubts people have about you, use them as fuel. Prove them wrong not with words but with results.',
        'On {q}: I believe in being the hardest worker in the room. Every room. Always. When you commit to that standard, the question answers itself. The people who achieve great things aren\'t necessarily the smartest — they\'re the ones who refused to be outworked.',
        'Regarding {q}: set your goals so high that people think you\'re crazy. When I said I wanted to be the best in the world, people laughed. Good. Their doubt was my breakfast. Your ambition should scare you a little. If it doesn\'t, you\'re not dreaming big enough.',
        'My answer on {q}: consistency beats everything. I didn\'t become who I am in one season. It took years of showing up every single day. Rain or shine, motivated or not, healthy or nursing injuries. Show up. Do the work. Let the compound effect do the rest.',
        'Here\'s the truth about {q}: take care of your body and your body will take care of your dreams. Sleep properly. Eat clean. Train smart. Recovery is not laziness — it\'s strategy. I\'m still performing at the highest level because I treat my body like the machine it is.',
      ],
    ),
    'bruce_lee': _MemberTemplates(
      tone: CouncilTone.philosophical,
      responses: [
        'On {q}: be water, my friend. Water can flow, or it can crash. Don\'t commit rigidly to one approach. Adapt. The person who is fluid in their thinking will find the opening that the rigid person misses. Empty your cup so it can be filled with something new.',
        'Regarding {q}: I fear not the man who has practiced 10,000 kicks once, but the man who has practiced one kick 10,000 times. Depth beats breadth. Find the essential technique for your situation and master it completely. Simplicity is the ultimate sophistication.',
        '{q} — absorb what is useful, discard what is useless, and add what is specifically your own. Don\'t copy anyone\'s path entirely. Take the principles that resonate with your nature and forge them into something original. The highest form of mastery is self-expression.',
        'Here is my perspective on {q}: knowing is not enough, you must apply. Willing is not enough, you must do. The gap between knowledge and action is where most people live their entire lives. Cross that gap today. One decisive step is worth a thousand plans.',
        'About {q}: do not pray for an easy life. Pray for the strength to endure a difficult one. Your challenge is not a punishment — it is a forge. The sword is made sharp by the stone, not by sitting in its sheath. Welcome the friction.',
        'On {q}: a goal is not always meant to be reached; it often serves simply as something to aim at. The real value is in who you become on the journey. Don\'t fixate on the destination so much that you miss the transformation happening right now, in this moment.',
      ],
    ),
    'arnold': _MemberTemplates(
      tone: CouncilTone.motivational,
      responses: [
        'Let me tell you about {q}: the mind is the limit. When I was 15 in Austria, I saw a magazine with a bodybuilder and said "That will be me." Everyone laughed. I became Mr. Olympia seven times. Then they said I couldn\'t act. I became the biggest action star in the world. Visualize it. Believe it. Then work for it.',
        'On {q}: you need a vision so clear you can taste it. I used to visualize every rep, every pose, every scene before it happened. Your brain doesn\'t fully distinguish between vivid imagination and reality. Use that. See yourself succeeding in detail. Then let your body follow where your mind has already been.',
        '{q}? Here\'s my rule: have a plan. Follow the plan. The plan will work. But you have to trust the process. When I trained for Mr. Olympia, I had every workout scheduled for the entire year. No guessing, no wondering what to do next. Plan your work, then work your plan.',
        'About {q}: strength does not come from winning. Your struggles develop your strength. When you go through hardships and decide not to surrender, that is strength. I failed plenty of times. Every failure taught me something no success could.',
        'Regarding {q}: don\'t be afraid to fail. In every one of my movies, I\'ve done things that didn\'t work. In business, in politics, same thing. But I showed up again the next day. You only truly fail when you stop trying. The comeback is always stronger than the setback.',
        'My advice on {q}: help others along the way. No one succeeds alone. I had mentors who believed in me, training partners who pushed me, and a community that supported me. Build your team. Lift others up. Success that isn\'t shared is hollow.',
      ],
    ),
    'jocko': _MemberTemplates(
      tone: CouncilTone.toughLove,
      responses: [
        'On {q}: good. That\'s my answer. Didn\'t get the promotion? Good. More time to develop. Got injured? Good. Time to work on your weaknesses. Lost everything? Good. Now you can start from a clean slate. Stop seeing obstacles as problems. They\'re opportunities to get better.',
        '{q} — this comes down to extreme ownership. Whatever situation you\'re in, you put yourself there. Not your boss, not the economy, not bad luck. You. Once you own that completely — no excuses, no blame — you gain the power to change it. Ownership is freedom.',
        'Regarding {q}: discipline equals freedom. You want more freedom in your life? Get more disciplined. Wake up early. Stick to the schedule. Do what you said you\'d do, especially when you don\'t feel like it. The undisciplined life is actually the one with the least freedom.',
        'About {q}: detach. Step back from the emotion. See the situation from above, like you\'re looking at a battlefield map. When you\'re too close to the problem, you can\'t see the solution. Detach. Assess. Decide. Execute. That\'s the leadership framework and it works in every area of life.',
        'My perspective on {q}: default aggressive. Don\'t wait for the perfect moment. Don\'t wait for more information. Don\'t wait for someone else to go first. When you see a problem, move toward it. When you have a decision to make, make it. Speed and decisiveness beat perfection.',
        'Here\'s the deal with {q}: check your ego. The ego clouds judgment, kills teamwork, and blocks learning. The best operators I served with were the most humble. They listened. They adapted. They put the mission above their pride. Do the same with your challenge.',
      ],
    ),
  };

  // ─── SEED DATA ──────────────────────────────────────────────────────────

  void _seedHistory() {
    final now = DateTime.now();

    _sessions.addAll([
      CouncilSession(
        id: 'seed_1',
        question: 'How do I stay motivated when progress feels slow?',
        responses: [
          const CouncilResponse(
            memberId: 'goggins',
            memberName: 'David Goggins',
            advice:
                'Slow progress? That\'s your ego talking. You\'re comparing yourself to some fantasy version of success. Look back at where you were 6 months ago. If you did the work, you\'re further ahead. If you didn\'t, that\'s not slow progress — that\'s no progress. Stop feeling sorry for yourself and get after it.',
            tone: CouncilTone.toughLove,
          ),
          const CouncilResponse(
            memberId: 'aurelius',
            memberName: 'Marcus Aurelius',
            advice:
                'The river does not rush to the sea, yet it arrives with certainty. Your impatience is a form of arrogance — a belief that you deserve faster results than the natural order provides. Focus not on the distance remaining but on the virtue of each step. Progress measured in character is never slow.',
            tone: CouncilTone.philosophical,
          ),
          const CouncilResponse(
            memberId: 'kobe',
            memberName: 'Kobe Bryant',
            advice:
                'When I was developing my footwork, it took two full summers before it became instinct. Two summers of the same drills, every single day. You know what separated that from wasted time? I loved the process. Fall in love with the daily work and stop watching the scoreboard. The score takes care of itself.',
            tone: CouncilTone.motivational,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 2)),
        isFavorited: true,
      ),
      CouncilSession(
        id: 'seed_2',
        question:
            'Should I quit my stable job to pursue my passion full-time?',
        responses: [
          const CouncilResponse(
            memberId: 'naval',
            memberName: 'Naval Ravikant',
            advice:
                'The real question isn\'t quit or stay — it\'s whether your passion can create leverage. Can you build something with your specific knowledge that scales without your time? If yes, start building it on the side first. Don\'t burn the bridge until the new one can hold your weight. But also don\'t wait forever — the perfect moment is a myth.',
            tone: CouncilTone.practical,
          ),
          const CouncilResponse(
            memberId: 'hormozi',
            memberName: 'Alex Hormozi',
            advice:
                'Here\'s what I\'d do: keep the job, but give your passion every spare hour. Nights, weekends, early mornings. When your side income matches 60% of your salary for 3 consecutive months, then quit. That\'s not a feeling — that\'s a number. Make decisions based on data, not emotions.',
            tone: CouncilTone.practical,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      CouncilSession(
        id: 'seed_3',
        question: 'How do I build unshakable confidence?',
        responses: [
          const CouncilResponse(
            memberId: 'arnold',
            memberName: 'Arnold Schwarzenegger',
            advice:
                'Confidence isn\'t born — it\'s built. Every time I stepped on that bodybuilding stage, my confidence came from the thousands of hours in the gym. You can\'t fake preparation. Do the reps. Put in the work. When you\'ve done more than anyone else in the room, confidence isn\'t something you need to summon — it\'s just there.',
            tone: CouncilTone.motivational,
          ),
          const CouncilResponse(
            memberId: 'bruce_lee',
            memberName: 'Bruce Lee',
            advice:
                'True confidence is not thinking you are better than others. It is knowing that you do not need to compare yourself to anyone at all. Empty your mind of the need for validation. When you are complete within yourself, external opinions become irrelevant. Confidence is stillness, not noise.',
            tone: CouncilTone.philosophical,
          ),
          const CouncilResponse(
            memberId: 'jocko',
            memberName: 'Jocko Willink',
            advice:
                'Confidence comes from competence. And competence comes from reps. There\'s no shortcut. Want to be confident in public speaking? Give 100 talks. Want to be confident in business? Start 3 businesses and fail at 2. Confidence is earned through action, not affirmation. Get to work.',
            tone: CouncilTone.toughLove,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 8)),
        isFavorited: true,
      ),
    ]);
  }

  // ─── GATEWAY METHODS ────────────────────────────────────────────────────

  @override
  Future<CouncilSession> askCouncil(
    String question,
    List<String> selectedMemberIds,
  ) async {
    await Future.delayed(
      Duration(milliseconds: 150 + _random.nextInt(100)),
    );

    final responses = <CouncilResponse>[];
    for (final memberId in selectedMemberIds) {
      final member = CouncilMember.findById(memberId);
      if (member == null) continue;

      final templates = _templates[memberId];
      if (templates == null) continue;

      final templateIndex = _random.nextInt(templates.responses.length);
      final template = templates.responses[templateIndex];
      final shortQ = question.length > 60
          ? '${question.substring(0, 57)}...'
          : question.toLowerCase();
      final advice = template.replaceAll('{q}', shortQ);

      responses.add(CouncilResponse(
        memberId: memberId,
        memberName: member.name,
        advice: advice,
        tone: templates.tone,
      ));

      // Stagger each response slightly
      await Future.delayed(
        Duration(milliseconds: 150 + _random.nextInt(100)),
      );
    }

    final session = CouncilSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      question: question,
      responses: responses,
      createdAt: DateTime.now(),
    );

    _sessions.insert(0, session);
    _questionsToday++;

    return session;
  }

  @override
  Future<List<CouncilSession>> loadHistory() async {
    await Future.delayed(
      Duration(milliseconds: 150 + _random.nextInt(100)),
    );
    return List.unmodifiable(_sessions);
  }

  @override
  Future<CouncilSession?> loadSession(String id) async {
    await Future.delayed(
      Duration(milliseconds: 150 + _random.nextInt(100)),
    );
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CouncilSession> toggleFavorite(String sessionId) async {
    await Future.delayed(
      Duration(milliseconds: 150 + _random.nextInt(100)),
    );

    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) throw Exception('Session not found');

    final updated = _sessions[index].copyWith(
      isFavorited: !_sessions[index].isFavorited,
    );
    _sessions[index] = updated;
    return updated;
  }

  @override
  Future<CouncilQuota> getQuota() async {
    await Future.delayed(
      Duration(milliseconds: 150 + _random.nextInt(100)),
    );

    final now = DateTime.now();
    final resetAt = DateTime(now.year, now.month, now.day + 1);

    return CouncilQuota(
      questionsToday: _questionsToday,
      maxPerDay: 3,
      resetAt: resetAt,
    );
  }
}

// ─── HELPER CLASS ───────────────────────────────────────────────────────────

class _MemberTemplates {
  final CouncilTone tone;
  final List<String> responses;

  const _MemberTemplates({
    required this.tone,
    required this.responses,
  });
}

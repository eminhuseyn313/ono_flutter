class Archetype {
  final String id;
  final String emoji;
  final String title;
  final String tagline;
  final String description;

  const Archetype({
    required this.id,
    required this.emoji,
    required this.title,
    required this.tagline,
    required this.description,
  });
}

class BlueprintDomain {
  final String name;
  final String emoji;
  final List<String> actions;
  final bool active;

  const BlueprintDomain({
    required this.name,
    required this.emoji,
    required this.actions,
    this.active = true,
  });
}

class AssessmentQuestion {
  final String question;
  final List<String> options;

  const AssessmentQuestion({
    required this.question,
    required this.options,
  });
}

// Static data
class AppData {
  static const List<Archetype> archetypes = [
    Archetype(
      id: 'executive',
      emoji: '🏆',
      title: 'The Executive',
      tagline: 'Leads with authority',
      description: 'Strategic, decisive, commands respect',
    ),
    Archetype(
      id: 'athlete',
      emoji: '💪',
      title: 'The Athlete',
      tagline: 'Built and disciplined',
      description: 'Peak performance, physical excellence',
    ),
    Archetype(
      id: 'creative',
      emoji: '🎨',
      title: 'The Creative',
      tagline: 'Original and expressive',
      description: 'Unique perspective, artistic vision',
    ),
    Archetype(
      id: 'intellectual',
      emoji: '📚',
      title: 'The Intellectual',
      tagline: 'Sharp and well-read',
      description: 'Wisdom, depth, continuous learning',
    ),
    Archetype(
      id: 'entrepreneur',
      emoji: '🚀',
      title: 'The Entrepreneur',
      tagline: 'Bold and driven',
      description: 'Builder, risk-taker, visionary',
    ),
    Archetype(
      id: 'gentleman',
      emoji: '👔',
      title: 'The Gentleman',
      tagline: 'Refined and magnetic',
      description: 'Polished, charming, impeccable presence',
    ),
  ];

  static const List<AssessmentQuestion> questions = [
    AssessmentQuestion(
      question: 'What\'s your current fitness level?',
      options: ['Never gym', 'Occasionally', '3x per week', 'Daily training'],
    ),
    AssessmentQuestion(
      question: 'How would you describe your style?',
      options: ['No system', 'Basic', 'Developing', 'Sharp'],
    ),
    AssessmentQuestion(
      question: 'Where are you in your career?',
      options: ['Student', 'Early career', 'Mid career', 'Senior'],
    ),
    AssessmentQuestion(
      question: 'How often do you read?',
      options: ['Never', 'Monthly', 'Weekly', 'Daily'],
    ),
    AssessmentQuestion(
      question: 'How confident are you socially?',
      options: ['Anxious', 'Okay', 'Confident', 'Very confident'],
    ),
    AssessmentQuestion(
      question: 'Is your LinkedIn profile complete?',
      options: ['Empty', 'Basic', 'Good', 'Optimised'],
    ),
    AssessmentQuestion(
      question: 'Describe your mornings',
      options: ['Chaotic', 'Okay', 'Routine', 'Optimised'],
    ),
    AssessmentQuestion(
      question: 'What\'s your biggest weakness?',
      options: ['Consistency', 'Focus', 'Confidence', 'Direction'],
    ),
    AssessmentQuestion(
      question: 'Who do you admire most?',
      options: ['Athlete', 'CEO / Founder', 'Artist', 'Intellectual'],
    ),
    AssessmentQuestion(
      question: 'When do you want to see results?',
      options: ['1 month', '3 months', '6 months', '1 year'],
    ),
  ];

  static List<BlueprintDomain> getDomains() => [
    const BlueprintDomain(
      name: 'Career',
      emoji: '💼',
      actions: [
        'Optimise your LinkedIn headline',
        'Engage daily with industry content',
        'Write one post per week in your voice',
      ],
      active: true,
    ),
    const BlueprintDomain(
      name: 'Style',
      emoji: '👕',
      actions: [
        'Audit your wardrobe — remove what doesn\'t fit',
        'Book your barber every 3 weeks',
        'Build a signature grooming routine',
      ],
      active: true,
    ),
    const BlueprintDomain(
      name: 'Body',
      emoji: '💪',
      actions: [
        'Train 3–4x per week — progressive overload',
        'Hit 2g protein per kg bodyweight daily',
        'Sleep 7–8 hours — consistent wake time',
        'Walk 8,000+ steps on rest days',
        'Drink 3L water daily — track it',
      ],
      active: true,
    ),
    const BlueprintDomain(
      name: 'Intellect',
      emoji: '📚',
      actions: [
        'Read 20 pages per day — non-fiction or classics',
        'Listen to one long-form podcast per week',
        'Write a 5-minute journal entry each evening',
        'Learn one new concept or skill each week',
        'Replace 30 min of scrolling with reading',
      ],
      active: true,
    ),
    const BlueprintDomain(
      name: 'Social',
      emoji: '🗣',
      actions: [
        'Start one conversation with a stranger per week',
        'Reach out to one old friend each week',
        'Practice active listening — no interrupting',
        'Attend one social event or meetup per month',
        'Give one genuine compliment per day',
      ],
      active: true,
    ),
  ];
}

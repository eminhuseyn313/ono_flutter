/// Someone whose relationship matters to the plan: a manager, a coach, a
/// partner, a mentor. Their name lets features recognise them (in 1:1s
/// and the calendar); [every] is the contact rhythm in days.
class KeyPerson {
  final String name;
  final String relation;
  final int every;

  /// The person who sees your work most and whose feedback counts most
  /// (a manager, a coach). Used as the default "with" in 1:1s.
  final bool primary;

  const KeyPerson(this.name, this.relation,
      {this.every = 30, this.primary = false});

  Map<String, dynamic> toJson() =>
      {'name': name, 'relation': relation, 'every': every, 'primary': primary};
}

/// Who the plan is for. Every feature reads names, roles and goals from
/// here — never from strings in screens — so the same app serves a
/// product leader, an athlete, a founder or a parent.
class Profile {
  final String name;
  final String firstName;

  /// Where you are now and the next step you're growing into.
  final String currentRole;
  final String targetRole;

  /// The organisation, team or club, and what you own there.
  final String organisation;
  final String focus;

  /// The field to stay sharp in (scan, reading, the brief's domain notes).
  final String domain;

  final String identityStatement;
  final List<String> path;
  final List<KeyPerson> keyPeople;

  /// Everything the weekly coach should know about this person's system,
  /// health and protocols, in plain language.
  final String coachContext;

  const Profile({
    required this.name,
    required this.firstName,
    required this.currentRole,
    required this.targetRole,
    required this.organisation,
    required this.focus,
    required this.domain,
    required this.identityStatement,
    required this.path,
    required this.keyPeople,
    this.coachContext = '',
  });

  /// The primary person (manager or coach), or the first key person.
  String get manager {
    for (final p in keyPeople) {
      if (p.primary) return p.name;
    }
    return keyPeople.isEmpty ? '' : keyPeople.first.name;
  }

  /// "Ali and Rustam", "Ali", or "".
  String get keyPeopleNames {
    final n = [for (final p in keyPeople) p.name];
    if (n.length <= 1) return n.join();
    return '${n.sublist(0, n.length - 1).join(', ')} and ${n.last}';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'current_role': currentRole,
        'target_role': targetRole,
        'organisation': organisation,
        'focus': focus,
        'domain': domain,
        'identity_statement': identityStatement,
        'path': path,
        'key_people': [for (final p in keyPeople) p.toJson()],
        'context': coachContext,
      };
}

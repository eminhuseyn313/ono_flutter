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

  factory KeyPerson.fromJson(Map m) => KeyPerson(
        '${m['name'] ?? ''}',
        '${m['relation'] ?? ''}',
        every: (m['every'] as num?)?.toInt() ?? 30,
        primary: m['primary'] == true,
      );
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

  /// Who they are becoming, in a few words, and a line under it.
  final String archetype;
  final String tagline;
  final String location;

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
    this.archetype = '',
    this.tagline = '',
    this.location = '',
    required this.path,
    required this.keyPeople,
    this.coachContext = '',
  });

  /// "Senior PO — Business ID", or just the role.
  String get roleLine =>
      focus.isEmpty ? currentRole : '$currentRole — $focus';

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
        'first_name': firstName,
        'current_role': currentRole,
        'target_role': targetRole,
        'organisation': organisation,
        'focus': focus,
        'domain': domain,
        'identity_statement': identityStatement,
        'archetype': archetype,
        'tagline': tagline,
        'location': location,
        'path': path,
        'key_people': [for (final p in keyPeople) p.toJson()],
        'context': coachContext,
      };

  factory Profile.fromJson(Map m) {
    String s(String k) => '${m[k] ?? ''}';
    final name = s('name');
    return Profile(
      name: name,
      firstName: m['first_name'] != null
          ? s('first_name')
          : (name.split(' ').first),
      currentRole: s('current_role'),
      targetRole: s('target_role'),
      organisation: s('organisation'),
      focus: s('focus'),
      domain: s('domain'),
      identityStatement: s('identity_statement'),
      archetype: s('archetype'),
      tagline: s('tagline'),
      location: s('location'),
      path: [for (final p in (m['path'] as List? ?? const [])) '$p'],
      keyPeople: [
        for (final k in (m['key_people'] as List? ?? const []))
          KeyPerson.fromJson(k as Map)
      ],
      coachContext: s('context'),
    );
  }

  Profile copyWith({
    String? name,
    String? firstName,
    String? currentRole,
    String? targetRole,
    String? organisation,
    String? focus,
    String? domain,
    String? identityStatement,
    String? archetype,
    String? tagline,
    String? location,
    List<String>? path,
    List<KeyPerson>? keyPeople,
    String? coachContext,
  }) =>
      Profile(
        name: name ?? this.name,
        firstName: firstName ?? this.firstName,
        currentRole: currentRole ?? this.currentRole,
        targetRole: targetRole ?? this.targetRole,
        organisation: organisation ?? this.organisation,
        focus: focus ?? this.focus,
        domain: domain ?? this.domain,
        identityStatement: identityStatement ?? this.identityStatement,
        archetype: archetype ?? this.archetype,
        tagline: tagline ?? this.tagline,
        location: location ?? this.location,
        path: path ?? this.path,
        keyPeople: keyPeople ?? this.keyPeople,
        coachContext: coachContext ?? this.coachContext,
      );
}

Profile? _override;

/// Replaces the built-in profile with one the person edited (or null to
/// go back to the built-in one). Set by the provider on load and on save.
void setProfileOverride(Profile? p) => _override = p;
Profile? get profileOverride => _override;

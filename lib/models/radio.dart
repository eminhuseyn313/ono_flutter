/// Radio feature models for Role Model Radio.

enum RadioChannel {
  theirWords,
  soundtrack,
  library,
}

enum RadioPlatform {
  spotify,
  youtube,
  applePodcasts,
  amazon,
  web,
}

class RadioItem {
  final String id;
  final String roleModelId;
  final RadioChannel channel;
  final String title;
  final String subtitle;
  final String description;
  final String? imageUrl;
  final String externalUrl;
  final RadioPlatform platform;
  final Duration? duration;
  final bool isMorning;
  final bool isEvening;

  const RadioItem({
    required this.id,
    required this.roleModelId,
    required this.channel,
    required this.title,
    required this.subtitle,
    required this.description,
    this.imageUrl,
    required this.externalUrl,
    required this.platform,
    this.duration,
    this.isMorning = false,
    this.isEvening = false,
  });

  RadioItem copyWith({
    String? id,
    String? roleModelId,
    RadioChannel? channel,
    String? title,
    String? subtitle,
    String? description,
    String? imageUrl,
    String? externalUrl,
    RadioPlatform? platform,
    Duration? duration,
    bool? isMorning,
    bool? isEvening,
  }) {
    return RadioItem(
      id: id ?? this.id,
      roleModelId: roleModelId ?? this.roleModelId,
      channel: channel ?? this.channel,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      externalUrl: externalUrl ?? this.externalUrl,
      platform: platform ?? this.platform,
      duration: duration ?? this.duration,
      isMorning: isMorning ?? this.isMorning,
      isEvening: isEvening ?? this.isEvening,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roleModelId': roleModelId,
      'channel': channel.index,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imageUrl': imageUrl,
      'externalUrl': externalUrl,
      'platform': platform.index,
      'duration': duration?.inSeconds,
      'isMorning': isMorning,
      'isEvening': isEvening,
    };
  }

  factory RadioItem.fromJson(Map<String, dynamic> json) {
    return RadioItem(
      id: json['id'] as String,
      roleModelId: json['roleModelId'] as String,
      channel: RadioChannel.values[json['channel'] as int],
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      externalUrl: json['externalUrl'] as String,
      platform: RadioPlatform.values[json['platform'] as int],
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      isMorning: json['isMorning'] as bool? ?? false,
      isEvening: json['isEvening'] as bool? ?? false,
    );
  }
}

class RadioPlaylist {
  final String roleModelId;
  final String roleModelName;
  final String roleModelEmoji;
  final Map<RadioChannel, List<RadioItem>> channels;

  const RadioPlaylist({
    required this.roleModelId,
    required this.roleModelName,
    required this.roleModelEmoji,
    required this.channels,
  });

  RadioPlaylist copyWith({
    String? roleModelId,
    String? roleModelName,
    String? roleModelEmoji,
    Map<RadioChannel, List<RadioItem>>? channels,
  }) {
    return RadioPlaylist(
      roleModelId: roleModelId ?? this.roleModelId,
      roleModelName: roleModelName ?? this.roleModelName,
      roleModelEmoji: roleModelEmoji ?? this.roleModelEmoji,
      channels: channels ?? this.channels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleModelId': roleModelId,
      'roleModelName': roleModelName,
      'roleModelEmoji': roleModelEmoji,
      'channels': channels.map(
        (key, value) => MapEntry(
          key.index.toString(),
          value.map((item) => item.toJson()).toList(),
        ),
      ),
    };
  }

  factory RadioPlaylist.fromJson(Map<String, dynamic> json) {
    final channelsJson = json['channels'] as Map<String, dynamic>;
    final channels = <RadioChannel, List<RadioItem>>{};
    channelsJson.forEach((key, value) {
      final channel = RadioChannel.values[int.parse(key)];
      final items = (value as List)
          .map((item) => RadioItem.fromJson(item as Map<String, dynamic>))
          .toList();
      channels[channel] = items;
    });
    return RadioPlaylist(
      roleModelId: json['roleModelId'] as String,
      roleModelName: json['roleModelName'] as String,
      roleModelEmoji: json['roleModelEmoji'] as String,
      channels: channels,
    );
  }

  /// Get all items across all channels.
  List<RadioItem> get allItems {
    return channels.values.expand((items) => items).toList();
  }
}

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../gateways/radio_gateway.dart';
import '../models/radio.dart';

class RadioProvider extends ChangeNotifier {
  final RadioGateway _gateway;

  RadioProvider({required RadioGateway gateway}) : _gateway = gateway;

  final Map<String, RadioPlaylist> _playlists = {};
  List<RadioItem> _featuredItems = [];
  final Set<String> _listenedIds = {};
  bool _isLoading = false;
  String? _error;

  Map<String, RadioPlaylist> get playlists => _playlists;
  List<RadioItem> get featuredItems => _featuredItems;
  Set<String> get listenedIds => _listenedIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPlaylist(String roleModelId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final playlist = await _gateway.loadPlaylist(roleModelId);
      _playlists[roleModelId] = playlist;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllPlaylists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final all = await _gateway.loadAllPlaylists();
      for (final p in all) {
        _playlists[p.roleModelId] = p;
      }
      _featuredItems = await _gateway.loadFeaturedItems(_currentTimeOfDay());
      final listened = await _gateway.getListenedIds();
      _listenedIds.addAll(listened);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openItem(RadioItem item) async {
    final uri = Uri.parse(item.externalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    await _gateway.markAsListened(item.id);
    _listenedIds.add(item.id);
    notifyListeners();
  }

  List<RadioItem> filterByTimeOfDay(List<RadioItem> items) {
    final hour = DateTime.now().hour;
    final isMorning = hour >= 4 && hour < 12;
    final isEvening = hour >= 18 || hour < 4;

    if (isMorning) {
      final morning = items.where((i) => i.isMorning).toList();
      if (morning.isNotEmpty) return morning;
    }
    if (isEvening) {
      final evening = items.where((i) => i.isEvening).toList();
      if (evening.isNotEmpty) return evening;
    }
    return items;
  }

  int listenedCount(String roleModelId) {
    final playlist = _playlists[roleModelId];
    if (playlist == null) return 0;
    int count = 0;
    for (final items in playlist.channels.values) {
      count += items.where((i) => _listenedIds.contains(i.id)).length;
    }
    return count;
  }

  int totalCount(String roleModelId) {
    final playlist = _playlists[roleModelId];
    if (playlist == null) return 0;
    int count = 0;
    for (final items in playlist.channels.values) {
      count += items.length;
    }
    return count;
  }

  String _currentTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    return 'evening';
  }
}

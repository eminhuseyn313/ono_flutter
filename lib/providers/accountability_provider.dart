// providers/accountability_provider.dart

import 'package:flutter/foundation.dart';
import '../gateways/accountability_gateway.dart';
import '../models/accountability.dart';

class AccountabilityProvider extends ChangeNotifier {
  final AccountabilityGateway gateway;

  AccountabilityProvider({required this.gateway});

  List<AccountabilityPartner> _partners = [];
  List<PartnerRequest> _requests = [];
  List<SharedProof> _proofs = [];
  List<DailyCheckIn> _checkIns = [];
  AccountabilityStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  List<AccountabilityPartner> get partners => _partners;
  List<PartnerRequest> get requests => _requests;
  List<SharedProof> get proofs => _proofs;
  List<DailyCheckIn> get checkIns => _checkIns;
  AccountabilityStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<AccountabilityPartner> get activePartners =>
      _partners.where((p) => p.status == PartnerStatus.active).toList();

  List<AccountabilityPartner> get pausedPartners =>
      _partners.where((p) => p.status == PartnerStatus.paused).toList();

  Future<void> loadPartners() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _partners = await gateway.loadPartners();
    } catch (e) {
      _errorMessage = 'Failed to load partners';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _requests = await gateway.loadRequests();
    } catch (e) {
      _errorMessage = 'Failed to load requests';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProofs(String partnerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _proofs = await gateway.loadProofs(partnerId);
    } catch (e) {
      _errorMessage = 'Failed to load proofs';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCheckIns(String partnerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _checkIns = await gateway.loadCheckIns(partnerId);
    } catch (e) {
      _errorMessage = 'Failed to load check-ins';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStats() async {
    try {
      _stats = await gateway.loadStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load stats';
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        gateway.loadPartners(),
        gateway.loadRequests(),
        gateway.loadStats(),
      ]);
      _partners = results[0] as List<AccountabilityPartner>;
      _requests = results[1] as List<PartnerRequest>;
      _stats = results[2] as AccountabilityStats;
    } catch (e) {
      _errorMessage = 'Failed to load data';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllProofsAndCheckIns() async {
    try {
      final allProofs = <SharedProof>[];
      final allCheckIns = <DailyCheckIn>[];
      for (final partner in _partners) {
        final partnerProofs = await gateway.loadProofs(partner.id);
        final partnerCheckIns = await gateway.loadCheckIns(partner.id);
        allProofs.addAll(partnerProofs);
        allCheckIns.addAll(partnerCheckIns);
      }
      _proofs = allProofs;
      _checkIns = allCheckIns;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load feed';
      notifyListeners();
    }
  }

  Future<String?> sendRequest(String code) async {
    try {
      final generatedCode = await gateway.sendRequest(code);
      return generatedCode;
    } catch (e) {
      _errorMessage = 'Failed to send request';
      notifyListeners();
      return null;
    }
  }

  Future<bool> acceptRequest(String id) async {
    try {
      final newPartner = await gateway.acceptRequest(id);
      _requests.removeWhere((r) => r.id == id);
      _partners = [..._partners, newPartner];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to accept request';
      notifyListeners();
      return false;
    }
  }

  Future<bool> declineRequest(String id) async {
    final backup = List<PartnerRequest>.from(_requests);
    _requests.removeWhere((r) => r.id == id);
    notifyListeners();
    try {
      await gateway.declineRequest(id);
      return true;
    } catch (e) {
      _requests = backup;
      _errorMessage = 'Failed to decline request';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendProof(String partnerId, SharedProof proof) async {
    try {
      final sent = await gateway.sendProof(partnerId, proof);
      _proofs = [sent, ..._proofs];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send proof';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendCheckIn(String partnerId, DailyCheckIn checkIn) async {
    // Optimistic update
    _checkIns = [checkIn, ..._checkIns];
    notifyListeners();
    try {
      final sent = await gateway.sendCheckIn(partnerId, checkIn);
      _checkIns = [sent, ..._checkIns.skip(1)];
      notifyListeners();
      return true;
    } catch (e) {
      _checkIns = _checkIns.where((c) => c.id != checkIn.id).toList();
      _errorMessage = 'Failed to send check-in';
      notifyListeners();
      return false;
    }
  }

  Future<bool> pausePartnership(String id) async {
    try {
      final updated = await gateway.pausePartnership(id);
      _partners = _partners.map((p) => p.id == id ? updated : p).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to pause partnership';
      notifyListeners();
      return false;
    }
  }

  Future<bool> endPartnership(String id) async {
    try {
      await gateway.endPartnership(id);
      _partners = _partners
          .map((p) => p.id == id ? p.copyWith(status: PartnerStatus.ended) : p)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to end partnership';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

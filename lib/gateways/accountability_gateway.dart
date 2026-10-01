// gateways/accountability_gateway.dart

import '../models/accountability.dart';

abstract class AccountabilityGateway {
  Future<List<AccountabilityPartner>> loadPartners();
  Future<List<PartnerRequest>> loadRequests();
  Future<List<SharedProof>> loadProofs(String partnerId);
  Future<List<DailyCheckIn>> loadCheckIns(String partnerId);
  Future<AccountabilityStats> loadStats();
  Future<String> sendRequest(String code);
  Future<AccountabilityPartner> acceptRequest(String id);
  Future<void> declineRequest(String id);
  Future<SharedProof> sendProof(String partnerId, SharedProof proof);
  Future<DailyCheckIn> sendCheckIn(String partnerId, DailyCheckIn checkIn);
  Future<AccountabilityPartner> pausePartnership(String id);
  Future<void> endPartnership(String id);
}

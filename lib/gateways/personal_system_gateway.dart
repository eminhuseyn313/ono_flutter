import '../models/personal_system.dart';

abstract class PersonalSystemGateway {
  Future<PersonalSystemState> load(String userId);
  Future<void> save(String userId, PersonalSystemState state);
}

import 'health_service.dart';

/// Web: no Apple Health.
HealthService createHealthService() => const NoopHealthService();

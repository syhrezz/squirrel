import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/repositories/administration_repository.dart';
import '../models/admin_models.dart';

final _adminRepoProvider = Provider<AdministrationRepository>((ref) {
  return SupabaseAdministrationRepository(
    Supabase.instance.client,
    AppEnv.organizationId,
  );
});

final organizationProvider =
    FutureProvider.autoDispose<OrganizationInfo>((ref) =>
        ref.read(_adminRepoProvider).getOrganization());

final usersProvider =
    FutureProvider.autoDispose<List<UserSummary>>((ref) =>
        ref.read(_adminRepoProvider).getUsers());

final devicesProvider =
    FutureProvider.autoDispose<List<DeviceSummary>>((ref) =>
        ref.read(_adminRepoProvider).getDevices());

// Period: 'today' | '7d' | '30d'
class SyncPeriodNotifier extends Notifier<String> {
  @override
  String build() => '7d';
  void set(String v) => state = v;
}

final syncHealthPeriodProvider =
    NotifierProvider<SyncPeriodNotifier, String>(SyncPeriodNotifier.new);

final syncHealthProvider =
    FutureProvider.autoDispose<SyncHealth>((ref) {
  final period = ref.watch(syncHealthPeriodProvider);
  return ref.read(_adminRepoProvider).getSyncHealth(period);
});

final systemInfoProvider =
    FutureProvider.autoDispose<SystemInfo>((ref) =>
        ref.read(_adminRepoProvider).getSystemInfo());

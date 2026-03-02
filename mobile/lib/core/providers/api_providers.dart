import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/auth_storage.dart';
import '../api/favorites_storage.dart';
import '../api/recently_viewed_storage.dart';
import '../api/profile_storage.dart';
import '../models/booking_model.dart';
import '../models/message_thread_model.dart';
import '../models/service_category.dart';
import '../models/service_model.dart';
import '../repository/api_repository.dart';
import '../models/host_profile_model.dart';

final apiClientProvider = Provider<Dio>((ref) => createApiClient());

final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  return ApiRepository(ref.watch(apiClientProvider));
});

final serviceByIdProvider = FutureProvider.family<dynamic, String>((ref, id) async {
  return ref.read(apiRepositoryProvider).getServiceById(id);
});

final bookingByIdProvider = FutureProvider.family<dynamic, String>((ref, id) async {
  return ref.read(apiRepositoryProvider).getBookingById(id);
});

final threadByIdProvider = FutureProvider.family<dynamic, String>((ref, id) async {
  return ref.read(apiRepositoryProvider).getThread(id);
});

final categoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  try {
    return await ref.read(apiRepositoryProvider).getCategories();
  } catch (_) {
    return [];
  }
});

final servicesProvider = FutureProvider.family<List<ServiceModel>, String?>((ref, categoryId) async {
  try {
    return await ref.read(apiRepositoryProvider).getServices(categoryId: categoryId);
  } catch (_) {
    return [];
  }
});

/// Services from API filtered by search query [q]. Empty/null query returns all services.
final searchResultsProvider = FutureProvider.family<List<ServiceModel>, String?>((ref, q) async {
  try {
    final query = q?.trim();
    return await ref.read(apiRepositoryProvider).getServices(q: query?.isEmpty == true ? null : query);
  } catch (_) {
    return [];
  }
});

final bookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  try {
    return await ref.read(apiRepositoryProvider).getBookings();
  } catch (_) {
    return [];
  }
});

final threadsProvider = FutureProvider<List<MessageThreadModel>>((ref) async {
  try {
    return await ref.read(apiRepositoryProvider).getThreads();
  } catch (_) {
    return [];
  }
});

/// Provider-only: activation status (hasActiveService, isActive, etc.).
/// Only fetches when current user role is 'provider'.
final providerStatusProvider = FutureProvider<ProviderStatus?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (!(user?.isProvider ?? false)) return null;
  try {
    return await ref.read(apiRepositoryProvider).getProviderStatus();
  } catch (_) {
    return null;
  }
});

/// Provider-only: my services (draft + active).
final myServicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  try {
    return await ref.read(apiRepositoryProvider).getMyServices();
  } catch (_) {
    return [];
  }
});

/// Current logged-in user (name, email, role) from secure storage. Null if not logged in.
final currentUserProvider = FutureProvider<CurrentUser?>((ref) async {
  Future<CurrentUser?> readStoredUser() async {
    final name = await getUserName();
    final email = await getUserEmail();
    final role = await getUserRole();
    final isCustomer = await getUserIsCustomer();
    final isProvider = await getUserIsProvider();
    final isAdmin = await getUserIsAdmin();
    final adminRole = await getUserAdminRole();
    if ((name == null || name.isEmpty) && (email == null || email.isEmpty)) {
      return null;
    }
    return CurrentUser(
      name: name?.trim().isNotEmpty == true ? name! : 'User',
      email: email?.trim().isNotEmpty == true ? email! : '',
      role: role,
      isCustomer: isCustomer,
      isProvider: isProvider,
      isAdmin: isAdmin,
      adminRole: adminRole,
    );
  }

  final token = await getToken();
  if (token == null || token.isEmpty) {
    return readStoredUser();
  }

  try {
    final me = await ref.read(apiRepositoryProvider).getMe();
    return CurrentUser(
      name: me.user.fullName.trim().isNotEmpty ? me.user.fullName : 'User',
      email: me.user.email,
      role: me.user.role,
      isCustomer: me.user.isCustomer,
      isProvider: me.user.isProvider,
      isAdmin: me.user.isAdmin,
      adminRole: me.user.adminRole,
    );
  } catch (_) {
    return readStoredUser();
  }
});

class CurrentUser {
  const CurrentUser({
    required this.name,
    required this.email,
    this.role,
    this.isCustomer,
    this.isProvider,
    this.isAdmin,
    this.adminRole,
  });
  final String name;
  final String email;
  /// 'customer' | 'provider' | 'admin'
  final String? role;
  final bool? isCustomer;
  final bool? isProvider;
  final bool? isAdmin;
  final String? adminRole;

  bool get isProviderRole => isProvider ?? role == 'provider';
  bool get isAdminRole => isAdmin ?? role == 'admin';
  bool get isCustomerRole => isCustomer ?? (!isProviderRole && !isAdminRole);
}

/// Extended profile (Get Started) data from local storage.
final profileExtendedProvider = FutureProvider<ProfileExtended>((ref) async {
  final m = await getProfileExtendedMap();
  return ProfileExtended(
    decadeBorn: m['decadeBorn'] ?? '',
    whereAlwaysWanted: m['whereAlwaysWanted'] ?? '',
    phone: m['phone'] ?? '',
    address: m['address'] ?? '',
    bio: m['bio'] ?? '',
  );
});

class ProfileExtended {
  const ProfileExtended({
    required this.decadeBorn,
    required this.whereAlwaysWanted,
    required this.phone,
    required this.address,
    required this.bio,
  });
  final String decadeBorn;
  final String whereAlwaysWanted;
  final String phone;
  final String address;
  final String bio;

  bool get isComplete =>
      decadeBorn.isNotEmpty &&
      whereAlwaysWanted.isNotEmpty &&
      phone.trim().isNotEmpty &&
      address.trim().isNotEmpty;
}

/// Set of favorited service IDs (persisted locally).
final favoritesIdsProvider = FutureProvider<Set<String>>((ref) => getFavoriteServiceIds());

/// Name of the current favorite list, if set.
final favoriteListNameProvider = FutureProvider<String?>((ref) => getFavoriteListName());

/// Whether a service is in favorites.
final isFavoriteProvider = Provider.family<bool, String>((ref, serviceId) {
  final ids = ref.watch(favoritesIdsProvider).value;
  return ids?.contains(serviceId) ?? false;
});

/// Recently viewed service IDs (most recent first), from local storage.
final recentlyViewedIdsProvider = FutureProvider<List<String>>((ref) => getRecentlyViewedIds());

/// Recently viewed services (details from API), in order (most recent first).
final recentlyViewedServicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final ids = await ref.watch(recentlyViewedIdsProvider.future);
  if (ids.isEmpty) return [];
  final all = await ref.watch(servicesProvider(null).future);
  final byId = {for (var s in all) s.id: s};
  return ids.map((id) => byId[id]).whereType<ServiceModel>().toList();
});

/// Lightweight public host profile for a given provider id (used on service detail page).
final hostProfileProvider = FutureProvider.family<HostProfile?, String>((ref, providerId) async {
  try {
    return await ref.read(apiRepositoryProvider).getHostPublicProfile(providerId);
  } catch (_) {
    return null;
  }
});

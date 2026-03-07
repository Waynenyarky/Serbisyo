import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/auth_storage.dart';
import '../api/experience_mode_storage.dart';
import '../api/favorites_storage.dart';
import '../api/recent_searches_storage.dart';
import '../api/recently_viewed_storage.dart';
import '../api/profile_storage.dart';
import '../models/booking_model.dart';
import '../models/message_thread_model.dart';
import '../models/review_model.dart';
import '../models/service_category.dart';
import '../models/service_model.dart';
import '../repository/api_repository.dart';
import '../models/host_profile_model.dart';

final apiClientProvider = Provider<Dio>((ref) => createApiClient());

final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  return ApiRepository(ref.watch(apiClientProvider));
});

final serviceByIdProvider = FutureProvider.family<dynamic, String>((
  ref,
  id,
) async {
  final service = await ref.read(apiRepositoryProvider).getServiceById(id);
  if (service == null) return null;
  final enriched = await _applyReviewFallbackToServices(ref, [service]);
  return enriched.isEmpty ? service : enriched.first;
});

final bookingByIdProvider = FutureProvider.family<dynamic, String>((
  ref,
  id,
) async {
  final mode = ref.watch(appExperienceModeProvider);
  final asRole = mode == 'host' ? 'provider' : 'customer';
  return ref.read(apiRepositoryProvider).getBookingById(id, asRole: asRole);
});

final threadByIdProvider = FutureProvider.family<dynamic, String>((
  ref,
  id,
) async {
  return ref.read(apiRepositoryProvider).getThread(id);
});

final categoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  try {
    return await ref.read(apiRepositoryProvider).getCategories();
  } catch (_) {
    return [];
  }
});

final servicesProvider = FutureProvider.family<List<ServiceModel>, String?>((
  ref,
  categoryId,
) async {
  try {
    final services = await ref
        .read(apiRepositoryProvider)
        .getServices(categoryId: categoryId, sortBy: 'newest');
    return _applyReviewFallbackToServices(ref, services);
  } catch (_) {
    return [];
  }
});

/// Home spotlight for newly created active services.
final latestServicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  try {
    final allNewest = await ref
        .read(apiRepositoryProvider)
        .getServices(sortBy: 'newest', limit: 24);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todayOnly = allNewest.where((service) {
      final created = _serviceCreatedAt(service)?.toLocal();
      if (created == null) return false;
      return !created.isBefore(today) && created.isBefore(tomorrow);
    }).toList();

    final pick = todayOnly.length <= 8 ? todayOnly : todayOnly.sublist(0, 8);
    return _applyReviewFallbackToServices(ref, pick);
  } catch (_) {
    return [];
  }
});

DateTime? _serviceCreatedAt(ServiceModel service) {
  if (service.createdAt != null) return service.createdAt;
  return _createdAtFromMongoObjectId(service.id);
}

DateTime? _createdAtFromMongoObjectId(String id) {
  final normalized = id.trim();
  if (normalized.length < 8) return null;
  final hex = normalized.substring(0, 8);
  final seconds = int.tryParse(hex, radix: 16);
  if (seconds == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
}

/// Services from API filtered by search query [q]. Empty/null query returns all services.
final searchResultsProvider =
    FutureProvider.family<List<ServiceModel>, String?>((ref, q) async {
      try {
        final query = q?.trim();
        final services = await ref
            .read(apiRepositoryProvider)
            .getServices(q: query?.isEmpty == true ? null : query);
        return _applyReviewFallbackToServices(ref, services);
      } catch (_) {
        return [];
      }
    });

/// Combined search: query + category + sort. Used by SearchScreen.
class SearchFilter {
  const SearchFilter({
    this.query,
    this.categoryId,
    this.sortBy = 'rating',
    this.sortOrder = 'desc',
  });
  final String? query;
  final String? categoryId;
  final String sortBy;
  final String sortOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFilter &&
          query == other.query &&
          categoryId == other.categoryId &&
          sortBy == other.sortBy &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(query, categoryId, sortBy, sortOrder);
}

final searchServicesProvider =
    FutureProvider.family<List<ServiceModel>, SearchFilter>((
      ref,
      filter,
    ) async {
      try {
        final services = await ref
            .read(apiRepositoryProvider)
            .getServices(
              q: filter.query?.trim().isEmpty == true
                  ? null
                  : filter.query?.trim(),
              categoryId: filter.categoryId,
              sortBy: filter.sortBy,
              sortOrder: filter.sortOrder,
            );
        return _applyReviewFallbackToServices(ref, services);
      } catch (_) {
        return [];
      }
    });

final bookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  try {
    return await ref
        .read(apiRepositoryProvider)
        .getBookings(asRole: 'customer');
  } catch (_) {
    return [];
  }
});

final bookingsByStatusProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, status) async {
      try {
        final all = await ref
            .read(apiRepositoryProvider)
            .getBookings(asRole: 'provider');
        final target = _normalizeStatusKey(status);
        return all
            .where((booking) => _effectiveBookingStatus(booking) == target)
            .toList();
      } catch (_) {
        return [];
      }
    });

final providerPendingRequestsProvider = FutureProvider<List<BookingModel>>((
  ref,
) async {
  try {
    final all = await ref
        .read(apiRepositoryProvider)
        .getBookings(asRole: 'provider');
    return all.where((b) => _effectiveBookingStatus(b) == 'pending').toList();
  } catch (_) {
    return [];
  }
});

final providerUpcomingBookingsProvider = FutureProvider<List<BookingModel>>((
  ref,
) async {
  try {
    final all = await ref
        .read(apiRepositoryProvider)
        .getBookings(asRole: 'provider');
    return all.where((b) => _effectiveBookingStatus(b) == 'confirmed').toList();
  } catch (_) {
    return [];
  }
});

final providerCurrentStaysProvider = FutureProvider<List<BookingModel>>((
  ref,
) async {
  try {
    final all = await ref
        .read(apiRepositoryProvider)
        .getBookings(asRole: 'provider');
    return all.where((b) => _effectiveBookingStatus(b) == 'ongoing').toList();
  } catch (_) {
    return [];
  }
});

final providerCompletedBookingsProvider = FutureProvider<List<BookingModel>>((
  ref,
) async {
  try {
    final all = await ref
        .read(apiRepositoryProvider)
        .getBookings(asRole: 'provider');
    return all.where((b) => _effectiveBookingStatus(b) == 'completed').toList();
  } catch (_) {
    return [];
  }
});

final providerCancelledBookingsProvider = FutureProvider<List<BookingModel>>((
  ref,
) async {
  try {
    final all = await ref
        .read(apiRepositoryProvider)
        .getBookings(asRole: 'provider');
    return all.where((b) => _effectiveBookingStatus(b) == 'cancelled').toList();
  } catch (_) {
    return [];
  }
});

String _normalizeStatusKey(String raw) {
  final status = raw.trim().toLowerCase();
  if (status == 'past') return 'completed';
  return status;
}

String _effectiveBookingStatus(BookingModel booking) {
  final status = _normalizeStatusKey(booking.status);
  if (status == 'upcoming') {
    final hasHostResponse = booking.respondedAt != null;
    return hasHostResponse ? 'confirmed' : 'pending';
  }
  return status;
}

class MessageThreadsFilter {
  const MessageThreadsFilter({
    this.query,
    this.unreadOnly = false,
    this.type = 'all',
  });

  final String? query;
  final bool unreadOnly;

  /// all | direct | support | booking
  final String type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageThreadsFilter &&
          query == other.query &&
          unreadOnly == other.unreadOnly &&
          type == other.type;

  @override
  int get hashCode => Object.hash(query, unreadOnly, type);
}

final threadsProvider = FutureProvider<List<MessageThreadModel>>((ref) async {
  try {
    return await ref.read(apiRepositoryProvider).getThreads();
  } catch (_) {
    return [];
  }
});

final threadsFilteredProvider =
    FutureProvider.family<List<MessageThreadModel>, MessageThreadsFilter>((
      ref,
      filter,
    ) async {
      try {
        return await ref
            .read(apiRepositoryProvider)
            .getThreads(
              q: filter.query,
              unreadOnly: filter.unreadOnly,
              type: filter.type,
            );
      } catch (_) {
        return [];
      }
    });

/// Provider-only: activation status (hasActiveService, isActive, etc.).
/// Only fetches when current user role is 'provider'.
final providerStatusProvider = FutureProvider<ProviderStatus?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user?.role != 'provider') return null;
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
  final userId = await getUserId();
  final name = await getUserName();
  final email = await getUserEmail();
  final role = await getUserRole();
  if ((name == null || name.isEmpty) &&
      (email == null || email.isEmpty) &&
      (userId == null || userId.isEmpty)) {
    return null;
  }
  return CurrentUser(
    id: userId ?? '',
    name: name?.trim().isNotEmpty == true ? name! : 'User',
    email: email?.trim().isNotEmpty == true ? email! : '',
    role: role,
  );
});

/// Preferred mode for users that have host access.
/// Value: 'customer' | 'host' | null (not set).
final preferredExperienceModeProvider = FutureProvider<String?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  final userId = await getUserId();
  if (userId == null || userId.isEmpty) return null;
  return getExperienceMode(userId);
});

/// Effective app mode used by shell/profile UX.
/// Non-provider accounts are always forced to 'customer'.
final appExperienceModeProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return 'customer';
  if (!user.isProviderRole) return 'customer';

  final preferred =
      ref.watch(preferredExperienceModeProvider).valueOrNull ?? '';
  if (preferred == 'customer' || preferred == 'host') return preferred;

  // Provider defaults to host mode unless user explicitly switches.
  return 'host';
});

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.name,
    required this.email,
    this.role,
  });
  final String id;
  final String name;
  final String email;

  /// 'customer' | 'provider' | 'admin'
  final String? role;

  /// Whether the current user has a provider role.
  bool get isProviderRole => role == 'provider' || role == 'Provider';
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

/// Favorite services for the current user (backend source of truth, with optional local migration).
final favoriteServicesProvider = FutureProvider.autoDispose<List<ServiceModel>>((
  ref,
) async {
  final repo = ref.watch(apiRepositoryProvider);

  // One-time migration: if backend has no favorites yet but local storage does, push them.
  final hasMigrated = await hasMigratedFavoritesToBackend();
  if (!hasMigrated) {
    try {
      final remote = await repo.getFavoriteServices();
      if (remote.isEmpty) {
        final localIds = await getFavoriteServiceIds();
        if (localIds.isNotEmpty) {
          for (final id in localIds) {
            await repo.addFavoriteService(id);
          }
        }
      }
      await markFavoritesMigratedToBackend();
    } catch (_) {
      // If migration fails, we still fall back to backend favorites as-is.
    }
  }

  return repo.getFavoriteServices();
});

/// Set of favorited service IDs derived from backend favorites.
final favoritesIdsProvider = FutureProvider<Set<String>>((ref) async {
  final services = await ref.watch(favoriteServicesProvider.future);
  return services.map((s) => s.id).toSet();
});

/// Name of the current favorite list, if set (still stored locally).
final favoriteListNameProvider = FutureProvider<String?>(
  (ref) => getFavoriteListName(),
);

/// Whether a service is in favorites.
final isFavoriteProvider = Provider.family<bool, String>((ref, serviceId) {
  final ids = ref.watch(favoritesIdsProvider).value;
  return ids?.contains(serviceId) ?? false;
});

/// Recently viewed service IDs (most recent first), from local storage.
final recentlyViewedIdsProvider = FutureProvider<List<String>>(
  (ref) => getRecentlyViewedIds(),
);

/// Recently viewed services (details from API), in order (most recent first).
final recentlyViewedServicesProvider = FutureProvider<List<ServiceModel>>((
  ref,
) async {
  final ids = await ref.watch(recentlyViewedIdsProvider.future);
  if (ids.isEmpty) return [];
  final all = await ref.watch(servicesProvider(null).future);
  final byId = {for (var s in all) s.id: s};
  return ids.map((id) => byId[id]).whereType<ServiceModel>().toList();
});

/// Recent search queries (most recent first), from local storage.
final recentSearchesProvider = FutureProvider<List<String>>(
  (ref) => getRecentSearches(),
);

/// Lightweight public host profile for a given provider id (used on service detail page).
final hostProfileProvider = FutureProvider.family<HostProfile?, String>((
  ref,
  providerId,
) async {
  try {
    return await ref
        .read(apiRepositoryProvider)
        .getHostPublicProfile(providerId);
  } catch (_) {
    return null;
  }
});

final bookingReviewsProvider = FutureProvider.family<List<ReviewModel>, String>(
  (ref, bookingId) async {
    try {
      final mode = ref.read(appExperienceModeProvider);
      final asRole = mode == 'host' ? 'provider' : 'customer';
      return await ref
          .read(apiRepositoryProvider)
          .getReviews(bookingId: bookingId, asRole: asRole);
    } catch (_) {
      return [];
    }
  },
);

final serviceReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((
  ref,
  serviceId,
) async {
  try {
    final mode = ref.read(appExperienceModeProvider);
    final asRole = mode == 'host' ? 'provider' : 'customer';
    final reviews = await ref
        .read(apiRepositoryProvider)
        .getReviews(
          serviceId: serviceId,
          roleType: 'guest_to_host',
          asRole: asRole,
        );
    // Compatibility fallback: older backends may ignore serviceId/roleType filters.
    final sameService = reviews
        .where((review) => review.serviceId == serviceId)
        .toList();
    final customerToHost = sameService
        .where(
          (review) => review.roleType.trim().toLowerCase() == 'guest_to_host',
        )
        .toList();
    if (customerToHost.isNotEmpty) {
      return customerToHost;
    }
    // Last-resort fallback for legacy/misclassified role records.
    return sameService;
  } catch (_) {
    return [];
  }
});

Future<List<ServiceModel>> _applyReviewFallbackToServices(
  Ref ref,
  List<ServiceModel> services,
) async {
  if (services.isEmpty) return services;
  final ids = services.map((s) => s.id).toSet();
  if (ids.isEmpty) return services;

  try {
    final mode = ref.read(appExperienceModeProvider);
    final asRole = mode == 'host' ? 'provider' : 'customer';
    final reviews = await ref
        .read(apiRepositoryProvider)
        .getReviews(asRole: asRole);
    final byService = <String, List<ReviewModel>>{};
    for (final review in reviews) {
      final sid = review.serviceId;
      if (sid == null || sid.isEmpty || !ids.contains(sid)) continue;
      byService.putIfAbsent(sid, () => <ReviewModel>[]).add(review);
    }

    final relevant = <ReviewModel>[];
    byService.forEach((_, grouped) {
      final customerToHost = grouped
          .where(
            (review) => review.roleType.trim().toLowerCase() == 'guest_to_host',
          )
          .toList();
      if (customerToHost.isNotEmpty) {
        relevant.addAll(customerToHost);
      } else {
        // Last-resort fallback for legacy/misclassified role records.
        relevant.addAll(grouped);
      }
    });

    final sumByService = <String, double>{};
    final countByService = <String, int>{};
    for (final review in relevant) {
      final sid = review.serviceId!;
      sumByService[sid] = (sumByService[sid] ?? 0) + review.ratingOverall;
      countByService[sid] = (countByService[sid] ?? 0) + 1;
    }

    return services.map((service) {
      final count = countByService[service.id] ?? 0;
      if (count <= 0) return service;
      final sum = sumByService[service.id] ?? 0;
      final avg = sum / count;
      return _copyServiceWithRatings(service, avg, count);
    }).toList();
  } catch (_) {
    return services;
  }
}

ServiceModel _copyServiceWithRatings(
  ServiceModel source,
  double rating,
  int reviewCount,
) {
  return ServiceModel(
    id: source.id,
    title: source.title,
    categoryId: source.categoryId,
    imageUrl: source.imageUrl,
    rating: rating,
    reviewCount: reviewCount,
    pricePerHour: source.pricePerHour,
    providerName: source.providerName,
    description: source.description,
    providerId: source.providerId,
    status: source.status,
    offers: source.offers,
    locationDescription: source.locationDescription,
    availability: source.availability,
    thingsToKnow: source.thingsToKnow,
    createdAt: source.createdAt,
  );
}

// (favoriteServicesProvider is defined above with backend sync.)

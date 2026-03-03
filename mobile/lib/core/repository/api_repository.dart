import 'package:dio/dio.dart';

import '../api/auth_guard.dart';
import '../api/auth_storage.dart';
import '../models/booking_model.dart';
import '../models/message_thread_model.dart';
import '../models/service_category.dart';
import '../models/service_model.dart';
import '../models/host_profile_model.dart';

class ApiRepository {
  ApiRepository(this._dio);

  final Dio _dio;

  // —— Auth ——
  Future<AuthResponse> login(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _parseAuthResponse(res.data!);
  }

  Future<AuthResponse> register(String email, String password, String fullName, {String role = 'customer'}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'email': email, 'password': password, 'fullName': fullName, 'role': role},
    );
    return _parseAuthResponse(res.data!, fallbackRole: role);
  }

  Future<AuthResponse> loginWithGoogleIdToken(
    String idToken, {
    String role = 'customer',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/oauth/google/mobile',
      data: {'idToken': idToken, 'role': role},
    );
    return _parseAuthResponse(res.data!, fallbackRole: role);
  }

  Future<AuthResponse> getMe() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    return _parseAuthResponse(res.data!);
  }

  Future<void> logout() async {
    await clearAuth();
    AuthGuard.setAuthState(authenticated: false);
  }

  Future<AuthResponse> _parseAuthResponse(Map<String, dynamic> data, {String? fallbackRole}) async {
    final userMap = data['user'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final userId = (userMap['id'] ?? userMap['_id'] ?? '').toString();
    final email = (userMap['email'] ?? '').toString();
    final fullName = ((userMap['fullName'] ?? userMap['name']) ?? email).toString();
    final isCustomer = _asBool(userMap['is_customer']) ?? _asBool(userMap['isCustomer']) ?? true;
    final isProvider = _asBool(userMap['is_provider']) ?? _asBool(userMap['isProvider']) ?? false;
    final isAdmin = _asBool(userMap['is_admin']) ?? _asBool(userMap['isAdmin']) ?? false;
    final adminRole = (userMap['admin_role'] ?? userMap['adminRole'])?.toString();

    String? role = userMap['role']?.toString();
    role ??= fallbackRole;
    role ??= isAdmin ? 'admin' : (isProvider ? 'provider' : 'customer');

    final token = (data['token'] ?? '').toString();
    await saveAuth(
      token: token,
      userId: userId,
      email: email,
      fullName: fullName,
      role: role,
      isCustomer: isCustomer,
      isProvider: isProvider,
      isAdmin: isAdmin,
      adminRole: adminRole,
    );
    AuthGuard.setAuthState(
      authenticated: token.trim().isNotEmpty,
      provider: isProvider,
      admin: isAdmin,
    );

    return AuthResponse(
      token: token,
      user: AuthUser(
        id: userId,
        email: email,
        fullName: fullName,
        role: role,
        isCustomer: isCustomer,
        isProvider: isProvider,
        isAdmin: isAdmin,
        adminRole: adminRole,
      ),
    );
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return null;
  }

  // —— Categories ——
  Future<List<ServiceCategory>> getCategories() async {
    final res = await _dio.get<List<dynamic>>('/categories');
    final list = res.data ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return ServiceCategory(
        id: m['id'] as String,
        name: m['name'] as String,
        assetImagePath: m['assetImagePath'] as String? ?? 'assets/images/placeholders/placeholder.png',
      );
    }).toList();
  }

  // —— Services ——
  Future<List<ServiceModel>> getServices({
    String? categoryId,
    String? q,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = <String, dynamic>{};
    if (categoryId != null) query['categoryId'] = categoryId;
    if (q != null && q.isNotEmpty) query['q'] = q;
    if (page != null && page > 0) query['page'] = page;
    if (limit != null && limit > 0) query['limit'] = limit;
    if (sortBy != null && sortBy.isNotEmpty) query['sortBy'] = sortBy;
    if (sortOrder != null && sortOrder.isNotEmpty) query['sortOrder'] = sortOrder;
    final res = await _dio.get<List<dynamic>>('/services', queryParameters: query);
    final list = res.data ?? [];
    return list.map<ServiceModel>((e) => _serviceFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NearestProvidersResult> getNearestProviders({
    required double lat,
    required double lng,
    int radiusMeters = 10000,
    int limit = 10,
    String? categoryId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/providers/nearest',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radiusMeters': radiusMeters,
        'limit': limit,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      },
    );

    final d = res.data ?? const <String, dynamic>{};
    final matched = d['matched'] as bool? ?? false;
    final fallbackReason = d['fallbackReason']?.toString();
    final list = (d['candidates'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => NearestProviderCandidate.fromJson(e as Map<String, dynamic>))
        .toList();
    return NearestProvidersResult(
      matched: matched,
      fallbackReason: fallbackReason,
      candidates: list,
    );
  }

  Future<ServiceModel?> getServiceById(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/services/$id');
      return _serviceFromJson(res.data!);
    } catch (_) {
      return null;
    }
  }

  /// Provider-only: list my services (draft + active).
  Future<List<ServiceModel>> getMyServices() async {
    final res = await _dio.get<List<dynamic>>('/services/mine');
    final list = res.data ?? [];
    return list.map<ServiceModel>((e) => _serviceFromJson(e as Map<String, dynamic>)).toList();
  }

  /// Provider-only: create draft service.
  Future<ServiceModel> createService({
    required String title,
    required String categoryId,
    double pricePerHour = 0,
    String? description,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'categoryId': categoryId,
      'pricePerHour': pricePerHour,
    };
    if (description != null && description.isNotEmpty) data['description'] = description;
    if (imageUrl != null && imageUrl.isNotEmpty) data['imageUrl'] = imageUrl;
    final res = await _dio.post<Map<String, dynamic>>('/services', data: data);
    return _serviceFromJson(res.data!);
  }

  /// Provider-only: update service (only owner). Set status: 'active' to publish.
  Future<ServiceModel> updateService({
    required String id,
    String? title,
    String? categoryId,
    double? pricePerHour,
    String? description,
    String? imageUrl,
    String? status,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (categoryId != null) data['categoryId'] = categoryId;
    if (pricePerHour != null) data['pricePerHour'] = pricePerHour;
    if (description != null) data['description'] = description;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (status != null) data['status'] = status;
    final res = await _dio.patch<Map<String, dynamic>>('/services/$id', data: data);
    return _serviceFromJson(res.data!);
  }

  /// Provider-only: activation status.
  Future<ProviderStatus> getProviderStatus() async {
    final res = await _dio.get<Map<String, dynamic>>('/providers/me/status');
    final d = res.data!;
    return ProviderStatus(
      hasActiveService: d['hasActiveService'] as bool? ?? false,
      isVerified: d['isVerified'] as bool? ?? false,
      hasPayoutMethod: d['hasPayoutMethod'] as bool? ?? false,
      isActive: d['isActive'] as bool? ?? false,
    );
  }

  /// Public: lightweight host profile for service detail page.
  Future<HostProfile?> getHostPublicProfile(String providerId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/providers/$providerId/public');
      final m = res.data!;
      return HostProfile(
        id: m['id'] as String,
        fullName: m['fullName'] as String? ?? '',
        bio: m['bio'] as String? ?? '',
        serviceArea: m['serviceArea'] as String? ?? '',
        avatarUrl: m['avatarUrl'] as String?,
        isVerified: m['isVerified'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  static ServiceModel _serviceFromJson(Map<String, dynamic> m) {
    return ServiceModel(
      id: m['id'] as String,
      title: m['title'] as String,
      categoryId: m['categoryId']?.toString() ?? '',
      imageUrl: m['imageUrl'] as String?,
      rating: (m['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (m['reviewCount'] as num?)?.toInt() ?? 0,
      pricePerHour: (m['pricePerHour'] as num?)?.toDouble() ?? 0,
      providerName: m['providerName'] as String,
      description: m['description'] as String?,
      providerId: m['providerId']?.toString(),
      status: m['status'] as String?,
      offers: m['offers'] as String?,
      locationDescription: m['locationDescription'] as String?,
      availability: m['availability'] as String?,
      thingsToKnow: m['thingsToKnow'] as String?,
    );
  }

  // —— Bookings ——
  Future<List<BookingModel>> getBookings() async {
    final res = await _dio.get<List<dynamic>>('/bookings');
    final list = res.data ?? [];
    return list.map<BookingModel>((e) => _bookingFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingModel?> getBookingById(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/bookings/$id');
      return _bookingFromJson(res.data!);
    } catch (_) {
      return null;
    }
  }

  Future<BookingModel> createBooking({
    required String serviceId,
    required String serviceTitle,
    required String providerName,
    required String scheduledDate,
    required String scheduledTime,
    required String address,
    required double totalAmount,
    String? providerId,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'providerName': providerName,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'address': address,
      'totalAmount': totalAmount,
    };
    if (providerId != null && providerId.isNotEmpty) data['providerId'] = providerId;
    if (imageUrl != null && imageUrl.isNotEmpty) data['imageUrl'] = imageUrl;
    final res = await _dio.post<Map<String, dynamic>>('/bookings', data: data);
    return _bookingFromJson(res.data!);
  }

  static BookingModel _bookingFromJson(Map<String, dynamic> m) {
    return BookingModel(
      id: m['id'] as String,
      serviceId: m['serviceId']?.toString() ?? '',
      serviceTitle: m['serviceTitle'] as String,
      providerName: m['providerName'] as String,
      scheduledDate: m['scheduledDate'] as String,
      scheduledTime: m['scheduledTime'] as String,
      address: m['address'] as String,
      status: m['status'] as String,
      totalAmount: (m['totalAmount'] as num).toDouble(),
      imageUrl: m['imageUrl'] as String?,
    );
  }

  // —— Messages ——
  Future<List<MessageThreadModel>> getThreads() async {
    final res = await _dio.get<List<dynamic>>('/messages/threads');
    final list = res.data ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return MessageThreadModel(
        id: m['id'] as String,
        providerName: m['providerName'] as String,
        serviceTitle: m['serviceTitle'] as String,
        lastMessage: m['lastMessage'] as String? ?? '',
        lastMessageAt: m['lastMessageAt'] as String? ?? '',
        unreadCount: (m['unreadCount'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<MessageThreadWithMessages?> getThread(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/messages/threads/$id');
      final d = res.data!;
      final messages = (d['messages'] as List<dynamic>?)?.map((e) {
        final m = e as Map<String, dynamic>;
        return ThreadMessage(
          id: m['id'] as String? ?? '',
          text: m['text'] as String,
          isMe: m['isMe'] as bool? ?? false,
          time: m['time'] as String? ?? '',
        );
      }).toList() ?? [];
      return MessageThreadWithMessages(
        id: d['id'] as String,
        providerName: d['providerName'] as String,
        serviceTitle: d['serviceTitle'] as String,
        messages: messages,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ThreadMessage?> sendMessage(String threadId, String text) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/messages/threads/$threadId/messages',
      data: {'text': text},
    );
    final d = res.data!;
    return ThreadMessage(
      id: d['id'] as String? ?? '',
      text: d['text'] as String,
      isMe: d['isMe'] as bool? ?? true,
      time: d['time'] as String? ?? '',
    );
  }

  /// Create or reuse a direct message thread for a given service and provider.
  Future<MessageThreadWithMessages?> createDirectThread({
    required String serviceId,
    required String providerId,
    required String serviceTitle,
    required String providerName,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/messages/threads/direct',
      data: {
        'serviceId': serviceId,
        'providerId': providerId,
      },
    );
    final d = res.data!;
    final messages = (d['messages'] as List<dynamic>?)?.map((e) {
          final m = e as Map<String, dynamic>;
          return ThreadMessage(
            id: m['id'] as String? ?? '',
            text: m['text'] as String,
            isMe: m['isMe'] as bool? ?? false,
            time: m['time'] as String? ?? '',
          );
        }).toList() ??
        [];
    return MessageThreadWithMessages(
      id: d['id'] as String,
      providerName: d['providerName'] as String? ?? providerName,
      serviceTitle: d['serviceTitle'] as String? ?? serviceTitle,
      messages: messages,
    );
  }
}

class AuthResponse {
  AuthResponse({required this.token, required this.user});
  final String token;
  final AuthUser user;
}

class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.role,
    this.isCustomer = true,
    this.isProvider = false,
    this.isAdmin = false,
    this.adminRole,
  });
  final String id;
  final String email;
  final String fullName;
  /// 'customer' | 'provider' | 'admin'
  final String? role;
  final bool isCustomer;
  final bool isProvider;
  final bool isAdmin;
  final String? adminRole;
}

class ProviderStatus {
  ProviderStatus({
    required this.hasActiveService,
    required this.isVerified,
    required this.hasPayoutMethod,
    required this.isActive,
  });
  final bool hasActiveService;
  final bool isVerified;
  final bool hasPayoutMethod;
  final bool isActive;
}

class NearestProvidersResult {
  NearestProvidersResult({
    required this.matched,
    required this.candidates,
    this.fallbackReason,
  });

  final bool matched;
  final String? fallbackReason;
  final List<NearestProviderCandidate> candidates;
}

class NearestProviderCandidate {
  NearestProviderCandidate({
    required this.id,
    required this.fullName,
    required this.distanceMeters,
    required this.services,
    this.ratings = 0,
    this.serviceArea,
    this.isVerified = false,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final num ratings;
  final int distanceMeters;
  final String? serviceArea;
  final bool isVerified;
  final String? avatarUrl;
  final List<NearestProviderService> services;

  factory NearestProviderCandidate.fromJson(Map<String, dynamic> m) {
    final services = (m['services'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => NearestProviderService.fromJson(e as Map<String, dynamic>))
        .toList();
    return NearestProviderCandidate(
      id: (m['id'] ?? '').toString(),
      fullName: (m['fullName'] ?? '').toString(),
      ratings: (m['ratings'] as num?) ?? 0,
      distanceMeters: ((m['distanceMeters'] as num?) ?? 0).round(),
      serviceArea: m['serviceArea']?.toString(),
      isVerified: m['isVerified'] as bool? ?? false,
      avatarUrl: m['avatarUrl']?.toString(),
      services: services,
    );
  }
}

class NearestProviderService {
  NearestProviderService({
    required this.id,
    required this.title,
    this.categoryId,
    this.rating = 0,
    this.pricePerHour = 0,
  });

  final String id;
  final String title;
  final String? categoryId;
  final num rating;
  final num pricePerHour;

  factory NearestProviderService.fromJson(Map<String, dynamic> m) {
    return NearestProviderService(
      id: (m['id'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      categoryId: m['categoryId']?.toString(),
      rating: (m['rating'] as num?) ?? 0,
      pricePerHour: (m['pricePerHour'] as num?) ?? 0,
    );
  }
}

class MessageThreadWithMessages {
  MessageThreadWithMessages({
    required this.id,
    required this.providerName,
    required this.serviceTitle,
    required this.messages,
  });
  final String id;
  final String providerName;
  final String serviceTitle;
  final List<ThreadMessage> messages;
}

class ThreadMessage {
  ThreadMessage({required this.id, required this.text, required this.isMe, required this.time});
  final String id;
  final String text;
  final bool isMe;
  final String time;
}

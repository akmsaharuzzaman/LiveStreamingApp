import 'package:equatable/equatable.dart';

/// Agency status check response
class AgencyStatusResponse extends Equatable {
  final bool success;
  final AgencyStatusResult result;

  const AgencyStatusResponse({required this.success, required this.result});

  factory AgencyStatusResponse.fromJson(Map<String, dynamic> json) {
    return AgencyStatusResponse(
      success: json['success'] ?? false,
      result: AgencyStatusResult.fromJson(json['result'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'result': result.toJson()};
  }

  @override
  List<Object?> get props => [success, result];
}

class AgencyStatusResult extends Equatable {
  final String status; // member, list, pending, congrats
  final AgencyDetails? agencyDetails;

  const AgencyStatusResult({required this.status, this.agencyDetails});

  factory AgencyStatusResult.fromJson(Map<String, dynamic> json) {
    return AgencyStatusResult(
      status: json['status'] ?? '',
      agencyDetails: json['agencyDetails'] != null
          ? AgencyDetails.fromJson(json['agencyDetails'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'agencyDetails': agencyDetails?.toJson()};
  }

  @override
  List<Object?> get props => [status, agencyDetails];
}

class AgencyDetails extends Equatable {
  final String name;
  final int hostCount;

  const AgencyDetails({required this.name, required this.hostCount});

  factory AgencyDetails.fromJson(Map<String, dynamic> json) {
    return AgencyDetails(
      name: json['name'] ?? '',
      hostCount: json['hostCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'hostCount': hostCount};
  }

  @override
  List<Object?> get props => [name, hostCount];
}

/// Agency list response
class AgencyListResponse extends Equatable {
  final bool success;
  final String message;
  final AgencyListResult result;

  const AgencyListResponse({
    required this.success,
    required this.message,
    required this.result,
  });

  factory AgencyListResponse.fromJson(Map<String, dynamic> json) {
    return AgencyListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      result: AgencyListResult.fromJson(json['result'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'result': result.toJson()};
  }

  @override
  List<Object?> get props => [success, message, result];
}

class AgencyListResult extends Equatable {
  final List<Agency> data;
  final Pagination pagination;

  const AgencyListResult({required this.data, required this.pagination});

  factory AgencyListResult.fromJson(Map<String, dynamic> json) {
    return AgencyListResult(
      data:
          (json['data'] as List?)
              ?.map((item) => Agency.fromJson(item))
              .toList() ??
          [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((agency) => agency.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  @override
  List<Object?> get props => [data, pagination];
}

class Agency extends Equatable {
  final ActivityZone activityZone;
  final String id;
  final String name;
  final String userId;
  final String password;
  final int coins;
  final String designation;
  final int diamonds;
  final String parentCreator;
  final List<String> userPermissions;
  final String userRole;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  const Agency({
    required this.activityZone,
    required this.id,
    required this.name,
    required this.userId,
    required this.password,
    required this.coins,
    required this.designation,
    required this.diamonds,
    required this.parentCreator,
    required this.userPermissions,
    required this.userRole,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      activityZone: ActivityZone.fromJson(json['activityZone'] ?? {}),
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      userId: json['userId'] ?? '',
      password: json['password'] ?? '',
      coins: json['coins'] ?? 0,
      designation: json['designation'] ?? '',
      diamonds: json['diamonds'] ?? 0,
      parentCreator: json['parentCreator'] ?? '',
      userPermissions:
          (json['userPermissions'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      userRole: json['userRole'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      version: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activityZone': activityZone.toJson(),
      '_id': id,
      'name': name,
      'userId': userId,
      'password': password,
      'coins': coins,
      'designation': designation,
      'diamonds': diamonds,
      'parentCreator': parentCreator,
      'userPermissions': userPermissions,
      'userRole': userRole,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': version,
    };
  }

  @override
  List<Object?> get props => [
    activityZone,
    id,
    name,
    userId,
    password,
    coins,
    designation,
    diamonds,
    parentCreator,
    userPermissions,
    userRole,
    createdAt,
    updatedAt,
    version,
  ];
}

class ActivityZone extends Equatable {
  final String zone;

  const ActivityZone({required this.zone});

  factory ActivityZone.fromJson(Map<String, dynamic> json) {
    return ActivityZone(zone: json['zone'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'zone': zone};
  }

  @override
  List<Object?> get props => [zone];
}

class Pagination extends Equatable {
  final int total;
  final int limit;
  final int page;
  final int totalPage;

  const Pagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 0,
      page: json['page'] ?? 0,
      totalPage: json['totalPage'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'limit': limit,
      'page': page,
      'totalPage': totalPage,
    };
  }

  @override
  List<Object?> get props => [total, limit, page, totalPage];
}

/// Agency join request payload
class AgencyJoinRequest extends Equatable {
  final String agencyId;

  const AgencyJoinRequest({required this.agencyId});

  factory AgencyJoinRequest.fromJson(Map<String, dynamic> json) {
    return AgencyJoinRequest(agencyId: json['agencyId'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'agencyId': agencyId};
  }

  @override
  List<Object?> get props => [agencyId];
}

/// Generic API response
class SimpleApiResponse extends Equatable {
  final bool success;
  final String? message;

  const SimpleApiResponse({required this.success, this.message});

  factory SimpleApiResponse.fromJson(Map<String, dynamic> json) {
    return SimpleApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message};
  }

  @override
  List<Object?> get props => [success, message];
}

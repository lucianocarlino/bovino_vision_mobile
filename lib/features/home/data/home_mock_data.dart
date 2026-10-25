/// Modelos y datos de estado para el panel principal de BovinoVision (Offline-First)
class UserModel {
  final String name;
  final String initials;
  final bool isOnline;

  const UserModel({
    required this.name,
    required this.initials,
    required this.isOnline,
  });

  UserModel copyWith({
    String? name,
    String? initials,
    bool? isOnline,
  }) {
    return UserModel(
      name: name ?? this.name,
      initials: initials ?? this.initials,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String? ?? 'Francisco López',
      initials: json['initials'] as String? ?? 'FL',
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }
}

class SyncStatusModel {
  final bool isSynced;
  final String title;
  final String message;
  final int pendingCount;
  final bool isSyncing;

  const SyncStatusModel({
    required this.isSynced,
    required this.title,
    required this.message,
    this.pendingCount = 0,
    this.isSyncing = false,
  });

  SyncStatusModel copyWith({
    bool? isSynced,
    String? title,
    String? message,
    int? pendingCount,
    bool? isSyncing,
  }) {
    return SyncStatusModel(
      isSynced: isSynced ?? this.isSynced,
      title: title ?? this.title,
      message: message ?? this.message,
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  factory SyncStatusModel.fromJson(Map<String, dynamic> json) {
    return SyncStatusModel(
      isSynced: json['isSynced'] as bool? ?? true,
      title: json['title'] as String? ?? 'Sincronización completa',
      message: json['message'] as String? ?? 'Los datos del rodeo están actualizados.',
      pendingCount: json['pendingCount'] as int? ?? 0,
      isSyncing: json['isSyncing'] as bool? ?? false,
    );
  }
}

class MetricsModel {
  final int totalRodeo;
  final int activeLotes;
  final int capturesToday;

  const MetricsModel({
    required this.totalRodeo,
    required this.activeLotes,
    required this.capturesToday,
  });

  MetricsModel copyWith({
    int? totalRodeo,
    int? activeLotes,
    int? capturesToday,
  }) {
    return MetricsModel(
      totalRodeo: totalRodeo ?? this.totalRodeo,
      activeLotes: activeLotes ?? this.activeLotes,
      capturesToday: capturesToday ?? this.capturesToday,
    );
  }

  factory MetricsModel.fromJson(Map<String, dynamic> json) {
    return MetricsModel(
      totalRodeo: json['totalRodeo'] as int? ?? 1248,
      activeLotes: json['activeLotes'] as int? ?? 6,
      capturesToday: json['capturesToday'] as int? ?? 42,
    );
  }
}

class RecentSessionModel {
  final String id;
  final String location;
  final int animalsProcessed;
  final String timestamp;
  final bool isPending;
  final String? date;
  final String? time;

  const RecentSessionModel({
    required this.id,
    this.location = '',
    required this.animalsProcessed,
    required this.timestamp,
    this.isPending = false,
    this.date,
    this.time,
  });

  /// Retorna el día de la sesión (ej. 'Hoy', 'Ayer' o '25/10')
  String get displayDay {
    if (date != null && date!.isNotEmpty) return date!;
    if (timestamp.toLowerCase().contains('ayer')) return 'Ayer';
    if (timestamp.toLowerCase().contains('hoy')) return 'Hoy';
    if (timestamp.contains(':')) return 'Hoy';
    return timestamp.isNotEmpty ? timestamp : 'Hoy';
  }

  /// Retorna la hora de la sesión (ej. '08:45', '16:20')
  String get displayTime {
    if (time != null && time!.isNotEmpty) return time!;
    if (timestamp.contains(':')) {
      final parts = timestamp.split(' ');
      return parts.firstWhere((p) => p.contains(':'), orElse: () => timestamp);
    }
    return '14:30';
  }

  RecentSessionModel copyWith({
    String? id,
    String? location,
    int? animalsProcessed,
    String? timestamp,
    bool? isPending,
    String? date,
    String? time,
  }) {
    return RecentSessionModel(
      id: id ?? this.id,
      location: location ?? this.location,
      animalsProcessed: animalsProcessed ?? this.animalsProcessed,
      timestamp: timestamp ?? this.timestamp,
      isPending: isPending ?? this.isPending,
      date: date ?? this.date,
      time: time ?? this.time,
    );
  }

  factory RecentSessionModel.fromJson(Map<String, dynamic> json) {
    return RecentSessionModel(
      id: json['id'] as String? ?? '',
      location: json['location'] as String? ?? '',
      animalsProcessed: json['animalsProcessed'] as int? ?? 0,
      timestamp: json['timestamp'] as String? ?? '',
      isPending: json['isPending'] as bool? ?? false,
      date: json['date'] as String?,
      time: json['time'] as String?,
    );
  }
}

class HomeDashboardData {
  final UserModel user;
  final SyncStatusModel syncStatus;
  final MetricsModel metrics;
  final List<RecentSessionModel> recentSessions;

  const HomeDashboardData({
    required this.user,
    required this.syncStatus,
    required this.metrics,
    required this.recentSessions,
  });

  HomeDashboardData copyWith({
    UserModel? user,
    SyncStatusModel? syncStatus,
    MetricsModel? metrics,
    List<RecentSessionModel>? recentSessions,
  }) {
    return HomeDashboardData(
      user: user ?? this.user,
      syncStatus: syncStatus ?? this.syncStatus,
      metrics: metrics ?? this.metrics,
      recentSessions: recentSessions ?? this.recentSessions,
    );
  }

  factory HomeDashboardData.fromJson(Map<String, dynamic> json) {
    return HomeDashboardData(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      syncStatus: SyncStatusModel.fromJson(json['syncStatus'] as Map<String, dynamic>),
      metrics: MetricsModel.fromJson(json['metrics'] as Map<String, dynamic>),
      recentSessions: (json['recentSessions'] as List<dynamic>?)
              ?.map((item) => RecentSessionModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Mock estático con día, hora y cantidad de animales (sin nombre de sesión)
  static const Map<String, dynamic> rawJson = {
    "user": {
      "name": "Francisco López",
      "initials": "FL",
      "isOnline": true
    },
    "syncStatus": {
      "isSynced": true,
      "title": "Sincronización completa",
      "message": "Los datos del rodeo están actualizados."
    },
    "metrics": {
      "totalRodeo": 1248,
      "activeLotes": 6,
      "capturesToday": 42
    },
    "recentSessions": [
      {
        "id": "s1",
        "location": "",
        "animalsProcessed": 12,
        "timestamp": "08:45",
        "date": "Hoy",
        "time": "08:45"
      },
      {
        "id": "s2",
        "location": "",
        "animalsProcessed": 30,
        "timestamp": "Ayer",
        "date": "Ayer",
        "time": "16:20"
      }
    ]
  };

  static HomeDashboardData get staticMock => HomeDashboardData.fromJson(rawJson);
}

class Profile {
  final String id;
  final String fullName;
  final String role;
  final String? posyanduId;
  final String? phoneNumber;
  final String? avatarUrl;
  final bool isActive;
  final String? posyanduName;
  final String? villageName;
  final String? email;
  final DateTime? createdAt;

  Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.posyanduId,
    this.phoneNumber,
    this.avatarUrl,
    this.isActive = true,
    this.posyanduName,
    this.villageName,
    this.email,
    this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map, {String? email}) {
    String? pName;
    String? vName;

    if (map['posyandus'] != null && map['posyandus'] is Map) {
      pName = map['posyandus']['name']?.toString();
      if (map['posyandus']['rws'] != null && map['posyandus']['rws'] is Map) {
        if (map['posyandus']['rws']['villages'] != null &&
            map['posyandus']['rws']['villages'] is Map) {
          vName = map['posyandus']['rws']['villages']['name']?.toString();
        }
      }
    }

    return Profile(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? 'Pengguna',
      role: map['role']?.toString() ?? 'kader',
      posyanduId: map['posyandu_id']?.toString(),
      phoneNumber: map['phone_number']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      isActive: map['is_active'] != null ? map['is_active'] == true : true,
      posyanduName: pName,
      villageName: vName,
      email: email ?? map['email']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())?.toLocal()
          : null,
    );
  }

  Profile copyWith({
    String? fullName,
    String? role,
    String? posyanduId,
    String? phoneNumber,
    String? avatarUrl,
    bool? isActive,
    String? posyanduName,
    String? villageName,
    String? email,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      posyanduId: posyanduId ?? this.posyanduId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      posyanduName: posyanduName ?? this.posyanduName,
      villageName: villageName ?? this.villageName,
      email: email ?? this.email,
      createdAt: createdAt,
    );
  }
}

class Village {
  final String id;
  final String name;

  Village({required this.id, required this.name});

  factory Village.fromMap(Map<String, dynamic> map) {
    return Village(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
    );
  }
}

class RW {
  final String id;
  final String villageId;
  final String rwNumber;

  RW({required this.id, required this.villageId, required this.rwNumber});

  factory RW.fromMap(Map<String, dynamic> map) {
    return RW(
      id: map['id']?.toString() ?? '',
      villageId: map['village_id']?.toString() ?? '',
      rwNumber: map['rw_number']?.toString() ?? '',
    );
  }
}

class Posyandu {
  final String id;
  final String rwId;
  final String name;
  final String? tahunPendirian;
  final String? alamat;
  final String? namaKetua;
  final String? nomorHp;
  final double? latitude;
  final double? longitude;

  Posyandu({
    required this.id,
    required this.rwId,
    required this.name,
    this.tahunPendirian,
    this.alamat,
    this.namaKetua,
    this.nomorHp,
    this.latitude,
    this.longitude,
  });

  factory Posyandu.fromMap(Map<String, dynamic> map) {
    return Posyandu(
      id: map['id']?.toString() ?? '',
      rwId: map['rw_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      tahunPendirian: map['tahun_pendirian']?.toString(),
      alamat: map['alamat']?.toString(),
      namaKetua: map['nama_ketua']?.toString(),
      nomorHp: map['nomor_hp']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class Report {
  final String id;
  final String kaderId;
  final String posyanduId;
  final DateTime reportDate;
  final DateTime createdAt;
  final int housesInspected;
  final int housesPositive;
  final String? notes;
  final String status;
  final List<String> breedingPlaceIds;
  final String? villageName;
  final String? posyanduName;
  final String? latestIntervention;
  final bool hasInterventionHistory;

  Report({
    required this.id,
    required this.kaderId,
    required this.posyanduId,
    required this.reportDate,
    required this.createdAt,
    required this.housesInspected,
    required this.housesPositive,
    this.notes,
    required this.status,
    this.breedingPlaceIds = const [],
    this.villageName,
    this.posyanduName,
    this.latestIntervention,
    this.hasInterventionHistory = false,
  });

  factory Report.fromMap(Map<String, dynamic> map, {List<String>? breedingPlaceIds}) {
    // Extract names from joined data if available
    String? vName;
    String? pName;
    
    if (map['posyandus'] != null && map['posyandus'] is Map) {
      pName = map['posyandus']['name']?.toString();
      if (map['posyandus']['rws'] != null && map['posyandus']['rws'] is Map) {
        if (map['posyandus']['rws']['villages'] != null && map['posyandus']['rws']['villages'] is Map) {
          vName = map['posyandus']['rws']['villages']['name']?.toString();
        }
      }
    }

    return Report(
      id: map['id']?.toString() ?? '',
      kaderId: map['kader_id']?.toString() ?? '',
      posyanduId: map['posyandu_id']?.toString() ?? '',
      reportDate: map['report_date'] != null ? DateTime.tryParse(map['report_date'].toString()) ?? DateTime.now() : DateTime.now(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now() : DateTime.now(),
      housesInspected: (map['houses_inspected'] as num?)?.toInt() ?? 0,
      housesPositive: (map['houses_positive'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString(),
      status: map['status']?.toString() ?? 'submitted',
      breedingPlaceIds: breedingPlaceIds ?? [],
      villageName: vName,
      posyanduName: pName,
      latestIntervention: null,
      hasInterventionHistory: false,
    );
  }
}

class BroadcastAnnouncement {
  final String id;
  final String title;
  final String content;
  final String urgency; // 'biasa', 'penting', 'darurat'
  final String? targetVillageId;
  final String? targetVillageName;
  final String? createdBy;
  final String authorName;
  final bool isActive;
  final DateTime createdAt;

  BroadcastAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    this.urgency = 'penting',
    this.targetVillageId,
    this.targetVillageName,
    this.createdBy,
    this.authorName = 'Superadmin Dinkes',
    this.isActive = true,
    required this.createdAt,
  });

  factory BroadcastAnnouncement.fromMap(Map<String, dynamic> map) {
    return BroadcastAnnouncement(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      urgency: map['urgency']?.toString() ?? 'penting',
      targetVillageId: map['target_village_id']?.toString(),
      targetVillageName: map['target_village_name']?.toString(),
      createdBy: map['created_by']?.toString(),
      authorName: map['author_name']?.toString() ?? 'Superadmin Dinkes',
      isActive: map['is_active'] != null ? map['is_active'] == true : true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'urgency': urgency,
      'target_village_id': targetVillageId,
      'target_village_name': targetVillageName,
      'created_by': createdBy,
      'author_name': authorName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AuditLogEntry {
  final String id;
  final String? userId;
  final String userName;
  final String userRole;
  final String actionType; // 'verifikasi_laporan', 'intervensi', 'kelola_wilayah', 'kelola_pengguna', 'broadcast_instruksi', 'ekspor_data'
  final String description;
  final String? targetId;
  final DateTime createdAt;

  AuditLogEntry({
    required this.id,
    this.userId,
    required this.userName,
    required this.userRole,
    required this.actionType,
    required this.description,
    this.targetId,
    required this.createdAt,
  });

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      userName: map['user_name']?.toString() ?? 'Sistem',
      userRole: map['user_role']?.toString() ?? 'admin',
      actionType: map['action_type']?.toString() ?? 'kelola_wilayah',
      description: map['description']?.toString() ?? '',
      targetId: map['target_id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'action_type': actionType,
      'description': description,
      'target_id': targetId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}


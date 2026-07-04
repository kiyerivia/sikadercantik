class Profile {
  final String id;
  final String fullName;
  final String role;
  final String? posyanduId;
  final String? phoneNumber;
  final String? avatarUrl;

  Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.posyanduId,
    this.phoneNumber,
    this.avatarUrl,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? 'Pengguna',
      role: map['role']?.toString() ?? 'kader',
      posyanduId: map['posyandu_id']?.toString(),
      phoneNumber: map['phone_number']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
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

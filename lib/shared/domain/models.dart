class Profile {
  final String id;
  final String fullName;
  final String role;
  final String? posyanduId;
  final String? phoneNumber;

  Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.posyanduId,
    this.phoneNumber,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      role: map['role'] as String,
      posyanduId: map['posyandu_id'] as String?,
      phoneNumber: map['phone_number'] as String?,
    );
  }
}

class Village {
  final String id;
  final String name;

  Village({required this.id, required this.name});

  factory Village.fromMap(Map<String, dynamic> map) {
    return Village(
      id: map['id'] as String,
      name: map['name'] as String,
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
      id: map['id'] as String,
      villageId: map['village_id'] as String,
      rwNumber: map['rw_number'] as String,
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
      id: map['id'] as String,
      rwId: map['rw_id'] as String,
      name: map['name'] as String,
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
  final int housesInspected;
  final int housesPositive;
  final String? notes;
  final String status;
  final List<String> breedingPlaceIds;
  final String? villageName;
  final String? posyanduName;
  final String? latestIntervention;

  Report({
    required this.id,
    required this.kaderId,
    required this.posyanduId,
    required this.reportDate,
    required this.housesInspected,
    required this.housesPositive,
    this.notes,
    required this.status,
    this.breedingPlaceIds = const [],
    this.villageName,
    this.posyanduName,
    this.latestIntervention,
  });

  factory Report.fromMap(Map<String, dynamic> map, {List<String>? breedingPlaceIds}) {
    // Extract names from joined data if available
    String? vName;
    String? pName;
    
    if (map['posyandus'] != null) {
      pName = map['posyandus']['name'] as String?;
      if (map['posyandus']['rws'] != null && map['posyandus']['rws']['villages'] != null) {
        vName = map['posyandus']['rws']['villages']['name'] as String?;
      }
    }

    return Report(
      id: map['id'] as String,
      kaderId: map['kader_id'] as String,
      posyanduId: map['posyandu_id'] as String,
      reportDate: DateTime.parse(map['report_date'] as String),
      housesInspected: map['houses_inspected'] as int,
      housesPositive: map['houses_positive'] as int,
      notes: map['notes'] as String?,
      status: map['status'] as String,
      breedingPlaceIds: breedingPlaceIds ?? [],
      villageName: vName,
      posyanduName: pName,
      latestIntervention: (map['interventions'] != null && (map['interventions'] as List).isNotEmpty)
          ? (map['interventions'] as List).last['description'] as String?
          : null,
    );
  }
}

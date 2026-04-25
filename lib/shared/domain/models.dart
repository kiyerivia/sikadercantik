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

  Posyandu({required this.id, required this.rwId, required this.name});

  factory Posyandu.fromMap(Map<String, dynamic> map) {
    return Posyandu(
      id: map['id'] as String,
      rwId: map['rw_id'] as String,
      name: map['name'] as String,
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
  });

  factory Report.fromMap(Map<String, dynamic> map, {List<String>? breedingPlaceIds}) {
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
    );
  }
}

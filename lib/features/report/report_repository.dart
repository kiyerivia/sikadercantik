import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/domain/models.dart';

class ReportRepository {
  final SupabaseClient _client;

  ReportRepository(this._client);

  Future<void> submitReport({
    required String posyanduId,
    required int housesInspected,
    required int housesPositive,
    required List<String> breedingPlaceIds,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Insert Report
    final reportResponse = await _client.from('reports').insert({
      'kader_id': userId,
      'posyandu_id': posyanduId,
      'houses_inspected': housesInspected,
      'houses_positive': housesPositive,
      'notes': notes,
      'status': 'submitted',
    }).select().single();

    final reportId = reportResponse['id'] as String;

    // 2. Insert Junction records for breeding places
    if (breedingPlaceIds.isNotEmpty) {
      final junctionData = breedingPlaceIds.map((id) => {
        'report_id': reportId,
        'breeding_place_id': id,
      }).toList();
      
      await _client.from('report_breeding_places').insert(junctionData);
    }
  }

  Future<List<Report>> getMyReports() async {
    final userId = _client.auth.currentUser?.id;
    if (_client.auth.currentSession?.user == null) {
      return [];
    }

    final response = await _client
        .from('reports')
        .select('*, posyandus(name, rws(villages(name))), report_breeding_places(breeding_place_id)')
        .eq('kader_id', userId!)
        .order('report_date', ascending: false);

    return (response as List).map((data) {
      final breedingPlaces = (data['report_breeding_places'] as List)
          .map((bp) => bp['breeding_place_id'] as String)
          .toList();
      return Report.fromMap(data, breedingPlaceIds: breedingPlaces);
    }).toList();
  }

  Future<List<Report>> getAllReports() async {
    final response = await _client
        .from('reports')
        .select('*, profiles(full_name), report_breeding_places(breeding_place_id)')
        .order('created_at', ascending: false);

    return (response as List).map((data) {
      final breedingPlaces = (data['report_breeding_places'] as List)
          .map((bp) => bp['breeding_place_id'] as String)
          .toList();
      // We'll store the profile name in a temporary way or handle it in UI
      return Report.fromMap(data, breedingPlaceIds: breedingPlaces);
    }).toList();
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await _client
        .from('reports')
        .update({'status': status})
        .eq('id', reportId);
  }

  Future<void> addIntervention({
    required String reportId,
    required String type,
    required String description,
  }) async {
    final adminId = _client.auth.currentUser?.id;
    if (adminId == null) throw Exception('Admin not authenticated');

    await _client.from('interventions').insert({
      'report_id': reportId,
      'type': type,
      'description': description,
      'admin_id': adminId,
    });

    await updateReportStatus(reportId, 'need_intervention');
  }

  Future<void> updateReport({
    required String reportId,
    required int housesInspected,
    required int housesPositive,
    required List<String> breedingPlaceIds,
    String? notes,
  }) async {
    // 1. Update Report
    await _client.from('reports').update({
      'houses_inspected': housesInspected,
      'houses_positive': housesPositive,
      'notes': notes,
    }).eq('id', reportId);

    // 2. Refresh breeding places
    await _client.from('report_breeding_places').delete().eq('report_id', reportId);
    if (breedingPlaceIds.isNotEmpty) {
      final junctionData = breedingPlaceIds.map((id) => {
        'report_id': reportId,
        'breeding_place_id': id,
      }).toList();
      await _client.from('report_breeding_places').insert(junctionData);
    }
  }

  Future<void> deleteReport(String reportId) async {
    // 1. Delete junctions
    await _client.from('report_breeding_places').delete().eq('report_id', reportId);
    
    // 2. Delete report
    await _client.from('reports').delete().eq('id', reportId);
  }
}

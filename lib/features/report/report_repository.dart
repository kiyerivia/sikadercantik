import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/domain/models.dart';

class ReportRepository {
  final SupabaseClient _client;

  ReportRepository(this._client);

  Future<void> _ensureProfileExists(String userId, {String? posyanduId}) async {
    try {
      final profileCheck = await _client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      if (profileCheck == null) {
        final email = _client.auth.currentUser?.email ?? 'kader@example.com';
        final emailPrefix = email.split('@').first;
        final roleClean = emailPrefix.toLowerCase();
        String assignedRole = 'kader';
        if (roleClean.contains('superadmin')) {
          assignedRole = 'superadmin';
        } else if (roleClean.contains('admin')) {
          assignedRole = 'admin';
        }
        await _client.from('profiles').upsert({
          'id': userId,
          'full_name': emailPrefix,
          'role': assignedRole,
          if (posyanduId != null) 'posyandu_id': posyanduId,
        });
      }
    } catch (e) {
      print('Warning: could not ensure profile exists: $e');
    }
  }

  Future<void> submitReport({
    required String posyanduId,
    required int housesInspected,
    required int housesPositive,
    required List<String> breedingPlaceIds,
    required DateTime reportDate,
    String? notes,
    String status = 'submitted',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _ensureProfileExists(userId, posyanduId: posyanduId);

    // 1. Insert Report
    final reportResponse = await _client.from('reports').insert({
      'kader_id': userId,
      'posyandu_id': posyanduId,
      'houses_inspected': housesInspected,
      'houses_positive': housesPositive,
      'report_date': reportDate.toIso8601String(),
      'notes': notes,
      'status': status,
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
        .order('report_date', ascending: false)
        .order('id', ascending: true);

    return (response as List).map((data) {
      final bpList = data['report_breeding_places'] as List?;
      final breedingPlaces = bpList != null
          ? bpList
              .map((bp) => bp['breeding_place_id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList()
          : <String>[];
      return Report.fromMap(data as Map<String, dynamic>, breedingPlaceIds: breedingPlaces);
    }).toList();
  }

  Future<List<Report>> getAllReports() async {
    final response = await _client
        .from('reports')
        .select('*, profiles(full_name), posyandus(name, rws(villages(name))), report_breeding_places(breeding_place_id)')
        .order('report_date', ascending: false)
        .order('id', ascending: true);

    return (response as List).map((data) {
      final bpList = data['report_breeding_places'] as List?;
      final breedingPlaces = bpList != null
          ? bpList
              .map((bp) => bp['breeding_place_id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList()
          : <String>[];
      return Report.fromMap(data as Map<String, dynamic>, breedingPlaceIds: breedingPlaces);
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

    await _ensureProfileExists(adminId);

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
    required DateTime reportDate,
    String? notes,
    String status = 'submitted',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await _ensureProfileExists(userId);
    }

    // 1. Update Report & reset status to submitted for re-verification
    await _client.from('reports').update({
      'houses_inspected': housesInspected,
      'houses_positive': housesPositive,
      'report_date': reportDate.toIso8601String(),
      'notes': notes,
      'status': status,
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

  Future<List<Map<String, dynamic>>> getInterventionsByReport(String reportId) async {
    final response = await _client
        .from('interventions')
        .select('*')
        .eq('report_id', reportId)
        .eq('type', 'psn_ulang')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}

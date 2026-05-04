import 'dart:convert';
import 'package:http/http.dart' as http;

const String supabaseUrl = 'https://iyznzyqhsbjgtvxgiewe.supabase.co';
const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5em56eXFoc2JqZ3R2eGdpZXdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMTQzMzUsImV4cCI6MjA5MjY5MDMzNX0.JaaXQd9n8uJPZwO-WQ7m06Kvf1Rw35itu07MAAOBKyQ';

final Map<String, String> headers = {
  'apikey': supabaseKey,
  'Authorization': 'Bearer $supabaseKey',
  'Content-Type': 'application/json',
};

void main() async {
  final badVillageId = 'b3a6b8a5-d984-445a-9aff-ee3b1b2898e8';
  
  // 1. Get RW IDs
  final rwRes = await http.get(Uri.parse('$supabaseUrl/rest/v1/rws?village_id=eq.$badVillageId&select=id'), headers: headers);
  final rwIds = (jsonDecode(rwRes.body) as List).map((e) => e['id']).toList();
  
  for (var rwId in rwIds) {
    // 2. Get Posyandu IDs
    final pRes = await http.get(Uri.parse('$supabaseUrl/rest/v1/posyandus?rw_id=eq.$rwId&select=id'), headers: headers);
    final pIds = (jsonDecode(pRes.body) as List).map((e) => e['id']).toList();
    
    for (var pId in pIds) {
      // 3. Get Report IDs
      final rRes = await http.get(Uri.parse('$supabaseUrl/rest/v1/reports?posyandu_id=eq.$pId&select=id'), headers: headers);
      final rIds = (jsonDecode(rRes.body) as List).map((e) => e['id']).toList();
      
      for (var rId in rIds) {
        // 4. Delete Report Breeding Places
        await http.delete(Uri.parse('$supabaseUrl/rest/v1/report_breeding_places?report_id=eq.$rId'), headers: headers);
        // 5. Delete Interventions (if any)
        await http.delete(Uri.parse('$supabaseUrl/rest/v1/interventions?report_id=eq.$rId'), headers: headers);
        // 6. Delete Report
        await http.delete(Uri.parse('$supabaseUrl/rest/v1/reports?id=eq.$rId'), headers: headers);
        print('Deleted report $rId');
      }
      // 7. Delete Posyandu
      await http.delete(Uri.parse('$supabaseUrl/rest/v1/posyandus?id=eq.$pId'), headers: headers);
      print('Deleted posyandu $pId');
    }
    // 8. Delete RW
    await http.delete(Uri.parse('$supabaseUrl/rest/v1/rws?id=eq.$rwId'), headers: headers);
    print('Deleted RW $rwId');
  }
  
  // 9. Delete Village
  final vRes = await http.delete(Uri.parse('$supabaseUrl/rest/v1/villages?id=eq.$badVillageId'), headers: headers);
  print('Deleted village $badVillageId: ${vRes.statusCode}');
}

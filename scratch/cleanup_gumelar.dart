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
  
  // Fetch RWs
  final rwUrl = Uri.parse('$supabaseUrl/rest/v1/rws?village_id=eq.$badVillageId&select=id,rw_number');
  final rwRes = await http.get(rwUrl, headers: headers);
  final rws = jsonDecode(rwRes.body) as List;
  
  print('RWs in bad Gumelar ($badVillageId):');
  for (var rw in rws) {
    print('  ID: ${rw["id"]}, Number: ${rw["rw_number"]}');
    
    // Check Posyandus
    final posyanduUrl = Uri.parse('$supabaseUrl/rest/v1/posyandus?rw_id=eq.${rw["id"]}&select=id,name');
    final posyanduRes = await http.get(posyanduUrl, headers: headers);
    final posyandus = jsonDecode(posyanduRes.body) as List;
    for (var p in posyandus) {
        print('    - Posyandu: ${p["name"]}');
    }
  }

  // Cleanup script
  print('\nCleaning up...');
  for (var rw in rws) {
    // Delete Posyandus first
    final delP = Uri.parse('$supabaseUrl/rest/v1/posyandus?rw_id=eq.${rw["id"]}');
    await http.delete(delP, headers: headers);
    print('Deleted Posyandus for RW ${rw["rw_number"]}');
    
    // Delete RW
    final delRw = Uri.parse('$supabaseUrl/rest/v1/rws?id=eq.${rw["id"]}');
    await http.delete(delRw, headers: headers);
    print('Deleted RW ${rw["rw_number"]}');
  }
  
  // Delete Village
  final delV = Uri.parse('$supabaseUrl/rest/v1/villages?id=eq.$badVillageId');
  await http.delete(delV, headers: headers);
  print('Deleted Village Gumelar ($badVillageId)');
  
  print('Cleanup Done!');
}

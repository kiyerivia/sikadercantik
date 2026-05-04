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
  
  // Get Posyandus for this village
  final rwUrl = Uri.parse('$supabaseUrl/rest/v1/rws?village_id=eq.$badVillageId&select=id');
  final rwRes = await http.get(rwUrl, headers: headers);
  final rws = jsonDecode(rwRes.body) as List;
  
  for (var rw in rws) {
    final rwId = rw['id'];
    final pUrl = Uri.parse('$supabaseUrl/rest/v1/posyandus?rw_id=eq.$rwId&select=id,name');
    final pRes = await http.get(pUrl, headers: headers);
    final posyandus = jsonDecode(pRes.body) as List;
    
    for (var p in posyandus) {
      final pId = p['id'];
      final pName = p['name'];
      
      final rUrl = Uri.parse('$supabaseUrl/rest/v1/reports?posyandu_id=eq.$pId&select=id');
      final rRes = await http.get(rUrl, headers: headers);
      final reports = jsonDecode(rRes.body) as List;
      
      print('Posyandu: $pName ($pId) has ${reports.length} reports.');
    }
  }
}

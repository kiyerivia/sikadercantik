import 'dart:io';
import 'dart:convert';

void main() async {
  final envFile = File('.env');
  final envLines = envFile.readAsLinesSync();
  String? supabaseUrl;
  String? supabaseKey;

  for (var line in envLines) {
    if (line.contains('=')) {
      final parts = line.split('=');
      final key = parts[0].trim();
      final value = parts.sublist(1).join('=').trim();
      if (key == 'SUPABASE_URL') supabaseUrl = value;
      if (key == 'SUPABASE_ANON_KEY') supabaseKey = value;
    }
  }

  final client = HttpClient();
  final skId = '10802fda-133e-42d2-abe5-03cdb57e974e'; // Samudra Kulon

  try {
    print('--- Deep Inspection: Samudra Kulon ---');
    
    // 1. Check Village
    final vUrl = '$supabaseUrl/rest/v1/villages?select=*&id=eq.$skId';
    final vReq = await client.getUrl(Uri.parse(vUrl));
    vReq.headers.set('apikey', supabaseKey!);
    vReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final vRes = await vReq.close();
    final vBody = await vRes.transform(utf8.decoder).join();
    print('Village Data: $vBody');

    // 2. Check RWs linked to this Village
    final rUrl = '$supabaseUrl/rest/v1/rws?select=*&village_id=eq.$skId';
    final rReq = await client.getUrl(Uri.parse(rUrl));
    rReq.headers.set('apikey', supabaseKey);
    rReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final rRes = await rReq.close();
    final rBody = await rRes.transform(utf8.decoder).join();
    final List rws = jsonDecode(rBody);
    print('RWs found: ${rws.length}');
    for (var rw in rws) {
      print('  RW ID: ${rw['id']} | Number: ${rw['rw_number']}');
    }

    if (rws.isEmpty) {
      print('❌ ERROR: No RWs found for Samudra Kulon!');
    }

    // 3. Check Posyandus linked to these RWs
    for (var rw in rws) {
      final rwId = rw['id'];
      final pUrl = '$supabaseUrl/rest/v1/posyandus?select=*&rw_id=eq.$rwId';
      final pReq = await client.getUrl(Uri.parse(pUrl));
      pReq.headers.set('apikey', supabaseKey);
      pReq.headers.set('Authorization', 'Bearer $supabaseKey');
      final pRes = await pReq.close();
      final pBody = await pRes.transform(utf8.decoder).join();
      final List posyandus = jsonDecode(pBody);
      print('  RW ${rw['rw_number']} Posyandus: ${posyandus.length}');
      for (var p in posyandus) {
        print('    - ${p['name']}');
      }
    }

    // 4. Test the join query exactly as in MasterRepository
    print('\nTesting Join Query:');
    final jUrl = '$supabaseUrl/rest/v1/posyandus?select=*,rws!inner(village_id)&rws.village_id=eq.$skId';
    final jReq = await client.getUrl(Uri.parse(jUrl));
    jReq.headers.set('apikey', supabaseKey);
    jReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final jRes = await jReq.close();
    final jBody = await jRes.transform(utf8.decoder).join();
    final List joinResults = jsonDecode(jBody);
    print('Join Results Count: ${joinResults.length}');

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

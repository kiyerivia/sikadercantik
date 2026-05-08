import 'dart:convert';
import 'dart:io';

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
  try {
    print('🔍 Deep Analysis of Reports table...');
    final rReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/reports?select=*'));
    rReq.headers.set('apikey', supabaseKey!);
    rReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final rRes = await rReq.close();
    final List reports = jsonDecode(await rRes.transform(utf8.decoder).join());
    
    print('Total raw reports in table: ${reports.length}');
    for (var r in reports) {
      print(' - ID: ${r['id']} | Posyandu ID: ${r['posyandu_id']} | Date: ${r['report_date']}');
    }

    print('\n🔍 Checking if these Posyandu IDs exist...');
    for (var r in reports) {
      final pId = r['posyandu_id'];
      final pReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/posyandus?id=eq.$pId&select=id,name'));
      pReq.headers.set('apikey', supabaseKey);
      pReq.headers.set('Authorization', 'Bearer $supabaseKey');
      final List pList = jsonDecode(await (await pReq.close()).transform(utf8.decoder).join());
      if (pList.isEmpty) {
        print('❌ Posyandu ID $pId NOT FOUND (Orphaned Report!)');
      } else {
        print('✅ Posyandu ID $pId found: ${pList[0]['name']}');
      }
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

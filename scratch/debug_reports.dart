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
    print('🔍 Analyzing reports...');
    final rReq = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/reports?select=*,posyandus(name,rws(villages(name)))'));
    rReq.headers.set('apikey', supabaseKey!);
    rReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final rRes = await rReq.close();
    final List reports = jsonDecode(await rRes.transform(utf8.decoder).join());
    
    print('Total reports found: ${reports.length}');
    for (var r in reports) {
      final p = r['posyandus'];
      final v = p != null && p['rws'] != null && p['rws']['villages'] != null ? p['rws']['villages']['name'] : 'UNKNOWN VILLAGE';
      print('Report ID: ${r['id']} | Date: ${r['report_date']} | Posyandu: ${p != null ? p['name'] : 'DELETED POSYANDU'} | Village: $v');
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

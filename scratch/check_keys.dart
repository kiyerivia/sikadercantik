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

  try {
    print('Checking Posyandu table structure...');
    
    // Get one posyandu to see keys
    final url = '$supabaseUrl/rest/v1/posyandus?select=*&limit=1';
    final req = await client.getUrl(Uri.parse(url));
    req.headers.set('apikey', supabaseKey!);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Posyandu sample: $body');

    // Get one rw to see keys
    final rwUrl = '$supabaseUrl/rest/v1/rws?select=*&limit=1';
    final rwReq = await client.getUrl(Uri.parse(rwUrl));
    rwReq.headers.set('apikey', supabaseKey);
    rwReq.headers.set('Authorization', 'Bearer $supabaseKey');
    final rwRes = await rwReq.close();
    final rwBody = await rwRes.transform(utf8.decoder).join();
    print('RW sample: $rwBody');

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

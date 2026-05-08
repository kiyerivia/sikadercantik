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
    print('Checking reports for Samudra Kulon...');
    // We need to join with posyandus -> rws -> villages to see the village name
    final url = '$supabaseUrl/rest/v1/reports?select=id,posyandus(name,rws(villages(name)))&posyandus.rws.villages.name=eq.Samudra%20Kulon';
    final req = await client.getUrl(Uri.parse(url));
    req.headers.set('apikey', supabaseKey!);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Reports: $body');

  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

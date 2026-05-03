import 'dart:convert';
import 'package:http/http.dart' as http;

const String supabaseUrl = 'https://iyznzyqhsbjgtvxgiewe.supabase.co';
const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5em56eXFoc2JqZ3R2eGdpZXdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMTQzMzUsImV4cCI6MjA5MjY5MDMzNX0.JaaXQd9n8uJPZwO-WQ7m06Kvf1Rw35itu07MAAOBKyQ';

final Map<String, String> headers = {
  'apikey': supabaseKey,
  'Authorization': 'Bearer $supabaseKey',
  'Content-Type': 'application/json',
  'Prefer': 'return=representation',
};

Future<String> insertVillage(String name) async {
  final url = Uri.parse('$supabaseUrl/rest/v1/villages');
  final res = await http.post(url, headers: headers, body: jsonEncode({'name': name}));
  if (res.statusCode == 201) {
    return jsonDecode(res.body)[0]['id'];
  } else if (res.statusCode == 409) {
     // conflict, let's fetch it
     final getUrl = Uri.parse('$supabaseUrl/rest/v1/villages?name=eq.$name&select=id');
     final getRes = await http.get(getUrl, headers: headers);
     return jsonDecode(getRes.body)[0]['id'];
  }
  throw Exception('Failed to insert village: ${res.body}');
}

Future<String> insertRw(String villageId, String rwNumber) async {
  final url = Uri.parse('$supabaseUrl/rest/v1/rws');
  final res = await http.post(url, headers: headers, body: jsonEncode({'village_id': villageId, 'rw_number': rwNumber}));
  if (res.statusCode == 201) {
    return jsonDecode(res.body)[0]['id'];
  } else if (res.statusCode == 409) {
     final getUrl = Uri.parse('$supabaseUrl/rest/v1/rws?village_id=eq.$villageId&rw_number=eq.$rwNumber&select=id');
     final getRes = await http.get(getUrl, headers: headers);
     if (jsonDecode(getRes.body).isEmpty) {
        throw Exception('rw conflict but not found');
     }
     return jsonDecode(getRes.body)[0]['id'];
  }
  throw Exception('Failed to insert rw: ${res.body}');
}

Future<void> insertPosyandu(String rwId, String name) async {
  final url = Uri.parse('$supabaseUrl/rest/v1/posyandus');
  final res = await http.post(url, headers: headers, body: jsonEncode({'rw_id': rwId, 'name': name}));
  if (res.statusCode != 201 && res.statusCode != 409) {
     throw Exception('Failed to insert posyandu: ${res.body}');
  }
}

void main() async {
  final data = [
    {'desa': 'Cilangkap', 'rw': '1', 'posyandu': 'Posyandu Bina Sejahtera 1'},
    {'desa': 'Cilangkap', 'rw': '2', 'posyandu': 'Posyandu Bina Sejahtera 2'},
    {'desa': 'Cilangkap', 'rw': '3', 'posyandu': 'Posyandu Bina Sejahtera 3'},
    {'desa': 'Cilangkap', 'rw': '4', 'posyandu': 'Posyandu Bina Sejahtera 4'},
    {'desa': 'Cilangkap', 'rw': '5', 'posyandu': 'Posyandu Bina Sejahtera 5'},
    {'desa': 'Cilangkap', 'rw': '6', 'posyandu': 'Posyandu Bina Sejahtera 6'},

    {'desa': 'Cihonje', 'rw': '2', 'posyandu': 'Posyandu Dahlia 1'},
    {'desa': 'Cihonje', 'rw': '3', 'posyandu': 'Posyandu Melati'},
    {'desa': 'Cihonje', 'rw': '7', 'posyandu': 'Posyandu Puji Lestari'},
    {'desa': 'Cihonje', 'rw': '8', 'posyandu': 'Posyandu Dahlia 2'},
    {'desa': 'Cihonje', 'rw': '9', 'posyandu': 'Posyandu Cempaka'},
    {'desa': 'Cihonje', 'rw': '13', 'posyandu': 'Posyandu Boby Lestari'},
    {'desa': 'Cihonje', 'rw': '12', 'posyandu': 'Posyandu Budi Sasono 1'},
    {'desa': 'Cihonje', 'rw': '18', 'posyandu': 'Posyandu Regil Rahayu'},
    {'desa': 'Cihonje', 'rw': '16', 'posyandu': 'Posyandu Wijaya Kusuma'},
    {'desa': 'Cihonje', 'rw': '17', 'posyandu': 'Posyandu Budi Sasono 2'},
    {'desa': 'Cihonje', 'rw': '14', 'posyandu': 'Posyandu Laksono Utomo'},

    {'desa': 'Paningkaban', 'rw': '1', 'posyandu': 'Posyandu Jatiwaluyo'},
    {'desa': 'Paningkaban', 'rw': '2', 'posyandu': 'Posyandu Widodo'},
    {'desa': 'Paningkaban', 'rw': '3', 'posyandu': 'Posyandu Lestari'},
    {'desa': 'Paningkaban', 'rw': '4', 'posyandu': 'Posyandu Rahayu'},

    {'desa': 'Karangkemojing', 'rw': '1', 'posyandu': 'Posyandu Sari Asih'},
    {'desa': 'Karangkemojing', 'rw': '2', 'posyandu': 'Posyandu Mardi Siwi'},
    {'desa': 'Karangkemojing', 'rw': '2', 'posyandu': 'Posyandu Pamardi Siwi'},
    {'desa': 'Karangkemojing', 'rw': '3', 'posyandu': 'Posyandu Mekar Sari'},
    {'desa': 'Karangkemojing', 'rw': '3', 'posyandu': 'Posyandu Mugi Lestari'},
    {'desa': 'Karangkemojing', 'rw': '4', 'posyandu': 'Posyandu Karya Lestari'},
    {'desa': 'Karangkemojing', 'rw': '4', 'posyandu': 'Posyandu Basuki'},

    {'desa': 'Gancang', 'rw': '1', 'posyandu': 'Posyandu Tunas Bangsa 1'},
    {'desa': 'Gancang', 'rw': '4', 'posyandu': 'Posyandu Tunas Bangsa 2'},
    {'desa': 'Gancang', 'rw': '5', 'posyandu': 'Posyandu Tunas Bangsa 3'},
    {'desa': 'Gancang', 'rw': '2', 'posyandu': 'Posyandu Tunas Bangsa 4'},
    {'desa': 'Gancang', 'rw': '5', 'posyandu': 'Posyandu Tunas Bangsa 5'},
    {'desa': 'Gancang', 'rw': '3', 'posyandu': 'Posyandu Tunas Bangsa 6'},

    {'desa': 'Kedungurang', 'rw': '4', 'posyandu': 'Posyandu Taman Sari'},
    {'desa': 'Kedungurang', 'rw': '1', 'posyandu': 'Posyandu Mawar'},
    {'desa': 'Kedungurang', 'rw': '7', 'posyandu': 'Posyandu Melati'},
    {'desa': 'Kedungurang', 'rw': '6', 'posyandu': 'Posyandu Sanggar Sari'},
    {'desa': 'Kedungurang', 'rw': '2', 'posyandu': 'Posyandu Laju Sejahtera'},
    {'desa': 'Kedungurang', 'rw': '8', 'posyandu': 'Posyandu Mugi Rahayu'},
    {'desa': 'Kedungurang', 'rw': '3', 'posyandu': 'Posyandu Mugi Lestari'},

    {'desa': 'Gumelar', 'rw': '1', 'posyandu': 'Posyandu Bina Laju Sejahtera 1'},
    {'desa': 'Gumelar', 'rw': '2', 'posyandu': 'Posyandu Bina Laju Sejahtera 2'},
    {'desa': 'Gumelar', 'rw': '3', 'posyandu': 'Posyandu Bina Laju Sejahtera 3'},
    {'desa': 'Gumelar', 'rw': '4', 'posyandu': 'Posyandu Bina Laju Sejahtera 4'},
    {'desa': 'Gumelar', 'rw': '5', 'posyandu': 'Posyandu Bina Laju Sejahtera 5'},
    {'desa': 'Gumelar', 'rw': '6', 'posyandu': 'Posyandu Bina Laju Sejahtera 6'},
    {'desa': 'Gumelar', 'rw': '7', 'posyandu': 'Posyandu Bina Laju Sejahtera 7'},
    {'desa': 'Gumelar', 'rw': '8', 'posyandu': 'Posyandu Bina Laju Sejahtera 8'},
    {'desa': 'Gumelar', 'rw': '9', 'posyandu': 'Posyandu Bina Laju Sejahtera 9'},
    {'desa': 'Gumelar', 'rw': '10', 'posyandu': 'Posyandu Bina Laju Sejahtera 10'},
    {'desa': 'Gumelar', 'rw': '11', 'posyandu': 'Posyandu Bina Laju Sejahtera 11'},

    {'desa': 'Tlaga', 'rw': '1', 'posyandu': 'Posyandu Balita Rahayu 1'},
    {'desa': 'Tlaga', 'rw': '2', 'posyandu': 'Posyandu Balita Rahayu 2'},
    {'desa': 'Tlaga', 'rw': '3', 'posyandu': 'Posyandu Balita Rahayu 3'},
    {'desa': 'Tlaga', 'rw': '4', 'posyandu': 'Posyandu Balita Rahayu 4'},
    {'desa': 'Tlaga', 'rw': '5', 'posyandu': 'Posyandu Balita Rahayu 5'},
    {'desa': 'Tlaga', 'rw': '6', 'posyandu': 'Posyandu Balita Rahayu 6'},
    {'desa': 'Tlaga', 'rw': '7', 'posyandu': 'Posyandu Balita Rahayu 7'},
    {'desa': 'Tlaga', 'rw': '8', 'posyandu': 'Posyandu Balita Rahayu 8'},

    {'desa': 'Samudra', 'rw': '1', 'posyandu': 'Posyandu Harapan Bangsa 1'},
    {'desa': 'Samudra', 'rw': '2', 'posyandu': 'Posyandu Harapan Bangsa 2'},
    {'desa': 'Samudra', 'rw': '3', 'posyandu': 'Posyandu Harapan Bangsa 3'},
    {'desa': 'Samudra', 'rw': '4', 'posyandu': 'Posyandu Harapan Bangsa 4'},
    {'desa': 'Samudra', 'rw': '5', 'posyandu': 'Posyandu Harapan Bangsa 5'},
    {'desa': 'Samudra', 'rw': '6', 'posyandu': 'Posyandu Harapan Bangsa 6'},
    {'desa': 'Samudra', 'rw': '7', 'posyandu': 'Posyandu Harapan Bangsa 7'},
    {'desa': 'Samudra', 'rw': '8', 'posyandu': 'Posyandu Harapan Bangsa 8'},

    {'desa': 'Samudra Kulon', 'rw': '1', 'posyandu': 'Posyandu Mawar'},
    {'desa': 'Samudra Kulon', 'rw': '2', 'posyandu': 'Posyandu Budi Asih'},
    {'desa': 'Samudra Kulon', 'rw': '3', 'posyandu': 'Posyandu Kasih Ibu'},
    {'desa': 'Samudra Kulon', 'rw': '4', 'posyandu': 'Posyandu Anak Sehat'},
    {'desa': 'Samudra Kulon', 'rw': '5', 'posyandu': 'Posyandu Sayang Anak'},
  ];

  Map<String, String> villageIds = {};
  Map<String, String> rwIds = {};

  for (var item in data) {
    try {
      final desa = item['desa']!;
      final rw = item['rw']!;
      final posyandu = item['posyandu']!;

      if (!villageIds.containsKey(desa)) {
        villageIds[desa] = await insertVillage(desa);
        print('Inserted Village: $desa');
      }
      
      final villageId = villageIds[desa]!;
      final rwKey = '$villageId-$rw';
      
      if (!rwIds.containsKey(rwKey)) {
        rwIds[rwKey] = await insertRw(villageId, rw);
        print('Inserted RW: $rw in $desa');
      }

      final rwId = rwIds[rwKey]!;
      await insertPosyandu(rwId, posyandu);
      print('Inserted Posyandu: $posyandu');
    } catch (e) {
      print('Error on ${item["posyandu"]}: $e');
    }
  }
  print('Done seeding!');
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/domain/models.dart';

class PlaceEntry {
  String? selectedPlaceId;
  final TextEditingController countController = TextEditingController(text: '0');

  PlaceEntry();

  void dispose() {
    countController.dispose();
  }
}

class HouseReportEntry {
  final TextEditingController kkNameController = TextEditingController();
  final TextEditingController rtController = TextEditingController();
  final TextEditingController rwController = TextEditingController();
  List<PlaceEntry> placeEntries = [PlaceEntry()];

  HouseReportEntry();

  void dispose() {
    kkNameController.dispose();
    rtController.dispose();
    rwController.dispose();
    for (var p in placeEntries) p.dispose();
  }
}

class ReportFormScreen extends HookConsumerWidget {
  const ReportFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final housesInspectedController = useTextEditingController(text: '0');
    final housesPositiveController = useTextEditingController(text: '0');
    
    final houseEntries = useState<List<HouseReportEntry>>([]);

    // Initialize with one entry if empty
    useEffect(() {
      if (houseEntries.value.isEmpty) {
        houseEntries.value = [HouseReportEntry()];
      }
      return () {
        // We don't dispose here because useState preserves it between rebuilds.
        // Disposal happens when removing or clearing.
      };
    }, []);

    final selectedVillageId = useState<String?>(null);
    final selectedPosyanduId = useState<String?>(null);
    final reportDate = useState(DateTime.now());
    final isLoading = useState(false);

    // Watch Master Data
    final villagesAsync = ref.watch(villagesProvider);
    final posyandusAsync = selectedVillageId.value != null
        ? ref.watch(posyandusByVillageProvider(selectedVillageId.value!))
        : const AsyncValue.data(<Posyandu>[]);
    final breedingPlacesAsync = ref.watch(breedingPlacesProvider);

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) return;
      if (selectedPosyanduId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih Posyandu')),
        );
        return;
      }

      isLoading.value = true;
      try {
        StringBuffer notesBuffer = StringBuffer();
        List<String> allBreedingPlaceIds = [];

        for (int i = 0; i < houseEntries.value.length; i++) {
          final entry = houseEntries.value[i];
          notesBuffer.writeln('--- KK ${i + 1} ---');
          notesBuffer.writeln('Nama KK: ${entry.kkNameController.text.trim()}');
          notesBuffer.writeln('RT/RW: ${entry.rtController.text.trim()}/${entry.rwController.text.trim()}');
          
          for (int j = 0; j < entry.placeEntries.length; j++) {
            final p = entry.placeEntries[j];
            notesBuffer.writeln('Tempat ${j + 1}: ${p.selectedPlaceId ?? "-"}');
            notesBuffer.writeln('Jumlah ${j + 1}: ${p.countController.text.trim()}');
            if (p.selectedPlaceId != null) {
              allBreedingPlaceIds.add(p.selectedPlaceId!);
            }
          }
          notesBuffer.writeln('');
        }

        await ref.read(reportRepositoryProvider).submitReport(
              posyanduId: selectedPosyanduId.value!,
              housesInspected: int.tryParse(housesInspectedController.text) ?? 0,
              housesPositive: int.tryParse(housesPositiveController.text) ?? 0,
              breedingPlaceIds: allBreedingPlaceIds,
              notes: notesBuffer.toString(),
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan berhasil dikirim!')),
          );
          ref.invalidate(myReportsProvider);
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim laporan: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFD4E6F1),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F618D), Color(0xFF2980B9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      children: const [
                        TextSpan(text: 'SI KADER ', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'PSN', style: TextStyle(color: Color(0xFF82E0AA))),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.notifications, color: Colors.white),
                  const SizedBox(width: 12),
                  PopupMenuButton<void>(
                    onSelected: (_) async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF1F618D), size: 20),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: null, child: Text('Logout', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ENTRI LAPORAN PSN', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF154360))),
                        const SizedBox(height: 20),

                        // Master Selection
                        _buildLabel(icon: Icons.location_on, label: 'Nama Desa'),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          value: selectedVillageId.value,
                          hint: 'Pilih Desa',
                          items: villagesAsync.maybeWhen(
                            data: (list) => list.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(),
                            orElse: () => [],
                          ),
                          onChanged: (val) {
                            selectedVillageId.value = val;
                            selectedPosyanduId.value = null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildLabel(icon: Icons.home_work, label: 'Nama Posyandu'),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          value: selectedPosyanduId.value,
                          hint: 'Pilih Posyandu',
                          items: posyandusAsync.maybeWhen(
                            data: (list) => list.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                            orElse: () => [],
                          ),
                          onChanged: (val) => selectedPosyanduId.value = val,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel(icon: Icons.calendar_today, label: 'Tanggal Laporan'),
                        const SizedBox(height: 8),
                        _buildDatePicker(context, reportDate),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(child: _buildFieldColumn('Rumah Diperiksa', housesInspectedController)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildFieldColumn('Rumah Positif', housesPositiveController)),
                          ],
                        ),
                        const Divider(height: 40),

                        // House List
                        ...houseEntries.value.asMap().entries.map((e) {
                          final idx = e.key;
                          final house = e.value;
                          return _buildHouseCard(context, idx, house, houseEntries, breedingPlacesAsync);
                        }),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading.value ? null : handleSubmit,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60)),
                            child: isLoading.value 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('KIRIM LAPORAN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldColumn(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        _buildNumericField(controller),
      ],
    );
  }

  Widget _buildHouseCard(BuildContext context, int idx, HouseReportEntry house, ValueNotifier<List<HouseReportEntry>> houseEntries, AsyncValue breedingPlacesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('DATA KK POSITIF #${idx + 1}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF154360))),
            if (idx == 0)
              InkWell(
                onTap: () {
                  Feedback.forTap(context);
                  houseEntries.value = [...houseEntries.value, HouseReportEntry()];
                },
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Tambah data', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                        Text('Kartu Keluarga', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Image.asset('assets/images/icon_kk.png', width: 34, height: 34),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildLabelAsset('assets/images/icon_mosquito.png', 'Status Pemeriksaan'),
        const SizedBox(height: 8),
        _buildDropdown(value: 'Ada Jentik', hint: 'Pilih Status', items: const [DropdownMenuItem(value: 'Ada Jentik', child: Text('Ada Jentik'))], onChanged: (_) {}),
        const SizedBox(height: 16),
        _buildLabelAsset('assets/images/icon_kk.png', 'Nama KK & RT/RW'),
        const SizedBox(height: 8),
        _buildKKRow(house),
        const SizedBox(height: 16),
        
        Text('Tempat Positif Jentik', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF154360))),
        const SizedBox(height: 8),
        ...house.placeEntries.asMap().entries.map((pe) {
          final pIdx = pe.key;
          final pEntry = pe.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: pEntry.selectedPlaceId,
                        hint: 'Pilih Tempat',
                        items: breedingPlacesAsync.maybeWhen(
                          data: (list) => (list as List).map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['name'].toString()))).toList(),
                          orElse: () => [],
                        ),
                        onChanged: (val) {
                          pEntry.selectedPlaceId = val;
                          houseEntries.value = [...houseEntries.value];
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (pIdx == 0)
                      InkWell(
                        onTap: () {
                          Feedback.forTap(context);
                          house.placeEntries.add(PlaceEntry());
                          houseEntries.value = [...houseEntries.value];
                        },
                        child: Image.asset('assets/images/icon_tambah_lokasi_positif.png', width: 34, height: 34),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () {
                          house.placeEntries.removeAt(pIdx);
                          houseEntries.value = [...houseEntries.value];
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Jumlah Tempat Positif', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[700])),
                    SizedBox(width: 80, child: _buildNumericField(pEntry.countController)),
                  ],
                ),
              ],
            ),
          );
        }),

        if (houseEntries.value.length > 1)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                houseEntries.value = List.from(houseEntries.value)..removeAt(idx);
              },
              icon: const Icon(Icons.delete, color: Colors.red, size: 16),
              label: Text('Hapus KK ini', style: TextStyle(color: Colors.red, fontSize: 11)),
            ),
          ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildKKRow(HouseReportEntry house) {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildTextField(house.kkNameController, 'Nama KK')),
        const SizedBox(width: 8),
        SizedBox(width: 45, child: _buildTextField(house.rtController, 'RT')),
        const SizedBox(width: 8),
        SizedBox(width: 45, child: _buildTextField(house.rwController, 'RW')),
      ],
    );
  }

  Widget _buildLabel({required IconData icon, required String label}) {
    return Row(children: [Icon(icon, size: 16, color: Colors.blue), const SizedBox(width: 8), Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold))]);
  }

  Widget _buildLabelAsset(String asset, String label) {
    return Row(children: [Image.asset(asset, width: 16, height: 16), const SizedBox(width: 8), Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold))]);
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
    );
  }

  Widget _buildNumericField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
    );
  }

  Widget _buildDropdown({required String? value, required String hint, required List<DropdownMenuItem<String>> items, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(value: value, hint: Text(hint, style: TextStyle(fontSize: 13, color: Colors.grey[600])), isExpanded: true, items: items, onChanged: onChanged),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, ValueNotifier<DateTime> date) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: date.value, firstDate: DateTime(2020), lastDate: DateTime.now());
        if (picked != null) date.value = picked;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [const Icon(Icons.calendar_today, size: 16, color: Colors.grey), const SizedBox(width: 12), Text(DateFormat('dd MMMM yyyy').format(date.value), style: const TextStyle(fontSize: 13))]),
      ),
    );
  }
}

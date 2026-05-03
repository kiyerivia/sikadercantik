import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../shared/providers/report_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/auth_providers.dart';

class HouseReportEntry {
  final TextEditingController kkNameController = TextEditingController();
  final TextEditingController rtController = TextEditingController();
  final TextEditingController rwController = TextEditingController();
  final TextEditingController positivePlacesCountController = TextEditingController(text: '0');
  String? selectedResult;
  String? selectedPlaceId;

  HouseReportEntry();

  void dispose() {
    kkNameController.dispose();
    rtController.dispose();
    rwController.dispose();
    positivePlacesCountController.dispose();
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
        for (var entry in houseEntries.value) {
          entry.dispose();
        }
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
          notesBuffer.writeln('Hasil: ${entry.selectedResult ?? "-"}');
          notesBuffer.writeln('Tempat: ${entry.selectedPlaceId ?? "-"}');
          notesBuffer.writeln('Jumlah: ${entry.positivePlacesCountController.text.trim()}');
          notesBuffer.writeln('');

          if (entry.selectedPlaceId != null) {
            allBreedingPlaceIds.add(entry.selectedPlaceId!);
          }
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
            const SnackBar(content: Text('Laporan berhasil dikirim dan tersimpan di database!')),
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
      backgroundColor: const Color(0xFFD4E6F1), // Light blue background like sky
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar (Same as before)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F618D), Color(0xFF2980B9)], // Dark to mid blue
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/images/psn_logo_new.jpg', fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      children: const [
                        TextSpan(text: 'SI KADER ', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'PSN', style: TextStyle(color: Color(0xFF82E0AA))),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      const Icon(Icons.notifications, color: Colors.white),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.yellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton<void>(
                    onSelected: (_) async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    offset: const Offset(0, 50),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: null,
                        child: Row(
                          children: [
                            const Icon(Icons.logout, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Text('Logout', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF1F618D), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            // Breadcrumbs (Same as before)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: Text('Beranda', style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 12)),
                  ),
                  const Icon(Icons.chevron_right, size: 14, color: Colors.blueGrey),
                  Text('Entri Laporan PSN', style: GoogleFonts.outfit(color: const Color(0xFF2C3E50), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            // Main Form Container
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ENTRI LAPORAN PSN',
                          style: GoogleFonts.outfit(color: const Color(0xFF154360), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        // Global Fields
                        _buildLabel(iconWidget: const Icon(Icons.location_on, size: 16, color: Colors.blue), label: 'Nama Desa'),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          value: selectedVillageId.value,
                          hint: villagesAsync.maybeWhen(loading: () => 'Memuat desa...', orElse: () => 'Pilih Desa'),
                          onChanged: (val) {
                            selectedVillageId.value = val;
                            selectedPosyanduId.value = null;
                          },
                          items: villagesAsync.maybeWhen(
                            data: (villages) => villages.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(),
                            orElse: () => [],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildLabel(iconWidget: Image.asset('assets/images/icon_posyandu.png', width: 16, height: 16), label: 'Nama Posyandu'),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          value: selectedPosyanduId.value,
                          hint: posyandusAsync.maybeWhen(loading: () => 'Memuat posyandu...', orElse: () => 'Pilih Posyandu'),
                          onChanged: (val) => selectedPosyanduId.value = val,
                          items: posyandusAsync.maybeWhen(
                            data: (posyandus) => posyandus.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                            orElse: () => [],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildLabel(iconWidget: const Icon(Icons.calendar_today, size: 16, color: Colors.blue), label: 'Tanggal Laporan'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: reportDate.value,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) reportDate.value = date;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month, color: Colors.grey[600], size: 18),
                                const SizedBox(width: 12),
                                Text(DateFormat('dd MMMM yyyy').format(reportDate.value)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Jumlah Rumah Diperiksa', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF154360))),
                                  const SizedBox(height: 8),
                                  _buildNumericInput(housesInspectedController),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Jumlah Rumah Positif Jentik', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF154360))),
                                  const SizedBox(height: 8),
                                  _buildNumericInput(housesPositiveController),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 40, thickness: 1, color: Color(0xFFD4E6F1)),

                        // House Entries
                        ...houseEntries.value.asMap().entries.map((e) {
                          final idx = e.key;
                          final entry = e.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'DATA KK POSITIF #${idx + 1}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF154360),
                                    ),
                                  ),
                                  // Custom Add Button (Match Screenshot Proportions)
                                  if (idx == 0)
                                    InkWell(
                                      onTap: () {
                                        Feedback.forTap(context);
                                        houseEntries.value = [...houseEntries.value, HouseReportEntry()];
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFF154360), width: 1.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              child: Text(
                                                'Tambah data KK',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF154360),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 1.2,
                                              height: 22,
                                              color: const Color(0xFF154360),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              child: Image.asset(
                                                'assets/images/icon_tambah_lokasi_positif.png',
                                                width: 16,
                                                height: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildLabel(
                                iconWidget: Image.asset('assets/images/icon_mosquito.png', width: 18, height: 18),
                                label: 'Status Pemeriksaan',
                              ),
                              const SizedBox(height: 8),
                              _buildDropdown(
                                value: entry.selectedResult,
                                hint: 'Pilih Status',
                                onChanged: (val) {
                                  Feedback.forTap(context);
                                  entry.selectedResult = val;
                                  houseEntries.value = [...houseEntries.value]; // Trigger rebuild
                                },
                                items: ['Ada Jentik', 'Nihil'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              ),
                              const SizedBox(height: 16),
                              _buildLabel(
                                iconWidget: Image.asset('assets/images/icon_kk.png', width: 18, height: 18),
                                label: 'Nama KK & RT/RW',
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(flex: 2, child: _buildTextInput(entry.kkNameController, 'Nama')),
                                  const SizedBox(width: 12),
                                  _buildSmallLabel('RT'),
                                  const SizedBox(width: 4),
                                  SizedBox(width: 45, child: _buildSmallTextInput(entry.rtController)),
                                  const SizedBox(width: 8),
                                  _buildSmallLabel('RW'),
                                  const SizedBox(width: 4),
                                  SizedBox(width: 45, child: _buildSmallTextInput(entry.rwController)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildLabel(
                                iconWidget: const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                                label: 'Tempat Positif Jentik',
                              ),
                              const SizedBox(height: 8),
                              _buildDropdown(
                                value: entry.selectedPlaceId,
                                hint: breedingPlacesAsync.maybeWhen(loading: () => 'Memuat tempat...', orElse: () => 'Pilih Tempat'),
                                onChanged: (val) {
                                  Feedback.forTap(context);
                                  entry.selectedPlaceId = val;
                                  houseEntries.value = [...houseEntries.value];
                                },
                                items: breedingPlacesAsync.maybeWhen(
                                  data: (places) => places.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['name'] as String))).toList(),
                                  orElse: () => [],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildLabel(
                                    iconWidget: const Icon(Icons.settings, size: 16, color: Colors.teal),
                                    label: 'Jumlah Tempat Positif',
                                  ),
                                  SizedBox(width: 60, child: _buildNumericInput(entry.positivePlacesCountController)),
                                ],
                              ),
                              if (houseEntries.value.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        Feedback.forTap(context);
                                        final newList = List<HouseReportEntry>.from(houseEntries.value);
                                        newList.removeAt(idx);
                                        entry.dispose();
                                        houseEntries.value = newList;
                                      },
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                      label: Text(
                                        'Hapus KK ini',
                                        style: GoogleFonts.outfit(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        backgroundColor: Colors.red.withOpacity(0.05),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              const Divider(height: 32),
                            ],
                          );
                        }),

                        const SizedBox(height: 16),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading.value
                                ? null
                                : () {
                                    Feedback.forTap(context);
                                    handleSubmit();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27AE60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: isLoading.value
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text('KIRIM LAPORAN', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildSmallLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[700])),
    );
  }

  Widget _buildLabel({required Widget iconWidget, required String label}) {
    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF154360)),
        ),
      ],
    );
  }

  Widget _buildSmallTextInput(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          isExpanded: true,
          menuMaxHeight: 350,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          dropdownColor: Colors.white,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildNumericInput(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }

  Widget _buildTextInput(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }
}


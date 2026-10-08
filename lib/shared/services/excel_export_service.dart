import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'dart:io' as io;

import '../domain/models.dart';
import '../providers/admin_providers.dart';

class ExcelExportService {
  /// Nama bulan dalam Bahasa Indonesia
  static const List<String> monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Generate dan download file Excel Rekap Bulanan PSN
  static Future<bool> exportMonthlyReport({
    required int month, // 0 = Semua, 1-12 = Bulan tertentu
    required int year, // 0 = Semua, atau angka tahun seperti 2026
    required List<VillageAbjDetail> villageDetails,
    required List<Report> reports,
    Map<String, dynamic>? stats,
    String? selectedVillage,
    String knownByName = 'Rivia Developer',
  }) async {
    final excel = Excel.createExcel();

    // Setup nama file
    final String monthText =
        (month >= 1 && month <= 12) ? monthNames[month - 1] : 'Semua_Bulan';
    final String yearText = year > 0 ? year.toString() : 'Semua_Tahun';
    final String fileSlug = 'Rekap_PSN_Gumelar_${monthText}_$yearText';
    final String fileName = '$fileSlug.xlsx';

    // ─────────────────────────────────────────────────────────
    // SHEET 1: REKAPITULASI CAPAIAN ABJ & PSN
    // ─────────────────────────────────────────────────────────
    const sheet1Name = 'Rekapitulasi ABJ';
    final Sheet sheet1 = excel[sheet1Name];
    excel.setDefaultSheet(sheet1Name);
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    _buildRekapSheet(
      sheet: sheet1,
      month: month,
      year: year,
      villageDetails: villageDetails,
      reports: reports,
      stats: stats,
      selectedVillage: selectedVillage,
      knownByName: knownByName,
    );

    // ─────────────────────────────────────────────────────────
    // SHEET 2: DETAIL LAPORAN SURVEILANS KADER
    // ─────────────────────────────────────────────────────────
    const sheet2Name = 'Detail Laporan Kader';
    final Sheet sheet2 = excel[sheet2Name];

    _buildDetailSheet(
      sheet: sheet2,
      month: month,
      year: year,
      reports: reports,
    );

    // ─────────────────────────────────────────────────────────
    // SIMPAN / UNDUH FILE
    // ─────────────────────────────────────────────────────────
    return await _saveFile(excel, fileName);
  }

  /// Membangun Sheet 1 (Rekapitulasi Eksekutif & per Desa)
  static void _buildRekapSheet({
    required Sheet sheet,
    required int month,
    required int year,
    required List<VillageAbjDetail> villageDetails,
    required List<Report> reports,
    Map<String, dynamic>? stats,
    String? selectedVillage,
    String knownByName = 'Rivia Developer',
  }) {
    // Definisi Style Elemen
    final headerKopStyle = CellStyle(
      bold: true,
      fontSize: 13,
      fontFamily: 'Calibri',
      fontColorHex: ExcelColor.fromHexString('FF10365F'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final subKopStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontFamily: 'Calibri',
      fontColorHex: ExcelColor.fromHexString('FF10365F'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final metaInfoStyle = CellStyle(
      italic: true,
      fontSize: 9,
      fontFamily: 'Calibri',
      fontColorHex: ExcelColor.fromHexString('FF64748B'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final sectionTitleStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('FF10365F'),
      fontColorHex: ExcelColor.white,
      bold: true,
      fontSize: 10,
      fontFamily: 'Calibri',
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final tableHeaderStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('FF1E3A8A'),
      fontColorHex: ExcelColor.white,
      bold: true,
      fontSize: 10,
      fontFamily: 'Calibri',
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFCBD5E1'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFCBD5E1'),
      ),
      topBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFCBD5E1'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFCBD5E1'),
      ),
    );

    final borderThin = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('FFE2E8F0'),
    );

    final dataTextStyle = CellStyle(
      fontSize: 9,
      fontFamily: 'Calibri',
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );

    final dataNumStyle = CellStyle(
      fontSize: 9,
      fontFamily: 'Calibri',
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );

    final dataCenterStyle = CellStyle(
      fontSize: 9,
      fontFamily: 'Calibri',
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );

    final kpiLabelStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('FFF8FAFC'),
      fontSize: 9,
      fontFamily: 'Calibri',
      bold: true,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );

    final kpiValueStyle = CellStyle(
      fontSize: 9,
      fontFamily: 'Calibri',
      bold: true,
      fontColorHex: ExcelColor.fromHexString('FF10365F'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );

    // Gunakan villageDetails atau sintesiskan dari daftar reports jika kosong
    List<VillageAbjDetail> effectiveVillageDetails = List.from(villageDetails);
    if (effectiveVillageDetails.isEmpty && reports.isNotEmpty) {
      final Map<String, List<Report>> grouped = {};
      for (final r in reports) {
        final vName = (r.villageName != null && r.villageName!.trim().isNotEmpty)
            ? r.villageName!.trim()
            : 'Desa Gumelar';
        grouped.putIfAbsent(vName, () => []).add(r);
      }
      effectiveVillageDetails = grouped.entries.map((entry) {
        final vName = entry.key;
        final vReports = entry.value;
        final inspected = vReports.fold<int>(0, (s, r) => s + r.housesInspected);
        final positive = vReports.fold<int>(0, (s, r) => s + r.housesPositive);
        final safePositive = positive.clamp(0, inspected);
        final free = (inspected - safePositive).clamp(0, inspected);
        final abj = inspected > 0 ? (free / inspected) * 100.0 : 100.0;
        final hi = inspected > 0 ? (positive / inspected) * 100.0 : 0.0;
        final posyanduSet = vReports.map((r) => r.posyanduName ?? '').where((p) => p.isNotEmpty).toSet();
        return VillageAbjDetail(
          villageName: vName,
          totalInspected: inspected,
          totalPositive: positive,
          totalFree: free,
          abj: abj,
          houseIndex: hi,
          reportCount: vReports.length,
          posyanduCount: posyanduSet.length,
          reports: vReports,
        );
      }).toList();
    }

    // Hitung ringkasan
    int totalInspected = 0;
    int totalPositive = 0;
    for (var v in effectiveVillageDetails) {
      totalInspected += v.totalInspected;
      totalPositive += v.totalPositive;
    }
    final int totalFree = totalInspected - totalPositive;
    final double overallAbj = totalInspected > 0
        ? ((totalInspected - totalPositive) / totalInspected) * 100
        : 100.0;
    final int targetMetCount = effectiveVillageDetails.where((v) => v.isTargetMet).length;

    final String monthStr =
        (month >= 1 && month <= 12) ? monthNames[month - 1] : 'Semua Bulan';
    final String yearStr = year > 0 ? year.toString() : 'Semua Tahun';
    final String periodLabel = '$monthStr $yearStr';
    final String exportDateStr =
        DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now());

    // 1. KOP SURAT
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0),
      customValue: TextCellValue('PEMERINTAH KABUPATEN BANYUMAS'),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle =
        headerKopStyle;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 1),
      customValue: TextCellValue('DINAS KESEHATAN - PUSKESMAS GUMELAR'),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle =
        headerKopStyle;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 2),
      customValue: TextCellValue(
          'LAPORAN REKAPITULASI SURVEILANS JENTIK & PSN (PEMBERANTASAN SARANG NYAMUK)'),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).cellStyle =
        subKopStyle;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 3),
      customValue: TextCellValue(
          'Periode: $periodLabel | Wilayah Kerja: Puskesmas Gumelar | Waktu Cetak: $exportDateStr WIB'),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).cellStyle =
        metaInfoStyle;

    // 2. KOTAK RINGKASAN INDIKATOR KESEHATAN
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 5),
      customValue: TextCellValue('RINGKASAN INDIKATOR EPIDEMIOLOGI KECAMATAN GUMELAR'),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).cellStyle =
        sectionTitleStyle;

    // Row 6: Total Rumah Diperiksa & Target Standar Kemenkes
    _setCellMerged(sheet, 0, 3, 6, 'Total Rumah Diperiksa', kpiLabelStyle);
    _setCell(sheet, 4, 6, '$totalInspected Rumah', kpiValueStyle);
    _setCellMerged(sheet, 5, 7, 6, 'Target Standar Kemenkes RI', kpiLabelStyle);
    _setCellMerged(sheet, 8, 9, 6, '≥ 95.0% (Angka Bebas Jentik)', kpiValueStyle);

    // Row 7: Total Rumah Positif & Capaian ABJ
    _setCellMerged(sheet, 0, 3, 7, 'Total Positif Jentik', kpiLabelStyle);
    _setCell(sheet, 4, 7, '$totalPositive Rumah', kpiValueStyle);
    _setCellMerged(sheet, 5, 7, 7, 'Capaian Angka Bebas Jentik (ABJ)', kpiLabelStyle);
    _setCellMerged(
      sheet,
      8,
      9,
      7,
      '${overallAbj.toStringAsFixed(1)}%',
      CellStyle(
        fontSize: 10,
        fontFamily: 'Calibri',
        bold: true,
        fontColorHex: overallAbj >= 95.0
            ? ExcelColor.fromHexString('FF15803D')
            : ExcelColor.fromHexString('FFB91C1C'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: borderThin,
        rightBorder: borderThin,
        topBorder: borderThin,
        bottomBorder: borderThin,
      ),
    );

    // Row 8: Total Rumah Bebas & Status Mutu Wilayah
    _setCellMerged(sheet, 0, 3, 8, 'Total Bebas Jentik', kpiLabelStyle);
    _setCell(sheet, 4, 8, '$totalFree Rumah', kpiValueStyle);
    _setCellMerged(sheet, 5, 7, 8, 'Status Mutu Wilayah Kerja', kpiLabelStyle);
    _setCellMerged(
      sheet,
      8,
      9,
      8,
      overallAbj >= 95.0 ? 'MEMENUHI TARGET (AMAN)' : 'DI BAWAH TARGET (WASPADA)',
      CellStyle(
        fontSize: 9,
        fontFamily: 'Calibri',
        bold: true,
        fontColorHex: overallAbj >= 95.0
            ? ExcelColor.fromHexString('FF15803D')
            : ExcelColor.fromHexString('FFB91C1C'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: borderThin,
        rightBorder: borderThin,
        topBorder: borderThin,
        bottomBorder: borderThin,
      ),
    );

    // Row 9: Total Laporan & Desa Memenuhi Target
    _setCellMerged(sheet, 0, 3, 9, 'Total Laporan PSN Terverifikasi', kpiLabelStyle);
    _setCell(sheet, 4, 9, '${reports.length} Laporan', kpiValueStyle);
    _setCellMerged(sheet, 5, 7, 9, 'Desa Capai Target / Total Desa', kpiLabelStyle);
    _setCellMerged(
      sheet,
      8,
      9,
      9,
      '$targetMetCount / ${villageDetails.length} Desa (${villageDetails.isNotEmpty ? ((targetMetCount / villageDetails.length) * 100).toStringAsFixed(0) : 0}%)',
      kpiValueStyle,
    );

    // 3. TABEL REKAPITULASI PER DESA
    const startTableHeadingRow = 11;
    final headers = [
      'NO',
      'NAMA DESA',
      'JML POSYANDU',
      'JML LAPORAN',
      'RUMAH DIPERIKSA',
      'POSITIF JENTIK',
      'BEBAS JENTIK',
      'ABJ (%)',
      'STATUS MUTU',
      'REKOMENDASI INTERVENSI PUSKESMAS',
    ];

    for (int col = 0; col < headers.length; col++) {
      _setCell(sheet, col, startTableHeadingRow, headers[col], tableHeaderStyle);
    }

    int currentRow = startTableHeadingRow + 1;
    int index = 1;

    for (var v in effectiveVillageDetails) {
      final isEven = index % 2 == 0;
      final rowBg = isEven
          ? ExcelColor.fromHexString('FFF8FAFC')
          : ExcelColor.white;

      final dynamicTextStyle = dataTextStyle.copyWith(
        backgroundColorHexVal: rowBg,
      );
      final dynamicNumStyle = dataNumStyle.copyWith(
        backgroundColorHexVal: rowBg,
      );
      final dynamicCenterStyle = dataCenterStyle.copyWith(
        backgroundColorHexVal: rowBg,
      );

      final abjStatusStyle = CellStyle(
        backgroundColorHex: rowBg,
        fontSize: 9,
        fontFamily: 'Calibri',
        bold: true,
        fontColorHex: v.isTargetMet
            ? ExcelColor.fromHexString('FF15803D')
            : ExcelColor.fromHexString('FFB91C1C'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: borderThin,
        rightBorder: borderThin,
        topBorder: borderThin,
        bottomBorder: borderThin,
      );

      _setCell(sheet, 0, currentRow, '$index', dynamicCenterStyle);
      _setCell(sheet, 1, currentRow, v.villageName, dynamicTextStyle);
      _setCell(sheet, 2, currentRow, '${v.posyanduCount}', dynamicCenterStyle);
      _setCell(sheet, 3, currentRow, '${v.reportCount}', dynamicCenterStyle);
      _setCell(sheet, 4, currentRow, '${v.totalInspected}', dynamicNumStyle);
      _setCell(sheet, 5, currentRow, '${v.totalPositive}', dynamicNumStyle);
      _setCell(sheet, 6, currentRow, '${v.totalFree}', dynamicNumStyle);
      _setCell(
        sheet,
        7,
        currentRow,
        '${v.abj.toStringAsFixed(1)}%',
        abjStatusStyle,
      );
      _setCell(
        sheet,
        8,
        currentRow,
        v.isTargetMet ? 'AMAN (≥95%)' : 'WASPADA (<95%)',
        abjStatusStyle,
      );
      _setCell(sheet, 9, currentRow, v.recommendation, dynamicTextStyle);

      currentRow++;
      index++;
    }

    // Baris Total / Rata-rata
    final totalRowStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('FFE2E8F0'),
      bold: true,
      fontSize: 10,
      fontFamily: 'Calibri',
      fontColorHex: ExcelColor.fromHexString('FF0F172A'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('FF10365F'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Double,
        borderColorHex: ExcelColor.fromHexString('FF10365F'),
      ),
      leftBorder: borderThin,
      rightBorder: borderThin,
    );

    final totalCenterStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('FFE2E8F0'),
      bold: true,
      fontSize: 10,
      fontFamily: 'Calibri',
      fontColorHex: ExcelColor.fromHexString('FF0F172A'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('FF10365F'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Double,
        borderColorHex: ExcelColor.fromHexString('FF10365F'),
      ),
      leftBorder: borderThin,
      rightBorder: borderThin,
    );

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
      customValue: TextCellValue('TOTAL / RATA-RATA WILAYAH'),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle =
        totalCenterStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).cellStyle =
        totalCenterStyle;

    int totalPosyandu = 0;
    for (var v in effectiveVillageDetails) {
      totalPosyandu += v.posyanduCount;
    }

    _setCell(sheet, 2, currentRow, '$totalPosyandu', totalCenterStyle);
    _setCell(sheet, 3, currentRow, '${reports.length}', totalCenterStyle);
    _setCell(sheet, 4, currentRow, '$totalInspected', totalRowStyle);
    _setCell(sheet, 5, currentRow, '$totalPositive', totalRowStyle);
    _setCell(sheet, 6, currentRow, '$totalFree', totalRowStyle);
    _setCell(sheet, 7, currentRow, '${overallAbj.toStringAsFixed(1)}%', totalCenterStyle);
    _setCell(
      sheet,
      8,
      currentRow,
      overallAbj >= 95.0 ? 'AMAN (≥95%)' : 'WASPADA (<95%)',
      totalCenterStyle,
    );
    _setCell(sheet, 9, currentRow, '-', totalCenterStyle);

    // 4. LEMBAR PENGESAHAN / TANDA TANGAN
    currentRow += 3;
    final signTextStyle = CellStyle(
      fontSize: 10,
      fontFamily: 'Calibri',
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final String todayDate =
        DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());

    _setCellMerged(
      sheet,
      6,
      9,
      currentRow,
      'Gumelar, $todayDate',
      signTextStyle,
    );
    currentRow++;

    _setCellMerged(
      sheet,
      1,
      3,
      currentRow,
      'Mengetahui,',
      signTextStyle,
    );
    _setCellMerged(
      sheet,
      6,
      9,
      currentRow,
      'Pengelola Program P2M / PSN,',
      signTextStyle,
    );
    currentRow++;

    _setCellMerged(
      sheet,
      1,
      3,
      currentRow,
      'Kepala Puskesmas Gumelar',
      signTextStyle,
    );
    _setCellMerged(
      sheet,
      6,
      9,
      currentRow,
      'Puskesmas Gumelar',
      signTextStyle,
    );

    currentRow += 4;
    final signNameStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontFamily: 'Calibri',
      underline: Underline.Single,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    _setCellMerged(
      sheet,
      1,
      3,
      currentRow,
      '( $knownByName )',
      signNameStyle,
    );
    _setCellMerged(
      sheet,
      6,
      9,
      currentRow,
      '( Tim Sanitarian Puskesmas )',
      signNameStyle,
    );

    // Set Column Widths yang proporsional
    sheet.setColumnWidth(0, 6.0); // NO
    sheet.setColumnWidth(1, 24.0); // NAMA DESA
    sheet.setColumnWidth(2, 14.0); // JML POSYANDU
    sheet.setColumnWidth(3, 14.0); // JML LAPORAN
    sheet.setColumnWidth(4, 18.0); // RUMAH DIPERIKSA
    sheet.setColumnWidth(5, 16.0); // POSITIF JENTIK
    sheet.setColumnWidth(6, 16.0); // BEBAS JENTIK
    sheet.setColumnWidth(7, 14.0); // ABJ %
    sheet.setColumnWidth(8, 22.0); // STATUS MUTU
    sheet.setColumnWidth(9, 45.0); // REKOMENDASI INTERVENSI
  }

  /// Membangun Sheet 2 (Detail Laporan PSN Individu)
  static void _buildDetailSheet({
    required Sheet sheet,
    required int month,
    required int year,
    required List<Report> reports,
  }) {
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontFamily: 'Calibri',
      fontColorHex: ExcelColor.fromHexString('FF10365F'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final subTitleStyle = CellStyle(
      italic: true,
      fontSize: 10,
      fontFamily: 'Calibri',
      fontColorHex: ExcelColor.fromHexString('FF64748B'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final tableHeaderStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('FF10365F'),
      fontColorHex: ExcelColor.white,
      bold: true,
      fontSize: 10,
      fontFamily: 'Calibri',
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFCBD5E1'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFCBD5E1'),
      ),
      topBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFCBD5E1'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFCBD5E1'),
      ),
    );

    final borderThin = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('FFE2E8F0'),
    );

    final dataTextStyle = CellStyle(
      fontSize: 9,
      fontFamily: 'Calibri',
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );

    final dataNumStyle = CellStyle(
      fontSize: 9,
      fontFamily: 'Calibri',
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );

    final dataCenterStyle = CellStyle(
      fontSize: 9,
      fontFamily: 'Calibri',
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: borderThin,
      rightBorder: borderThin,
      topBorder: borderThin,
      bottomBorder: borderThin,
    );

    final String monthStr =
        (month >= 1 && month <= 12) ? monthNames[month - 1] : 'Semua Bulan';
    final String yearStr = year > 0 ? year.toString() : 'Semua Tahun';

    _setCell(
      sheet,
      0,
      0,
      'DETAIL LOG LAPORAN HASIL PEMANTAUAN JENTIK OLEH KADER',
      titleStyle,
    );
    _setCell(
      sheet,
      0,
      1,
      'Wilayah: Puskesmas Gumelar | Periode: $monthStr $yearStr | Total: ${reports.length} Data',
      subTitleStyle,
    );

    const startRow = 3;
    final headers = [
      'NO',
      'TANGGAL PSN',
      'JAM LAPOR',
      'DESA',
      'POSYANDU',
      'RUMAH DIPERIKSA',
      'POSITIF JENTIK',
      'BEBAS JENTIK',
      'ABJ (%)',
      'STATUS VERIFIKASI',
      'CATATAN / TINDAK LANJUT',
    ];

    for (int col = 0; col < headers.length; col++) {
      _setCell(sheet, col, startRow, headers[col], tableHeaderStyle);
    }

    int currentRow = startRow + 1;
    int index = 1;

    for (var r in reports) {
      final isEven = index % 2 == 0;
      final rowBg = isEven
          ? ExcelColor.fromHexString('FFF8FAFC')
          : ExcelColor.white;

      final dynamicTextStyle = dataTextStyle.copyWith(
        backgroundColorHexVal: rowBg,
      );
      final dynamicNumStyle = dataNumStyle.copyWith(
        backgroundColorHexVal: rowBg,
      );
      final dynamicCenterStyle = dataCenterStyle.copyWith(
        backgroundColorHexVal: rowBg,
      );

      final free = r.housesInspected - r.housesPositive;
      final abj = r.housesInspected > 0
          ? ((r.housesInspected - r.housesPositive) / r.housesInspected) * 100
          : 100.0;

      final abjStyle = CellStyle(
        backgroundColorHex: rowBg,
        fontSize: 9,
        fontFamily: 'Calibri',
        bold: true,
        fontColorHex: abj >= 95.0
            ? ExcelColor.fromHexString('FF15803D')
            : ExcelColor.fromHexString('FFB91C1C'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: borderThin,
        rightBorder: borderThin,
        topBorder: borderThin,
        bottomBorder: borderThin,
      );

      final statusText = r.status == 'verified'
          ? 'Terverifikasi'
          : (r.status == 'need_intervention'
              ? 'Perlu Intervensi'
              : 'Terkirim');

      _setCell(sheet, 0, currentRow, '$index', dynamicCenterStyle);
      _setCell(
        sheet,
        1,
        currentRow,
        DateFormat('dd/MM/yyyy').format(r.reportDate),
        dynamicCenterStyle,
      );
      _setCell(
        sheet,
        2,
        currentRow,
        DateFormat('HH:mm').format(r.createdAt),
        dynamicCenterStyle,
      );
      _setCell(sheet, 3, currentRow, r.villageName ?? '-', dynamicTextStyle);
      _setCell(sheet, 4, currentRow, r.posyanduName ?? '-', dynamicTextStyle);
      _setCell(sheet, 5, currentRow, '${r.housesInspected}', dynamicNumStyle);
      _setCell(sheet, 6, currentRow, '${r.housesPositive}', dynamicNumStyle);
      _setCell(sheet, 7, currentRow, '$free', dynamicNumStyle);
      _setCell(
        sheet,
        8,
        currentRow,
        '${abj.toStringAsFixed(1)}%',
        abjStyle,
      );
      _setCell(sheet, 9, currentRow, statusText, dynamicCenterStyle);
      _setCell(
        sheet,
        10,
        currentRow,
        r.latestIntervention ?? r.notes ?? '-',
        dynamicTextStyle,
      );

      currentRow++;
      index++;
    }

    // Set Column Widths
    sheet.setColumnWidth(0, 6.0); // NO
    sheet.setColumnWidth(1, 14.0); // TANGGAL
    sheet.setColumnWidth(2, 12.0); // JAM
    sheet.setColumnWidth(3, 18.0); // DESA
    sheet.setColumnWidth(4, 25.0); // POSYANDU
    sheet.setColumnWidth(5, 16.0); // DIPERIKSA
    sheet.setColumnWidth(6, 14.0); // POSITIF
    sheet.setColumnWidth(7, 14.0); // BEBAS
    sheet.setColumnWidth(8, 12.0); // ABJ %
    sheet.setColumnWidth(9, 18.0); // STATUS
    sheet.setColumnWidth(10, 35.0); // CATATAN
  }

  /// Helper untuk set value dan style satu cell
  static void _setCell(
    Sheet sheet,
    int col,
    int row,
    String text,
    CellStyle style,
  ) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = TextCellValue(text);
    cell.cellStyle = style;
  }

  /// Helper untuk set cell merged dengan value & style
  static void _setCellMerged(
    Sheet sheet,
    int startCol,
    int endCol,
    int row,
    String text,
    CellStyle style,
  ) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: endCol, rowIndex: row),
      customValue: TextCellValue(text),
    );
    for (int col = startCol; col <= endCol; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).cellStyle =
          style;
    }
  }

  /// Helper penyimpanan file lintas platform
  static Future<bool> _saveFile(Excel excel, String fileName) async {
    try {
      if (kIsWeb) {
        excel.save(fileName: fileName);
        return true;
      } else {
        final bytes = excel.encode();
        if (bytes == null) return false;

        final path = await FilePicker.saveFile(
          dialogTitle: 'Simpan Laporan Excel Rekap Bulanan PSN',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          bytes: Uint8List.fromList(bytes),
        );

        if (path != null) {
          final file = io.File(path);
          await file.writeAsBytes(bytes);
          return true;
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error saving excel file: $e');
      return false;
    }
  }
}

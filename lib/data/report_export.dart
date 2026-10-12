// สร้างไฟล์ export ของตารางสรุปเคส: CSV (เปิดใน Excel ได้) และ PDF
// ไฟล์นี้แค่ “สร้างเนื้อไฟล์” ส่วนการบันทึก/แชร์ไฟล์อยู่ในหน้าจอ (report_screen.dart)
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'mock_store.dart';
import 'models.dart';

class ReportExport {
  /// หัวคอลัมน์ (ตามแบบที่ตกลงกัน)
  static const headers = [
    'วันที่',
    'รหัสนิสิต',
    'ชื่อ-สกุล',
    'ประเภทเรื่องที่ถาม/ตอบ',
    'ช่องทางที่ถาม/ตอบ',
    'เรื่องที่ถาม/ตอบ',
    'คำตอบที่เจ้าหน้าที่ให้',
    'ระดับ',
  ];

  /// ประเภทปรึกษาแบบสั้น: ทั่วไป / เร่งด่วน
  static String categoryLabel(String categoryId) =>
      MockStore.category(categoryId).urgent ? 'เร่งด่วน' : 'ทั่วไป';

  /// วันที่แบบ วว/ดด/ปปปป(พ.ศ.) ชม:นน เช่น 11/10/2569 10:00
  static String dateText(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year + 543} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  /// ข้อมูล 1 แถวตามลำดับคอลัมน์ [headers]
  static List<String> rowValues(CaseReport r) => [
    dateText(r.date),
    r.studentIdNo,
    r.studentName,
    categoryLabel(r.categoryId),
    r.channel.name,
    r.topic,
    r.advice,
    r.level?.label ?? '',
  ];

  /// CSV แบบ UTF-8 มี BOM (ให้ Excel อ่านภาษาไทยไม่เพี้ยน) และขึ้นบรรทัดแบบ CRLF
  static String buildCsv(List<CaseReport> rows) {
    String cell(String v) {
      final needsQuote = v.contains(',') || v.contains('"') || v.contains('\n');
      final escaped = v.replaceAll('"', '""');
      return needsQuote ? '"$escaped"' : escaped;
    }

    final lines = [
      headers.map(cell).join(','),
      for (final r in rows) rowValues(r).map(cell).join(','),
    ];
    return '﻿${lines.join('\r\n')}\r\n';
  }

  /// จำนวนแถวต่อ 1 หน้า PDF
  static const rowsPerPage = 10;

  /// PDF แนวนอน A4
  ///
  /// ไลบรารี pdf ยังวางสระ/วรรณยุกต์ไทยไม่ได้ (เช่น “ที่” กลายเป็น “ที”)
  /// จึงให้ Flutter วาดตารางแต่ละหน้าเป็นรูป (ภาษาไทยถูกต้องเหมือนในแอป) แล้วใส่ลง PDF
  /// ข้อเสีย: ข้อความใน PDF คัดลอกไม่ได้ (ต้องการข้อมูลแบบข้อความให้ใช้ CSV)
  static Future<List<int>> buildPdf(
    List<CaseReport> rows, {
    required String title,
    required String subtitle,
  }) async {
    final chunks = <List<CaseReport>>[
      for (var i = 0; i < rows.length; i += rowsPerPage)
        rows.sublist(i, (i + rowsPerPage).clamp(0, rows.length)),
    ];
    if (chunks.isEmpty) chunks.add(const []);

    final doc = pw.Document();
    for (var i = 0; i < chunks.length; i++) {
      final png = await renderWidgetToPng(
        _PdfPage(
          title: title,
          subtitle: subtitle,
          rows: chunks[i],
          page: i + 1,
          pages: chunks.length,
        ),
        width: _pageWidth,
      );
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => pw.Align(
            alignment: pw.Alignment.topLeft,
            child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    return doc.save();
  }

  /// ความกว้างของหน้าที่วาด (หน่วย logical pixel ของ Flutter)
  static const _pageWidth = 1120.0;
}

/// วาด widget นอกจอ (ไม่ต้องแสดงบนหน้าจอ) แล้วคืนเป็นรูป PNG
/// [width] = ความกว้าง, ความสูงตามเนื้อหา, [pixelRatio] = ความคมชัด
Future<Uint8List> renderWidgetToPng(
  Widget widget, {
  required double width,
  double pixelRatio = 2,
}) async {
  final boundary = RenderRepaintBoundary();
  final view = ui.PlatformDispatcher.instance.views.first;
  final renderView = RenderView(
    view: view,
    child: RenderPositionedBox(alignment: Alignment.topLeft, child: boundary),
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tightFor(width: width, height: 10000),
      devicePixelRatio: 1,
    ),
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final buildOwner = BuildOwner(focusManager: FocusManager());
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: width, child: widget),
      ),
    ),
  ).attachToRenderTree(buildOwner);
  buildOwner
    ..buildScope(root)
    ..finalizeTree();
  pipeline
    ..flushLayout()
    ..flushCompositingBits()
    ..flushPaint();
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// หน้ากระดาษ 1 หน้าของ PDF (หัวเรื่อง + ตาราง + เลขหน้า) วาดด้วย Flutter
class _PdfPage extends StatelessWidget {
  const _PdfPage({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.page,
    required this.pages,
  });
  final String title;
  final String subtitle;
  final List<CaseReport> rows;
  final int page;
  final int pages;

  static const _font = 'Sarabun';
  static const _ink = Color(0xFF222222);

  @override
  Widget build(BuildContext context) {
    Widget cell(String text, {bool header = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: _font,
          fontSize: header ? 13 : 12.5,
          height: 1.35,
          fontWeight: header ? FontWeight.w700 : FontWeight.w400,
          color: _ink,
        ),
      ),
    );
    return ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 14,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            cell('ไม่มีเคสในช่วงเวลานี้')
          else
            Table(
              border: TableBorder.all(color: _ink, width: 1),
              columnWidths: const {
                0: FixedColumnWidth(110),
                1: FixedColumnWidth(90),
                2: FixedColumnWidth(130),
                3: FixedColumnWidth(72),
                4: FixedColumnWidth(70),
                5: FlexColumnWidth(2),
                6: FlexColumnWidth(2.4),
                7: FixedColumnWidth(52),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFFCE3BE)),
                  children: [
                    for (final h in ReportExport.headers) cell(h, header: true),
                  ],
                ),
                for (final r in rows)
                  TableRow(
                    children: [
                      for (final v in ReportExport.rowValues(r)) cell(v),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'หน้า $page/$pages',
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 11,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

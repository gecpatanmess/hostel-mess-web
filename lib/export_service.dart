import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'main.dart';

class ExportService {
  static Future<void> exportReport({
    required BuildContext context,
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    required String format,
  }) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export not available on web')));
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String safeTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-').replaceAll(' ', '_');
      File? savedFile;

      if (format == 'excel') {
        var excel = Excel.createExcel();
        Sheet sheetObject = excel['Sheet1'];
        
        sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());
        for (var row in data) {
          sheetObject.appendRow(row.map((c) => TextCellValue(c)).toList());
        }
        
        final String filePath = '${directory.path}/$safeTitle.xlsx';
        final List<int>? bytes = excel.encode();
        if (bytes != null) {
           savedFile = File(filePath)..writeAsBytesSync(bytes);
        }
      } else if (format == 'pdf') {
        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return [
                pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  data: data,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellHeight: 25,
                  cellAlignments: { for (var i=0; i<headers.length; i++) i : pw.Alignment.centerLeft },
                )
              ];
            }
          )
        );
        final String filePath = '${directory.path}/$safeTitle.pdf';
        savedFile = File(filePath)..writeAsBytesSync(await pdf.save());
      } 

      if (savedFile != null) {
        await Share.shareXFiles([XFile(savedFile.path)], text: 'Here is the report: $title');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}


import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/dashboard_summary.dart';

// The `pdf` package's built-in fonts don't include the ₹ glyph, so the PDF
// uses "Rs." instead of the on-screen ₹ symbol.
final _pdfCurrencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);
final _pdfDateFormat = DateFormat('dd MMM yyyy');

Future<void> exportFeeSummaryPdf(FeeSummary summary) async {
  final logoBytes = await rootBundle.load('assets/images/bill_title.png');
  final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) {
        if (context.pageNumber > 1) return pw.SizedBox();
        return pw.Column(
          children: [
            pw.Container(
              width: double.infinity,
              alignment: pw.Alignment.topCenter,
              child: pw.Image(logo, height: 60, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Fee Summary in date range: ${_pdfDateFormat.format(summary.start)} - ${_pdfDateFormat.format(summary.end)}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
          ],
        );
      },
      build: (context) => [
        if (summary.rows.isEmpty)
          pw.Text('No payments recorded in this period.')
        else
          pw.TableHelper.fromTextArray(
            headers: const ['S.No', 'Date', 'Student Name', 'Collected', 'Pending'],
            data: [
              for (var i = 0; i < summary.rows.length; i++)
                [
                  '${i + 1}',
                  _pdfDateFormat.format(summary.rows[i].date),
                  summary.rows[i].studentName,
                  _pdfCurrencyFormat.format(summary.rows[i].collected),
                  _pdfCurrencyFormat.format(summary.rows[i].pending),
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
        pw.Divider(height: 24),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('Total Collected: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(_pdfCurrencyFormat.format(summary.collected)),
            pw.SizedBox(width: 24),
            pw.Text('Total Pending: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(_pdfCurrencyFormat.format(summary.pending)),
          ],
        ),
      ],
    ),
  );

  await Printing.sharePdf(bytes: await doc.save(), filename: 'fee_summary.pdf');
}

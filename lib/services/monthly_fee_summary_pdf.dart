import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/dashboard_summary.dart';

// The `pdf` package's built-in fonts don't include the ₹ glyph, so the PDF
// uses "Rs." instead of the on-screen ₹ symbol.
final _pdfCurrencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);

Future<void> exportMonthlyFeeSummaryPdf(List<MonthlyFeeSummary> months) async {
  final doc = pw.Document();
  final totalCollected = months.fold<double>(0, (sum, m) => sum + m.collected);
  final totalPending = months.fold<double>(0, (sum, m) => sum + m.pending);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Monthly Fee Summary', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Generated ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Month', 'Collected', 'Pending'],
            data: [
              for (final m in months)
                [
                  DateFormat('MMM yyyy').format(m.month),
                  _pdfCurrencyFormat.format(m.collected),
                  _pdfCurrencyFormat.format(m.pending),
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          pw.Divider(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Total Collected: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(_pdfCurrencyFormat.format(totalCollected)),
              pw.SizedBox(width: 24),
              pw.Text('Total Pending: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(_pdfCurrencyFormat.format(totalPending)),
            ],
          ),
        ],
      ),
    ),
  );

  await Printing.sharePdf(bytes: await doc.save(), filename: 'monthly_fee_summary.pdf');
}

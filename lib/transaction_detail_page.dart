import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'edit_transaction_page.dart';


class TransactionDetailPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  static Future<pw.Document> buildPdf(Map<String, dynamic> transaction) async {
    final pdf = pw.Document();

    final id = transaction['id'] ?? 'TXN-${DateTime.now().millisecondsSinceEpoch}';
    final isExpense = transaction['recordType'] == 'expense';
    final amount = transaction['amount']?.toDouble() ?? 0.0;
    final formattedDate = transaction['date'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(transaction['date'].toDate())
        : 'No date';

    final docId = transaction['docId'] ?? 'N/A';
    final userName = transaction['userName'] ?? 'John Doe'; // Replace with actual user info if available
    final userEmail = transaction['userEmail'] ?? 'johndoe@example.com'; // Optional
    final verificationCode = id.hashCode.toRadixString(16).padLeft(6, '0').toUpperCase();

    pw.Widget pdfText(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          children: [
            pw.Text("$label ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Expanded(child: pw.Text(value)),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "SpendSimple Transaction Receipt",
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 24),
              pdfText("User:", userName),
              pdfText("Email:", userEmail),
              pw.Divider(),

              pdfText("Transaction ID:", id),
              pdfText("Amount:", "${isExpense ? '-' : '+'} RM${amount.toStringAsFixed(2)}"),
              pdfText("Category:", transaction['category']),
              pdfText("Payment Type:", transaction['paymentType'] ?? "Not specified"),
              pdfText("Note:", transaction['note'] ?? "None"),
              pdfText("Type:", transaction['recordType']),
              pdfText("Date:", formattedDate),
              pdfText("Status:", transaction['status'] ?? "Completed"),

              pw.SizedBox(height: 20),
              pdfText("Verification Code:", verificationCode),
              pw.Divider(),

              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text(
                  "Thank you for using SpendSimple!",
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  "Need help? support@spendsimple.app",
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction['recordType'] == 'expense';
    final amount = transaction['amount']?.toDouble() ?? 0.0;
    final formattedDate = transaction['date'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(transaction['date'].toDate())
        : 'No date';
    final transactionId = transaction['id'] ?? 'TXN-${DateTime.now().millisecondsSinceEpoch}';
    final paymentType = transaction['paymentType'] ?? 'Not specified';
    final status = transaction['status'] ?? 'Completed';

    void generateAndSharePdf(BuildContext context) async {
      print("Generating PDF...");
      final pdf = await buildPdf(transaction);
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'transaction_receipt.pdf');
      print("PDF shared.");
    }

    void printReceipt() async {
      final pdf = await buildPdf(transaction);
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Transaction Details',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5F7FA), Color(0xFFe7ad99)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.9),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditTransactionPage(
                                transaction: transaction,
                                docId: transaction['docId'], // Make sure this is passed
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_note_outlined, color: Colors.black54),
                        tooltip: 'Edit Field',
                      )
                    ],
                  ),
                  Icon(
                    isExpense
                        ? Icons.arrow_circle_down_rounded
                        : Icons.arrow_circle_up_rounded,
                    size: 60,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${isExpense ? '-' : '+'} RM${amount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Chip(
                    label: Text(status),
                    backgroundColor: status == "Completed"
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    labelStyle: TextStyle(
                      color: status == "Completed"
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  const Divider(height: 30, thickness: 1.2),
                  _infoText("Category", transaction['category']),
                  _infoText("Payment Type", paymentType),
                  _infoText("Note", transaction['note'] ?? "None"),
                  _infoText("Type", transaction['recordType']),
                  _infoText("Date", formattedDate),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: transactionId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Transaction ID copied')),
                      );
                    },
                    child: _infoText("Transaction ID", transactionId),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      QrImageView(
                        data: transaction['docId'], // Only the Firestore docId
                        size: 100,
                        backgroundColor: Colors.white,
                      ),
                      // QrImageView(
                      //   data: 'http://192.168.0.135:5000/receipt/${transaction['docId']}',
                      //   size: 100,
                      // ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan to View Receipt',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => generateAndSharePdf(context),
                        icon: const Icon(Icons.download),
                        tooltip: 'Download PDF',
                        style: ElevatedButton.styleFrom(backgroundColor: Color(
                            0xFFDCB8BC)),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: printReceipt,
                        icon: const Icon(Icons.print),
                        tooltip: 'Print Receipt',
                        style: ElevatedButton.styleFrom(backgroundColor: Color(
                            0xFFA2B9C5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(thickness: 1),
                  Text("Thank you for using SpendSimple", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoText(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: color ?? Colors.black, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

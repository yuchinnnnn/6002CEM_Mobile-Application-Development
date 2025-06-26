// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:printing/printing.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
// import 'transaction_detail_page.dart'; // adjust path
//
// class QRScannerPage extends StatefulWidget {
//   const QRScannerPage({super.key});
//
//   @override
//   State<QRScannerPage> createState() => _QRScannerPageState();
// }
//
// class _QRScannerPageState extends State<QRScannerPage> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;
//   bool hasScanned = false;
//
//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }
//
//   void _onQRScanned(BuildContext context, String code) async {
//     if (code.startsWith('receipt:')) {
//       final docId = code.replaceFirst('receipt:', '');
//       final docSnapshot = await FirebaseFirestore.instance
//           .collection('transactions')
//           .doc(docId)
//           .get();
//
//       if (docSnapshot.exists) {
//         final transaction = docSnapshot.data()!;
//         final pdf = await TransactionDetailPage.buildPdf(transaction);
//         await Printing.sharePdf(bytes: await pdf.save(), filename: 'scanned_receipt.pdf');
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//           content: Text('Transaction not found.'),
//         ));
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text('Invalid QR code.'),
//       ));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Scan QR to View Receipt')),
//       body: QRView(
//         key: qrKey,
//         onQRViewCreated: (QRViewController c) {
//           controller = c;
//           c.scannedDataStream.listen(_onQRScanned(context));
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}


class _AddRecordPageState extends State<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();


  String? _selectedCategory;
  String? _selectedType;
  String ?_selectedPaymentType;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, dynamic>> categories = [
    {'name': 'Food & Beverage', 'icon': Icons.fastfood},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Bills', 'icon': Icons.account_balance_rounded},
    {'name': 'Health', 'icon': Icons.health_and_safety},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Others', 'icon': Icons.more_horiz},
  ];

  final List<String> _type = [
    'expense',
    'income'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      final String amount = _amountController.text;
      final String recordType = _selectedType ?? 'Expense';
      final String note = _noteController.text;
      final String category = _selectedCategory ?? 'Others';
      final String paymentType = _selectedPaymentType ?? 'Cash';
      final String uid = FirebaseAuth.instance.currentUser!.uid;

      try {
        await FirebaseFirestore.instance.collection('transactions').add({
          'userId': uid,
          'amount': double.parse(amount),
          'category': category,
          'recordType': recordType,
          'paymentType': paymentType,
          'note': note,
          'date': Timestamp.fromDate(_selectedDate),
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction saved to Firebase!')),
        );

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Record Saved"),
              content: Text("Do you want to add another record or go back to the homepage?"),
              actions: [
                TextButton(
                  child: Text("Add Another"),
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                    _formKey.currentState!.reset();
                    _amountController.clear();
                    _noteController.clear();
                    setState(() {
                      _selectedCategory = null;
                      _selectedDate = DateTime.now();
                    });
                  },
                ),
                TextButton(
                  child: Text("Go Back"),
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                    Navigator.of(context).pop(); // return to homepage
                  },
                ),
              ],
            );
          },
        );


        // Clear form
        _formKey.currentState!.reset();
        _amountController.clear();
        _noteController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedDate = DateTime.now();
        });
      } catch (e) {
        print("Error saving transaction: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transaction.')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Add Record',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Date picker & display
                ListTile(
                  title: Text(
                    "Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
                    style: TextStyle(fontSize: 16),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),

                const SizedBox(height: 20),

                // Amount
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF1E5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Amount", style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          prefixText: 'RM',
                        ),
                      ),
                    ],
                  ),
                ),

                // Category dropdown
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Category",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.arrow_drop_down_circle_rounded),
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['name'],
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: const Color(0xFFFEEBCB), // light yellow-ish background
                                  child: Icon(
                                    category['icon'],
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(category['name']),
                              ],
                            ),
                          );
                        }).toList(),
                        validator: (value) =>
                        value == null ? 'Please select a category' : null,
                      ),
                    ],
                  ),
                ),

                // Record type dropdown
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F6FA), // ✅ You can customize this to other soft tones
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Record Type",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          // prefixIcon: Icon(Icons.wallet),
                          contentPadding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.arrow_drop_down_circle_rounded),
                        items: _type.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type[0].toUpperCase() + type.substring(1), // Capitalize first letter
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedType = val;
                          });
                        },
                        validator: (value) =>
                        value == null ? 'Please select a type' : null,
                      ),
                    ],
                  ),
                ),

                // Payment type radio button
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F0FF), // ✅ You can customize this to other soft tones
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Type',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<String>(
                        title: const Text('Cash'),
                        value: 'Cash',
                        groupValue: _selectedPaymentType,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentType = value;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Card'),
                        value: 'Card',
                        groupValue: _selectedPaymentType,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentType = value;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Online Banking'),
                        value: 'Online Banking',
                        groupValue: _selectedPaymentType,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentType = value;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Other'),
                        value: 'Other',
                        groupValue: _selectedPaymentType,
                        onChanged: (value) {
                          String customMethod = '';

                          AwesomeDialog(
                            context: context,
                            dialogType: DialogType.question,
                            animType: AnimType.rightSlide,
                            customHeader: Icon(Icons.payment, size: 40, color: Color(0xDCB8BCFF)),
                            title: 'Enter Payment Method',
                            body: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Enter Payment Method',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                Text('Please enter your payment method'),
                                SizedBox(height: 10),
                                TextField(
                                  onChanged: (val) {
                                    customMethod = val;
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'e.g., eWallet, Bank Transfer',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                            btnCancelOnPress: () {},
                            btnOkOnPress: () {
                              if (customMethod.isNotEmpty) {
                                setState(() {
                                  _selectedPaymentType = customMethod;
                                });
                              }
                            },
                          ).show();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (e.g.: Taking breakfast at Queensbay Mall',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    prefixIcon: const Icon(
                      Icons.note,
                    ),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _saveRecord,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(400, 50),
                    backgroundColor: Color(0xFFD77988),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Save Record',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

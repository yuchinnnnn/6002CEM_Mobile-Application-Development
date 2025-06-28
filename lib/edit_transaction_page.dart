import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTransactionPage extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final String docId;

  const EditTransactionPage({super.key, required this.transaction, required this.docId});

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  String? _category;
  String? _paymentType;
  String? _recordType;

  final List<String> _categories = [
    'Food & Beverage',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Health',
    'Others',
  ];

  final List<String> _paymentTypes = ['Cash', 'Card', 'eWallet', 'Online Banking'];
  final List<String> _recordTypes = ['Income', 'Expense'];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.transaction['amount'].toString());
    _noteController = TextEditingController(text: widget.transaction['note']);
    _selectedDate = widget.transaction['date'].toDate();
    _category = _categories.contains(widget.transaction['category']) ? widget.transaction['category'] : null;
    _paymentType = _paymentTypes.contains(widget.transaction['paymentType']) ? widget.transaction['paymentType'] : null;
    _recordType = _recordTypes.contains(widget.transaction['recordType']) ? widget.transaction['recordType'] : null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void confirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Changes'),
        content: const Text('Are you sure you want to save the changes?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              _saveChanges();
              Navigator.pop(context);
            }
      )])
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'amount': double.tryParse(_amountController.text),
        'note': _noteController.text,
        'category': _category,
        'paymentType': _paymentType,
        'recordType': _recordType?.toLowerCase(),
        'date': Timestamp.fromDate(_selectedDate),
      };

      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(widget.docId)
          .update(updatedData);

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf2ede9),
      appBar: AppBar(
        title: const Text('Edit Transaction', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField('Amount (RM)', _amountController, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildDropdown('Category', _categories, _category, (val) => setState(() => _category = val)),
              const SizedBox(height: 12),
              _buildDropdown('Payment Type', _paymentTypes, _paymentType, (val) => setState(() => _paymentType = val)),
              const SizedBox(height: 12),
              _buildDropdown('Type', _recordTypes, _recordType, (val) => setState(() => _recordType = val)),
              const SizedBox(height: 12),
              _buildTextField('Note', _noteController, maxLines: 2),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: confirmDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDCB8BC),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (val) => val == null ? 'Please select $label' : null,
    );
  }
}

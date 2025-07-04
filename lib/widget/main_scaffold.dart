import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../home_page.dart';
import '../summary_page.dart';
import '../spending_page.dart';
import '../profile_page.dart';
import '../add_record_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }


  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    SummaryPage(),
    Placeholder(), // Placeholder for FAB
    SpendingPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index != 2) { // Skip FAB index
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  late stt.SpeechToText _speech;

  bool _isListening = false;

  String _voiceText = '';

  String _selectedType = 'expense';// Same default

  final List<String> _categories = [
    'Food & Beverage',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Others',
  ];

  Map<String, String> quickEntryCategoryMap = {};

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              _voiceText = result.recognizedWords;
              _showVoiceConfirmDialog();
            });
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }


  void _showVoiceConfirmDialog() {
    String selectedCategory = 'Others';
    TextEditingController _controller = TextEditingController(text: _voiceText);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirm Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'e.g. RM5 Coffee',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _parseAndSaveQuickExpense(
                  _controller.text,
                  _selectedType,
                  overrideCategory: selectedCategory,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved: ${_controller.text}')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  // Save entry
  void _parseAndSaveQuickExpense(String input, String fallbackType, {String? overrideCategory}) async {
    input = input.toLowerCase();

    // 1. Amount
    final amountReg = RegExp(r'(rm)?\s*(\d+(?:\.\d{1,2})?)');
    final amountMatch = amountReg.firstMatch(input);
    double? amount = amountMatch != null ? double.tryParse(amountMatch.group(2)!) : null;
    if (amount == null) {
      _showError("Could not detect amount.");
      return;
    }

    // 2. Payment method
    final paymentReg = RegExp(r'\b(cash|card|ewallet|bank|transfer)\b');
    final paymentMatch = paymentReg.firstMatch(input);
    String paymentType = paymentMatch?.group(1)?.capitalize() ?? 'Cash';

    // 3. Record Type (expense/income)
    final expenseKeywords = ['spent', 'spend', 'paid', 'bought'];
    final incomeKeywords = ['earned', 'received', 'salary', 'income'];
    String recordType = fallbackType; // e.g. default to 'expense'

    if (expenseKeywords.any((word) => input.contains(word))) {
      recordType = 'expense';
    } else if (incomeKeywords.any((word) => input.contains(word))) {
      recordType = 'income';
    }

    // 4. Date parsing
    DateTime date = DateTime.now();
    if (input.contains('yesterday')) {
      date = DateTime.now().subtract(Duration(days: 1));
    } else if (input.contains('today')) {
      date = DateTime.now();
    } else {
      final dateReg = RegExp(r'\b(?:on\s*)?((?:january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2})\b');
      final dateMatch = dateReg.firstMatch(input);
      if (dateMatch != null) {
        try {
          final parsedDate = DateTime.tryParse('${dateMatch.group(1)} ${DateTime.now().year}');
          if (parsedDate != null) {
            date = parsedDate;
          }
        } catch (_) {}
      }
    }

    // 5. Note cleanup
    final stopWords = [
      'spent', 'spend', 'paid', 'bought', 'earned', 'received',
      'with', 'by', 'on', 'through', 'for', 'add', 'yesterday', 'today',
      'income', 'expense', 'rm', 'of'
    ];

    String cleanedInput = input;

    // Remove the amount phrase safely
    if (amountMatch != null && amountMatch.group(0) != null) {
      cleanedInput = cleanedInput.replaceFirst(amountMatch.group(0)!, '');
    }

    // Remove the payment type if matched
    if (paymentMatch != null && paymentMatch.group(0) != null) {
      cleanedInput = cleanedInput.replaceFirst(paymentMatch.group(0)!, '');
    }

    // Remove stop words from the string
    for (String word in stopWords) {
      cleanedInput = cleanedInput.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
    }

    // Remove leftover punctuation and clean up
    String note = cleanedInput.trim().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(' +'), ' ');
    note = note.isEmpty ? 'General' : note.capitalize();


    // 6. Category (based on note or override)
    String category = overrideCategory ?? quickEntryCategoryMap[note.toLowerCase()] ?? 'Others';

    // Save to Firestore
    await FirebaseFirestore.instance.collection('transactions').add({
      'amount': amount,
      'note': note,
      'category': category,
      'paymentType': paymentType,
      'recordType': recordType,
      'date': date,
      'userId': FirebaseAuth.instance.currentUser!.uid,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved: $recordType RM$amount - $note')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 15,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNavBarItem(CupertinoIcons.house_fill, 'Home', 0),
            buildNavBarItem(CupertinoIcons.chart_bar_square, 'Summary', 1),
            const SizedBox(width: 40), // Leave space for FAB
            buildNavBarItem(CupertinoIcons.money_dollar_circle, 'Spending', 3),
            buildNavBarItem(CupertinoIcons.profile_circled, 'Profile', 4),
          ],
        ),
      ),
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 15),
        child: ClipOval(
          child: Material(
            color: const Color(0xFFDCB8BC),
            elevation: 10,
            child: InkWell(
              onTap: () {},
              child: SizedBox(
                width: 56,
                height: 56,
                child: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _isListening ? _stopListening : _startListening,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget buildNavBarItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;

    return Expanded( // Distributes space evenly and avoids overflow
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(
                  icon,
                  size: isSelected ? 25 : 22, // 🔍 Animated scaling
                  color: isSelected ? const Color(0xFFD77988) : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 13 : 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w800,
                  color: isSelected ? const Color(0xFFD77988) : Colors.black54,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

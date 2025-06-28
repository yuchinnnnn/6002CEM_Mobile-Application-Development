import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // For voice control
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceText = '';

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              _voiceText = result.recognizedWords;
              _showVoiceConfirmDialog(); // Show the dialog for confirmation
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
          title: Text('Confirm Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'e.g. RM5 Coffee',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
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
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _parseAndSaveQuickExpense(
                  _controller.text,
                  _selectedType,
                  overrideCategory: selectedCategory, // 👈 pass override
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved: ${_controller.text}')),
                );
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

// For username display
  String _username = '';
  bool _isLoading = true;

  // For bottom navigation bar
  int _selectedIndex = 0;

  // For quick expense entry field
  final List<String> _categories = [
    'Food & Beverage',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Others',
  ];

  String _selectedType = 'expense'; // default to 'expense'
  final TextEditingController _quickExpenseController = TextEditingController();

  Map<String, String> quickEntryCategoryMap = {};


  Widget quickEntryField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Type:'),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedType,
                items: ['expense', 'income']
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(
                    type[0].toUpperCase() + type.substring(1).toLowerCase(),
                  ),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quickExpenseController,
                  decoration: InputDecoration(
                    hintText: 'e.g. RM12 Nasi Lemak',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  _parseAndSaveQuickExpense(
                    _quickExpenseController.text,
                    _selectedType,
                  );
                  _quickExpenseController.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Add new shortcut
  List<Map<String, String>> _presetEntries = [];
  String? _selectedPresetCategory;

  final TextEditingController _newPresetController = TextEditingController();

  void _showAddPresetDialog() {
    _selectedPresetCategory = _categories.first;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Preset"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newPresetController,
                decoration: const InputDecoration(hintText: "e.g. RM10 Bubble Tea"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedPresetCategory,
                items: _categories
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPresetCategory = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Category"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _newPresetController.clear();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final trimmed = _newPresetController.text.trim();
                if (trimmed.isNotEmpty && _selectedPresetCategory != null) {
                  await _savePresetEntry(trimmed, _selectedPresetCategory!);
                  _newPresetController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Widget presetButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: _presetEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final preset = entry.value;

            return ElevatedButton(
              onPressed: () => _parseAndSaveQuickExpense(
                preset['text']!,
                _selectedType,
                overrideCategory: preset['category'],
              ),
              onLongPress: () => _showDeletePresetDialog(index),
              child: Text('+${preset['text']}'),
            );
          }).toList(),
        ),
        TextButton.icon(
          onPressed: _showAddPresetDialog,
          icon: Icon(Icons.add),
          label: Text("Add Preset Entry"),
        ),
      ],
    );
  }

  Future<void> _deletePresetEntry(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('presets')
        .doc(uid)
        .collection('entries')
        .doc(id)
        .delete();

    _loadPresets(); // Refresh after deletion
  }

  _showDeletePresetDialog(int index) {
    final id = _presetEntries[index]['id']!;
    final text = _presetEntries[index]['text']!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Remove Preset"),
        content: Text("Do you want to remove '$text'?"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text("Remove"),
            onPressed: () async {
              await _deletePresetEntry(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // For pie chart
  double totalSpend = 0.0;
  double totalIncome = 0.0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/summary');
        break;
      case 2:
      // Not used, as index 2 is the FAB
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/spending');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  void _loadPresets() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('presets')
        .doc(uid)
        .collection('entries')
        .get();

    setState(() {
      _presetEntries = snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, String>{
          'id': doc.id,
          'text': data['text'] ?? '',
          'category': data['category'] ?? 'Others',
        };
      }).toList();
    });
  }

  Future<void> _savePresetEntry(String text, String category) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('presets')
        .doc(uid)
        .collection('entries')
        .add({
      'text': text,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _loadPresets(); // Refresh the local list
  }


  void _savePresets() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> encodedList = _presetEntries.map((e) => e.toString()).toList();
    prefs.setStringList('presetEntries', encodedList);
  }

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _loadPresets();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _newPresetController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsername() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
        setState(() {
          _username = userDoc['username'] ?? 'User';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
      setState(() {
        _username = 'User';
        _isLoading = false;
      });
    }
  }

  Stream<QuerySnapshot> _getUserTransactions() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint(uid);
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        // .orderBy('date', descending: true)
        .limit(5) // Show only recent 5
        .snapshots();
  }

  final Map<String, IconData> categoryIcons = {
    'Food & Beverage': Icons.fastfood,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_cart,
    'Bills': Icons.receipt,
    'Health': Icons.health_and_safety,
    'Entertainment': Icons.movie,
    'Others': Icons.category,
  };

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    String uid = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFf2ede9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Header display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 20),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "Hello, \n",
                              style: TextStyle(
                                fontFamily: 'SansSerif',
                                fontSize: 30,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            TextSpan(
                              text: _username,
                              style: const TextStyle(
                                fontFamily: 'SansSerif',
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: IconButton(
                        alignment: Alignment.center,
                          onPressed: (){},
                          icon: Icon(Icons.circle_notifications_rounded, size: 30)
                      ),
                    ),
                  ],
                ),

                // Filter button
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                          child: ElevatedButton(
                            onPressed: (){},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 40,
                              ),
                            ),
                            child:
                            Text("All",
                              style: TextStyle(
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                          child: ElevatedButton(
                            onPressed: (){},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 40,
                              ),
                            ),
                            child:
                            Text("Daily",
                              style: TextStyle(
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                          child: ElevatedButton(
                            onPressed: (){},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 40,
                              ),
                            ),
                            child:
                            Text("Weekly",
                              style: TextStyle(
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                          child: ElevatedButton(
                            onPressed: (){},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 40,
                              ),
                            ),
                            child:
                            Text("Monthly",
                              style: TextStyle(
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                      ]
                  ),
                ),

                // Expense chart
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('transactions')
                              .where('userId', isEqualTo: uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Text("No Data");
                            }

                            double totalIncome = 0.0;
                            double totalSpend = 0.0;

                            for (var doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final amount = double.tryParse(data['amount'].toString()) ?? 0.0;
                              final type = data['recordType'];

                              if (type == 'income') {
                                totalIncome += amount;
                              } else if (type == 'expense') {
                                totalSpend += amount;
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF98aeb6), // match your pie chart income color
                                            shape: BoxShape.circle,   // or BoxShape.rectangle if you prefer
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Income",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ]),
                                      Text(
                                          'RM${totalIncome.toStringAsFixed(2)}',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Color(0xFFD77988), // match your pie chart income color
                                            shape: BoxShape.circle,   // or BoxShape.rectangle if you prefer
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Spend",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ]),
                                      Text(
                                        'RM${totalSpend.toStringAsFixed(2)}',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      )
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 120, top: 20, bottom: 20),
                                    child: SizedBox(
                                      width: 130,
                                      height: 130,
                                      child: PieChart(
                                        PieChartData(
                                          sections: [
                                            PieChartSectionData(
                                              value: (((totalIncome - totalSpend) / totalIncome) * 100),
                                              color: const Color(0xFF98aeb6),
                                              radius: 50,
                                            ),
                                            PieChartSectionData(
                                              value: (totalSpend/totalIncome)*100,
                                              color: const Color(0xFFD77988),
                                              radius: 50,
                                            ),
                                          ],
                                          centerSpaceRadius: 40,
                                          sectionsSpace: 2,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),

                      ],
                    )
                  )
                ),

                SizedBox(height: 20),

                // Add Quick Entry
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("Add Quick Entry", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 280),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add, color: Colors.black, size: 16,),
                            tooltip: 'Add New Transaction Records',
                            onPressed: () {
                              Navigator.pushNamed(context, '/addRecord');
                            },
                          ),
                        )
                      ],
                    ),
                    quickEntryField(),
                    const SizedBox(height: 10),
                    presetButtons(),
                  ],
                ),

                SizedBox(height: 20),

                // Recent transaction list
                Row(
                  children: [
                    Text("Recent Transactions",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 200),
                      child: ElevatedButton(
                          onPressed: (){
                            Navigator.pushNamed(context, '/spending');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                          ),
                          child: Text("See All >")
                      ),
                    )
                  ],
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _getUserTransactions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }

                    if (snapshot.hasError) {
                      print('Error: ${snapshot.error}');
                      return Text("Error loading transactions.");
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print('No data found in transactions collection.');
                      return Text("No recent transactions.");
                    }

                    // Debug print all documents
                    for (var doc in snapshot.data!.docs) {
                      print('Transaction: ${doc.data()}');
                    }

                    return ListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final category = data['category'] ?? 'Others';
                        final icon = categoryIcons[category] ?? Icons.help_outline;
                        final note = data['note'] ?? '';
                        final amount = data['amount']?.toStringAsFixed(2) ?? '0.00';
                        final isExpense = data['recordType'] == 'expense';
                        final formattedAmount = isExpense ? "-RM$amount" : "+RM$amount";
                        final amountColor = isExpense ? Colors.red : Colors.green;

                        return ListTile(
                          leading: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(icon, color: Color(0xDCB8BCFF)),
                            ),
                          ),
                          title: Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(note, style: TextStyle(color: Colors.grey)),
                          trailing: Text(formattedAmount,
                            style: TextStyle(
                              color: amountColor,
                              fontWeight: FontWeight.bold,
                            ),),
                        );
                      }).toList(),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),

      // Bottom navigation bar
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNavBarItem(CupertinoIcons.house_fill, 'Home', 0),
            buildNavBarItem(CupertinoIcons.chart_bar_square, 'Summary', 1),
            const SizedBox(width: 20, height: 15,),
            buildNavBarItem(CupertinoIcons.money_dollar_circle, 'Spending', 3),
            buildNavBarItem(CupertinoIcons.profile_circled, 'Profile', 4),
          ],
        ),
      ),
      floatingActionButton:
      ClipOval(
        child: Material(
          color: const Color(0xFFDCB8BC),
          elevation: 10,
          child: InkWell(
            onTap: (){
              Navigator.pushNamed(context, '/addRecord');
            } ,
            child: SizedBox(
              width: 56,
              height: 56,
              child: IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                onPressed: _isListening ? _stopListening : _startListening,
              )
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
  Widget buildNavBarItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index
                ? const Color(0xFFD77988)
                : Colors.black87,
          ),
          Text(
            label,
            style: TextStyle(
              color: _selectedIndex == index
                  ? const Color(0xFFD77988)
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? '' : this[0].toUpperCase() + substring(1).toLowerCase();
}



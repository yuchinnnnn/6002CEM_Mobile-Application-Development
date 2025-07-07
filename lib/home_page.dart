import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware{

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    getTotalIncome();
    getTotalSpending();
    // Called when user navigates back to HomePage
    setState(() {
      _selectedIndex = 0;
    });
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

    await getTotalSpending();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved: $recordType RM$amount - $note')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
      'userId':uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

  }

  double income = 0.0;
  double spending = 0.0;
  bool showOverspendingWarning = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 1500  ), () {
      setState(() {
        showOverspendingWarning = true;
      });
    });

    _fetchUsername();
    _loadPresets();
    getTotalIncome();
    getTotalSpending();
    sendDailySpendingSummary();
    sendMonthlyReportNotification();
    updateLastActiveTime();
    checkInactiveUser();
    checkInactivityNotification();
    checkUnreadNotifications();
  }

  Future<void> getTotalIncome() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('recordType', isEqualTo: 'income')
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc['amount'] ?? 0).toDouble();
    }

    final prefs = await SharedPreferences.getInstance();
    final incomeNotified = prefs.getString('income_notified_date') ?? '';
    final today = DateTime.now();
    final formattedToday = "${today.year}-${today.month}-${today.day}";

    if (total > 1000 && incomeNotified != formattedToday) {
      await sendNotification(
        'Great Job!',
        'You’ve earned over RM1000 this month.',
      );
      await prefs.setString('income_notified_date', formattedToday);
    }

    setState(() {
      income = total;
    });
  }

  Future<void> getTotalSpending() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('recordType', isEqualTo: 'expense')
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc['amount'] ?? 0).toDouble();
    }

    final prefs = await SharedPreferences.getInstance();
    final spendingNotified = prefs.getString('spending_notified_date') ?? '';
    final today = DateTime.now();
    final formattedToday = "${today.year}-${today.month}-${today.day}";

    if (total > 100 && spendingNotified != formattedToday) {
      await sendNotification(
        'High Spending Alert',
        'You’ve spent over RM100 this month.',
      );
      await prefs.setString('spending_notified_date', formattedToday);
    }

    setState(() {
      spending = total;
    });
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

  final Map<String, IconData> categoryIcons = {
    'Food & Beverage': Icons.fastfood,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_cart,
    'Bills': Icons.receipt,
    'Health': Icons.health_and_safety,
    'Entertainment': Icons.movie,
    'Others': Icons.category,
  };

  // Send notification function passing title and
  Future<void> sendNotification(String title, String body) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'timestamp': Timestamp.now(),
      'read': false,
    });
  }

  // send daily spending summary notification
  Future<void> sendDailySpendingSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentDate = prefs.getString('daily_spending_notified') ?? '';

    final today = DateTime.now();
    final formattedToday = "${today.year}-${today.month}-${today.day}";

    if (lastSentDate == formattedToday) return; // already sent today

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      total += (data['amount'] ?? 0).toDouble();
    }

    if (total > 0) {
      await sendNotification(
        'Daily Spending',
        "You've spent RM${total.toStringAsFixed(2)} today.",
      );
      await prefs.setString('daily_spending_notified', formattedToday);
    }
  }

  Future<void> sendMonthlyReportNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentMonth = prefs.getString('monthly_report_notified') ?? '';

    final now = DateTime.now();
    final currentMonth = "${now.year}-${now.month}";

    if (lastSentMonth == currentMonth) return; // already sent this month

    // Only send on the first day of the month
    if (now.day == 1) {
      await sendNotification(
        'Monthly Report Ready',
        "Your ${DateFormat('MMMM').format(now.subtract(Duration(days: 1)))} report is ready. Review your habits!",
      );
      await prefs.setString('monthly_report_notified', currentMonth);
    }
  }


  // Future<void> sendMonthlyReportNotification() async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   // Simulate this as a new month every time (for testing)
  //   final now = DateTime.now();
  //   final currentMonth = "${now.year}-${now.month}";
  //
  //   // Temporarily skip checking SharedPreferences
  //   await sendNotification(
  //     'Monthly Report Ready',
  //     "Your ${DateFormat('MMMM').format(now)} report is ready. Review your habits!",
  //   );
  //
  //   // Still update SharedPreferences to simulate real behavior
  //   await prefs.setString('monthly_report_notified', currentMonth);
  // }

  void updateLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_active', DateTime.now().toIso8601String());
  }

  Future<void> checkInactiveUser() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveStr = prefs.getString('last_active');
    final lastNotified = prefs.getBool('inactive_user_notified') ?? false;

    if (lastActiveStr == null) return;

    final lastActive = DateTime.parse(lastActiveStr);
    final now = DateTime.now();
    final diff = now.difference(lastActive).inDays;

    if (diff >= 7 && !lastNotified) {
      await sendNotification(
        'We miss you!',
        'You haven’t logged any expenses for over a week. Let’s get back on track!',
      );
      await prefs.setBool('inactive_user_notified', true);
    }

    // Reset if user returns
    if (diff < 7 && lastNotified) {
      await prefs.setBool('inactive_user_notified', false);
    }
  }

  Future<void> checkInactivityNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final lastNotified = prefs.getString('inactive_notified') ?? '';
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";

    if (lastNotified == today) return; // Already notified today

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return;

    final lastTxn = querySnapshot.docs.first.data();
    final lastCreatedAt = (lastTxn['createdAt'] as Timestamp).toDate();
    final daysSinceLastTxn = now.difference(lastCreatedAt).inDays;

    if (daysSinceLastTxn >= 3) {
      await sendNotification(
          'It’s been a while!',
          'You haven’t logged any transactions in the past 3 days. Stay on top of your budget!'
      );
      await prefs.setString('inactive_notified', today);
    }
  }

  // Notification Icon Display
  bool _hasUnreadNotifications = false;

  Future<bool> hasUnreadNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> checkUnreadNotifications() async {
    bool hasUnread = await hasUnreadNotifications();
    setState(() {
      _hasUnreadNotifications = hasUnread;
    });
  }


  bool isOverspending(double income, double spending) {
    return spending > income;
  }

  // void _sendAllTestNotifications() async {
  //   await sendNotification("Test Notification", "This is a general test message.");
  //   await sendNotification("High Spending Alert", "You’ve spent over RM100 this month.");
  //   await sendNotification("Great Job!", "You’ve earned over RM1000 this month.");
  //   await sendNotification("It’s been a while!", "You haven’t logged any transactions in 3 days.");
  //   await sendNotification("We miss you!", "You haven’t logged any expenses for over a week.");
  //   await sendNotification("Monthly Report Ready", "Your monthly report is ready.");
  //   await sendNotification("Daily Spending", "You’ve spent RM50.00 today.");
  //
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text("All test notifications sent!")),
  //   );
  // }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFf2ede9),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting text (Hello and username on two lines)
                _isLoading
                    ? const CircularProgressIndicator()
                    : Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: "Hello,\n",
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
                ),

                // Notification icon with badge
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      tooltip: "Notifications",
                      onPressed: () {
                        setState(() {
                          _hasUnreadNotifications = false;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationPage()),
                        );
                      },
                    ),
                    if (_hasUnreadNotifications)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

        // Filter buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ["All", "Daily", "Weekly", "Monthly"].map((label) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                    child: ElevatedButton(
                      onPressed: () {},
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
                      child: Text(label, style: const TextStyle(color: Colors.grey)),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Expense Summary Chart
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: (income == 0 && spending == 0)
                      ? Center(
                    child: Column(
                      children: const [
                        Icon(Icons.info_outline, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          "No data available",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: Income & Spend display
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (income > 0) ...[
                              Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF98aeb6),
                                      shape: BoxShape.circle,
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
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'RM${income.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (spending > 0) ...[
                              Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD77988),
                                      shape: BoxShape.circle,
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
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'RM${spending.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // RIGHT: Pie Chart + Warning stacked
                      SizedBox(
                        width: 250,
                        child: Column(
                          children: [
                            AnimatedScale(
                              scale: showOverspendingWarning ? 1.0 : 0.8,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeOutBack,
                              child: SizedBox(
                                height: 140,
                                width: 140,
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                        value: income,
                                        color: Color(0xFF98aeb6),
                                        title:
                                        '${((income / (income + spending)) * 100).toStringAsFixed(0)}%',
                                      ),
                                      PieChartSectionData(
                                        value: spending,
                                        color: Color(0xFFD77988),
                                        title:
                                        '${((spending / (income + spending)) * 100).toStringAsFixed(0)}%',
                                      ),
                                    ],
                                    centerSpaceRadius: 30,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            if (isOverspending(income, spending)) ...[
                              AnimatedOpacity(
                                opacity: showOverspendingWarning && isOverspending(income, spending) ? 1.0 : 0.0,
                                duration: Duration(milliseconds: 600),
                                child: AnimatedSlide(
                                  offset: showOverspendingWarning && isOverspending(income, spending) ? Offset(0, 0) : Offset(0, 0.2),
                                  duration: Duration(milliseconds: 600),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              "You're spending more than your income!",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Overspent by RM${(spending - income).toStringAsFixed(2)}",
                                        style: const TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

            // Quick Entry
            Row(
              children: [
                const Text("Add Quick Entry", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Spacer(),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.black, size: 16),
                    tooltip: 'Add New Transaction Records',
                    onPressed: () {
                      Navigator.pushNamed(context, '/addRecord');
                    },
                  ),
                ),
              ],
            ),
            quickEntryField(),
            const SizedBox(height: 10),
            presetButtons(),

            const SizedBox(height: 20),

            // Recent Transactions
            Row(
              children: [
                const Text("Recent Transactions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/spending');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  ),
                  child: const Text("See All >"),
                ),
              ],
            ),
            const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .orderBy('date', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final transactions = snapshot.data?.docs ?? [];
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    // print("Transaction count: ${snapshot.data!.docs.length}");
                    return Text("No recent transactions found."); // Helps confirm it's not UI issue
                  }
                  return Column(
                    children: transactions.map((doc) {
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
              ),
            const SizedBox(height: 80),
            ],
          ),
        ),
    ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? '' : this[0].toUpperCase() + substring(1).toLowerCase();
}



import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  String selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  Map<String, double> categoryTotals = {};
  double totalSpending = 0;

  final List<String> months = List.generate(12, (index) {
    final date = DateTime(DateTime.now().year, index + 1);
    return DateFormat('MMMM yyyy').format(date);
  });

  @override
  void initState() {
    super.initState();
    fetchMonthlyData();
  }

  Future<void> fetchMonthlyData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final DateTime monthDate = DateFormat('MMMM yyyy').parse(selectedMonth);
    final DateTime startOfMonth = DateTime(monthDate.year, monthDate.month);
    final DateTime endOfMonth = DateTime(monthDate.year, monthDate.month + 1);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .where('recordType', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    final data = querySnapshot.docs.map((doc) => doc.data()).toList();

    Map<String, double> tempTotals = {};
    double tempSum = 0;

    for (var transaction in data) {
      final category = transaction['category'] ?? 'Others';
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

      tempTotals[category] = (tempTotals[category] ?? 0) + amount;
      tempSum += amount;
    }

    setState(() {
      categoryTotals = tempTotals;
      totalSpending = tempSum;
    });
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final List<Color> colors = [
      Colors.redAccent, Colors.blueAccent, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.brown, Colors.cyan,
    ];

    final List<PieChartSectionData> sections = [];
    int index = 0;

    categoryTotals.forEach((category, amount) {
      sections.add(
        PieChartSectionData(
          value: amount,
          title: '${(amount / totalSpending * 100).toStringAsFixed(1)}%',
          color: colors[index % colors.length],
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
      index++;
    });

    final topCategories = categoryTotals.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top3 = topCategories.take(3).toList();
    
    return sections;
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf2ede9),
      appBar: AppBar(
        title: const Text('Monthly Summary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Month Selector
            DropdownButton<String>(
              value: selectedMonth,
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  selectedMonth = value!;
                });
                fetchMonthlyData();
              },
              items: months.map((month) {
                return DropdownMenuItem(value: month, child: Text(month));
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Total Spending
            Text(
              'Total Spending: RM${totalSpending.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Pie Chart
            categoryTotals.isEmpty
                ? const Text("No spending data available for this month.")
                : SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),

            // Category Breakdown Legend
            const SizedBox(height: 20),
            ...categoryTotals.entries.map((entry) {
              final color = _buildPieChartSections()[categoryTotals.keys.toList().indexOf(entry.key)].color;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, color: color),
                    const SizedBox(width: 8),
                    Text('${entry.key}: RM${entry.value.toStringAsFixed(2)}'),
                  ],
                ),
              );
            }).toList()
          ],
        ),
      ),
    );
  }
}

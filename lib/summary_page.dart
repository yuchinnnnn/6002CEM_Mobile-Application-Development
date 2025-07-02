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

  List<MapEntry<String, double>> sortedEntries = [];
  Map<String, Color> categoryColors = {};
  final List<Color> barColors = [Colors.blueAccent, Colors.redAccent, Colors.green];

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
      sortedEntries = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    });
  }

  List<BarChartGroupData> _buildBarChartData() {
    categoryColors.clear();

    return List.generate(sortedEntries.length, (index) {
      final entry = sortedEntries[index];

      final color = index < 3
          ? barColors[index % barColors.length]
          : Colors.grey.shade400;

      categoryColors[entry.key] = color;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: color,
            width: 30,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf2ede9),
      appBar: AppBar(
        title: Text('Monthly Summary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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

            Text(
              'Total Spending: RM${totalSpending.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            categoryTotals.isEmpty
                ? const Text("No spending data available for this month.")
                : SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: categoryTotals.values.fold(0.0, (prev, curr) => curr > prev ? curr : prev) * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 || value.toInt() >= sortedEntries.length) {
                            return const SizedBox();
                          }
                          final label = sortedEntries[value.toInt()].key;
                          final isTop3 = value.toInt() < 3;

                          return SideTitleWidget(
                            space: 5,
                            meta: meta,
                            child: Text(
                              isTop3 ? '🏆 $label' : label,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text('RM${value.toInt()}');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarChartData(),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Avg Spending/Day: RM${(totalSpending / DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month)).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),
            ...sortedEntries.map((entry) {
              final color = categoryColors[entry.key] ?? Colors.grey;
              final isTop3 = sortedEntries.indexOf(entry) < 3;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, color: color),
                    const SizedBox(width: 8),
                    Text(
                      '${isTop3 ? '🏆 ' : ''}${entry.key}: RM${entry.value.toStringAsFixed(2)}',
                      style: isTop3
                          ? const TextStyle(fontWeight: FontWeight.bold)
                          : null,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
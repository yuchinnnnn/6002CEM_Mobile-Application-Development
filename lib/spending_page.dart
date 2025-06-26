import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'transaction_detail_page.dart';

class SpendingPage extends StatefulWidget {
  const SpendingPage({super.key});

  @override
  State<SpendingPage> createState() => _SpendingPageState();
}

class _SpendingPageState extends State<SpendingPage> {
  String selectedCategory = 'All';
  String selectedType = 'All';

  final List<String> _categories = [
    'All',
    'Food & Beverage',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Others',
  ];

  final List<String> _recordTypes = ['All', 'Income', 'Expense'];

  final Map<String, IconData> categoryIcons = {
    'Food & Beverage': Icons.fastfood,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_cart,
    'Bills': Icons.receipt,
    'Health': Icons.health_and_safety,
    'Entertainment': Icons.movie,
    'Others': Icons.category,
  };

  Stream<QuerySnapshot> _getUserTransactions() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Filter Section
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: _categories
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedCategory = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                      items: _recordTypes
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedType = value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Transaction List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getUserTransactions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Text("Error loading transactions.");
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text("No transactions found.");
                    }

                    final filteredDocs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final category = data['category'] ?? 'Others';
                      final recordType = data['recordType']?.toString().toLowerCase();

                      final categoryMatch = selectedCategory == 'All' || selectedCategory == category;
                      final typeMatch = selectedType == 'All' || selectedType.toLowerCase() == recordType;

                      return categoryMatch && typeMatch;
                    }).toList();

                    return ListView.separated(
                      itemCount: filteredDocs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final category = data['category'] ?? 'Others';
                        final icon = categoryIcons[category] ?? Icons.help_outline;
                        final note = data['note'] ?? '';
                        final amount = data['amount']?.toDouble() ?? 0.0;
                        final isExpense = data['recordType'] == 'expense';
                        final formattedAmount = isExpense ? "- RM${amount.toStringAsFixed(2)}" : "+ RM${amount.toStringAsFixed(2)}";
                        final amountColor = isExpense ? Colors.red : Colors.green;

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailPage(transaction: data),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE0E7FF),
                                child: Icon(icon, color: Colors.deepPurple),
                              ),
                              title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(note, style: const TextStyle(color: Colors.grey)),
                              trailing: Text(
                                formattedAmount,
                                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );

                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

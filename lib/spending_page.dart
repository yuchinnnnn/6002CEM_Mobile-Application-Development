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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _selectedSort = 'Newest';
  final List<String> _sortOptions = ['Newest', 'Oldest', 'Amount ↑', 'Amount ↓'];

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

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf2ede9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('All Transactions', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search by note or category...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
              // Filter Section
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                      decoration: InputDecoration(labelText: 'Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                      child: Text(_startDate != null
                          ? 'From: ${_startDate!.toLocal().toString().split(' ')[0]}'
                          : 'Start Date'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                      child: Text(_endDate != null
                          ? 'To: ${_endDate!.toLocal().toString().split(' ')[0]}'
                          : 'End Date'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = 'All';
                        selectedType = 'All';
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                    child: const Text("Clear Filters"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedSort,
                decoration: InputDecoration(
                  labelText: 'Sort By',
                  prefixIcon: Icon(Icons.sort, color: Colors.grey.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                items: _sortOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSort = value);
                  }
                },
              ),

              const SizedBox(height: 10),
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

                      final timestamp = data['date'];
                      DateTime? txnDate = timestamp != null ? (timestamp as Timestamp).toDate() : null;

                      final dateMatch = (_startDate == null || (txnDate != null && txnDate.isAfter(_startDate!.subtract(const Duration(days: 1))))) &&
                          (_endDate == null || (txnDate != null && txnDate.isBefore(_endDate!.add(const Duration(days: 1)))));

                      final note = data['note']?.toString().toLowerCase() ?? '';
                      final categoryText = category.toLowerCase();

                      final searchMatch = _searchQuery.isEmpty ||
                          note.contains(_searchQuery) ||
                          categoryText.contains(_searchQuery);

                      return categoryMatch && typeMatch && dateMatch && searchMatch;
                    }).toList();

                    filteredDocs.sort((a, b) {
                      final ascDate = (a['date'] as Timestamp).toDate();
                      final dscDate = (b['date'] as Timestamp).toDate();
                      final aAmt = a['amount']?.toDouble() ?? 0.0;
                      final bAmt = b['amount']?.toDouble() ?? 0.0;

                      switch (_selectedSort) {
                        case 'Newest':
                          return dscDate.compareTo(ascDate);
                        case 'Oldest':
                          return ascDate.compareTo(dscDate);
                        case 'Amount ↑':
                          return aAmt.compareTo(bAmt);
                        case 'Amount ↓':
                          return bAmt.compareTo(aAmt);
                        default:
                          return 0;
                      }
                    });



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

                        return Dismissible(
                          key: ValueKey(doc.id),
                          background: slideRightBackground(),   // Delete background
                          secondaryBackground: slideLeftBackground(), // Edit background
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // Delete
                              final confirm = await showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Transaction'),
                                  content: const Text('Are you sure you want to delete this transaction?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await doc.reference.delete();
                                return true;
                              }
                              return false;
                            } else {
                              // Edit
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionDetailPage(transaction: {
                                    ...data,
                                    'docId': doc.id}
                                  ), // Or to your Edit page
                                ),
                              );
                              return false; // Don't dismiss when editing
                            }
                          },
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionDetailPage(transaction: {
                                    ...data,
                                    'docId': doc.id, }
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 3,
                              color: Color(0xFFF7F6F3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFDCB8BC),
                                    child: Icon(icon, color: Colors.black),
                                  ),
                                  title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(note, style: const TextStyle(color: Colors.grey)),
                                  trailing: Text(
                                    formattedAmount,
                                    style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
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
  Widget slideRightBackground() {
    return Container(
      color: Colors.red.shade300,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget slideLeftBackground() {
    return Container(
      color: Colors.blue.shade200,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.edit, color: Colors.white),
    );
  }
}

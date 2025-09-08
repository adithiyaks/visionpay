import 'package:flutter/material.dart';


class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy data for all transactions
  final List<Map<String, dynamic>> _allTransactions = [
     {
      'title': 'Zomato Order',
      'amount': -480.50,
      'date': '07 Sep 2025',
      'type': 'Food & Drinks',
      'icon': Icons.fastfood_outlined,
    },
    {
      'title': 'Reliance Digital',
      'amount': -1250.75,
      'date': '06 Sep 2025',
      'type': 'Shopping',
      'icon': Icons.shopping_cart_outlined,
    },
    {
      'title': 'Salary Credit',
      'amount': 50000.00,
      'date': '05 Sep 2025',
      'type': 'Salary',
      'icon': Icons.account_balance_wallet_outlined,
    },
     {
      'title': 'Transfer from Friend',
      'amount': 2000.00,
      'date': '03 Sep 2025',
      'type': 'Transfer',
      'icon': Icons.person_outline,
    },
     {
      'title': 'Electricity Bill',
      'amount': -1500.00,
      'date': '02 Sep 2025',
      'type': 'Utilities',
      'icon': Icons.lightbulb_outline,
    },
     {
      'title': 'Netflix Subscription',
      'amount': -649.00,
      'date': '02 Sep 2025',
      'type': 'Entertainment',
      'icon': Icons.movie_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper to group transactions by date
  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
      List<Map<String, dynamic>> transactions) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var tx in transactions) {
      grouped.putIfAbsent(tx['date'], () => []).add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Transactions',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Credit'),
            Tab(text: 'Debit'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList(_allTransactions), // All
                _buildTransactionList(_allTransactions.where((tx) => tx['amount'] > 0).toList()), // Credit
                _buildTransactionList(_allTransactions.where((tx) => tx['amount'] < 0).toList()), // Debit
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }
    
    final groupedTransactions = _groupTransactionsByDate(transactions);
    final dates = groupedTransactions.keys.toList();

    return ListView.builder(
      itemCount: dates.length,
      itemBuilder: (context, index) {
        String date = dates[index];
        List<Map<String, dynamic>> dayTransactions = groupedTransactions[date]!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  date,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              ...dayTransactions.map((tx) => _buildTransactionTile(tx)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    bool isCredit = transaction['amount'] > 0;
    IconData icon = transaction['icon'];
    Color color = isCredit ? Colors.green : Colors.redAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(
          transaction['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(transaction['type']),
        trailing: Text(
          '${isCredit ? '+' : '-'} ₹${transaction['amount'].abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: isCredit ? Colors.green : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

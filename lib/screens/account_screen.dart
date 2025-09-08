import 'package:flutter/material.dart';

class CheckBalanceScreen extends StatefulWidget {
  const CheckBalanceScreen({super.key});

  @override
  State<CheckBalanceScreen> createState() => _CheckBalanceScreenState();
}

class _CheckBalanceScreenState extends State<CheckBalanceScreen> {
  // Dummy data for recent transactions
  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Reliance Digital',
      'amount': -1250.75,
      'date': '06 Sep 2025',
      'icon': Icons.shopping_cart_outlined,
      'color': Colors.redAccent,
    },
    {
      'title': 'Salary Credit',
      'amount': 50000.00,
      'date': '05 Sep 2025',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Colors.green,
    },
    {
      'title': 'Zomato Order',
      'amount': -480.50,
      'date': '04 Sep 2025',
      'icon': Icons.fastfood_outlined,
      'color': Colors.redAccent,
    },
    {
      'title': 'Transfer from Friend',
      'amount': 2000.00,
      'date': '03 Sep 2025',
      'icon': Icons.person_outline,
      'color': Colors.green,
    },
     {
      'title': 'Electricity Bill',
      'amount': -1500.00,
      'date': '02 Sep 2025',
      'icon': Icons.lightbulb_outline,
      'color': Colors.redAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Account Balance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildBalanceCard(),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  /// Widget for the main balance display card
  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '₹ 58,768.75', // Dummy balance
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Account Number',
                    style: TextStyle(color: Colors.white70),
                  ),
                   Text(
                    '**** **** 1234', // Masked account number
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Savings',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
  
  /// Widget for the recent transactions list
  Widget _buildRecentTransactions() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 0),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  bool isCredit = transaction['amount'] > 0;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: transaction['color'].withOpacity(0.1),
                      foregroundColor: transaction['color'],
                      child: Icon(transaction['icon']),
                    ),
                    title: Text(
                      transaction['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(transaction['date']),
                    trailing: Text(
                      '${isCredit ? '+' : '-'} ₹${transaction['amount'].abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isCredit ? Colors.green : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

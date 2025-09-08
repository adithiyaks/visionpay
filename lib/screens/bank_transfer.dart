import 'package:flutter/material.dart';

class BankTransferScreen extends StatefulWidget {
  const BankTransferScreen({super.key});

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  // Dummy data for recent payees
  final List<Map<String, String>> _recentPayees = [
    {'name': 'Dad', 'initials': 'D'},
    {'name': 'Jane Doe', 'initials': 'JD'},
    {'name': 'Landlord', 'initials': 'L'},
    {'name': 'Work', 'initials': 'W'},
  ];

  @override
  void dispose() {
    _accountNumberController.dispose();
    _ifscController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Bank Transfer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecentPayees(),
              const SizedBox(height: 32),
              const Text(
                'Enter Recipient Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _accountNumberController,
                labelText: 'Account Number',
                icon: Icons.account_balance,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _ifscController,
                labelText: 'IFSC Code',
                icon: Icons.code,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _nameController,
                labelText: 'Recipient Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _amountController,
                labelText: 'Amount (₹)',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              _buildProceedButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPayees() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Payees',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recentPayees.length,
            itemBuilder: (context, index) {
              final payee = _recentPayees[index];
              return SingleChildScrollView(
                
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.deepPurple.withValues(alpha: .1),
                      foregroundColor: Colors.deepPurple,
                      child: Text(payee['initials']!,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Text(payee['name']!, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field cannot be empty';
        }
        return null;
      },
    );
  }

  Widget _buildProceedButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Process the transfer
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Processing Transfer...')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 5,
        ),
        child: const Text(
          'Proceed to Pay',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

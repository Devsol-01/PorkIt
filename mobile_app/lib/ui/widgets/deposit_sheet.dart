import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/utils/format_utils.dart';
import 'package:mobile_app/utils/input_formatters.dart';

class DepositSheet extends StatefulWidget {
  final Function(double amount, String fundSource) onDeposit;
  final double currentBalance;
  final bool isLoading;

  const DepositSheet({
    Key? key,
    required this.onDeposit,
    required this.currentBalance,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedFundSource = 'Porket Wallet';
  final List<String> _fundSources = [
    'Porket Wallet',
    'External Wallet',
    'Add Card',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onDeposit() {
    final amount = double.tryParse(
        _amountController.text.replaceAll('\$', '').replaceAll(',', ''));
    if (amount != null && amount > 0) {
      widget.onDeposit(amount, _selectedFundSource);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Deposit to Porket Save',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Current balance
          Text(
            'Current Balance: \$${widget.currentBalance.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Amount input
          Text(
            'Enter Amount',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                NumberInputFormatter(maxDecimalPlaces: 2, allowDecimals: true),
              ],
              decoration: InputDecoration(
                //hintText: '0.00',
                //prefixText: '\$ ',
                prefixStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick amount buttons
          Text(
            'Quick Select',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuickAmountButton('10'),
              const SizedBox(width: 12),
              _buildQuickAmountButton('50'),
              const SizedBox(width: 12),
              _buildQuickAmountButton('100'),
              const SizedBox(width: 12),
              _buildQuickAmountButton('500'),
            ],
          ),
          const SizedBox(height: 24),

          // Fund source selection
          Text(
            'Fund Source',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedFundSource,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              items: _fundSources.map((source) {
                return DropdownMenuItem(
                  value: source,
                  child: Row(
                    children: [
                      Icon(
                        source == 'Porket Wallet'
                            ? Icons.account_balance_wallet
                            : source == 'External Wallet'
                                ? Icons.wallet
                                : Icons.credit_card,
                        size: 20,
                        color: Color(0xFF0000A5),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        source,
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFundSource = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 32),

          // Deposit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _onDeposit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0000A5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Deposit',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(String amount) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final numericAmount = double.tryParse(amount) ?? 0;
          _amountController.text = FormatUtils.formatCurrency(numericAmount);
          _amountController.selection = TextSelection.collapsed(
            offset: FormatUtils.formatCurrency(numericAmount).length,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            '\$$amount',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/utils/format_utils.dart';
import 'package:mobile_app/utils/input_formatters.dart';

class WithdrawSheet extends StatefulWidget {
  final Function(double amount) onWithdraw;
  final double currentBalance;
  final bool isLoading;

  const WithdrawSheet({
    Key? key,
    required this.onWithdraw,
    required this.currentBalance,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onWithdraw() {
    final amount = double.tryParse(
        _amountController.text.replaceAll('\$', '').replaceAll(',', ''));
    if (amount != null && amount > 0 && amount <= widget.currentBalance) {
      widget.onWithdraw(amount);
      Navigator.pop(context);
    }
  }

  void _setMaxAmount() {
    _amountController.text = FormatUtils.formatCurrency(widget.currentBalance);
    _amountController.selection = TextSelection.collapsed(
      offset: FormatUtils.formatCurrency(widget.currentBalance).length,
    );
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
            'Withdraw from Porket Save',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          // Available balance
          Text(
            'Available Balance: \$${widget.currentBalance.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Amount input
          Text(
            'Amount',
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
                hintText: '0.00',
                prefixText: '\$ ',
                prefixStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black,
                ),
                suffixIcon: TextButton(
                  onPressed: _setMaxAmount,
                  child: Text(
                    'MAX',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A90E2),
                    ),
                  ),
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
              _buildQuickAmountButton('25%'),
              const SizedBox(width: 12),
              _buildQuickAmountButton('50%'),
              const SizedBox(width: 12),
              _buildQuickAmountButton('75%'),
              const SizedBox(width: 12),
              _buildQuickAmountButton('100%'),
            ],
          ),
          const SizedBox(height: 24),

          // Warning message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Funds will be transferred to your connected wallet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Withdraw button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _onWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
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
                      'Withdraw',
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

  Widget _buildQuickAmountButton(String percentage) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          double multiplier;
          switch (percentage) {
            case '25%':
              multiplier = 0.25;
              break;
            case '50%':
              multiplier = 0.50;
              break;
            case '75%':
              multiplier = 0.75;
              break;
            case '100%':
              multiplier = 1.0;
              break;
            default:
              multiplier = 0.0;
          }
          final amount = widget.currentBalance * multiplier;
          _amountController.text = FormatUtils.formatCurrency(amount);
          _amountController.selection = TextSelection.collapsed(
            offset: FormatUtils.formatCurrency(amount).length,
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
            percentage,
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

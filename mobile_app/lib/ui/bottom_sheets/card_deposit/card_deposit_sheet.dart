import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:mobile_app/utils/input_formatters.dart';

import 'card_deposit_sheet_model.dart';

class CardDepositSheet extends StackedView<CardDepositSheetModel> {
  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  const CardDepositSheet({
    Key? key,
    required this.completer,
    required this.request,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    CardDepositSheetModel viewModel,
    Widget? child,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Card Deposit',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => completer!(SheetResponse(confirmed: false)),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Input
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
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: viewModel.amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        NumberInputFormatter(maxDecimalPlaces: 2, allowDecimals: true),
                      ],
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                        prefixText: '₦ ',
                        prefixStyle: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Card Number
                  Text(
                    'Card Number',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: viewModel.cardNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CardNumberInputFormatter(),
                      ],
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: '1234 5678 9012 3456',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.credit_card,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Expiry and CVV Row
                  Row(
                    children: [
                      // Expiry Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry Date',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextField(
                                controller: viewModel.expiryController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  ExpiryDateInputFormatter(),
                                ],
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'MM/YY',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.grey[400],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // CVV
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CVV',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextField(
                                controller: viewModel.cvvController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: '123',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.grey[400],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Cardholder Name
                  Text(
                    'Cardholder Name',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: viewModel.cardholderController,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'John Doe',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Deposit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.isBusy
                          ? null
                          : () => viewModel.processCardDeposit(completer!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: viewModel.isBusy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Deposit Funds',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Security Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          size: 16,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your card details are encrypted and secure',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  @override
  CardDepositSheetModel viewModelBuilder(BuildContext context) =>
      CardDepositSheetModel();
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:mobile_app/utils/input_formatters.dart';

import 'ngn_send_sheet_model.dart';

class NgnSendSheet extends StackedView<NgnSendSheetModel> {
  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  const NgnSendSheet({
    Key? key,
    required this.completer,
    required this.request,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    NgnSendSheetModel viewModel,
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
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==== HEADER ====
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bank Details',
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
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==== CONTENT ====
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Bank Name ---
                  _buildLabel('Bank Name'),
                  const SizedBox(height: 8),
                  _buildBankSelector(viewModel),

                  const SizedBox(height: 16),

                  // --- Account Number ---
                  _buildLabel('Account Number'),
                  const SizedBox(height: 8),
                  _buildAccountNumberField(viewModel),

                  // --- Verified Account Name ---
                  if (viewModel.accountName.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildVerificationBanner(viewModel),
                    const SizedBox(height: 8),
                    Text(
                      viewModel.accountName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // --- Amount ---
                  _buildLabel('Amount'),
                  const SizedBox(height: 8),
                  _buildAmountField(viewModel),

                  const SizedBox(height: 32),

                  // --- Continue Button ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.canContinue
                          ? () => viewModel.processSend(completer!)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: viewModel.canContinue
                            ? Colors.black
                            : Colors.grey[300],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==== HELPERS ====

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }

  Widget _buildBankSelector(NgnSendSheetModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            viewModel.selectedBank,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountNumberField(NgnSendSheetModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: viewModel.accountNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Enter account number',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: viewModel.onAccountNumberChanged,
            ),
          ),
          if (viewModel.isVerifying)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            )
          else if (viewModel.accountName.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner(NgnSendSheetModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Account verified with ${viewModel.selectedBank}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.green[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(NgnSendSheetModel viewModel) {
    return Container(
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
    );
  }

  @override
  NgnSendSheetModel viewModelBuilder(BuildContext context) =>
      NgnSendSheetModel();
}

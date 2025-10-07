import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:mobile_app/utils/input_formatters.dart';

import 'crypto_send_sheet_model.dart';

class CryptoSendSheet extends StackedView<CryptoSendSheetModel> {
  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  const CryptoSendSheet({
    Key? key,
    required this.completer,
    required this.request,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    CryptoSendSheetModel viewModel,
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title + subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Crypto',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter or select recipient',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  // Close button
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
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipient header + QR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recipient Address',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.qr_code_scanner,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Address input
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: TextField(
                            controller: viewModel.addressController,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Paste or scan address',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.grey[400],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: viewModel.pasteAddress,
                        child: Text(
                          'Paste',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Amount section
                  Text(
                    'Amount (USDC)',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Amount input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: viewModel.amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        NumberInputFormatter(maxDecimalPlaces: 6, allowDecimals: true),
                      ],
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        suffixText: 'USDC',
                        suffixStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Recent section
                  Text(
                    'Recent',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      'No recent recipient',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.canSend
                          ? () => viewModel.processCryptoSend(completer!)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            viewModel.canSend ? Colors.black : Colors.grey[300],
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
                              'Send USDC',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
  CryptoSendSheetModel viewModelBuilder(BuildContext context) =>
      CryptoSendSheetModel();
}

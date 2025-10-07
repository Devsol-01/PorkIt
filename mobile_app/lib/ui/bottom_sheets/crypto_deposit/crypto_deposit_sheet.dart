import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:mobile_app/app/app.locator.dart';
import 'package:mobile_app/services/wallet_service.dart';

import 'crypto_deposit_sheet_model.dart';

class CryptoDepositSheet extends StackedView<CryptoDepositSheetModel> {
  final Function(SheetResponse response)? completer;
  final SheetRequest request;

  const CryptoDepositSheet({
    Key? key,
    required this.completer,
    required this.request,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    CryptoDepositSheetModel viewModel,
    Widget? child,
  ) {
    final walletService = locator<WalletService>();

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
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Crypto Deposit',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
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
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // QR Code
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FutureBuilder<String?>(
                  future: walletService.getCurrentWalletAddress(),
                  builder: (context, snapshot) {
                    final address = snapshot.data ?? 'Loading...';
                    return QrImageView(
                      data: address,
                      version: QrVersions.auto,
                      size: 150,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // Wallet Address
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'USDC Wallet Address',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    FutureBuilder<String?>(
                      future: walletService.getCurrentWalletAddress(),
                      builder: (context, snapshot) {
                        final walletAddress = snapshot.data ?? 'Loading...';
                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                walletAddress,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () async {
                                if (walletAddress != 'Loading...') {
                                  await Clipboard.setData(
                                    ClipboardData(text: walletAddress),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Wallet address copied!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0077FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.copy,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

// Warning Box
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFE082),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: Color(0xFFFFA000),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Only send USDC to this address. Sending other cryptocurrencies may result in permanent loss.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF8B6914),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )

              // const SizedBox(height: 32),

              // SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  @override
  CryptoDepositSheetModel viewModelBuilder(BuildContext context) =>
      CryptoDepositSheetModel();
}

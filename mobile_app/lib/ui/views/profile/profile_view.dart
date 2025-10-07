import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:mobile_app/app/app.locator.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:mobile_app/services/wallet_service.dart';

import 'profile_viewmodel.dart';

class ProfileView extends StackedView<ProfileViewModel> {
  const ProfileView({super.key});

  @override
  Widget builder(
    BuildContext context,
    ProfileViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              //Main Content
              Expanded(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header
                        _buildProfileHeader(context, viewModel),
                        const SizedBox(height: 32),

                        // Statistics Section
                        _buildStatisticsSection(context, viewModel),
                        const SizedBox(height: 32),

                        // Wallet Address Section
                        _buildWalletAddressSection(context),
                        const SizedBox(height: 24),

                        _buildLanguage(context, viewModel),
                        const SizedBox(height: 16),

                        _buildContactSection(context),
                        const SizedBox(height: 16),

                        // Privacy Section
                        _buildPrivacySection(context),
                        const SizedBox(height: 16),

                        // Log Out Section
                        _buildLogOutSection(context, viewModel),
                      ],
                    )),
              ),
            ],
          ),
        ));
  }

  Widget _buildProfileHeader(BuildContext context, ProfileViewModel viewModel) {
    return Row(
      children: [
        // Profile Avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.5, -1.0),
              end: Alignment(0.5, 1.0),
              colors: [
                Color(0xFF0000A5).withOpacity(0.7),
                Color(0xFF1D84F3).withOpacity(0.7),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              viewModel.getUserInitials(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Profile Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.currentUser?.fullName ?? 'Loading...',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                viewModel.currentUser?.email ?? 'Loading...',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                'PorkCoin Member',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0000A5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(
      BuildContext context, ProfileViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.settings,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600, // Medium
            fontSize: 16,
            height: 17 / 14, // lineHeight ratio
            color: const Color(0xFF0D0D0D), // Secondary Black 100
          ),
        ),
        const SizedBox(height: 16),

        // Statistics Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
                value: '47',
                label: 'Day Streak',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.currency_exchange,
                iconColor: Colors.amber,
                value: '2,847',
                label: 'PorkCoins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.show_chart,
                iconColor: Colors.green,
                value: '\$1,247',
                label: 'Total Returns',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  viewModel.navigateToBadges();
                },
                child: _buildStatCard(
                  context,
                  icon: Icons.emoji_events,
                  iconColor: Colors.purple,
                  value: '4',
                  label: 'Badges',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    bool isWide = false,
  }) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9.59138),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 76, 232, 0.1),
            offset: Offset(-0.834033, 0.834033),
            blurRadius: 4.17017,
            inset: true, // 👈 makes it inset
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 76, 232, 0.1),
            offset: Offset(0.834033, 0.834033),
            blurRadius: 1.25105,
            inset: true, //
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    height: 12 / 9.76561,
                    color: const Color(0xFF0000A5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletAddressSection(BuildContext context) {
    final walletService = locator<WalletService>();

    return Container(
        width: 370,
        height: 87,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, // Secondary color/White 80
          border: Border.all(
            color: const Color(0xFFDADADA), // border #DADADA
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Wallet Address Label
          Text(
            "Wallet Address",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, // Medium
              fontSize: 14,
              height: 17 / 14,
              color: const Color(0xFF0D0D0D), // Black 100
            ),
          ),
          const SizedBox(height: 12), // gap between texts
          // Wallet Address Value
          FutureBuilder<String?>(
            future: walletService.getCurrentWalletAddress(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final address = snapshot.data!;
                final shortAddress =
                    '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
                return Text(
                  "Wallet address: $shortAddress",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 15 / 12, // keeps line height identical to Figma
                    color: const Color(0xFF0000A5),
                  ),
                );
              }
              return Text(
                "Wallet address: Loading...",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 15 / 12,
                  color: const Color(0xFF0000A5),
                ),
              );
            },
          )
        ]));
  }

  Widget _buildLanguage(BuildContext context, ProfileViewModel viewModel) {
    return GestureDetector(
      onTap: () => viewModel.showLanguageSelection(),
      child: Container(
        width: 370,
        height: 64,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDADADA), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left section (icon + text)
            Row(
              children: [
                // Small icon container with inset shadow
                Icon(
                  Icons.language,
                  size: 24,
                  color: Colors.black,
                ),
                const SizedBox(width: 10),
                // Label and current language
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.language,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 17 / 14,
                        color: const Color(0xFF0D0D0D),
                      ),
                    ),
                    Text(
                      viewModel.currentLanguageName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Right caret (arrow)
            const Icon(
              Icons.chevron_right,
              size: 24,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      width: 370,
      height: 64,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDADADA), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left section (icon + text)
          Row(
            children: [
              // Small icon container with inset shadow
              Icon(
                Icons.headset_mic, // substitute for ShieldCheckered
                size: 24,
                color: Colors.black,
              ),
              const SizedBox(width: 10),
              // Label
              Text(
                AppLocalizations.of(context)!.contact,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 17 / 14,
                  color: const Color(0xFF0D0D0D),
                ),
              ),
            ],
          ),
          // Right caret (arrow)
          const Icon(
            Icons.chevron_right,
            size: 24,
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    return Container(
      width: 380,
      height: 64,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDADADA), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left section (icon + text)
          Row(
            children: [
              // Small icon container with inset shadow
              Icon(
                Icons.shield_outlined, // substitute for ShieldCheckered
                size: 24,
                color: Colors.black,
              ),
              const SizedBox(width: 10),
              // Label
              Text(
                AppLocalizations.of(context)!.privacy,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 17 / 14,
                  color: const Color(0xFF0D0D0D),
                ),
              ),
            ],
          ),
          // Right caret (arrow)
          const Icon(
            Icons.chevron_right,
            size: 24,
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildLogOutSection(BuildContext context, ProfileViewModel viewModel) {
    return GestureDetector(
      onTap: () => viewModel.logout(),
      child: Container(
        width: 370,
        height: 64,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDADADA), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left section (icon + text)
            Row(
              children: [
                // Small icon container with inset shadow
                Icon(
                  Icons.logout, // substitute for ShieldCheckered
                  size: 24,
                  color: Colors.red,
                ),
                const SizedBox(width: 10),
                // Label
                Text(
                  AppLocalizations.of(context)!.logout,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 17 / 14,
                      color: Colors.red),
                ),
              ],
            ),
            // Right caret (arrow)
            const Icon(
              Icons.chevron_right,
              size: 24,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  @override
  ProfileViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      ProfileViewModel();
}

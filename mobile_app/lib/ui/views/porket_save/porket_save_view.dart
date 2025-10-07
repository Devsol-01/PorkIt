import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/ui/views/porket_save/porket_save_viewmodel.dart';
import 'package:mobile_app/ui/views/dashboard/dashboard_viewmodel.dart';
import 'package:mobile_app/ui/widgets/deposit_sheet.dart';
import 'package:mobile_app/ui/widgets/withdraw_sheet.dart';
import 'package:stacked/stacked.dart';
import 'package:mobile_app/app/app.locator.dart';
import 'package:mobile_app/utils/format_utils.dart';

class PorketSaveView extends StackedView<PorketSaveViewModel> {
  const PorketSaveView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    PorketSaveViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Porket Savings',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Main Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Color(0xFF0000A5).withOpacity(0.7),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interest Rate
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.2), // subtle transparent white
                      borderRadius: BorderRadius.circular(20), // pill shape
                    ),
                    child: Text(
                      '4.5% per annum',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Balance Label
                  Text(
                    "Porket Savings Balance",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 17 / 14, // lineHeight / fontSize
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Balance Amount
                  Row(
                    children: [
                      Text(
                        viewModel.isBalanceVisible
                            ? FormatUtils.formatCurrency(viewModel.rawBalance)
                            : '****',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: viewModel.toggleBalanceVisibility,
                        child: Icon(
                          viewModel.isBalanceVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // AutoSave Card
            _AutoSaveCard(context, viewModel),

            const SizedBox(height: 24),

            // Action Buttons
            _buildAction(context, viewModel),

            const SizedBox(height: 50),

            // Flexible Savings Section
            //Column(
            //   children: [
            //     Container(
            //       width: 80,
            //       height: 80,
            //       decoration: BoxDecoration(
            //         color: Color(0xFFCADAFC),
            //         borderRadius: BorderRadius.circular(16),
            //       ),
            //       child: Icon(
            //         Icons.savings_outlined,
            //         color: Colors.black,
            //         size: 24,
            //       ),
            //     ),
            //     const SizedBox(height: 16),
            //     Text(
            //       'No ongoing Porket savings',
            //       style: GoogleFonts.inter(
            //         fontWeight: FontWeight.w500, // 500 = medium
            //         fontSize: 15,
            //         height: 17 / 14, // line-height ÷ font-size
            //         color: const Color(0xFF0D0D0D), // #0D0D0D
            //       ),
            //     ),
            //     const SizedBox(height: 8),
            //     Text(
            //       'Create your first Porket savings to get started',
            //       style: TextStyle(
            //         fontSize: 13,
            //         color: Colors.grey[600],
            //       ),
            //       textAlign: TextAlign.center,
            //     ),
            //   ],
            // ),

            // const SizedBox(height: 10),

            // Transaction History Section
            _buildTransactionHistory(viewModel),
          ],
        ),
      ),
    );
  }

    Widget _buildSavingsCard({
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
    required IconData icon,
    required Color decorativeColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Decorative circles in background
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Main content
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 22),
                
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: textColor.withOpacity(0.8),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _AutoSaveCard(BuildContext context, PorketSaveViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(77, 58, 58, 59),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AutoSave is enable',
            style: TextStyle(
              color: Colors.black,
              height: 17 / 14,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your next auto save is schedule to be on 3rd October 2025, by 8:00 am',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Auto Save amount :${FormatUtils.formatCurrency(double.tryParse(viewModel.autoSaveAmount) ?? 0.0)} daily',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Transform.scale(
                scale:
                    0.8, // Adjust the scale to reduce size (0.5 = half size, 1.0 = default)
                child: Switch(
                  value: viewModel.isAutoSaveEnabled,
                  onChanged: (value) => viewModel.toggleAutoSave(value),
                  activeColor:
                      const Color(0xFF0000A5), // thumb color when active
                  activeTrackColor: const Color(0xFF0000A5)
                      .withOpacity(0.5), // track color when active
                  //inactiveThumbColor: Colors.grey, // thumb color when inactive
                  //inactiveTrackColor: Colors.grey.shade400, // track color when inactive
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, PorketSaveViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.arrow_upward,
          label: 'Quick Save',
          onTap: () => _showDepositSheet(context, viewModel),
        ),
        _buildActionButton(
          icon: Icons.savings_outlined,
          label: 'Withdraw',
          onTap: () => _showWithdrawSheet(context, viewModel),
        ),
        _buildActionButton(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
            onTap: onTap,
            child: Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23.434),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(29, 132, 243, 0.1),
                    offset: Offset(-2.03774, 2.03774),
                    blurRadius: 10.1887,
                    inset: true,
                  ),
                  BoxShadow(
                    color: Color.fromRGBO(29, 132, 243, 0.1),
                    offset: Offset(2.03774, 2.03774),
                    blurRadius: 3.0566,
                    inset: true,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Color(0xFF000000),
                size: 24,
              ),
            )),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  void _showDepositSheet(BuildContext context, PorketSaveViewModel viewModel) {
    // Use the same dashboard viewmodel instance that was passed to porket save viewmodel
    final dashboardViewModel = viewModel.dashboardViewModel;

    if (dashboardViewModel == null) {
      print('❌ Dashboard viewmodel is null in deposit sheet');
      return;
    }

    print(
        '💰 Deposit sheet using dashboard balance: \$${dashboardViewModel.usdcBalance}');
    print(
        '💰 Dashboard balance (display): \$${dashboardViewModel.dashboardBalance}');
    print('💰 Dashboard viewmodel instance: ${dashboardViewModel.hashCode}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DepositSheet(
        onDeposit: (amount, fundSource) =>
            viewModel.quickSave(amount, fundSource),
        currentBalance: dashboardViewModel.usdcBalance, // Use real USDC balance
        isLoading: viewModel.isBusy,
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context, PorketSaveViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WithdrawSheet(
        onWithdraw: (amount) => viewModel.withdraw(amount),
        currentBalance: viewModel.rawBalance,
        isLoading: viewModel.isBusy,
      ),
    );
  }

  @override
  PorketSaveViewModel viewModelBuilder(
    BuildContext context,
  ) {
    final dashboardViewModel = locator<DashboardViewModel>();
    final viewModel = PorketSaveViewModel();
    viewModel.initialize(dashboardViewModel);
    return viewModel;
  }

  Widget _buildTransactionHistory(PorketSaveViewModel viewModel) {
    if (viewModel.transactions.isEmpty) {
      return SizedBox.shrink(); // Don't show anything if no transactions
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: viewModel.transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final transaction = viewModel.transactions[index];
            return _buildTransactionCard(transaction);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String? ?? 'deposit';
    final amount = (transaction['amount'] as double? ?? 0.0);
    final date = transaction['date'] as String? ?? '';
    final status = transaction['status'] as String? ?? 'completed';

    final isDeposit = type.toLowerCase().contains('deposit') ||
        type.toLowerCase().contains('save');
    final icon = isDeposit ? Icons.arrow_downward : Icons.arrow_upward;
    final color = isDeposit ? Colors.green : Colors.red;
    final prefix = isDeposit ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$prefix\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dashboard_viewmodel.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:mobile_app/utils/format_utils.dart';
import 'package:mobile_app/app/app.locator.dart';

class DashboardView extends StackedView<DashboardViewModel> {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    DashboardViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                _buildHeader(context, viewModel),
                const SizedBox(height: 24),

                // Balance Card
                _buildBalanceCard(context, viewModel),
                const SizedBox(height: 24),

                // Action Buttons
                _buildAction(context, viewModel),
                const SizedBox(height: 32),

                // Interest Earnings Card - REPLACED SECTION
                _buildInterestEarningsCard(context, viewModel),
                const SizedBox(height: 32),

                // Bottom Buttons
                _buildBottomButtons(context, viewModel),
                const SizedBox(height: 24),

                // Transaction History Section (only shown when Transactions is selected)
                if (!viewModel.isOngoingSelected)
                  _buildTransactionHistory(viewModel),

                const SizedBox(height: 100), // Space for bottom navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DashboardViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard",
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 17 / 14,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
                color: const Color(0xFF0D0D0D),
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Welcome back, ',
                    style: GoogleFonts.inter(
                      fontSize: 11, // font-size: 11px
                      height: 13 / 11, // line-height: 13px → 13 ÷ 11
                      fontWeight: FontWeight.w400, // font-weight: 400
                      fontStyle: FontStyle.normal, // font-style: normal
                      color: const Color(0xFF004CE8), // #004CE8
                    ),
                  ),
                  TextSpan(
                    text: viewModel.getCurrentUserFirstName(),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(
              Icons.qr_code_scanner,
              color: Colors.black,
              size: 24,
            ),
            const SizedBox(width: 12),
            Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                  size: 24,
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, DashboardViewModel viewModel) {
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -1.0),
          end: Alignment(0.5, 1.0),
          colors: [
            Color(0xFF0000A5).withOpacity(0.7),
            Color(0xFF1D84F3).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Wallet address:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  FutureBuilder<String?>(
                    future: viewModel.getCurrentWalletAddress(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final address = snapshot.data!;
                        final shortAddress =
                            '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
                        return Text(
                          shortAddress,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        );
                      }
                      return Text(
                        'Loading...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => viewModel.copyWalletAddressToClipboard(),
                    child: Icon(
                      Icons.copy,
                      size: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: (20)),
            child: Row(
              children: [
                Text(
                  'Total Balance',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white.withOpacity(0.8),
                    size: 25,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                viewModel.isBusy
                    ? SizedBox(
                        width: 120,
                        height: 24,
                        child: Center(
                          child: Text(
                            'Loading...',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: Duration(milliseconds: 10000),
                        child: Text(
                          FormatUtils.formatCurrency(
                              viewModel.dashboardBalance),
                          key: ValueKey(viewModel.dashboardBalance),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                SizedBox(width: 12),
                Icon(
                  Icons.visibility_outlined,
                  color: Colors.white.withOpacity(0.8),
                  size: 24,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, DashboardViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.arrow_upward,
          label: 'Deposit',
          onTap: () {
            viewModel.showDepositSheet();
          },
        ),
        _buildActionButton(
          icon: Icons.savings_outlined,
          label: 'Save',
          onTap: () {},
        ),
        _buildActionButton(
          icon: Icons.send,
          label: 'send',
          onTap: () {
            viewModel.showSendSheet();
          },
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

  Widget _buildInterestEarningsCard(
      BuildContext context, DashboardViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 10,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interest Earnings',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'This Week',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'APY',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Text(
                    '0.56%',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Warning message (if balance is low)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Minimum \$1 USD required to earn interest',
                style: GoogleFonts.inter(
                  color: Colors.orange[700],
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Chart using fl_chart
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                minY: 0,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: GoogleFonts.inter(
                              color: value.toInt() == 5
                                  ? Colors.green
                                  : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: value.toInt() == 6
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green, 'Earned'),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.blue, 'Earning'),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.grey, 'No Funds'),
            ],
          ),

          const SizedBox(height: 16),

          // Total earned
          Text.rich(
            TextSpan(
              text: 'Total Earned: ',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: '\$0.00',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    // Sample data - you can make this dynamic
    List<EarningStatus> weeklyData = [
      EarningStatus.noFunds, // Mon
      EarningStatus.noFunds, // Tue
      EarningStatus.noFunds, // Wed
      EarningStatus.noFunds, // Thu
      EarningStatus.noFunds, // Fri
      EarningStatus.noFunds, // Sat
      EarningStatus.noFunds, // Sun
    ];

    return weeklyData.asMap().entries.map((entry) {
      int index = entry.key;
      EarningStatus status = entry.value;

      Color barColor;
      switch (status) {
        case EarningStatus.earned:
          barColor = Colors.green;
          break;
        case EarningStatus.earning:
          barColor = Colors.blue;
          break;
        case EarningStatus.noFunds:
          barColor = Colors.grey;
          break;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: 1,
            color: barColor,
            width: 16,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(
      BuildContext context, DashboardViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => viewModel.setOngoingSelected(true),
            child: Container(
              width: 171,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: viewModel.isOngoingSelected
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(46),
                  border: viewModel.isOngoingSelected
                      ? null
                      : Border.all(color: Color(0xFF0000A5), width: 1),
                  boxShadow: viewModel.isOngoingSelected
                      ? const [
                          BoxShadow(
                            color: const Color.fromRGBO(29, 132, 243, 0.1),
                            offset: const Offset(-4, 4),
                            blurRadius: 20,
                            spreadRadius: 0,
                            inset: true,
                          ),
                          BoxShadow(
                            color: const Color.fromRGBO(29, 132, 243, 0.1),
                            offset: const Offset(4, 4),
                            blurRadius: 6,
                            spreadRadius: 0,
                            inset: true,
                          ),
                        ]
                      : null),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 24, color: Color(0xFF0000A5)),
                  const SizedBox(width: 5),
                  Text(
                    'Milestone',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0000A5)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => viewModel.setOngoingSelected(false),
            child: Container(
              width: 171,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: !viewModel.isOngoingSelected
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(46),
                  border: !viewModel.isOngoingSelected
                      ? null
                      : Border.all(color: Color(0xFF0000A5), width: 1),
                  boxShadow: !viewModel.isOngoingSelected
                      ? const [
                          BoxShadow(
                            color: const Color.fromRGBO(29, 132, 243, 0.1),
                            offset: const Offset(-4, 4),
                            blurRadius: 20,
                            spreadRadius: 0,
                            inset: true,
                          ),
                          BoxShadow(
                            color: const Color.fromRGBO(29, 132, 243, 0.1),
                            offset: const Offset(4, 4),
                            blurRadius: 6,
                            spreadRadius: 0,
                            inset: true,
                          ),
                        ]
                      : null),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu,
                    color: Color(0xFF0000A5),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Transactions',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0000A5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  DashboardViewModel viewModelBuilder(BuildContext context) {
    return locator<DashboardViewModel>();
  }

  @override
  void onViewModelReady(DashboardViewModel viewModel) {
    print('🎯 Dashboard viewmodel instance: ${viewModel.hashCode}');
    viewModel.initialize();
  }

  Widget _buildTransactionHistory(DashboardViewModel viewModel) {
    if (viewModel.recentTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
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
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
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
          itemCount: viewModel.recentTransactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final transaction = viewModel.recentTransactions[index];
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

  @override
  bool get reactive => true;
}

enum EarningStatus {
  earned,
  earning,
  noFunds,
}

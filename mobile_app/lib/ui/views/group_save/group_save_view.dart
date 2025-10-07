import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'group_save_viewmodel.dart';
import 'package:mobile_app/utils/format_utils.dart';

class GroupSaveView extends StackedView<GroupSaveViewModel> {
  const GroupSaveView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    GroupSaveViewModel viewModel,
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
        title: const Text(
          'Group Savings',
          style: TextStyle(
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
                color: const Color.fromRGBO(9, 129, 9, 0.7),
                borderRadius: BorderRadius.circular(20),
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
                    "Group Savings Balance",
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
                            ? FormatUtils.formatCurrency(
                                viewModel.groupSaveBalance)
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

            const SizedBox(height: 24),

            _buildPromotedSavingsSection(context, viewModel),

            const SizedBox(height: 24),

            // Toggle buttons for Live and Completed
            _buildToggleButtons(context, viewModel),
            const SizedBox(height: 20),
            // Groups List
            viewModel.isBusy
                ? _buildLoadingState()
                : viewModel.currentGroups.isEmpty
                    ? _buildEmptyState()
                    : _buildGroupsList(context, viewModel),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => viewModel.createGroupSave(),
        backgroundColor: const Color(0xFF8A38F5),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildToggleButtons(
      BuildContext context, GroupSaveViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => viewModel.setOngoingSelected(true),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: viewModel.isOngoingSelected
                    ? Colors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(46),
                border: viewModel.isOngoingSelected
                    ? null
                    : Border.all(
                        color: const Color(0xFF8A38F5),
                      ),
                boxShadow: viewModel.isOngoingSelected
                    ? [
                        BoxShadow(
                          color: const Color.fromRGBO(138, 56, 245, 0.1),
                          offset: const Offset(-4, 4),
                          blurRadius: 20,
                        ),
                        BoxShadow(
                          color: const Color.fromRGBO(138, 56, 245, 0.1),
                          offset: const Offset(4, 4),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  'Live (${viewModel.liveGroups.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8A38F5),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => viewModel.setOngoingSelected(false),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: !viewModel.isOngoingSelected
                    ? Colors.white
                    : Colors.transparent,
                border: !viewModel.isOngoingSelected
                    ? null
                    : Border.all(
                        color: const Color(0xFF8A38F5),
                        width: 1,
                      ),
                borderRadius: BorderRadius.circular(46),
                boxShadow: !viewModel.isOngoingSelected
                    ? [
                        BoxShadow(
                          color: const Color.fromRGBO(138, 56, 245, 0.1),
                          offset: const Offset(-4, 4),
                          blurRadius: 20,
                        ),
                        BoxShadow(
                          color: const Color.fromRGBO(138, 56, 245, 0.1),
                          offset: const Offset(4, 4),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  'Completed (${viewModel.completedGroups.length})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Color(0xFF8A38F5),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A38F5)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Color(0xFFE8D7FF),
            borderRadius: BorderRadius.circular(23.434),
          ),
          child: Center(
            child: Icon(
              Icons.group,
              size: 40,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No Group Savings Found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your first group savings to get started',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGroupsList(BuildContext context, GroupSaveViewModel viewModel) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModel.currentGroups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = viewModel.currentGroups[index];
        return _buildGroupCard(context, group, viewModel);
      },
    );
  }

  Widget _buildGroupCard(BuildContext context, Map<String, dynamic> group,
      GroupSaveViewModel viewModel) {
    final title = group['title'] ?? 'Untitled Group';
    final currentAmount = (group['currentAmount'] ?? 0.0) as double;
    final targetAmount = (group['targetAmount'] ?? 0.0) as double;
    final memberCount = group['memberCount'] ?? 0;
    final progressPercentage = (group['progressPercentage'] ?? 0.0) as double;
    final status = group['status'] ?? 'active';
    final isPublic = group['isPublic'] ?? false;
    final category = group['category'] ?? 'General';

    // Status color
    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = const Color(0xFF8A38F5);
        break;
      case 'target_reached':
        statusColor = Colors.green;
        break;
      case 'completed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = const Color(0xFF8A38F5);
    }

    return GestureDetector(
      onTap: () => viewModel.navigateToGroupDetail(group),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isPublic ? Icons.public : Icons.lock,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPublic ? 'Public' : 'Private',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.category,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      FormatUtils.formatCurrency(currentAmount),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8A38F5),
                      ),
                    ),
                    Text(
                      'of ${FormatUtils.formatCurrency(targetAmount)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (progressPercentage / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${progressPercentage.toStringAsFixed(1)}% completed',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$memberCount members',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotedSavingsSection(
      BuildContext context, GroupSaveViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Promoted Savings Groups',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Text(
                    'Find More',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.black,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Image.asset(
                'lib/assets/Group3.png',
                width: 139,
                height: 172,
              ),
              const SizedBox(width: 16),
              Image.asset(
                'lib/assets/Group2.png',
                width: 139,
                height: 172,
              ),
              const SizedBox(width: 16),
              Image.asset(
                'lib/assets/Group1.png',
                width: 139,
                height: 172,
              ),
              const SizedBox(width: 16),
              Image.asset(
                'lib/assets/Group4.png',
                width: 139,
                height: 172,
              ),
              const SizedBox(width: 16),
              Image.asset(
                'lib/assets/Group5.png',
                width: 139,
                height: 172,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  GroupSaveViewModel viewModelBuilder(BuildContext context) =>
      GroupSaveViewModel();

  @override
  void onViewModelReady(GroupSaveViewModel viewModel) {
    viewModel.initialize();
  }
}

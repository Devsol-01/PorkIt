import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/utils/format_utils.dart';
import 'package:stacked/stacked.dart';

import 'group_save_details_viewmodel.dart';

class GroupSaveDetailsView extends StackedView<GroupSaveDetailsViewModel> {
  final Map<String, dynamic> group;
  
  const GroupSaveDetailsView({Key? key, required this.group}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    GroupSaveDetailsViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () => viewModel.navigateBack(),
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${viewModel.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => viewModel.loadGroupSaveDetails(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildGroupHeader(context, viewModel),
                      const SizedBox(height: 16),
                      _buildLeaderboardAndMembers(context, viewModel),
                      const SizedBox(height: 16),
                      _buildActionButtons(context, viewModel),
                      const SizedBox(height: 16),
                      _buildGroupDetails(context, viewModel),
                      const SizedBox(height: 16),
                      _buildQuickLinks(context, viewModel),
                      const SizedBox(height: 16),
                      _buildLatestActivities(context, viewModel),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, GroupSaveDetailsViewModel viewModel) {
    final groupData = viewModel.groupSaveData ?? group;
    final groupName = groupData['name'] as String? ?? 'Group Save';
    final memberCount = groupData['memberCount'] as int? ?? 1;
    final currentAmount = groupData['currentAmount'] as double? ?? 0.0;
    final targetAmount = groupData['targetAmount'] as double? ?? 1000.0;
    final daysLeft = groupData['daysLeft'] as int? ?? 30;
    final progress = targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C851), Color(0xFF00A843)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C851).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  groupName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$memberCount members',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Saved',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FormatUtils.formatCurrency(currentAmount),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$daysLeft days left',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target: ${FormatUtils.formatCurrency(targetAmount)}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardAndMembers(BuildContext context, GroupSaveDetailsViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickLinkCard(
              'Leaderboard',
              Icons.leaderboard,
              const Color(0xFF00C851),
              () => viewModel.navigateToLeaderboard(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickLinkCard(
              'Members',
              Icons.group,
              const Color(0xFF2196F3),
              () => viewModel.navigateToMembers(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, GroupSaveDetailsViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => viewModel.showTopUpDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C851),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Top Up',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => viewModel.showLeaveGroupDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Leave Group',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupDetails(BuildContext context, GroupSaveDetailsViewModel viewModel) {
    final groupData = viewModel.groupSaveData ?? group;
    final frequency = groupData['frequency'] as String? ?? 'Weekly';
    final contributionAmount = groupData['contributionAmount'] as double? ?? 5000.0;
    final startDate = groupData['startDate'] as String? ?? '1st Jan 2024';
    final endDate = groupData['endDate'] as String? ?? '31st Dec 2024';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Details',
            style: GoogleFonts.inter(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Frequency', frequency),
          const SizedBox(height: 12),
          _buildDetailRow('Contribution', FormatUtils.formatCurrency(contributionAmount)),
          const SizedBox(height: 12),
          _buildDetailRow('Start Date', startDate),
          const SizedBox(height: 12),
          _buildDetailRow('End Date', endDate),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinks(BuildContext context, GroupSaveDetailsViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Links',
            style: GoogleFonts.inter(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickLinkCard(
                  'History',
                  Icons.history,
                  const Color(0xFF9C27B0),
                  () => viewModel.navigateToHistory(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickLinkCard(
                  'Invite',
                  Icons.person_add,
                  const Color(0xFFFF9800),
                  () => viewModel.showInviteDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickLinkCard(
                  'Settings',
                  Icons.settings,
                  const Color(0xFF607D8B),
                  () => viewModel.navigateToSettings(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickLinkCard(
                  'Break',
                  Icons.warning,
                  const Color(0xFFF44336),
                  () => viewModel.showBreakGroupDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestActivities(BuildContext context, GroupSaveDetailsViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Activities',
            style: GoogleFonts.inter(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'John Doe contributed ₦5,000',
            '2 hours ago',
            Icons.add_circle,
            const Color(0xFF00C851),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            'Jane Smith joined the group',
            '1 day ago',
            Icons.person_add,
            const Color(0xFF2196F3),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            'Mike Johnson contributed ₦3,000',
            '2 days ago',
            Icons.add_circle,
            const Color(0xFF00C851),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  @override
  GroupSaveDetailsViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      GroupSaveDetailsViewModel();

  @override
  void onViewModelReady(GroupSaveDetailsViewModel viewModel) {
    // Initialize the viewModel with the group ID from the passed group data
    final groupId = group['id'];
    if (groupId != null) {
      if (groupId is BigInt) {
        viewModel.initialize(groupId);
      } else if (groupId is int) {
        viewModel.initialize(BigInt.from(groupId));
      } else if (groupId is String) {
        try {
          viewModel.initialize(BigInt.parse(groupId));
        } catch (e) {
          print('Error parsing group ID: $e');
        }
      }
    }
    super.onViewModelReady(viewModel);
  }
}

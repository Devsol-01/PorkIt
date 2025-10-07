import 'package:flutter/material.dart';
import 'package:mobile_app/app/app.locator.dart';
import 'package:mobile_app/services/contract_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class GroupSaveDetailsViewModel extends BaseViewModel {
  final NavigationService _navigationService = locator<NavigationService>();
  final ContractService _contractService = locator<ContractService>();

  Map<String, dynamic>? _groupSaveData;
  Map<String, dynamic>? get groupSaveData => _groupSaveData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  BigInt? _groupId;

  void initialize(BigInt groupId) {
    _groupId = groupId;
    loadGroupSaveDetails();
  }

  Future<void> loadGroupSaveDetails() async {
    if (_groupId == null) {
      _errorMessage = 'Invalid group ID';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔍 Loading group save details for ID: $_groupId');
      
      final groupData = await _contractService.getGroupSave(groupId: _groupId!);
      _groupSaveData = groupData;
      
      print('✅ Group save details loaded: ${_groupSaveData?['title']}');
      
    } catch (e) {
      print('❌ Error loading group save details: $e');
      _errorMessage = 'Failed to load group save details: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void navigateBack() {
    _navigationService.back();
  }

  void navigateToLeaderboard() {
    // TODO: Navigate to leaderboard page
    print('Navigate to leaderboard');
  }

  void navigateToMembers() {
    // TODO: Navigate to members page
    print('Navigate to members');
  }

  void showTopUpDialog() {
    final context = StackedService.navigatorKey!.currentContext!;
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Up Group Save'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the amount you want to contribute to this group save'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (USDC)',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                Navigator.of(context).pop();
                topUpGroup(amount);
              }
            },
            child: const Text('Contribute'),
          ),
        ],
      ),
    );
  }

  void navigateToHistory() {
    // TODO: Navigate to history page
    print('Navigate to history');
  }

  void showInviteDialog() {
    // TODO: Show invite dialog
    print('Show invite dialog');
  }

  void navigateToSettings() {
    // TODO: Navigate to settings page
    print('Navigate to settings');
  }

  void showBreakGroupDialog() {
    final context = StackedService.navigatorKey!.currentContext!;
    final groupData = _groupSaveData ?? {};
    final currentAmount = groupData['currentAmount'] as double? ?? 0.0;
    final penaltyAmount = currentAmount * 0.03; // 3% penalty
    final refundAmount = currentAmount - penaltyAmount;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Break Group Save'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to break this group save?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Breaking this group will:',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade700),
                  ),
                  SizedBox(height: 8),
                  Text('• End the group save permanently'),
                  Text('• Apply a 3% penalty fee (\$${penaltyAmount.toStringAsFixed(2)})'),
                  Text('• Refund \$${refundAmount.toStringAsFixed(2)} to members'),
                  Text('• This action cannot be undone'),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Only the group creator can break a group save.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              breakGroup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Break Group'),
          ),
        ],
      ),
    );
  }

  void showLeaveGroupDialog() {
    // TODO: Show leave group dialog
    print('Show leave group dialog');
  }

  Future<void> topUpGroup(double amount) async {
    if (_groupId == null) {
      _errorMessage = 'Invalid group ID';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('💰 Contributing $amount USDC to group $_groupId');
      
      final transactionHash = await _contractService.contributeToGroupSave(
        groupId: _groupId!,
        amount: amount,
      );
      
      print('✅ Group contribution successful! Transaction: $transactionHash');
      
      // Show success message
      final context = StackedService.navigatorKey!.currentContext!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully contributed \$${amount.toStringAsFixed(2)} USDC to the group!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Reload group details to reflect new balance
      await loadGroupSaveDetails();
      
    } catch (e) {
      print('❌ Error contributing to group: $e');
      _errorMessage = 'Failed to contribute to group: $e';
      
      // Show error message
      final context = StackedService.navigatorKey!.currentContext!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to contribute: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> breakGroup() async {
    if (_groupId == null) {
      _errorMessage = 'Invalid group ID';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('💥 Breaking group $_groupId');
      
      final transactionHash = await _contractService.breakGroupSave(
        groupId: _groupId!,
      );
      
      print('✅ Group break successful! Transaction: $transactionHash');
      
      // Show success message
      final context = StackedService.navigatorKey!.currentContext!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group save has been broken successfully. Members will be refunded.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      
      // Navigate back after breaking the group
      await Future.delayed(Duration(seconds: 1));
      navigateBack();
      
    } catch (e) {
      print('❌ Error breaking group: $e');
      _errorMessage = 'Failed to break group: $e';
      
      // Show error message
      final context = StackedService.navigatorKey!.currentContext!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to break group: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveGroup() async {
    if (_groupId == null) {
      _errorMessage = 'Invalid group ID';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🚪 Leaving group $_groupId');
      
      // TODO: Implement leave group functionality when contract method is available
      // For now, just simulate the action
      await Future.delayed(Duration(seconds: 1));
      
      print('✅ Successfully left group');
      
      // Navigate back after leaving
      navigateBack();
      
    } catch (e) {
      print('❌ Error leaving group: $e');
      _errorMessage = 'Failed to leave group: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}

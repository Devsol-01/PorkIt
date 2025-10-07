import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:mobile_app/app/app.bottomsheets.dart';
import 'package:mobile_app/app/app.locator.dart';
import 'package:mobile_app/app/app.router.dart';
import 'package:mobile_app/services/contract_service.dart';
import 'package:mobile_app/services/wallet_service.dart';
import 'package:mobile_app/services/firebase_wallet_manager_service.dart';

class GroupSaveViewModel extends BaseViewModel {
  // Services
  final ContractService _contractService = locator<ContractService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final WalletService _walletService = locator<WalletService>();
  final FirebaseWalletManagerService _firebaseWalletManager = locator<FirebaseWalletManagerService>();

  // State properties
  bool _isOngoingSelected = true;
  bool _isBalanceVisible = true;
  double _groupSaveBalance = 0.0;
  List<Map<String, dynamic>> _liveGroups = [];
  List<Map<String, dynamic>> _completedGroups = [];
  List<Map<String, dynamic>> _publicGroups = [];

  // Getters for state properties
  bool get isOngoingSelected => _isOngoingSelected;
  bool get isBalanceVisible => _isBalanceVisible;
  double get groupSaveBalance => _groupSaveBalance;
  List<Map<String, dynamic>> get liveGroups => _liveGroups;
  List<Map<String, dynamic>> get completedGroups => _completedGroups;
  List<Map<String, dynamic>> get publicGroups => _publicGroups;

  // Real data getters - no legacy mock data

  List<dynamic> get currentGroups =>
      _isOngoingSelected ? _liveGroups : _completedGroups;

  GroupSaveViewModel() {
    initialize();
  }

  Future<void> initialize() async {
    await loadGroupSaveBalance();
    await loadUserGroupSaves();
  }

  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }

  // Ensure wallet is available before contract calls
  Future<void> _ensureWalletAvailable() async {
    if (_walletService.currentAccount != null) {
      return; // Wallet already available
    }

    print('⚠️ No wallet in WalletService, checking Firebase...');

    if (_firebaseWalletManager.isAuthenticated) {
      print('✅ User authenticated, initializing Firebase wallet manager...');
      await _firebaseWalletManager.initialize();

      if (_walletService.currentAccount == null) {
        print('❌ Firebase initialization didn\'t load wallet, trying direct load...');
        try {
          await _walletService.loadWallet();
        } catch (e) {
          print('❌ Error in direct wallet load: $e');
        }
      }
    } else {
      print('❌ User not authenticated with Firebase');
    }
  }

  // Load group save balance from contract with improved error handling
  Future<void> loadGroupSaveBalance() async {
    try {
      await _ensureWalletAvailable();

      if (_walletService.currentAccount == null) {
        print('❌ No wallet available for loading group save balance');
        _groupSaveBalance = 0.0;
        return;
      }

      print('💰 Loading group save balance from contract...');
      final balanceBigInt = await _contractService.getUserGroupSaveBalance();
      final balance = balanceBigInt.toDouble() / 1000000; // Convert from USDC units

      print('✅ Group save balance loaded: $balance USDC');
      _groupSaveBalance = balance;
    } catch (e) {
      print('❌ Error loading group save balance: $e');
      _groupSaveBalance = 0.0;
      // Don't throw here, just log and continue
    }
  }

  // Load user group saves from contract using improved method
  Future<void> loadUserGroupSaves() async {
    try {
      // Ensure wallet is available
      await _ensureWalletAvailable();

      if (_walletService.currentAccount == null) {
        print('❌ No wallet available for loading group saves');
        _liveGroups = [];
        _completedGroups = [];
        return;
      }

      print('👥 Loading user group saves from contract...');

      // Use the getUserGroupSaves method
      final groupSaves = await _contractService.getUserGroupSaves();
      print('👥 Raw group saves from contract: ${groupSaves.length} total');

      _liveGroups = [];
      _completedGroups = [];

      // Process each group save with improved error handling
      for (int i = 0; i < groupSaves.length; i++) {
        try {
          final groupSave = groupSaves[i];
          print('🔍 Processing group save $i: $groupSave');

          final mappedGroup = _mapContractGroupToUI(groupSave);

          if (mappedGroup != null) {
            print(
                '✅ Successfully mapped group $i: ${mappedGroup['title']} - ${mappedGroup['currentAmount']} USDC');

            if (mappedGroup['isCompleted'] == true) {
              _completedGroups.add(mappedGroup);
              print('   -> Added to completed groups');
            } else {
              _liveGroups.add(mappedGroup);
              print('   -> Added to live groups');
            }
          } else {
            print('❌ Failed to map group save $i - skipping');
          }
        } catch (e) {
          print('⚠️ Error processing individual group save at index $i: $e');
          // Continue processing other group saves
        }
      }

      print(
          '👥 Final result: ${_liveGroups.length} live groups, ${_completedGroups.length} completed groups');

      // Log sample data for debugging
      if (_liveGroups.isNotEmpty) {
        print('📋 Sample live group: ${_liveGroups.first}');
      }
      if (_completedGroups.isNotEmpty) {
        print('📋 Sample completed group: ${_completedGroups.first}');
      }
    } catch (e) {
      print('❌ Error loading user group saves: $e');
      _liveGroups = [];
      _completedGroups = [];
      // Don't throw here, just log and set empty arrays
    }
  }

  // Helper method to map contract group save data to UI format
  Map<String, dynamic>? _mapContractGroupToUI(
      Map<String, dynamic> contractGroup) {
    try {
      print('🔄 Mapping contract group: $contractGroup');

      final id = contractGroup['id'];
      final title = contractGroup['title'] ?? 'Untitled Group';
      final description = contractGroup['description'] ?? '';
      final category = contractGroup['category'] ?? 'General';
      final targetAmount = (contractGroup['targetAmount'] ?? 0.0) as double;
      final currentAmount = (contractGroup['currentAmount'] ?? 0.0) as double;
      final memberCount = contractGroup['memberCount'] ?? 0;
      final isCompleted = contractGroup['isCompleted'] ?? false;
      final isPublic = contractGroup['isPublic'] ?? false;
      final creator = contractGroup['creator'] ?? '';
      final createdAt = contractGroup['createdAt'];
      final endTime = contractGroup['endTime'];

      print(
          '🔍 Raw values - Target: $targetAmount, Current: $currentAmount, Title: "$title", Completed: $isCompleted');

      // Calculate progress percentage
      final progressPercentage = targetAmount > 0 
          ? (currentAmount / targetAmount * 100).clamp(0.0, 100.0) 
          : 0.0;

      // Calculate amount remaining
      final amountRemaining = (targetAmount - currentAmount).clamp(0.0, double.infinity);

      // Format dates if available
      String? createdDateString;
      String? endDateString;
      
      if (createdAt != null) {
        final createdDate = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
        createdDateString = '${createdDate.day}/${createdDate.month}/${createdDate.year}';
      }
      
      if (endTime != null) {
        final endDate = DateTime.fromMillisecondsSinceEpoch(endTime * 1000);
        endDateString = '${endDate.day}/${endDate.month}/${endDate.year}';
      }

      // Determine status
      String status;
      if (isCompleted) {
        status = 'completed';
      } else if (progressPercentage >= 100.0) {
        status = 'target_reached';
      } else {
        status = 'active';
      }

      final mappedGroup = {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'memberCount': memberCount,
        'isCompleted': isCompleted,
        'isPublic': isPublic,
        'creator': creator,
        'status': status,
        'progressPercentage': progressPercentage,
        'amountRemaining': amountRemaining,
        'createdDate': createdDateString,
        'endDate': endDateString,
      };

      print('✅ Successfully mapped group: $mappedGroup');
      return mappedGroup;
    } catch (e) {
      print('❌ Error mapping contract group to UI: $e');
      return null;
    }
  }

  void setOngoingSelected(bool value) {
    _isOngoingSelected = value;
    notifyListeners(); // Notify UI to rebuild
  }

  void setLiveSelected(bool value) {
    _isOngoingSelected = value;
    notifyListeners();
  }

  void navigateBack() {
    _navigationService.back();
  }

  Future<void> createGroupSave() async {
    print('Create group save button tapped!');

    try {
      // Show our custom group save selection bottom sheet
      print('Showing group save selection bottom sheet...');
      final response = await _bottomSheetService.showCustomSheet(
        variant: BottomSheetType.groupSaveSelection,
        title: 'Create Group Save',
      );
      print('Group save bottom sheet call completed');

      // Handle the response
      if (response?.confirmed == true) {
        final data = response?.data as String?;
        if (data == 'public') {
          print('Navigating to public group save form...');
          await _navigationService.navigateToCreatePublicGroupSaveView();
          // Refresh groups when returning from create group page
          await initialize();
        } else if (data == 'private') {
          print('Navigating to private group save form...');
          await _navigationService.navigateToCreatePrivateGroupSaveView();
          // Refresh groups when returning from create group page
          await initialize();
        }
      }
    } catch (e) {
      print('Error with group save bottom sheet: $e');
      // Fallback to simple dialog
      showDialog(
        context: StackedService.navigatorKey!.currentContext!,
        builder: (context) => AlertDialog(
          title: const Text('Group Save'),
          content:
              const Text('Group save bottom sheet failed, but button works!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void findMoreGroups() {
    // TODO: Implement find more groups logic
    print('Find more groups tapped');
  }


  // Create a new group using contract service



  void navigateToCreateGroup() async {
    await createGroupSave();
    // Refresh groups when returning from create group page
    await initialize();
  }

  // Get group save details
  // Future<Map<String, dynamic>> getGroupSaveDetails(String groupId) async {
  //   try {
  //     final groupIdBigInt = BigInt.parse(groupId);
  //     final groupDetails =
  //         await _contractService.getGroupSave(groupId: groupIdBigInt);
  //     return groupDetails;
  //   } catch (e) {
  //     print('Error getting group save details: $e');
  //     rethrow;
  //   }
  // }

  void navigateToGroupDetail(Map<String, dynamic> group) {
    _navigationService.navigateToGroupSaveDetailsView(group: group);
  }

  @override
  void dispose() {
    // Dispose any controllers or listeners here if any
    super.dispose();
  }
}

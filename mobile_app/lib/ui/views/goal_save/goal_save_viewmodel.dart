import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:mobile_app/services/contract_service.dart';
import 'package:mobile_app/services/wallet_service.dart';
import 'package:mobile_app/app/app.locator.dart';
import 'package:mobile_app/app/app.router.dart';

class GoalSaveViewModel extends BaseViewModel {
  // Services
  final ContractService _contractService = locator<ContractService>();
  final WalletService _walletService = locator<WalletService>();
  final NavigationService _navigationService = locator<NavigationService>();

  // State properties
  bool _isBalanceVisible = true;
  double _goalSaveBalance = 0.0;
  List<Map<String, dynamic>> _liveGoals = [];
  List<Map<String, dynamic>> _completedGoals = [];
  bool _isLiveSelected = true;

  // Getters
  bool get isBalanceVisible => _isBalanceVisible;
  double get goalSaveBalance => _goalSaveBalance;
  List<Map<String, dynamic>> get liveGoals => _liveGoals;
  List<Map<String, dynamic>> get completedGoals => _completedGoals;
  bool get isLiveSelected => _isLiveSelected;

  List<Map<String, dynamic>> get currentGoals =>
      _isLiveSelected ? _liveGoals : _completedGoals;

  GoalSaveViewModel();

  // Navigate to Create Goal page
  void navigateToCreateGoal() async {
    await _navigationService.navigateToCreateGoalView();
    // Refresh goals when returning from create goal page
    await initialize();
  }

  @override
  void dispose() {
    // Dispose any controllers or listeners here if any
    super.dispose();
  }

  // Navigate to Goal Detail page
  void navigateToGoalDetail(Map<String, dynamic> goal) {
    _navigationService.navigateToGoalSaveDetailsView(goal: goal);
  }

  Future<void> initialize() async {
    await loadGoalSaveBalance();
    await loadUserGoals();
  }

  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }

  void setLiveSelected(bool value) {
    _isLiveSelected = value;
    notifyListeners();
  }

  // Load goal save balance from contract
  Future<void> loadGoalSaveBalance() async {
    try {
      // Get the actual user goal save balance from contract
      final balanceBigInt = await _contractService.getUserGoalSaveBalance();
      // Convert from raw USDC units (6 decimals) to readable format
      _goalSaveBalance = balanceBigInt.toDouble() / 1000000.0;
      notifyListeners();
    } catch (e) {
      print('Error loading goal save balance: $e');
      _goalSaveBalance = 0.0;
    }
  }

  // Load user goals from contract
  Future<void> loadUserGoals() async {
    try {
      setBusy(true);
      print('🔍 Loading user goal saves from contract...');
      
      // Get all user goal saves from contract
      final allGoalSaves = await _contractService.getUserGoalSaves();
      
      // Separate live and completed goals
      _liveGoals = allGoalSaves.where((goal) => !goal['isCompleted']).toList();
      _completedGoals = allGoalSaves.where((goal) => goal['isCompleted']).toList();
      
      print('✅ Loaded ${_liveGoals.length} live goals and ${_completedGoals.length} completed goals');
      
      notifyListeners();
    } catch (e) {
      print('❌ Error loading user goal saves: $e');
      // Keep empty lists on error
      _liveGoals = [];
      _completedGoals = [];
    } finally {
      setBusy(false);
    }
  }

  // Helper method to convert contribution type to string
  String _getContributionTypeString(int type) {
    switch (type) {
      case 1:
        return 'Daily';
      case 2:
        return 'Weekly';
      case 3:
        return 'Monthly';
      case 4:
        return 'Manual';
      default:
        return 'Manual';
    }
  }

  // Create a new goal using contract service
  Future<void> createGoal({
    required String purpose,
    required String category,
    required double targetAmount,
    required String frequency,
    required double contributionAmount,
    required DateTime startDate,
    required DateTime endDate,
    required String fundSource,
  }) async {
    setBusy(true);
    try {
      final contributionTypeMap = {
        'Daily': 1,
        'Weekly': 2,
        'Monthly': 3,
        'Manual': 4,
      };

      final contributionType = contributionTypeMap[frequency] ?? 4;

      final txHash = await _contractService.createGoalSave(
        title: purpose,
        category: category,
        targetAmount: targetAmount,
        contributionType: contributionType,
        contributionAmount: contributionAmount,
        startDate: startDate,
        endDate: endDate,
      );

      print('Goal created successfully with TX: $txHash');
      // Refresh data
      await loadGoalSaveBalance();
      // await loadUserGoals();
    } catch (e) {
      print('Error creating goal: $e');
      throw e; // Re-throw to let caller handle
    } finally {
      setBusy(false);
    }
  }

  // Add contribution to goal
  Future<void> addContribution(String goalId, double amount) async {
    setBusy(true);
    try {
      final goalIdBigInt = BigInt.parse(goalId);
      final txHash = await _contractService.contributeGoalSave(
        goalId: goalIdBigInt,
        amount: amount,
      );

      print('Contribution successful: $txHash');
      // Refresh data
      await loadGoalSaveBalance();
      //await loadUserGoals();
    } catch (e) {
      print('Error adding contribution: $e');
      throw e; // Re-throw to let caller handle
    } finally {
      setBusy(false);
    }
  }

  // Claim completed goal
  Future<void> claimCompletedGoal(String goalId) async {
    setBusy(true);
    try {
      // TODO: Implement contract integration
      // await _contractService.contributeGoalSave(goalId: goalId, amount: 0.0);
      await Future.delayed(Duration(milliseconds: 500)); // Mock delay
      print('Goal claimed successfully: $goalId');
      // Refresh data
      await loadGoalSaveBalance();
      //await loadUserGoals();
    } catch (e) {
      print('Error claiming goal: $e');
    } finally {
      setBusy(false);
    }
  }
}

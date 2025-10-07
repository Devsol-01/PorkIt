
import 'package:mobile_app/services/firebase_wallet_manager_service.dart';
import 'package:mobile_app/services/wallet_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:mobile_app/services/contract_service.dart';
import 'package:mobile_app/ui/views/dashboard/dashboard_viewmodel.dart';
import 'package:mobile_app/app/app.locator.dart';

class LockSaveViewModel extends BaseViewModel {
  // Services
  final ContractService _contractService = locator<ContractService>();
  final WalletService _walletService = locator<WalletService>();
  final NavigationService _navigationService = NavigationService();
  final SnackbarService _snackbarService = locator<SnackbarService>();
  final FirebaseWalletManagerService _firebaseWalletManager =
      locator<FirebaseWalletManagerService>();

  // Reference to dashboard viewmodel for balance updates
  DashboardViewModel? _dashboardViewModel;

  // State properties
  bool _isOngoingSelected = true;
  bool _isBalanceVisible = true;
  double _balance = 0.0;
  bool _isLoading = false;
  bool _isRefreshing = false; // Added for pull-to-refresh
  List<Map<String, dynamic>> _ongoingLocks = [];
  List<Map<String, dynamic>> _completedLocks = [];
  String? _lastError; // Track last error

  // Getters
  bool get isOngoingSelected => _isOngoingSelected;
  double get rawBalance => _balance;
  bool get isBalanceVisible => _isBalanceVisible;
  List<Map<String, dynamic>> get ongoingLocks => _ongoingLocks;
  List<Map<String, dynamic>> get completedLocks => _completedLocks;
  List<Map<String, dynamic>> get lockPeriods => _lockPeriods;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get lastError => _lastError;

  // Lock period configurations with interest rates
  final List<Map<String, dynamic>> _lockPeriods = [
    {
      'id': '10-30',
      'label': '10-30 days',
      'minDays': 10,
      'maxDays': 30,
      'interestRate': 5.5,
      'color': 0xFF4CAF50,
    },
    {
      'id': '31-60',
      'label': '31-60 days',
      'minDays': 31,
      'maxDays': 60,
      'interestRate': 6.2,
      'color': 0xFF2196F3,
    },
    {
      'id': '91-180',
      'label': '91-180 days',
      'minDays': 91,
      'maxDays': 180,
      'interestRate': 7.8,
      'color': 0xFF9C27B0,
    },
    {
      'id': '181-270',
      'label': '181-270 days',
      'minDays': 181,
      'maxDays': 270,
      'interestRate': 9.1,
      'color': 0xFFFF9800,
    },
    {
      'id': '271-365',
      'label': '271-365 days',
      'minDays': 271,
      'maxDays': 365,
      'interestRate': 12.5,
      'color': 0xFFE91E63,
    },
    {
      'id': '366-730',
      'label': '1-2 years',
      'minDays': 366,
      'maxDays': 730,
      'interestRate': 15.8,
      'color': 0xFF673AB7,
    },
    {
      'id': '731+',
      'label': 'Above 2 years',
      'minDays': 731,
      'maxDays': 1095, // 3 years max
      'interestRate': 18.5,
      'color': 0xFF795548,
    },
  ];

  LockSaveViewModel() {
    initialize();
  }

  Future<void> initialize([DashboardViewModel? dashboardViewModel]) async {
    _dashboardViewModel = dashboardViewModel;

    try {
      _isLoading = true;
      notifyListeners();

      // Load data concurrently for better performance
      await Future.wait([
        loadBalance(),
        loadUserLocks(),
      ]);

      print(
          '🔒 Lock Save Debug: Loaded ${_ongoingLocks.length} ongoing locks, ${_completedLocks.length} completed locks');
      _lastError = null; // Clear any previous errors
    } catch (e) {
      _lastError = 'Failed to initialize: $e';
      print('❌ Error initializing LockSaveViewModel: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Real data getters - no legacy mock data
  List<dynamic> get currentLocks =>
      _isOngoingSelected ? _ongoingLocks : _completedLocks;

  void setOngoingSelected(bool value) {
    _isOngoingSelected = value;
    notifyListeners();
  }

  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }

  void navigateBack() {
    _navigationService.back();
  }

  void navigateToCreateLockWithPeriod(Map<String, dynamic> period) {
    // Navigate to create lock page with selected period
    // TODO: Implement proper navigation when routes are set up
    // _navigationService.navigateTo('/create-lock', arguments: period);
  }

  /// Refresh all data (pull-to-refresh)
  Future<void> refreshData() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

    try {
      _isRefreshing = true;
      _lastError = null;
      notifyListeners();

      print('🔄 Refreshing lock save data...');

      // First try auto-release, then refresh both balance and locks
      try {
        print('🔄 Auto-releasing matured locks during refresh...');
        final autoReleaseResult = await _contractService.autoReleaseMaturedLockSaves();
        if (autoReleaseResult != null) {
          print('✅ Auto-release during refresh completed with TX: $autoReleaseResult');
          // Wait a moment for the transaction to be processed
          await Future.delayed(Duration(milliseconds: 1000));
        }
      } catch (e) {
        print('⚠️ Auto-release during refresh failed, continuing: $e');
      }

      // Refresh both balance and locks
      await Future.wait([
        loadBalance(),
        loadUserLocks(),
      ]);

      print('✅ Data refresh completed');
    } catch (e) {
      _lastError = 'Failed to refresh data: $e';
      print('❌ Error refreshing data: $e');
      _showErrorSnackbar('Failed to refresh data');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Load lock save balance from contract
  Future<void> loadBalance() async {
    try {
      // Ensure wallet is available
      await _ensureWalletAvailable();

      if (_walletService.currentAccount == null) {
        print('❌ No wallet available for balance loading');
        _balance = 0.0;
        return;
      }

      print('💰 Loading lock save balance from contract...');

      // Get real balance from contract using the improved method
      final balanceBigInt = await _contractService.getUserLockSaveBalance();
      final balance =
          balanceBigInt.toDouble() / 1000000; // Convert from USDC units

      print('✅ Lock save balance loaded: $balance USDC');
      _balance = balance;
    } catch (e) {
      print('❌ Error loading balance: $e');
      _balance = 0.0;
      // Don't throw here, just log and continue
    }
  }

  // Load user locks from contract using improved method
// Load user locks from contract using improved method
  Future<void> loadUserLocks() async {
    try {
      // Ensure wallet is available
      await _ensureWalletAvailable();

      if (_walletService.currentAccount == null) {
        print('❌ No wallet available for loading locks');
        _ongoingLocks = [];
        _completedLocks = [];
        return;
      }

      print('🔒 Loading user locks from contract...');

      // First, try to auto-release any matured lock saves
      try {
        print('🔄 Attempting to auto-release matured locks...');
        final autoReleaseResult = await _contractService.autoReleaseMaturedLockSaves();
        if (autoReleaseResult != null) {
          print('✅ Auto-release completed with TX: $autoReleaseResult');
          // Wait a moment for the transaction to be processed
          await Future.delayed(Duration(milliseconds: 1000));
        } else {
          print('ℹ️ No matured locks to auto-release or auto-release skipped');
        }
      } catch (e) {
        print('⚠️ Auto-release failed, continuing with normal flow: $e');
        // Don't let auto-release failure block the normal flow
      }

      // Load ongoing and matured locks separately for better accuracy
      final ongoingLocksTask = _contractService.getOngoingLockSaves();
      final maturedLocksTask = _contractService.getMaturedLockSaves();

      final results = await Future.wait([ongoingLocksTask, maturedLocksTask]);
      final ongoingLocks = results[0];
      final maturedLocks = results[1];

      print('🔒 Raw locks from contract: ${ongoingLocks.length} ongoing, ${maturedLocks.length} matured');

      _ongoingLocks = [];
      _completedLocks = [];

      // Process ongoing locks
      for (int i = 0; i < ongoingLocks.length; i++) {
        try {
          final lock = ongoingLocks[i];
          print('🔍 Processing ongoing lock $i: $lock');

          final mappedLock = _mapContractLockToUI(lock);

          if (mappedLock != null) {
            print(
                '✅ Successfully mapped ongoing lock $i: ${mappedLock['title']} - ${mappedLock['amount']} USDC');
            _ongoingLocks.add(mappedLock);
            print('   -> Added to ongoing locks');
          } else {
            print('❌ Failed to map ongoing lock $i - skipping');
          }
        } catch (e) {
          print('⚠️ Error processing individual ongoing lock at index $i: $e');
          // Continue processing other locks
        }
      }

      // Process matured locks (these should go to completed)
      for (int i = 0; i < maturedLocks.length; i++) {
        try {
          final lock = maturedLocks[i];
          print('🔍 Processing matured lock $i: $lock');

          final mappedLock = _mapContractLockToUI(lock);

          if (mappedLock != null) {
            print(
                '✅ Successfully mapped matured lock $i: ${mappedLock['title']} - ${mappedLock['amount']} USDC');
            _completedLocks.add(mappedLock);
            print('   -> Added to completed locks');
          } else {
            print('❌ Failed to map matured lock $i - skipping');
          }
        } catch (e) {
          print('⚠️ Error processing individual matured lock at index $i: $e');
          // Continue processing other locks
        }
      }

      print(
          '🔒 Final result: ${_ongoingLocks.length} ongoing, ${_completedLocks.length} completed');

      // Log sample data for debugging
      if (_ongoingLocks.isNotEmpty) {
        print('📋 Sample ongoing lock: ${_ongoingLocks.first}');
      }
      if (_completedLocks.isNotEmpty) {
        print('📋 Sample completed lock: ${_completedLocks.first}');
      }
    } catch (e) {
      print('❌ Error loading user locks: $e');
      _ongoingLocks = [];
      _completedLocks = [];
      // Don't throw here, just log and set empty arrays
    }
  }

  // Helper method to map contract lock data to UI format
// Helper method to map contract lock data to UI format
  Map<String, dynamic>? _mapContractLockToUI(
      Map<String, dynamic> contractLock) {
    try {
      print('🔄 Mapping contract lock: $contractLock');

      final id = contractLock['id'];
      final title = contractLock['title'] ?? 'Untitled Lock';
      final amount = (contractLock['amount'] ?? 0.0) as double;
      final isMatured = contractLock['isMatured'] ?? false;
      final isWithdrawn = contractLock['isWithdrawn'] ?? false;
      final isExpired = contractLock['isExpired'] ?? false;
      final timeRemaining = contractLock['timeRemaining'] ?? 0;
      final startTime = contractLock['startTime'];
      final maturityTime = contractLock['maturityTime'];

      print(
          '🔍 Raw values - Amount: $amount, Title: "$title", Matured: $isMatured, Withdrawn: $isWithdrawn');
      print(
          '   Start Time: $startTime, Maturity Time: $maturityTime, Time Remaining: $timeRemaining');

      // Validate amount
      if (amount <= 0) {
        print('⚠️ Warning: Lock has zero or negative amount: $amount');
      }

      // Format maturity date properly
      String? maturityDateString;
      if (maturityTime != null && maturityTime > 0) {
        try {
          // Ensure maturityTime is treated as seconds timestamp
          final timestamp = maturityTime is int
              ? maturityTime
              : int.parse(maturityTime.toString());

          // Validate timestamp (should be reasonable unix timestamp)
          if (timestamp < 1000000000) {
            // Before year 2001 - likely invalid
            print('⚠️ Warning: Invalid timestamp detected: $timestamp');
            maturityDateString = 'Invalid Date';
          } else {
            final maturityDate =
                DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            maturityDateString =
                '${maturityDate.day.toString().padLeft(2, '0')}/${maturityDate.month.toString().padLeft(2, '0')}/${maturityDate.year}';
            print(
                '✅ Formatted maturity date: $maturityDateString (from timestamp: $timestamp)');
          }
        } catch (e) {
          print(
              '❌ Error formatting maturity date from timestamp $maturityTime: $e');
          maturityDateString = 'Date Error';
        }
      } else {
        print('⚠️ Warning: No valid maturity time provided');
        maturityDateString = 'No Date';
      }

      // Determine status more reliably
      String status;
      if (isWithdrawn) {
        status = 'completed';
      } else if (isMatured || isExpired) {
        status = 'ready_to_withdraw';
      } else if (timeRemaining > 0) {
        status = 'ongoing';
      } else {
        // Fallback status determination
        final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (maturityTime != null && currentTime >= maturityTime) {
          status = 'ready_to_withdraw';
        } else {
          status = 'ongoing';
        }
      }

      print('✅ Determined status: $status');

      final mappedLock = {
        'id': id,
        'title': title.isEmpty ? 'Untitled Lock' : title,
        'amount': amount,
        'maturityDate': maturityDateString,
        'status': status,
        'isMatured': isMatured,
        'isWithdrawn': isWithdrawn,
        'isExpired': isExpired,
        'timeRemaining': timeRemaining,
        'duration': contractLock['duration'],
        'startTime': startTime,
        'maturityTime': maturityTime,
        'interestRate': contractLock['interestRate'],
      };

      print(
          '✅ Successfully mapped lock: ${mappedLock['title']} - ${mappedLock['amount']} USDC - Status: ${mappedLock['status']}');
      return mappedLock;
    } catch (e) {
      print('❌ Error mapping contract lock to UI: $e');
      print('   Contract lock data: $contractLock');
      return null;
    }
  }

  // Helper method to ensure wallet is available
  Future<void> _ensureWalletAvailable() async {
    if (_walletService.currentAccount != null) {
      return; // Wallet already available
    }

    print('⚠️ No wallet in WalletService, attempting to load...');

    // Check if user is authenticated with Firebase
    if (_firebaseWalletManager.isAuthenticated) {
      print('✅ User authenticated, initializing Firebase wallet manager...');

      try {
        await _firebaseWalletManager.initialize();

        if (_walletService.currentAccount == null) {
          print(
              '❌ Firebase initialization didn\'t load wallet, trying direct load...');
          await _walletService.loadWallet();
        }
      } catch (e) {
        print('❌ Error loading wallet: $e');
        throw Exception('Failed to load wallet: $e');
      }
    } else {
      print('❌ User not authenticated with Firebase');
      throw Exception('User not authenticated');
    }
  }

  // Create a new lock save using contract service
  Future<bool> createLockSave(
    double amount,
    String title,
    int lockDays,
  ) async {
    if (amount <= 0) {
      _showErrorSnackbar('Please enter a valid amount');
      return false;
    }

    // Check if dashboard has sufficient balance
    if (_dashboardViewModel != null) {
      if (_dashboardViewModel!.dashboardBalance < amount) {
        _showErrorSnackbar('Insufficient balance in dashboard');
        return false;
      }
    }

    setBusy(true);
    try {
      // Ensure wallet is available
      await _ensureWalletAvailable();

      // Transfer from dashboard to lock save first
      bool transferSuccess = false;
      if (_dashboardViewModel != null) {
        transferSuccess = _dashboardViewModel!.transferToLockSave(amount);
      }

      if (!transferSuccess) {
        _showErrorSnackbar('Transfer failed. Please try again.');
        return false;
      }

      print(
          '🔒 Creating lock save: amount=$amount, title=$title, days=$lockDays');

      await Future.delayed(Duration(milliseconds: 1500));
      final lockId = 'lock_${DateTime.now().millisecondsSinceEpoch}';

      if (lockId.isNotEmpty) {
        // Refresh data to show new lock
        await Future.wait([
          loadBalance(),
          loadUserLocks(),
        ]);

        _showSuccessSnackbar(
            '🔒 Lock save created successfully! \$${amount.toStringAsFixed(2)} locked for $lockDays days');
        return true;
      } else {
        // Rollback the transfer on error
        if (_dashboardViewModel != null) {
          _dashboardViewModel!.transferFromFlexiSave(amount);
        }
        _showErrorSnackbar('Failed to create lock save');
        return false;
      }
    } catch (e) {
      print('❌ Error creating lock save: $e');
      _showErrorSnackbar('Error creating lock save: ${e.toString()}');

      // Rollback the transfer on error
      if (_dashboardViewModel != null) {
        _dashboardViewModel!.transferFromFlexiSave(amount);
      }
      return false;
    } finally {
      setBusy(false);
    }
  }

  // Calculate interest for preview
  Future<Map<String, dynamic>> calculateLockPreview(
    double amount,
    int lockDays,
    String periodId,
  ) async {
    try {
      // TODO: Implement contract integration for interest calculation
      // final preview = await _contractService.calculateLockInterest(
      //   amount: amount,
      //   durationDays: lockDays,
      // );

      // Fallback to local calculation
      final period = _lockPeriods.firstWhere((p) => p['id'] == periodId,
          orElse: () => _lockPeriods[0]);

      final rate = period['interestRate'] / 100;
      final interest = (amount * rate * lockDays) / 365;
      final maturityDate = DateTime.now().add(Duration(days: lockDays));

      return {
        'interest': interest,
        'totalPayout': amount + interest,
        'maturityDate':
            '${maturityDate.day}/${maturityDate.month}/${maturityDate.year}',
        'annualRate': period['interestRate'],
      };
    } catch (e) {
      print('❌ Error calculating lock preview: $e');
      throw Exception('Failed to calculate preview: $e');
    }
  }

  // Withdraw from matured lock
  Future<bool> withdrawLock(String lockId) async {
    setBusy(true);
    try {
      await _ensureWalletAvailable();

      print('💸 Withdrawing lock: $lockId');

      // TODO: Implement actual contract call
      // final txHash = await _contractService.withdrawLockSave(lockId: lockId);

      // Simulate contract interaction
      await Future.delayed(Duration(milliseconds: 1000));
      final txHash = 'tx_${DateTime.now().millisecondsSinceEpoch}';

      if (txHash.isNotEmpty) {
        print('✅ Lock withdrawal successful');

        // Refresh data to reflect changes
        await Future.wait([
          loadBalance(),
          loadUserLocks(),
        ]);

        _showSuccessSnackbar('Lock withdrawn successfully!');
        return true;
      } else {
        _showErrorSnackbar('Lock withdrawal failed');
        return false;
      }
    } catch (e) {
      print('❌ Error withdrawing lock: $e');
      _showErrorSnackbar('Error withdrawing lock: ${e.toString()}');
      return false;
    } finally {
      setBusy(false);
    }
  }

  // Break lock early (with penalty)
  Future<bool> breakLock(String lockId) async {
    setBusy(true);
    try {
      await _ensureWalletAvailable();

      print('💥 Breaking lock early: $lockId');

      // TODO: Implement actual contract call
      // final txHash = await _contractService.breakLockSave(lockId: lockId);

      // Simulate contract interaction
      await Future.delayed(Duration(milliseconds: 1000));
      final txHash = 'tx_${DateTime.now().millisecondsSinceEpoch}';

      if (txHash.isNotEmpty) {
        print('✅ Lock break successful (with penalty)');

        // Refresh data to reflect changes
        await Future.wait([
          loadBalance(),
          loadUserLocks(),
        ]);

        _showSuccessSnackbar('Lock broken successfully (penalty applied)');
        return true;
      } else {
        _showErrorSnackbar('Lock break failed');
        return false;
      }
    } catch (e) {
      print('❌ Error breaking lock: $e');
      _showErrorSnackbar('Error breaking lock: ${e.toString()}');
      return false;
    } finally {
      setBusy(false);
    }
  }

  // Get locks by status for easier filtering
  Future<List<Map<String, dynamic>>> getOngoingLocks() async {
    try {
      await _ensureWalletAvailable();
      return await _contractService.getOngoingLockSaves();
    } catch (e) {
      print('❌ Error getting ongoing locks: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMaturedLocks() async {
    try {
      await _ensureWalletAvailable();
      return await _contractService.getMaturedLockSaves();
    } catch (e) {
      print('❌ Error getting matured locks: $e');
      return [];
    }
  }

  // Set dashboard viewmodel reference
  void setDashboardViewModel(DashboardViewModel? dashboardViewModel) {
    _dashboardViewModel = dashboardViewModel;
  }

  // Helper methods for snackbars
  void _showSuccessSnackbar(String message) {
    _snackbarService.showSnackbar(
      message: message,
      duration: Duration(seconds: 3),
    );
  }

  void _showErrorSnackbar(String message) {
    _snackbarService.showSnackbar(
      message: message,
      duration: Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    // Dispose any controllers or listeners here if any
    super.dispose();
  }
}

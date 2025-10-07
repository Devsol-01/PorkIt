import 'package:flutter/services.dart';
import 'package:mobile_app/app/app.bottomsheets.dart';
import 'package:mobile_app/app/app.locator.dart';
import 'package:mobile_app/services/contract_service.dart';
import 'package:mobile_app/services/firebase_auth_service.dart';
import 'package:mobile_app/services/firebase_wallet_manager_service.dart';
import 'package:mobile_app/services/token_service.dart';
import 'package:mobile_app/services/wallet_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class DashboardViewModel extends BaseViewModel {
  final _bottomSheetService = locator<BottomSheetService>();
  final _firebaseWalletManager = locator<FirebaseWalletManagerService>();
  final _walletService = locator<WalletService>();
  final _snackbarService = locator<SnackbarService>();
  final _authService = locator<FirebaseAuthService>();

  bool _isOngoingSelected = true;

  TokenService? _tokenService;

  bool get isOngoingSelected => _isOngoingSelected;

  WalletInfo? _walletInfo;
  WalletInfo? get walletInfo => _walletInfo;

  BigInt _balance = BigInt.zero;
  BigInt get balance => _balance;

  double _usdcBalance = 0.0; // Will be loaded from blockchain
  double _dashboardBalance = 0.0; // Will be synced with USDC balance

  double get usdcBalance {
    print('🔍 usdcBalance getter called: $_usdcBalance');
    return _usdcBalance;
  }

  double get dashboardBalance {
    print('🔍 dashboardBalance getter called: $_dashboardBalance');
    return _dashboardBalance;
  }

  String get formattedBalance => formatBalance(_balance);
  String get formattedDashboardBalance =>
      '\$${_dashboardBalance.toStringAsFixed(2)}';
  String get formattedTotalSavingsBalance =>
      '\$${_totalSavingsBalance.toStringAsFixed(2)}';

  /// Format balance for display (in ETH by default)
  String formatBalance(BigInt balance, {int decimals = 18}) {
    if (balance == BigInt.zero) return '0.0';
    final divisor = BigInt.from(10).pow(decimals);
    final whole = balance ~/ divisor;
    final fraction = (balance % divisor).toString().padLeft(decimals, '0');
    final trimmedFraction = fraction.replaceAll(RegExp(r'0*$'), '');
    return '$whole${trimmedFraction.isNotEmpty ? '.$trimmedFraction' : ''}';
  }

  bool get hasWallet => _walletInfo != null;

  /// Initialize - load wallet from Firebase system
  Future<void> initialize() async {
    setBusy(true);

    try {
      _tokenService ??= TokenService();

      // Check if user is authenticated
      if (_firebaseWalletManager.isAuthenticated) {
        print('✅ User is authenticated, loading wallet...');

        // First try to get wallet info from WalletService
        _walletInfo = _walletService.walletInfo;

        if (_walletInfo != null) {
          print('✅ Wallet found in WalletService: ${_walletInfo!.address}');
          await loadBalance();
        } else {
          print('⚠️ No wallet in WalletService, triggering wallet load...');

          // If no wallet in WalletService, trigger the Firebase wallet loading
          await _firebaseWalletManager.initialize();

          // Try again after initialization
          _walletInfo = _walletService.walletInfo;

          if (_walletInfo != null) {
            print(
                '✅ Wallet loaded after initialization: ${_walletInfo!.address}');
            await loadBalance();
          } else {
            print(
                '⚠️ Firebase initialization didn\'t load wallet, trying direct load...');

            // Try to load wallet directly from WalletService storage
            try {
              _walletInfo = await _walletService.loadWallet();
              if (_walletInfo != null) {
                print(
                    '✅ Wallet loaded directly from storage: ${_walletInfo!.address}');
                await loadBalance();
              } else {
                print('❌ Still no wallet found after direct load');
                // Don't show error snackbar immediately, try to continue
                print('🔄 Attempting to continue without wallet for now...');
              }
            } catch (e) {
              print('❌ Error loading wallet directly: $e');
              // Don't show error snackbar immediately, try to continue
              print('🔄 Attempting to continue without wallet for now...');
            }
          }
        }
      } else {
        print('❌ User not authenticated');
        _showErrorSnackbar('User not authenticated. Please log in.');
      }
    } catch (e) {
      print('❌ Error in DashboardViewModel initialize: $e');
      _showErrorSnackbar('Error loading wallet: $e');
    } finally {
      setBusy(false);
    }

    // Always try to load balance, even if wallet loading failed
    await loadBalance();
  }

  /// Load wallet balance - Focus on real USDC balance
  Future<void> loadBalance() async {
    if (_walletInfo == null) {
      print('⚠️ No wallet info available, attempting to load wallet first...');

      // Try to load wallet if not available
      try {
        _walletInfo = await _walletService.loadWallet();
        if (_walletInfo == null) {
          print('❌ Still no wallet available after loading attempt');
          // Set balances to 0 and continue
          _usdcBalance = 0.0;
          _dashboardBalance = 0.0;
          _balance = BigInt.zero;
          notifyListeners();
          return;
        }
        print('✅ Wallet loaded during balance check: ${_walletInfo!.address}');
      } catch (e) {
        print('❌ Error loading wallet during balance check: $e');
        // Set balances to 0 and continue
        _usdcBalance = 0.0;
        _dashboardBalance = 0.0;
        _balance = BigInt.zero;
        notifyListeners();
        return;
      }
    }

    try {
      print('💰 Loading real USDC balance from blockchain...');

      // Load real USDC balance from blockchain
      _usdcBalance = await _walletService.getUsdcBalance(_walletInfo!.address);
      _dashboardBalance = _usdcBalance; // Sync dashboard balance with real USDC

      print('✅ Real USDC balance loaded: $_usdcBalance');
      print('✅ Dashboard balance set to: $_dashboardBalance');

      // Keep ETH balance for deployment checks only (not displayed)
      _balance = await _walletService.getEthBalance(_walletInfo!.address);

      // Load total savings balance - mock data for now
      await loadSavingsBalance();

      notifyListeners();
    } catch (e) {
      print('❌ Error loading balance: $e');
      // Don't show error snackbar for balance loading failures to avoid spam
      // Just set balances to 0 and continue
      _usdcBalance = 0.0;
      _dashboardBalance = 0.0;
      _balance = BigInt.zero;
      notifyListeners();
    }
  }

  void setOngoingSelected(bool value) {
    // _isOngoingSelected = value;
    // notifyListeners(); // Notify UI to rebuild

    // // Load transactions when Transactions tab is selected
    // if (!value) {
    //   loadRecentTransactions();
    // }
  }

  Future<void> loadUsdcBalance() async {
    if (_walletInfo == null) return;

    try {
      print('🔄 Refreshing USDC balance...');
      _usdcBalance = await _walletService.getUsdcBalance(_walletInfo!.address);
      _dashboardBalance = _usdcBalance; // Keep in sync
      print('✅ USDC balance refreshed: $_usdcBalance');
      notifyListeners();
    } catch (e) {
      print('❌ Error loading USDC balance: $e');
      _showErrorSnackbar('Error loading USDC balance: $e');
    }
  }

  /// Refresh wallet data - Focus on ETH
  Future<void> refresh() async {
    await loadBalance(); // This now loads ETH as primary
  }

  /// Navigate to send USDC screen
  void navigateToSendUsdc() {
    if (_walletInfo == null) {
      _showErrorSnackbar('No wallet found');
      return;
    }

    // Show the crypto send sheet
    _bottomSheetService
        .showCustomSheet(
      variant: BottomSheetType.cryptoSend,
      title: 'Send Crypto',
    )
        .then((response) {
      if (response?.confirmed == true && response?.data != null) {
        // Handle the confirmed response
        final address = response!.data!['address'];
        // Call the method to send crypto
        processCryptoSend(address);
      }
    });
  }

  Future<void> processCryptoSend(String address) async {
    // Implement the logic to send crypto
    // This is where you would interact with the contract service to send the crypto
    // For now, just show a success message
    _showSuccessSnackbar('Crypto sent to $address successfully!');
  }

  /// Deploy account (needed for sending transactions)
  Future<void> deployAccount() async {
    if (_walletInfo == null || _walletInfo!.isDeployed) return;

    setBusy(true);

    try {
      final txHash = await _walletService.deployAccount();
      _showSuccessSnackbar(
          'Account deployment initiated!\nTx: ${txHash.substring(0, 10)}...');

      // Reload wallet info to update deployment status
      _walletInfo = await _walletService.loadWallet();
      notifyListeners();
    } catch (e) {
      _showErrorSnackbar('Failed to deploy account: $e');
    } finally {
      setBusy(false);
    }
  }

  /// Delete wallet
  Future<void> deleteWallet() async {
    setBusy(true);

    try {
      await _walletService.deleteWallet();
      _walletInfo = null;
      _balance = BigInt.zero;
      _showInfoSnackbar('Wallet deleted successfully');
    } catch (e) {
      _showErrorSnackbar('Error deleting wallet: $e');
    } finally {
      setBusy(false);
    }
  }

  // Helper methods for snackbars
  void _showSuccessSnackbar(String message) {
    _snackbarService.showSnackbar(
      message: message,
      duration: Duration(seconds: 4),
    );
  }

  void _showErrorSnackbar(String message) {
    _snackbarService.showSnackbar(
      message: message,
      duration: Duration(seconds: 4),
    );
  }

  void _showInfoSnackbar(String message) {
    _snackbarService.showSnackbar(
      message: message,
      duration: Duration(seconds: 2),
    );
  }

  // Savings-related properties
  double _totalSavingsBalance = 0.0;
  double _flexiSaveBalance = 0.0;
  double _lockSaveBalance = 0.0;
  double _goalSaveBalance = 0.0;
  double _groupSaveBalance = 0.0;

  double get totalSavingsBalance => _totalSavingsBalance;
  double get flexiSaveBalance => _flexiSaveBalance;
  double get lockSaveBalance => _lockSaveBalance;
  double get goalSaveBalance => _goalSaveBalance;
  double get groupSaveBalance => _groupSaveBalance;

  // Calculate total savings as sum of all individual balances
  void _updateTotalSavingsBalance() {
    _totalSavingsBalance = _flexiSaveBalance +
        _lockSaveBalance +
        _goalSaveBalance +
        _groupSaveBalance;
    notifyListeners();
  }

  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? get userStats => _userStats;

  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;

  /// Load total savings balance from contract
  Future<void> loadSavingsBalance() async {
    try {
      print('📊 Loading real savings balances from contract...');

      // Import contract service
      final contractService = locator<ContractService>();

      // Load real balances from contract
      final flexiBalanceBigInt = await contractService.getFlexiBalance();
      final totalDepositsBigInt = await contractService.getUserTotalDeposits();

      _flexiSaveBalance = flexiBalanceBigInt.toDouble() /
          1000000.0; // Convert from raw USDC units
      _lockSaveBalance = totalDepositsBigInt.toDouble() /
          1000000.0; // This includes all deposits (flexi + lock + goal + group)

      // Load goal save balance from contract
      final userGoalSaves = await contractService.getUserGoalSaves();
      _goalSaveBalance = userGoalSaves.fold(0.0, (sum, goal) {
        final currentAmount = goal['current_amount'] as BigInt?;
        if (currentAmount != null) {
          return sum +
              (currentAmount.toDouble() / 1000000.0); // Convert from USDC units
        }
        return sum;
      });

      // For now, set group to 0 until we implement group saves
      _groupSaveBalance = 0.0;

      _updateTotalSavingsBalance();
      print(
          '✅ Real savings balances loaded: Flexi: \$${_flexiSaveBalance}, Lock: \$${_lockSaveBalance}, Total: \$${_totalSavingsBalance}');
    } catch (e) {
      print('❌ Error loading real savings balances: $e');
      // Fallback to mock mode if contract call fails
      _updateTotalSavingsBalance();
    }
  }

  /// Refresh all dashboard data
  Future<void> refreshDashboard() async {
    await Future.wait([
      loadBalance(),
    ]);
  }

  /// Refresh only savings balances - mock implementation
  Future<void> refreshSavingsBalances() async {
    try {
      // In mock mode, balances are already managed by transfer methods
      // Just update the total
      _updateTotalSavingsBalance();
      notifyListeners();
      print('✅ Savings balances refreshed (mock)');
    } catch (e) {
      print('❌ Error refreshing savings balances: $e');
    }
  }

  Future<void> logout() async {
    setBusy(true);

    try {
      _authService.logout();
    } catch (e) {
      print('❌ Error during logout: $e');
      _showErrorSnackbar('Error logging out: $e');
    } finally {
      setBusy(false);
    }
  }

  void showDepositSheet() {
    _bottomSheetService.showCustomSheet(
        variant: BottomSheetType.deposit, barrierDismissible: false);
  }

  /// Handle flexi save deposit from dashboard
  Future<void> depositToFlexiSave(double amount) async {
    if (amount <= 0) {
      _showErrorSnackbar('Invalid deposit amount');
      return;
    }

    if (_dashboardBalance < amount) {
      _showErrorSnackbar(
          'Insufficient balance. Available: \$${_dashboardBalance}, Required: \$${amount}');
      return;
    }

    setBusy(true);
    try {
      print('🚀 Starting flexi save deposit: \$${amount}');

      // Show deposit sheet with flexi save option
      final response = await _bottomSheetService.showCustomSheet(
        variant: BottomSheetType.deposit,
        title: 'Deposit to Flexi Save',
        data: {'amount': amount, 'type': 'flexi_save'},
      );

      if (response?.confirmed == true) {
        // Deposit was successful
        final data = response!.data as Map<String, dynamic>;
        final txHash = data['txHash'];
        final depositedAmount = data['amount'];

        // Update balances
        _dashboardBalance -= depositedAmount;
        _flexiSaveBalance += depositedAmount;
        _usdcBalance = _dashboardBalance;
        _updateTotalSavingsBalance();
        notifyListeners();

        _showSuccessSnackbar(
            'Flexi save deposit successful! TX: ${txHash.substring(0, 10)}...');
        print('✅ Flexi save deposit completed: TX $txHash');
      } else if (response?.data != null) {
        // Deposit failed
        _showErrorSnackbar(response!.data.toString());
      }
    } catch (e) {
      print('❌ Flexi save deposit error: $e');
      _showErrorSnackbar('Flexi save deposit failed: $e');
    } finally {
      setBusy(false);
    }
  }

  void showSendSheet() {
    _bottomSheetService.showCustomSheet(
        variant: BottomSheetType.send, barrierDismissible: false);
  }

  // Balance transfer methods for unified balance system

  /// Transfer money from dashboard to flexi save
  bool transferToFlexiSave(double amount) {
    print('🔄 Attempting flexi save transfer: \$${amount}');
    print('💰 Current dashboard balance: \$${_dashboardBalance}');
    print('💰 Current USDC balance: \$${_usdcBalance}');

    if (_dashboardBalance >= amount) {
      print('✅ Sufficient balance, proceeding with transfer');
      _dashboardBalance -= amount;
      _flexiSaveBalance += amount;
      _usdcBalance = _dashboardBalance; // Keep USDC balance in sync
      _updateTotalSavingsBalance();
      notifyListeners(); // Trigger UI update
      print(
          '✅ Transfer completed. New dashboard balance: \$${_dashboardBalance}');
      return true;
    }

    print('❌ Insufficient balance for transfer');
    print('   Required: \$${amount}, Available: \$${_dashboardBalance}');
    _showErrorSnackbar(
        'Insufficient balance. Available: \$${_dashboardBalance}, Required: \$${amount}');
    return false;
  }

  /// Transfer money from flexi save back to dashboard
  bool transferFromFlexiSave(double amount) {
    if (_flexiSaveBalance >= amount) {
      _flexiSaveBalance -= amount;
      _dashboardBalance += amount;
      _usdcBalance = _dashboardBalance;
      _updateTotalSavingsBalance();
      notifyListeners(); // Trigger UI update
      return true;
    }
    return false;
  }

  /// Transfer money from dashboard to lock save
  bool transferToLockSave(double amount) {
    if (_dashboardBalance >= amount) {
      _dashboardBalance -= amount;
      _lockSaveBalance += amount;
      _usdcBalance = _dashboardBalance;
      _updateTotalSavingsBalance();
      print(
          '💰 Dashboard balance updated: \$${_dashboardBalance} (reduced by \$${amount})');
      notifyListeners(); // Trigger UI update
      return true;
    }
    print(
        '❌ Insufficient dashboard balance: \$${_dashboardBalance} < \$${amount}');
    return false;
  }

  /// Transfer money from lock save back to dashboard
  bool transferFromLockSave(double amount) {
    if (_lockSaveBalance >= amount) {
      _lockSaveBalance -= amount;
      _dashboardBalance += amount;
      _usdcBalance = _dashboardBalance;
      _updateTotalSavingsBalance();
      notifyListeners(); // Trigger UI update
      return true;
    }
    return false;
  }

  /// Transfer money from dashboard to goal save
  bool transferToGoalSave(double amount) {
    if (_dashboardBalance >= amount) {
      _dashboardBalance -= amount;
      _goalSaveBalance += amount;
      _usdcBalance = _dashboardBalance;
      _updateTotalSavingsBalance();
      notifyListeners(); // Trigger UI update
      return true;
    }
    return false;
  }

  /// Transfer money from goal save back to dashboard
  bool transferFromGoalSave(double amount) {
    if (_goalSaveBalance >= amount) {
      _goalSaveBalance -= amount;
      _dashboardBalance += amount;
      _usdcBalance = _dashboardBalance;
      _updateTotalSavingsBalance();
      notifyListeners(); // Trigger UI update
      return true;
    }
    return false;
  }

  /// Deposit to savings - reduces dashboard balance
  Future<void> depositToSavings(double amount) async {
    if (amount <= 0 || amount > _dashboardBalance) return;

    setBusy(true);
    try {
      _dashboardBalance -= amount;
      _usdcBalance = _dashboardBalance; // Keep in sync
      notifyListeners();

      // 3 second loading for demo
      await Future.delayed(Duration(seconds: 3));
    } finally {
      setBusy(false);
    }
  }

  /// Withdraw from savings - increases dashboard balance
  Future<void> withdrawFromSavings(double amount) async {
    if (amount <= 0) return;

    setBusy(true);
    try {
      _dashboardBalance += amount;
      _usdcBalance = _dashboardBalance; // Keep in sync
      notifyListeners();

      // Quick operation for demo
      await Future.delayed(Duration(milliseconds: 500));
    } finally {
      setBusy(false);
    }
  }

  /// Transfer money from dashboard to group save
  bool transferToGroupSave(double amount) {
    if (_dashboardBalance >= amount) {
      _dashboardBalance -= amount;
      _groupSaveBalance += amount;
      _usdcBalance = _dashboardBalance;
      _updateTotalSavingsBalance();
      notifyListeners(); // Trigger UI update
      return true;
    }
    return false;
  }

  /// Transfer money from group save back to dashboard
  bool transferFromGroupSave(double amount) {
    if (_groupSaveBalance >= amount) {
      _groupSaveBalance -= amount;
      _dashboardBalance += amount;
      _usdcBalance = _dashboardBalance;
      _updateTotalSavingsBalance();
      notifyListeners(); // Trigger UI update
      return true;
    }
    return false;
  }

  // Formatted getters for display
  String get formattedFlexiSaveBalance =>
      '\$${_flexiSaveBalance.toStringAsFixed(2)}';
  String get formattedLockSaveBalance =>
      '\$${_lockSaveBalance.toStringAsFixed(2)}';
  String get formattedGoalSaveBalance =>
      '\$${_goalSaveBalance.toStringAsFixed(2)}';
  String get formattedGroupSaveBalance =>
      '\$${_groupSaveBalance.toStringAsFixed(2)}';

  // Portfolio value calculation (dashboard + savings)
  double get totalPortfolioValue => _dashboardBalance + _totalSavingsBalance;
  String get formattedPortfolioValue =>
      '\$${totalPortfolioValue.toStringAsFixed(2)}';

  // Loading states for refresh
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  /// Refresh dashboard with animation
  Future<void> refreshDashboardWithAnimation() async {
    _isRefreshing = true;
    notifyListeners();

    await Future.delayed(
        Duration(milliseconds: 1500)); // Realistic loading time
    await refreshDashboard();

    _isRefreshing = false;
    notifyListeners();
  }

  /// Force refresh balance - useful for debugging balance issues
  Future<void> forceRefreshBalance() async {
    print('🔄 Force refreshing balance...');
    await loadBalance();
    print('✅ Balance refresh completed');
    _showInfoSnackbar('Balance refreshed: \$${_dashboardBalance}');
  }

  /// Force reload wallet and balance - useful for debugging wallet issues
  Future<void> forceReloadWallet() async {
    print('🔄 Force reloading wallet...');

    try {
      _walletInfo = await _walletService.loadWallet();
      if (_walletInfo != null) {
        print('✅ Wallet reloaded: ${_walletInfo!.address}');
        await loadBalance();
        _showInfoSnackbar('Wallet reloaded successfully');
      } else {
        print('❌ Failed to reload wallet');
        _showErrorSnackbar('Failed to reload wallet');
      }
    } catch (e) {
      print('❌ Error reloading wallet: $e');
      _showErrorSnackbar('Error reloading wallet: $e');
    }
  }

  /// Check if balance is loaded and valid
  bool get isBalanceLoaded => _dashboardBalance > 0.0;

  /// Ensure balance is loaded before transactions
  Future<bool> ensureBalanceLoaded() async {
    print(
        '🔍 Checking if balance is loaded... Current balance: $_dashboardBalance');

    if (!isBalanceLoaded) {
      print('🔄 Balance not loaded, refreshing...');

      // First ensure wallet is loaded
      if (_walletInfo == null) {
        print(
            '⚠️ No wallet info available, attempting to load wallet first...');

        // Check if user is authenticated with Firebase
        if (_firebaseWalletManager.isAuthenticated) {
          print(
              '✅ User authenticated, initializing Firebase wallet manager...');

          // Initialize Firebase wallet manager to load wallet
          await _firebaseWalletManager.initialize();

          // Check if wallet is now available
          if (_walletService.currentAccount == null) {
            print(
                '❌ Firebase initialization didn\'t load wallet, trying direct load...');

            // Try direct load as fallback
            try {
              _walletInfo = await _walletService.loadWallet();
              if (_walletInfo == null) {
                print('❌ Still no wallet available after loading attempt');
                return false;
              }
            } catch (e) {
              print('❌ Error loading wallet during balance check: $e');
              return false;
            }
          } else {
            _walletInfo = _walletService.walletInfo;
          }
        } else {
          print('❌ User not authenticated with Firebase');
          return false;
        }
      }

      await loadBalance();

      if (isBalanceLoaded) {
        print('✅ Balance loaded successfully: $_dashboardBalance');
        return true;
      } else {
        print('❌ Balance still not loaded after refresh');
        return false;
      }
    }

    print('✅ Balance already loaded: $_dashboardBalance');
    return true;
  }

  /// Get current wallet address for display
  Future<String?> getCurrentWalletAddress() async {
    try {
      return await _walletService.getCurrentWalletAddress();
    } catch (e) {
      print('❌ Error getting current wallet address: $e');
      return null;
    }
  }

  String getCurrentUserFirstName() {
    final user = _authService.currentUser;
    return user?.firstName ?? 'User';
  }

  Future<void> copyWalletAddressToClipboard() async {
    try {
      final address = await getCurrentWalletAddress();
      if (address != null) {
        await Clipboard.setData(ClipboardData(text: address));
        _showSuccessSnackbar('Wallet address copied to clipboard');
      } else {
        _showErrorSnackbar('Failed to get wallet address');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to copy address: $e');
    }
  }

  @override
  void dispose() {
    // Dispose any controllers or listeners here if any
    super.dispose();
  }
}

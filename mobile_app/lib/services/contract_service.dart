import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'package:starknet/starknet.dart';
import 'package:starknet_provider/starknet_provider.dart';
import 'package:avnu_provider/avnu_provider.dart';
import 'package:mobile_app/services/wallet_service.dart';
import 'package:mobile_app/config/env_config.dart';

class ContractService {
  final WalletService _walletService;

  ContractService(this._walletService);

  /// Get contract address from config
  Felt get _contractAddress =>
      Felt.fromHexString(EnvConfig.savingsVaultContractAddress);

  /// Check if contract exists on chain
  Future<bool> _checkContractExists() async {
    try {
      final result =
          await _walletService.currentAccount?.provider.getClassHashAt(
        contractAddress: _contractAddress,
        blockId: BlockId.latest,
      );
      return result != null;
    } catch (e) {
      print('❌ CONTRACT SERVICE: Error checking contract existence: $e');
      return false;
    }
  }

  /// Approve USDC spending for the savings vault contract using wallet service
  Future<String> _approveUsdcSpending(BigInt amount) async {
    print('🔐 CONTRACT SERVICE: Approving USDC spending for amount: $amount');

    // Convert amount to USDC units (6 decimals)
    final amountInUsdc = amount.toDouble() / 1000000.0;
    print('🔢 CONTRACT SERVICE: Amount in USDC: $amountInUsdc');

    // Use the wallet service's approveUsdc method which is more robust
    final spenderAddress = _contractAddress.toHexString();
    print('🎯 CONTRACT SERVICE: Approving spender: $spenderAddress');

    return await _walletService.approveUsdc(
      spenderAddress: spenderAddress,
      amount: amountInUsdc,
    );
  }

  //functions for porket save

  /// Get flexi balance for current user
  Future<BigInt> getFlexiBalance() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      print('❌ CONTRACT SERVICE: Wallet not connected');
      return BigInt.zero; // Return zero instead of throwing
    }

    final userAddress = account.accountAddress;

    print(
        '🔍 CONTRACT SERVICE: Getting flexi balance for user: ${userAddress.toHexString()}');
    print('📞 CONTRACT SERVICE: Contract address: $_contractAddress');

    try {
      // Prepare function call for get_flexi_balance
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_flexi_balance'),
        calldata: [userAddress],
      );

      print(
          '📋 CONTRACT SERVICE: Function call prepared: ${functionCall.entryPointSelector}');

      // Call the contract
      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return response.when(
        result: (result) {
          print('📊 CONTRACT SERVICE: Raw balance result: $result');

          if (result.length < 2) {
            print(
                '❌ CONTRACT SERVICE: Invalid balance response - not enough elements');
            return BigInt.zero; // Return zero instead of throwing
          }

          // Combine low and high parts for u256
          final low = result[0].toBigInt();
          final high = result[1].toBigInt();

          print('🔢 CONTRACT SERVICE: Low: $low, High: $high');

          final balance = low + (high << 128);
          print('✅ CONTRACT SERVICE: Combined balance: $balance');

          return balance;
        },
        error: (error) {
          print('❌ CONTRACT SERVICE: Failed to get flexi balance: $error');
          return BigInt.zero; // Return zero instead of throwing
        },
      );
    } catch (e) {
      print('❌ CONTRACT SERVICE: Exception getting flexi balance: $e');
      return BigInt.zero; // Return zero instead of throwing
    }
  }

  /// Flexi deposit using AVNU provider for better transaction handling
  Future<String> flexiDepositWithAvnu({
    required double amount,
  }) async {
    final currentAccount = _walletService.currentAccount;
    final ownerSigner = _walletService.ownerSigner;
    final guardianSigner = _walletService.guardianSigner;
    final avnuProvider = _walletService.avnuProvider;

    if (currentAccount == null ||
        ownerSigner == null ||
        guardianSigner == null) {
      throw Exception('No wallet account available');
    }

    if (amount <= 0) {
      throw Exception('Amount must be greater than 0');
    }

    try {
      print('🏦 Initiating Flexi Deposit with AVNU: $amount USDC');

      // Check if account is deployed, deploy if necessary
      final deployResult = await currentAccount.provider.getClassHashAt(
        contractAddress: currentAccount.accountAddress,
        blockId: BlockId.latest,
      );
      final isDeployed = deployResult.when(
        result: (_) => true,
        error: (_) => false,
      );
      if (!isDeployed) {
        print('🚀 Account not deployed, deploying first...');
        await _walletService.deployAccount();
      }

      // Check USDC balance before depositing
      final currentBalance = await _walletService.getUsdcBalance();
      if (currentBalance < amount) {
        throw Exception(
            'Insufficient USDC balance. Available: ${_walletService.formatUsdcBalance(currentBalance)}, Required: ${_walletService.formatUsdcBalance(amount)}');
      }

      // Convert amount to raw USDC units (6 decimals)
      final rawAmount = BigInt.from((amount * pow(10, 6)).round());
      print('📊 Raw deposit amount: $rawAmount (${amount} USDC)');

      // Check current allowance for the contract
      final currentAllowance = await getUsdcAllowance(
        ownerAddress: currentAccount.accountAddress.toHexString(),
        spenderAddress: _contractAddress.toHexString(),
      );

      // If allowance is insufficient, approve first
      if (currentAllowance < amount) {
        print(
            '🔓 Insufficient allowance (${_walletService.formatUsdcBalance(currentAllowance)}), approving ${_walletService.formatUsdcBalance(amount)} USDC...');
        await _walletService.approveUsdc(
          spenderAddress: _contractAddress.toHexString(),
          amount: amount,
        );
        print('✅ USDC approval completed');

        // Small delay to ensure approval is processed
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Prepare flexi_deposit call data
      final calls = [
        {
          'contractAddress': _contractAddress.toHexString(),
          'entrypoint': 'flexi_deposit',
          'calldata': [
            '0x${rawAmount.toRadixString(16)}',
            '0x0', // amount.high for amounts < 2^128
          ],
        },
      ];

      print('🔧 Building typed data with Avnu for deposit...');

      // Build typed data with AVNU
      final avnuBuildTypeDataResponse = await avnuProvider.buildTypedData(
        currentAccount.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        WalletService.argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        throw Exception(
            'Failed to build typed data: $avnuBuildTypeDataResponse');
      }

      final avnuTypedData =
          avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create owner account signer
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: ownerSigner,
        guardianSigner: guardianSigner,
      );

      // Compute message hash and sign it
      final hash = avnuTypedData.hash(currentAccount.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing Flexi Deposit with Avnu...');

      // Execute the transaction via AVNU provider
      final avnuExecute = await avnuProvider.execute(
        currentAccount.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        throw Exception('Flexi deposit failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        throw Exception('Transaction hash is null or empty');
      }

      print('✅ Flexi Deposit successful! TX: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ Flexi Deposit error: $e');
      throw Exception('Failed to complete flexi deposit: $e');
    }
  }

  /// Flexi deposit with approval in one call
  Future<String> flexiDepositWithApproval({
    required double amount,
  }) async {
    try {
      print('🔄 Starting approve + deposit flow...');

      // First approve
      final approvalTx = await _walletService.approveUsdc(
        spenderAddress: _contractAddress.toHexString(),
        amount: amount,
      );
      print('✅ Approval TX: $approvalTx');

      // Wait a bit for approval to be processed
      await Future.delayed(Duration(seconds: 2));

      // Then deposit
      final depositTx = await flexiDepositWithAvnu(amount: amount);
      print('✅ Deposit TX: $depositTx');

      return depositTx;
    } catch (e) {
      print('❌ Approve + Deposit flow error: $e');
      rethrow;
    }
  }

  /// Flexi withdraw using AVNU provider for better transaction handling
  Future<String> flexiWithdrawWithAvnu({
    required double amount,
  }) async {
    final currentAccount = _walletService.currentAccount;
    final ownerSigner = _walletService.ownerSigner;
    final guardianSigner = _walletService.guardianSigner;
    final avnuProvider = _walletService.avnuProvider;

    if (currentAccount == null ||
        ownerSigner == null ||
        guardianSigner == null) {
      throw Exception('No wallet account available');
    }

    if (amount <= 0) {
      throw Exception('Amount must be greater than 0');
    }

    try {
      print('🏦 Initiating Flexi Withdraw with AVNU: $amount USDC');

      // Check if account is deployed, deploy if necessary
      final deployResult = await currentAccount.provider.getClassHashAt(
        contractAddress: currentAccount.accountAddress,
        blockId: BlockId.latest,
      );
      final isDeployed = deployResult.when(
        result: (_) => true,
        error: (_) => false,
      );
      if (!isDeployed) {
        print('🚀 Account not deployed, deploying first...');
        await _walletService.deployAccount();
      }

      // Check USDC balance before depositing
      final currentBalance = await _walletService.getUsdcBalance();
      if (currentBalance < amount) {
        throw Exception(
            'Insufficient USDC balance. Available: ${_walletService.formatUsdcBalance(currentBalance)}, Required: ${_walletService.formatUsdcBalance(amount)}');
      }

      // Convert amount to raw USDC units (6 decimals)
      final rawAmount = BigInt.from((amount * pow(10, 6)).round());
      print('📊 Raw deposit amount: $rawAmount (${amount} USDC)');

      // Check current allowance for the contract
      final currentAllowance = await getUsdcAllowance(
        ownerAddress: currentAccount.accountAddress.toHexString(),
        spenderAddress: _contractAddress.toHexString(),
      );

      // If allowance is insufficient, approve first
      if (currentAllowance < amount) {
        print(
            '🔓 Insufficient allowance (${_walletService.formatUsdcBalance(currentAllowance)}), approving ${_walletService.formatUsdcBalance(amount)} USDC...');
        await _walletService.approveUsdc(
          spenderAddress: _contractAddress.toHexString(),
          amount: amount,
        );
        print('✅ USDC approval completed');

        // Small delay to ensure approval is processed
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Prepare flexi_deposit call data
      final calls = [
        {
          'contractAddress': _contractAddress.toHexString(),
          'entrypoint': 'flexi_withdraw',
          'calldata': [
            '0x${rawAmount.toRadixString(16)}',
            '0x0', // amount.high for amounts < 2^128
          ],
        },
      ];

      print('🔧 Building typed data with Avnu for deposit...');

      // Build typed data with AVNU
      final avnuBuildTypeDataResponse = await avnuProvider.buildTypedData(
        currentAccount.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        WalletService.argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        throw Exception(
            'Failed to build typed data: $avnuBuildTypeDataResponse');
      }

      final avnuTypedData =
          avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create owner account signer
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: ownerSigner,
        guardianSigner: guardianSigner,
      );

      // Compute message hash and sign it
      final hash = avnuTypedData.hash(currentAccount.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing Flexi Withdraw with Avnu...');

      // Execute the transaction via AVNU provider
      final avnuExecute = await avnuProvider.execute(
        currentAccount.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        throw Exception('Flexi Withdraw failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        throw Exception('Transaction hash is null or empty');
      }

      print('✅ Flexi withdraw successful! TX: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ Flexi Withdraw error: $e');
      throw Exception('Failed to complete flexi Withdraw: $e');
    }
  }

  /// Flexi deposit with approval in one call
  Future<String> flexiWithdrawWithApproval({
    required double amount,
  }) async {
    try {
      print('🔄 Starting approve + deposit flow...');

      // First approve
      final approvalTx = await _walletService.approveUsdc(
        spenderAddress: _contractAddress.toHexString(),
        amount: amount,
      );
      print('✅ Approval TX: $approvalTx');

      // Wait a bit for approval to be processed
      await Future.delayed(Duration(seconds: 2));

      // Then deposit
      final depositTx = await flexiWithdrawWithAvnu(amount: amount);
      print('✅ Deposit TX: $depositTx');

      return depositTx;
    } catch (e) {
      print('❌ Approve + Deposit flow error: $e');
      rethrow;
    }
  }

  /// Get Savings balance for current user
  Future<BigInt> getSavingsBalance() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    final userAddress = account.accountAddress;

    print(
        '🔍 CONTRACT SERVICE: Getting Savings balance for user: ${userAddress.toHexString()}');
    print('📞 CONTRACT SERVICE: Contract address: $_contractAddress');

    // Prepare function call for get_flexi_balance
    final functionCall = FunctionCall(
      contractAddress: _contractAddress,
      entryPointSelector: getSelectorByName('get_user_total_deposits'),
      calldata: [userAddress],
    );

    print(
        '📋 CONTRACT SERVICE: Function call prepared: ${functionCall.entryPointSelector}');

    // Call the contract
    final response = await account.provider.call(
      request: functionCall,
      blockId: BlockId.latest,
    );

    return response.when(
      result: (result) {
        print('📊 CONTRACT SERVICE: Raw balance result: $result');

        if (result.length < 2) {
          print(
              '❌ CONTRACT SERVICE: Invalid balance response - not enough elements');
          throw Exception('Invalid balance response');
        }

        // Combine low and high parts for u256
        final low = result[0].toBigInt();
        final high = result[1].toBigInt();

        print('🔢 CONTRACT SERVICE: Low: $low, High: $high');

        final balance = low + (high << 128);
        print('✅ CONTRACT SERVICE: Combined balance: $balance');

        return balance;
      },
      error: (error) {
        print('❌ CONTRACT SERVICE: Failed to get savings balance: $error');
        throw Exception('Failed to get savings balance: $error');
      },
    );
  }

  /// Get user total deposits
  Future<BigInt> getUserTotalDeposits() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    final userAddress = account.accountAddress;

    // Prepare function call for get_user_total_deposits
    final functionCall = FunctionCall(
      contractAddress: _contractAddress,
      entryPointSelector: getSelectorByName('get_user_total_deposits'),
      calldata: [userAddress],
    );

    // Call the contract
    final response = await account.provider.call(
      request: functionCall,
      blockId: BlockId.latest,
    );

    return response.when(
      result: (result) {
        if (result.length < 2) {
          throw Exception('Invalid deposits response');
        }
        // Combine low and high parts for u256
        final low = result[0].toBigInt();
        final high = result[1].toBigInt();
        return low + (high << 128);
      },
      error: (error) => throw Exception('Failed to get total deposits: $error'),
    );
  }

  /// Get user savings streak
  Future<int> getUserSavingsStreak() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    final userAddress = account.accountAddress;

    // Prepare function call for get_user_savings_streak
    final functionCall = FunctionCall(
      contractAddress: _contractAddress,
      entryPointSelector: getSelectorByName('get_user_savings_streak'),
      calldata: [userAddress],
    );

    // Call the contract
    final response = await account.provider.call(
      request: functionCall,
      blockId: BlockId.latest,
    );

    return response.when(
      result: (result) {
        if (result.isEmpty) {
          throw Exception('Invalid streak response');
        }
        return result[0].toBigInt().toInt();
      },
      error: (error) => throw Exception('Failed to get savings streak: $error'),
    );
  }

  /// Get USDC allowance for a spender
  Future<double> getUsdcAllowance({
    required String ownerAddress,
    required String spenderAddress,
  }) async {
    try {
      final usdcContract =
          Felt.fromHexString(_walletService.usdcContractAddress);
      final owner = Felt.fromHexString(ownerAddress);
      final spender = Felt.fromHexString(spenderAddress);

      final result = await _walletService.currentAccount?.provider.call(
        request: FunctionCall(
          contractAddress: usdcContract,
          entryPointSelector: getSelectorByName('allowance'),
          calldata: [owner, spender],
        ),
        blockId: BlockId.latest,
      );

      if (result == null) {
        return 0.0;
      }

      return result.when(
        result: (callResult) {
          if (callResult.isEmpty) {
            return 0.0;
          }

          // Allowance is returned as Uint256 (low, high)
          final allowanceLow = callResult[0].toBigInt();
          final allowanceHigh =
              callResult.length > 1 ? callResult[1].toBigInt() : BigInt.zero;

          // Combine low and high parts
          final fullAllowance = allowanceLow + (allowanceHigh << 128);

          // Convert from raw USDC units (6 decimals) to readable format
          final allowanceInUsdc = fullAllowance.toDouble() / pow(10, 6);

          return allowanceInUsdc;
        },
        error: (error) {
          print('❌ Failed to get USDC allowance: $error');
          return 0.0;
        },
      );
    } catch (e) {
      print('❌ Error getting USDC allowance: $e');
      return 0.0;
    }
  }

  /// Create a lock save
  Future<String> createLockSave({
    required double amount,
    required int durationDays,
    required String title,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('🔒 Creating lock save: $amount USDC for $durationDays days');

      // Convert amount to raw USDC units (6 decimals)
      final rawAmount = BigInt.from((amount * pow(10, 6)).round());
      print('📊 Raw amount: $rawAmount (${amount} USDC)');

      // Convert title to felt252 (first 31 characters)
      final titleFelt =
          Felt.fromString(title.length > 31 ? title.substring(0, 31) : title);
      final titleHex = '0x${titleFelt.toBigInt().toRadixString(16)}';

      // Check USDC balance before creating lock save
      final currentBalance = await _walletService.getUsdcBalance();
      if (currentBalance < amount) {
        throw Exception(
            'Insufficient USDC balance. Available: ${_walletService.formatUsdcBalance(currentBalance)}, Required: ${_walletService.formatUsdcBalance(amount)}');
      }

      // Check current allowance for the contract
      final currentAllowance = await getUsdcAllowance(
        ownerAddress: account.accountAddress.toHexString(),
        spenderAddress: _contractAddress.toHexString(),
      );

      // If allowance is insufficient, approve first
      if (currentAllowance < amount) {
        print(
            '🔓 Insufficient allowance (${_walletService.formatUsdcBalance(currentAllowance)}), approving ${_walletService.formatUsdcBalance(amount)} USDC...');
        await _walletService.approveUsdc(
          spenderAddress: _contractAddress.toHexString(),
          amount: amount,
        );
        print('✅ USDC approval completed');

        // Small delay to ensure approval is processed
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Prepare create_lock_save call data
      final calls = [
        {
          'contractAddress': _contractAddress.toHexString(),
          'entrypoint': 'create_lock_save',
          'calldata': [
            '0x${rawAmount.toRadixString(16)}',
            '0x0',
            '0x${BigInt.from(durationDays).toRadixString(16)}',
            titleHex,
          ],
        },
      ];

      print('🔧 Building typed data with Avnu for lock save creation...');

      // Build typed data with AVNU
      final avnuBuildTypeDataResponse =
          await _walletService.avnuProvider.buildTypedData(
        account.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        WalletService.argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        throw Exception(
            'Failed to build typed data: $avnuBuildTypeDataResponse');
      }

      final avnuTypedData =
          avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create owner account signer
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _walletService.ownerSigner!,
        guardianSigner: _walletService.guardianSigner!,
      );

      // Compute message hash and sign it
      final hash = avnuTypedData.hash(account.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing lock save creation with Avnu...');

      // Execute the transaction via AVNU provider
      final avnuExecute = await _walletService.avnuProvider.execute(
        account.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        throw Exception('Lock save creation failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        throw Exception('Transaction hash is null or empty');
      }

      print('✅ Lock save created successfully! TX: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ Lock save creation error: $e');
      throw Exception('Failed to create lock save: $e');
    }
  }

  /// Withdraw from a lock save
  Future<String> withdrawLockSave({
    required BigInt lockId,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('🔓 Withdrawing from lock save ID: $lockId');

      // Convert BigInt lockId to u256 format (low, high)
      final low = lockId & BigInt.parse('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
      final high = lockId >> 128;

      // Prepare withdraw_lock_save call data
      final calls = [
        {
          'contractAddress': _contractAddress.toHexString(),
          'entrypoint': 'withdraw_lock_save',
          'calldata': [
            '0x${low.toRadixString(16)}',
            '0x${high.toRadixString(16)}',
          ],
        },
      ];

      print('🔧 Building typed data with Avnu for lock save withdrawal...');

      // Build typed data with AVNU
      final avnuBuildTypeDataResponse =
          await _walletService.avnuProvider.buildTypedData(
        account.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        WalletService.argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        throw Exception(
            'Failed to build typed data: $avnuBuildTypeDataResponse');
      }

      final avnuTypedData =
          avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create owner account signer
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _walletService.ownerSigner!,
        guardianSigner: _walletService.guardianSigner!,
      );

      // Compute message hash and sign it
      final hash = avnuTypedData.hash(account.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing lock save withdrawal with Avnu...');

      // Execute the transaction via AVNU provider
      final avnuExecute = await _walletService.avnuProvider.execute(
        account.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        throw Exception('Lock save withdrawal failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        throw Exception('Transaction hash is null or empty');
      }

      print('✅ Lock save withdrawal successful! TX: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ Lock save withdrawal error: $e');
      throw Exception('Failed to withdraw from lock save: $e');
    }
  }

  /// Get lock save details
  Future<Map<String, dynamic>> getLockSave({
    required BigInt lockId,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('🔍 Getting lock save details for ID: $lockId');

      // Convert BigInt lockId to u256 format (low, high)
      final low =
          Felt(lockId & BigInt.parse('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'));
      final high = Felt(lockId >> 128);

      // Prepare function call for get_lock_save
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_lock_save'),
        calldata: [low, high],
      );

      // Call the contract
      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return response.when(
        result: (result) {
          print('📊 Lock save result: $result');

          if (result.length < 8) {
            throw Exception('Invalid lock save response');
          }

          // Parse the LockSave struct
          final lockSaveData = {
            'id': result[0].toBigInt(),
            'user': result[1].toHexString(),
            'amount': result[2].toBigInt(),
            'interest_rate': result[3].toBigInt(),
            'lock_duration': result[4].toBigInt().toInt(),
            'start_time': result[5].toBigInt().toInt(),
            'maturity_time': result[6].toBigInt().toInt(),
            'title':
                result[7].toString(), // This might need adjustment for felt252
            'is_matured':
                result.length > 8 ? result[8].toBigInt() == BigInt.one : false,
            'is_withdrawn':
                result.length > 9 ? result[9].toBigInt() == BigInt.one : false,
          };

          print('✅ Lock save details retrieved: $lockSaveData');
          return lockSaveData;
        },
        error: (error) {
          print('❌ Failed to get lock save: $error');
          throw Exception('Failed to get lock save: $error');
        },
      );
    } catch (e) {
      print('❌ Error getting lock save details: $e');
      throw Exception('Failed to get lock save details: $e');
    }
  }

  /// Get lock save interest rate for duration
  Future<double> getLockSaveRate({
    required int durationDays,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('📊 Getting lock save rate for $durationDays days');

      // Prepare function call for get_lock_save_rate
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_lock_save_rate'),
        calldata: [Felt(BigInt.from(durationDays))],
      );

      // Call the contract
      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return response.when(
        result: (result) {
          if (result.isEmpty) {
            throw Exception('Invalid rate response');
          }

          // Rate is in basis points (10000 = 100%)
          final rateBasisPoints = result[0].toBigInt().toDouble();
          final ratePercent = rateBasisPoints / 100.0;

          print('✅ Lock save rate: $ratePercent% for $durationDays days');
          return ratePercent;
        },
        error: (error) {
          print('❌ Failed to get lock save rate: $error');
          throw Exception('Failed to get lock save rate: $error');
        },
      );
    } catch (e) {
      print('❌ Error getting lock save rate: $e');
      throw Exception('Failed to get lock save rate: $e');
    }
  }

  /// Calculate lock save maturity amount
  Future<Map<String, BigInt>> calculateLockSaveMaturity({
    required BigInt lockId,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('🧮 Calculating lock save maturity for ID: $lockId');

      // Convert BigInt lockId to u256 format (low, high)
      final low =
          Felt(lockId & BigInt.parse('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'));
      final high = Felt(lockId >> 128);

      // Prepare function call for calculate_lock_save_maturity
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('calculate_lock_save_maturity'),
        calldata: [low, high],
      );

      // Call the contract
      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return response.when(
        result: (result) {
          if (result.length < 2) {
            throw Exception('Invalid maturity calculation response');
          }

          final principal = result[0].toBigInt();
          final interest = result[1].toBigInt();
          final total = principal + interest;

          print(
              '✅ Maturity calculation - Principal: $principal, Interest: $interest, Total: $total');
          return {
            'principal': principal,
            'interest': interest,
            'total': total,
          };
        },
        error: (error) {
          print('❌ Failed to calculate lock save maturity: $error');
          throw Exception('Failed to calculate lock save maturity: $error');
        },
      );
    } catch (e) {
      print('❌ Error calculating lock save maturity: $e');
      throw Exception('Failed to calculate lock save maturity: $e');
    }
  }

  /// Get all lock saves for the current user
  Future<List<Map<String, dynamic>>> getUserLockSaves() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    final userAddress = account.accountAddress;

    try {
      print('🔍 Getting user lock saves for: ${userAddress.toHexString()}');

      // Get ongoing lock saves
      final ongoingFunctionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_user_ongoing_lock_saves'),
        calldata: [userAddress],
      );

      // Get matured lock saves
      final maturedFunctionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_user_matured_lock_saves'),
        calldata: [userAddress],
      );

      // Execute both calls
      final results = await Future.wait([
        account.provider
            .call(request: ongoingFunctionCall, blockId: BlockId.latest),
        account.provider
            .call(request: maturedFunctionCall, blockId: BlockId.latest),
      ]);

      final ongoingResponse = results[0];
      final maturedResponse = results[1];
      final lockSaves = <Map<String, dynamic>>[];

      // Parse ongoing lock saves
      await ongoingResponse.when(
        result: (result) async {
          final parsedLockSaves = await _parseLockSaveResults(result, false);
          lockSaves.addAll(parsedLockSaves);
        },
        error: (error) {
          print('❌ Failed to get ongoing lock saves: $error');
          throw Exception('Failed to get ongoing lock saves: $error');
        },
      );

      // Parse matured lock saves
      await maturedResponse.when(
        result: (result) async {
          final parsedLockSaves = await _parseLockSaveResults(result, true);
          lockSaves.addAll(parsedLockSaves);
        },
        error: (error) {
          print('❌ Failed to get matured lock saves: $error');
          throw Exception('Failed to get matured lock saves: $error');
        },
      );

      print('✅ Retrieved ${lockSaves.length} lock saves');
      return lockSaves;
    } catch (e) {
      print('❌ Error getting user lock saves: $e');
      throw Exception('Failed to get user lock saves: $e');
    }
  }

  /// Helper method to parse lock save results
// Replace your existing _parseLockSaveResults method with this one:
  Future<List<Map<String, dynamic>>> _parseLockSaveResults(
    List<Felt> result,
    bool isMatured,
  ) async {
    final lockSaves = <Map<String, dynamic>>[];

    if (result.isEmpty) {
      print('📝 No ${isMatured ? 'matured' : 'ongoing'} lock saves found');
      return lockSaves;
    }

    print(
        '🔍 Raw ${isMatured ? 'matured' : 'ongoing'} lock save result: $result');

    // In Starknet, Array<T> is serialized as [length, element1, element2, ...]
    // So we skip the first element (length) and start parsing from index 1
    if (result.isEmpty) {
      print('⚠️ Empty result array');
      return lockSaves;
    }

    final arrayLength = result[0].toBigInt().toInt();
    print('📏 Array length from contract: $arrayLength');

    const int structSize = 13;
    final dataStartIndex = 1; // Skip the length element
    final expectedTotalLength = dataStartIndex + (arrayLength * structSize);

    if (result.length != expectedTotalLength) {
      print(
          '⚠️ Warning: Expected length $expectedTotalLength, got ${result.length}');
    }

    for (int structIndex = 0; structIndex < arrayLength; structIndex++) {
      final i = dataStartIndex + (structIndex * structSize);
      if (i + structSize - 1 < result.length) {
        try {
          // Parse u256 fields (2 felts each)
          BigInt parseU256(int index) {
            final low = result[index].toBigInt();
            final high = result[index + 1].toBigInt();
            return low + (high << 128);
          }

          final lockId = parseU256(i); // id: u256
          final userAddress =
              result[i + 2].toHexString(); // user: ContractAddress
          final amount =
              parseU256(i + 3).toDouble() / pow(10, 6); // amount: u256
          final interestRate = parseU256(i + 5); // interest_rate: u256
          final lockDuration =
              result[i + 7].toBigInt().toInt(); // lock_duration: u64
          final startTime = result[i + 8].toBigInt().toInt(); // start_time: u64
          final maturityTime =
              result[i + 9].toBigInt().toInt(); // maturity_time: u64
          final titleFelt = result[i + 10].toBigInt(); // felt252

          String title;
          try {
            if (titleFelt == BigInt.zero) {
              title = 'Untitled';
            } else {
              title = _feltToString(titleFelt);
              if (title.isEmpty) title = 'Untitled';
            }
          } catch (e) {
            print('⚠️ Failed to convert title, using fallback: $e');
            title = 'Untitled Lock';
          }

          final isMaturedField =
              result[i + 11].toBigInt() == BigInt.one; // is_matured: bool
          final isWithdrawnField =
              result[i + 12].toBigInt() == BigInt.one; // is_withdrawn: bool

          final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final timeRemaining = math.max(0, maturityTime - currentTime);

          String status;
          if (isWithdrawnField) {
            status = 'completed';
          } else if (isMaturedField || currentTime >= maturityTime) {
            status = 'ready_to_withdraw';
          } else {
            status = 'ongoing';
          }

          String? maturityDateString;
          if (maturityTime > 0) {
            try {
              if (maturityTime < 1000000000) {
                print('⚠️ Warning: Invalid timestamp detected: $maturityTime');
                maturityDateString = 'Invalid Date';
              } else {
                final maturityDate =
                    DateTime.fromMillisecondsSinceEpoch(maturityTime * 1000);
                maturityDateString =
                    '${maturityDate.day.toString().padLeft(2, '0')}/${maturityDate.month.toString().padLeft(2, '0')}/${maturityDate.year}';
              }
            } catch (e) {
              print('⚠️ Error formatting maturity date: $e');
              maturityDateString = 'Invalid Date';
            }
          }

          final lockSave = {
            'id': lockId,
            'title': title,
            'amount': amount,
            'maturityDate': maturityDateString,
            'status': status,
            'isMatured': isMaturedField,
            'isWithdrawn': isWithdrawnField,
            'isExpired': currentTime >= maturityTime,
            'timeRemaining': timeRemaining,
            'duration': lockDuration,
            'startTime': startTime,
            'maturityTime': maturityTime,
            'interestRate': interestRate,
            'user': userAddress,
            'is_expired':
                DateTime.now().millisecondsSinceEpoch ~/ 1000 > maturityTime,
            'time_remaining': status == 'ongoing'
                ? math.max(
                    0,
                    maturityTime -
                        (DateTime.now().millisecondsSinceEpoch ~/ 1000))
                : 0,
          };

          lockSaves.add(lockSave);
          print(
              '✅ Parsed lock save: ID ${lockSave['id']}, Amount: ${lockSave['amount']}, Title: "${lockSave['title']}", Status: ${lockSave['status']}');
          print(
              '   Maturity Date: ${lockSave['maturityDate']}, Time Remaining: ${lockSave['timeRemaining']}s');
        } catch (e) {
          print('❌ Error parsing lock save at index $i: $e');
        }
      } else {
        print('⚠️ Incomplete struct data at index $i, skipping');
      }
    }

    return lockSaves;
  }

  String _feltToString(BigInt feltValue) {
    if (feltValue == BigInt.zero) return '';

    print('🔍 Converting felt252 to string: $feltValue (hex: 0x${feltValue.toRadixString(16)})');

    try {
      // Method 1: Extract bytes and convert to ASCII/UTF-8
      final bytes = <int>[];
      var value = feltValue;

      while (value > BigInt.zero) {
        final byte = (value & BigInt.from(0xFF)).toInt();
        if (byte != 0) {
          bytes.insert(0, byte);
        }
        value = value >> 8;
      }

      print('📝 Extracted bytes: $bytes');

      if (bytes.isNotEmpty) {
        // Try ASCII first (printable characters)
        final asciiChars = bytes.where((byte) => byte >= 32 && byte <= 126).toList();
        if (asciiChars.length == bytes.length) {
          final asciiResult = String.fromCharCodes(asciiChars);
          print('✅ ASCII conversion successful: "$asciiResult"');
          return asciiResult;
        }

        // Try UTF-8 conversion
        try {
          final utf8Result = String.fromCharCodes(bytes);
          if (utf8Result.isNotEmpty && !utf8Result.contains('\u{FFFD}')) {
            print('✅ UTF-8 conversion successful: "$utf8Result"');
            return utf8Result;
          }
        } catch (e) {
          print('⚠️ UTF-8 conversion failed: $e');
        }
      }

      // Method 2: Try direct character conversion for small values
      if (feltValue <= BigInt.from(1114111)) {
        try {
          final charResult = String.fromCharCode(feltValue.toInt());
          if (charResult.isNotEmpty && charResult.codeUnitAt(0) >= 32) {
            print('✅ Direct char conversion successful: "$charResult"');
            return charResult;
          }
        } catch (e) {
          print('⚠️ Direct char conversion failed: $e');
        }
      }

      // Method 3: Try hex string interpretation
      final hexString = feltValue.toRadixString(16);
      if (hexString.length % 2 == 0) {
        try {
          final hexBytes = <int>[];
          for (int i = 0; i < hexString.length; i += 2) {
            final hexByte = int.parse(hexString.substring(i, i + 2), radix: 16);
            if (hexByte >= 32 && hexByte <= 126) {
              hexBytes.add(hexByte);
            }
          }
          if (hexBytes.isNotEmpty) {
            final hexResult = String.fromCharCodes(hexBytes);
            print('✅ Hex string conversion successful: "$hexResult"');
            return hexResult;
          }
        } catch (e) {
          print('⚠️ Hex string conversion failed: $e');
        }
      }

      print('❌ All conversion methods failed, returning hex representation');
      return '0x${feltValue.toRadixString(16)}';
    } catch (e) {
      print('❌ Error converting Felt to string: $e');
      return '0x${feltValue.toRadixString(16)}';
    }
  }

  /// Get only ongoing lock saves
  Future<List<Map<String, dynamic>>> getOngoingLockSaves() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    final userAddress = account.accountAddress;

    try {
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_user_ongoing_lock_saves'),
        calldata: [userAddress],
      );

      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return await response.when(
        result: (result) => _parseLockSaveResults(result, false),
        error: (error) {
          print('❌ Failed to get ongoing lock saves: $error');
          throw Exception('Failed to get ongoing lock saves: $error');
        },
      );
    } catch (e) {
      print('❌ Error getting ongoing lock saves: $e');
      throw Exception('Failed to get ongoing lock saves: $e');
    }
  }

  /// Get only matured lock saves
  Future<List<Map<String, dynamic>>> getMaturedLockSaves() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    final userAddress = account.accountAddress;

    try {
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_user_matured_lock_saves'),
        calldata: [userAddress],
      );

      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return await response.when(
        result: (result) => _parseLockSaveResults(result, true),
        error: (error) {
          print('❌ Failed to get matured lock saves: $error');
          throw Exception('Failed to get matured lock saves: $error');
        },
      );
    } catch (e) {
      print('❌ Error getting matured lock saves: $e');
      throw Exception('Failed to get matured lock saves: $e');
    }
  }

  /// Auto-release matured lock saves for the current user
  Future<String?> autoReleaseMaturedLockSaves() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      print('❌ No wallet available for auto-release');
      return null;
    }

    try {
      print('🔄 Auto-releasing matured lock saves for user: ${account.accountAddress.toHexString()}');

      // Prepare auto_release_matured_lock_saves call data
      final calls = [
        {
          'contractAddress': _contractAddress.toHexString(),
          'entrypoint': 'auto_release_matured_lock_saves',
          'calldata': [
            account.accountAddress.toHexString(),
          ],
        },
      ];

      print('🔧 Building typed data with Avnu for auto-release...');

      // Build typed data with AVNU
      final avnuBuildTypeDataResponse =
          await _walletService.avnuProvider.buildTypedData(
        account.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        WalletService.argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        print('❌ Failed to build typed data for auto-release: $avnuBuildTypeDataResponse');
        return null; // Don't throw, just return null
      }

      final avnuTypedData =
          avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create owner account signer
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _walletService.ownerSigner!,
        guardianSigner: _walletService.guardianSigner!,
      );

      // Compute message hash and sign it
      final hash = avnuTypedData.hash(account.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing auto-release with Avnu...');

      // Execute the transaction via AVNU provider
      final avnuExecute = await _walletService.avnuProvider.execute(
        account.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        print('❌ Auto-release failed: $avnuExecute');
        return null; // Don't throw, just return null
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        print('❌ Auto-release transaction hash is null or empty');
        return null;
      }

      print('✅ Auto-release successful! TX: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ Error in auto-release: $e');
      return null; // Don't throw, just return null to avoid breaking the flow
    }
  }

  /// Get all goal saves for the current user
  Future<List<Map<String, dynamic>>> getUserGoalSaves() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      print('❌ CONTRACT SERVICE: Wallet not connected');
      return []; // Return empty list instead of throwing
    }

    final userAddress = account.accountAddress;

    try {
      print('🔍 CONTRACT SERVICE: Getting user goal saves for: ${userAddress.toHexString()}');

      // Get live goal saves
      final liveFunctionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_user_live_goal_saves'),
        calldata: [userAddress],
      );

      // Get completed goal saves
      final completedFunctionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_user_completed_goal_saves'),
        calldata: [userAddress],
      );

      // Execute both calls
      final results = await Future.wait([
        account.provider.call(request: liveFunctionCall, blockId: BlockId.latest),
        account.provider.call(request: completedFunctionCall, blockId: BlockId.latest),
      ]);

      final liveResponse = results[0];
      final completedResponse = results[1];
      final goalSaves = <Map<String, dynamic>>[];

      // Parse live goal saves
      await liveResponse.when(
        result: (result) async {
          print('📊 CONTRACT SERVICE: Live goal saves raw result length: ${result.length}');
          final parsedGoalSaves = await _parseGoalSaveResults(result, false);
          goalSaves.addAll(parsedGoalSaves);
          print('✅ CONTRACT SERVICE: Parsed ${parsedGoalSaves.length} live goal saves');
        },
        error: (error) {
          print('❌ CONTRACT SERVICE: Failed to get live goal saves: $error');
          // Don't throw, continue with completed saves
        },
      );

      // Parse completed goal saves
      await completedResponse.when(
        result: (result) async {
          print('📊 CONTRACT SERVICE: Completed goal saves raw result length: ${result.length}');
          final parsedGoalSaves = await _parseGoalSaveResults(result, true);
          goalSaves.addAll(parsedGoalSaves);
          print('✅ CONTRACT SERVICE: Parsed ${parsedGoalSaves.length} completed goal saves');
        },
        error: (error) {
          print('❌ CONTRACT SERVICE: Failed to get completed goal saves: $error');
          // Don't throw, return what we have
        },
      );

      print('✅ CONTRACT SERVICE: Retrieved total ${goalSaves.length} goal saves');
      return goalSaves;
    } catch (e) {
      print('❌ CONTRACT SERVICE: Error getting user goal saves: $e');
      return []; // Return empty list instead of throwing
    }
  }

  /// Helper method to parse goal save results
  Future<List<Map<String, dynamic>>> _parseGoalSaveResults(
    List<Felt> result,
    bool isCompleted,
  ) async {
    final goalSaves = <Map<String, dynamic>>[];

    if (result.isEmpty) {
      print('📝 No ${isCompleted ? 'completed' : 'live'} goal saves found');
      return goalSaves;
    }

    print('🔍 Raw ${isCompleted ? 'completed' : 'live'} goal save result: $result');

    // In Starknet, Array<T> is serialized as [length, element1, element2, ...]
    // So we skip the first element (length) and start parsing from index 1
    if (result.isEmpty) {
      print('⚠️ Empty result array');
      return goalSaves;
    }

    final arrayLength = result[0].toBigInt().toInt();
    print('📏 Array length from contract: $arrayLength');

    // GoalSave struct has 11 fields:
    // id(u256=2), user(1), title(1), category(1), target_amount(u256=2),
    // current_amount(u256=2), contribution_type(1), contribution_amount(u256=2),
    // start_time(1), end_time(1), is_completed(1) = 13 total felts
    const int structSize = 13;
    final dataStartIndex = 1; // Skip the length element
    final expectedTotalLength = dataStartIndex + (arrayLength * structSize);

    if (result.length != expectedTotalLength) {
      print('⚠️ Warning: Expected length $expectedTotalLength, got ${result.length}');
    }

    for (int structIndex = 0; structIndex < arrayLength; structIndex++) {
      final i = dataStartIndex + (structIndex * structSize);
      print('🔍 Parsing GoalSave struct $structIndex at index $i');
      
      if (i + structSize - 1 < result.length) {
        try {
          // Parse u256 fields (2 felts each)
          BigInt parseU256(int index) {
            if (index + 1 >= result.length) {
              print('❌ Index out of bounds for u256 at $index');
              return BigInt.zero;
            }
            final low = result[index].toBigInt();
            final high = result[index + 1].toBigInt();
            final value = low + (high << 128);
            print('📊 u256 at index $index: low=$low, high=$high, result=$value');
            return value;
          }

          // Parse according to GoalSave struct field order:
          // id(u256), user(ContractAddress), title(felt252), category(felt252),
          // target_amount(u256), current_amount(u256), contribution_type(u8),
          // contribution_amount(u256), start_time(u64), end_time(u64), is_completed(bool)
          
          final id = parseU256(i); // id: u256 (2 felts)
          final user = result[i + 2].toHexString(); // user: ContractAddress (1 felt)
          final titleFelt = result[i + 3].toBigInt(); // title: felt252 (1 felt)
          final categoryFelt = result[i + 4].toBigInt(); // category: felt252 (1 felt)
          final targetAmount = parseU256(i + 5).toDouble() / pow(10, 6); // target_amount: u256 (2 felts)
          final currentAmount = parseU256(i + 7).toDouble() / pow(10, 6); // current_amount: u256 (2 felts)
          final contributionType = result[i + 9].toBigInt().toInt(); // contribution_type: u8 (1 felt)
          final contributionAmount = parseU256(i + 10).toDouble() / pow(10, 6); // contribution_amount: u256 (2 felts)
          final startTime = result[i + 12].toBigInt().toInt(); // start_time: u64 (1 felt)
          final endTime = result[i + 13].toBigInt().toInt(); // end_time: u64 (1 felt)
          final isCompletedField = isCompleted; // Use the parameter since this field might not be in the struct

          print('📋 Parsed GoalSave fields:');
          print('   ID: $id');
          print('   User: $user');
          print('   Title felt: $titleFelt');
          print('   Category felt: $categoryFelt');
          print('   Target Amount: $targetAmount USDC');
          print('   Current Amount: $currentAmount USDC');
          print('   Contribution Type: $contributionType');
          print('   Contribution Amount: $contributionAmount USDC');
          print('   Start Time: $startTime');
          print('   End Time: $endTime');
          print('   Is Completed: $isCompletedField');

          // Convert felt252 values to strings
          String title;
          try {
            if (titleFelt == BigInt.zero) {
              title = 'Untitled';
            } else {
              title = _feltToString(titleFelt);
              if (title.isEmpty) title = 'Untitled';
            }
          } catch (e) {
            print('⚠️ Failed to convert title, using fallback: $e');
            title = 'Untitled Goal';
          }

          String category;
          try {
            if (categoryFelt == BigInt.zero) {
              category = 'General';
            } else {
              category = _feltToString(categoryFelt);
              if (category.isEmpty) category = 'General';
            }
          } catch (e) {
            print('⚠️ Failed to convert category, using fallback: $e');
            category = 'General';
          }

          final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final progressPercentage = targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0.0, 100.0) : 0.0;
          final amountRemaining = (targetAmount - currentAmount).clamp(0.0, double.infinity);

          String status;
          if (isCompletedField) {
            status = 'completed';
          } else if (currentTime >= endTime) {
            status = 'expired';
          } else if (currentAmount >= targetAmount) {
            status = 'target_reached';
          } else {
            status = 'active';
          }

          final goalSave = {
            'id': id,
            'user': user,
            'title': title,
            'category': category,
            'target_amount': targetAmount,
            'current_amount': currentAmount,
            'contribution_type': contributionType,
            'contribution_amount': contributionAmount,
            'start_time': startTime,
            'end_time': endTime,
            'is_completed': isCompletedField,
            'status': status,
            'progress_percentage': progressPercentage,
            'amount_remaining': amountRemaining,
          };

          goalSaves.add(goalSave);
          print('✅ Successfully parsed GoalSave: $title - $currentAmount/$targetAmount USDC');

        } catch (e) {
          print('❌ Error parsing GoalSave struct at index $i: $e');
          continue;
        }
      } else {
        print('⚠️ Incomplete struct data at index $i, skipping');
      }
    }

    return goalSaves;
  }

  /// Create a goal save
  Future<String> createGoalSave({
    required String title,
    required String category,
    required double targetAmount,
    required int contributionType, // 1=daily, 2=weekly, 3=monthly, 4=manual
    required double contributionAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('🎯 Creating goal save: $title, Target: $targetAmount USDC');

      // Convert amounts to raw USDC units (6 decimals)
      final rawTargetAmount = BigInt.from((targetAmount * pow(10, 6)).round());
      final rawContributionAmount =
          BigInt.from((contributionAmount * pow(10, 6)).round());
      print(
          '📊 Raw target amount: $rawTargetAmount, Raw contribution: $rawContributionAmount');

      // Convert title and category to felt252
      final titleFelt =
          Felt.fromString(title.length > 31 ? title.substring(0, 31) : title);
      final categoryFelt = Felt.fromString(
          category.length > 31 ? category.substring(0, 31) : category);

      // Convert dates to timestamps
      final startTimestamp = (startDate.millisecondsSinceEpoch / 1000).round();
      final endTimestamp = (endDate.millisecondsSinceEpoch / 1000).round();

      // Check current allowance for the contract
      final currentAllowance = await getUsdcAllowance(
        ownerAddress: account.accountAddress.toHexString(),
        spenderAddress: _contractAddress.toHexString(),
      );

      // If allowance is insufficient, approve first
      if (currentAllowance < contributionAmount) {
        print(
            '🔓 Insufficient allowance (${_walletService.formatUsdcBalance(currentAllowance)}), approving ${_walletService.formatUsdcBalance(contributionAmount)} USDC...');
        await _walletService.approveUsdc(
          spenderAddress: _contractAddress.toHexString(),
          amount: contributionAmount,
        );
        print('✅ USDC approval completed');

        // Small delay to ensure approval is processed
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Prepare create_goal_save call data
      final calls = [
        {
          'contractAddress': _contractAddress.toHexString(),
          'entrypoint': 'create_goal_save',
          'calldata': [
            '0x${titleFelt.toBigInt().toRadixString(16)}',
            '0x${categoryFelt.toBigInt().toRadixString(16)}',
            '0x${rawTargetAmount.toRadixString(16)}',
            '0x0', // target_amount.high (assuming < 2^128)
            '0x${contributionType.toRadixString(16)}',
            '0x${rawContributionAmount.toRadixString(16)}',
            '0x0', // contribution_amount.high (assuming < 2^128)
            '0x${startTimestamp.toRadixString(16)}',
            '0x${endTimestamp.toRadixString(16)}',
          ],
        },
      ];

      print('🔧 Building typed data with Avnu for goal save creation...');

      // Build typed data with AVNU
      final avnuBuildTypeDataResponse =
          await _walletService.avnuProvider.buildTypedData(
        account.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        WalletService.argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        throw Exception(
            'Failed to build typed data: $avnuBuildTypeDataResponse');
      }

      final avnuTypedData =
          avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create owner account signer
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _walletService.ownerSigner!,
        guardianSigner: _walletService.guardianSigner!,
      );

      // Compute message hash and sign it
      final hash = avnuTypedData.hash(account.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing goal save creation with Avnu...');

      // Execute the transaction via AVNU provider
      final avnuExecute = await _walletService.avnuProvider.execute(
        account.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        throw Exception('Goal save creation failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        throw Exception('Transaction hash is null or empty');
      }

      print('✅ Goal save created successfully! TX: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ Goal save creation error: $e');
      throw Exception('Failed to create goal save: $e');
    }
  }

  /// Contribute to a goal save
  Future<String> contributeGoalSave({
    required BigInt goalId,
    required double amount,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('💰 Contributing $amount USDC to goal save ID: $goalId');

      // Convert amount to raw USDC units (6 decimals)
      final rawAmount = BigInt.from((amount * pow(10, 6)).round());
      print('📊 Raw contribution amount: $rawAmount (${amount} USDC)');

      // Check USDC balance before contributing
      final currentBalance = await _walletService.getUsdcBalance();
      if (currentBalance < amount) {
        throw Exception(
            'Insufficient USDC balance. Available: ${_walletService.formatUsdcBalance(currentBalance)}, Required: ${_walletService.formatUsdcBalance(amount)}');
      }

      // Check current allowance for the contract
      final currentAllowance = await getUsdcAllowance(
        ownerAddress: account.accountAddress.toHexString(),
        spenderAddress: _contractAddress.toHexString(),
      );

      // If allowance is insufficient, approve first
      if (currentAllowance < amount) {
        print(
            '🔓 Insufficient allowance (${_walletService.formatUsdcBalance(currentAllowance)}), approving ${_walletService.formatUsdcBalance(amount)} USDC...');
        await _walletService.approveUsdc(
          spenderAddress: _contractAddress.toHexString(),
          amount: amount,
        );
        print('✅ USDC approval completed');

        // Small delay to ensure approval is processed
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Convert BigInt goalId to u256 format (low, high)
      final low = goalId & BigInt.parse('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
      final high = goalId >> 128;

      // Prepare contribute_goal_save call data
      final calls = [
        {
          'contractAddress': _contractAddress.toHexString(),
          'entrypoint': 'contribute_goal_save',
          'calldata': [
            '0x${low.toRadixString(16)}',
            '0x${high.toRadixString(16)}',
            '0x${rawAmount.toRadixString(16)}',
            '0x0', // amount.high (assuming < 2^128)
          ],
        },
      ];

      print('🔧 Building typed data with Avnu for goal contribution...');

      // Build typed data with AVNU
      final avnuBuildTypeDataResponse =
          await _walletService.avnuProvider.buildTypedData(
        account.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        WalletService.argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        throw Exception(
            'Failed to build typed data: $avnuBuildTypeDataResponse');
      }

      final avnuTypedData =
          avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create owner account signer
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _walletService.ownerSigner!,
        guardianSigner: _walletService.guardianSigner!,
      );

      // Compute message hash and sign it
      final hash = avnuTypedData.hash(account.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing goal contribution with Avnu...');

      // Execute the transaction via AVNU provider
      final avnuExecute = await _walletService.avnuProvider.execute(
        account.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        throw Exception('Goal contribution failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        throw Exception('Transaction hash is null or empty');
      }

      print('✅ Goal contribution successful! TX: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ Goal contribution error: $e');
      throw Exception('Failed to contribute to goal save: $e');
    }
  }

  /// Get goal save details
  Future<Map<String, dynamic>> getGoalSave({
    required BigInt goalId,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('🔍 Getting goal save details for ID: $goalId');

      // Convert BigInt goalId to u256 format (low, high)
      final low = goalId & BigInt.parse('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
      final high = goalId >> 128;

      // Prepare function call for get_goal_save
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_goal_save'),
        calldata: [Felt(low), Felt(high)],
      );

      // Call the contract
      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return response.when(
        result: (result) {
          print('📊 Goal save result: $result');

          if (result.length < 10) {
            throw Exception('Invalid goal save response');
          }

          // Parse the GoalSave struct
          final goalSaveData = {
            'id': result[0].toBigInt(),
            'user': result[1].toHexString(),
            'title': result[2].toString(), // felt252
            'category': result[3].toString(), // felt252
            'target_amount': result[4].toBigInt(),
            'current_amount': result[5].toBigInt(),
            'contribution_type': result[6].toBigInt().toInt(),
            'contribution_amount': result[7].toBigInt(),
            'start_time': result[8].toBigInt().toInt(),
            'end_time': result[9].toBigInt().toInt(),
            'is_completed': result.length > 10
                ? result[10].toBigInt() == BigInt.one
                : false,
          };

          print('✅ Goal save details retrieved: $goalSaveData');
          return goalSaveData;
        },
        error: (error) {
          print('❌ Failed to get goal save: $error');
          throw Exception('Failed to get goal save: $error');
        },
      );
    } catch (e) {
      print('❌ Error getting goal save details: $e');
      throw Exception('Failed to get goal save details: $e');
    }
  }

  /// Create a group save (public or private)
  Future<String> createGroupSave({
    required String title,
    required String description,
    required String category,
    required double targetAmount,
    required int contributionType, // 1=daily, 2=weekly, 3=monthly, 4=manual
    required double contributionAmount,
    required bool isPublic,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print(
          '👥 Creating ${isPublic ? 'public' : 'private'} group save: $title, Target: $targetAmount USDC');

      // Convert amounts to raw USDC units (6 decimals)
      final rawTargetAmount = BigInt.from((targetAmount * pow(10, 6)).round());
      final rawContributionAmount =
          BigInt.from((contributionAmount * pow(10, 6)).round());
      print(
          '📊 Raw target amount: $rawTargetAmount, Raw contribution: $rawContributionAmount');

      // Convert strings to felt252
      final titleFelt =
          Felt.fromString(title.length > 31 ? title.substring(0, 31) : title);
      final descriptionFelt = Felt.fromString(
          description.length > 31 ? description.substring(0, 31) : description);
      final categoryFelt = Felt.fromString(
          category.length > 31 ? category.substring(0, 31) : category);

      // Convert dates to timestamps
      final startTimestamp = (startDate.millisecondsSinceEpoch / 1000).round();
      final endTimestamp = (endDate.millisecondsSinceEpoch / 1000).round();

      // Check current allowance for the contract
      final currentAllowance = await getUsdcAllowance(
        ownerAddress: account.accountAddress.toHexString(),
        spenderAddress: _contractAddress.toHexString(),
      );

      // If allowance is insufficient, approve first
      if (currentAllowance < contributionAmount) {
        print(
            '🔓 Insufficient allowance (${_walletService.formatUsdcBalance(currentAllowance)}), approving ${_walletService.formatUsdcBalance(contributionAmount)} USDC...');
        await _walletService.approveUsdc(
          spenderAddress: _contractAddress.toHexString(),
          amount: contributionAmount,
        );
        print('✅ USDC approval completed');

        // Small delay to ensure approval is processed
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Prepare create_group_save call data
      final calls = [
        {
          'contractAddress': _contractAddress.toHexString(),
          'entrypoint': 'create_group_save',
          'calldata': [
            '0x${titleFelt.toBigInt().toRadixString(16)}',
            '0x${descriptionFelt.toBigInt().toRadixString(16)}',
            '0x${categoryFelt.toBigInt().toRadixString(16)}',
            '0x${rawTargetAmount.toRadixString(16)}',
            '0x0', // target_amount.high (assuming < 2^128)
            '0x${contributionType.toRadixString(16)}',
            '0x${rawContributionAmount.toRadixString(16)}',
            '0x0', // contribution_amount.high (assuming < 2^128)
            isPublic ? '0x1' : '0x0', // is_public as bool
            '0x${startTimestamp.toRadixString(16)}',
            '0x${endTimestamp.toRadixString(16)}',
          ],
        },
      ];

      print('🔧 Building typed data with Avnu for group save creation...');

      // Build typed data with AVNU
      final avnuBuildTypeDataResponse =
          await _walletService.avnuProvider.buildTypedData(
        account.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        WalletService.argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        throw Exception(
            'Failed to build typed data: $avnuBuildTypeDataResponse');
      }

      final avnuTypedData =
          avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create owner account signer
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _walletService.ownerSigner!,
        guardianSigner: _walletService.guardianSigner!,
      );

      // Compute message hash and sign it
      final hash = avnuTypedData.hash(account.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing group save creation with Avnu...');

      // Execute the transaction via AVNU provider
      final avnuExecute = await _walletService.avnuProvider.execute(
        account.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        throw Exception('Group save creation failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        throw Exception('Transaction hash is null or empty');
      }

      print('✅ Group save created successfully! TX: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ Group save creation error: $e');
      throw Exception('Failed to create group save: $e');
    }
  }

  /// Join a group save
  Future<String> joinGroupSave({
    required BigInt groupId,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('🤝 Joining group save ID: $groupId');

      // Convert BigInt groupId to u256 format (low, high)
      final low = groupId & BigInt.parse('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
      final high = groupId >> 128;

      // Prepare join_group_save call data
      final calls = [
        {
          'contractAddress': _contractAddress.toHexString(),
          'entrypoint': 'join_group_save',
          'calldata': [
            '0x${low.toRadixString(16)}',
            '0x${high.toRadixString(16)}',
          ],
        },
      ];

      print('🔧 Building typed data with Avnu for joining group save...');

      // Build typed data with AVNU
      final avnuBuildTypeDataResponse =
          await _walletService.avnuProvider.buildTypedData(
        account.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        WalletService.argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        throw Exception(
            'Failed to build typed data: $avnuBuildTypeDataResponse');
      }

      final avnuTypedData =
          avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create owner account signer
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _walletService.ownerSigner!,
        guardianSigner: _walletService.guardianSigner!,
      );

      // Compute message hash and sign it
      final hash = avnuTypedData.hash(account.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing join group save with Avnu...');

      // Execute the transaction via AVNU provider
      final avnuExecute = await _walletService.avnuProvider.execute(
        account.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        throw Exception('Join group save failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        throw Exception('Transaction hash is null or empty');
      }

      print('✅ Joined group save successfully! TX: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ Join group save error: $e');
      throw Exception('Failed to join group save: $e');
    }
  }

  /// Contribute to a group save
  Future<String> contributeToGroupSave({
    required BigInt groupId,
    required double amount,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('💰 Contributing $amount USDC to group save ID: $groupId');

      // Convert amount to raw USDC units (6 decimals)
      final rawAmount = BigInt.from((amount * pow(10, 6)).round());
      print('📊 Raw contribution amount: $rawAmount (${amount} USDC)');

      // Check current allowance for the contract
      final currentAllowance = await getUsdcAllowance(
        ownerAddress: account.accountAddress.toHexString(),
        spenderAddress: _contractAddress.toHexString(),
      );

      // If allowance is insufficient, approve first
      if (currentAllowance < amount) {
        print(
            '🔓 Insufficient allowance (${_walletService.formatUsdcBalance(currentAllowance)}), approving ${_walletService.formatUsdcBalance(amount)} USDC...');
        await _walletService.approveUsdc(
          spenderAddress: _contractAddress.toHexString(),
          amount: amount,
        );
        print('✅ USDC approval completed');

        // Small delay to ensure approval is processed
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Convert BigInt groupId to u256 format (low, high)
      final low = groupId & BigInt.parse('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
      final high = groupId >> 128;

      // Prepare contribute_to_group_save call data
      final calls = [
        {
          'contractAddress': _contractAddress.toHexString(),
          'entrypoint': 'contribute_to_group_save',
          'calldata': [
            '0x${low.toRadixString(16)}',
            '0x${high.toRadixString(16)}',
            '0x${rawAmount.toRadixString(16)}',
            '0x0', // amount.high (assuming < 2^128)
          ],
        },
      ];

      print('🔧 Building typed data with Avnu for group contribution...');

      // Build typed data with AVNU
      final avnuBuildTypeDataResponse =
          await _walletService.avnuProvider.buildTypedData(
        account.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        WalletService.argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        throw Exception(
            'Failed to build typed data: $avnuBuildTypeDataResponse');
      }

      final avnuTypedData =
          avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create owner account signer
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _walletService.ownerSigner!,
        guardianSigner: _walletService.guardianSigner!,
      );

      // Compute message hash and sign it
      final hash = avnuTypedData.hash(account.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing group contribution with Avnu...');

      // Execute the transaction via AVNU provider
      final avnuExecute = await _walletService.avnuProvider.execute(
        account.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        throw Exception('Group contribution failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        throw Exception('Transaction hash is null or empty');
      }

      print('✅ Group contribution successful! TX: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ Group contribution error: $e');
      throw Exception('Failed to contribute to group save: $e');
    }
  }

  /// Get group save details
  Future<Map<String, dynamic>> getGroupSave({
    required BigInt groupId,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('🔍 Getting group save details for ID: $groupId');

      // Convert BigInt groupId to u256 format (low, high)
      final low = groupId & BigInt.parse('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
      final high = groupId >> 128;

      // Prepare function call for get_group_save
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_group_save'),
        calldata: [Felt(low), Felt(high)],
      );

      // Call the contract
      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return response.when(
        result: (result) {
          print('📊 Group save result: $result');

          if (result.length < 12) {
            throw Exception('Invalid group save response');
          }

          // Parse the GroupSave struct with correct field alignment
          // GroupSave: id(u256=2), creator(1), title(1), description(1), category(1),
          // target_amount(u256=2), current_amount(u256=2), contribution_type(1),
          // contribution_amount(u256=2), is_public(1), member_count(u256=2),
          // start_time(1), end_time(1), is_completed(1) = 19 total felts
          
          if (result.length < 19) {
            throw Exception('Invalid group save response: expected 19 felts, got ${result.length}');
          }

          // Parse u256 fields (2 felts each)
          BigInt parseU256(int index) {
            final low = result[index].toBigInt();
            final high = result[index + 1].toBigInt();
            return low + (high << 128);
          }

          final id = parseU256(0); // id: u256 (2 felts)
          final creator = result[2].toHexString(); // creator: ContractAddress (1 felt)
          final titleFelt = result[3].toBigInt(); // title: felt252 (1 felt)
          final descriptionFelt = result[4].toBigInt(); // description: felt252 (1 felt)
          final categoryFelt = result[5].toBigInt(); // category: felt252 (1 felt)
          final targetAmount = parseU256(6).toDouble() / pow(10, 6); // target_amount: u256 (2 felts)
          final currentAmount = parseU256(8).toDouble() / pow(10, 6); // current_amount: u256 (2 felts)
          final contributionType = result[10].toBigInt().toInt(); // contribution_type: u8 (1 felt)
          final contributionAmount = parseU256(11).toDouble() / pow(10, 6); // contribution_amount: u256 (2 felts)
          final isPublic = result[13].toBigInt() == BigInt.one; // is_public: bool (1 felt)
          final memberCount = parseU256(14); // member_count: u256 (2 felts)
          final startTime = result[16].toBigInt().toInt(); // start_time: u64 (1 felt)
          final endTime = result[17].toBigInt().toInt(); // end_time: u64 (1 felt)
          final isCompleted = result[18].toBigInt() == BigInt.one; // is_completed: bool (1 felt)

          // Convert felt252 values to strings
          String title;
          try {
            title = titleFelt == BigInt.zero ? 'Untitled' : _feltToString(titleFelt);
            if (title.isEmpty) title = 'Untitled';
          } catch (e) {
            title = 'Untitled Group';
          }

          String description;
          try {
            description = descriptionFelt == BigInt.zero ? 'No description' : _feltToString(descriptionFelt);
            if (description.isEmpty) description = 'No description';
          } catch (e) {
            description = 'No description';
          }

          String category;
          try {
            category = categoryFelt == BigInt.zero ? 'General' : _feltToString(categoryFelt);
            if (category.isEmpty) category = 'General';
          } catch (e) {
            category = 'General';
          }

          final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final progressPercentage = targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0.0, 100.0) : 0.0;
          final amountRemaining = (targetAmount - currentAmount).clamp(0.0, double.infinity);

          String status;
          if (isCompleted) {
            status = 'completed';
          } else if (currentTime >= endTime) {
            status = 'expired';
          } else if (currentAmount >= targetAmount) {
            status = 'target_reached';
          } else {
            status = 'active';
          }

          // Convert timestamps to formatted date strings
          String formatDate(int timestamp) {
            try {
              final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
              final day = date.day;
              final month = [
                '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
              ][date.month];
              final year = date.year;
              
              String dayWithSuffix;
              if (day >= 11 && day <= 13) {
                dayWithSuffix = '${day}th';
              } else {
                switch (day % 10) {
                  case 1:
                    dayWithSuffix = '${day}st';
                    break;
                  case 2:
                    dayWithSuffix = '${day}nd';
                    break;
                  case 3:
                    dayWithSuffix = '${day}rd';
                    break;
                  default:
                    dayWithSuffix = '${day}th';
                }
              }
              
              return '$dayWithSuffix $month $year';
            } catch (e) {
              print('Error formatting date for timestamp $timestamp: $e');
              return 'Invalid Date';
            }
          }

          print('🔍 Debug timestamps - startTime: $startTime, endTime: $endTime');
          final startDate = formatDate(startTime);
          final endDate = formatDate(endTime);
          print('🔍 Debug formatted dates - startDate: $startDate, endDate: $endDate');

          // Calculate days left
          final endDateTime = DateTime.fromMillisecondsSinceEpoch(endTime * 1000);
          final now = DateTime.now();
          final daysDifference = endDateTime.difference(now).inDays;
          final daysLeft = daysDifference > 0 ? daysDifference : 0;

          final groupSaveData = {
            'id': id,
            'creator': creator,
            'title': title,
            'name': title, // Add name alias for UI compatibility
            'description': description,
            'category': category,
            'targetAmount': targetAmount,
            'currentAmount': currentAmount,
            'contributionType': contributionType,
            'contributionAmount': contributionAmount,
            'isPublic': isPublic,
            'memberCount': memberCount.toInt(),
            'startTime': startTime,
            'endTime': endTime,
            'startDate': startDate,
            'endDate': endDate,
            'daysLeft': daysLeft,
            'isCompleted': isCompleted,
            'status': status,
            'progressPercentage': progressPercentage,
            'amountRemaining': amountRemaining,
            // Add frequency mapping based on contribution type
            'frequency': contributionType == 1 ? 'Daily' : contributionType == 2 ? 'Weekly' : contributionType == 3 ? 'Monthly' : 'Manual',
          };

          print('✅ Group save details retrieved: $groupSaveData');
          return groupSaveData;
        },
        error: (error) {
          print('❌ Failed to get group save: $error');
          throw Exception('Failed to get group save: $error');
        },
      );
    } catch (e) {
      print('❌ Error getting group save details: $e');
      throw Exception('Failed to get group save details: $e');
    }
  }

  /// Break a group save (creator only)
  Future<String> breakGroupSave({
    required BigInt groupId,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('💥 Breaking group save ID: $groupId');

      // Convert BigInt groupId to u256 format (low, high)
      final low = groupId & BigInt.parse('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
      final high = groupId >> 128;

      // Prepare break_group_save call data
      final calls = [
        {
          'contractAddress': _contractAddress.toHexString(),
          'entrypoint': 'break_group_save',
          'calldata': [
            '0x${low.toRadixString(16)}',
            '0x${high.toRadixString(16)}',
          ],
        },
      ];

      print('🔧 Building typed data with Avnu for group break...');

      // Build typed data with AVNU
      final avnuBuildTypeDataResponse = await _walletService.avnuProvider.buildTypedData(
        account.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        WalletService.argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        throw Exception('Failed to build typed data: $avnuBuildTypeDataResponse');
      }

      final avnuTypedData = avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create account signer
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _walletService.ownerSigner!,
        guardianSigner: _walletService.guardianSigner!,
      );

      // Compute message hash and sign it
      final hash = avnuTypedData.hash(account.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing group break with Avnu...');

      // Execute the transaction via AVNU provider
      final avnuExecute = await _walletService.avnuProvider.execute(
        account.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        throw Exception('Group break failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        throw Exception('Transaction hash is null or empty');
      }

      print('✅ Break group save transaction submitted: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ Error breaking group save: $e');
      throw Exception('Failed to break group save: $e');
    }
  }

  /// Check if user is a member of a group save
  Future<bool> isGroupMember({
    required BigInt groupId,
    required String userAddress,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      // Convert BigInt groupId to u256 format (low, high)
      final groupLow =
          groupId & BigInt.parse('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
      final groupHigh = groupId >> 128;

      final user = Felt.fromHexString(userAddress);

      // Prepare function call for is_group_member
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('is_group_member'),
        calldata: [Felt(groupLow), Felt(groupHigh), user],
      );

      // Call the contract
      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return response.when(
        result: (result) {
          if (result.isEmpty) {
            return false;
          }
          return result[0].toBigInt() == BigInt.one;
        },
        error: (error) => false,
      );
    } catch (e) {
      print('❌ Error checking group membership: $e');
      return false;
    }
  }

  /// Get user's contribution to a group save
  Future<BigInt> getGroupMemberContribution({
    required BigInt groupId,
    required String userAddress,
  }) async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      // Convert BigInt groupId to u256 format (low, high)
      final groupLow =
          groupId & BigInt.parse('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
      final groupHigh = groupId >> 128;

      final user = Felt.fromHexString(userAddress);

      // Prepare function call for get_group_member_contribution
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_group_member_contribution'),
        calldata: [Felt(groupLow), Felt(groupHigh), user],
      );

      // Call the contract
      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return response.when(
        result: (result) {
          if (result.length < 2) {
            return BigInt.zero;
          }
          // Combine low and high parts for u256
          final low = result[0].toBigInt();
          final high = result[1].toBigInt();
          return low + (high << 128);
        },
        error: (error) => BigInt.zero,
      );
    } catch (e) {
      print('❌ Error getting group member contribution: $e');
      return BigInt.zero;
    }
  }

  /// Get group save rate
  Future<double> getGroupSaveRate() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    try {
      print('📊 Getting group save rate');

      // Prepare function call for get_group_save_rate
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_group_save_rate'),
        calldata: [],
      );

      // Call the contract
      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return response.when(
        result: (result) {
          if (result.isEmpty) {
            throw Exception('Invalid rate response');
          }

          // Rate is in basis points (10000 = 100%)
          final rateBasisPoints = result[0].toBigInt().toDouble();
          final ratePercent = rateBasisPoints / 100.0;

          print('✅ Group save rate: $ratePercent%');
          return ratePercent;
        },
        error: (error) {
          print('❌ Failed to get group save rate: $error');
          throw Exception('Failed to get group save rate: $error');
        },
      );
    } catch (e) {
      print('❌ Error getting group save rate: $e');
      throw Exception('Failed to get group save rate: $e');
    }
  }

  /// Get all group saves for the current user
  Future<List<Map<String, dynamic>>> getUserGroupSaves() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      print('❌ CONTRACT SERVICE: Wallet not connected');
      return []; // Return empty list instead of throwing
    }

    final userAddress = account.accountAddress;

    try {
      print(
          '🔍 CONTRACT SERVICE: Getting user group saves for: ${userAddress.toHexString()}');

      // Get live group saves
      final liveFunctionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_user_live_group_saves'),
        calldata: [userAddress],
      );

      // Get completed group saves
      final completedFunctionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_user_completed_group_saves'),
        calldata: [userAddress],
      );

      // Execute both calls
      final results = await Future.wait([
        account.provider
            .call(request: liveFunctionCall, blockId: BlockId.latest),
        account.provider
            .call(request: completedFunctionCall, blockId: BlockId.latest),
      ]);

      final liveResponse = results[0];
      final completedResponse = results[1];
      final groupSaves = <Map<String, dynamic>>[];

      // Parse live group saves
      await liveResponse.when(
        result: (result) async {
          print(
              '📊 CONTRACT SERVICE: Live group saves raw result length: ${result.length}');
          final parsedGroupSaves = await _parseGroupSaveResults(result, false);
          groupSaves.addAll(parsedGroupSaves);
          print(
              '✅ CONTRACT SERVICE: Parsed ${parsedGroupSaves.length} live group saves');
        },
        error: (error) {
          print('❌ CONTRACT SERVICE: Failed to get live group saves: $error');
          // Don't throw, continue with completed saves
        },
      );

      // Parse completed group saves
      await completedResponse.when(
        result: (result) async {
          print(
              '📊 CONTRACT SERVICE: Completed group saves raw result length: ${result.length}');
          final parsedGroupSaves = await _parseGroupSaveResults(result, true);
          groupSaves.addAll(parsedGroupSaves);
          print(
              '✅ CONTRACT SERVICE: Parsed ${parsedGroupSaves.length} completed group saves');
        },
        error: (error) {
          print(
              '❌ CONTRACT SERVICE: Failed to get completed group saves: $error');
          // Don't throw, return what we have
        },
      );

      print(
          '✅ CONTRACT SERVICE: Retrieved total ${groupSaves.length} group saves');
      return groupSaves;
    } catch (e) {
      print('❌ CONTRACT SERVICE: Error getting user group saves: $e');
      return []; // Return empty list instead of throwing
    }
  }

  /// Helper method to parse group save results
  Future<List<Map<String, dynamic>>> _parseGroupSaveResults(
    List<Felt> result,
    bool isCompleted,
  ) async {
    final groupSaves = <Map<String, dynamic>>[];

    if (result.isEmpty) {
      print('📝 No ${isCompleted ? 'completed' : 'live'} group saves found');
      return groupSaves;
    }

    print(
        '🔍 Raw ${isCompleted ? 'completed' : 'live'} group save result: $result');

    // In Starknet, Array<T> is serialized as [length, element1, element2, ...]
    // So we skip the first element (length) and start parsing from index 1
    if (result.isEmpty) {
      print('⚠️ Empty result array');
      return groupSaves;
    }

    final arrayLength = result[0].toBigInt().toInt();
    print('📏 Array length from contract: $arrayLength');

    // GroupSave struct has 14 fields:
    // id(u256=2), creator(1), title(1), description(1), category(1),
    // target_amount(u256=2), current_amount(u256=2), contribution_type(1),
    // contribution_amount(u256=2), is_public(1), member_count(u256=2),
    // start_time(1), end_time(1), is_completed(1) = 19 total felts
    const int structSize = 19;
    final dataStartIndex = 1; // Skip the length element
    final expectedTotalLength = dataStartIndex + (arrayLength * structSize);

    if (result.length != expectedTotalLength) {
      print(
          '⚠️ Warning: Expected length $expectedTotalLength, got ${result.length}');
    }

    for (int structIndex = 0; structIndex < arrayLength; structIndex++) {
      final i = dataStartIndex + (structIndex * structSize);
      print('🔍 Parsing GroupSave struct $structIndex at index $i');
      
      if (i + structSize - 1 < result.length) {
        try {
          // Parse u256 fields (2 felts each)
          BigInt parseU256(int index) {
            if (index + 1 >= result.length) {
              print('❌ Index out of bounds for u256 at $index');
              return BigInt.zero;
            }
            final low = result[index].toBigInt();
            final high = result[index + 1].toBigInt();
            final value = low + (high << 128);
            print('📊 u256 at index $index: low=$low, high=$high, result=$value');
            return value;
          }

          // Parse according to GroupSave struct field order:
          // id(u256), creator(ContractAddress), title(felt252), description(felt252), category(felt252),
          // target_amount(u256), current_amount(u256), contribution_type(u8),
          // contribution_amount(u256), is_public(bool), member_count(u256),
          // start_time(u64), end_time(u64), is_completed(bool)
          
          final id = parseU256(i); // id: u256 (2 felts)
          final creator = result[i + 2].toHexString(); // creator: ContractAddress (1 felt)
          final titleFelt = result[i + 3].toBigInt(); // title: felt252 (1 felt)
          final descriptionFelt = result[i + 4].toBigInt(); // description: felt252 (1 felt)
          final categoryFelt = result[i + 5].toBigInt(); // category: felt252 (1 felt)
          final targetAmount = parseU256(i + 6).toDouble() / pow(10, 6); // target_amount: u256 (2 felts)
          final currentAmount = parseU256(i + 8).toDouble() / pow(10, 6); // current_amount: u256 (2 felts)
          final contributionType = result[i + 10].toBigInt().toInt(); // contribution_type: u8 (1 felt)
          final contributionAmount = parseU256(i + 11).toDouble() / pow(10, 6); // contribution_amount: u256 (2 felts)
          final isPublic = result[i + 13].toBigInt() == BigInt.one; // is_public: bool (1 felt)
          final memberCount = parseU256(i + 14); // member_count: u256 (2 felts)
          final startTime = result[i + 16].toBigInt().toInt(); // start_time: u64 (1 felt)
          final endTime = result[i + 17].toBigInt().toInt(); // end_time: u64 (1 felt)
          final isCompletedField = result[i + 18].toBigInt() == BigInt.one; // is_completed: bool (1 felt)

          print('📋 Parsed GroupSave fields:');
          print('   ID: $id');
          print('   Creator: $creator');
          print('   Title felt: $titleFelt');
          print('   Description felt: $descriptionFelt');
          print('   Category felt: $categoryFelt');
          print('   Target Amount: $targetAmount USDC');
          print('   Current Amount: $currentAmount USDC');
          print('   Contribution Type: $contributionType');
          print('   Contribution Amount: $contributionAmount USDC');
          print('   Is Public: $isPublic');
          print('   Member Count: $memberCount');
          print('   Start Time: $startTime');
          print('   End Time: $endTime');
          print('   Is Completed: $isCompletedField');

          // Convert felt252 values to strings
          String title;
          try {
            if (titleFelt == BigInt.zero) {
              title = 'Untitled';
            } else {
              title = _feltToString(titleFelt);
              if (title.isEmpty) title = 'Untitled';
            }
          } catch (e) {
            print('⚠️ Failed to convert title, using fallback: $e');
            title = 'Untitled Group';
          }

          String description;
          try {
            if (descriptionFelt == BigInt.zero) {
              description = 'No description';
            } else {
              description = _feltToString(descriptionFelt);
              if (description.isEmpty) description = 'No description';
            }
          } catch (e) {
            print('⚠️ Failed to convert description, using fallback: $e');
            description = 'No description';
          }

          String category;
          try {
            if (categoryFelt == BigInt.zero) {
              category = 'General';
            } else {
              category = _feltToString(categoryFelt);
              if (category.isEmpty) category = 'General';
            }
          } catch (e) {
            print('⚠️ Failed to convert category, using fallback: $e');
            category = 'General';
          }

          final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          String status;
          if (isCompletedField) {
            status = 'completed';
          } else if (currentTime >= endTime) {
            status = 'expired';
          } else {
            status = 'active';
          }

          String? endDateString;
          if (endTime > 0) {
            try {
              if (endTime < 1000000000) {
                print('⚠️ Warning: Invalid timestamp detected: $endTime');
                endDateString = 'Invalid Date';
              } else {
                final endDate =
                    DateTime.fromMillisecondsSinceEpoch(endTime * 1000);
                endDateString =
                    '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}';
              }
            } catch (e) {
              print('⚠️ Error formatting end date: $e');
              endDateString = 'Invalid Date';
            }
          }

          final progressPercent = targetAmount > 0
              ? (currentAmount / targetAmount * 100).clamp(0, 100)
              : 0.0;

          final groupSave = {
            'id': id,
            'creator': creator,
            'title': title,
            'description': description,
            'category': category,
            'targetAmount': targetAmount,
            'currentAmount': currentAmount,
            'contributionType': contributionType,
            'contributionAmount': contributionAmount,
            'isPublic': isPublic,
            'memberCount': memberCount.toInt(),
            'startTime': startTime,
            'endTime': endTime,
            'endDate': endDateString,
            'isCompleted': isCompletedField,
            'status': status,
            'progressPercent': progressPercent,
            'isExpired': currentTime >= endTime,
            'timeRemaining':
                status == 'active' ? math.max(0, endTime - currentTime) : 0,
          };

          groupSaves.add(groupSave);
          print(
              '✅ Parsed group save: ID ${groupSave['id']}, Title: "${groupSave['title']}", Status: ${groupSave['status']}');
          print(
              '   Progress: ${groupSave['currentAmount']}/${groupSave['targetAmount']} (${progressPercent.toStringAsFixed(1)}%)');
        } catch (e) {
          print('❌ Error parsing group save at index $i: $e');
        }
      } else {
        print('⚠️ Incomplete struct data at index $i, skipping');
      }
    }

    return groupSaves;
  }

  Future<BigInt> getUserLockSaveBalance() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      print('❌ CONTRACT SERVICE: Wallet not connected');
      return BigInt.zero; // Return zero instead of throwing
    }

    final userAddress = account.accountAddress;

    print(
        '🔍 CONTRACT SERVICE: Getting flexi balance for user: ${userAddress.toHexString()}');
    print('📞 CONTRACT SERVICE: Contract address: $_contractAddress');

    try {
      // Prepare function call for get_flexi_balance
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_user_lock_save_balance'),
        calldata: [userAddress],
      );

      print(
          '📋 CONTRACT SERVICE: Function call prepared: ${functionCall.entryPointSelector}');

      // Call the contract
      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return response.when(
        result: (result) {
          print('📊 CONTRACT SERVICE: Raw balance result: $result');

          if (result.length < 2) {
            print(
                '❌ CONTRACT SERVICE: Invalid balance response - not enough elements');
            return BigInt.zero; // Return zero instead of throwing
          }

          // Combine low and high parts for u256
          final low = result[0].toBigInt();
          final high = result[1].toBigInt();

          print('🔢 CONTRACT SERVICE: Low: $low, High: $high');

          final balance = low + (high << 128);
          print('✅ CONTRACT SERVICE: Combined balance: $balance');

          return balance;
        },
        error: (error) {
          print('❌ CONTRACT SERVICE: Failed to get lock balance: $error');
          return BigInt.zero; // Return zero instead of throwing
        },
      );
    } catch (e) {
      print('❌ CONTRACT SERVICE: Exception getting lock balance: $e');
      return BigInt.zero; // Return zero instead of throwing
    }
  }

  /// Get user goal save balance
  Future<BigInt> getUserGoalSaveBalance() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    final userAddress = account.accountAddress;

    try {
      print(
          '🔍 Getting user goal save balance for: ${userAddress.toHexString()}');

      // Prepare function call for get_user_goal_save_balance
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_user_goal_save_balance'),
        calldata: [userAddress],
      );

      // Call the contract
      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return response.when(
        result: (result) {
          if (result.length < 2) {
            return BigInt.zero;
          }
          // Combine low and high parts for u256
          final low = result[0].toBigInt();
          final high = result[1].toBigInt();
          final balance = low + (high << 128);
          print('✅ User goal save balance: $balance');
          return balance;
        },
        error: (error) {
          print('❌ Failed to get user goal save balance: $error');
          return BigInt.zero;
        },
      );
    } catch (e) {
      print('❌ Error getting user goal save balance: $e');
      return BigInt.zero;
    }
  }

  /// Get user group save balance
  Future<BigInt> getUserGroupSaveBalance() async {
    final account = _walletService.currentAccount;
    if (account == null) {
      throw Exception('Wallet not connected');
    }

    final userAddress = account.accountAddress;

    try {
      print(
          '🔍 Getting user group save balance for: ${userAddress.toHexString()}');

      // Prepare function call for get_user_group_save_balance
      final functionCall = FunctionCall(
        contractAddress: _contractAddress,
        entryPointSelector: getSelectorByName('get_user_group_save_balance'),
        calldata: [userAddress],
      );

      // Call the contract
      final response = await account.provider.call(
        request: functionCall,
        blockId: BlockId.latest,
      );

      return response.when(
        result: (result) {
          if (result.length < 2) {
            return BigInt.zero;
          }
          // Combine low and high parts for u256
          final low = result[0].toBigInt();
          final high = result[1].toBigInt();
          final balance = low + (high << 128);
          print('✅ User group save balance: $balance');
          return balance;
        },
        error: (error) {
          print('❌ Failed to get user group save balance: $error');
          return BigInt.zero;
        },
      );
    } catch (e) {
      print('❌ Error getting user group save balance: $e');
      return BigInt.zero;
    }
  }
}

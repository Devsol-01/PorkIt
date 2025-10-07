import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:starknet/starknet.dart';
import 'package:starknet_provider/starknet_provider.dart';
import 'package:avnu_provider/avnu_provider.dart';
import 'package:mobile_app/services/token_service.dart';

class WalletService {
  static const _storage = FlutterSecureStorage();
  static const String _privateKeyKey = 'starknet_private_key';
  static const String _guardianKeyKey = 'starknet_guardian_key';
  static const String _appKeyKey = 'starknet_app_key';
  static const String _addressKey = 'starknet_address';
  static const String _publicKeyKey = 'starknet_public_key';

  late final JsonRpcProvider _provider;
  late final TokenService _tokenService;
  late final AvnuJsonRpcProvider _avnuProvider;
  Account? _currentAccount;
  StarkSigner? _ownerSigner;
  StarkSigner? _guardianSigner;
  StarkSigner? _appSigner;
  String? _currentPrivateKeyHex;
  String? _currentGuardianKeyHex;
  String? _currentAppKeyHex;
  WalletInfo? _walletInfo;

  // Argent account class hash (Argent X 0.4.0)
  static final argentClassHash = Felt.fromHexString(
    '0x036078334509b514626504edc9fb252328d1a240e4e948bef8d0c08dff45927f',
  );

  WalletService() {
    // Initialize provider (mainnet to match Ark)
    _provider = JsonRpcProvider(
        nodeUri: Uri.parse('https://starknet-sepolia.public.blastapi.io'));
    _tokenService = TokenService();

    // Initialize Avnu provider for sponsored deployments
    _avnuProvider = AvnuJsonRpcProvider(
      nodeUri: Uri.parse('https://sepolia.api.avnu.fi'),
      //apiKey: Platform.environment['AVNU_API_KEY'] ?? '',
      apiKey: 'ee9d2deb-dc4c-4793-9c94-025ad10f69d6',
    );
  }

  /// Get token service instance
  TokenService get tokenService => _tokenService;

  /// Get current wallet address (properly formatted for Argent compatibility)
  Future<String?> getCurrentWalletAddress() async {
    // First try to get from loaded wallet info
    if (_walletInfo != null && _walletInfo!.address.isNotEmpty) {
      print('📋 Using loaded wallet info address: ${_walletInfo!.address}');
      return _walletInfo!.address;
    }
    
    // If not in memory, try to load from storage
    final address = await _storage.read(key: _addressKey);
    if (address != null) {
      print('📋 Using storage address: $address');
      return _formatAddressTo66Chars(address);
    }
    
    // Try to load wallet if not available
    try {
      print('🔄 Attempting to load wallet...');
      final walletInfo = await loadWallet();
      if (walletInfo != null) {
        print('✅ Wallet loaded, address: ${walletInfo.address}');
        return walletInfo.address;
      }
    } catch (e) {
      print('❌ Error loading wallet: $e');
    }
    
    print('❌ No wallet address available');
    return null;
  }

  /// Check if wallet exists in storage
  Future<bool> hasWalletInStorage() async {
    final address = await _storage.read(key: _addressKey);
    return address != null;
  }

  /// Helper: Build Argent constructor calldata for Argent X 0.4.0
  List<Felt> _buildArgentConstructorCalldata({
    required Felt ownerPublicKey,
    required Felt guardianPublicKey,
  }) {
    final starkSignerId = Felt.zero;
    return [
      starkSignerId,
      ownerPublicKey,
      Felt.zero, // Some
      starkSignerId,
      guardianPublicKey,
    ];
  }

  /// Helper: Compute Argent account address
  Felt _computeArgentAddress({
    required Felt ownerPublicKey,
    required Felt guardianPublicKey,
  }) {
    final calldata = _buildArgentConstructorCalldata(
      ownerPublicKey: ownerPublicKey,
      guardianPublicKey: guardianPublicKey,
    );
    final salt = ownerPublicKey;
    return Contract.computeAddress(
      classHash: argentClassHash,
      calldata: calldata,
      salt: salt,
    );
  }

  /// Helper: Format address to 66 characters (0x + 64 hex digits) for Argent compatibility
  String _formatAddressTo66Chars(String address) {
    try {
      if (address.isEmpty) {
        print('❌ _formatAddressTo66Chars: Empty address provided');
        throw ArgumentError('Address cannot be empty');
      }

      print('🔧 Formatting address: "$address"');

      // Remove 0x prefix if present
      String cleanAddress =
          address.startsWith('0x') ? address.substring(2) : address;

      if (cleanAddress.isEmpty) {
        print(
            '❌ _formatAddressTo66Chars: Address is just "0x" with no content');
        throw ArgumentError('Address cannot be just "0x"');
      }

      // Pad with leading zeros to make it 64 characters
      cleanAddress = cleanAddress.padLeft(64, '0');
      // Add 0x prefix
      final formatted = '0x$cleanAddress';

      print('✅ Formatted address: "$formatted"');
      return formatted;
    } catch (e) {
      print('❌ Error in _formatAddressTo66Chars: $e');
      rethrow;
    }
  }

  /// Generate secure private key within Starknet field bounds
  BigInt _generateSecurePrivateKey() {
    final random = Random.secure();
    final starknetFieldPrime = BigInt.parse(
        '800000000000011000000000000000000000000000000000000000000000001',
        radix: 16);

    BigInt keyBigInt;
    do {
      final keyBytes = List<int>.generate(31, (i) => random.nextInt(256));
      keyBigInt = BigInt.parse(
          keyBytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join(),
          radix: 16);
    } while (keyBigInt >= starknetFieldPrime);

    return keyBigInt;
  }

  /// Create a new Argent wallet with guardian protection - users don't see any keys!
  /// Automatically deploys the account so it's ready to send transactions immediately
  Future<WalletInfo> createWallet() async {
    try {
      // Generate three secure private keys
      final ownerKeyBigInt = _generateSecurePrivateKey();
      final guardianKeyBigInt = _generateSecurePrivateKey();
      final appKeyBigInt = _generateSecurePrivateKey();

      final ownerKeyHex = '0x${ownerKeyBigInt.toRadixString(16)}';
      final guardianKeyHex = '0x${guardianKeyBigInt.toRadixString(16)}';
      final appKeyHex = '0x${appKeyBigInt.toRadixString(16)}';

      // Create signers
      _ownerSigner = StarkSigner(privateKey: Felt(ownerKeyBigInt));
      _guardianSigner = StarkSigner(privateKey: Felt(guardianKeyBigInt));
      _appSigner = StarkSigner(privateKey: Felt(appKeyBigInt));

      // Store keys for later use
      _currentPrivateKeyHex = ownerKeyHex;
      _currentGuardianKeyHex = guardianKeyHex;
      _currentAppKeyHex = appKeyHex;

      // Compute Argent account address
      final accountAddress = _computeArgentAddress(
        ownerPublicKey: _ownerSigner!.publicKey,
        guardianPublicKey: _guardianSigner!.publicKey,
      );

      // Create Argent account with guardian signer
      final argentAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _ownerSigner!,
        guardianSigner: _guardianSigner!,
      );

      _currentAccount = Account(
        provider: _provider,
        signer: argentAccountSigner,
        accountAddress: accountAddress,
        chainId: StarknetChainId.testNet,
      );

      // Set default transaction version to v1 for compatibility
      _currentAccount!.supportedTxVersion = AccountSupportedTxVersion.v1;

      // Create wallet info - initially not deployed
      var walletInfo = WalletInfo(
        address: _formatAddressTo66Chars(accountAddress.toHexString()),
        publicKey:
            _formatAddressTo66Chars(_ownerSigner!.publicKey.toHexString()),
        isDeployed: false,
      );

      // Store wallet securely first
      await _storeWalletSecurely(
          ownerKeyHex, guardianKeyHex, appKeyHex, walletInfo);

      // 🚀 AUTO-DEPLOY IMMEDIATELY using Avnu with session keys
      try {
        print('🚀 Auto-deploying Argent wallet with Avnu session keys...');
        final deployTxHash = await _deployWithAvnuSessionKeys();

        // Update wallet info to reflect successful deployment
        walletInfo = walletInfo.copyWith(isDeployed: true);
        await _storeWalletSecurely(
            ownerKeyHex, guardianKeyHex, appKeyHex, walletInfo);

        print(
            '✅ Argent wallet created and deployed successfully! TX: $deployTxHash');
      } catch (deployError) {
        print(
            '⚠️ Argent wallet created but auto-deployment failed: $deployError');
        print(
            '💡 Wallet can still receive tokens. Will retry deployment on first send.');
        // Wallet is still functional for receiving, deployment will be retried later
      }

      return walletInfo;
    } catch (e) {
      throw WalletException('Failed to create Argent wallet: $e');
    }
  }

  /// 🔥 FIXED: Deploy account with Avnu using session keys
  Future<String> _deployWithAvnuSessionKeys() async {
    if (_currentAccount == null ||
        _ownerSigner == null ||
        _guardianSigner == null ||
        _appSigner == null) {
      throw WalletException('Missing signers for deployment');
    }

    try {
      final accountAddress = _currentAccount!.accountAddress;

      // Get chain ID
      final chainIdResult = await _provider.chainId();
      final chainId = chainIdResult.when(
        result: (result) => result,
        error: (error) => throw Exception('Failed to get chain ID: $error'),
      );

      // 1. Create session key for deployment
      print('📝 Creating session key for deployment...');

      // Define allowed methods for session key
      const strkContractAddress =
          '0x4718F5A0FC34CC1AF16A1CDEE98FFB20C31F5CD61D6AB07201858F4287C938D';
      const ethContractAddress =
          '0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7';

      final allowedMethods = [
        AllowedMethod(
          contractAddress: Felt.fromHexString(strkContractAddress),
          selector: getSelectorByName('approve'),
        ),
        AllowedMethod(
          contractAddress: Felt.fromHexString(ethContractAddress),
          selector: getSelectorByName('approve'),
        ),
      ];

      final currentEpoch =
          (DateTime.now().millisecondsSinceEpoch / 1000).floor();
      final argentSession = ArgentSessionKey(
        accountAddress: accountAddress,
        guardianSigner: _guardianSigner!,
        allowedMethods: allowedMethods
            .map((e) => (
                  contractAddress: e.contractAddress.toHexString(),
                  selector: e.selector.toHexString(),
                ))
            .toList(),
        metadata: DateTime.now().millisecondsSinceEpoch.toString(),
        expiresAt: currentEpoch + 60 * 60 * 24, // 24 hours
        chainId: Felt.fromHexString(chainId),
        appSigner: _appSigner!,
      );

      // 2. Get authorization signature from owner
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _ownerSigner!,
        guardianSigner: _guardianSigner!,
      );

      final authorizationSignature = await ownerAccountSigner.sign(
        argentSession.hash,
        null,
      );
      argentSession.authorizationSignature = authorizationSignature;

      // 3. Prepare deployment data
      final deploymentData = {
        'class_hash': argentClassHash.toHexString(),
        'salt': _ownerSigner!.publicKey.toHexString(),
        'unique': Felt.zero.toHexString(),
        'calldata': _buildArgentConstructorCalldata(
          ownerPublicKey: _ownerSigner!.publicKey,
          guardianPublicKey: _guardianSigner!.publicKey,
        ).map((e) => e.toHexString()).toList(),
      };

      // 4. Create dummy transactions for deployment (required by Avnu)
      final dummyTransactions = [
        {
          'contractAddress': strkContractAddress,
          'entrypoint': 'approve',
          'calldata': ['0x1', '0x0', '0x0'] // Minimal approve call
        },
      ];

      // 5. Build typed data with Avnu
      print('🔧 Building typed data with Avnu...');
      final avnuBuildTypedDataResponse = await _avnuProvider.buildTypedData(
        accountAddress.toHexString(),
        dummyTransactions,
        '', // No session key needed for deployment
        '', // No metadata needed
        argentClassHash.toHexString(),
      );

      if (avnuBuildTypedDataResponse is AvnuBuildTypedDataError) {
        throw Exception(
            'Failed to build typed data: $avnuBuildTypedDataResponse');
      }

      final avnuTypedData =
          avnuBuildTypedDataResponse as AvnuBuildTypedDataResult;
      final outsideExecutionMessage = OutsideExecutionMessageV2.fromJson(
          avnuTypedData.toTypedData().message);

      // 6. Sign with session key
      print('✍️ Signing deployment transaction...');
      final sessionTokenSignature = await argentSession
          .outsideExecutionMessageToken(outsideExecutionMessage);
      final signature =
          sessionTokenSignature.map((e) => e.toHexString()).toList();

      // 7. Execute deployment with Avnu
      print('🚀 Executing deployment...');
      final avnuExecute = await _avnuProvider.execute(
        accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature,
        deploymentData, // This triggers deployment
      );

      if (avnuExecute is AvnuExecuteError) {
        throw Exception('Avnu deployment failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      print('✅ Deployment successful! TX: ${result.transactionHash}');

      // 8. Wait for deployment confirmation
      await _waitForAcceptance(result.transactionHash);

      return result.transactionHash;
    } catch (e) {
      print('❌ Deployment failed: $e');
      rethrow;
    }
  }

  /// Wait for transaction acceptance
  Future<void> _waitForAcceptance(String transactionHash) async {
    print('⏳ Waiting for transaction acceptance...');
    for (int i = 0; i < 30; i++) {
      // Wait up to 5 minutes
      try {
        final txResult = await _provider
            .getTransactionByHash(Felt.fromHexString(transactionHash));
        final isAccepted = txResult.when(
          result: (tx) => true,
          error: (error) => false,
        );

        if (isAccepted) {
          print('✅ Transaction accepted!');
          return;
        }

        await Future.delayed(const Duration(seconds: 10));
      } catch (e) {
        // Continue waiting
      }
    }
    print('⚠️ Transaction may still be pending...');
  }

  /// Check if user has a wallet stored
  Future<bool> hasWalletStored() async {
    try {
      final address = await _storage.read(key: _addressKey);
      return address != null;
    } catch (e) {
      return false;
    }
  }

  /// Load existing wallet from secure storage
  Future<WalletInfo?> loadWallet() async {
    try {
      final privateKey = await _storage.read(key: _privateKeyKey);
      final guardianKey = await _storage.read(key: _guardianKeyKey);
      final appKey = await _storage.read(key: _appKeyKey);
      final address = await _storage.read(key: _addressKey);
      final publicKey = await _storage.read(key: _publicKeyKey);

      if (privateKey == null ||
          guardianKey == null ||
          appKey == null ||
          address == null ||
          publicKey == null) {
        return null;
      }

      // Recreate signers from stored keys
      _ownerSigner = StarkSigner(privateKey: Felt.fromHexString(privateKey));
      _guardianSigner =
          StarkSigner(privateKey: Felt.fromHexString(guardianKey));
      _appSigner = StarkSigner(privateKey: Felt.fromHexString(appKey));
      _currentPrivateKeyHex = privateKey;
      _currentGuardianKeyHex = guardianKey;
      _currentAppKeyHex = appKey;

      // Create Argent account with guardian signer
      final argentAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _ownerSigner!,
        guardianSigner: _guardianSigner!,
      );

      _currentAccount = Account(
        provider: _provider,
        signer: argentAccountSigner,
        accountAddress: Felt.fromHexString(address),
        chainId: StarknetChainId.testNet,
      );

      // Set default transaction version to v1 for compatibility
      _currentAccount!.supportedTxVersion = AccountSupportedTxVersion.v1;

      // Check if account is deployed
      final isDeployed = await _checkIfDeployed(address);

      _walletInfo = WalletInfo(
        address: address,
        publicKey: publicKey,
        isDeployed: isDeployed,
      );

      return _walletInfo;
    } catch (e) {
      throw WalletException('Failed to load wallet: $e');
    }
  }

  // 💰 USDC CONTRACT ADDRESSES (official Starknet addresses)
  static const String _usdcContractTestnet =
      '0x053b40a647cedfca6ca84f542a0fe36736031905a9639a7f19a3c1e66bfd5080';
  // Sepolia
  // static const String _usdcContractMainnet =
  //     '0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8';

  /// Get USDC contract address based on network (already properly formatted)
  String get _usdcContractAddress => _usdcContractTestnet;

  /// 💰 Get USDC balance for the wallet
  Future<double> getUsdcBalance([String? walletAddress]) async {
    try {
      print('🔍 Starting USDC balance check...');

      String? address;

      // First try to get address from parameter
      if (walletAddress != null && walletAddress.isNotEmpty) {
        address = walletAddress;
        print('📋 Using provided wallet address: "$address"');
      } else {
        // Try to get from current wallet info
        if (_walletInfo != null && _walletInfo!.address.isNotEmpty) {
          address = _walletInfo!.address;
          print('📋 Using wallet info address: "$address"');
        } else {
          // Try to get from storage
          address = await _storage.read(key: _addressKey);
          print('📋 Raw address from storage: "$address"');
        }
      }

      if (address == null || address.isEmpty) {
        print('❌ No wallet address found or empty address');
        print('💡 Try loading wallet first with loadWallet()');
        return 0.0;
      }

      // Ensure address is properly formatted
      final formattedAddress = _formatAddressTo66Chars(address);
      print('🔍 Checking USDC balance for: $formattedAddress');

      // Debug USDC contract address
      print('📋 Raw USDC contract: "$_usdcContractAddress"');
      if (_usdcContractAddress.isEmpty) {
        print('❌ USDC contract address is empty!');
        return 0.0;
      }

      final usdcContract = Felt.fromHexString(_usdcContractAddress);
      final walletAddressFelt = Felt.fromHexString(formattedAddress);

      print('📞 Calling USDC contract: $_usdcContractAddress');
      print('📍 For wallet: $formattedAddress');

      final result = await _provider.call(
        request: FunctionCall(
          contractAddress: usdcContract,
          entryPointSelector: getSelectorByName('balanceOf'),
          calldata: [walletAddressFelt],
        ),
        blockId: BlockId.latest,
      );

      return result.when(
        result: (callResult) {
          print('📊 Raw balance result: $callResult');
          if (callResult.isEmpty) {
            print('⚠️ Empty balance result');
            return 0.0;
          }

          // USDC has 6 decimals, handle as Uint256 (low, high)
          final balanceLow = callResult[0].toBigInt();
          final balanceHigh =
              callResult.length > 1 ? callResult[1].toBigInt() : BigInt.zero;

          print('💰 Balance Low: $balanceLow, High: $balanceHigh');

          // Combine low and high parts: balance = low + (high * 2^128)
          final fullBalance = balanceLow + (balanceHigh << 128);

          // Convert from raw USDC units (6 decimals) to readable format
          final balanceInUsdc = fullBalance.toDouble() / pow(10, 6);

          print('✅ USDC Balance: $balanceInUsdc USDC');
          return balanceInUsdc;
        },
        error: (error) {
          print('❌ Failed to get USDC balance: $error');
          return 0.0;
        },
      );
    } catch (e) {
      print('❌ Error getting USDC balance: $e');
      return 0.0;
    }
  }

  /// Get wallet ETH balance (for gas fees)
  Future<BigInt> getEthBalance([String? walletAddress]) async {
    try {
      final address = walletAddress ?? await _storage.read(key: _addressKey);
      if (address == null) {
        print('❌ No wallet address found for ETH balance');
        return BigInt.zero;
      }

      // Ensure address is properly formatted
      final formattedAddress = _formatAddressTo66Chars(address);
      print('🔍 Checking ETH balance for: $formattedAddress');

      // ETH contract address on Starknet (properly formatted)
      final ethContractFormatted = _formatAddressTo66Chars(
          '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7');
      final ethContractAddress = Felt.fromHexString(ethContractFormatted);

      print('📞 Calling ETH contract: $ethContractFormatted');

      final result = await _provider.call(
        request: FunctionCall(
          contractAddress: ethContractAddress,
          entryPointSelector: getSelectorByName('balanceOf'),
          calldata: [Felt.fromHexString(formattedAddress)],
        ),
        blockId: BlockId.latest,
      );

      // Handle the result - extract the balance from the call result
      return result.when(
        result: (callResult) {
          print('📊 Raw ETH balance result: $callResult');
          if (callResult.isEmpty) {
            print('⚠️ Empty ETH balance result');
            return BigInt.zero;
          }

          // ETH balance is returned as Uint256 (low, high)
          final balanceLow = callResult[0].toBigInt();
          final balanceHigh =
              callResult.length > 1 ? callResult[1].toBigInt() : BigInt.zero;

          // Combine low and high parts
          final fullBalance = balanceLow + (balanceHigh << 128);
          print('💰 ETH Balance: $fullBalance wei');

          return fullBalance;
        },
        error: (error) {
          print('❌ Failed to get ETH balance: $error');
          return BigInt.zero;
        },
      );
    } catch (e) {
      print('❌ Error getting ETH balance: $e');
      return BigInt.zero;
    }
  }

  /// Format ETH balance for display
  String formatEthBalance(BigInt balance) {
    final eth = balance ~/ BigInt.from(10).pow(18);
    final decimal =
        (balance % BigInt.from(10).pow(18)) ~/ BigInt.from(10).pow(14);
    return '$eth.${decimal.toString().padLeft(4, '0')} ETH';
  }

  /// Format USDC balance for display
  String formatUsdcBalance(double balance) {
    return '${balance.toStringAsFixed(6)} USDC';
  }

  /// Deploy account (public method to retry deployment if needed)
  Future<String> deployAccount() async {
    if (_currentAccount == null) {
      throw WalletException('No wallet loaded');
    }

    try {
      return await _deployWithAvnuSessionKeys();
    } catch (e) {
      throw WalletException('Failed to deploy account: $e');
    }
  }

  /// 💸 Send USDC to another address using AVNU provider (like the example)
  Future<String> sendUsdc({
    required String recipientAddress,
    required double amount,
  }) async {
    if (_currentAccount == null ||
        _ownerSigner == null ||
        _guardianSigner == null) {
      throw WalletException('No wallet account available');
    }

    if (amount <= 0) {
      throw WalletException('Amount must be greater than 0');
    }

    try {
      print('💸 Initiating USDC transfer: $amount USDC to $recipientAddress');

      // Check if account is deployed, deploy if necessary
      final isDeployed =
          await _checkIfDeployed(_currentAccount!.accountAddress.toHexString());
      if (!isDeployed) {
        print('🚀 Account not deployed, deploying first...');
        await deployAccount();
      }

      // Check USDC balance before sending
      final currentBalance = await getUsdcBalance();
      if (currentBalance < amount) {
        throw WalletException(
            'Insufficient USDC balance. Available: ${formatUsdcBalance(currentBalance)}, Required: ${formatUsdcBalance(amount)}');
      }

      // Convert amount to raw USDC units (6 decimals)
      final rawAmount = BigInt.from((amount * pow(10, 6)).round());
      print('📊 Raw amount: $rawAmount (${amount} USDC)');

      // Prepare transfer call data (like in the example)
      final calls = [
        {
          'contractAddress': _usdcContractAddress,
          'entrypoint': 'transfer',
          'calldata': [
            recipientAddress,
            '0x${rawAmount.toRadixString(16)}',
            '0x0', // amount.high for amounts < 2^128
          ],
        },
      ];

      print('🔧 Building typed data with Avnu...');

      // Build typed data with AVNU (like in the example)
      final avnuBuildTypeDataResponse = await _avnuProvider.buildTypedData(
        _currentAccount!.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        throw WalletException(
            'Failed to build typed data: $avnuBuildTypeDataResponse');
      }

      final avnuTypedData =
          avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create owner account signer (like in the example)
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _ownerSigner!,
        guardianSigner: _guardianSigner!,
      );

      // Compute message hash and sign it (like in the example)
      final hash = avnuTypedData.hash(_currentAccount!.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing USDC transfer with Avnu...');

      // Execute the transaction via AVNU provider (like in the example)
      final avnuExecute = await _avnuProvider.execute(
        _currentAccount!.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        throw WalletException('USDC transfer failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        throw WalletException('Transaction hash is null or empty');
      }

      print('✅ USDC transfer successful! TX: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ USDC transfer error: $e');
      if (e is WalletException) rethrow;
      throw WalletException('Failed to send USDC: $e');
    }
  }

  Future<String> approveUsdc({
    required String spenderAddress,
    required double amount,
  }) async {
    if (_currentAccount == null ||
        _ownerSigner == null ||
        _guardianSigner == null) {
      throw WalletException('No wallet account available');
    }

    if (amount < 0) {
      throw WalletException('Amount must be greater than or equal to 0');
    }

    try {
      print('🔓 Initiating USDC approval: $amount USDC for $spenderAddress');

      // Check if account is deployed, deploy if necessary
      final isDeployed =
          await _checkIfDeployed(_currentAccount!.accountAddress.toHexString());
      if (!isDeployed) {
        print('🚀 Account not deployed, deploying first...');
        await deployAccount();
      }

      // Convert amount to raw USDC units (6 decimals)
      final rawAmount = BigInt.from((amount * pow(10, 6)).round());
      print('📊 Raw approval amount: $rawAmount (${amount} USDC)');

      // Prepare approve call data
      final calls = [
        {
          'contractAddress': _usdcContractAddress,
          'entrypoint': 'approve',
          'calldata': [
            spenderAddress,
            '0x${rawAmount.toRadixString(16)}',
            '0x0', // amount.high for amounts < 2^128
          ],
        },
      ];

      print('🔧 Building typed data with Avnu...');

      // Build typed data with AVNU
      final avnuBuildTypeDataResponse = await _avnuProvider.buildTypedData(
        _currentAccount!.accountAddress.toHexString(),
        calls,
        '', // use sponsor gas token
        '', // use sponsor gas limit
        argentClassHash.toHexString(),
      );

      if (avnuBuildTypeDataResponse is AvnuBuildTypedDataError) {
        throw WalletException(
            'Failed to build typed data: $avnuBuildTypeDataResponse');
      }

      final avnuTypedData =
          avnuBuildTypeDataResponse as AvnuBuildTypedDataResult;

      // Create owner account signer
      final ownerAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _ownerSigner!,
        guardianSigner: _guardianSigner!,
      );

      // Compute message hash and sign it
      final hash = avnuTypedData.hash(_currentAccount!.accountAddress);
      final signature = await ownerAccountSigner.sign(hash, null);

      print('🚀 Executing USDC approval with Avnu...');

      // Execute the transaction via AVNU provider
      final avnuExecute = await _avnuProvider.execute(
        _currentAccount!.accountAddress.toHexString(),
        jsonEncode(avnuTypedData.toTypedData()),
        signature.map((e) => e.toHexString()).toList(),
        null, // account is already deployed
      );

      if (avnuExecute is AvnuExecuteError) {
        throw WalletException('USDC approval failed: $avnuExecute');
      }

      final result = avnuExecute as AvnuExecuteResult;
      final transactionHash = result.transactionHash;

      if (transactionHash == null || transactionHash.isEmpty) {
        throw WalletException('Transaction hash is null or empty');
      }

      print('✅ USDC approval successful! TX: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('❌ USDC approval error: $e');
      if (e is WalletException) rethrow;
      throw WalletException('Failed to approve USDC: $e');
    }
  }

// Helper function to check current allowance
  Future<double> getUsdcAllowance({
    required String ownerAddress,
    required String spenderAddress,
  }) async {
    try {
      // Prepare call data for allowance check
      final calls = [
        {
          'contractAddress': _usdcContractAddress,
          'entrypoint': 'allowance',
          'calldata': [
            ownerAddress,
            spenderAddress,
          ],
        },
      ];

      // You might need to use a different method to read contract state
      // This is a placeholder - you'll need to adapt based on your provider's API
      // For now, returning 0.0 as a safe default
      print('📊 Checking USDC allowance for $spenderAddress');

      // TODO: Implement contract call using your available provider
      // This might require a different method than what's available in _avnuProvider

      return 0.0;
    } catch (e) {
      print('❌ Error getting USDC allowance: $e');
      return 0.0;
    }
  }

// Helper function to revoke approval (set allowance to 0)
  Future<String> revokeUsdcApproval({
    required String spenderAddress,
  }) async {
    return approveUsdc(spenderAddress: spenderAddress, amount: 0.0);
  }

  /// 📱 Get wallet summary with all balances
  Future<WalletSummary> getWalletSummary() async {
    if (_walletInfo == null) {
      throw WalletException('No wallet loaded');
    }

    try {
      final address = _walletInfo!.address;

      // Get balances concurrently for better performance
      final futures = await Future.wait([
        getUsdcBalance(address),
        getEthBalance(address),
      ]);

      final usdcBalance = futures[0] as double;
      final ethBalance = futures[1] as BigInt;

      return WalletSummary(
        walletInfo: _walletInfo!,
        usdcBalance: usdcBalance,
        ethBalance: ethBalance,
        formattedUsdcBalance: formatUsdcBalance(usdcBalance),
        formattedEthBalance: formatEthBalance(ethBalance),
      );
    } catch (e) {
      throw WalletException('Failed to get wallet summary: $e');
    }
  }

  /// 🔄 Refresh wallet balances
  Future<void> refreshBalances() async {
    if (_walletInfo != null) {
      await getWalletSummary(); // This will update the cached balances
    }
  }

  /// Delete wallet from storage
  Future<void> deleteWallet() async {
    try {
      await _storage.deleteAll();
      _walletInfo = null;
      _currentAccount = null;
      _ownerSigner = null;
      _guardianSigner = null;
      _appSigner = null;
      _currentPrivateKeyHex = null;
      _currentGuardianKeyHex = null;
      _currentAppKeyHex = null;
    } catch (e) {
      throw WalletException('Failed to delete wallet: $e');
    }
  }

  /// Get current account instance
  Account? get currentAccount => _currentAccount;

  /// Get current wallet info
  WalletInfo? get walletInfo => _walletInfo;

  /// Check if user has a wallet
  bool get hasWallet => _walletInfo != null;

  /// Get current wallet private key (for Firebase integration)
  String? get currentPrivateKeyHex => _currentPrivateKeyHex;

  /// Get current guardian key (for Firebase integration)
  String? get currentGuardianKeyHex => _currentGuardianKeyHex;

  /// Get current app key (for Firebase integration)
  String? get currentAppKeyHex => _currentAppKeyHex;

  /// Get USDC contract address (for contract service)
  String get usdcContractAddress => _usdcContractAddress;

  /// Get AVNU provider (for contract service)
  AvnuJsonRpcProvider get avnuProvider => _avnuProvider;

  /// Get owner signer (for contract service)
  StarkSigner? get ownerSigner => _ownerSigner;

  /// Get guardian signer (for contract service)
  StarkSigner? get guardianSigner => _guardianSigner;

  /// Clear wallet data
  Future<void> clearWallet() async {
    try {
      print('🧹 Clearing wallet data...');

      // Clear in-memory data
      _walletInfo = null;
      _currentAccount = null;
      _ownerSigner = null;
      _guardianSigner = null;
      _appSigner = null;
      _currentPrivateKeyHex = null;
      _currentGuardianKeyHex = null;
      _currentAppKeyHex = null;

      print('✅ Wallet data cleared successfully');
    } catch (e) {
      print('❌ Error clearing wallet data: $e');
      throw WalletException('Failed to clear wallet data: $e');
    }
  }

  /// Load wallet from provided keys (for Firebase integration)
  Future<WalletInfo> loadWalletFromKeys({
    required String privateKey,
    required String guardianKey,
    required String appKey,
    required String address,
    required String publicKey,
    required bool isDeployed,
  }) async {
    try {
      print('🔑 Loading wallet from provided keys...');

      // Store keys for current session
      _currentPrivateKeyHex = privateKey;
      _currentGuardianKeyHex = guardianKey;
      _currentAppKeyHex = appKey;

      // Create signers from keys
      _ownerSigner = StarkSigner(privateKey: Felt.fromHexString(privateKey));
      _guardianSigner =
          StarkSigner(privateKey: Felt.fromHexString(guardianKey));
      _appSigner = StarkSigner(privateKey: Felt.fromHexString(appKey));

      // Create account with signers
      final argentAccountSigner = ArgentXGuardianAccountSigner(
        ownerSigner: _ownerSigner!,
        guardianSigner: _guardianSigner!,
      );

      _currentAccount = Account(
        provider: _provider,
        signer: argentAccountSigner,
        accountAddress: Felt.fromHexString(address),
        chainId: StarknetChainId.testNet,
      );

      // Create wallet info
      _walletInfo = WalletInfo(
        address: address,
        publicKey: publicKey,
        isDeployed: isDeployed,
      );

      print('✅ Wallet loaded from keys successfully');
      return _walletInfo!;
    } catch (e) {
      throw WalletException('Failed to load wallet from keys: $e');
    }
  }

  /// Store wallet data securely (updated to include app key)
  Future<void> _storeWalletSecurely(String privateKey, String guardianKey,
      String appKey, WalletInfo walletInfo) async {
    await _storage.write(key: _privateKeyKey, value: privateKey);
    await _storage.write(key: _guardianKeyKey, value: guardianKey);
    await _storage.write(key: _appKeyKey, value: appKey);
    await _storage.write(key: _addressKey, value: walletInfo.address);
    await _storage.write(key: _publicKeyKey, value: walletInfo.publicKey);
  }

  /// Check if account is deployed on-chain
  Future<bool> _checkIfDeployed(String address) async {
    try {
      final result = await _provider.getClassHashAt(
        contractAddress: Felt.fromHexString(address),
        blockId: BlockId.latest,
      );
      return result.when(
        result: (_) => true,
        error: (_) => false,
      );
    } catch (e) {
      return false; // Account not deployed yet
    }
  }
}

// 📊 Enhanced Data Models
class WalletInfo {
  final String address;
  final String publicKey;
  final bool isDeployed;

  WalletInfo({
    required this.address,
    required this.publicKey,
    required this.isDeployed,
  });

  WalletInfo copyWith({bool? isDeployed}) => WalletInfo(
        address: address,
        publicKey: publicKey,
        isDeployed: isDeployed ?? this.isDeployed,
      );

  @override
  String toString() => 'WalletInfo(address: $address, deployed: $isDeployed)';
}

class WalletSummary {
  final WalletInfo walletInfo;
  final double usdcBalance;
  final BigInt ethBalance;
  final String formattedUsdcBalance;
  final String formattedEthBalance;

  WalletSummary({
    required this.walletInfo,
    required this.usdcBalance,
    required this.ethBalance,
    required this.formattedUsdcBalance,
    required this.formattedEthBalance,
  });

  @override
  String toString() =>
      'WalletSummary(address: ${walletInfo.address}, USDC: $formattedUsdcBalance, ETH: $formattedEthBalance)';
}

class WalletException implements Exception {
  final String message;
  WalletException(this.message);

  @override
  String toString() => 'WalletException: $message';
}

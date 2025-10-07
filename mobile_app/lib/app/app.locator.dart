// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// StackedLocatorGenerator
// **************************************************************************

// ignore_for_file: public_member_api_docs, implementation_imports, depend_on_referenced_packages

import 'package:stacked_services/src/bottom_sheet/bottom_sheet_service.dart';
import 'package:stacked_services/src/dialog/dialog_service.dart';
import 'package:stacked_services/src/navigation/navigation_service.dart';
import 'package:stacked_services/src/snackbar/snackbar_service.dart';
import 'package:stacked_shared/stacked_shared.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/contract_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_wallet_manager_service.dart';
import '../services/localization_service.dart';
import '../services/token_service.dart';
import '../services/wallet_service.dart';
import '../ui/views/dashboard/dashboard_viewmodel.dart';
import '../ui/views/goal_save/goal_save_viewmodel.dart';

final locator = StackedLocator.instance;

Future<void> setupLocator({
  String? environment,
  EnvironmentFilter? environmentFilter,
}) async {
// Register environments
  locator.registerEnvironment(
      environment: environment, environmentFilter: environmentFilter);

// Register dependencies
  locator.registerLazySingleton(() => BottomSheetService());
  locator.registerLazySingleton(() => DialogService());
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => WalletService());
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => TokenService());
  locator.registerLazySingleton(() => FirebaseWalletManagerService());
  locator.registerLazySingleton(() => FirebaseAuthService());
  locator.registerLazySingleton(() => SnackbarService());
  locator.registerLazySingleton(() => ApiService());
  locator
      .registerLazySingleton(() => ContractService(locator<WalletService>()));
  locator.registerLazySingleton(() => LocalizationService());
  locator.registerFactory(() => DashboardViewModel());
  locator.registerFactory(() => GoalSaveViewModel());
}

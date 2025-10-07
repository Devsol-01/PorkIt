import 'package:mobile_app/services/firebase_wallet_manager_service.dart';
import 'package:stacked/stacked.dart';
import 'package:mobile_app/app/app.locator.dart';
import 'package:mobile_app/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';

class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _firebaseWalletManager = locator<FirebaseWalletManagerService>();

  // Place anything here that needs to happen before we get into the application
  Future runStartupLogic() async {
    await Future.delayed(const Duration(seconds: 2));
   
    try {
      // Initialize Firebase Wallet Manager
      await _firebaseWalletManager.initialize();

      // Check if user is already authenticated
      if (_firebaseWalletManager.isAuthenticated) {
        // User is already logged in, go to home view with wallet
        _navigationService.navigateToBottomNavView();
      } else {
        // User needs to authenticate, go to login view
        _navigationService.navigateToLoginView();
      }
    } catch (e) {
      print('❌ Error during startup: $e');
      // On error, go to login view
      _navigationService.navigateToLoginView();
    }
  }
}

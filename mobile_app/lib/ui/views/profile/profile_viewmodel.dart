import 'package:mobile_app/app/app.router.dart';
import 'package:mobile_app/app/app.bottomsheets.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:mobile_app/services/firebase_auth_service.dart';
import 'package:mobile_app/services/wallet_service.dart';
import 'package:mobile_app/services/localization_service.dart';
import 'package:mobile_app/app/app.locator.dart';

class ProfileViewModel extends BaseViewModel {
  final NavigationService _navigationService = NavigationService();
  final FirebaseAuthService _authService = locator<FirebaseAuthService>();
  final WalletService _walletService = locator<WalletService>();
  final LocalizationService _localizationService =
      locator<LocalizationService>();

  ProfileViewModel() {
    _localizationService.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localizationService.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    notifyListeners();
  }

  AppUser? get currentUser => _authService.currentUser;

  String get currentLanguage => _localizationService.currentLocale.languageCode;
  String get currentLanguageName =>
      _localizationService.getLanguageName(currentLanguage);

  List<String> get availableLanguages => _localizationService.supportedLocales
      .map((locale) => locale.languageCode)
      .toList();

  void navigateToBadges() {
    _navigationService.navigateToBadgesView();
  }

  Future<void> logout() async {
    setBusy(true);
    try {
      // Clear wallet data
      await _walletService.deleteWallet();

      // Sign out from Firebase
      await _authService.signOut();

      // Navigate to login screen
      _navigationService.clearStackAndShow(Routes.loginView);
    } catch (e) {
      print('❌ Error during logout: $e');
      // Still navigate to login even if there's an error
      _navigationService.clearStackAndShow(Routes.loginView);
    } finally {
      setBusy(false);
    }
  }

  String getUserInitials() {
    final user = currentUser;
    if (user != null) {
      final firstInitial =
          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '';
      final lastInitial =
          user.lastName.isNotEmpty ? user.lastName[0].toUpperCase() : '';
      return '$firstInitial$lastInitial';
    }
    return 'U'; // Default fallback
  }

  Future<void> changeLanguage(String languageCode) async {
    setBusy(true);
    try {
      await _localizationService.changeLanguage(languageCode);
      notifyListeners();
    } catch (e) {
      print('❌ Error changing language: $e');
    } finally {
      setBusy(false);
    }
  }

  void showLanguageSelection() async {
    final bottomSheetService = locator<BottomSheetService>();
    await bottomSheetService.showCustomSheet(
      variant: BottomSheetType.languageSelection,
      title: 'Select Language',
    );
  }
}

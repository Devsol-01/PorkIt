import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:mobile_app/app/app.locator.dart';
import 'package:mobile_app/services/localization_service.dart';

class LanguageSelectionSheet extends StackedView<LanguageSelectionViewModel> {
  const LanguageSelectionSheet(BuildContext context, SheetRequest request, void Function(SheetResponse response) completer, {Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    LanguageSelectionViewModel viewModel,
    Widget? child,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            'Select Language',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          
          // Language options
          ...viewModel.availableLanguages.map((languageCode) {
            final languageName = viewModel.getLanguageName(languageCode);
            final isSelected = viewModel.isCurrentLanguage(languageCode);
            
            return GestureDetector(
              onTap: () => viewModel.selectLanguage(languageCode),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? const Color(0xFF6366F1) : Colors.black,
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  LanguageSelectionViewModel viewModelBuilder(BuildContext context) =>
      LanguageSelectionViewModel();
}

class LanguageSelectionViewModel extends BaseViewModel {
  final LocalizationService _localizationService = locator<LocalizationService>();
  final BottomSheetService _bottomSheetService = locator<BottomSheetService>();

  List<String> get availableLanguages => _localizationService.supportedLocales
      .map((locale) => locale.languageCode)
      .toList();

  String getLanguageName(String languageCode) {
    return _localizationService.getLanguageName(languageCode);
  }

  bool isCurrentLanguage(String languageCode) {
    return _localizationService.currentLocale.languageCode == languageCode;
  }

  Future<void> selectLanguage(String languageCode) async {
    setBusy(true);
    try {
      await _localizationService.changeLanguage(languageCode);
      _bottomSheetService.completeSheet(SheetResponse(confirmed: true));
    } catch (e) {
      print('❌ Error selecting language: $e');
    } finally {
      setBusy(false);
    }
  }
}

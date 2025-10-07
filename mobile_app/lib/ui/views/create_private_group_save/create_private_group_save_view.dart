import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/services.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:mobile_app/utils/input_formatters.dart';

import 'create_private_group_save_viewmodel.dart';

class CreatePrivateGroupSaveView
    extends StackedView<CreatePrivateGroupSaveViewModel> {
  const CreatePrivateGroupSaveView({Key? key}) : super(key: key);

  @override
  void onViewModelReady(CreatePrivateGroupSaveViewModel viewModel) {
    viewModel.initializeListeners();
    super.onViewModelReady(viewModel);
  }

  @override
  CreatePrivateGroupSaveViewModel viewModelBuilder(BuildContext context) =>
      CreatePrivateGroupSaveViewModel();

  @override
  Widget builder(
    BuildContext context,
    CreatePrivateGroupSaveViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 17.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 24,
                      ),
                      onPressed: () {
                        viewModel.navigateBack();
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Create Group Save',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 17.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Purpose Input
                      _buildSectionTitle('What do you want to save for?'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: viewModel.purposeController,
                        hintText: 'e.g., Dream vacation to Bali',
                      ),
                      const SizedBox(height: 24),

                      // Description Input (Optional)
                      _buildSectionTitle('Description (Optional)'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: viewModel.descriptionController,
                        hintText: 'Add more details about your group save',
                      ),

                      const SizedBox(height: 24),

                      // Category Selection
                      _buildSectionTitle('Category'),
                      const SizedBox(height: 12),
                      _buildCategoryGrid(viewModel),

                      const SizedBox(height: 24),

                      // Target Amount
                      _buildSectionTitle('Total Goal Amount'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: viewModel.targetAmountController,
                        hintText: 'Enter target amount',
                        keyboardType: TextInputType.number,
                        prefixText: '\$',
                      ),

                      const SizedBox(height: 24),

                      // Frequency Selection
                      _buildSectionTitle('How do you want to save?'),
                      const SizedBox(height: 12),
                      _buildFrequencySelection(viewModel),

                      const SizedBox(height: 24),

                      // Frequency-specific options
                      if (viewModel.selectedFrequency == 'Daily' ||
                          viewModel.selectedFrequency == 'Weekly' ||
                          viewModel.selectedFrequency == 'Monthly' ||
                          viewModel.selectedFrequency == 'Manual')
                        _buildFrequencySpecificOptions(context, viewModel),

                      const SizedBox(height: 24),

                      // Start Date
                      _buildSectionTitle('Start Date'),
                      const SizedBox(height: 12),
                      _buildDateSelector(
                        context: context,
                        selectedDate: viewModel.startDate,
                        onTap: () => viewModel.selectStartDate(context),
                        label: 'Select start date',
                      ),

                      const SizedBox(height: 24),

                      // End Date
                      _buildSectionTitle('End Date'),
                      const SizedBox(height: 12),
                      _buildDateSelector(
                        context: context,
                        selectedDate: viewModel.endDate,
                        onTap: () => viewModel.selectEndDate(context),
                        label: 'Select end date',
                      ),

                      const SizedBox(height: 24),

                      // Contribution Amount
                      _buildSectionTitle(
                          'Amount to contribute ${viewModel.contributionFrequencyText}'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: viewModel.contributionController,
                        hintText: 'Calculated automatically',
                        keyboardType: TextInputType.number,
                        prefixText: '\$',
                        readOnly: true,
                      ),

                      const SizedBox(height: 32),

                      // Who can invite new members
                      _buildSectionTitle('Who can invite new members?'),
                      const SizedBox(height: 12),
                      _buildDropdownTextField(context, viewModel),

                      SizedBox(height: 32),

                      // Terms and Conditions

                      // Terms and Conditions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Transform.scale(
                            scale:
                                0.8, // Adjust the scale to reduce size (0.5 = half size, 1.0 = default)
                            child: Switch(
                              value: viewModel.isTermsAccepted,
                              onChanged: (value) =>
                                  viewModel.toggleTermsAcceptance(),
                              activeColor:
                                  Colors.green, // thumb color when active
                              activeTrackColor: Colors.green
                                  .withOpacity(0.5), // track color when active
                              //inactiveThumbColor: Colors.grey, // thumb color when inactive
                              //inactiveTrackColor: Colors.grey.shade400, // track color when inactive
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'I hereby agree that I will forfeit the interest accrued on this Goal savings if I fail to meet the goal amount by the set withdrawal date.',
                              style: GoogleFonts.inter(
                                  color: Colors.black, fontSize: 14, height: 1),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Create Goal Button
                      InkWell(
                        onTap: viewModel.isBusy
                            ? null
                            : (viewModel.canCreateGoal
                                ? viewModel.createPrivateGroup
                                : null),
                        borderRadius: BorderRadius.circular(46),
                        child: Container(
                          width: 358,
                          height: 50, // use same as Figma input/button height
                          decoration: BoxDecoration(
                            color: Colors.white, // background for light mode
                            borderRadius: BorderRadius.circular(46),
                            boxShadow: [
                              const BoxShadow(
                                  color: Color.fromRGBO(13, 213, 13, 0.1),
                                  offset: Offset(-4, 4),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                  inset: true),
                              const BoxShadow(
                                  color: Color.fromRGBO(13, 213, 13, 0.1),
                                  offset: Offset(4, 4),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                  inset: true),
                            ],
                          ),
                          child: Center(
                            child: viewModel.isBusy
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.green),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Creating...',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Create Goal Save',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      color: Colors.green,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
}

Widget _buildTextField({
  required TextEditingController controller,
  required String hintText,
  TextInputType? keyboardType,
  String? prefixText,
  bool readOnly = false,
  Function(String)? onChanged,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
        width: 1,
      ),
    ),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      inputFormatters: keyboardType == TextInputType.number 
          ? [
              NumberInputFormatter(maxDecimalPlaces: 2, allowDecimals: true),
            ]
          : null,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 16,
        ),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 16,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
      ),
    ),
  );
}

Widget _buildCategoryGrid(CreatePrivateGroupSaveViewModel viewModel) {
  final categories = [
    {
      'name': 'Rent/Accommodation',
      'icon': Icons.home,
      'color': const Color(0xFF8B5CF6),
      'bgColor': const Color(0xFF1E1B4B),
    },
    {
      'name': 'Vacation/Travel',
      'icon': Icons.flight,
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFF451A03),
    },
    {
      'name': 'Car/Vehicle',
      'icon': Icons.directions_car,
      'color': const Color(0xFF10B981),
      'bgColor': const Color(0xFF064E3B),
    },
    {
      'name': 'Fees or Debt',
      'icon': Icons.account_balance,
      'color': const Color(0xFF06B6D4),
      'bgColor': const Color(0xFF164E63),
    },
    {
      'name': 'Education',
      'icon': Icons.school,
      'color': const Color(0xFF8B5CF6),
      'bgColor': const Color(0xFF1E1B4B),
    },
    {
      'name': 'Starting/Growing Business',
      'icon': Icons.business,
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFF451A03),
    },
    {
      'name': 'Events',
      'icon': Icons.event,
      'color': const Color(0xFFEF4444),
      'bgColor': const Color(0xFF450A0A),
    },
    {
      'name': 'Birthday',
      'icon': Icons.cake,
      'color': const Color(0xFFEC4899),
      'bgColor': const Color(0xFF500724),
    },
    {
      'name': 'Gadgets',
      'icon': Icons.phone_android,
      'color': const Color(0xFF6366F1),
      'bgColor': const Color(0xFF1E1B4B),
    },
    {
      'name': 'Investments',
      'icon': Icons.trending_up,
      'color': const Color(0xFF10B981),
      'bgColor': const Color(0xFF064E3B),
    },
    {
      'name': 'Challenge/Contents',
      'icon': Icons.emoji_events,
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFF451A03),
    },
    {
      'name': 'Unforeseen Circumstances',
      'icon': Icons.warning,
      'color': const Color(0xFFEF4444),
      'bgColor': const Color(0xFF450A0A),
    },
    {
      'name': 'No Reason',
      'icon': Icons.help_outline,
      'color': const Color(0xFF6B7280),
      'bgColor': const Color(0xFF1F2937),
    },
    {
      'name': 'Another Reason',
      'icon': Icons.more_horiz,
      'color': const Color(0xFF6B7280),
      'bgColor': const Color(0xFF1F2937),
    },
  ];

  return SizedBox(
    height: 120,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = viewModel.selectedCategory == category['name'];

        return GestureDetector(
          onTap: () => viewModel.selectCategory(category['name'] as String),
          child: Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? category['color'] as Color
                  : category['bgColor'] as Color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? category['color'] as Color
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? (category['color'] as Color).withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category['icon'] as IconData,
                  color: isSelected ? Colors.white : category['color'] as Color,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildFrequencySelection(CreatePrivateGroupSaveViewModel viewModel) {
  final frequencies = ['Daily', 'Weekly', 'Monthly', 'Manual'];

  return Row(
    children: frequencies.map((frequency) {
      final isSelected = viewModel.selectedFrequency == frequency;

      return Expanded(
        child: GestureDetector(
          onTap: () => viewModel.selectFrequency(frequency),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: isSelected
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(46),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(13, 213, 13, 0.1),
                        offset: const Offset(-4, 4),
                        blurRadius: 20,
                        inset: true, // inside shadow
                      ),
                      BoxShadow(
                        color: const Color.fromRGBO(13, 213, 13, 0.1),
                        offset: const Offset(4, 4),
                        blurRadius: 6,
                        inset: true, // inside shadow
                      ),
                    ],
                  )
                : BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(46),
                    border: Border.all(
                      color: const Color(0xFFDADADA),
                      width: 1,
                    ),
                  ),
            child: Text(
              frequency,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0DD50D) : Colors.black87,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

Widget _buildFrequencySpecificOptions(
    BuildContext context, CreatePrivateGroupSaveViewModel viewModel) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Preferred Time
      _buildSectionTitle('Preferred Time'),
      const SizedBox(height: 12),
      _buildTimeSelector(context, viewModel),

      const SizedBox(height: 16),

      // Day selection based on frequency
      if (viewModel.selectedFrequency == 'Weekly') ...[
        _buildSectionTitle('Day of Week'),
        const SizedBox(height: 12),
        _buildDayOfWeekSelector(viewModel),
      ] else if (viewModel.selectedFrequency == 'Monthly') ...[
        _buildSectionTitle('Day of Month'),
        const SizedBox(height: 12),
        _buildDayOfMonthSelector(viewModel),
      ],
    ],
  );
}

Widget _buildTimeSelector(
    BuildContext context, CreatePrivateGroupSaveViewModel viewModel) {
  return GestureDetector(
    onTap: () => viewModel.selectPreferredTime(context),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            viewModel.preferredTime != null
                ? '${viewModel.preferredTime!.hour.toString().padLeft(2, '0')}:${viewModel.preferredTime!.minute.toString().padLeft(2, '0')}'
                : 'Select preferred time',
            style: TextStyle(
              color: viewModel.preferredTime != null
                  ? Colors.black
                  : const Color(0xFF9CA3AF),
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDayOfWeekSelector(CreatePrivateGroupSaveViewModel viewModel) {
  final days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  return SizedBox(
    height: 50,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final isSelected = viewModel.selectedDayOfWeek == day;

        return GestureDetector(
          onTap: () => viewModel.selectDayOfWeek(day),
          child: Container(
            width: 70,
            height: 70,
            margin: const EdgeInsets.only(right: 8),
            decoration: isSelected
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(13, 213, 13, 0.1),
                        offset: const Offset(-4, 4),
                        blurRadius: 20,
                        inset: true, // inside shadow
                      ),
                      BoxShadow(
                        color: const Color.fromRGBO(13, 213, 13, 0.1),
                        offset: const Offset(4, 4),
                        blurRadius: 6,
                        inset: true, // inside shadow
                      ),
                    ],
                  )
                : BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFDADADA),
                      width: 1,
                    ),
                  ),
            alignment: Alignment.center,
            child: Text(
              day.substring(0, 3),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0DD50D) : Colors.black87,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildDayOfMonthSelector(CreatePrivateGroupSaveViewModel viewModel) {
  final days = List.generate(28, (index) => index + 1);

  return SizedBox(
    height: 40,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final isSelected = viewModel.selectedDayOfMonth == day;

        return GestureDetector(
          onTap: () => viewModel.selectDayOfMonth(day),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: isSelected
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(13, 213, 13, 0.1),
                        offset: const Offset(-4, 4),
                        blurRadius: 20,
                        inset: true, // inside shadow
                      ),
                      BoxShadow(
                        color: const Color.fromRGBO(13, 213, 13, 0.1),
                        offset: const Offset(4, 4),
                        blurRadius: 6,
                        inset: true, // inside shadow
                      ),
                    ],
                  )
                : BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3.53),
                    border: Border.all(
                      color: const Color(0xFFDADADA),
                      width: 1,
                    ),
                  ),
            child: Text(
              day.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0DD50D) : Colors.black87,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildDateSelector({
  required BuildContext context,
  required DateTime? selectedDate,
  required VoidCallback onTap,
  required String label,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            selectedDate != null
                ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                : label,
            style: TextStyle(
              color:
                  selectedDate != null ? Colors.black : const Color(0xFF9CA3AF),
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDropdownTextField(
  BuildContext context,
  CreatePrivateGroupSaveViewModel viewModel,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Text Field
      GestureDetector(
        onTap: viewModel.toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  viewModel.textController.text.isEmpty
                      ? 'Select an option'
                      : viewModel.textController.text,
                  style: TextStyle(
                    color: viewModel.textController.text.isEmpty
                        ? const Color(0xFF9CA3AF)
                        : Colors.grey[800],
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(
                viewModel.isDropdownOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: const Color(0xFF9CA3AF),
                size: 20,
              ),
            ],
          ),
        ),
      ),

      // Dropdown List
      if (viewModel.isDropdownOpen) ...[
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            children: viewModel.filteredOptions
                .map((option) => _buildDropdownItem(
                      context,
                      option,
                      viewModel,
                    ))
                .toList(),
          ),
        ),
      ],
    ],
  );
}

Widget _buildDropdownItem(
  BuildContext context,
  String option,
  CreatePrivateGroupSaveViewModel viewModel,
) {
  final isLast = viewModel.filteredOptions.last == option;

  return InkWell(
    onTap: () => viewModel.selectOption(option),
    borderRadius: BorderRadius.vertical(
      top: viewModel.filteredOptions.first == option
          ? const Radius.circular(12)
          : Radius.zero,
      bottom: isLast ? const Radius.circular(12) : Radius.zero,
    ),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: Text(
        option,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    ),
  );
}

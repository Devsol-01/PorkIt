import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/services.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'create_lock_viewmodel.dart';
import 'package:mobile_app/utils/format_utils.dart';
import 'package:mobile_app/utils/input_formatters.dart';

class CreateLockView extends StackedView<CreateLockViewModel> {
  final Map<String, dynamic> selectedPeriod;

  const CreateLockView({
    super.key,
    required this.selectedPeriod,
  });

  @override
  Widget builder(
    BuildContext context,
    CreateLockViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => viewModel.navigateBack(),
        ),
        title: Text(
          'Create SafeLock',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(selectedPeriod['color']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(selectedPeriod['color']).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(selectedPeriod['color']),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedPeriod['label'],
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Up to ${selectedPeriod['interestRate']}% per annum',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Amount Input
              Text(
                'Amount to Lock',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFA82F),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: viewModel.amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  NumberInputFormatter(maxDecimalPlaces: 2, allowDecimals: true),
                ],
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixText: '\$ ',
                  prefixStyle: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  viewModel.updateAmount(value);
                },
              ),

              const SizedBox(height: 24),

              // Title Input
              Text(
                'Lock Title',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFA82F),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: viewModel.titleController,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g., Emergency Fund',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.black,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Fund Source
              Text(
                'Fund Source',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFA82F),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color(0xFF9CA3AF),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: viewModel.selectedFundSource,
                    isExpanded: true,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    items: ['Porket Wallet', 'External Wallet', 'Add Card']
                        .map((source) => DropdownMenuItem(
                              value: source,
                              child: Text(source),
                            ))
                        .toList(),
                    onChanged: (value) => viewModel.setFundSource(value!),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payback Date Selection
              Text(
                'Select Payback Date',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFA82F),
                ),
              ),
              const SizedBox(height: 12),

              // Dynamic Date Options
// Dynamic Date Options
              if (viewModel.amount > 0) ...[
                Container(
                  height: 220,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    itemCount: viewModel.generateDateOptions().length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemBuilder: (context, index) {
                      final dateOptions = viewModel.generateDateOptions();
                      final option = dateOptions[index];
                      final isSelected =
                          viewModel.selectedDays == option['days'];

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => viewModel.selectDate(option['days']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(selectedPeriod['color'])
                                    .withOpacity(0.1) // light tint
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Color(selectedPeriod[
                                      'color']) // highlight border
                                  : const Color(0xFFE5E7EB),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Days badge
                              Container(
                                width: 50,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Color(selectedPeriod['color'])
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${option['days']}d',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(selectedPeriod['color']),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Date
                              Expanded(
                                child: Text(
                                  option['date'],
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Color(selectedPeriod['color'])
                                        : Colors.black87,
                                  ),
                                ),
                              ),

                              // Interest Rate
                              Text(
                                '${option['interestRate'].toStringAsFixed(2)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(selectedPeriod['color']),
                                ),
                              ),

                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: Color(selectedPeriod['color']),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      'Enter amount to see payback date options',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Preview Button
              GestureDetector(
                onTap:
                    viewModel.isBusy ? null : () => viewModel.createLockSave(),
                child: Container(
                  width: 358,
                  height: 45,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white, // Light mode background
                    borderRadius: BorderRadius.circular(46),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFA82F).withOpacity(0.1),
                        offset: const Offset(-4, 4),
                        blurRadius: 20,
                        spreadRadius: 0,
                        inset:
                            true, // 👈 requires flutter_inset_box_shadow package
                      ),
                      BoxShadow(
                        color: const Color(0xFFFFA82F).withOpacity(0.1),
                        offset: const Offset(4, 4),
                        blurRadius: 6,
                        spreadRadius: 0,
                        inset: true, // 👈
                      ),
                    ],
                  ),
                  child: viewModel.isBusy
                      ? Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Creating...',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Text(
                            'Create SafeLock',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFFA82F),
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  CreateLockViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      CreateLockViewModel(selectedPeriod);
}

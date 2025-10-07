import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';
import 'package:mobile_app/utils/input_formatters.dart';
import 'register_viewmodel.dart';

class RegisterView extends StackedView<RegisterViewModel> {
  const RegisterView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    RegisterViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Header
              _buildHeader(),
              const SizedBox(height: 40),

              // Registration Form
              _buildRegistrationForm(viewModel),
              const SizedBox(height: 24),

              // Register Button
              _buildRegisterButton(viewModel),
              const SizedBox(height: 24),

              // Login Link
              _buildLoginLink(viewModel),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Logo/Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        const Text(
          'Create Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        const Text(
          'Join the future of decentralized finance',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(RegisterViewModel viewModel) {
    return Column(
      children: [
        // First Name
        _buildTextField(
          controller: viewModel.firstNameController,
          label: 'First Name',
          hint: 'Enter your first name',
          icon: Icons.person_outline,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Last Name
        _buildTextField(
          controller: viewModel.lastNameController,
          label: 'Last Name',
          hint: 'Enter your last name',
          icon: Icons.person_outline,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Email
        _buildTextField(
          controller: viewModel.emailController,
          label: 'Email Address',
          hint: 'Enter your email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Password
        _buildTextField(
          controller: viewModel.passwordController,
          label: 'Password',
          hint: 'Create a strong password',
          icon: Icons.lock_outline,
          isPassword: true,
          isPasswordVisible: viewModel.isPasswordVisible,
          onPasswordToggle: viewModel.togglePasswordVisibility,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Confirm Password
        _buildTextField(
          controller: viewModel.confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Confirm your password',
          icon: Icons.lock_outline,
          isPassword: true,
          isPasswordVisible: viewModel.isConfirmPasswordVisible,
          onPasswordToggle: viewModel.toggleConfirmPasswordVisibility,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Referral Code (Optional)
        _buildTextField(
          controller: viewModel.referralCodeController,
          label: 'Referral Code (Optional)',
          hint: 'Enter referral code if you have one',
          icon: Icons.card_giftcard_outlined,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onPasswordToggle,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: onPasswordToggle,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(RegisterViewModel viewModel) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: viewModel.isBusy ? null : viewModel.register,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C5CE7),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: viewModel.isBusy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink(RegisterViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.grey),
        ),
        GestureDetector(
          onTap: viewModel.navigateToLogin,
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Color(0xFF6C5CE7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  RegisterViewModel viewModelBuilder(BuildContext context) =>
      RegisterViewModel();
}

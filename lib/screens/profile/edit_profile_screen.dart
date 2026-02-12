import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user!;

    UserModel updatedUser = user.copyWith(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      updatedAt: DateTime.now(),
    );

    bool success = await authProvider.updateUser(updatedUser);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Cập nhật thành công'
                : authProvider.error ?? 'Đã có lỗi xảy ra',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.editProfile),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.user;
                  return Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: user?.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.avatarUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.primary,
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Full name
              TextFormField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: AppStrings.fullName,
                  prefixIcon: const Icon(Icons.person_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email (read-only)
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return TextFormField(
                    initialValue: authProvider.user?.email,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: AppStrings.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          AppStrings.save,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

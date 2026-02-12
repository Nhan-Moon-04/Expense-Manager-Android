import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../../services/cloudinary_service.dart';

class CreateGroupScreen extends StatefulWidget {
  final GroupModel? group; // null for create, not null for edit

  const CreateGroupScreen({super.key, this.group});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _targetDescriptionController = TextEditingController();
  final _cloudinaryService = CloudinaryService();

  File? _selectedImage;
  String? _avatarUrl;
  DateTime? _targetDeadline;
  bool _hasTarget = false;
  bool _isLoading = false;

  bool get isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description ?? '';
      _avatarUrl = widget.group!.avatarUrl;

      if (widget.group!.targetAmount != null &&
          widget.group!.targetAmount! > 0) {
        _hasTarget = true;
        _targetAmountController.text = widget.group!.targetAmount!
            .toStringAsFixed(0);
        _targetDescriptionController.text =
            widget.group!.targetDescription ?? '';
        _targetDeadline = widget.group!.targetDeadline;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _targetDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Chỉnh sửa nhóm' : 'Tạo nhóm mới',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatarSection(),
              const SizedBox(height: 32),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildTargetSection(),
              const SizedBox(height: 40),
              _buildSubmitButton(),
              if (isEditing) ...[
                const SizedBox(height: 16),
                _buildDeleteButton(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: _selectedImage == null && _avatarUrl == null
                    ? const LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                image: _selectedImage != null
                    ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      )
                    : _avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _selectedImage == null && _avatarUrl == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thêm ảnh',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ảnh đại diện nhóm',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Thông tin cơ bản'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nameController,
          label: 'Tên nhóm',
          hint: 'VD: Chi tiêu gia đình',
          prefixIcon: Icons.group_rounded,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên nhóm';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'Mô tả',
          hint: 'Mô tả ngắn về nhóm (không bắt buộc)',
          prefixIcon: Icons.description_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTargetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Mục tiêu hùn tiền'),
            Switch(
              value: _hasTarget,
              onChanged: (value) {
                setState(() {
                  _hasTarget = value;
                  if (!value) {
                    _targetAmountController.clear();
                    _targetDescriptionController.clear();
                    _targetDeadline = null;
                  }
                });
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
        if (_hasTarget) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _targetAmountController,
            label: 'Số tiền mục tiêu',
            hint: 'VD: 10000000',
            prefixIcon: Icons.savings_rounded,
            keyboardType: TextInputType.number,
            suffixText: '₫',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _targetDescriptionController,
            label: 'Tên mục tiêu',
            hint: 'VD: Du lịch Đà Lạt',
            prefixIcon: Icons.flag_rounded,
          ),
          const SizedBox(height: 16),
          _buildDatePicker(),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    String? suffixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textHint),
          labelStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(prefixIcon, color: AppColors.primary),
          suffixText: suffixText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate:
              _targetDeadline ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() {
            _targetDeadline = date;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hạn chót',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _targetDeadline != null
                        ? DateFormat('dd/MM/yyyy').format(_targetDeadline!)
                        : 'Chọn ngày (không bắt buộc)',
                    style: TextStyle(
                      fontSize: 16,
                      color: _targetDeadline != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                isEditing ? 'Lưu thay đổi' : 'Tạo nhóm',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _showDeleteConfirmation,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Xóa nhóm',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chọn ảnh đại diện',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildImageOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Chụp ảnh',
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        setState(() {
                          _selectedImage = File(image.path);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Thư viện',
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        setState(() {
                          _selectedImage = File(image.path);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? uploadedAvatarUrl = _avatarUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        final groupId = isEditing
            ? widget.group!.id
            : 'new_${DateTime.now().millisecondsSinceEpoch}';
        uploadedAvatarUrl = await _cloudinaryService.uploadGroupAvatar(
          _selectedImage!,
          groupId,
        );
      }

      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      double? targetAmount;
      if (_hasTarget && _targetAmountController.text.isNotEmpty) {
        targetAmount = double.tryParse(
          _targetAmountController.text.replaceAll(',', ''),
        );
      }

      bool success;
      if (isEditing) {
        final updatedGroup = widget.group!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          avatarUrl: uploadedAvatarUrl,
          targetAmount: _hasTarget ? targetAmount : null,
          targetDescription:
              _hasTarget && _targetDescriptionController.text.trim().isNotEmpty
              ? _targetDescriptionController.text.trim()
              : null,
          targetDeadline: _hasTarget ? _targetDeadline : null,
          updatedAt: DateTime.now(),
        );
        success = await groupProvider.updateGroup(updatedGroup);
      } else {
        success = await groupProvider.createGroup(
          name: _nameController.text.trim(),
          ownerId: authProvider.user!.uid,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          avatarUrl: uploadedAvatarUrl,
          targetAmount: _hasTarget ? targetAmount : null,
          targetDescription:
              _hasTarget && _targetDescriptionController.text.trim().isNotEmpty
              ? _targetDescriptionController.text.trim()
              : null,
          targetDeadline: _hasTarget ? _targetDeadline : null,
          ownerDisplayName: authProvider.user!.fullName,
          ownerAvatarUrl: authProvider.user!.avatarUrl,
        );
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Cập nhật nhóm thành công!'
                    : 'Tạo nhóm thành công!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(groupProvider.error ?? 'Đã có lỗi xảy ra'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa nhóm'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa nhóm này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              final groupProvider = Provider.of<GroupProvider>(
                context,
                listen: false,
              );
              final success = await groupProvider.deleteGroup(widget.group!.id);

              if (mounted) {
                setState(() {
                  _isLoading = false;
                });

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã xóa nhóm'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

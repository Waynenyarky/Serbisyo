import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/profile_storage.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Decade options for "Decade I was born".
const List<String> kDecadeOptions = [
  '1960s',
  '1970s',
  '1980s',
  '1990s',
  '2000s',
  '2010s',
];

class ProfileDetailScreen extends ConsumerStatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  ConsumerState<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  bool _isEditing = false;
  String? _selectedDecade;
  final _decadeController = TextEditingController();
  final _whereWantedController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final decade = await getDecadeBorn();
    final where = await getWhereAlwaysWanted();
    final phone = await getProfilePhone();
    final address = await getProfileAddress();
    final bio = await getProfileBio();
    _decadeController.text = decade ?? '';
    _selectedDecade = (decade != null && decade.isNotEmpty) ? decade : null;
    _whereWantedController.text = where ?? '';
    _phoneController.text = phone ?? '';
    _addressController.text = address ?? '';
    _bioController.text = bio ?? '';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _decadeController.dispose();
    _whereWantedController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await saveProfileExtended(
      decadeBorn: (_selectedDecade ?? _decadeController.text).trim(),
      whereAlwaysWanted: _whereWantedController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      bio: _bioController.text.trim(),
    );
    ref.invalidate(profileExtendedProvider);
    if (mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }

  bool get _canSave {
    final decade = _selectedDecade ?? _decadeController.text.trim();
    return decade.isNotEmpty &&
        _whereWantedController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileExtendedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Get Started'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _canSave
                  ? () async => await _save()
                  : null,
              child: const Text('Save'),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              userAsync.when(
                data: (user) => _ProfileHeader(name: user?.name ?? 'Guest', email: user?.email ?? ''),
                loading: () => const _ProfileHeader(name: '...', email: '...'),
                error: (e, s) => const _ProfileHeader(name: 'Guest', email: ''),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!_isEditing) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.rocket_launch_rounded, size: 22),
                    label: const Text('Get Started'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (_isEditing) ...[
                _SectionTitle(title: 'About you'),
                const SizedBox(height: AppSpacing.sm),
                _DropdownField(
                  label: 'Decade I was born',
                  hint: 'Select decade',
                  initialValue: _selectedDecade,
                  options: kDecadeOptions,
                  onChanged: (v) {
                    setState(() {
                      _selectedDecade = v;
                      _decadeController.text = v ?? '';
                    });
                  },
                  required: true,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _whereWantedController,
                  decoration: const InputDecoration(
                    labelText: "Where I've always wanted to get a service",
                    hintText: 'e.g. At home with a view, a cozy café area...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+63 912 345 6789',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Street, city, region',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Short bio (optional)',
                    hintText: 'A bit about yourself...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _canSave ? () async => await _save() : null,
                  child: const Text('Save profile'),
                ),
              ] else
                profileAsync.when(
                  data: (p) => _ProfileViewContent(profile: p),
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.primary))),
                  error: (err, stack) => const _ProfileViewContent(profile: null),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.email});

  final String name;
  final String email;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.isNotEmpty ? parts.first.substring(0, 1).toUpperCase() : '?';
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primaryLight.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              _initials,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(email, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.options,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final String hint;
  final String? initialValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
      ),
      items: options.map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: onChanged,
    );
  }
}

class _ProfileViewContent extends StatelessWidget {
  const _ProfileViewContent({this.profile});

  final ProfileExtended? profile;

  @override
  Widget build(BuildContext context) {
    if (profile == null || !profile!.isComplete) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete your profile',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap Edit (top right) to add Decade I was born, where you\'ve always wanted to get a service, phone, and address.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final p = profile!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ViewRow(label: 'Decade I was born', value: p.decadeBorn),
          const SizedBox(height: 12),
          _ViewRow(label: "Where I've always wanted to get a service", value: p.whereAlwaysWanted),
          const SizedBox(height: 12),
          _ViewRow(label: 'Phone', value: p.phone),
          const SizedBox(height: 12),
          _ViewRow(label: 'Address', value: p.address),
          if (p.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ViewRow(label: 'Bio', value: p.bio),
          ],
        ],
      ),
    );
  }
}

class _ViewRow extends StatelessWidget {
  const _ViewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

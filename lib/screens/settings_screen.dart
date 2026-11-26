import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/event_bus.dart';
import '../core/premium_ui.dart';
import '../services/backup_service.dart';
import '../services/storage_services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _soundEffects = true;
  String _userName = 'Champion';
  String _userTitle = 'Fitness Enthusiast';
  int _recoveryCoins = 0;
  int _weight = 70;
  int _age = 25;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WorkoutEventBus.instance.revision.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) _loadSettings();
  }

  @override
  void dispose() {
    WorkoutEventBus.instance.revision.removeListener(_onDataChanged);
    super.dispose();
  }

  void _loadSettings() {
    setState(() {
      _notifications = SettingsStorage.getNotifications();
      _soundEffects = SettingsStorage.getSoundEffects();
      _userName = SettingsStorage.getUserName();
      _userTitle = SettingsStorage.getUserTitle();
      _recoveryCoins = SettingsStorage.getRecoveryCoins();
      _weight = SettingsStorage.getWeight();
      _age = SettingsStorage.getAge();
    });
  }

  Future<void> _exportBackup() async {
    try {
      final result = await BackupService.exportBackup();
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: PUI.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (BuildContext sheetContext) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  const Icon(Icons.check_circle, color: PUI.mint, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Backup Ready',
                      style: PUI.text(size: 20, weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.savedFilePath != null
                    ? 'Saved locally to:\n${result.savedFilePath}\n\nCopy the JSON below to keep an external copy in Notes, Drive, or Files.'
                    : 'Copy the JSON below to save your backup anywhere.',
                style: PUI.text(
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Copy Backup JSON',
                icon: Icons.copy_rounded,
                height: 54,
                onTap: () async {
                  final sheetNav = Navigator.of(sheetContext);
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: result.json));
                  if (!mounted) return;
                  sheetNav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Backup JSON copied to clipboard!',
                        style: PUI.text(
                          color: Colors.black,
                          weight: FontWeight.w700,
                        ),
                      ),
                      backgroundColor: PUI.mint,
                    ),
                  );
                },
              ),
              SizedBox(height: MediaQuery.of(sheetContext).padding.bottom + 8),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup failed: $e'),
          backgroundColor: PUI.flame,
        ),
      );
    }
  }

  Future<void> _showRestoreBackupSheet() async {
    final localBackups = await BackupService.listLocalBackups();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: PUI.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) => _RestoreBackupSheet(
        localBackups: localBackups,
        onRestored: (BackupRestoreSummary summary) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Restored ${summary.workoutsRestored} workouts, '
                '${summary.routinesRestored} routines & '
                '${summary.splitsRestored} splits!',
                style: PUI.text(
                  color: Colors.black,
                  weight: FontWeight.w700,
                ),
              ),
              backgroundColor: PUI.mint,
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final updated = await showDialog<({String name, String title})>(
      context: context,
      builder: (_) => _EditProfileDialog(
        initialName: _userName,
        initialTitle: _userTitle,
      ),
    );

    if (updated == null) return;
    if (updated.name.isNotEmpty) {
      await SettingsStorage.setUserName(updated.name);
    }
    if (updated.title.isNotEmpty) {
      await SettingsStorage.setUserTitle(updated.title);
    }
  }

  Future<void> _confirmClearHistory() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: PUI.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Clear History?',
          style: PUI.text(size: 20, weight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently delete all your logged workout sessions.',
          style: PUI.text(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: PUI.text(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PUI.flame,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Clear', style: PUI.text(weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await WorkoutStorage.clearAll();
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Workout history cleared.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      aurora: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'PREFERENCES',
                        style: PUI.text(
                          size: 11,
                          weight: FontWeight.w600,
                          letterSpacing: 2.2,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const GradientText('Customize', size: 32),
                    ],
                  ),
                  const Glass(
                    radius: 16,
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.settings_rounded,
                      color: PUI.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Pressable(
                onTap: _showEditProfileDialog,
                child: Glass(
                  radius: 24,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: <Color>[PUI.primary, PUI.primaryDeep],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: PUI.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'U',
                            style: PUI.text(size: 28, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _userName,
                              style: PUI.text(
                                size: 20,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userTitle,
                              style: PUI.text(
                                size: 13,
                                color: PUI.primary,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: SectionTitle('Body Stats'),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Glass(
                radius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    _NumberInputRow(
                      label: 'Weight (kg)',
                      value: _weight,
                      icon: Icons.scale,
                      color: PUI.primary,
                      onChanged: (int value) =>
                          unawaited(SettingsStorage.setWeight(value)),
                    ),
                    const SizedBox(height: 12),
                    _NumberInputRow(
                      label: 'Age (years)',
                      value: _age,
                      icon: Icons.cake_outlined,
                      color: PUI.mint,
                      onChanged: (int value) =>
                          unawaited(SettingsStorage.setAge(value)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: SectionTitle('Recovery Bank'),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Glass(
                radius: 20,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PUI.mint.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: PUI.mint,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Current Balance',
                            style: PUI.text(size: 16, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_recoveryCoins Coins available to freeze streaks',
                            style: PUI.text(
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: SectionTitle('App Settings'),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildSettingToggle(
                'Streak Reminders',
                'Show Home reminder banner when streak is at risk',
                Icons.notifications_outlined,
                _notifications,
                (bool v) => unawaited(SettingsStorage.setNotifications(v)),
                PUI.primary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildSettingToggle(
                'Sound Effects',
                'Click sounds when logging sets and switching tabs',
                Icons.volume_up_outlined,
                _soundEffects,
                (bool v) => unawaited(SettingsStorage.setSoundEffects(v)),
                PUI.pink,
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: SectionTitle('Data Management'),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildSettingItem(
                'Export Backup',
                Icons.cloud_upload_outlined,
                PUI.mint,
                onTap: _exportBackup,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildSettingItem(
                'Import / Restore Backup',
                Icons.restore_rounded,
                PUI.primary,
                onTap: _showRestoreBackupSheet,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildSettingItem(
                'Clear Workout History',
                Icons.delete_outline,
                PUI.flame,
                onTap: _confirmClearHistory,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) {
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: PUI.text(size: 15, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: PUI.text(
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
              return s.contains(WidgetState.selected) ? color : Colors.white70;
            }),
            trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
              return s.contains(WidgetState.selected)
                  ? color.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.12);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Pressable(
      onTap: onTap,
      child: Glass(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: PUI.text(size: 15, weight: FontWeight.w700),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.4),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final String initialName;
  final String initialTitle;

  const _EditProfileDialog({
    required this.initialName,
    required this.initialTitle,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialName,
  );
  late final TextEditingController _titleController = TextEditingController(
    text: widget.initialTitle,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      (
        name: _nameController.text.trim(),
        title: _titleController.text.trim(),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: PUI.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PUI.primary.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        style: PUI.text(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: PUI.text(color: Colors.white.withValues(alpha: 0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PUI.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Edit Profile',
        style: PUI.text(size: 20, weight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildTextField(_nameController, 'Your name'),
          const SizedBox(height: 12),
          _buildTextField(
            _titleController,
            'Your title (e.g. Fitness Enthusiast)',
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: PUI.text(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: PUI.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Save', style: PUI.text(weight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _RestoreBackupSheet extends StatefulWidget {
  final List<LocalBackupFileEntry> localBackups;
  final ValueChanged<BackupRestoreSummary> onRestored;

  const _RestoreBackupSheet({
    required this.localBackups,
    required this.onRestored,
  });

  @override
  State<_RestoreBackupSheet> createState() => _RestoreBackupSheetState();
}

class _RestoreBackupSheetState extends State<_RestoreBackupSheet> {
  final TextEditingController _jsonController = TextEditingController();
  String? _errorMessage;
  bool _isRestoring = false;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || data?.text == null) return;
    setState(() {
      _jsonController.text = data!.text!;
      _errorMessage = null;
    });
  }

  Future<void> _restoreJson(String rawJson) async {
    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });
    try {
      final summary = await BackupService.restoreFromJson(rawJson);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onRestored(summary);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _errorMessage = e.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  Future<void> _restoreLocalFile(LocalBackupFileEntry entry) async {
    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });
    try {
      final summary = await BackupService.restoreFromFile(entry.path);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onRestored(summary);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Restore Backup',
              style: PUI.text(size: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Restore from a saved local backup file or paste backup JSON.',
              style: PUI.text(
                size: 13,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            if (widget.localBackups.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              const SectionTitle('Saved Local Backups'),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.localBackups.length,
                  itemBuilder: (BuildContext context, int index) {
                    final file = widget.localBackups[index];
                    return Pressable(
                      onTap: _isRestoring
                          ? null
                          : () => _restoreLocalFile(file),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.description_outlined,
                              color: PUI.mint,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PUI.text(
                                  size: 13,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.restore,
                              color: PUI.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const SectionTitle('Paste Backup JSON'),
                TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste_rounded, size: 16),
                  label: Text(
                    'Paste Clipboard',
                    style: PUI.text(
                      size: 12,
                      color: PUI.mint,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: PUI.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PUI.primary.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _jsonController,
                maxLines: 4,
                style: PUI.text(size: 12),
                decoration: InputDecoration(
                  hintText: '{"version": 1, "workouts": [...], ...}',
                  hintStyle: PUI.text(
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: PUI.text(
                  size: 12,
                  color: PUI.flame,
                  weight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: _isRestoring ? 'Restoring...' : 'Restore from JSON',
              icon: Icons.restore_rounded,
              height: 54,
              muted: _isRestoring,
              onTap: _isRestoring
                  ? null
                  : () => _restoreJson(_jsonController.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberInputRow extends StatefulWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final ValueChanged<int> onChanged;

  const _NumberInputRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  State<_NumberInputRow> createState() => _NumberInputRowState();
}

class _NumberInputRowState extends State<_NumberInputRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value.toString(),
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant _NumberInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _commitValue(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed != null && parsed > 0 && parsed <= 500) {
      widget.onChanged(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(widget.icon, color: widget.color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            widget.label,
            style: PUI.text(size: 15, weight: FontWeight.w700),
          ),
        ),
        SizedBox(
          width: 84,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            textAlign: TextAlign.center,
            style: PUI.text(
              size: 18,
              weight: FontWeight.w800,
              color: widget.color,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.color.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.color, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.color.withValues(alpha: 0.3),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: _commitValue,
            onSubmitted: _commitValue,
            onTapOutside: (_) => _focusNode.unfocus(),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';
import '../core/premium_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _soundEffects = true;
  String _userName = 'Mitesh';
  String _userTitle = 'Fitness Enthusiast';
  int _recoveryCoins = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _notifications = SettingsStorage.getNotifications();
      _soundEffects = SettingsStorage.getSoundEffects();
      _userName = SettingsStorage.getUserName();
      _userTitle = SettingsStorage.getUserTitle();
      _recoveryCoins = SettingsStorage.getRecoveryCoins();
    });
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final titleController = TextEditingController(text: _userTitle);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PUI.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Profile', style: PUI.text(size: 20, weight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(nameController, 'Your name'),
            const SizedBox(height: 12),
            _buildTextField(titleController, 'Your title (e.g. Fitness Enthusiast)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: PUI.text(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newTitle = titleController.text.trim();
              if (newName.isNotEmpty) {
                await SettingsStorage.setUserName(newName);
                await SettingsStorage.setUserTitle(newTitle.isNotEmpty ? newTitle : _userTitle);
                setState(() {
                  _userName = newName;
                  _userTitle = newTitle.isNotEmpty ? newTitle : _userTitle;
                });
              }
              if (!mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PUI.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save', style: PUI.text(weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: PUI.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PUI.primary.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        style: PUI.text(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: PUI.text(color: Colors.white.withOpacity(0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      aurora: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PREFERENCES",
                        style: PUI.text(
                          size: 11,
                          weight: FontWeight.w600,
                          letterSpacing: 2.2,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GradientText("Customize", size: 32),
                    ],
                  ),
                  Glass(
                    radius: 16,
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.settings_rounded, color: PUI.primary, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Profile Card ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Pressable(
                onTap: _showEditProfileDialog,
                child: Glass(
                  radius: 24,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [PUI.primary, PUI.primaryDeep],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: PUI.primary.withOpacity(0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                            style: PUI.text(size: 28, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_userName, style: PUI.text(size: 20, weight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              _userTitle,
                              style: PUI.text(size: 13, color: PUI.primary, weight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_rounded, color: Colors.white.withOpacity(0.5), size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Recovery Bank ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SectionTitle("Recovery Bank"),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Glass(
                radius: 20,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PUI.mint.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.shield, color: PUI.mint, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Current Balance",
                            style: PUI.text(size: 16, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$_recoveryCoins Coins available to freeze streaks",
                            style: PUI.text(size: 12, color: Colors.white.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── App Settings ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SectionTitle("App Settings"),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildSettingToggle(
                "Notifications",
                "Workout reminders",
                Icons.notifications_outlined,
                _notifications,
                (v) async {
                  await SettingsStorage.setNotifications(v);
                  setState(() => _notifications = v);
                },
                PUI.primary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildSettingToggle(
                "Sound Effects",
                "Timer and completion sounds",
                Icons.volume_up_outlined,
                _soundEffects,
                (v) async {
                  await SettingsStorage.setSoundEffects(v);
                  setState(() => _soundEffects = v);
                },
                PUI.pink,
              ),
            ),
            const SizedBox(height: 32),

            // ── Data Management ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SectionTitle("Data Management"),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildSettingItem(
                "Clear Workout History",
                Icons.delete_outline,
                PUI.flame,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: PUI.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Text("Clear History?", style: PUI.text(size: 20, weight: FontWeight.w700)),
                      content: Text(
                        "This will permanently delete all your workout data.",
                        style: PUI.text(color: Colors.white.withOpacity(0.7)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel", style: PUI.text(color: Colors.white.withOpacity(0.5))),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await WorkoutStorage.clearAll();
                            Navigator.pop(context);
                            _loadSettings();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PUI.flame,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("Clear", style: PUI.text(weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────

  Widget _buildSettingToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    Color color,
  ) {
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PUI.text(size: 15, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: PUI.text(size: 12, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
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
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: PUI.text(size: 15, weight: FontWeight.w700)),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4), size: 22),
          ],
        ),
      ),
    );
  }
}
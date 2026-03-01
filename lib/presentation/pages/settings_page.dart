import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final isDarkMode = state.themeMode == ThemeMode.dark;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'settings'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionHeader(context, 'preferences'.tr()),
              _buildSettingsTile(
                context,
                icon: Icons.dark_mode,
                title: isDarkMode ? 'dark_mode'.tr() : 'light_mode'.tr(),
                trailing: Switch(
                  value: isDarkMode,
                  activeColor: const Color(0xFFE50914),
                  onChanged: (val) {
                    context.read<SettingsCubit>().updateThemeMode(val);
                  },
                ),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.notifications,
                title: 'notifications'.tr(),
                trailing: Switch(
                  value: state.notificationsEnabled,
                  activeColor: const Color(0xFFE50914),
                  onChanged: (val) {
                    context.read<SettingsCubit>().updateNotifications(val);
                  },
                ),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.language,
                title: 'language'.tr(),
                trailing: DropdownButton<String>(
                  value: context.locale.languageCode,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  underline: const SizedBox(),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      context.setLocale(Locale(newValue));
                      context.read<SettingsCubit>().updateLocale(
                        Locale(newValue),
                      );
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'account'.tr()),
              _buildSettingsTile(
                context,
                icon: Icons.person,
                title: 'edit_profile'.tr(),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.security,
                title: 'security'.tr(),
              ),
              const SizedBox(height: 32),
              Divider(color: Theme.of(context).dividerColor.withOpacity(0.2)),
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'info'.tr()),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE50914).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.code, color: Color(0xFFE50914), size: 32),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'developed_by'.tr(),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'version'.tr(),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFE50914),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

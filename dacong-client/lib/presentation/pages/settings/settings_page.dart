import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildThemeSection(context),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '外观',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            _ThemeOption(
              title: '亮色',
              icon: Icons.light_mode,
              isSelected: themeMode == ThemeMode.light,
              onTap: () {
                context.read<ThemeCubit>().setLightTheme();
              },
            ),
            _ThemeOption(
              title: '暗色',
              icon: Icons.dark_mode,
              isSelected: themeMode == ThemeMode.dark,
              onTap: () {
                context.read<ThemeCubit>().setDarkTheme();
              },
            ),
            _ThemeOption(
              title: '跟随系统',
              icon: Icons.brightness_auto,
              isSelected: themeMode == ThemeMode.system,
              onTap: () {
                context.read<ThemeCubit>().setSystemTheme();
              },
            ),
          ],
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? primaryColor : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primaryColor : null,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: primaryColor,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

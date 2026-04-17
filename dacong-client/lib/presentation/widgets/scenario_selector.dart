import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// 场景选择器组件
class ScenarioSelector extends StatelessWidget {
  final String? selectedScenario;
  final Function(String) onScenarioSelected;

  const ScenarioSelector({
    super.key,
    required this.selectedScenario,
    required this.onScenarioSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final scenarios = [
      {
        'id': 'coding',
        'name': l10n.scenarioCoding,
        'icon': Icons.code,
        'description': l10n.scenarioCodingDesc,
      },
      {
        'id': 'video',
        'name': l10n.scenarioVideo,
        'icon': Icons.video_library,
        'description': l10n.scenarioVideoDesc,
      },
      {
        'id': 'image',
        'name': l10n.scenarioImage,
        'icon': Icons.image,
        'description': l10n.scenarioImageDesc,
      },
      {
        'id': 'chat',
        'name': l10n.scenarioChat,
        'icon': Icons.chat,
        'description': l10n.scenarioChatDesc,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectScenario,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: scenarios.length,
            itemBuilder: (context, index) {
              final scenario = scenarios[index];
              final isSelected = selectedScenario == scenario['id'];

              return _ScenarioCard(
                scenario: scenario,
                isSelected: isSelected,
                onTap: () => onScenarioSelected(scenario['id'] as String),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final Map<String, dynamic> scenario;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.scenario,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                scenario['icon'] as IconData,
                size: 40,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                scenario['name'] as String,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                scenario['description'] as String,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

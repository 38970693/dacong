import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../core/accessibility/accessibility_utils.dart';

/// 带无障碍支持的场景选择器组件
class AccessibleScenarioSelector extends StatelessWidget {
  final String? selectedScenario;
  final Function(String) onScenarioSelected;

  const AccessibleScenarioSelector({
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

    return Semantics(
      label: '场景选择区域',
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.selectScenario,
                style: Theme.of(context).textTheme.titleLarge,
              ),
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

                return _AccessibleScenarioCard(
                  scenario: scenario,
                  isSelected: isSelected,
                  onTap: () => onScenarioSelected(scenario['id'] as String),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessibleScenarioCard extends StatefulWidget {
  final Map<String, dynamic> scenario;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccessibleScenarioCard({
    required this.scenario,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AccessibleScenarioCard> createState() => _AccessibleScenarioCardState();
}

class _AccessibleScenarioCardState extends State<_AccessibleScenarioCard> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semanticLabel = AccessibilityUtils.generateSemanticLabel(
      label: '场景选项',
      value: '${widget.scenario['name']}，${widget.scenario['description']}',
      hint: widget.isSelected ? '已选中' : '双击选择此场景',
    );

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: widget.isSelected,
      enabled: true,
      onTap: widget.onTap,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey.keyLabel == 'Enter' ||
                event.logicalKey.keyLabel == ' ') {
              widget.onTap();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Card(
          elevation: widget.isSelected ? 8 : 2,
          color: widget.isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: InkWell(
            onTap: widget.onTap,
            focusNode: _focusNode,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 44, // 确保最小触摸目标尺寸
                minWidth: 44,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.scenario['icon'] as IconData,
                    size: 40,
                    color: widget.isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.scenario['name'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                          color: widget.isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.scenario['description'] as String,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

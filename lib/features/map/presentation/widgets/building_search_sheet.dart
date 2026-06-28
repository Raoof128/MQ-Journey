import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_journey/app/l10n/generated/app_localizations.dart';
import 'package:mq_journey/app/theme/mq_colors.dart';
import 'package:mq_journey/app/theme/mq_spacing.dart';
import 'package:mq_journey/core/utils/haptics.dart';
import 'package:mq_journey/features/map/domain/entities/building.dart';
import 'package:mq_journey/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_journey/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_journey/shared/extensions/context_extensions.dart';

class BuildingSearchSheet extends ConsumerStatefulWidget {
  const BuildingSearchSheet({super.key});

  @override
  ConsumerState<BuildingSearchSheet> createState() =>
      _BuildingSearchSheetState();
}

class _BuildingSearchSheetState extends ConsumerState<BuildingSearchSheet> {
  late final TextEditingController _controller;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(mapControllerProvider).value?.searchQuery ?? '',
    );
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(mapControllerProvider.notifier).updateSearchQuery(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final state = ref.watch(mapControllerProvider).value;
    final results = state?.searchResults ?? const <Building>[];
    final query = _controller.text.trim();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.15,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const <double>[0.15, 0.5, 0.9],
      builder: (context, scrollController) {
        return Material(
          color: isDark ? MqColors.charcoal800 : null,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(MqSpacing.space6),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(MqSpacing.space4),
            children: [
              TextField(
                controller: _controller,
                focusNode: _searchFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  color: isDark ? Colors.white : MqColors.contentPrimary,
                ),
                cursorColor: isDark ? Colors.white : MqColors.red,
                decoration: InputDecoration(
                  hintText: l10n.searchBuildingsPlaceholder,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white : MqColors.contentTertiary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white : MqColors.contentTertiary,
                  ),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _searchFocusNode.unfocus(),
              ),
              const SizedBox(height: MqSpacing.space4),
              ...results.map(
                (building) => ListTile(
                  title: Text(
                    building.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : MqColors.contentPrimary,
                    ),
                  ),
                  subtitle: Text(
                    building.code,
                    style: TextStyle(
                      color: isDark ? Colors.white : MqColors.contentSecondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isDark ? Colors.white : MqColors.contentTertiary,
                  ),
                  onTap: () {
                    final haptics =
                        ref
                            .read(settingsControllerProvider)
                            .value
                            ?.hapticsEnabled ??
                        true;
                    MqHaptics.selection(haptics);
                    _searchFocusNode.unfocus();
                    Navigator.of(context).pop(building);
                  },
                ),
              ),
              if (results.isEmpty && query.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: MqSpacing.space8,
                  ),
                  child: Center(
                    child: Text(
                      l10n.noBuildingsFound(query),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white : MqColors.contentTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

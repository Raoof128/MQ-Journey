import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_bottom_sheet.dart';

class BuildingActionsSheet extends ConsumerWidget {
  const BuildingActionsSheet({
    super.key,
    required this.buildingId,
    required this.buildingName,
  });

  final String buildingId;
  final String buildingName;

  static Future<void> show(
    BuildContext context, {
    required String buildingId,
    required String buildingName,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BuildingActionsSheet(
        buildingId: buildingId,
        buildingName: buildingName,
      ),
    );

    if (context.mounted) {
      context.goNamed(
        RouteNames.map,
        queryParameters: {'building': buildingId},
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dark = context.isDarkMode;

    return MqBottomSheet(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: MqSpacing.space2,
          vertical: MqSpacing.space2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: MqSpacing.space2,
                vertical: MqSpacing.space1,
              ),
              child: Text(
                buildingName,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : MqColors.contentPrimary,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: l10n.openDay_viewInCampusMapSemantic(buildingName),
              child: ListTile(
                leading: Icon(
                  Icons.location_on_rounded,
                  color: dark ? MqColors.brightRed : MqColors.red,
                ),
                title: Text(
                  l10n.openDay_viewInCampusMap,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(l10n.openDay_openInsideMqNav),
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

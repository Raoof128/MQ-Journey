import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_bottom_sheet.dart';

/// Generic building navigation action sheet — the same two-option
/// "View in Campus Map / Navigate with Google Maps" pattern that
/// [EventActionsSheet] uses for Open Day events, but parameterised
/// by raw [buildingId] and [buildingName] so that any feature
/// (Favourites, search results, etc.) can reuse it without depending
/// on Open Day domain types.
///
/// Both actions route **through the in-app Navigation tab** so the
/// user never leaves MQ Navigation:
///   1. **View in Campus Map** → campus renderer, building selected.
///   2. **Navigate with Google Maps** → Google renderer, building selected.
///
/// The 250 ms delay before navigation allows `setRenderer` to settle
/// before the Map tab rebuilds — same contract as [EventActionsSheet].
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
    final renderer = await showModalBottomSheet<MapRendererType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BuildingActionsSheet(
        buildingId: buildingId,
        buildingName: buildingName,
      ),
    );

    if (renderer != null && context.mounted) {
      final container = ProviderScope.containerOf(context);
      container.read(mapControllerProvider.notifier).setRenderer(renderer);
      context.goNamed(
        RouteNames.buildingDetail,
        pathParameters: {'buildingId': buildingId},
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
                onTap: () => Navigator.pop(context, MapRendererType.campus),
              ),
            ),
            Semantics(
              button: true,
              label: l10n.openDay_navigateWithGoogleSemantic(buildingName),
              child: ListTile(
                leading: Icon(
                  Icons.navigation_rounded,
                  color: dark
                      ? Colors.white.withValues(alpha: 0.85)
                      : MqColors.contentPrimary,
                ),
                title: Text(
                  l10n.openDay_navigateWithGoogle,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(l10n.openDay_openGoogleMapsInsideNav),
                onTap: () => Navigator.pop(context, MapRendererType.google),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

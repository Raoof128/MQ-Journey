import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/favorites/presentation/controllers/favorites_controller.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoritesControllerProvider.notifier).load();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(favoritesControllerProvider.notifier).refresh();
  }

  Future<bool> _confirmRemove(String buildingName) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.favoritesDeleteConfirm),
        content: Text(l10n.favoritesDeleteConfirmBody(buildingName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.favoritesDeleteCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: MqColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.favoritesDeleteYes),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(favoritesControllerProvider);
    final dark = context.isDarkMode;

    return Scaffold(
      backgroundColor: dark ? MqColors.charcoal800 : Colors.white,
      appBar: AppBar(
        title: Text(l10n.favoritesTitle),
        backgroundColor: dark ? MqColors.charcoal800 : Colors.white,
        foregroundColor: dark ? Colors.white : MqColors.contentPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (dark)
            PositionedDirectional(
              top: -80,
              start: 0,
              end: 0,
              height: 380,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -1.2),
                      radius: 1.1,
                      colors: [
                        MqColors.red.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          if (state.isLoading && state.favorites.isEmpty)
            const Center(child: CircularProgressIndicator(color: MqColors.red))
          else if (state.error != null && state.favorites.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(MqSpacing.space6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: MqColors.slate500,
                    ),
                    const SizedBox(height: MqSpacing.space4),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: dark ? Colors.white : MqColors.contentPrimary,
                      ),
                    ),
                    const SizedBox(height: MqSpacing.space4),
                    FilledButton.icon(
                      onPressed: _onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            )
          else if (state.favorites.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(MqSpacing.space8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 72,
                      color: dark
                          ? Colors.white.withValues(alpha: 0.3)
                          : MqColors.slate400,
                    ),
                    const SizedBox(height: MqSpacing.space6),
                    Text(
                      l10n.favoritesEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: dark ? Colors.white : MqColors.contentSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            RefreshIndicator(
              onRefresh: _onRefresh,
              color: MqColors.red,
              child: ListView.builder(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  MqSpacing.space4,
                  MqSpacing.space2,
                  MqSpacing.space4,
                  MqSpacing.space12,
                ),
                itemCount: state.favorites.length,
                itemBuilder: (context, index) {
                  final fav = state.favorites[index];
                  return Dismissible(
                    key: ValueKey(fav.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: MqSpacing.space5),
                      color: MqColors.red,
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    confirmDismiss: (_) => _confirmRemove(fav.buildingName),
                    onDismissed: (_) {
                      unawaited(
                        ref
                            .read(favoritesControllerProvider.notifier)
                            .remove(fav.id),
                      );
                    },
                    child: Card(
                      color: dark
                          ? MqColors.charcoal800.withValues(alpha: 0.94)
                          : Colors.white,
                      margin: const EdgeInsets.symmetric(
                        vertical: MqSpacing.space1,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: MqColors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          fav.buildingName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: dark
                                ? Colors.white
                                : MqColors.contentPrimary,
                          ),
                        ),
                        subtitle: Text(
                          fav.buildingId,
                          style: TextStyle(
                            color: dark
                                ? Colors.white.withValues(alpha: 0.6)
                                : MqColors.contentSecondary,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: MqColors.red,
                          onPressed: () async {
                            final confirmed = await _confirmRemove(
                              fav.buildingName,
                            );
                            if (confirmed && context.mounted) {
                              await ref
                                  .read(favoritesControllerProvider.notifier)
                                  .remove(fav.id);
                            }
                          },
                        ),
                        onTap: () =>
                            context.go('/map/building/${fav.buildingId}'),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

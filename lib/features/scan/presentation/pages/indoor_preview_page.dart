import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_journey/features/scan/providers/scan_providers.dart';
import 'package:mq_journey/features/scan/presentation/widgets/indoor_webview.dart';
import 'package:mq_journey/features/scan/presentation/widgets/indoor_stop_list.dart';

class IndoorPreviewPage extends ConsumerWidget {
  const IndoorPreviewPage({super.key, required this.buildingId});
  final String buildingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifestAsync = ref.watch(indoorManifestProvider(buildingId));
    return Scaffold(
      appBar: AppBar(title: Text('$buildingId Indoor')),
      body: manifestAsync.when(
        data: (manifest) {
          if (manifest == null || manifest.isEmpty) {
            return const Center(child: Text('No indoor preview available'));
          }
          return Column(
            children: [
              Expanded(flex: 3, child: IndoorWebView(manifest: manifest)),
              const Divider(height: 1),
              Expanded(flex: 2, child: IndoorStopList(manifest: manifest)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load indoor preview: $e')),
      ),
    );
  }
}

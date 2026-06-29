import 'package:flutter/material.dart';
import 'package:mq_journey/features/scan/domain/models/indoor_manifest.dart';

class IndoorStopList extends StatelessWidget {
  const IndoorStopList({super.key, required this.manifest});
  final IndoorManifest manifest;

  @override
  Widget build(BuildContext context) {
    if (manifest.isEmpty) {
      return const Center(child: Text('No indoor preview available'));
    }
    return ListView.separated(
      itemCount: manifest.nodes.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final node = manifest.nodes[index];
        return ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(node.description.isNotEmpty ? node.description : node.id),
          subtitle: node.neighbours.isNotEmpty
              ? Text('${node.neighbours.length} connection(s)')
              : null,
        );
      },
    );
  }
}

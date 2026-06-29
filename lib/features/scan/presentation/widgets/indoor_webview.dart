import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mq_journey/features/scan/domain/models/indoor_manifest.dart';

class IndoorWebView extends StatefulWidget {
  const IndoorWebView({super.key, required this.manifest});
  final IndoorManifest manifest;

  @override
  State<IndoorWebView> createState() => _IndoorWebViewState();
}

class _IndoorWebViewState extends State<IndoorWebView> {
  InAppWebViewSettings get _settings => InAppWebViewSettings(
    javaScriptEnabled: true,
    transparentBackground: true,
    mediaPlaybackRequiresUserGesture: true,
  );

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialFile: 'assets/web/indoor_viewer.html',
      initialSettings: _settings,
      onLoadStop: (controller, _) async {
        final config = widget.manifest.buildPannellumConfig(
          assetBaseUrl: '/assets/indoor',
        );
        final cfgJson = jsonEncode(config);
        await controller.evaluateJavascript(source: 'loadTour($cfgJson);');
      },
    );
  }
}

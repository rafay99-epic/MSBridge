import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyCMSWebView extends StatefulWidget {
  final String cmsUrl;

  const MyCMSWebView({super.key, required this.cmsUrl});

  @override
  MyCMSWebViewState createState() => MyCMSWebViewState();
}

class MyCMSWebViewState extends State<MyCMSWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
            Page resource error:
              code: ${error.errorCode}
              description: ${error.description}
              errorType: ${error.errorType}
              isForMainFrame: ${error.isForMainFrame}
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.cmsUrl));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface, // Background color
        foregroundColor: theme.colorScheme.primary, // Text color
        title: const Text('My CMS'),
      ),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}

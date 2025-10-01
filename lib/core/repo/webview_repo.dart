// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Project imports:
import 'package:msbridge/widgets/appbar.dart';

class MyCMSWebView extends StatefulWidget {
  final String cmsUrl;
  final String? pageTitle;

  const MyCMSWebView({super.key, required this.cmsUrl, this.pageTitle});

  @override
  MyCMSWebViewState createState() => MyCMSWebViewState();
}

class MyCMSWebViewState extends State<MyCMSWebView> {
  late final WebViewController _controller;
  String? pageTitle;

  @override
  void initState() {
    super.initState();
    pageTitle = widget.pageTitle;

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

    _preCacheWebView();
  }

  Future<void> _preCacheWebView() async {
    try {
      final file = await DefaultCacheManager().getSingleFile(widget.cmsUrl);
      debugPrint('Pre-cached WebView content to: ${file.path}');
    } catch (e) {
      debugPrint('Failed to pre-cache WebView content: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        showTitle: true,
        title: pageTitle ?? "CMS System",
        showBackButton: true,
      ),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}

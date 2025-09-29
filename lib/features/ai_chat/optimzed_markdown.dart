import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class OptimizedMarkdownBody extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet styleSheet;

  const OptimizedMarkdownBody({
    super.key,
    required this.data,
    required this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      styleSheet: styleSheet,
      selectable: true,
      builders: {
        'img': OptimizedImageBuilder(),
      },
    );
  }
}

class OptimizedImageBuilder extends MarkdownElementBuilder {
  Widget? visitImageElement(String uri, String? title, String? alt) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: _SafeNetworkImage(
        uri: uri,
        alt: alt,
        title: title,
      ),
    );
  }
}

class _SafeNetworkImage extends StatefulWidget {
  final String uri;
  final String? alt;
  final String? title;

  const _SafeNetworkImage({
    required this.uri,
    this.alt,
    this.title,
  });

  @override
  State<_SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<_SafeNetworkImage> {
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  @override
  Widget build(BuildContext context) {
    if (_hasError && _retryCount >= _maxRetries) {
      return _buildErrorWidget();
    }

    return Image.network(
      widget.uri,
      key: ValueKey('${widget.uri}_$_retryCount'), // Force rebuild on retry
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            height: 50,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_retryCount < _maxRetries) {
            Future.delayed(Duration(seconds: _retryCount + 1), () {
              if (mounted) {
                setState(() {
                  _retryCount++;
                });
              }
            });
          } else {
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          }
        });

        return _buildRetryWidget();
      },
    );
  }

  Widget _buildRetryWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh, size: 24, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'Retrying... (${_retryCount + 1}/$_maxRetries)',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            widget.alt ?? 'Image failed to load',
            style: const TextStyle(color: Colors.red, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (widget.title != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.title!,
              style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.7), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:url_launcher/url_launcher.dart';

Widget buildHtmlContent(
    String? htmlData, ThemeData theme, BuildContext context) {
  final baseTextStyle = TextStyle(
    fontSize: 16,
    color: theme.colorScheme.primary,
    height: 1.6,
  );

  return SingleChildScrollView(
    child: HtmlWidget(
      htmlData ?? '<p>No content available.</p>',
      textStyle: baseTextStyle,
      customStylesBuilder: (element) {
        switch (element.localName) {
          case 'h1':
            return null;
          case 'h2':
            return null;
          case 'p':
          case 'div':
          case 'span':
            return {
              'text-align': 'justify',
            };
          case 'code':
            return {
              'font-family': 'monospace',
              'background-color': theme.colorScheme.secondary
                  .withValues(alpha: 0.1)
                  .toARGB32()
                  .toRadixString(16),
              'padding': '2px 5px',
              'color': theme.colorScheme.secondary.toARGB32().toRadixString(16),
              'font-size': '0.9em',
            };
          case 'pre':
            return {
              'font-family': 'monospace',
              'background-color': theme.colorScheme.onSurface
                  .withValues(alpha: 0.05)
                  .toARGB32()
                  .toRadixString(16),
              'padding': '12px',
              'margin': '10px 0',
              'white-space': 'pre-wrap',
              'word-wrap': 'break-word',
            };
          case 'table':
            return {
              'border':
                  '1px solid ${Colors.grey.shade400.toARGB32().toRadixString(16)}',
              'border-collapse': 'collapse',
              'margin': '10px 0',
              'width': 'auto',
            };
          case 'th':
          case 'td':
            return {
              'border':
                  '1px solid ${Colors.grey.shade400.toARGB32().toRadixString(16)}',
              'padding': '8px',
            };
          case 'a':
            return {
              'color': theme.colorScheme.secondary.toARGB32().toRadixString(16),
              'text-decoration': 'underline',
            };
        }
        return null;
      },
      onTapUrl: (url) async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return true;
        } else {
          if (context.mounted) {
            CustomSnackBar.show(
              context,
              'Invalid URL: $url',
              isSuccess: false,
            );
          }

          return false;
        }
      },
      onTapImage: (ImageMetadata imageMetadata) {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            'Image tapped: ${imageMetadata.sources.first.url}',
            isSuccess: true,
          );
        }
      },
      buildAsync: true,
      enableCaching: true,
    ),
  );
}

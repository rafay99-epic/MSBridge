import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

Widget buildHtmlContent(
    String? htmlData, ThemeData theme, BuildContext context) {
  return Html(
    data: htmlData ?? '',
    style: {
      "body": Style(
        fontSize: FontSize(16),
        color: theme.colorScheme.primary,
        lineHeight: LineHeight.number(1.6),
        textAlign: TextAlign.justify,
      ),
      "h1": Style(
        fontSize: FontSize(24),
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
      "h2": Style(
        fontSize: FontSize(20),
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
      "strong": Style(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
      "code": Style(
        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
        color: theme.colorScheme.secondary,
      ),
      "pre": Style(
        padding: HtmlPaddings.all(8),
        textOverflow: TextOverflow.fade,
        width: Width(MediaQuery.of(context).size.width),
      ),
      "table": Style(
        border: Border.all(color: Colors.grey),
      ),
      "th": Style(
        padding: HtmlPaddings.all(8),
        border: Border.all(color: Colors.grey),
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey[300],
      ),
      "td": Style(
        padding: HtmlPaddings.all(8),
        border: Border.all(color: Colors.grey),
      ),
    },
  );
}

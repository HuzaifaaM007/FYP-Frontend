import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';

/// Shows lesson text written by the admin in Markdown, optionally mixed with simple HTML.
///
/// Supports headings, paragraphs, bold/italic/underline/strikethrough, bullet and numbered lists,
/// quotes, links (open in the browser), images (uploaded lesson images load from the server),
/// tables, dividers, inline code and code blocks with syntax colouring. Text can be selected.
///
/// How it works: Markdown -> HTML (package:markdown, GitHub flavour, unsafe tags filtered out)
/// -> Flutter widgets (flutter_widget_from_html_core), styled with the current theme's colours.
class MarkdownView extends StatelessWidget {
  final String data;
  const MarkdownView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final html = md.markdownToHtml(
      _prepare(data),
      extensionSet: md.ExtensionSet.gitHubFlavored, // tables, ~~strike~~, autolinks
      enableTagfilter: true, // GitHub's filter: neutralises <script>, <iframe>, <style> ...
    );

    return SelectionArea(
      child: HtmlWidget(
        html,
        // Lesson images are stored as "/storage/lesson_images/..." on the backend.
        baseUrl: Uri.tryParse(Env.apiBaseUrl.endsWith('/') ? Env.apiBaseUrl : '${Env.apiBaseUrl}/'),
        textStyle: TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary),
        onTapUrl: (url) async {
          final uri = Uri.tryParse(url);
          if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'mailto')) return true;
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return true;
        },
        customStylesBuilder: _styles,
        customWidgetBuilder: _widgets,
      ),
    );
  }

  // ---------------------------------------------------------------- styling

  static String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  Map<String, String>? _styles(dynamic element) {
    final border = _hex(AppColors.border);
    switch (element.localName as String?) {
      case 'h1':
        return {'font-size': '24px', 'font-weight': '700', 'margin': '22px 0 10px', 'padding-bottom': '6px', 'border-bottom': '1px solid $border', 'line-height': '1.3'};
      case 'h2':
        return {'font-size': '20px', 'font-weight': '700', 'margin': '20px 0 8px', 'padding-bottom': '5px', 'border-bottom': '1px solid $border', 'line-height': '1.3'};
      case 'h3':
        return {'font-size': '17px', 'font-weight': '700', 'margin': '16px 0 6px'};
      case 'h4':
      case 'h5':
      case 'h6':
        return {'font-size': '15px', 'font-weight': '700', 'margin': '14px 0 4px'};
      case 'p':
        // Justified like a book: straight left AND right edges.
        return {'margin': '0 0 12px', 'text-align': 'justify'};
      case 'a':
        return {'color': _hex(AppColors.accentBlue), 'text-decoration': 'underline'};
      case 'blockquote':
        return {
          'margin': '6px 0 14px',
          'padding': '10px 14px',
          'border-left': '3px solid ${_hex(AppColors.accentPurple)}',
          'background-color': _hex(AppColors.surface),
          'color': _hex(AppColors.textSecondary),
          'font-style': 'italic',
          'text-align': 'justify',
        };
      case 'code': // inline code (code blocks are handled by _widgets)
        return {
          'font-family': 'monospace',
          'font-size': '13px',
          'background-color': _hex(AppColors.surfaceElevated),
          'color': _hex(AppColors.accentOrange),
        };
      case 'ul':
      case 'ol':
        return {'margin': '0 0 12px', 'padding-left': '22px'};
      case 'li':
        return {'margin': '0 0 4px', 'text-align': 'justify'};
      case 'hr':
        return {'margin': '18px 0', 'border-top': '1px solid $border'};
      case 'table':
        return {'margin': '6px 0 14px', 'border-collapse': 'collapse', 'border': '1px solid $border'};
      case 'th':
        return {
          'padding': '8px 10px',
          'border': '1px solid $border',
          'background-color': _hex(AppColors.surfaceElevated),
          'font-weight': '600',
          'text-align': 'left',
        };
      case 'td':
        return {'padding': '8px 10px', 'border': '1px solid $border', 'vertical-align': 'top'};
      case 'mark':
        return {'background-color': _hex(AppColors.accentOrange), 'color': '#000000'};
      case 'del':
        return {'color': _hex(AppColors.textSecondary)};
    }
    return null;
  }

  Widget? _widgets(dynamic element) {
    final name = element.localName as String?;

    // Code blocks: syntax colouring + horizontal scroll, same look as before.
    if (name == 'pre') {
      final children = element.children as List;
      final code = children.isNotEmpty ? children.first : element;
      final classes = (code.className as String? ?? '');
      final lang = RegExp(r'language-([\w#+-]+)').firstMatch(classes)?.group(1);
      final text = (code.text as String).replaceAll(RegExp(r'\n$'), '');
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        width: double.infinity,
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: HighlightView(
            text,
            language: _language(lang),
            theme: atomOneDarkTheme,
            padding: const EdgeInsets.all(12),
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.4),
          ),
        ),
      );
    }
    return null; // everything else uses the package's normal rendering + _styles
  }

  String _language(String? name) {
    switch (name?.toLowerCase().trim()) {
      case 'c#':
      case 'csharp':
      case 'cs':
        return 'csharp';
      case 'java':
        return 'java';
      case 'python':
      case 'py':
        return 'python';
      case 'html':
      case 'xml':
        return 'xml';
      case 'css':
        return 'css';
      case 'javascript':
      case 'js':
      case 'jsx':
      case 'typescript':
      case 'ts':
        return 'javascript';
      case 'sql':
        return 'sql';
      case 'shell':
      case 'bash':
      case 'sh':
        return 'bash';
      case 'json':
        return 'json';
      case 'dart':
        return 'dart';
      case 'cpp':
      case 'c++':
        return 'cpp';
      case 'php':
        return 'php';
      default:
        return 'plaintext';
    }
  }

  // ---------------------------------------------------------------- input clean-up

  /// Makes older lesson text render well with the standard Markdown parser:
  /// - "Code Example (Java - ...)" blocks from early seeded lessons become fenced code;
  /// - "•" bullets (from PDF imports) become "-" bullets.
  static String _prepare(String text) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAllMapped(
          RegExp(r'^(\s*)•\s+', multiLine: true),
          (m) => '${m.group(1)}- ',
        );
    return _upgradeLegacy(normalized);
  }

  static String _upgradeLegacy(String text) {
    if (text.contains('```') || !text.contains('Code Example')) return text;
    final out = StringBuffer();
    var inCode = false;
    final marker = RegExp(r'^\s*Code Example\s*\(([^)-]+)', caseSensitive: false);
    for (final line in text.split('\n')) {
      final match = marker.firstMatch(line);
      if (!inCode && match != null) {
        out.writeln('```${match.group(1)!.trim()}');
        inCode = true;
        continue;
      }
      if (inCode && line.trim().isEmpty) {
        out.writeln('```');
        out.writeln();
        inCode = false;
        continue;
      }
      out.writeln(line);
    }
    if (inCode) out.writeln('```');
    return out.toString();
  }
}

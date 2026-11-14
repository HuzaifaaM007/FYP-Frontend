import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../../core/theme/app_colors.dart';

/// Shows lesson text written in simple Markdown: headings (#, ##, ###), paragraphs, bullet and numbered
/// lists, fenced code blocks, **bold**, *italic* and `inline code`. Text can be selected and copied.
class MarkdownView extends StatelessWidget {
  final String data;
  const MarkdownView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final blocks = _parse(_upgradeLegacy(data));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final block in blocks) _buildBlock(block)],
    );
  }

  // ---------------------------------------------------------------- building

  Widget _buildBlock(_Block block) {
    switch (block.kind) {
      case _Kind.heading:
        final size = block.level <= 1 ? 24.0 : block.level == 2 ? 20.0 : block.level == 3 ? 17.0 : 15.0;
        return Padding(
          padding: EdgeInsets.only(top: block.level <= 2 ? 22 : 16, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText.rich(
                TextSpan(
                  children: _inline(block.text, TextStyle(fontSize: size, fontWeight: FontWeight.w700, height: 1.3)),
                ),
              ),
              if (block.level <= 2)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Divider(height: 1, color: AppColors.border),
                ),
            ],
          ),
        );
      case _Kind.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectableText.rich(
            TextSpan(children: _inline(block.text, const TextStyle(fontSize: 15, height: 1.6))),
          ),
        );
      case _Kind.bullet:
      case _Kind.numbered:
        return Padding(
          padding: EdgeInsets.only(left: 6.0 + block.level * 16, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(block.kind == _Kind.bullet ? '•' : '${block.number}.',
                    style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textSecondary)),
              ),
              Expanded(
                child: SelectableText.rich(
                  TextSpan(children: _inline(block.text, const TextStyle(fontSize: 15, height: 1.6))),
                ),
              ),
            ],
          ),
        );
      case _Kind.quote:
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.accentBlue, width: 3)),
          ),
          child: SelectableText.rich(
            TextSpan(
              children: _inline(
                block.text,
                const TextStyle(fontSize: 15, height: 1.6, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
              ),
            ),
          ),
        );
      case _Kind.code:
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              block.text,
              language: _language(block.lang),
              theme: atomOneDarkTheme,
              padding: const EdgeInsets.all(12),
              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.4),
            ),
          ),
        );
    }
  }

  List<InlineSpan> _inline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`|\*[^*\s][^*]*\*)');
    var last = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > last) spans.add(TextSpan(text: text.substring(last, match.start), style: base));
      final token = match.group(0)!;
      if (token.startsWith('**')) {
        spans.add(TextSpan(text: token.substring(2, token.length - 2), style: base.copyWith(fontWeight: FontWeight.w700)));
      } else if (token.startsWith('`')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: base.copyWith(
            fontFamily: 'monospace',
            fontSize: (base.fontSize ?? 15) - 1,
            backgroundColor: AppColors.surfaceElevated,
            color: AppColors.accentGreen,
          ),
        ));
      } else {
        spans.add(TextSpan(text: token.substring(1, token.length - 1), style: base.copyWith(fontStyle: FontStyle.italic)));
      }
      last = match.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last), style: base));
    return spans;
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
      case 'react native':
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
      default:
        return 'plaintext';
    }
  }

  // ----------------------------------------------------------------- parsing

  /// Older seeded lessons mark code as "Code Example (Java - ...)" followed by lines up to a blank line.
  /// Turn that into fenced code so the same renderer handles both kinds of lesson.
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

  static List<_Block> _parse(String text) {
    final blocks = <_Block>[];
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final paragraph = <String>[];

    void flushParagraph() {
      if (paragraph.isNotEmpty) {
        blocks.add(_Block(_Kind.paragraph, paragraph.join(' ').trim()));
        paragraph.clear();
      }
    }

    final heading = RegExp(r'^(#{1,6})\s+(.*)$');
    final bullet = RegExp(r'^(\s*)[-*•]\s+(.*)$');
    final numbered = RegExp(r'^(\s*)(\d+)[.)]\s+(.*)$');

    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.startsWith('```')) {
        flushParagraph();
        final lang = trimmed.substring(3).trim();
        final code = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          code.add(lines[i]);
          i++;
        }
        i++; // closing fence
        blocks.add(_Block(_Kind.code, code.join('\n').trimRight(), lang: lang.isEmpty ? null : lang));
        continue;
      }
      if (trimmed.isEmpty) {
        flushParagraph();
        i++;
        continue;
      }
      final h = heading.firstMatch(trimmed);
      if (h != null) {
        flushParagraph();
        blocks.add(_Block(_Kind.heading, h.group(2)!.trim(), level: h.group(1)!.length));
        i++;
        continue;
      }
      final b = bullet.firstMatch(line);
      if (b != null) {
        flushParagraph();
        blocks.add(_Block(_Kind.bullet, b.group(2)!.trim(), level: (b.group(1)!.length ~/ 2).clamp(0, 3).toInt()));
        i++;
        continue;
      }
      final n = numbered.firstMatch(line);
      if (n != null) {
        flushParagraph();
        blocks.add(_Block(_Kind.numbered, n.group(3)!.trim(),
            level: (n.group(1)!.length ~/ 2).clamp(0, 3).toInt(), number: int.parse(n.group(2)!)));
        i++;
        continue;
      }
      if (trimmed.startsWith('>')) {
        flushParagraph();
        blocks.add(_Block(_Kind.quote, trimmed.replaceFirst(RegExp(r'^>\s?'), '')));
        i++;
        continue;
      }
      paragraph.add(trimmed);
      i++;
    }
    flushParagraph();
    return blocks;
  }
}

enum _Kind { heading, paragraph, bullet, numbered, quote, code }

class _Block {
  final _Kind kind;
  final String text;
  final int level;
  final int number;
  final String? lang;
  _Block(this.kind, this.text, {this.level = 0, this.number = 0, this.lang});
}

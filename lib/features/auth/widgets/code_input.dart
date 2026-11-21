import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// Six boxes for a 6-digit email code. One hidden text field underneath does the typing,
/// so paste and the keyboard's "code from email" suggestion both work.
class CodeInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final bool hasError;
  final bool enabled;

  const CodeInput({super.key, required this.controller, required this.onCompleted, this.hasError = false, this.enabled = true});

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    if (widget.controller.text.length == 6) widget.onCompleted(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              final filled = i < text.length;
              final active = _focus.hasFocus && i == text.length.clamp(0, 5);
              final borderColor = widget.hasError
                  ? AppColors.error
                  : active
                      ? AppColors.primary
                      : AppColors.border;
              return Container(
                width: 46,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: active || widget.hasError ? 2 : 1),
                ),
                child: Text(
                  filled ? text[i] : '',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              );
            }),
          ),
          // The real input, invisible but on top so taps and paste reach it.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: '', border: InputBorder.none, filled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

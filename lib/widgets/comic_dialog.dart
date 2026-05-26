import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/dot_grid_painter.dart';

class ComicDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? emoji;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color shadowColor;
  final bool isAlert;

  const ComicDialog({
    super.key,
    required this.title,
    required this.content,
    this.emoji,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.shadowColor = Colors.black,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(8, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(
                emoji!,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            if (isAlert)
              _buildButton(
                context,
                text: confirmText ?? 'OKEE!',
                color: AppColors.primary,
                textColor: Colors.black,
                onTap: onConfirm ?? () => Navigator.pop(context),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      context,
                      text: cancelText ?? 'Batal',
                      color: Colors.white,
                      textColor: Colors.black,
                      onTap: onCancel ?? () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildButton(
                      context,
                      text: confirmText ?? 'Yakin!',
                      color: AppColors.expense,
                      textColor: Colors.black,
                      onTap: () {
                        if (onConfirm != null) onConfirm!();
                        Navigator.pop(context, true);
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

Future<bool?> showComicConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String? emoji,
  String? confirmText,
  String? cancelText,
  Color shadowColor = AppColors.expense,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ComicDialog(
      title: title,
      content: content,
      emoji: emoji,
      confirmText: confirmText,
      cancelText: cancelText,
      shadowColor: shadowColor,
      isAlert: false,
    ),
  );
}

Future<void> showComicAlertDialog({
  required BuildContext context,
  required String title,
  required String content,
  String? emoji,
  String? confirmText,
  Color shadowColor = AppColors.primary,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => ComicDialog(
      title: title,
      content: content,
      emoji: emoji,
      confirmText: confirmText,
      shadowColor: shadowColor,
      isAlert: true,
    ),
  );
}

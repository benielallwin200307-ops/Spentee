import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Premium, lightweight reusable Lottie loading animation widget for Spentee.
///
/// Supports:
/// - Inline mode (inside buttons like Google Login, Email Login, or Save Transaction)
/// - Centered or Card mode (for dashboard, transactions, or insights loading)
/// - Modal dialog mode (for Firebase sync, account deletion, or blocking operations)
class SpenteeLoading extends StatelessWidget {
  /// Diameter of the animation canvas.
  final double size;

  /// Optional message displayed alongside or beneath the animation.
  final String? message;

  /// Whether the loader is displayed inline (e.g. inside a button or row).
  final bool isInline;

  /// Optional custom color filter for the animation.
  final Color? color;

  const SpenteeLoading({
    super.key,
    this.size = 50.0,
    this.message,
    this.isInline = false,
    this.color,
  });

  /// Compact inline loading spinner for buttons and dense headers.
  const SpenteeLoading.inline({
    super.key,
    this.size = 24.0,
    this.message,
    this.color,
  }) : isInline = true;

  /// Centered full-screen or card loading state with an optional status label.
  const SpenteeLoading.full({
    super.key,
    this.size = 72.0,
    this.message = 'Loading...',
    this.color,
  }) : isInline = false;

  /// Show a non-dismissible modal loading dialog for asynchronous blocking tasks.
  static void showLoadingDialog(
    BuildContext context, {
    String message = 'Please wait...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF091C24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF144548), width: 1.2),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SpenteeLoading.inline(size: 32),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget lottieWidget = SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'Assets/spentee_loader.json',
        fit: BoxFit.contain,
        repeat: true,
        errorBuilder: (context, error, stackTrace) {
          // Graceful fallback for unit tests or environments without asset loading
          return Center(
            child: SizedBox(
              width: size * 0.7,
              height: size * 0.7,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? const Color(0xFF00E676),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (message == null) {
      return isInline
          ? lottieWidget
          : Center(child: lottieWidget);
    }

    if (isInline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          lottieWidget,
          const SizedBox(width: 10),
          Text(
            message!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          lottieWidget,
          const SizedBox(height: 12),
          Text(
            message!,
            style: const TextStyle(
              color: Color(0xFF88A0A8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


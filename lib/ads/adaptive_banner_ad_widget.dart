// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Reusable adaptive banner ad widget.
///
/// Loads a banner using the provided **adUnitId** and determines the appropriate
/// size for the current screen width via
/// `AnchoredAdaptiveBannerAdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize`.
/// The widget rebuilds when the available width changes (e.g., device rotation
/// or split‑view) and preserves space while loading to avoid layout shifts.
/// Errors are logged and the widget displays a placeholder instead of breaking
/// the surrounding UI.
class AdaptiveBannerAdWidget extends StatefulWidget {
  const AdaptiveBannerAdWidget({required this.adUnitId, super.key});

  final String adUnitId;

  @override
  State<AdaptiveBannerAdWidget> createState() => _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  double _lastWidth = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _maybeLoadAd() async {
    if (!mounted) return;
    final double width = MediaQuery.of(context).size.width;
    if (_bannerAd != null && (width - _lastWidth).abs() < 1) {
      // Width unchanged – keep the current ad.
      return;
    }
    // Dispose previous ad if size changed.
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
    _lastWidth = width;

    final AnchoredAdaptiveBannerAdSize? adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width.truncate(),
    );
    if (!mounted || adaptiveSize == null) {
      // Fallback or widget unmounted – do not attempt to load.
      return;
    }
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: adaptiveSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Adaptive banner failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      // Keep placeholder height to avoid layout shift without infinite animation loops.
      return const SizedBox(height: 50);
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

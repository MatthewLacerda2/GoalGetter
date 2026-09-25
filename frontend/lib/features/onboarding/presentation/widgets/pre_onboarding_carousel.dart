import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

/// One page of the carousel.
typedef CarouselItem = ({IconData icon, String title, String body});

/// A looping, auto-sliding carousel of icon + title + body pages. Without
/// [items] it shows the start screen's pitch, which is its only caller today:
/// the introduction screens that passed their own were removed with the Gemini
/// call that wrote them (#132), so [items] is now unused but still supported.
class PreOnboardingCarousel extends StatefulWidget {
  const PreOnboardingCarousel({super.key, this.height = 170, this.items});

  final double height;
  final List<CarouselItem>? items;

  @override
  State<PreOnboardingCarousel> createState() => _PreOnboardingCarouselState();
}

class _PreOnboardingCarouselState extends State<PreOnboardingCarousel> {
  final PageController _controller = PageController();
  int _index = 0;
  int _pageCount = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();

    _autoSlideTimer = Timer.periodic(Duration(seconds: 13), (_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }

      if (_pageCount <= 0) {
        return;
      }

      // Use the extra "duplicate first page" (index == _pageCount) to get a smooth wrap.
      final nextIndex = _index + 1;
      _controller.animateToPage(
        nextIndex,
        duration: Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// The start screen's own pitch, used when the caller brings no pages.
  List<CarouselItem> _defaultItems(AppLocalizations l10n) => <CarouselItem>[
    (
      icon: Icons.auto_stories,
      title: l10n.preOnboardingYourCoursesTitle,
      body: l10n.preOnboardingYourCoursesBody,
    ),
    (
      icon: Icons.flag,
      title: l10n.preOnboardingTellUsYourGoalTitle,
      body: l10n.preOnboardingTellUsYourGoalBody,
    ),
    (
      icon: Icons.calendar_today,
      title: l10n.preOnboardingDailyLessonTitle,
      body: l10n.preOnboardingDailyLessonBody,
    ),
    (
      icon: Icons.smart_toy,
      title: l10n.preOnboardingAiThatKnowsYouTitle,
      body: l10n.preOnboardingAiThatKnowsYouBody,
    ),
  ];

  /// The carousel wraps by keeping one extra page — a duplicate of the first.
  /// Landing on it jumps back to the real page 0 without an animation.
  void _onPageChanged(int i, int pageCount) {
    if (i == pageCount) {
      setState(() => _index = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items ?? _defaultItems(AppLocalizations.of(context));

    _pageCount = items.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: const {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
                PointerDeviceKind.unknown,
              },
            ),
            child: PageView.builder(
              controller: _controller,
              physics: PageScrollPhysics(),
              onPageChanged: (i) => _onPageChanged(i, items.length),
              itemCount: items.length + 1,
              itemBuilder: (context, i) =>
                  _CarouselPage(item: items[i % items.length]),
            ),
          ),
        ),
        SizedBox(height: 12),
        _Dots(count: items.length, active: _index),
      ],
    );
  }
}

/// One page: the icon over its title and body, centred.
class _CarouselPage extends StatelessWidget {
  const _CarouselPage({required this.item});

  final CarouselItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 44, color: theme.colorScheme.primary),
          SizedBox(height: 12.0),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            item.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// The page indicator: the current dot grows and takes the full accent.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          width: isActive ? 10 : 8,
          height: isActive ? 10 : 8,
          decoration: BoxDecoration(
            color: isActive ? primary : primary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
      }),
    );
  }
}

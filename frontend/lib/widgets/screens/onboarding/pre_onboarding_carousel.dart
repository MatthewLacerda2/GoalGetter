import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class PreOnboardingCarousel extends StatefulWidget {
  const PreOnboardingCarousel({super.key, this.height = 170});

  final double height;

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

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
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
        duration: const Duration(milliseconds: 420),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = <({IconData icon, String title, String body})>[
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
        icon: Icons.person,
        title: l10n.preOnboardingMadeForYouTitle,
        body: l10n.preOnboardingMadeForYouBody,
      ),
      (
        icon: Icons.smart_toy,
        title: l10n.preOnboardingAiThatKnowsYouTitle,
        body: l10n.preOnboardingAiThatKnowsYouBody,
      ),
    ];

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
              physics: const PageScrollPhysics(),
              onPageChanged: (i) {
                if (i == items.length) {
                  // We swiped onto the extra "duplicate" page -> jump back to real page 0.
                  setState(() => _index = 0);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _controller.hasClients) {
                      _controller.jumpToPage(0);
                    }
                  });
                  return;
                }
                setState(() => _index = i);
              },
              itemCount: items.length + 1,
              itemBuilder: (context, i) {
                final item = items[i % items.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 44, color: Colors.green),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 10 : 8,
              height: active ? 10 : 8,
              decoration: BoxDecoration(
                color: active
                    ? Colors.green
                    : Colors.green.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }
}

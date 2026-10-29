import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    ('assets/photos/building-1.jpg', 'onb1_title', 'onb1_body', Icons.travel_explore_rounded),
    ('assets/photos/interior-1.jpg', 'onb2_title', 'onb2_body', Icons.phone_iphone_rounded),
    ('assets/photos/interior-3.jpg', 'onb3_title', 'onb3_body', Icons.handyman_rounded),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _slides.length - 1) {
      context.appRead.finishOnboarding();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final s = _slides[i];
                return Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xl + 6),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(s.$1, fit: BoxFit.cover),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0x66001A2C), Colors.transparent, Colors.transparent],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 20,
                                bottom: 20,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Icon(s.$4, color: AppColors.brand, size: 26),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr(s.$2), style: AppTheme.serif(size: 32)),
                          const SizedBox(height: 12),
                          Text(
                            context.tr(s.$3),
                            style: const TextStyle(fontSize: 16, color: AppColors.muted, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _page ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? AppColors.brand : AppColors.silver,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      const Spacer(),
                      if (!last)
                        TextButton(
                          onPressed: context.app.finishOnboarding,
                          child: Text(
                            context.tr('skip'),
                            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  PillButton(
                    color: AppColors.brand,
                    label: context.tr(last ? 'get_started' : 'next'),
                    icon: last ? null : Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

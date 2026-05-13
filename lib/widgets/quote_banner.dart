import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/quote_service.dart';

class QuoteBanner extends StatefulWidget {
  const QuoteBanner({super.key});

  @override
  State<QuoteBanner> createState() => _QuoteBannerState();
}

class _QuoteBannerState extends State<QuoteBanner> {
  late Future<MotivationalQuote> _quoteFuture;

  @override
  void initState() {
    super.initState();
    _fetchQuote();
  }

  void _fetchQuote() {
    HapticFeedback.selectionClick();
    setState(() {
      _quoteFuture = context.read<QuoteService>().fetchQuote();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.secondaryContainer,
              theme.colorScheme.primaryContainer,
            ],
          ),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: FutureBuilder<MotivationalQuote>(
          future: _quoteFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final quote = snapshot.data ?? QuoteService.fallbackQuote;

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: Padding(
                key: ValueKey(isLoading ? 'loading' : quote.content),
                padding: const EdgeInsets.all(18),
                child: isLoading
                    ? SizedBox(
                        height: 94,
                        child: Row(
                          children: [
                            const _QuoteIcon(isLoading: true),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  _QuoteSkeleton(widthFactor: 0.92),
                                  SizedBox(height: 10),
                                  _QuoteSkeleton(widthFactor: 0.52),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _QuoteIcon(isLoading: false),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quote.content,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w900,
                                    height: 1.22,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 16,
                                      color: theme.colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      quote.author,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.refresh_rounded),
                            onPressed: _fetchQuote,
                            tooltip: 'Generate new quote',
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuoteIcon extends StatelessWidget {
  final bool isLoading;

  const _QuoteIcon({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: isLoading
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: theme.colorScheme.secondary,
              ),
            )
          : Icon(
              Icons.psychology_alt_rounded,
              color: theme.colorScheme.secondary,
            ),
    );
  }
}

class _QuoteSkeleton extends StatefulWidget {
  final double widthFactor;

  const _QuoteSkeleton({required this.widthFactor});

  @override
  State<_QuoteSkeleton> createState() => _QuoteSkeletonState();
}

class _QuoteSkeletonState extends State<_QuoteSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.38, end: 0.82).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      widthFactor: widget.widthFactor,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        },
      ),
    );
  }
}

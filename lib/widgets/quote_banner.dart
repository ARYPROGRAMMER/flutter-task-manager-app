import 'package:flutter/material.dart';

import '../services/quote_service.dart';

class QuoteBanner extends StatefulWidget {
  const QuoteBanner({super.key});

  @override
  State<QuoteBanner> createState() => _QuoteBannerState();
}

class _QuoteBannerState extends State<QuoteBanner> {
  final QuoteService _quoteService = QuoteService();
  late Future<Map<String, String>> _quoteFuture;

  @override
  void initState() {
    super.initState();
    _fetchQuote();
  }

  void _fetchQuote() {
    setState(() {
      _quoteFuture = _quoteService.fetchQuote();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16.0),
      color: theme.colorScheme.primaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, String>>(
          future: _quoteFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final quoteData = snapshot.data!;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"${quoteData['content']}"',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        '- ${quoteData['author']}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimaryContainer),
                  onPressed: _fetchQuote,
                  tooltip: 'Fetch new quote',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

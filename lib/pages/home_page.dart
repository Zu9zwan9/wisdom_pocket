import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quote.dart';
import '../services/animation_settings.dart';
import '../services/feature_flags.dart';
import '../services/quote_repository.dart';
import '../services/streak_service.dart';
import '../services/subscription_service.dart';
import '../services/telemetry.dart';
import '../widgets/pocket_extraction_widget.dart';

class HomePage extends StatefulWidget {
  final QuoteRepository repo;
  final FeatureFlags flags;
  final AnimationSettings anim;
  final String userId;

  const HomePage({
    super.key,
    required this.repo,
    required this.flags,
    required this.anim,
    required this.userId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Quote _quote;
  final _streak = StreakService();
  final _sub = SubscriptionService();
  bool _subActive = false;

  @override
  void initState() {
    super.initState();
    _quote = widget.repo.getDailyQuote(widget.userId);
    Telemetry.appOpen(userId: widget.userId, source: 'direct');
    _streak.incrementIfNewDay().then(
      (v) => Telemetry.streakIncrement(userId: widget.userId, streakLength: v),
    );
    _sub.isActive().then((v) => setState(() => _subActive = v));
  }

  void _shareQuote(Quote q) {
    Share.share('"${q.text}" — ${q.author}');
    Telemetry.share(
      quoteId: q.id,
      channel: 'system',
      shareType: 'quote',
      userId: widget.userId,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Shared!')));
  }

  @override
  Widget build(BuildContext context) {
    final isPremiumLocked =
        _quote.isPremium && !_subActive && !widget.flags.shareToUnlock;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wisdom Pocket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final q = await showSearch<Quote?>(
                context: context,
                delegate: _QuoteSearchDelegate(widget.repo),
              );
              if (q != null) setState(() => _quote = q);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: Center(
        child: PocketExtractionWidget(
          stiffness: widget.anim.stiffness,
          damping: widget.anim.damping,
          maxPull: widget.anim.maxPull,
          confetti: widget.flags.confettiOnExtract,
          onExtract: () => Telemetry.quoteView(
            quoteId: _quote.id,
            location: 'daily',
            userId: widget.userId,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _quote.category.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _quote.text,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '— ${_quote.author}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        if (_quote.isPremium)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.lock,
                              size: 16,
                              color: _subActive || widget.flags.shareToUnlock
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Random',
                          onPressed: () => setState(
                            () => _quote = widget.repo.random(
                              premiumOk:
                                  _subActive || widget.flags.shareToUnlock,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share),
                          tooltip: 'Share',
                          onPressed: () {
                            if (_quote.isPremium &&
                                !_subActive &&
                                widget.flags.shareToUnlock) {
                              _shareQuote(_quote);
                            } else if (isPremiumLocked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Premium: Subscribe or enable share-to-unlock',
                                  ),
                                ),
                              );
                            } else {
                              _shareQuote(_quote);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!_subActive) {
            await _sub.mockPurchase();
            setState(() => _subActive = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Subscription activated (mock)')),
            );
          } else {
            setState(() => _subActive = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Subscription already active')),
            );
          }
        },
        icon: Icon(_subActive ? Icons.verified : Icons.workspace_premium),
        label: Text(_subActive ? 'Active' : 'Mock Subscribe'),
      ),
    );
  }
}

class _QuoteSearchDelegate extends SearchDelegate<Quote?> {
  final QuoteRepository repo;
  _QuoteSearchDelegate(this.repo);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) {
    final results = repo.search(query);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final q = results[i];
        return ListTile(
          title: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(q.author),
          onTap: () => close(context, q),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

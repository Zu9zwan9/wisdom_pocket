import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wisdom_pocket/handwriting/handwriting_rules.dart' as hw;
import 'package:wisdom_pocket/widgets/handwriting_quote_painter.dart';
import '../models/quote.dart';
import '../services/quote_repository.dart';

class AnimatedQuotePage extends StatefulWidget {
  final QuoteRepository repository;
  const AnimatedQuotePage({super.key, required this.repository});

  @override
  State<AnimatedQuotePage> createState() => _AnimatedQuotePageState();
}

class _AnimatedQuotePageState extends State<AnimatedQuotePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Quote? _quote;
  List<Path>? _quoteLines;
  Path? _authorPath;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6));
    _loadNew();
  }

  Future<void> _loadNew() async {
    _controller.stop();
    setState(() { _quote = null; });
    final q = widget.repository.getRandomQuote();
    // адаптивная ширина будет вычислена позже через LayoutBuilder, поэтому делаем предварительно стандартную сборку, а финальную — в builder
    setState(() { _quote = q; });
  }

  Future<void> _buildPaths(BoxConstraints constraints) async {
    if (_quote == null) return;
    if (_quoteLines != null) return; // уже построено для текущей цитаты
    final maxWidth = constraints.maxWidth * 0.88; // ч��ть меньше полной ширины
    final lines = await hw.buildAdvancedAdaptiveMultilineQuotePaths(
      _quote!.text,
      maxWidth: maxWidth,
      maxLines: 12,
    );
    final author = (await hw.buildAdvancedTextPath('- ${_quote!.author}')).path;
    if (!mounted) return;
    setState(() {
      _quoteLines = lines;
      _authorPath = author;
    });
    _controller
      ..reset()
      ..forward();
  }

  void _next() {
    _quoteLines = null;
    _authorPath = null;
    _loadNew();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Animated Quote'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.arrow_clockwise),
          onPressed: _next,
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _buildPaths(constraints); // лениво
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 3/5, // вертикальный холст
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: _quoteLines == null || _authorPath == null
                            ? const CupertinoActivityIndicator()
                            : AnimatedBuilder(
                                animation: _controller,
                                builder: (ctx, _) => CustomPaint(
                                  painter: QuoteHandwritingMultilinePainter(
                                    quoteLinePaths: _quoteLines!,
                                    authorPath: _authorPath!,
                                    progress: _controller.value,
                                    strokeWidth: 2.0,
                                    padding: 8,
                                    lineSpacing: 28,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _next,
                      child: const Text('Next Quote'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

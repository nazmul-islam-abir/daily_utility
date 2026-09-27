import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/quiz_category.dart';
import '../../models/quiz_result.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

const _uuid = Uuid();

/// Plays through one quiz [category]'s questions. All colours come from
/// `Theme.of(context).colorScheme` so the screen reads cleanly in both
/// light and dark themes; the question pool is supplied by [category]
/// (typically fetched from Firestore via [QuizService]).
class QuizScreen extends StatefulWidget {
  final QuizCategory category;
  const QuizScreen({super.key, required this.category});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late int _index;
  int? _selected;
  bool _answered = false;
  int _correct = 0;
  late List<int?> _answers;
  bool _completed = false;
  late AnimationController _confettiCtrl;

  List<QuizQuestion> get _questions => widget.category.questions;

  @override
  void initState() {
    super.initState();
    _index = 0;
    _answers = List<int?>.filled(_questions.length, null);
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (_answered) return;
    setState(() {
      _selected = i;
    });
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    final q = _questions[_index];
    final correct = _selected == q.correctIndex;
    setState(() {
      _answered = true;
      if (correct) _correct++;
      _answers[_index] = _selected;
    });
  }

  void _skip() {
    if (_answered) return;
    setState(() {
      _answers[_index] = null;
    });
  }

  Future<void> _next() async {
    if (_index + 1 >= _questions.length) {
      await _finish();
      return;
    }
    setState(() {
      _index++;
      _selected = _answers[_index];
      _answered = _selected != null;
    });
  }

  Future<void> _finish() async {
    final total = _questions.length;
    final score = total == 0 ? 0 : (_correct / total * 100).round();
    final result = QuizResult(
      id: _uuid.v4(),
      score: score,
      correctCount: _correct,
      totalQuestions: total,
      completedAt: DateTime.now(),
    );
    await HiveService.quizResults.put(result.id, result);
    setState(() => _completed = true);
    _confettiCtrl.forward(from: 0);
  }

  void _restart() {
    setState(() {
      _index = 0;
      _selected = null;
      _answered = false;
      _correct = 0;
      for (int i = 0; i < _answers.length; i++) {
        _answers[i] = null;
      }
      _completed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_questions.isEmpty) {
      // Defensive: the hub only shows categories with valid questions, but
      // if a category arrives empty (admin mid-edit), show a friendly
      // empty state instead of crashing.
      return Scaffold(
        backgroundColor: scheme.surfaceContainerLow,
        appBar: AppBar(
          backgroundColor: scheme.surfaceContainerLow,
          title: Text(widget.category.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 56, color: scheme.outline),
              const SizedBox(height: 14),
              Text(
                tr(context, 'এই ক্যাটাগরিতে এখনো কোনো প্রশ্ন নেই',
                    'This category has no questions yet'),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                tr(context,
                    'অ্যাডমিন যখন প্রশ্ন যোগ করবে এখানে দেখা যাবে।',
                    'The admin will add questions to this category soon.'),
                style: TextStyle(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: scheme.surfaceContainerLow,
              appBar: AppBar(
                backgroundColor: scheme.surfaceContainerLow,
                title: Text(widget.category.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _restart,
                    tooltip: tr(context, 'পুনরায় শুরু', 'Restart'),
                  ),
                ],
              ),
              body: _completed
                  ? _buildResult(context, scheme: scheme)
                  : _buildQuiz(context, scheme: scheme),
            ),
            if (_completed) IgnorePointer(child: _ConfettiOverlay(ctrl: _confettiCtrl)),
          ],
        );
      },
    );
  }

  Widget _buildQuiz(BuildContext context, {required ColorScheme scheme}) {
    final q = _questions[_index];
    final total = _questions.length;
    final progress = (_index + 1) / total;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppColors.cardGradient(widget.category.color)),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.category.color,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(widget.category.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context,
                            'প্রশ্ন ${_index + 1} এর $total',
                            'Question ${_index + 1} of $total'),
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).round()}% ${tr(context, 'সম্পন্ন', 'Complete')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: TweenAnimationBuilder<double>(
                  duration: AppAnimations.medium,
                  tween: Tween(begin: 0, end: progress),
                  curve: AppAnimations.curve,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation(widget.category.color),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.category.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(widget.category.icon, color: widget.category.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                q.q,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < 4; i++) ...[
          _OptionCard(
            label: q.options[i],
            index: i,
            isSelected: _selected == i,
            isCorrect: _answered && i == q.correctIndex,
            isWrong: _answered && _selected == i && i != q.correctIndex,
            brandColor: widget.category.color,
            onTap: () => _select(i),
          ),
          const SizedBox(height: 10),
        ],
        if (_answered) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (_selected == q.correctIndex ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.10),
                  scheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(
                _selected == q.correctIndex ? Icons.check_circle : Icons.lightbulb_outline,
                color: _selected == q.correctIndex ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selected == q.correctIndex
                      ? tr(context, 'সঠিক!', 'Correct!')
                      : tr(context, 'ইঙ্গিত: ${q.hint ?? ''}',
                          'Hint: ${q.hint ?? ''}'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
        ],
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _answered ? null : _skip,
              icon: const Icon(Icons.skip_next_outlined),
              label: Text(tr(context, 'এড়িয়ে যান', 'Skip'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _selected == null ? null : (_answered ? _next : _submit),
              icon: Icon(_answered ? Icons.arrow_forward : Icons.check),
              label: Text(
                _answered
                    ? (_index + 1 < _questions.length
                        ? tr(context, 'পরবর্তী', 'Next')
                        : tr(context, 'শেষ করুন', 'Finish'))
                    : tr(context, 'উত্তর দিন', 'Submit Answer'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _answered ? scheme.onSurface : widget.category.color,
                foregroundColor: _answered ? scheme.surface : Colors.white,
                minimumSize: const Size(0, 52),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildResult(BuildContext context, {required ColorScheme scheme}) {
    final total = _questions.length;
    final score = total == 0 ? 0 : (_correct / total * 100).round();
    return ValueListenableBuilder(
      valueListenable: HiveService.quizResults.listenable(),
      builder: (context, Box<QuizResult> box, _) {
        final history = box.values.toList()..sort((a, b) => b.completedAt.compareTo(a.completedAt));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.heroGradientDark,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 56),
                  const SizedBox(height: 12),
                  Text(tr(context, 'আপনার স্কোর', 'Your Score'),
                      style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('$score%',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      )),
                  const SizedBox(height: 8),
                  Text('$_correct / $total ${tr(context, 'সঠিক', 'correct')}',
                      style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(tr(context, 'ইতিহাস', 'History'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: scheme.onSurface)),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const EmptyState(icon: Icons.history, title: '—', message: '—')
            else
              ...history.take(10).map((r) {
                final color = r.score >= 80
                    ? AppColors.success
                    : (r.score >= 50 ? AppColors.warning : AppColors.danger);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        '${r.score}%',
                        style: TextStyle(fontWeight: FontWeight.w900, color: color),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r.correctCount}/${r.totalQuestions} ${tr(context, 'সঠিক', 'correct')}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(r.completedAt),
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ]),
                );
              }),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.replay),
              label: Text(tr(context, 'আবার শুরু করুন', 'Try Again'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(
                backgroundColor: widget.category.color,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 52),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final Color brandColor;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.brandColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final letters = ['A', 'B', 'C', 'D'];
    final scheme = Theme.of(context).colorScheme;
    final Color color;
    if (isCorrect) {
      color = AppColors.success;
    } else if (isWrong) {
      color = AppColors.danger;
    } else if (isSelected) {
      color = brandColor;
    } else {
      color = scheme.outline;
    }
    return PressableCard(
      onTap: onTap,
      color: scheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      radius: AppRadius.lg,
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Text(letters[index], style: TextStyle(fontWeight: FontWeight.w900, color: color)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (isCorrect) const Icon(Icons.check_circle, color: AppColors.success),
        if (isWrong) const Icon(Icons.cancel, color: AppColors.danger),
      ]),
    );
  }
}

class _ConfettiOverlay extends StatelessWidget {
  final AnimationController ctrl;
  const _ConfettiOverlay({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _ConfettiPainter(progress: ctrl.value, seed: (ctrl.value * 1000).toInt()),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final int seed;
  _ConfettiPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    const colors = [
      AppColors.success,
      AppColors.warning,
      AppColors.primary,
      AppColors.quiz,
      AppColors.converter,
      AppColors.mood,
    ];
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      const startY = -20.0;
      final endY = size.height + 20.0;
      final y = startY + (endY - startY) * progress * (0.6 + rng.nextDouble() * 0.4);
      final paint = Paint()..color = colors[i % colors.length].withValues(alpha: 1 - progress);
      final dx = math.sin((progress * 6 + i)) * 8;
      canvas.drawCircle(Offset(x + dx, y), 3 + rng.nextDouble() * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}

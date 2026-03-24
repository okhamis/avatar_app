import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/route_names.dart';
import '../../theme/presnt_tokens.dart';
import '../../config/behavioral_training_questions.dart';
import '../../providers/avatar_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/presnt/presnt_glass_bar.dart';

class BehavioralTrainingScreen extends ConsumerStatefulWidget {
  const BehavioralTrainingScreen({super.key});

  @override
  ConsumerState<BehavioralTrainingScreen> createState() => _BehavioralTrainingScreenState();
}

class _BehavioralTrainingScreenState extends ConsumerState<BehavioralTrainingScreen> {
  List<String> get _questions => kBehavioralTrainingQuestions;

  late final List<TextEditingController> _controllers;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_questions.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canContinue => _controllers.any((c) => c.text.trim().isNotEmpty);

  Future<void> _continue() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    setState(() => _loading = true);
    final answers = <String, String>{};
    for (var i = 0; i < _questions.length; i++) {
      final t = _controllers[i].text.trim();
      if (t.isNotEmpty) answers['q${i + 1}'] = t;
    }

    // 1. Fire-and-forget: update flag (sets state synchronously, Firebase save
    //    may hang so we must not await it).
    ref.read(authProvider.notifier).updateTrainingFlags(hasBehaviorTrained: true).catchError((_) {});
    debugPrint('[BEHAVIOR] hasBehaviorTrained=true set');

    // 2. Fire-and-forget: train behavior profile.
    ref.read(avatarProvider.notifier).trainBehaviorProfile(
      ownerId: user.uid,
      answers: answers,
    ).then((_) {
      debugPrint('[BEHAVIOR] Training saved');
    }).catchError((Object e) {
      debugPrint('[BEHAVIOR] Training save error (non-blocking): $e');
    });

    // 3. Navigate immediately.
    if (mounted) {
      context.goNamed(RouteNames.avatarPreview);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PresntTokens.surface,
      body: Column(
        children: [
          // Thin top progress (step 5 of 6)
          SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: 5 / 6,
              backgroundColor: PresntTokens.surfaceContainerLowest,
              color: PresntTokens.primary,
            ),
          ),
          PresntGlassTopBar(
            height: 68,
            leading: const CircleAvatar(
              radius: 18,
              backgroundColor: PresntTokens.surfaceContainerHigh,
              child: Icon(Icons.person_rounded, size: 20, color: PresntTokens.onSurfaceVariant),
            ),
            title: Text(
              'PRESNT',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: PresntTokens.primary,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  'STEP 05 / 06',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: PresntTokens.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings_suggest_outlined, color: PresntTokens.primary),
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 840;
                final pad = const EdgeInsets.symmetric(horizontal: 22, vertical: 12);
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 34, child: Padding(padding: pad, child: _leftColumn())),
                      Expanded(flex: 66, child: Padding(padding: pad, child: _formColumn())),
                    ],
                  );
                }
                return SingleChildScrollView(
                  padding: pad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _leftColumn(compact: true),
                      const SizedBox(height: 28),
                      _formColumn(),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2, color: PresntTokens.primary)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _leftColumn({bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: GoogleFonts.manrope(
              fontSize: compact ? 36 : 48,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -1.5,
              color: PresntTokens.onSurface,
            ),
            children: const [
              TextSpan(text: "Let's model your "),
              TextSpan(
                text: 'behavior',
                style: TextStyle(color: PresntTokens.primary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Our neural synthesis engine requires behavioral mapping to replicate your decision-making patterns and communication nuances effectively.',
          style: GoogleFonts.manrope(
            fontSize: 13,
            height: 1.5,
            color: PresntTokens.onSurfaceVariant,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 36),
          _sideCard(
            Icons.auto_awesome_rounded,
            PresntTokens.secondary,
            'COGNITIVE FIDELITY',
            'Your responses calibrate the empathy-logic balance of your Presence.',
          ),
          const SizedBox(height: 16),
          _sideCard(
            Icons.fingerprint_rounded,
            PresntTokens.primary,
            'IDENTITY LOCK',
            'Data is encrypted and used solely for your personalized instance.',
          ),
        ],
      ],
    );
  }

  Widget _sideCard(IconData icon, Color ic, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PresntTokens.surfaceContainerLow.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: PresntTokens.primary, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ic),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
              color: PresntTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.manrope(fontSize: 12, height: 1.4, color: PresntTokens.onSurfaceVariant.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }

  Widget _formColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(_questions.length, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i == _questions.length - 1 ? 24 : 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        '0${i + 1}',
                        style: GoogleFonts.manrope(
                          fontSize: 36,
                          fontWeight: FontWeight.w200,
                          color: PresntTokens.surfaceBright,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _questions[i],
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: PresntTokens.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 0, top: 8),
                  child: TextField(
                    controller: _controllers[i],
                    maxLines: 3,
                    minLines: 2,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.manrope(fontSize: 16, color: PresntTokens.onSurface),
                    decoration: InputDecoration(
                      hintText: _hintFor(i),
                      hintStyle: TextStyle(color: PresntTokens.surfaceBright.withValues(alpha: 0.65)),
                      filled: false,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: PresntTokens.outlineVariant.withValues(alpha: 0.35)),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: PresntTokens.outlineVariant.withValues(alpha: 0.35)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: PresntTokens.primary, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerRight,
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: PresntTokens.primary),
                )
              : FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: PresntTokens.primaryContainer,
                    foregroundColor: PresntTokens.onPrimaryFixed,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _canContinue ? _continue : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    'FINAL STEP',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 12),
                  ),
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _hintFor(int i) {
    const hints = [
      'e.g. Direct, empathetic, succinct…',
      'Integrity, growth, balance…',
      'I analyze my capacity before committing…',
      'Family, career, personal well-being…',
      'Intuition driven, data-backed, collaborative…',
    ];
    return hints[i];
  }
}

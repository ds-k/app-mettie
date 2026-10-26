import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/record.dart';
import '../../../data/repositories/ai_coach_repository.dart';
import '../../../l10n/l10n.dart';
import '../../view_models/ai_coach_view_model.dart';
import '../../view_models/dashboard_view_model.dart';
import '../../widgets/pet_app_bar.dart';
import '../dashboard/widgets/dashboard_record_row.dart';

/// AI 코치: 서버 함수(ai-coach)를 거쳐 Claude가 펫 기록을 근거로 답한다.
class AiCoachView extends ConsumerStatefulWidget {
  const AiCoachView({super.key});

  @override
  ConsumerState<AiCoachView> createState() => _AiCoachViewState();
}

class _AiCoachViewState extends ConsumerState<AiCoachView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final value = (text ?? _input.text).trim();
    if (value.isEmpty) return;
    _input.clear();
    ref.read(aiCoachViewModelProvider.notifier).send(value, locale: context.localeName);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pet = ref.watch(currentPetProvider);
    final state = ref.watch(aiCoachViewModelProvider);
    ref.listen(aiCoachViewModelProvider.select((s) => s.messages), (_, _) => _scrollToEnd());

    final quota = state.quota;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PetAppBar(subtitle: pet == null ? null : l.navCoach, title: pet == null ? l.navCoach : null),
        body: pet == null
            ? _Centered(text: l.coachNoPet)
            : switch (state.status) {
                AiCoachStatus.loading => const Center(child: CircularProgressIndicator(color: kBrandBlue)),
                AiCoachStatus.unavailable => _Centered(
                    text: l.coachNetworkError,
                    action: TextButton(
                      onPressed: () => ref.read(aiCoachViewModelProvider.notifier).refreshQuota(),
                      child: Text(l.coachRetry),
                    ),
                  ),
                AiCoachStatus.needsConsent => const _ConsentCard(),
                AiCoachStatus.ready => Column(
                    children: [
                      _ContextBar(
                        petName: pet.name,
                        records: state.recordsConsidered,
                        quota: quota,
                        canReset: state.messages.isNotEmpty && !state.isGenerating,
                        onReset: () => ref.read(aiCoachViewModelProvider.notifier).clearChat(),
                      ),
                      if (state.bannerError != null) _Banner(code: state.bannerError!, quota: quota),
                      Expanded(
                        child: state.messages.isEmpty
                            ? _Suggestions(onTap: _send)
                            : ListView.builder(
                                controller: _scroll,
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: state.messages.length,
                                itemBuilder: (_, i) => _Bubble(
                                  message: state.messages[i],
                                  isLast: i == state.messages.length - 1,
                                  generating: state.isGenerating,
                                ),
                              ),
                      ),
                      _InputBar(
                        controller: _input,
                        generating: state.isGenerating,
                        enabled: quota == null || quota.remaining > 0 || state.isGenerating,
                        onSend: _send,
                        onStop: () => ref.read(aiCoachViewModelProvider.notifier).stop(),
                      ),
                    ],
                  ),
              },
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  final String text;
  final Widget? action;
  const _Centered({required this.text, this.action});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: kSlate, fontSize: 15, height: 1.5)),
            ?action,
          ]),
        ),
      );
}

class _ConsentCard extends ConsumerWidget {
  const _ConsentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    Widget item(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: kBrandBlueDeep),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(color: kInk, fontSize: 14, height: 1.45))),
          ]),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCanvas,
            borderRadius: BorderRadius.circular(kRadiusXl),
            border: Border.all(color: kHairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.sparkle, color: kBrandBlue, size: 28),
              const SizedBox(height: 12),
              Text(l.consentTitle, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 10),
              Text(l.consentBody, style: const TextStyle(color: kCharcoal, fontSize: 14, height: 1.5)),
              const SizedBox(height: 10),
              item(LucideIcons.pawPrint, l.consentItemPet),
              item(LucideIcons.chartLine, l.consentItemRecords),
              item(LucideIcons.messageCircle, l.consentItemQuestion),
              const SizedBox(height: 10),
              Text(l.consentFooter, style: const TextStyle(color: kSlate, fontSize: 13, height: 1.5)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => ref.read(aiCoachViewModelProvider.notifier).giveConsent(),
                  style: FilledButton.styleFrom(backgroundColor: kBrandBlue, shape: const StadiumBorder()),
                  child: Text(l.consentAgree, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    final base = dotenv.env['WEB_BASE_URL'] ?? 'https://mettieapp.com';
                    launchUrl(Uri.parse('$base/privacy'), mode: LaunchMode.inAppWebView);
                  },
                  child: Text(l.consentPrivacy, style: const TextStyle(color: kSlate)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContextBar extends StatelessWidget {
  final String petName;
  final int? records;
  final AiQuota? quota;
  final bool canReset;
  final VoidCallback onReset;

  const _ContextBar({
    required this.petName,
    required this.records,
    required this.quota,
    required this.canReset,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              records == null ? l.coachContextBefore(petName) : l.coachContextAfter(petName, records!),
              style: const TextStyle(color: kSlate, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (quota != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: quota!.remaining == 0 ? kStatusWarnSoft : kBrandBlueSoft,
                borderRadius: BorderRadius.circular(kRadiusFull),
              ),
              child: Text(
                l.coachQuota(quota!.used, quota!.limit),
                style: TextStyle(
                  color: quota!.remaining == 0 ? kStatusWarn : kBrandBlueDeep,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ),
          IconButton(
            tooltip: l.coachNewChat,
            onPressed: canReset ? onReset : null,
            icon: const Icon(LucideIcons.squarePen, size: 20),
            color: kCharcoal,
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String code;
  final AiQuota? quota;
  const _Banner({required this.code, required this.quota});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = switch (code) {
      'quota_exceeded' => l.coachQuotaExceeded(quota?.limit ?? 0),
      'ai_unavailable' => l.coachUnavailable,
      'pet_not_found' => l.commonLoadError,
      _ => l.coachNetworkError,
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kStatusWarnSoft, borderRadius: BorderRadius.circular(kRadiusLg)),
      child: Text(text, style: const TextStyle(color: kCharcoal, fontSize: 13, height: 1.4)),
    );
  }
}

class _Suggestions extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _Suggestions({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      children: [
        const Icon(LucideIcons.sparkle, color: kBrandBlue, size: 32),
        const SizedBox(height: 12),
        Text(l.coachEmptyTitle,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
        const SizedBox(height: 20),
        for (final q in [l.coachSuggestTrend, l.coachSuggestNadir, l.coachSuggestVet])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: kCanvas,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusLg),
                side: const BorderSide(color: kHairline),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(kRadiusLg),
                onTap: () => onTap(q),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Expanded(child: Text(q, style: const TextStyle(color: kInk, fontSize: 14))),
                    const Icon(LucideIcons.arrowUpRight, size: 16, color: kStone),
                  ]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isLast;
  final bool generating;

  const _Bubble({required this.message, required this.isLast, required this.generating});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final maxWidth = MediaQuery.of(context).size.width * 0.8;

    if (message.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: kBrandBlue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(message.content, style: const TextStyle(color: kOnDark, fontSize: 15, height: 1.45)),
        ),
      );
    }

    final text = visibleReply(message.content);
    final Widget body;
    if (message.errorCode != null) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message.errorCode == 'refused' ? l.coachRefused : l.coachModelError,
            style: const TextStyle(color: kCharcoal, fontSize: 14)),
        if (message.errorCode != 'refused' && isLast)
          TextButton(
            onPressed: () => ref.read(aiCoachViewModelProvider.notifier).retryLast(locale: context.localeName),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(l.coachRetry),
          ),
      ]);
    } else if (text.isEmpty && isLast && generating) {
      body = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: kBrandBlue),
      );
    } else {
      body = MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(color: kInk, fontSize: 15, height: 1.5),
          strong: const TextStyle(color: kBrandBlueDeep, fontWeight: FontWeight.w700),
          listBullet: const TextStyle(color: kInk, fontSize: 15),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kCanvas,
          border: Border.all(color: kHairline),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            body,
            if (message.refs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final r in message.refs) _RefChip(ref: r),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _RefChip extends ConsumerWidget {
  final AiRef ref;
  const _RefChip({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final l = context.l10n;
    final label = l.coachRef(DateFormat.Md(l.localeName).add_Hm().format(ref.recordedAt));
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        final records = widgetRef.read(recordsStreamProvider).value ?? const <Record>[];
        final record = records.where((r) => r.id == ref.recordId).firstOrNull;
        if (record == null) return;
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          backgroundColor: kCanvas,
          showDragHandle: true,
          builder: (_) => SafeArea(child: DashboardRecordRow(record: record)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: kBrandBlueSoft, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: kBrandBlueDeep, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool generating;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onStop;

  const _InputBar({
    required this.controller,
    required this.generating,
    required this.enabled,
    required this.onSend,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Container(
      // 키보드가 닫혀 있으면 떠 있는 하단 탭에 가리지 않게 띄운다
      padding: EdgeInsets.fromLTRB(16, 8, 16, keyboardOpen ? 12 : 112),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled && !generating,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: l.coachInputHint,
                    counterText: '',
                    filled: true,
                    fillColor: kCanvas,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: kHairline)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: kHairline)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: kBrandBlue)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: generating ? l.coachStop : l.coachSend,
                onPressed: generating ? onStop : (enabled ? onSend : null),
                style: IconButton.styleFrom(backgroundColor: generating ? kCharcoal : kBrandBlue),
                icon: Icon(generating ? LucideIcons.square : LucideIcons.arrowUp, color: kOnDark, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(l.coachDisclaimer,
              textAlign: TextAlign.center, style: const TextStyle(color: kStone, fontSize: 11, height: 1.3)),
        ],
      ),
    );
  }
}

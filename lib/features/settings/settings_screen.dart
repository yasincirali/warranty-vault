import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import 'settings.dart';

/// Two decisions and one fact (yasin, 15 Oct: "ayarlar yok, İngilizce de
/// kullanılabilir olmalı"):
/// - language: the phone's, or Türkçe / English regardless of the phone;
/// - country: which law new products are judged by;
/// - where the data lives.
/// Choices are checkmark lists, the iOS Settings pattern, not dropdowns:
/// every option is visible and one tap away.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final ctl = ref.read(settingsProvider.notifier);
    final phoneLanguage = WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'tr' ? l.langTr : l.langEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle),
        backgroundColor: context.c.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.sm, VSpace.xl, VSpace.xxl),
        children: [
          SectionTitle(l.settingsLanguage),
          _Choices(
            children: [
              _Choice(
                label: l.languageSystem,
                detail: phoneLanguage,
                selected: s.language == null,
                onTap: () => ctl.setLanguage(null),
              ),
              _Choice(label: l.langTr, selected: s.language == 'tr', onTap: () => ctl.setLanguage('tr')),
              _Choice(label: l.langEn, selected: s.language == 'en', onTap: () => ctl.setLanguage('en')),
            ],
          ),
          const SizedBox(height: VSpace.xxl),
          SectionTitle(l.settingsRegion),
          _Choices(
            children: [
              _Choice(
                label: l.regionSystem,
                detail: regionName(l, deviceRegion()),
                selected: s.region == null,
                onTap: () => ctl.setRegion(null),
              ),
              for (final r in kRegions)
                _Choice(label: regionName(l, r), selected: s.region == r, onTap: () => ctl.setRegion(r)),
            ],
          ),
          const SizedBox(height: VSpace.sm),
          Text(l.settingsRegionHint, style: context.t.small.copyWith(color: context.c.textSecondary)),
          const SizedBox(height: VSpace.xxl),
          SectionTitle(l.settingsAbout),
          VCard(
            padding: const EdgeInsets.all(VSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.aboutLocal, style: context.t.body),
                const SizedBox(height: VSpace.sm),
                Text(l.disclaimer, style: context.t.small.copyWith(color: context.c.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({required this.children});
  final List<_Choice> children;

  @override
  Widget build(BuildContext context) => VCard(
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: VSpace.lg, color: context.c.divider),
          children[i],
        ],
      ],
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, this.detail, required this.selected, required this.onTap});
  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    button: true,
    child: InkWell(
      onTap: () {
        if (selected) return;
        HapticFeedback.selectionClick();
        onTap();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: VSize.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.lg, vertical: VSpace.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.t.label),
                    if (detail != null) Text(detail!, style: context.t.small.copyWith(color: context.c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: VSpace.md),
              // The checkmark is the state; it also scales in so a change
              // reads even without looking right at it.
              AnimatedScale(
                scale: selected ? 1 : .6,
                duration: VMotion.of(context, VMotion.quick),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: VMotion.of(context, VMotion.quick),
                  curve: Curves.easeOutCubic,
                  child: Icon(Icons.check_rounded, color: context.c.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

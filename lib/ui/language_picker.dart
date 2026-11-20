import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../state/settings_controller.dart';

/// Bottom sheet listing every interface language.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final s = ctx.watch<SettingsController>();
      final l = L.of(ctx);
      final cs = Theme.of(ctx).colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: EdgeInsets.fromLTRB(
            12,
            0,
            12,
            24 + MediaQuery.paddingOf(ctx).bottom,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                l('chooseLanguage'),
                style: Theme.of(ctx).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final lang in kAppLanguages)
              ListTile(
                selected: s.uiLang == lang.code,
                selectedTileColor: cs.primaryContainer.withValues(alpha: 0.4),
                leading: CircleAvatar(
                  backgroundColor: cs.secondaryContainer,
                  child: Text(
                    lang.code.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ),
                title: Text(
                  lang.nativeName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  lang.complete
                      ? lang.englishName
                      : '${lang.englishName} · translation needed',
                ),
                trailing: s.uiLang == lang.code
                    ? Icon(Icons.check_circle_rounded, color: cs.primary)
                    : null,
                onTap: () {
                  s.uiLang = lang.code;
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      );
    },
  );
}

/// Compact app-bar button showing the current language.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final code = context.select<SettingsController, String>((s) => s.uiLang);
    final l = L.of(context);
    return Tooltip(
      message: l('language'),
      child: ActionChip(
        avatar: const Icon(Icons.translate_rounded, size: 18),
        label: Text(appLanguage(code).nativeName),
        onPressed: () => showLanguagePicker(context),
      ),
    );
  }
}

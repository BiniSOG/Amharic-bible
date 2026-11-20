import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/l10n.dart';
import '../data/update_service.dart';

/// Runs the update check once and shows the right prompt.
Future<void> checkForUpdates(BuildContext context) async {
  final info = await UpdateService.check();
  if (info == null || info.kind == UpdateKind.none || !context.mounted) return;
  if (info.kind == UpdateKind.optional &&
      await UpdateService.wasDismissed(info.latestBuild)) {
    return;
  }
  if (!context.mounted) return;
  if (info.kind == UpdateKind.required) {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, _, _) => ForceUpdateScreen(info: info),
      ),
    );
  } else {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final l = L.of(ctx);
        return AlertDialog(
          icon: const Icon(Icons.system_update_rounded),
          title: Text(l('updateAvailable')),
          content: Text(
            [
              '${l('version')} ${info.latestVersion}',
              l.amharic ? info.notesAm : info.notesEn,
            ].where((e) => e.isNotEmpty).join('\n\n'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                UpdateService.dismiss(info.latestBuild);
                Navigator.pop(ctx);
              },
              child: Text(l('later')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _open(info.url);
              },
              child: Text(l('updateNow')),
            ),
          ],
        );
      },
    );
  }
}

Future<void> _open(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Blocks the app until the user installs the required update.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, required this.info});
  final UpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 96,
                      height: 96,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l('updateRequired'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  l('updateRequiredBody'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15.5),
                ),
                if ((l.amharic ? info.notesAm : info.notesEn).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l.amharic ? info.notesAm : info.notesEn),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: const Icon(Icons.system_update_rounded),
                  label: Text('${l('updateNow')} · ${info.latestVersion}'),
                  onPressed: () => _open(info.url),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

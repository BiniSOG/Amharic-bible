import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import 'quiz/quiz_screen.dart';
import 'more_screen.dart';
import 'plans/plans_screen.dart';
import 'reader/reader_screen.dart';
import 'today_screen.dart';
import 'widgets/common.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppNav(),
      child: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  final _built = <int>{0};

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<AppNav>();
    final l = L.of(context);
    _built.add(nav.tab);
    final pages = <Widget>[
      const TodayScreen(),
      const ReaderScreen(),
      const PlansScreen(),
      const QuizHomeScreen(),
      const MoreScreen(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: nav.tab,
        children: [
          for (var i = 0; i < pages.length; i++)
            _built.contains(i) ? pages[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: nav.tab,
        onDestinationSelected: nav.setTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny),
            label: l('today'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l('bible'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: const Icon(Icons.event_note),
            label: l('plans'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.quiz_outlined),
            selectedIcon: const Icon(Icons.quiz),
            label: l('quiz2'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.apps_outlined),
            selectedIcon: const Icon(Icons.apps),
            label: l('more'),
          ),
        ],
      ),
    );
  }
}

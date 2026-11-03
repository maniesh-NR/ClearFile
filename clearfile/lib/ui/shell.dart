import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/assistant.dart';
import 'screens/interview.dart';
import 'screens/results.dart';
import 'screens/settings.dart';
import 'screens/welcome.dart';

/// Adaptive MD3 app shell: a bottom NavigationBar on phones and a
/// NavigationRail on wide screens, mirroring the layout of the web prototype.
class Shell extends StatelessWidget {
  const Shell({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final wide = MediaQuery.widthOf(context) >= 900;
        final screens = [
          WelcomeScreen(state: state),
          InterviewScreen(state: state),
          ResultsScreen(state: state),
          AssistantScreen(state: state),
          SettingsScreen(state: state),
        ];
        final body = wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: state.selectedIndex,
                    onDestinationSelected: state.selectTab,
                    labelType: NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          _Logo(colorScheme: Theme.of(context).colorScheme),
                        ],
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.edit_note_outlined),
                        selectedIcon: Icon(Icons.edit_note),
                        label: Text('Return'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.calculate_outlined),
                        selectedIcon: Icon(Icons.calculate),
                        label: Text('Results'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.forum_outlined),
                        selectedIcon: Icon(Icons.forum),
                        label: Text('Assistant'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: Text('Settings'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: screens[state.selectedIndex]),
                ],
              )
            : screens[state.selectedIndex];

        return Scaffold(
          body: body,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: state.selectedIndex,
                  onDestinationSelected: state.selectTab,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.edit_note_outlined),
                      selectedIcon: Icon(Icons.edit_note),
                      label: 'Return',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.calculate_outlined),
                      selectedIcon: Icon(Icons.calculate),
                      label: 'Results',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.forum_outlined),
                      selectedIcon: Icon(Icons.forum),
                      label: 'Assistant',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.receipt_long, color: colorScheme.onPrimary, size: 22),
    );
  }
}

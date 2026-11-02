/// Home flow: the guided interview. Topics list → interview pages →
/// review → results, rendered inside the shell like TurboTax's left-rail
/// navigation. Direct File influence: one question at a time, plain
/// language, "check your answers" review before results.
library;

import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import 'topics.dart';
import 'interview.dart';
import 'review.dart';
import 'results.dart';

class HomeFlow extends StatelessWidget {
  final AppState state;
  const HomeFlow({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (route) {
        final name = route.name ?? '/';
        Widget page;
        switch (name) {
          case '/review':
            page = ReviewScreen(state: state);
            break;
          case '/results':
            page = ResultsScreen(state: state);
            break;
          default:
            if (name != '/' && name.startsWith('/topic/')) {
              final topicId = name.substring('/topic/'.length);
              page = InterviewScreen(state: state, topicId: topicId);
            } else {
              page = TopicsScreen(state: state);
            }
        }
        return MaterialPageRoute(builder: (_) => page, settings: route);
      },
    );
  }
}

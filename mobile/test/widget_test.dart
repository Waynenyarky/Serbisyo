import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:serbisyo/app/app.dart';
import 'package:serbisyo/core/router/app_router.dart';

void main() {
  testWidgets('App loads login route', (WidgetTester tester) async {
    final router = createAppRouter(initialLocation: '/login');
    await tester.pumpWidget(
      ProviderScope(
        child: SerbisyoApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsOneWidget);
  });
}

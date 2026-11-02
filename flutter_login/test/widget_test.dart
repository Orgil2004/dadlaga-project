import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:flutter_login/home_page.dart';
import 'package:flutter_login/main.dart';
import 'package:flutter_login/user/workspace.dart';
import 'package:flutter_login/user_data.dart';

Future<void> navigate(WidgetTester tester, int index) async {
  final rail = find.byType(NavigationRail);
  if (rail.evaluate().isNotEmpty) {
    const labels = [
      'Нүүр',
      'Газрын зураг',
      'Хадгалсан',
      'Зар нэмэх',
      'Мессеж',
      'Профайл',
    ];
    await tester.tap(
      find.descendant(of: rail, matching: find.text(labels[index])),
    );
  } else {
    await tester.tap(find.byType(NavigationDestination).at(index));
  }
  await tester.pumpAndSettle();
}

Future<void> enterField(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    UserData.name = 'Demo User';
    UserData.email = 'user@gmail.com';
    UserData.password = '123456';
  });

  testWidgets('Login opens user area; desktop has all six destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextFormField).at(0), 'user@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    for (final index in [2, 3, 4, 5, 0, 1]) {
      await navigate(tester, index);
      expect(tester.takeException(), isNull);
    }
    expect(find.byType(FlutterMap), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Mobile can save a listing and remove it from saved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final workspace = UserWorkspace(account: UserData.email, persist: false);
    await tester.pumpWidget(MaterialApp(home: HomePage(workspace: workspace)));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('MacBook Air M2'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final save = find.byTooltip('Зар хадгалах').first;
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    await navigate(tester, 2);
    expect(find.text('MacBook Air M2'), findsOneWidget);
    await tester.tap(find.byTooltip('Хадгалснаас хасах'));
    await tester.pumpAndSettle();
    expect(find.text('Хадгалсан зар алга'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New listing validates input and appears in feed and profile', (
    tester,
  ) async {
    final workspace = UserWorkspace(account: UserData.email, persist: false);
    await tester.pumpWidget(MaterialApp(home: HomePage(workspace: workspace)));
    await navigate(tester, 3);
    final submit = find.widgetWithText(FilledButton, 'Зар нэмэх');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(workspace.myListings, isEmpty);
    await enterField(tester, 'Зарын гарчиг', 'Туршилтын утас');
    await enterField(tester, 'Үнэ', '350000');
    await enterField(tester, 'Байршил / хаяг', 'Хан-Уул дүүрэг');
    await enterField(
      tester,
      'Дэлгэрэнгүй тайлбар',
      'Цэвэрхэн хэрэглэсэн утас.',
    );
    await enterField(tester, 'Өргөрөг', 'NaN');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(workspace.myListings, isEmpty);
    await enterField(tester, 'Өргөрөг', '47.9');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(workspace.myListings.single.title, 'Туршилтын утас');
    await tester.enterText(
      find.widgetWithText(TextField, 'Зар хайх'),
      'Туршилтын утас',
    );
    await tester.pumpAndSettle();
    expect(find.text('Туршилтын утас'), findsOneWidget);
    await navigate(tester, 5);
    expect(find.text('Миний зар: 1'), findsOneWidget);
    await enterField(tester, 'Нэр', 'Бат');
    final save = find.widgetWithText(FilledButton, 'Профайл хадгалах');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(workspace.name, 'Бат');
    await navigate(tester, 0);
    expect(find.text('Сайн байна уу, Бат!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Listing opens local conversation; message survives navigation', (
    tester,
  ) async {
    final workspace = UserWorkspace(account: UserData.email, persist: false);
    await tester.pumpWidget(MaterialApp(home: HomePage(workspace: workspace)));
    await tester.pumpAndSettle();
    final ad = find.text('MacBook Air M2');
    await tester.scrollUntilVisible(
      ad,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(ad);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Мессеж бичих'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Мессеж бичих…'),
      'Сайн байна уу?',
    );
    await tester.tap(find.byTooltip('Мессежийг төхөөрөмжид хадгалах'));
    await tester.pumpAndSettle();
    await navigate(tester, 0);
    await navigate(tester, 4);
    expect(find.text('Сайн байна уу?'), findsOneWidget);
    expect(workspace.messages['demo-1'], ['Сайн байна уу?']);
    expect(tester.takeException(), isNull);
  });
}

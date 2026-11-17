import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_login/home_page.dart';
import 'package:flutter_login/user/feed_page.dart';
import 'package:flutter_login/user/store_catalog.dart';
import 'package:flutter_login/user/workspace.dart';

Map<String, dynamic> shop(int id, String name, String category, String item) => {
  'id': id,
  'name': name,
  'category': category,
  'category_icon': 'checkroom',
  'address': 'Сүхбаатар дүүрэг',
  'latitude': 47.92,
  'longitude': 106.91,
  'products': [
    {'id': id * 10, 'name': item, 'price': '129000', 'in_stock': true},
  ],
};

StoreRepository fakeApi() => StoreRepository(
  client: MockClient((request) async {
    final body = request.url.path.endsWith('categories/')
        ? [
            {'id': 1, 'name': 'Хувцас', 'icon': 'checkroom'},
            {'id': 2, 'name': 'Гоо сайхан', 'icon': 'spa'},
          ]
        : [
            shop(1, 'Nomin Fashion', 'Хувцас', 'Хүрэм'),
            shop(2, 'Beauty Lab', 'Гоо сайхан', 'Нүүрний тос'),
          ];
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }),
);

Future<void> phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  test('filterStores matches store name, product and category', () {
    final stores = [
      MapStore.fromJson(shop(1, 'Nomin Fashion', 'Хувцас', 'Хүрэм')),
      MapStore.fromJson(shop(2, 'Beauty Lab', 'Гоо сайхан', 'Нүүрний тос')),
    ];
    expect(filterStores(stores, query: 'nomin').single.id, 1);
    expect(filterStores(stores, query: 'ХҮРЭМ').single.id, 1);
    expect(filterStores(stores, category: 'Гоо сайхан').single.id, 2);
    expect(filterStores(stores, query: 'хүрэм', category: 'Гоо сайхан'), []);
    expect(stores.first.productsMatching('хүрэм').single.name, 'Хүрэм');
  });

  testWidgets('Feed search shows a new store by name and opens it (375px)', (
    tester,
  ) async {
    await phone(tester);
    final api = fakeApi();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedPage(
            workspace: UserWorkspace(account: 't', persist: false),
            onOpen: (_) {},
            onMap: () {},
            repository: api,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('feed-search')), 'nomin');
    await tester.pumpAndSettle();
    expect(find.text('Дэлгүүр (1)'), findsOneWidget);
    expect(find.text('Beauty Lab'), findsNothing);
    final card = find.byKey(const ValueKey('feed-store-1'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('Дэлгүүрийн бараанууд'), findsOneWidget);
    expect(find.text('Хүрэм'), findsWidgets);
    expect(tester.takeException(), isNull);
    api.dispose();
  });

  testWidgets('Admin categories reach the feed chips and the ad form', (
    tester,
  ) async {
    await phone(tester);
    final api = fakeApi();
    final workspace = UserWorkspace(account: 't', persist: false);
    await tester.pumpWidget(
      MaterialApp(home: HomePage(workspace: workspace, repository: api)),
    );
    await tester.pumpAndSettle();
    expect(workspace.categories, ['Хувцас', 'Гоо сайхан']);
    expect(find.widgetWithText(ChoiceChip, 'Гоо сайхан'), findsOneWidget);
    // Demo ads in older categories still stay filterable.
    expect(find.widgetWithText(ChoiceChip, 'Электрон бараа'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Гоо сайхан'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Beauty Lab'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Beauty Lab'), findsOneWidget);
    expect(find.text('Nomin Fashion'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });

  testWidgets('An ad cannot be posted without a price', (tester) async {
    await phone(tester);
    final api = fakeApi();
    final workspace = UserWorkspace(account: 't', persist: false);
    await tester.pumpWidget(
      MaterialApp(home: HomePage(workspace: workspace, repository: api)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    final before = workspace.listings.length;
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Зарын гарчиг'),
      'Хүрэм',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Байршил / хаяг'),
      'Төв',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Дэлгэрэнгүй тайлбар'),
      'Шинэ',
    );
    final submit = find.byKey(const ValueKey('listing-submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Үнийг заавал оруулна уу'), findsOneWidget);
    expect(workspace.listings.length, before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });
}

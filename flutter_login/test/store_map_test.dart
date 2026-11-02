import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_login/user/map_page.dart';
import 'package:flutter_login/user/store_catalog.dart';
import 'package:flutter_login/user/workspace.dart';

Map<String, dynamic> shopJson(
  int id,
  String name,
  double latitude, {
  String product = 'Хүрэм',
}) => {
  'id': id,
  'name': name,
  'category': 'Хувцас',
  'address': 'Төв',
  'latitude': latitude,
  'longitude': 106.9177,
  'opening_hours': '10:00–20:00',
  'products': [
    {
      'id': id * 10,
      'name': product,
      'category': 'Хувцас',
      'price': '129000',
      'sizes': 'M, L',
      'colors': 'Хар',
      'in_stock': true,
    },
  ],
};

void main() {
  test('Search finds clothing, excludes stores without a point and sorts by distance', () {
    final near = MapStore.fromJson(shopJson(1, 'Urban', 47.919));
    final far = MapStore.fromJson(shopJson(2, 'Step', 48.5, product: 'Кет'));
    final noLocation = MapStore.fromJson({
      ...shopJson(3, 'Unknown', 47.9),
      'latitude': null,
    });
    final results = searchStores([
      far,
      noLocation,
      near,
    ], center: const LatLng(47.9185, 106.9177));
    expect(results.map((result) => result.store.name), ['Urban', 'Step']);
    expect(
      searchStores(
        [near, far],
        center: const LatLng(47.9185, 106.9177),
        radiusKm: 1,
      ).single.store.id,
      1,
    );
    expect(
      searchStores(
        [near, far],
        center: const LatLng(47.9185, 106.9177),
        query: 'хҮрЭм хар',
      ).single.store.id,
      1,
    );
    expect(
      searchStores(
        [near],
        center: const LatLng(47.9185, 106.9177),
        query: 'кет',
      ),
      isEmpty,
    );
    expect(
      searchStores(
        [near],
        center: const LatLng(47.9185, 106.9177),
        category: 'Гутал',
      ),
      isEmpty,
    );
  });

  test('Repository decodes UTF-8 stores and handles paginated APIs', () async {
    final repository = StoreRepository(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'results': [
              shopJson(request.url.query.isEmpty ? 1 : 2, 'Хувцас', 47.9),
            ],
            'next': request.url.query.isEmpty ? '?page=2' : null,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final stores = await repository.fetchStores();
    expect(stores.map((store) => store.id), [1, 2]);
    expect(stores.first.products.first.sizes, 'M, L');
    repository.dispose();
  });

  test(
    'Repository rejects an API error instead of showing fabricated stores',
    () async {
      final repository = StoreRepository(
        client: MockClient((_) async => http.Response('offline', 503)),
      );
      await expectLater(repository.fetchStores(), throwsStateError);
      repository.dispose();
    },
  );

  testWidgets(
    'Map search opens a shop, and newly added clothing appears after refresh',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var updated = false;
      final repository = StoreRepository(
        client: MockClient((request) async {
          final shop = shopJson(1, 'Urban', 47.919);
          if (updated)
            (shop['products'] as List).add({
              'id': 22,
              'name': 'Шинэ футболк',
              'price': '45000',
              'sizes': 'S, M',
              'in_stock': true,
            });
          return http.Response(
            jsonEncode(
              request.url.path.endsWith('/1/')
                  ? shop
                  : [shop, shopJson(2, 'Step', 47.92, product: 'Кет')],
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserMapPage(
              workspace: UserWorkspace(account: 'test', persist: false),
              onOpen: (_) {},
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('store-search')),
        'хүрэм',
      );
      await tester.pumpAndSettle();
      expect(find.text('1 дэлгүүр олдлоо'), findsOneWidget);
      expect(find.text('Step'), findsNothing);
      final result = find.byKey(const ValueKey('store-result-1'));
      await tester.scrollUntilVisible(
        result,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(result);
      await tester.pumpAndSettle();
      expect(find.text('Дэлгүүрийн бараанууд'), findsOneWidget);
      expect(find.text('Хүрэм'), findsOneWidget);
      updated = true;
      await tester.tap(find.byTooltip('Барааг шинэчлэх'));
      await tester.pumpAndSettle();
      expect(find.text('Шинэ футболк'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      repository.dispose();
    },
  );

  testWidgets(
    'Mobile location searches from GPS; denied location keeps the manual center',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var denied = false;
      final repository = StoreRepository(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode([
              shopJson(1, 'Төвийн дэлгүүр', 47.919),
              shopJson(2, 'Алсын дэлгүүр', 48.5),
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserMapPage(
              workspace: UserWorkspace(account: 'test', persist: false),
              onOpen: (_) {},
              repository: repository,
              locate: () async {
                if (denied)
                  throw const MapLocationException(
                    'Байршлын зөвшөөрөл олгосонгүй.',
                  );
                return const LatLng(48.5, 106.9177);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Миний байршил'));
      await tester.pumpAndSettle();
      expect(find.text('Миний байршлаас хайж байна.'), findsOneWidget);
      final result = find.byKey(const ValueKey('store-result-2'));
      await tester.scrollUntilVisible(
        result,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Алсын дэлгүүр'), findsOneWidget);
      expect(find.text('Төвийн дэлгүүр'), findsNothing);
      denied = true;
      final locateButton = find.widgetWithText(FilledButton, 'Миний байршил');
      await tester.ensureVisible(locateButton);
      await tester.pumpAndSettle();
      await tester.tap(locateButton);
      await tester.pumpAndSettle();
      expect(find.text('Байршлын зөвшөөрөл олгосонгүй.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      repository.dispose();
    },
  );
}

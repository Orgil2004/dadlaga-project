import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:flutter_login/user/workspace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('Listings, bookmarks, profile and messages restore for the same account only', () async {
    final first = UserWorkspace(account: 'first@example.com');
    final ad = Listing(
      id: 'own',
      title: 'Утас',
      category: 'Электрон бараа',
      price: 100000,
      address: 'Улаанбаатар',
      description: 'Тайлбар',
      owner: 'Бат',
      latitude: 47.9,
      longitude: 106.9,
      isMine: true,
    );
    await first.addListing(ad);
    await first.toggleSaved(ad);
    await first.addMessage('demo-1', 'Ажиллаж байгаа юу?');
    await first.updateProfile('Бат', '99112233', 'Миний тухай');

    final restored = UserWorkspace(account: 'first@example.com');
    await restored.load();
    expect(restored.myListings.single.title, 'Утас');
    expect(restored.savedListings.single.id, 'own');
    expect(restored.messages['demo-1'], ['Ажиллаж байгаа юу?']);
    expect(
      [restored.name, restored.phone, restored.bio],
      ['Бат', '99112233', 'Миний тухай'],
    );
    final other = UserWorkspace(account: 'second@example.com');
    await other.load();
    expect(other.myListings, isEmpty);
    expect(other.savedListings, isEmpty);
    expect(other.messages, isEmpty);
  });

  test('Rapid bookmark changes persist in their final order', () async {
    final workspace = UserWorkspace(account: 'first@example.com');
    await Future.wait([
      workspace.toggleSaved(demoListings.first),
      workspace.toggleSaved(demoListings[1]),
      workspace.toggleSaved(demoListings.first),
    ]);
    final restored = UserWorkspace(account: 'first@example.com');
    await restored.load();
    expect(restored.savedIds, {'demo-2'});
  });

  test('Corrupt local storage reports an error while leaving example listings usable', () async {
    await SharedPreferencesAsync().setString(
      'haana_workspace_v1_first@example.com',
      '{invalid',
    );
    final workspace = UserWorkspace(account: 'first@example.com');
    await workspace.load();
    expect(workspace.storageError, isNotNull);
    expect(workspace.listings.length, demoListings.length);
  });
}

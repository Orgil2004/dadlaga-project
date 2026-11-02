import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

String tugrik(num value) =>
    '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ')} ₮';

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.name,
    required this.price,
    this.category = '',
    this.description = '',
    this.sizes = '',
    this.colors = '',
    this.imageUrl = '',
    this.inStock = true,
  });
  final int id;
  final String name, category, description, sizes, colors, imageUrl;
  final double price;
  final bool inStock;

  factory StoreProduct.fromJson(Map<String, dynamic> json) => StoreProduct(
    id: json['id'] as int,
    name: json['name'] as String,
    price: double.parse(json['price'].toString()),
    category: json['category'] as String? ?? '',
    description: json['description'] as String? ?? '',
    sizes: json['sizes'] as String? ?? '',
    colors: json['colors'] as String? ?? '',
    imageUrl: json['image_url'] as String? ?? '',
    inStock: json['in_stock'] as bool? ?? true,
  );

  String get searchable =>
      '$name $category $description $sizes $colors'.toLowerCase();
}

class MapStore {
  const MapStore({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    this.latitude,
    this.longitude,
    this.phone = '',
    this.description = '',
    this.openingHours = '',
    this.isDemo = false,
    this.products = const [],
  });
  final int id;
  final String name, category, address, phone, description, openingHours;
  final double? latitude, longitude;
  final bool isDemo;
  final List<StoreProduct> products;

  factory MapStore.fromJson(Map<String, dynamic> json) => MapStore(
    id: json['id'] as int,
    name: json['name'] as String,
    category: json['category'] as String,
    address: json['address'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    phone: json['phone'] as String? ?? '',
    description: json['description'] as String? ?? '',
    openingHours: json['opening_hours'] as String? ?? '',
    isDemo: json['is_demo'] as bool? ?? false,
    products: (json['products'] as List? ?? [])
        .map(
          (item) =>
              StoreProduct.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
  );

  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude!.abs() <= 85 &&
      longitude!.abs() <= 180;
  LatLng get point => LatLng(latitude!, longitude!);
  String get searchable =>
      '$name $category $address $description ${products.map((p) => p.searchable).join(' ')}'
          .toLowerCase();
}

class StoreMatch {
  const StoreMatch(this.store, this.kilometers);
  final MapStore store;
  final double kilometers;
  String get distanceLabel => kilometers < 1
      ? '${(kilometers * 1000).round()} м'
      : '${kilometers.toStringAsFixed(1)} км';
}

List<StoreMatch> searchStores(
  List<MapStore> stores, {
  required LatLng center,
  String query = '',
  String category = 'Бүгд',
  double? radiusKm,
}) {
  final words = query
      .toLowerCase()
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  final matches = <StoreMatch>[];
  for (final store in stores) {
    if (!store.hasLocation ||
        (category != 'Бүгд' && store.category != category) ||
        !words.every(store.searchable.contains))
      continue;
    final km = const Distance()(center, store.point) / 1000;
    if (radiusKm == null || km <= radiusKm) matches.add(StoreMatch(store, km));
  }
  matches.sort((a, b) {
    final distance = a.kilometers.compareTo(b.kilometers);
    return distance == 0 ? a.store.id.compareTo(b.store.id) : distance;
  });
  return matches;
}

class StoreRepository {
  StoreRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = Uri.parse(
        baseUrl ??
            const String.fromEnvironment(
              'MAP_API_BASE_URL',
              defaultValue: 'http://127.0.0.1:8000/api/',
            ),
      );
  final http.Client _client;
  final Uri baseUrl;

  Future<dynamic> _get(Uri uri) async {
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200)
      throw StateError('API ${response.statusCode}');
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<List<MapStore>> fetchStores() async {
    var next = baseUrl.resolve('organizations/');
    final stores = <MapStore>[];
    final seen = <Uri>{};
    while (seen.add(next)) {
      final json = await _get(next);
      final rows = json is List
          ? json
          : (json as Map<String, dynamic>)['results'] as List;
      stores.addAll(
        rows.map(
          (row) => MapStore.fromJson(Map<String, dynamic>.from(row as Map)),
        ),
      );
      if (json is List || json['next'] == null) return stores;
      final nextPage = next.resolve(json['next'] as String);
      if (nextPage.origin != baseUrl.origin)
        throw const FormatException('Invalid API pagination origin');
      next = nextPage;
    }
    throw const FormatException('Repeated API page');
  }

  Future<MapStore> fetchStore(int id) async => MapStore.fromJson(
    Map<String, dynamic>.from(
      await _get(baseUrl.resolve('organizations/$id/')) as Map,
    ),
  );
  void dispose() => _client.close();
}

class MapLocationException implements Exception {
  const MapLocationException(this.message);
  final String message;
}

Future<LatLng> locateMapUser() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const MapLocationException(
        'Төхөөрөмжийн байршлын үйлчилгээг асаана уу.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const MapLocationException(
        'Байршлын зөвшөөрөл олгосонгүй. Газрын зургаа хөдөлгөөд «Энэ орчмоос хайх» товчийг ашиглаж болно.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  } on MapLocationException {
    rethrow;
  } on TimeoutException {
    throw const MapLocationException(
      'Байршил тогтоох хугацаа дууслаа. Дахин оролдоно уу.',
    );
  } catch (_) {
    throw const MapLocationException(
      'Байршил тогтоож чадсангүй. Хөтөчийн байршлын зөвшөөрлийг шалгана уу.',
    );
  }
}

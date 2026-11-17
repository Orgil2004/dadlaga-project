import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../user_data.dart';

/// Used until the admin-managed categories load (or if the API is offline).
const listingCategories = [
  'Бүгд',
  'Электрон бараа',
  'Гэр ахуй',
  'Хувцас',
  'Үйлчилгээ',
];

class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.address,
    required this.description,
    required this.owner,
    required this.latitude,
    required this.longitude,
    this.isMine = false,
  });

  final String id, title, category, address, description, owner;
  final int price;
  final double latitude, longitude;
  final bool isMine;

  String get priceLabel =>
      '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ')} ₮';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'price': price,
    'address': address,
    'description': description,
    'owner': owner,
    'latitude': latitude,
    'longitude': longitude,
    'isMine': isMine,
  };

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    price: json['price'] as int,
    address: json['address'] as String,
    description: json['description'] as String,
    owner: json['owner'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    isMine: true,
  );
}

const demoListings = [
  Listing(
    id: 'demo-1',
    title: 'MacBook Air M2',
    category: 'Электрон бараа',
    price: 2400000,
    address: 'Сүхбаатар дүүрэг, 1-р хороо',
    description:
        '8GB RAM, 256GB SSD. Цэнэглэгчийн хамт, цэвэрхэн хэрэглэсэн. Энэ нь жишээ зар юм.',
    owner: 'Техно дэлгүүр',
    latitude: 47.9185,
    longitude: 106.9177,
  ),
  Listing(
    id: 'demo-2',
    title: 'Модон ажлын ширээ',
    category: 'Гэр ахуй',
    price: 180000,
    address: 'Баянгол дүүрэг, 3-р хороо',
    description: '120 × 60 см хэмжээтэй ажлын ширээ. Энэ нь жишээ зар юм.',
    owner: 'Гэр тохижилт',
    latitude: 47.9105,
    longitude: 106.8860,
  ),
  Listing(
    id: 'demo-3',
    title: 'Намрын хүрэм',
    category: 'Хувцас',
    price: 85000,
    address: 'Чингэлтэй дүүрэг, 4-р хороо',
    description: 'M размер, шинэ хүрэм. Энэ нь жишээ зар юм.',
    owner: 'Urban хувцас',
    latitude: 47.9250,
    longitude: 106.9090,
  ),
  Listing(
    id: 'demo-4',
    title: 'Дугуй засварын үйлчилгээ',
    category: 'Үйлчилгээ',
    price: 25000,
    address: 'Баянзүрх дүүрэг, 6-р хороо',
    description: 'Унадаг дугуйн тохиргоо, засвар. Энэ нь жишээ зар юм.',
    owner: 'Дугуй засвар',
    latitude: 47.9180,
    longitude: 106.9450,
  ),
];

class UserWorkspace extends ChangeNotifier {
  UserWorkspace({required this.account, bool persist = true})
    : _preferences = persist ? SharedPreferencesAsync() : null;

  final String account;
  final SharedPreferencesAsync? _preferences;
  final List<Listing> listings = [...demoListings];
  final Set<String> savedIds = {};
  final Map<String, List<String>> messages = {};

  /// Selectable categories (without 'Бүгд'), in admin order.
  List<String> categories = listingCategories.skip(1).toList();
  String name = UserData.name;
  String phone = '';
  String bio = '';
  String? storageError;
  Future<void> _pendingWrite = Future.value();
  bool _disposed = false;
  String get _key => 'haana_workspace_v1_${account.toLowerCase()}';
  List<Listing> get savedListings =>
      listings.where((ad) => savedIds.contains(ad.id)).toList();
  List<Listing> get myListings => listings.where((ad) => ad.isMine).toList();

  Future<void> load() async {
    if (_preferences == null) return;
    try {
      final raw = await _preferences.getString(_key);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // Decode before changing state so a corrupt record cannot load halfway.
      final own = (json['listings'] as List)
          .map((ad) => Listing.fromJson(Map<String, dynamic>.from(ad as Map)))
          .toList();
      final saved = (json['saved'] as List).cast<String>().toSet();
      final chats = (json['messages'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as List).cast<String>()),
      );
      name = json['name'] as String;
      phone = json['phone'] as String;
      bio = json['bio'] as String;
      listings.addAll(own);
      savedIds.addAll(saved);
      messages.addAll(chats);
      UserData.name = name;
    } catch (_) {
      storageError =
          'Хадгалсан мэдээллийг уншиж чадсангүй. Дахин нэвтэрч үзнэ үү.';
    }
  }

  Future<void> _save() {
    storageError = null;
    notifyListeners();
    if (_preferences == null) return Future.value();
    final raw = jsonEncode({
      'listings': myListings.map((ad) => ad.toJson()).toList(),
      'saved': savedIds.toList(),
      'messages': messages,
      'name': name,
      'phone': phone,
      'bio': bio,
    });
    // Keep rapid changes in order when asynchronous platform writes overlap.
    _pendingWrite = _pendingWrite.then(
      (_) => _preferences.setString(_key, raw),
    );
    _pendingWrite = _pendingWrite.catchError((Object error) {
      storageError =
          'Мэдээлэл төхөөрөмжид хадгалагдсангүй. Дараа дахин оролдоно уу.';
      if (!_disposed) notifyListeners();
    });
    return _pendingWrite;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void setCategories(List<String> names) {
    final clean = [
      for (final name in names)
        if (name.trim().isNotEmpty) name.trim(),
    ];
    if (clean.isEmpty || listEquals(clean, categories)) return;
    categories = clean;
    if (!_disposed) notifyListeners();
  }

  /// Filter chips: 'Бүгд', admin categories, then any category still used
  /// by an ad (e.g. an ad made before its category was renamed).
  List<String> get filterCategories => [
    'Бүгд',
    ...categories,
    ...{
      for (final ad in listings)
        if (!categories.contains(ad.category)) ad.category,
    },
  ];

  Future<void> toggleSaved(Listing ad) {
    if (!savedIds.add(ad.id)) savedIds.remove(ad.id);
    return _save();
  }

  Future<void> addListing(Listing ad) {
    listings.insert(0, ad);
    return _save();
  }

  Future<void> startChat(Listing ad) {
    messages.putIfAbsent(ad.id, () => []);
    return _save();
  }

  Future<void> addMessage(String listingId, String text) {
    if (text.trim().isEmpty) return Future.value();
    messages.putIfAbsent(listingId, () => []).add(text.trim());
    return _save();
  }

  Future<void> updateProfile(String newName, String newPhone, String newBio) {
    name = newName.trim();
    phone = newPhone.trim();
    bio = newBio.trim();
    UserData.name = name;
    return _save();
  }
}

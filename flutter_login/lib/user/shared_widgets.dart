import 'package:flutter/material.dart';

import 'workspace.dart';

/// Icon key per category name, filled from the admin-managed categories.
final categoryIconKeys = <String, String>{
  'Электрон бараа': 'devices',
  'Гэр ахуй': 'chair',
  'Хувцас': 'checkroom',
  'Гутал': 'footwear',
  'Спорт': 'sports',
  'Үйлчилгээ': 'handyman',
};

IconData iconForKey(String key) => switch (key) {
  'devices' => Icons.devices_rounded,
  'chair' => Icons.chair_outlined,
  'checkroom' => Icons.checkroom_rounded,
  'footwear' => Icons.hiking_rounded,
  'sports' => Icons.sports_basketball_outlined,
  'restaurant' => Icons.restaurant_outlined,
  'grocery' => Icons.local_grocery_store_outlined,
  'spa' => Icons.spa_outlined,
  'car' => Icons.directions_car_outlined,
  'book' => Icons.menu_book_outlined,
  'pets' => Icons.pets_outlined,
  'child' => Icons.child_care_outlined,
  'handyman' => Icons.handyman_outlined,
  _ => Icons.category_outlined,
};

IconData categoryIcon(String category) =>
    iconForKey(categoryIconKeys[category] ?? 'other');

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Colors.blueGrey)),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.indigo.shade200),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    ),
  );
}

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.workspace,
    required this.onOpen,
  });
  final Listing listing;
  final UserWorkspace workspace;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final saved = workspace.savedIds.contains(listing.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 132,
              color: Colors.indigo.shade50,
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      categoryIcon(listing.category),
                      size: 58,
                      color: Colors.indigo.shade300,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 12,
                    child: Chip(
                      label: Text(listing.isMine ? 'Миний зар' : 'Жишээ зар'),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton.filledTonal(
                      tooltip: saved ? 'Хадгалснаас хасах' : 'Зар хадгалах',
                      onPressed: () => workspace.toggleSaved(listing),
                      icon: Icon(
                        saved ? Icons.bookmark : Icons.bookmark_border,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.category,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.priceLabel,
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 15,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListingGrid extends StatelessWidget {
  const ListingGrid({
    super.key,
    required this.listings,
    required this.workspace,
    required this.onOpen,
  });
  final List<Listing> listings;
  final UserWorkspace workspace;
  final ValueChanged<Listing> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 3
          : constraints.maxWidth >= 600
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final ad in listings)
            SizedBox(
              width: width,
              child: ListingCard(
                listing: ad,
                workspace: workspace,
                onOpen: () => onOpen(ad),
              ),
            ),
        ],
      );
    },
  );
}

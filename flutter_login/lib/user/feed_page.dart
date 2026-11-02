import 'package:flutter/material.dart';

import 'shared_widgets.dart';
import 'workspace.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    required this.workspace,
    required this.onOpen,
    required this.onMap,
  });
  final UserWorkspace workspace;
  final ValueChanged<Listing> onOpen;
  final VoidCallback onMap;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  String query = '', category = 'Бүгд';

  @override
  Widget build(BuildContext context) {
    final visible = widget.workspace.listings
        .where(
          (ad) =>
              (category == 'Бүгд' || ad.category == category) &&
              '${ad.title} ${ad.address} ${ad.description} ${ad.owner}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF243A80), Color(0xFF5264BE)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ХАЙСАН БҮХЭН ЭНД',
                style: TextStyle(
                  color: Colors.white70,
                  letterSpacing: 2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Сайн байна уу, ${widget.workspace.name}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Өөрт хэрэгтэй бараа, үйлчилгээг ойроос олоорой.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: widget.onMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Газрын зураг харах'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          onChanged: (value) => setState(() => query = value.trim()),
          decoration: const InputDecoration(
            labelText: 'Зар хайх',
            hintText: 'Бараа, үйлчилгээ, байршил…',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in listingCategories)
              ChoiceChip(
                label: Text(item),
                selected: category == item,
                onSelected: (_) => setState(() => category = item),
              ),
          ],
        ),
        const SizedBox(height: 24),
        PageHeading(
          'Шинэ зарууд',
          '${visible.length} зар · Жишээ заруудыг туршилтаар оруулсан.',
        ),
        if (visible.isEmpty)
          const EmptyState(
            icon: Icons.search_off,
            title: 'Зар олдсонгүй',
            subtitle: 'Хайлтын үг эсвэл ангиллаа солиод үзээрэй.',
          )
        else
          ListingGrid(
            listings: visible,
            workspace: widget.workspace,
            onOpen: widget.onOpen,
          ),
      ],
    );
  }
}

class SavedPage extends StatelessWidget {
  const SavedPage({super.key, required this.workspace, required this.onOpen});
  final UserWorkspace workspace;
  final ValueChanged<Listing> onOpen;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      PageHeading(
        'Хадгалсан зарууд',
        '${workspace.savedListings.length} зар хадгалсан байна.',
      ),
      if (workspace.savedListings.isEmpty)
        const EmptyState(
          icon: Icons.bookmark_border,
          title: 'Хадгалсан зар алга',
          subtitle: 'Зарын баруун дээд булан дахь хадгалах товчийг дараарай.',
        )
      else
        ListingGrid(
          listings: workspace.savedListings,
          workspace: workspace,
          onOpen: onOpen,
        ),
    ],
  );
}

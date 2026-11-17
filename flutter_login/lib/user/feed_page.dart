import 'package:flutter/material.dart';

import 'shared_widgets.dart';
import 'store_catalog.dart';
import 'store_detail_page.dart';
import 'workspace.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    required this.workspace,
    required this.onOpen,
    required this.onMap,
    this.repository,
  });
  final UserWorkspace workspace;
  final ValueChanged<Listing> onOpen;
  final VoidCallback onMap;

  /// Stores from the backend; when null the feed shows ads only.
  final StoreRepository? repository;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final search = TextEditingController();
  String query = '', category = 'Бүгд';
  List<MapStore> stores = [];
  bool storesLoading = false;
  String? storesError;

  @override
  void initState() {
    super.initState();
    loadStores();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> loadStores() async {
    final repository = widget.repository;
    if (repository == null) return;
    setState(() {
      storesLoading = true;
      storesError = null;
    });
    try {
      final result = await repository.fetchStores();
      if (mounted) setState(() => stores = result);
    } catch (_) {
      if (mounted) {
        setState(
          () => storesError =
              'Дэлгүүрүүдийг ачаалж чадсангүй. Зөвхөн зарууд дотроос хайлаа.',
        );
      }
    } finally {
      if (mounted) setState(() => storesLoading = false);
    }
  }

  Future<void> openStore(MapStore store) async {
    final repository = widget.repository;
    if (repository == null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => StoreDetailPage(
          store: store,
          repository: repository,
          distanceLabel: '',
          initialQuery: store.productsMatching(query).isEmpty ? '' : query,
        ),
      ),
    );
  }

  void clearSearch() {
    search.clear();
    setState(() => query = '');
  }

  String storeSubtitle(MapStore store) {
    final hits = store.productsMatching(query);
    return [
      store.category,
      if (hits.isEmpty)
        '${store.products.length} бараа'
      else
        'Таарсан: ${hits.take(2).map((p) => '${p.name} ${tugrik(p.price)}').join(', ')}',
      if (store.address.isNotEmpty) store.address,
    ].join(' · ');
  }

  Widget storeResults(List<MapStore> found) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Дэлгүүр (${found.length})',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      for (final store in found.take(6))
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            key: ValueKey('feed-store-${store.id}'),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              onTap: () => openStore(store),
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade50,
                child: Icon(
                  store.categoryIcon.isEmpty
                      ? categoryIcon(store.category)
                      : iconForKey(store.categoryIcon),
                  color: Colors.indigo,
                ),
              ),
              title: Text(
                store.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                storeSubtitle(store),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      if (found.length > 6)
        TextButton.icon(
          onPressed: widget.onMap,
          icon: const Icon(Icons.map_outlined),
          label: Text('Бүх ${found.length} дэлгүүрийг газрын зурагт харах'),
        ),
      const SizedBox(height: 16),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final words = searchWords(query);
    final categories = widget.workspace.filterCategories;
    if (!categories.contains(category)) category = 'Бүгд';
    final visible = widget.workspace.listings.where((ad) {
      final text =
          '${ad.title} ${ad.category} ${ad.address} ${ad.description} ${ad.owner}'
              .toLowerCase();
      return (category == 'Бүгд' || ad.category == category) &&
          words.every(text.contains);
    }).toList();
    final searching = words.isNotEmpty || category != 'Бүгд';
    final foundStores = searching
        ? filterStores(stores, query: query, category: category)
        : const <MapStore>[];
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
          key: const ValueKey('feed-search'),
          controller: search,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => query = value.trim()),
          decoration: InputDecoration(
            labelText: 'Зар, дэлгүүр хайх',
            hintText: 'Бараа, дэлгүүрийн нэр, байршил…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Хайлт цэвэрлэх',
                    onPressed: clearSearch,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in categories)
              ChoiceChip(
                avatar: item == 'Бүгд'
                    ? null
                    : Icon(categoryIcon(item), size: 18),
                label: Text(item),
                selected: category == item,
                onSelected: (_) => setState(() => category = item),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (searching && storesLoading) const LinearProgressIndicator(),
        if (searching && storesError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    storesError!,
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
                ),
                TextButton(
                  onPressed: loadStores,
                  child: const Text('Дахин оролдох'),
                ),
              ],
            ),
          ),
        if (foundStores.isNotEmpty) storeResults(foundStores),
        PageHeading(
          searching ? 'Зар (${visible.length})' : 'Шинэ зарууд',
          searching
              ? (query.isEmpty
                    ? '«$category» ангиллын зарууд'
                    : '«$query» хайлтын үр дүн')
              : '${visible.length} зар · Жишээ заруудыг туршилтаар оруулсан.',
        ),
        if (visible.isEmpty)
          EmptyState(
            icon: Icons.search_off,
            title: foundStores.isEmpty ? 'Юу ч олдсонгүй' : 'Зар олдсонгүй',
            subtitle: foundStores.isEmpty
                ? 'Хайлтын үг эсвэл ангиллаа солиод үзээрэй.'
                : 'Дээрх дэлгүүрүүдээс хайсан бараагаа үзээрэй.',
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

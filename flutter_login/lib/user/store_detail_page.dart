import 'package:flutter/material.dart';

import 'shared_widgets.dart';
import 'store_catalog.dart';

class StoreDetailPage extends StatefulWidget {
  const StoreDetailPage({
    super.key,
    required this.store,
    required this.repository,
    required this.distanceLabel,
  });
  final MapStore store;
  final StoreRepository repository;
  final String distanceLabel;

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  late MapStore store = widget.store;
  String query = '';
  bool onlyInStock = false, refreshing = false;
  String? error;

  Future<void> refresh() async {
    if (refreshing) return;
    setState(() {
      refreshing = true;
      error = null;
    });
    try {
      final fresh = await widget.repository.fetchStore(store.id);
      if (mounted) setState(() => store = fresh);
    } catch (_) {
      if (mounted)
        setState(
          () => error =
              'Дэлгүүрийн мэдээллийг шинэчилж чадсангүй. Дахин оролдоно уу.',
        );
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  void productDetails(StoreProduct product) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ProductImage(product: product),
            ),
            const SizedBox(height: 20),
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              tugrik(product.price),
              style: const TextStyle(
                fontSize: 24,
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(product.inStock ? 'Бэлэн байгаа' : 'Дууссан'),
            if (product.sizes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Размер: ${product.sizes}'),
              ),
            if (product.colors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Өнгө: ${product.colors}'),
              ),
            const SizedBox(height: 16),
            Text(
              product.description.isEmpty
                  ? 'Нэмэлт тайлбар оруулаагүй.'
                  : product.description,
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final products = store.products
        .where(
          (p) =>
              p.searchable.contains(query.toLowerCase().trim()) &&
              (!onlyInStock || p.inStock),
        )
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(store.name),
        actions: [
          IconButton(
            tooltip: 'Барааг шинэчлэх',
            onPressed: refreshing ? null : refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          child: Icon(Icons.storefront, size: 32),
                        ),
                        Text(
                          store.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (store.isDemo)
                          const Chip(label: Text('Жишээ дэлгүүр')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('${store.category} · ${widget.distanceLabel} зайд'),
                    const SizedBox(height: 12),
                    Text('Хаяг: ${store.address}'),
                    if (store.phone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SelectableText('Утас: ${store.phone}'),
                      ),
                    if (store.openingHours.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text('Ажиллах цаг: ${store.openingHours}'),
                      ),
                    if (store.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(store.description),
                      ),
                  ],
                ),
              ),
            ),
            if (refreshing) const LinearProgressIndicator(),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.deepOrange),
                ),
              ),
            const SizedBox(height: 24),
            PageHeading(
              'Дэлгүүрийн бараанууд',
              '${products.length} бараа · Шинэ барааг шинэчлэх товчоор харна уу.',
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Энэ дэлгүүрээс хайх',
                hintText: 'Хувцас, размер, өнгө…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Зөвхөн бэлэн бараа'),
                selected: onlyInStock,
                onSelected: (value) => setState(() => onlyInStock = value),
              ),
            ),
            const SizedBox(height: 20),
            if (products.isEmpty)
              EmptyState(
                icon: Icons.checkroom_outlined,
                title: store.products.isEmpty
                    ? 'Бараа хараахан нэмээгүй байна'
                    : 'Тохирох бараа олдсонгүй',
                subtitle: store.products.isEmpty
                    ? 'Дэлгүүр бараагаа нэмэхэд энд харагдана.'
                    : 'Хайлтын үг, шүүлтүүрээ өөрчилнө үү.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1000
                      ? 4
                      : constraints.maxWidth >= 680
                      ? 3
                      : constraints.maxWidth >= 440
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 16) / columns;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final product in products)
                        SizedBox(
                          width: width,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => productDetails(product),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 170,
                                    width: double.infinity,
                                    child: ProductImage(product: product),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          tugrik(product.price),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                        if (product.sizes.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              'Размер: ${product.sizes}',
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Text(
                                          product.inStock
                                              ? 'Бэлэн байгаа'
                                              : 'Дууссан',
                                          style: TextStyle(
                                            color: product.inStock
                                                ? Colors.teal
                                                : Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product});
  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Colors.indigo.shade50,
      child: Center(
        child: Icon(
          Icons.checkroom_outlined,
          size: 64,
          color: Colors.indigo.shade300,
        ),
      ),
    );
    final uri = Uri.tryParse(product.imageUrl);
    return uri != null && uri.scheme == 'https'
        ? Image.network(
            product.imageUrl,
            fit: BoxFit.cover,
            semanticLabel: product.name,
            errorBuilder: (context, error, stack) => placeholder,
          )
        : placeholder;
  }
}

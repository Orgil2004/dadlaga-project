import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'shared_widgets.dart';
import 'store_catalog.dart';
import 'store_detail_page.dart';
import 'workspace.dart';

class UserMapPage extends StatefulWidget {
  const UserMapPage({
    super.key,
    required this.workspace,
    required this.onOpen,
    this.focus,
    this.repository,
    this.locate,
  });
  final UserWorkspace workspace;
  final ValueChanged<Listing> onOpen;
  final Listing? focus;
  final StoreRepository? repository;
  final Future<LatLng> Function()? locate;

  @override
  State<UserMapPage> createState() => _UserMapPageState();
}

class _UserMapPageState extends State<UserMapPage> {
  final controller = MapController();
  late final StoreRepository repository;
  late LatLng center;
  List<MapStore> stores = [];
  String query = '', category = 'Бүгд';
  late String centerLabel;
  String? loadError, locationError;
  int radius = 5;
  int? selectedId;
  bool loading = true, locating = false, tileError = false, mapReady = false;
  LatLng? userLocation;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? StoreRepository();
    widget.workspace.addListener(onWorkspace);
    center = widget.focus == null
        ? const LatLng(47.9185, 106.9177)
        : LatLng(widget.focus!.latitude, widget.focus!.longitude);
    centerLabel = widget.focus == null
        ? 'Улаанбаатарын төвөөс'
        : 'Сонгосон зарын цэгээс';
    reload();
  }

  @override
  void didUpdateWidget(covariant UserMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focus != null && widget.focus != oldWidget.focus) {
      center = LatLng(widget.focus!.latitude, widget.focus!.longitude);
      centerLabel = 'Сонгосон зарын цэгээс';
      if (mapReady) controller.move(center, 14);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    if (widget.repository == null) repository.dispose();
    widget.workspace.removeListener(onWorkspace);
    super.dispose();
  }

  // Category order/icons arrive from the admin after the first build.
  void onWorkspace() {
    if (mounted) setState(() {});
  }

  Future<void> reload() async {
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final results = await repository.fetchStores();
      if (mounted)
        setState(() {
          stores = results;
          if (category != 'Бүгд' && !stores.any((s) => s.category == category))
            category = 'Бүгд';
        });
    } catch (_) {
      if (mounted)
        setState(
          () => loadError =
              'Дэлгүүрүүдийг ачаалж чадсангүй. Серверийн холболтыг шалгаад дахин оролдоно уу.',
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> locate() async {
    if (locating) return;
    setState(() {
      locating = true;
      locationError = null;
    });
    try {
      final point = await (widget.locate ?? locateMapUser)();
      if (!mounted) return;
      setState(() {
        center = point;
        userLocation = point;
        centerLabel = 'Миний байршлаас';
      });
      if (mapReady) controller.move(point, 14);
    } catch (error) {
      if (mounted)
        setState(
          () => locationError = error is MapLocationException
              ? error.message
              : 'Байршил тогтоож чадсангүй. Газрын зураг дээр хайх орчноо сонгоно уу.',
        );
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  void searchHere() {
    if (!mapReady) return;
    setState(() {
      center = controller.camera.center;
      centerLabel = 'Сонгосон цэгээс';
      locationError = null;
    });
  }

  Future<void> openStore(StoreMatch match) async {
    setState(() => selectedId = match.store.id);
    if (mapReady) controller.move(match.store.point, 15);
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => StoreDetailPage(
          store: match.store,
          repository: repository,
          distanceLabel: match.distanceLabel,
        ),
      ),
    );
    if (mounted) await reload();
  }

  void reportTileError() {
    if (tileError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !tileError) setState(() => tileError = true);
    });
  }

  Widget map(List<StoreMatch> matches, double height) => SizedBox(
    height: height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              minZoom: 3,
              maxZoom: 18,
              onMapReady: () => mapReady = true,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'mn.haanawe.app',
                errorTileCallback: (_, error, stack) => reportTileError(),
              ),
              if (radius > 0)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: center,
                      radius: radius * 1000.0,
                      useRadiusInMeter: true,
                      color: Colors.indigo.withValues(alpha: .06),
                      borderColor: Colors.indigo.withValues(alpha: .3),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 38,
                    height: 38,
                    child: Tooltip(
                      message: centerLabel,
                      child: const Icon(
                        Icons.adjust,
                        color: Colors.indigo,
                        size: 28,
                      ),
                    ),
                  ),
                  if (userLocation != null)
                    Marker(
                      point: userLocation!,
                      width: 40,
                      height: 40,
                      child: const Tooltip(
                        message: 'Миний байршил',
                        child: CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 16,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  for (final match in matches)
                    Marker(
                      point: match.store.point,
                      width: 52,
                      height: 52,
                      child: IconButton.filled(
                        tooltip: '${match.store.name} · ${match.distanceLabel}',
                        style: IconButton.styleFrom(
                          backgroundColor: selectedId == match.store.id
                              ? Colors.deepOrange
                              : Colors.indigo,
                        ),
                        onPressed: () => openStore(match),
                        icon: Icon(
                          match.store.categoryIcon.isEmpty
                              ? Icons.storefront
                              : iconForKey(match.store.categoryIcon),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (widget.focus != null)
                    Marker(
                      point: LatLng(
                        widget.focus!.latitude,
                        widget.focus!.longitude,
                      ),
                      width: 40,
                      height: 40,
                      child: IconButton(
                        tooltip: 'Зарын байршил: ${widget.focus!.title}',
                        onPressed: () => widget.onOpen(widget.focus!),
                        icon: const Icon(Icons.place, color: Colors.deepOrange),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: FilledButton.tonalIcon(
              onPressed: locating ? null : searchHere,
              icon: const Icon(Icons.travel_explore),
              label: const Text('Энэ орчмоос хайх'),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Ойртуулах',
                  onPressed: () {
                    if (mapReady)
                      controller.move(
                        controller.camera.center,
                        (controller.camera.zoom + 1).clamp(3, 18),
                      );
                  },
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                IconButton.filledTonal(
                  tooltip: 'Холдуулах',
                  onPressed: () {
                    if (mapReady)
                      controller.move(
                        controller.camera.center,
                        (controller.camera.zoom - 1).clamp(3, 18),
                      );
                  },
                  icon: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 6,
            bottom: 6,
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget results(List<StoreMatch> matches) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${matches.length} дэлгүүр олдлоо',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        '$centerLabel · Ойроос хол руу',
        style: const TextStyle(color: Colors.blueGrey),
      ),
      const SizedBox(height: 16),
      if (!loading && loadError == null && matches.isEmpty)
        const EmptyState(
          icon: Icons.storefront_outlined,
          title: 'Тохирох дэлгүүр олдсонгүй',
          subtitle:
              'Хайлт, зайны шүүлтүүрээ өөрчлөх эсвэл газрын зургаа хөдөлгөөд «Энэ орчмоос хайх» товчийг дараарай.',
        ),
      for (final match in matches)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            key: ValueKey('store-result-${match.store.id}'),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => openStore(match),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: const Icon(Icons.storefront, color: Colors.indigo),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.store.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${match.store.category} · ${match.distanceLabel}',
                            style: const TextStyle(color: Colors.indigo),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            match.store.address,
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${match.store.products.length} бараа${match.store.isDemo ? ' · Жишээ дэлгүүр' : ''}',
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final order = widget.workspace.categories;
    int rank(String name) {
      final index = order.indexOf(name);
      return index < 0 ? order.length : index;
    }

    final categories = [
      'Бүгд',
      ...({
        ...stores.where((s) => s.hasLocation).map((s) => s.category),
      }.toList()..sort((a, b) => rank(a).compareTo(rank(b)))),
    ];
    final matches = searchStores(
      stores,
      center: center,
      query: query,
      category: category,
      radiusKm: radius == 0 ? null : radius.toDouble(),
    );
    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            'Ойр байгаа дэлгүүрүүд',
            'Дэлгүүр, хувцсаа хайгаад газрын зураг дээрх дэлгүүрийг нээгээрэй.',
          ),
          TextField(
            key: const ValueKey('store-search'),
            decoration: const InputDecoration(
              labelText: 'Дэлгүүр, хувцас хайх',
              hintText: 'Дэлгүүрийн нэр, хүрэм, гутал, хаяг…',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: locating ? null : locate,
                icon: const Icon(Icons.my_location),
                label: Text(
                  locating ? 'Байршил тогтоож байна…' : 'Миний байршил',
                ),
              ),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: radius,
                  decoration: const InputDecoration(
                    labelText: 'Хайх зай',
                    isDense: true,
                  ),
                  items: [
                    for (final km in [1, 3, 5, 10, 0])
                      DropdownMenuItem(
                        value: km,
                        child: Text(km == 0 ? 'Бүх зай' : '$km км дотор'),
                      ),
                  ],
                  onChanged: (value) => setState(() => radius = value!),
                ),
              ),
              OutlinedButton.icon(
                onPressed: loading ? null : reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Дэлгүүрүүдийг шинэчлэх'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$centerLabel хайж байна.',
            style: const TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in categories)
                ChoiceChip(
                  label: Text(item),
                  selected: item == category,
                  onSelected: (_) => setState(() => category = item),
                ),
            ],
          ),
          if (locationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                locationError!,
                style: const TextStyle(color: Colors.deepOrange),
              ),
            ),
          if (tileError)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Газрын зургийн зураглал ачаалагдсангүй. Интернет холболтоо шалгана уу.',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
          if (loadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                loadError!,
                style: const TextStyle(color: Colors.deepOrange),
              ),
            ),
          const SizedBox(height: 20),
          if (loading) const LinearProgressIndicator(),
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 1000
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: map(matches, 520)),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: results(matches)),
                    ],
                  )
                : Column(
                    children: [
                      map(matches, 350),
                      const SizedBox(height: 24),
                      results(matches),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

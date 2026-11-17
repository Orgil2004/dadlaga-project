import 'package:flutter/material.dart';

import 'user/create_listing_page.dart';
import 'user/feed_page.dart';
import 'user/map_page.dart';
import 'user/messages_page.dart';
import 'user/profile_page.dart';
import 'user/shared_widgets.dart';
import 'user/store_catalog.dart';
import 'user/workspace.dart';
import 'user_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.workspace, this.repository});
  final UserWorkspace? workspace;
  final StoreRepository? repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const labels = [
    'Нүүр',
    'Газрын зураг',
    'Хадгалсан',
    'Зар нэмэх',
    'Мессеж',
    'Профайл',
  ];
  static const icons = [
    Icons.home_outlined,
    Icons.map_outlined,
    Icons.bookmark_outline,
    Icons.add_circle_outline,
    Icons.chat_bubble_outline,
    Icons.person_outline,
  ];
  late final UserWorkspace workspace;
  late final StoreRepository repository;
  int selected = 0;
  bool loading = true;
  Listing? mapFocus;
  String? chatFocus;
  final visited = <int>{0};

  @override
  void initState() {
    super.initState();
    workspace = widget.workspace ?? UserWorkspace(account: UserData.email);
    repository = widget.repository ?? StoreRepository();
    workspace.addListener(refresh);
    load();
    loadCategories();
  }

  Future<void> load() async {
    if (widget.workspace == null) await workspace.load();
    if (mounted) setState(() => loading = false);
  }

  /// Admin-managed categories; the built-in list stays if this fails.
  Future<void> loadCategories() async {
    try {
      final categories = await repository.fetchCategories();
      for (final item in categories) {
        categoryIconKeys[item.name] = item.icon;
      }
      if (mounted) {
        workspace.setCategories([for (final c in categories) c.name]);
      }
    } catch (_) {}
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    workspace.removeListener(refresh);
    if (widget.workspace == null) workspace.dispose();
    if (widget.repository == null) repository.dispose();
    super.dispose();
  }

  void navigate(int index) => setState(() {
    selected = index;
    visited.add(index);
  });
  void logout() =>
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

  void openListing(Listing ad) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => ListenableBuilder(
        listenable: workspace,
        builder: (context, _) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(categoryIcon(ad.category), size: 52, color: Colors.indigo),
                const SizedBox(height: 16),
                Text(
                  ad.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  ad.priceLabel,
                  style: const TextStyle(
                    fontSize: 25,
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text('${ad.category} · ${ad.owner}'),
                const SizedBox(height: 8),
                Text(ad.address),
                const SizedBox(height: 16),
                Text(ad.description),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => workspace.toggleSaved(ad),
                      icon: Icon(
                        workspace.savedIds.contains(ad.id)
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                      ),
                      label: Text(
                        workspace.savedIds.contains(ad.id)
                            ? 'Хадгалсан'
                            : 'Хадгалах',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        setState(() => mapFocus = ad);
                        navigate(1);
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Газрын зурагт харах'),
                    ),
                    if (!ad.isMine)
                      OutlinedButton.icon(
                        onPressed: () {
                          workspace.startChat(ad);
                          Navigator.pop(sheetContext);
                          setState(() => chatFocus = ad.id);
                          navigate(4);
                        },
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Мессеж бичих'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget page(int index) => switch (index) {
    0 => FeedPage(
      workspace: workspace,
      onOpen: openListing,
      onMap: () => navigate(1),
      repository: repository,
    ),
    1 => UserMapPage(
      workspace: workspace,
      focus: mapFocus,
      onOpen: openListing,
      repository: repository,
    ),
    2 => SavedPage(workspace: workspace, onOpen: openListing),
    3 => CreateListingPage(workspace: workspace, onCreated: () => navigate(0)),
    4 => MessagesPage(workspace: workspace, listingId: chatFocus),
    _ => ProfilePage(
      workspace: workspace,
      onLogout: logout,
      onOpen: openListing,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDE3EF)),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE5E9F2)),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'ХаанаВэ?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF243A80),
          actions: [
            if (wide)
              Center(child: Text('Хэрэглэгчийн хэсэг · ${workspace.name}')),
            IconButton(
              tooltip: 'Гарах',
              onPressed: logout,
              icon: const Icon(Icons.logout),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Row(
                  children: [
                    if (wide)
                      NavigationRail(
                        extended: true,
                        minExtendedWidth: 210,
                        backgroundColor: Colors.white,
                        selectedIndex: selected,
                        onDestinationSelected: navigate,
                        destinations: [
                          for (var i = 0; i < labels.length; i++)
                            NavigationRailDestination(
                              icon: Icon(icons[i]),
                              label: Text(labels[i]),
                            ),
                        ],
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          if (workspace.storageError != null)
                            MaterialBanner(
                              content: Text(workspace.storageError!),
                              actions: [
                                TextButton(
                                  onPressed: () => setState(
                                    () => workspace.storageError = null,
                                  ),
                                  child: const Text('Хаах'),
                                ),
                              ],
                            ),
                          Expanded(
                            child: IndexedStack(
                              index: selected,
                              children: [
                                for (var i = 0; i < labels.length; i++)
                                  visited.contains(i)
                                      ? KeyedSubtree(
                                          key: ValueKey(i),
                                          child: page(i),
                                        )
                                      : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: navigate,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: [
                  for (var i = 0; i < labels.length; i++)
                    NavigationDestination(
                      icon: Icon(icons[i]),
                      label: labels[i],
                      tooltip: labels[i],
                    ),
                ],
              ),
      ),
    );
  }
}

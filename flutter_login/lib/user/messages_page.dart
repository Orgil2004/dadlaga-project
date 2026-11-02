import 'package:flutter/material.dart';

import 'shared_widgets.dart';
import 'workspace.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, required this.workspace, this.listingId});
  final UserWorkspace workspace;
  final String? listingId;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final composer = TextEditingController();
  String? selectedId;

  @override
  void initState() {
    super.initState();
    selectedId = widget.listingId;
  }

  @override
  void didUpdateWidget(covariant MessagesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listingId != oldWidget.listingId) {
      selectedId = widget.listingId;
      composer.clear();
    }
  }

  @override
  void dispose() {
    composer.dispose();
    super.dispose();
  }

  void send() {
    if (selectedId == null || composer.text.trim().isEmpty) return;
    widget.workspace.addMessage(selectedId!, composer.text);
    composer.clear();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = widget.workspace.listings
        .where((ad) => widget.workspace.messages.containsKey(ad.id))
        .toList();
    final selected = conversations
        .where((ad) => ad.id == selectedId)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeading(
            'Мессеж',
            'Туршилтын чат · Мессеж зөвхөн энэ төхөөрөмжид хадгалагдана, хүлээн авагчид илгээгдэхгүй.',
          ),
          if (conversations.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'Харилцан яриа алга',
                subtitle:
                    'Зарын дэлгэрэнгүйгээс «Мессеж бичих» товчийг дараарай.',
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(selected?.id),
                    initialValue: selected?.id,
                    decoration: const InputDecoration(
                      labelText: 'Харилцан яриа',
                      prefixIcon: Icon(Icons.forum_outlined),
                    ),
                    isExpanded: true,
                    items: [
                      for (final ad in conversations)
                        DropdownMenuItem(
                          value: ad.id,
                          child: Text(
                            '${ad.owner} · ${ad.title}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      selectedId = value;
                      composer.clear();
                    }),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: selected == null
                        ? const EmptyState(
                            icon: Icons.forum_outlined,
                            title: 'Харилцан яриагаа сонгоно уу',
                            subtitle: 'Дээрх жагсаалтаас сонгоорой.',
                          )
                        : widget.workspace.messages[selected.id]!.isEmpty
                        ? const EmptyState(
                            icon: Icons.edit_note,
                            title: 'Мессежээ бичээрэй',
                            subtitle: 'Бичсэн зүйлсээ туршилтын чатаар хадгалж болно.',
                          )
                        : ListView.builder(
                            reverse: true,
                            itemCount:
                                widget.workspace.messages[selected.id]!.length,
                            itemBuilder: (context, index) {
                              final messages =
                                  widget.workspace.messages[selected.id]!;
                              return Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 520,
                                  ),
                                  margin: const EdgeInsets.only(
                                    bottom: 12,
                                    left: 24,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        messages[messages.length - 1 - index],
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Зөвхөн төхөөрөмжид',
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (selected != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: composer,
                            minLines: 1,
                            maxLines: 3,
                            maxLength: 2000,
                            decoration: const InputDecoration(
                              hintText: 'Мессеж бичих…',
                              counterText: '',
                            ),
                            onSubmitted: (_) => send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Мессежийг төхөөрөмжид хадгалах',
                          onPressed: send,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

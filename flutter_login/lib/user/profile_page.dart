import 'package:flutter/material.dart';

import 'shared_widgets.dart';
import 'workspace.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.workspace,
    required this.onLogout,
    required this.onOpen,
  });
  final UserWorkspace workspace;
  final VoidCallback onLogout;
  final ValueChanged<Listing> onOpen;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.workspace.name);
  late final phone = TextEditingController(text: widget.workspace.phone);
  late final bio = TextEditingController(text: widget.workspace.bio);
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || saving) return;
    setState(() => saving = true);
    await widget.workspace.updateProfile(name.text, phone.text, bio.text);
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.workspace.storageError ?? 'Профайл хадгалагдлаа.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const PageHeading(
        'Миний профайл',
        'Хувийн мэдээлэл болон өөрийн заруудаа удирдаарай.',
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      widget.workspace.name.isEmpty
                          ? '?'
                          : widget.workspace.name.characters.first
                                .toUpperCase(),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workspace.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.workspace.account,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  Text('Миний зар: ${widget.workspace.myListings.length}'),
                  Text('Хадгалсан: ${widget.workspace.savedListings.length}'),
                ],
              ),
              const Divider(height: 40),
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: name,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Нэр',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Нэрээ оруулна уу'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Утасны дугаар (заавал биш)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) =>
                          value == null ||
                              value.trim().isEmpty ||
                              RegExp(r'^\+?[\d\s-]{8,16}$')
                                  .hasMatch(value.trim())
                          ? null
                          : 'Зөв утасны дугаар оруулна уу',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: bio,
                      maxLines: 3,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        labelText: 'Миний тухай',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: saving ? null : save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Профайл хадгалах'),
                        ),
                        OutlinedButton.icon(
                          onPressed: widget.onLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Гарах'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      const PageHeading('Миний зарууд', 'Энэ төхөөрөмжөөс нэмсэн зарууд.'),
      if (widget.workspace.myListings.isEmpty)
        const EmptyState(
          icon: Icons.post_add,
          title: 'Та зар нэмээгүй байна',
          subtitle: '«Зар нэмэх» хэсгээр анхны зараа оруулаарай.',
        )
      else
        ListingGrid(
          listings: widget.workspace.myListings,
          workspace: widget.workspace,
          onOpen: widget.onOpen,
        ),
    ],
  );
}

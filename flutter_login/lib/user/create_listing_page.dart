import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shared_widgets.dart';
import 'workspace.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({
    super.key,
    required this.workspace,
    required this.onCreated,
  });
  final UserWorkspace workspace;
  final VoidCallback onCreated;

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController(), price = TextEditingController();
  final address = TextEditingController(),
      description = TextEditingController();
  final latitude = TextEditingController(text: '47.9185');
  final longitude = TextEditingController(text: '106.9177');
  String category = listingCategories[1];
  bool saving = false;

  @override
  void dispose() {
    for (final field in [
      title,
      price,
      address,
      description,
      latitude,
      longitude,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  String? requiredValue(String? value) =>
      value == null || value.trim().isEmpty ? 'Энэ талбарыг бөглөнө үү' : null;

  Future<void> submit() async {
    if (saving || !formKey.currentState!.validate()) return;
    setState(() => saving = true);
    await widget.workspace.addListing(
      Listing(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        title: title.text.trim(),
        category: category,
        price: int.parse(price.text),
        address: address.text.trim(),
        description: description.text.trim(),
        owner: widget.workspace.name,
        latitude: double.parse(latitude.text.trim()),
        longitude: double.parse(longitude.text.trim()),
        isMine: true,
      ),
    );
    if (!mounted) return;
    formKey.currentState!.reset();
    for (final field in [title, price, address, description]) {
      field.clear();
    }
    latitude.text = '47.9185';
    longitude.text = '106.9177';
    setState(() {
      saving = false;
      category = listingCategories[1];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.workspace.storageError ?? 'Зар энэ төхөөрөмжид нэмэгдлээ.',
        ),
      ),
    );
    widget.onCreated();
  }

  Widget field(
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: lines,
      maxLength: lines > 1 ? 2000 : 150,
      validator: requiredValue,
    ),
  );

  Widget coordinate(
    TextEditingController controller,
    String label,
    double min,
    double max,
  ) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: const TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    ),
    validator: (value) {
      final number = double.tryParse(value?.trim() ?? '');
      return number == null || !number.isFinite || number < min || number > max
          ? '$min – $max хооронд оруулна уу'
          : null;
    },
  );

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const PageHeading(
        'Зар нэмэх',
        'Бараа, үйлчилгээнийхээ мэдээллийг оруулаарай.',
      ),
      Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Нэмсэн зар тухайн төхөөрөмжид хадгалагдана. Бусад хэрэглэгчид хараахан харагдахгүй.',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 24),
                    field(title, 'Зарын гарчиг'),
                    DropdownButtonFormField<String>(
                      key: ValueKey(category),
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Ангилал'),
                      items: listingCategories
                          .skip(1)
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => category = value!),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Үнэ',
                        suffixText: '₮',
                      ),
                      validator: (value) {
                        final amount = int.tryParse(value ?? '');
                        return amount == null ||
                                amount <= 0 ||
                                amount > 999999999999
                            ? 'Зөв үнэ оруулна уу (1–999999999999)'
                            : null;
                      },
                    ),
                    const SizedBox(height: 20),
                    field(address, 'Байршил / хаяг'),
                    field(description, 'Дэлгэрэнгүй тайлбар', lines: 4),
                    const Text(
                      'Газрын зургийн цэг',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Анхны цэг Улаанбаатарын төвд байна. Зарынхаа бодит координатаар солино уу.',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 230,
                          child: coordinate(latitude, 'Өргөрөг', -90, 90),
                        ),
                        SizedBox(
                          width: 230,
                          child: coordinate(longitude, 'Уртраг', -180, 180),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: saving ? null : submit,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(saving ? 'Хадгалж байна…' : 'Зар нэмэх'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/database/database.dart';

const _categoryColors = <int>[
  0xFFE53935,
  0xFFE91E63,
  0xFF9C27B0,
  0xFF673AB7,
  0xFF3F51B5,
  0xFF2196F3,
  0xFF00BCD4,
  0xFF009688,
  0xFF4CAF50,
  0xFF8BC34A,
  0xFFFF9800,
  0xFF795548,
];

class CategoriesScreen extends StatefulWidget {
  final AppDatabase db;
  const CategoriesScreen({super.key, required this.db});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  TransactionType _selectedType = TransactionType.expense;

  Future<void> _showEditDialog({Category? existing}) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    int selectedColor = existing?.colorValue ?? _categoryColors.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(existing == null ? 'Nowa kategoria' : 'Zmień nazwę'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nazwa kategorii'),
              ),
              const SizedBox(height: 16),
              const Text('Kolor', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categoryColors.map((c) {
                  final selected = c == selectedColor;
                  return InkWell(
                    onTap: () => setStateDialog(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;

    if (existing == null) {
      await widget.db.transactionsDao.insertCategory(
        CategoriesCompanion.insert(
          name: name,
          type: _selectedType,
          colorValue: Value(selectedColor),
        ),
      );
    } else {
      await widget.db.transactionsDao.updateCategory(
        existing.copyWith(name: name, colorValue: selectedColor),
      );
    }
  }

  Future<void> _confirmDelete(Category category) async {
    final siblings =
        await widget.db.transactionsDao.getCategoriesByType(category.type);
    if (!mounted) return;
    if (siblings.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Musi zostać przynajmniej jedna kategoria tego typu')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usunąć kategorię?'),
        content: Text(
            'Kategoria "${category.name}" zostanie usunięta. Istniejące transakcje zachowają tę nazwę w historii.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Usuń', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.db.transactionsDao.deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategorie')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Wydatki'),
                    icon: Icon(Icons.arrow_downward, size: 16)),
                ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Przychody'),
                    icon: Icon(Icons.arrow_upward, size: 16)),
              ],
              selected: {_selectedType},
              onSelectionChanged: (s) =>
                  setState(() => _selectedType = s.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Category>>(
              stream: widget.db.transactionsDao.watchAllCategories(),
              builder: (context, snapshot) {
                final categories = (snapshot.data ?? [])
                    .where((c) => c.type == _selectedType)
                    .toList();
                if (categories.isEmpty) {
                  return const Center(
                    child: Text('Brak kategorii. Dodaj pierwszą przyciskiem +',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final category = categories[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(category.colorValue),
                        radius: 14,
                      ),
                      title: Text(category.name,
                          style: const TextStyle(fontSize: 16)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Zmień nazwę',
                            onPressed: () =>
                                _showEditDialog(existing: category),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            tooltip: 'Usuń',
                            onPressed: () => _confirmDelete(category),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Dodaj kategorię'),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/cuisine_model.dart';
import '../../../data/repositories/cuisine_repository.dart';
import '../../../data/services/sync_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Admin Panel',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Sync'),
            Tab(text: 'Add Cuisine'),
            Tab(text: 'Add Dish'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _SyncTab(),
          _AddCuisineTab(),
          _AddDishTab(),
        ],
      ),
    );
  }
}

// ── Sync Status Tab ───────────────────────────────────────────────────────────

class _SyncTab extends StatefulWidget {
  const _SyncTab();

  @override
  State<_SyncTab> createState() => _SyncTabState();
}

class _SyncTabState extends State<_SyncTab> {
  SyncResult? _result;
  bool _syncing = false;
  int _localCuisines = 0;
  int _localDishes = 0;

  @override
  void initState() {
    super.initState();
    _result = SyncService.lastResult;
    _loadLocalCounts();
  }

  Future<void> _loadLocalCounts() async {
    final db = await AppDatabase.database;
    final c = (await db.rawQuery('SELECT COUNT(*) as n FROM cuisines')).first['n'] as int;
    final d = (await db.rawQuery('SELECT COUNT(*) as n FROM dishes')).first['n'] as int;
    if (mounted) setState(() { _localCuisines = c; _localDishes = d; });
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final result = await SyncService.syncWithResult();
    await _loadLocalCounts();
    if (mounted) setState(() { _result = result; _syncing = false; });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Local DB counts
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Local Database',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                _Row('Cuisines in SQLite', '$_localCuisines'),
                _Row('Dishes in SQLite', '$_localDishes'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Last sync result
          if (_result != null)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _result!.success
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: _result!.success ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _result!.success ? 'Last Sync: Success' : 'Last Sync: Failed',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _result!.success ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  if (_result!.success) ...[
                    const SizedBox(height: 12),
                    _Row('Cuisines from Supabase', '${_result!.cuisinesFetched}'),
                    _Row('Dishes from Supabase', '${_result!.dishesFetched}'),
                    _Row('Details from Supabase', '${_result!.detailsFetched}'),
                    if (_result!.cuisinesFetched == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Text(
                            '⚠️ Supabase returned 0 cuisines.\n'
                            'Check:\n'
                            '• RLS policies (public read must be enabled)\n'
                            '• Supabase URL & anon key in supabase_config.dart\n'
                            '• That cuisines exist in the Supabase table',
                            style: TextStyle(fontSize: 12, height: 1.5),
                          ),
                        ),
                      ),
                  ],
                  if (_result!.error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: SelectableText(
                        _result!.error!,
                        style: const TextStyle(
                            fontSize: 12, fontFamily: 'monospace', height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          if (_result == null)
            _Card(
              child: Text('No sync result yet.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _syncing ? null : _syncNow,
              icon: _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(_syncing ? 'Syncing…' : 'Sync Now'),
            ),
          ),

          const SizedBox(height: 16),

          // RLS hint
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Supabase RLS Setup',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                SizedBox(height: 8),
                SelectableText(
                  'Run this SQL in Supabase → SQL Editor:\n\n'
                  'alter table cuisines enable row level security;\n'
                  'alter table dishes enable row level security;\n'
                  'alter table dish_details enable row level security;\n\n'
                  'create policy "public read cuisines"\n'
                  '  on cuisines for select using (true);\n\n'
                  'create policy "public read dishes"\n'
                  '  on dishes for select using (true);\n\n'
                  'create policy "public read dish_details"\n'
                  '  on dish_details for select using (true);',
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ── Add Cuisine Tab ───────────────────────────────────────────────────────────

class _AddCuisineTab extends StatefulWidget {
  const _AddCuisineTab();

  @override
  State<_AddCuisineTab> createState() => _AddCuisineTabState();
}

class _AddCuisineTabState extends State<_AddCuisineTab> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _flag = TextEditingController();
  final _description = TextEditingController();
  final _thumbnailUrl = TextEditingController();
  final _gradientStart = TextEditingController(text: '4A90E2');
  final _gradientEnd = TextEditingController(text: '2F74CC');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _flag, _description, _thumbnailUrl, _gradientStart, _gradientEnd]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final db = await AppDatabase.database;
      await db.insert('cuisines', {
        'name': _name.text.trim(),
        'flag': _flag.text.trim(),
        'description': _description.text.trim(),
        'thumbnail_url': _thumbnailUrl.text.trim(),
        'gradient_start': _gradientStart.text.trim().replaceAll('#', ''),
        'gradient_end': _gradientEnd.text.trim().replaceAll('#', ''),
      });
      _formKey.currentState!.reset();
      _gradientStart.text = '4A90E2';
      _gradientEnd.text = '2F74CC';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cuisine added!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(controller: _name, label: 'Cuisine Name', hint: 'e.g. Mexican', required: true),
            _Field(controller: _flag, label: 'Flag Emoji', hint: 'e.g. 🇲🇽', required: true),
            _Field(controller: _description, label: 'Description', hint: 'Short description...', maxLines: 3, required: true),
            _Field(controller: _thumbnailUrl, label: 'Thumbnail URL', hint: 'https://images.unsplash.com/...', required: true),
            Row(
              children: [
                Expanded(
                  child: _Field(controller: _gradientStart, label: 'Gradient Start (hex)', hint: '4A90E2'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(controller: _gradientEnd, label: 'Gradient End (hex)', hint: '2F74CC'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Cuisine'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Dish Tab ──────────────────────────────────────────────────────────────

class _AddDishTab extends StatefulWidget {
  const _AddDishTab();

  @override
  State<_AddDishTab> createState() => _AddDishTabState();
}

class _AddDishTabState extends State<_AddDishTab> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _thumbnailUrl = TextEditingController();
  final _category = TextEditingController();
  final _shortDesc = TextEditingController();
  final _fullDesc = TextEditingController();
  final _preparation = TextEditingController();
  final _videoUrl = TextEditingController();

  final List<Map<String, TextEditingController>> _ingredients = [];
  List<Cuisine> _cuisines = [];
  int? _selectedCuisineId;
  bool _saving = false;
  bool _loadingCuisines = true;

  @override
  void initState() {
    super.initState();
    _loadCuisines();
    _addIngredientRow();
  }

  Future<void> _loadCuisines() async {
    try {
      final list = await CuisineRepository().getCuisines();
      if (mounted) setState(() { _cuisines = list; _loadingCuisines = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCuisines = false);
    }
  }

  void _addIngredientRow() {
    setState(() {
      _ingredients.add({
        'name': TextEditingController(),
        'measure': TextEditingController(),
      });
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index]['name']!.dispose();
      _ingredients[index]['measure']!.dispose();
      _ingredients.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _thumbnailUrl, _category, _shortDesc, _fullDesc, _preparation, _videoUrl]) {
      c.dispose();
    }
    for (final row in _ingredients) {
      row['name']!.dispose();
      row['measure']!.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCuisineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a cuisine'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final db = await AppDatabase.database;

      final dishId = await db.insert('dishes', {
        'cuisine_id': _selectedCuisineId,
        'name': _name.text.trim(),
        'thumbnail_url': _thumbnailUrl.text.trim(),
        'category': _category.text.trim(),
        'short_description': _shortDesc.text.trim(),
      });

      final ingredientsJson = _ingredients
          .where((r) => r['name']!.text.trim().isNotEmpty)
          .map((r) => {
                'name': r['name']!.text.trim(),
                'measure': r['measure']!.text.trim(),
              })
          .toList();

      await db.insert('dish_details', {
        'dish_id': dishId,
        'full_description': _fullDesc.text.trim(),
        'ingredients': jsonEncode(ingredientsJson),
        'preparation': _preparation.text.trim(),
        'video_url': _videoUrl.text.trim().isEmpty ? null : _videoUrl.text.trim(),
      });

      _formKey.currentState!.reset();
      for (final row in _ingredients) {
        row['name']!.dispose();
        row['measure']!.dispose();
      }
      setState(() {
        _selectedCuisineId = null;
        _ingredients.clear();
        _addIngredientRow();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Dish added!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Cuisine'),
            _loadingCuisines
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : DropdownButtonFormField<int>(
                    value: _selectedCuisineId,
                    decoration: _inputDecoration('Select cuisine'),
                    items: _cuisines
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.flag} ${c.name}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCuisineId = v),
                  ),

            _Field(controller: _name, label: 'Dish Name', hint: 'e.g. Tacos al Pastor', required: true),
            _Field(controller: _thumbnailUrl, label: 'Thumbnail URL', hint: 'https://images.unsplash.com/...', required: true),
            _Field(controller: _category, label: 'Category', hint: 'e.g. Street Food', required: true),
            _Field(controller: _shortDesc, label: 'Short Description', hint: 'One-liner summary...', required: true),
            _Field(controller: _fullDesc, label: 'Full Description', hint: 'Detailed write-up...', maxLines: 4, required: true),

            _SectionLabel('Ingredients'),
            ..._ingredients.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: row['name'],
                        decoration: _inputDecoration('Ingredient'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: row['measure'],
                        decoration: _inputDecoration('Amount'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                      onPressed: _ingredients.length > 1 ? () => _removeIngredient(i) : null,
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addIngredientRow,
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              label: const Text('Add Ingredient', style: TextStyle(color: AppColors.primary)),
            ),

            _Field(
              controller: _preparation,
              label: 'Preparation Steps (one step per line)',
              hint: 'Step 1...\nStep 2...\nStep 3...',
              maxLines: 7,
              required: true,
            ),
            _Field(
              controller: _videoUrl,
              label: 'YouTube URL (optional)',
              hint: 'https://www.youtube.com/watch?v=...',
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Dish'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final bool required;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: _inputDecoration(hint),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

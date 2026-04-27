import 'dart:convert';
import 'package:smart_meds_v2/core/services/local_storage_service.dart';
import 'package:smart_meds_v2/features/inventory/data/models/inventory_item_model.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_meds_v2/features/inventory/domain/repositories/inventory_repository.dart';

class FakeInventoryRepository implements InventoryRepository {
  final LocalStorageService _storage;
  static const String _storageKey = 'inventory_items';

  final List<InventoryItem> _items = [];
  bool _isInitialized = false;

  FakeInventoryRepository(this._storage);

  Future<void> _init() async {
    if (_isInitialized) return;

    final storedData = _storage.readString(_storageKey);
    if (storedData != null) {
      final List<dynamic> decoded = jsonDecode(storedData);
      _items.clear();
      _items.addAll(
        decoded.map((m) => InventoryItemModel.fromMap(m as Map<String, dynamic>).toDomain()),
      );
    } else {
      // Seed initial data if nothing is stored
      _items.addAll([
        InventoryItem(
          id: 'inv_1',
          catalogMedicationId: 'cat_1',
          name: 'Paracetamol 500mg',
          expirationDate: DateTime.now().add(const Duration(days: 365)),
          quantity: 2,
        ),
        InventoryItem(
          id: 'inv_2',
          catalogMedicationId: 'cat_2',
          name: 'Ibuprofeno 400mg',
          expirationDate: DateTime.now().add(const Duration(days: 180)),
          quantity: 1,
        ),
      ]);
      await _save();
    }
    _isInitialized = true;
  }

  Future<void> _save() async {
    final String encoded = jsonEncode(
      _items.map((i) => InventoryItemModel.fromDomain(i).toMap()).toList(),
    );
    await _storage.writeString(_storageKey, encoded);
  }

  String _normalizeName(String name) {
    return name.trim().toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u');
  }

  void _validateItem(InventoryItem item) {
    if (item.name.trim().isEmpty) {
      throw Exception('El nombre del medicamento no puede estar vacío');
    }
    if (item.quantity <= 0) {
      throw Exception('La cantidad debe ser mayor a 0');
    }
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    if (item.expirationDate.isBefore(todayMidnight)) {
      throw Exception('La fecha de vencimiento no puede ser anterior a hoy');
    }
  }

  @override
  Future<List<InventoryItem>> getUserInventory() async {
    await _init();
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_items);
  }

  @override
  Future<void> addInventoryItem(InventoryItem item) async {
    await _init();
    await Future.delayed(const Duration(milliseconds: 100));
    
    _validateItem(item);

    // Rule: Combine duplicates
    int existingIndex = -1;
    if (item.catalogMedicationId != 'desconocido') {
      existingIndex = _items.indexWhere(
        (i) => i.catalogMedicationId == item.catalogMedicationId &&
               i.expirationDate.year == item.expirationDate.year &&
               i.expirationDate.month == item.expirationDate.month &&
               i.expirationDate.day == item.expirationDate.day
      );
    } else {
      final normalizedNew = _normalizeName(item.name);
      existingIndex = _items.indexWhere(
        (i) => i.catalogMedicationId == 'desconocido' &&
               _normalizeName(i.name) == normalizedNew &&
               i.expirationDate.year == item.expirationDate.year &&
               i.expirationDate.month == item.expirationDate.month &&
               i.expirationDate.day == item.expirationDate.day
      );
    }

    if (existingIndex != -1) {
      final existing = _items[existingIndex];
      _items[existingIndex] = InventoryItem(
        id: existing.id,
        catalogMedicationId: existing.catalogMedicationId,
        name: existing.name,
        expirationDate: existing.expirationDate,
        quantity: existing.quantity + item.quantity,
      );
    } else {
      _items.add(item);
    }

    await _save();
  }

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {
    await _init();
    await Future.delayed(const Duration(milliseconds: 100));
    
    _validateItem(item);

    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      await _save();
    }
  }

  @override
  Future<void> removeInventoryItem(String id) async {
    await _init();
    await Future.delayed(const Duration(milliseconds: 100));
    _items.removeWhere((item) => item.id == id);
    await _save();
  }
}

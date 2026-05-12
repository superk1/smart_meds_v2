import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_meds_v2/features/inventory/data/models/inventory_item_model.dart';
import 'package:smart_meds_v2/features/inventory/domain/entities/inventory_item.dart';

class InventoryExportDataSource {
  Future<String> exportToJSON(List<InventoryItem> items) async {
    final List<Map<String, dynamic>> mappedItems = 
        items.map((i) => InventoryItemModel.fromDomain(i).toMap()).toList();
    
    final Map<String, dynamic> exportData = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'items': mappedItems,
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  Future<void> shareExportFile(String jsonContent) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/smart_meds_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonContent);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Respaldo de mi Botiquín Smart Meds',
    );
  }

  Future<List<InventoryItem>?> pickAndParseJSON() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final Map<String, dynamic> decoded = jsonDecode(content);

    if (!decoded.containsKey('items') || decoded['items'] is! List) {
      throw const FormatException('El archivo no tiene un formato válido de Smart Meds (falta lista de items).');
    }

    final List<dynamic> itemsList = decoded['items'];
    return itemsList
        .map((m) => InventoryItemModel.fromMap(m as Map<String, dynamic>).toDomain())
        .toList();
  }
}

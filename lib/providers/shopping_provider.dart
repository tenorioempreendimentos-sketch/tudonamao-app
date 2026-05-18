import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_item.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class ShoppingProvider extends ChangeNotifier {
  late Box<ShoppingItem> _box;
  final _uuid = const Uuid();
  ApiService? _api;
  SyncService? _sync;

  void setServices(ApiService api, SyncService sync) {
    _api  = api;
    _sync = sync;
  }

  static const List<String> categories = [
    'Supermercado','Hortifruti','Açougue','Peixaria','Padaria','Laticínios',
    'Bebidas','Congelados','Mercearia','Material de Construção','Ferramentas',
    'Elétrica','Hidráulica','Tintas','Acabamentos','Madeiras','Farmácia',
    'Higiene Pessoal','Limpeza','Cuidados Infantis','Suplementos','Eletrônicos',
    'Informática','Celulares','Acessórios Tech','Vestuário','Calçados',
    'Cama/Mesa/Banho','Móveis','Eletrodomésticos','Decoração','Utensílios Domésticos',
    'Papelaria','Material Escolar','Escritório','Brinquedos','Fraldas & Bebê',
    'Roupas Infantis','Pet Shop','Automotivo','Jardinagem','Esporte & Lazer',
    'Presentes','Outros',
  ];

  static const Map<String, String> categoryIcons = {
    'Supermercado':'🛒','Hortifruti':'🥦','Açougue':'🥩','Peixaria':'🐟',
    'Padaria':'🍞','Laticínios':'🧀','Bebidas':'🧃','Congelados':'🧊',
    'Mercearia':'🏪','Material de Construção':'🧱','Ferramentas':'🔧',
    'Elétrica':'⚡','Hidráulica':'🚿','Tintas':'🎨','Acabamentos':'🪟',
    'Madeiras':'🪵','Farmácia':'💊','Higiene Pessoal':'🧴','Limpeza':'🧹',
    'Cuidados Infantis':'👶','Suplementos':'💪','Eletrônicos':'📱',
    'Informática':'💻','Celulares':'📲','Acessórios Tech':'🎧','Vestuário':'👕',
    'Calçados':'👟','Cama/Mesa/Banho':'🛏️','Móveis':'🛋️','Eletrodomésticos':'🫙',
    'Decoração':'🖼️','Utensílios Domésticos':'🍳','Papelaria':'📝',
    'Material Escolar':'📚','Escritório':'🗂️','Brinquedos':'🧸',
    'Fraldas & Bebê':'🍼','Roupas Infantis':'👗','Pet Shop':'🐾',
    'Automotivo':'🚗','Jardinagem':'🌱','Esporte & Lazer':'⚽','Presentes':'🎁',
    'Outros':'📦',
  };

  static const Map<String, List<String>> categoryGroups = {
    'Alimentação':['Supermercado','Hortifruti','Açougue','Peixaria','Padaria','Laticínios','Bebidas','Congelados','Mercearia'],
    'Construção & Reforma':['Material de Construção','Ferramentas','Elétrica','Hidráulica','Tintas','Acabamentos','Madeiras'],
    'Saúde & Higiene':['Farmácia','Higiene Pessoal','Limpeza','Cuidados Infantis','Suplementos'],
    'Tecnologia':['Eletrônicos','Informática','Celulares','Acessórios Tech'],
    'Moda & Casa':['Vestuário','Calçados','Cama/Mesa/Banho','Móveis','Eletrodomésticos','Decoração','Utensílios Domésticos'],
    'Escola & Escritório':['Papelaria','Material Escolar','Escritório'],
    'Bebê & Criança':['Brinquedos','Fraldas & Bebê','Roupas Infantis'],
    'Outros':['Pet Shop','Automotivo','Jardinagem','Esporte & Lazer','Presentes','Outros'],
  };

  static const Map<String, String> groupIcons = {
    'Alimentação':'🍽️','Construção & Reforma':'🏗️','Saúde & Higiene':'❤️',
    'Tecnologia':'💡','Moda & Casa':'🏠','Escola & Escritório':'🎓',
    'Bebê & Criança':'👶','Outros':'📦',
  };

  static const Map<String, int> groupColors = {
    'Alimentação':0xFF27AE60,'Construção & Reforma':0xFFE67E22,
    'Saúde & Higiene':0xFFE74C3C,'Tecnologia':0xFF2E86D1,
    'Moda & Casa':0xFF8E44AD,'Escola & Escritório':0xFF16A085,
    'Bebê & Criança':0xFFE91E8C,'Outros':0xFF7F8C8D,
  };

  List<ShoppingItem> get items =>
      _box.values.toList()..sort((a, b) => a.category.compareTo(b.category));

  Future<void> init() async {
    _box = await Hive.openBox<ShoppingItem>('shopping_items');
    notifyListeners();
  }

  Future<void> sincronizarDoServidor() async {
    if (_api == null || !(_sync?.online ?? false)) return;
    try {
      final lista = await _api!.get('/api/app/compras') as List<dynamic>;
      for (final item in lista) {
        final id = item['id'].toString();
        if (!_box.containsKey(id)) {
          final s = ShoppingItem(
            id            : id,
            name          : item['item'] ?? item['name'] ?? '',
            category      : item['categoria'] ?? item['category'] ?? 'Outros',
            quantity      : (item['quantidade'] ?? item['quantity'] ?? 1).toDouble(),
            unit          : item['unidade'] ?? item['unit'] ?? 'un',
            estimatedPrice: item['preco_estimado'] != null
                ? (item['preco_estimado']).toDouble() : null,
            isChecked     : (item['comprado'] ?? 0) == 1,
            note          : item['nota'] ?? item['note'] ?? '',
            createdAt     : DateTime.tryParse(item['criado_em'] ?? '') ?? DateTime.now(),
          );
          await _box.put(id, s);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  List<ShoppingItem> getByCategory(String category) =>
      items.where((i) => i.category == category).toList();

  Map<String, List<ShoppingItem>> get itemsByCategory {
    final map = <String, List<ShoppingItem>>{};
    for (final item in items) {
      map[item.category] = [...(map[item.category] ?? []), item];
    }
    return map;
  }

  int get totalItems    => items.length;
  int get checkedItems  => items.where((i) => i.isChecked).length;
  double get estimatedTotal => items
      .where((i) => !i.isChecked && i.estimatedPrice != null)
      .fold(0, (s, i) => s + (i.estimatedPrice! * i.quantity));

  int countByCategory(String cat)        => items.where((i) => i.category == cat).length;
  int countPendingByCategory(String cat) => items.where((i) => i.category == cat && !i.isChecked).length;

  Future<void> add(ShoppingItem item) async {
    await _box.put(item.id, item);
    notifyListeners();
    final body = {
      'item'           : item.name,
      'categoria'      : item.category,
      'quantidade'     : item.quantity,
      'unidade'        : item.unit,
      'preco_estimado' : item.estimatedPrice,
      'nota'           : item.note,
    };
    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.post('/api/app/compras', body); } catch (_) {
        await _sync?.enfileirar(metodo: 'POST', path: '/api/app/compras', body: body, idLocal: item.id);
      }
    } else {
      await _sync?.enfileirar(metodo: 'POST', path: '/api/app/compras', body: body, idLocal: item.id);
    }
  }

  Future<void> toggleCheck(ShoppingItem item) async {
    item.isChecked = !item.isChecked;
    await item.save();
    notifyListeners();
    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.patch('/api/app/compras/${item.id}/toggle'); } catch (_) {
        await _sync?.enfileirar(metodo: 'PATCH', path: '/api/app/compras/${item.id}/toggle');
      }
    } else {
      await _sync?.enfileirar(metodo: 'PATCH', path: '/api/app/compras/${item.id}/toggle');
    }
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    notifyListeners();
    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.delete('/api/app/compras/$id'); } catch (_) {
        await _sync?.enfileirar(metodo: 'DELETE', path: '/api/app/compras/$id');
      }
    } else {
      await _sync?.enfileirar(metodo: 'DELETE', path: '/api/app/compras/$id');
    }
  }

  Future<void> clearChecked() async {
    final checked = items.where((i) => i.isChecked).toList();
    for (final item in checked) { await _box.delete(item.id); }
    notifyListeners();
    if (_api != null && (_sync?.online ?? false)) {
      try { await _api!.delete('/api/app/compras/limpar/comprados'); } catch (_) {}
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
    notifyListeners();
  }

  String generateId() => _uuid.v4();
}

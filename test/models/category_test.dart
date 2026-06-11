import 'package:flutter_test/flutter_test.dart';
import 'package:accounting_app/models/category.dart';

void main() {
  group('Category Model', () {
    test('fromMap 正確解析所有欄位', () {
      final map = {
        'category_id': 1,
        'category_name': '早餐',
        'icon_name': 'breakfast',
        'display_order': 1,
      };
      final cat = Category.fromMap(map);
      expect(cat.id, 1);
      expect(cat.name, '早餐');
      expect(cat.iconName, 'breakfast');
      expect(cat.displayOrder, 1);
    });

    test('fromMap 處理 null icon_name', () {
      final map = {
        'category_id': 2,
        'category_name': '午餐',
        'icon_name': null,
        'display_order': 2,
      };
      final cat = Category.fromMap(map);
      expect(cat.iconName, isNull);
    });

    test('toMap 排除 null id', () {
      const cat = Category(name: '晚餐');
      final map = cat.toMap();
      expect(map.containsKey('category_id'), isFalse);
      expect(map['category_name'], '晚餐');
    });

    test('toMap 包含非 null id', () {
      const cat = Category(id: 3, name: '交通', displayOrder: 4);
      final map = cat.toMap();
      expect(map['category_id'], 3);
      expect(map['display_order'], 4);
    });
  });
}

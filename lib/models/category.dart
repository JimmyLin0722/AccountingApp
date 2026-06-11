class Category {
  final int? id;
  final String name;
  final String? iconName;
  final int displayOrder;

  const Category({
    this.id,
    required this.name,
    this.iconName,
    this.displayOrder = 0,
  });

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['category_id'] as int?,
        name: map['category_name'] as String,
        iconName: map['icon_name'] as String?,
        displayOrder: map['display_order'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'category_id': id,
        'category_name': name,
        'icon_name': iconName,
        'display_order': displayOrder,
      };
}

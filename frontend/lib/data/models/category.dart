class Category {
  final int id;
  final String name;
  final String type;
  final String? emoji;
  final List<Category> children;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.emoji,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      emoji: json['emoji'],
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => Category.fromJson(c))
              .toList() ??
          [],
    );
  }

  /// 递归获取所有叶子节点（没有子分类的最终分类）
  List<Category> get leafCategories {
    if (children.isEmpty) return [this];
    return children.expand((c) => c.leafCategories).toList();
  }
}

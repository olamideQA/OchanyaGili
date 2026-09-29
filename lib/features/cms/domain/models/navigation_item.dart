class NavigationItem {
  final String id;
  final String title;
  final String path;
  final int sortOrder;
  final bool isVisible;
  final bool isExternal;

  const NavigationItem({
    required this.id,
    required this.title,
    required this.path,
    this.sortOrder = 0,
    this.isVisible = true,
    this.isExternal = false,
  });

  factory NavigationItem.fromJson(Map<String, dynamic> json) {
    return NavigationItem(
      id: json['id'] as String? ?? UniqueKey().toString(),
      title: json['title'] as String? ?? '',
      path: json['path'] as String? ?? '/',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isVisible: json['is_visible'] as bool? ?? true,
      isExternal: json['is_external'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'sort_order': sortOrder,
      'is_visible': isVisible,
      'is_external': isExternal,
    };
  }

  NavigationItem copyWith({
    String? id,
    String? title,
    String? path,
    int? sortOrder,
    bool? isVisible,
    bool? isExternal,
  }) {
    return NavigationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      path: path ?? this.path,
      sortOrder: sortOrder ?? this.sortOrder,
      isVisible: isVisible ?? this.isVisible,
      isExternal: isExternal ?? this.isExternal,
    );
  }
}

// Utility class for UniqueKey without flutter dependency if needed
class UniqueKey {
  static int _counter = 0;
  @override
  String toString() => 'nav-item-${++_counter}';
}

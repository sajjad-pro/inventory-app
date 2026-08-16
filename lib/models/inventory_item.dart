/// نموذج يمثل مادة واحدة في المخزن
class InventoryItem {
  final int? id; // معرف قاعدة البيانات (تلقائي)
  final String name; // اسم المادة
  final double received; // الكمية المستلمة
  final double issued; // الكمية المصروفة
  final double delivered; // الكمية المسلمة

  InventoryItem({
    this.id,
    required this.name,
    required this.received,
    required this.issued,
    required this.delivered,
  });

  /// باقي الكمية في المخزن = المستلمة - المصروفة - المسلمة
  /// يُحسب دائماً تلقائياً، لا يُخزَّن كقيمة ثابتة حتى لا يختل التوافق
  double get remaining => received - issued - delivered;

  /// تحويل الكائن إلى Map لتخزينه في SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'received': received,
      'issued': issued,
      'delivered': delivered,
    };
  }

  /// إنشاء الكائن من صف قادم من قاعدة البيانات
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      received: (map['received'] as num).toDouble(),
      issued: (map['issued'] as num).toDouble(),
      delivered: (map['delivered'] as num).toDouble(),
    );
  }

  InventoryItem copyWith({
    int? id,
    String? name,
    double? received,
    double? issued,
    double? delivered,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      received: received ?? this.received,
      issued: issued ?? this.issued,
      delivered: delivered ?? this.delivered,
    );
  }
}

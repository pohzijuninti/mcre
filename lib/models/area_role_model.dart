class AreaRoleModel {
  final String id;
  final String name;

  AreaRoleModel({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory AreaRoleModel.fromJson(Map<String, dynamic> json) {
    return AreaRoleModel(
      id: json['id'],
      name: json['name'],
    );
  }
}

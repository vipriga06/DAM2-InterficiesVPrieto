
class ServerConfig {
  final String id;
  String name;
  String host;
  int port;
  String username;
  String password;
  String keyPath;
  bool isFavorite;

  ServerConfig({
    required this.id,
    required this.name,
    required this.host,
    this.port = 22,
    this.username = 'root',
    this.password = '',
    this.keyPath = '',
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'keyPath': keyPath,
        'isFavorite': isFavorite,
      };

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        host: json['host'] as String,
        port: (json['port'] as num?)?.toInt() ?? 22,
        username: json['username'] as String? ?? 'root',
        password: json['password'] as String? ?? '',
        keyPath: json['keyPath'] as String? ?? '',
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  ServerConfig copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? keyPath,
    bool? isFavorite,
  }) =>
      ServerConfig(
        id: id,
        name: name ?? this.name,
        host: host ?? this.host,
        port: port ?? this.port,
        username: username ?? this.username,
        password: password ?? this.password,
        keyPath: keyPath ?? this.keyPath,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}

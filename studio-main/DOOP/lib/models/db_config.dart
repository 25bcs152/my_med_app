enum DbType {
  marg,
  pmbi,
}

class DbConfig {
  final DbType type;
  /// For Marg: The 'Data' directory path
  /// For PMBI: Can be used as a base to find config, but mostly we use host/port
  final String? path;
  
  /// SQL Server specific
  final String host;
  final int port;
  final String databaseName;
  final String username;
  final String password;

  DbConfig({
    required this.type,
    this.path,
    this.host = 'localhost',
    this.port = 1433,
    this.databaseName = '',
    this.username = '',
    this.password = '',
  });
}

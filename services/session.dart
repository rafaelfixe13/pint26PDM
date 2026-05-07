class Session {
  static Map<String, dynamic> utilizador = {};

  static void iniciar(Map<String, dynamic> user) {
    utilizador = Map<String, dynamic>.from(user);
  }

  static void terminar() {
    utilizador = {};
  }

  static int get id => int.tryParse('${utilizador['idutilizador'] ?? 0}') ?? 0;
  static String get nome => utilizador['nome']?.toString() ?? '';
  static String get email => utilizador['email']?.toString() ?? '';
  static String get fotoUrl => utilizador['fotourl']?.toString() ?? '';
  static int get pontos => int.tryParse('${utilizador['pontos'] ?? 0}') ?? 0;
}
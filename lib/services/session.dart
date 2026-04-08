class Session {
  static Map<String, dynamic> utilizador = {};

  static void iniciar(Map<String, dynamic> user) {
    utilizador = Map<String, dynamic>.from(user);
  }

  static void terminar() {
    utilizador = {};
  }

  static int get id => utilizador['idutilizador'] ?? 0;
  static String get nome => utilizador['nome'] ?? '';
  static String get email => utilizador['email'] ?? '';
  static String get fotoUrl => utilizador['fotourl'] ?? '';
}
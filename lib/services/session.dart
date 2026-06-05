class Session {
  static Map<String, dynamic> utilizador = {};
  static bool lembretesMostrados = false;
  static bool marcosVerificados = false;

  static void iniciar(Map<String, dynamic> user) {
    utilizador = Map<String, dynamic>.from(user);
    lembretesMostrados = false;
    marcosVerificados = false;
  }

  static void terminar() {
    utilizador = {};
    lembretesMostrados = false;
    marcosVerificados = false;
  }

  static int get id => int.tryParse('${utilizador['idutilizador'] ?? 0}') ?? 0;
  static String get nome => utilizador['nome']?.toString() ?? '';
  static String get email => utilizador['email']?.toString() ?? '';
  static String get fotoUrl => utilizador['fotourl']?.toString() ?? '';
  static int get pontos => int.tryParse('${utilizador['pontos'] ?? 0}') ?? 0;
  static int get idArea => int.tryParse('${utilizador['idarea'] ?? 0}') ?? 0;
}
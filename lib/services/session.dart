import 'basededados.dart';

class Session {
  static Map<String, dynamic> utilizador = {};
  static bool lembretesMostrados = false;
  static bool marcosVerificados = false;
  static bool expiracaoVerificada = false;
  static bool rgpdVerificado = false;

  static void iniciar(Map<String, dynamic> user) {
    utilizador = Map<String, dynamic>.from(user);
    lembretesMostrados = false;
    marcosVerificados = false;
    expiracaoVerificada = false;
    rgpdVerificado = false;
  }

  static void terminar() {
    utilizador = {};
    lembretesMostrados = false;
    marcosVerificados = false;
    expiracaoVerificada = false;
    rgpdVerificado = false;
  }

  static int get id => int.tryParse('${utilizador['idutilizador'] ?? 0}') ?? 0;
  static String get nome => utilizador['nome']?.toString() ?? '';
  static String get email => utilizador['email']?.toString() ?? '';
  static String get fotoUrl => utilizador['fotourl']?.toString() ?? '';
  static int get pontos => int.tryParse('${utilizador['pontos'] ?? 0}') ?? 0;
  static int get idArea => int.tryParse('${utilizador['idarea'] ?? 0}') ?? 0;

  // Atualiza o RGPD em memória e persiste no cache local (com o mesmo hash
  // de password já guardado), para a escolha sobreviver a um reinício da app.
  static Future<void> atualizarRgpdPersistente(bool valor) async {
    utilizador['rgpd'] = valor;
    final sessaoLocal = await Basededados().obterSessaoLocal();
    final pwHash = sessaoLocal?['_pw_hash']?.toString() ?? '';
    await Basededados().guardarSessao(utilizador, pwHash);
  }
}
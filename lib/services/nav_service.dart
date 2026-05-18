/// Serviço singleton de navegação global.
/// Permite que qualquer tela navegue para um índice do MainShell
/// sem depender de import circular do main.dart.
class NavService {
  NavService._();
  static final NavService instance = NavService._();

  void Function(int)? _navigate;

  /// Registrado pelo MainShell ao ser construído.
  void register(void Function(int) fn) => _navigate = fn;

  /// Chamado por qualquer tela para navegar.
  void goTo(int index) => _navigate?.call(index);

  /// Atalho estático para uso direto.
  static void go(int index) => instance.goTo(index);
}

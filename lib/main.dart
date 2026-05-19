import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';

import 'theme/app_theme.dart';
import 'models/appointment.dart';
import 'models/transaction.dart';
import 'models/budget.dart';
import 'models/shopping_item.dart';
import 'models/urgent_task.dart';
import 'models/password_entry.dart';
import 'models/pet.dart';
import 'providers/agenda_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/shopping_provider.dart';
import 'providers/urgent_task_provider.dart';
import 'providers/password_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/sync_service.dart';
import 'services/update_service.dart';
import 'services/nav_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/agenda_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/shopping_screen.dart';
import 'screens/urgent_tasks_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/pet_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notes_screen.dart';
import 'models/note.dart';
import 'providers/notes_provider.dart';
import 'widgets/voice_assistant_widget.dart';

// ── Providers globais (criados antes do runApp) ───────────────────────────────
late AuthService       _authService;
late ApiService        _apiService;
late SyncService       _syncService;
late AgendaProvider    _agendaProvider;
late FinanceProvider   _financeProvider;
late BudgetProvider    _budgetProvider;
late ShoppingProvider  _shoppingProvider;
late UrgentTaskProvider _urgentTaskProvider;
late PasswordProvider  _passwordProvider;
late PetProvider       _petProvider;
late ThemeProvider     _themeProvider;
late NotesProvider     _notesProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Inicialização mínima ANTES do runApp (só o essencial) ─────────────────
  await Future.wait([
    initializeDateFormatting('pt_BR', null),
    Hive.initFlutter(),
  ]);

  // Registra adapters (síncrono — rápido)
  Hive.registerAdapter(AppointmentAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(BudgetItemAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(ShoppingItemAdapter());
  Hive.registerAdapter(UrgentTaskAdapter());
  Hive.registerAdapter(PasswordEntryAdapter());
  Hive.registerAdapter(PetAdapter());
  Hive.registerAdapter(PetVacinaAdapter());
  Hive.registerAdapter(PetConsultaAdapter());
  Hive.registerAdapter(PetMedicamentoAdapter());
  Hive.registerAdapter(NoteAdapter());

  // Cria providers (sem init ainda)
  _authService        = AuthService();
  _agendaProvider     = AgendaProvider();
  _financeProvider    = FinanceProvider();
  _budgetProvider     = BudgetProvider();
  _shoppingProvider   = ShoppingProvider();
  _urgentTaskProvider = UrgentTaskProvider();
  _passwordProvider   = PasswordProvider();
  _petProvider        = PetProvider();
  _themeProvider      = ThemeProvider();
  _notesProvider      = NotesProvider();

  // runApp imediato — mostra splash Flutter enquanto inicializa
  runApp(const _BootstrapApp());
}

// ── App de boot — inicializa tudo em paralelo e troca para o app real ─────────
class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();
  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  bool _pronto = false;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      // Auth primeiro (para saber se está logado)
      await _authService.init();

      // Cria dependências que precisam do auth
      _apiService  = ApiService(_authService);
      _syncService = SyncService(_apiService);

      // Tudo em paralelo — abre todos os Hive boxes ao mesmo tempo
      await Future.wait([
        _syncService.init(),
        _agendaProvider.init(),
        _financeProvider.init(),
        _budgetProvider.init(),
        _shoppingProvider.init(),
        _urgentTaskProvider.init(),
        _passwordProvider.init(),
        _petProvider.init(),
        _themeProvider.init(),
        _notesProvider.init(),
      ]);

      // Injeta serviços
      _agendaProvider.setServices(_apiService, _syncService);
      _financeProvider.setServices(_apiService, _syncService);
      _shoppingProvider.setServices(_apiService, _syncService);
      _urgentTaskProvider.setServices(_apiService, _syncService);

    } catch (e) {
      // Mesmo com erro, abre o app (não trava)
      debugPrint('Bootstrap error: $e');
    }

    if (mounted) setState(() => _pronto = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_pronto) {
      // Splash Flutter nativa — mesma cor do launch_background.xml
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _SplashView(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider.value(value: _syncService),
        ChangeNotifierProvider.value(value: _agendaProvider),
        ChangeNotifierProvider.value(value: _financeProvider),
        ChangeNotifierProvider.value(value: _budgetProvider),
        ChangeNotifierProvider.value(value: _shoppingProvider),
        ChangeNotifierProvider.value(value: _urgentTaskProvider),
        ChangeNotifierProvider.value(value: _passwordProvider),
        ChangeNotifierProvider.value(value: _petProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _notesProvider),
      ],
      child: const TudoNaMaoApp(),
    );
  }
}

// ── Splash view Flutter (substitui a nativa após o Flutter engine subir) ──────
class _SplashView extends StatelessWidget {
  const _SplashView();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0B1F3A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo igual à splash nativa
            Image(
              image: const AssetImage('assets/logo/logo_192.png'),
              width: 110,
              height: 110,
              errorBuilder: _logoFallback,
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFf97316)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _logoFallback(BuildContext ctx, Object err, StackTrace? st) {
    return Container(
      width: 110, height: 110,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFf97316), Color(0xFFea580c)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 56),
    );
  }
}

// ── App root — decide Login ou MainShell ──────────────────────────────────────

class TudoNaMaoApp extends StatelessWidget {
  const TudoNaMaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'TudoNaMão',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.theme,
      themeMode: themeProvider.themeMode,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.loggedIn) return const MainShell();
    return const LoginScreen();
  }
}

// ── Shell principal do app ────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _syncIniciado = false;

  @override
  void initState() {
    super.initState();
    NavService.instance.register(_navigateTo);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissions();
      await _iniciarSync();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        try {
          await UpdateService.checarAtualizacao(context);
        } catch (_) {}
      }
    });
  }

  Future<void> _requestPermissions() async {
    try {
      final micStatus = await Permission.microphone.status;
      if (micStatus.isDenied) await Permission.microphone.request();
    } catch (_) {}
  }

  Future<void> _iniciarSync() async {
    if (_syncIniciado) return;
    _syncIniciado = true;
    try {
      final sync    = context.read<SyncService>();
      final agenda  = context.read<AgendaProvider>();
      final finance = context.read<FinanceProvider>();
      final shop    = context.read<ShoppingProvider>();
      final urgent  = context.read<UrgentTaskProvider>();

      if (sync.online) {
        await Future.wait([
          agenda.sincronizarDoServidor(),
          finance.sincronizarDoServidor(),
          shop.sincronizarDoServidor(),
          urgent.sincronizarDoServidor(),
        ]);
        await sync.sincronizar();
      }
    } catch (_) {}
  }

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  final _screens = const [
    HomeScreen(),
    AgendaScreen(),
    FinanceScreen(),
    ShoppingScreen(),
    UrgentTasksScreen(),
    BudgetScreen(),
    VaultScreen(),
    PetScreen(),
    AiAssistantScreen(),
    SettingsScreen(),
    NotesScreen(),
  ];

  static const _navItems = [
    _NavConfig(icon: Icons.dashboard_rounded,              label: 'Início',   index: 0),
    _NavConfig(icon: Icons.calendar_month_rounded,         label: 'Agenda',   index: 1),
    _NavConfig(icon: Icons.account_balance_wallet_rounded, label: 'Finanças', index: 2),
    _NavConfig(icon: Icons.shopping_cart_rounded,          label: 'Compras',  index: 3),
    _NavConfig(icon: Icons.alarm_rounded,                  label: 'Urgente',  index: 4),
  ];

  @override
  Widget build(BuildContext context) {
    final urgentProvider   = context.watch<UrgentTaskProvider>();
    final shoppingProvider = context.watch<ShoppingProvider>();
    final syncService      = context.watch<SyncService>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: VoiceAssistantButton(onNavigate: _navigateTo),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: AppColors.primaryDark,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 20,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                ..._navItems.sublist(0, 3).map((cfg) => Expanded(
                  child: _NavItem(
                    icon: cfg.icon, label: cfg.label,
                    selected: _currentIndex == cfg.index,
                    onTap: () => _navigateTo(cfg.index),
                  ),
                )),
                const SizedBox(width: 68),
                ..._navItems.sublist(3, 5).map((cfg) {
                  int? badge;
                  if (cfg.index == 4) {
                    final p = urgentProvider.pendingCount;
                    badge = p > 0 ? p : null;
                  }
                  if (cfg.index == 3) {
                    final rem = shoppingProvider.totalItems - shoppingProvider.checkedItems;
                    badge = rem > 0 ? rem : null;
                  }
                  return Expanded(
                    child: _NavItem(
                      icon: cfg.icon, label: cfg.label,
                      selected: _currentIndex == cfg.index,
                      badge: badge,
                      onTap: () => _navigateTo(cfg.index),
                    ),
                  );
                }),
                Expanded(
                  child: _MoreButton(
                    currentIndex: _currentIndex,
                    onSelect: _navigateTo,
                    pendentes: syncService.pendentes,
                    urgentesNaoVistos: urgentProvider.pendingCount,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Botão "Mais" com menu popup ───────────────────────────────────────────────

class _MoreButton extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onSelect;
  final int pendentes;
  final int urgentesNaoVistos;
  const _MoreButton({
    required this.currentIndex,
    required this.onSelect,
    this.pendentes = 0,
    this.urgentesNaoVistos = 0,
  });

  bool get _isActive => currentIndex == 5 || currentIndex == 6 || currentIndex == 7 || currentIndex == 8 || currentIndex == 9 || currentIndex == 10;

  String get _label {
    if (currentIndex == 5) return 'Orçam.';
    if (currentIndex == 6) return 'Cofre';
    if (currentIndex == 7) return 'MeuPet';
    if (currentIndex == 8) return 'IA';
    if (currentIndex == 9) return 'Config.';
    if (currentIndex == 10) return 'Notas';
    return 'Mais';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openMenu(context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        decoration: BoxDecoration(
          color: _isActive
              ? AppColors.accentOrange.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.apps_rounded,
                    color: _isActive ? AppColors.accentOrange : const Color(0xFFBDD3EA),
                    size: _isActive ? 24 : 22),
                if (urgentesNaoVistos > 0 && currentIndex != 4)
                  Positioned(
                    right: -6, top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: AppColors.danger, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                          urgentesNaoVistos > 9 ? '9+' : '$urgentesNaoVistos',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center),
                    ),
                  )
                else if (pendentes > 0 && urgentesNaoVistos == 0)
                  Positioned(
                    right: -5, top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Color(0xFFf97316), shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text('$pendentes',
                          style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(_label,
                style: TextStyle(
                  color: _isActive ? AppColors.accentOrange : const Color(0xFFBDD3EA),
                  fontSize: 9,
                  fontWeight: _isActive ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    final RenderBox button  = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect pos  = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<int>(
      context: context,
      position: pos,
      color: const Color(0xFF0F2240),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      items: [
        _menuItem(10, Icons.sticky_note_2_rounded, 'Anotações',    const Color(0xFFFF7A00)),
        _menuItem(5, Icons.description_rounded,    'Orçamentos',   const Color(0xFF3B82F6)),
        _menuItem(6, Icons.lock_rounded,            'Cofre',        const Color(0xFFFF7A00)),
        _menuItem(7, Icons.pets_rounded,            'MeuPet',       const Color(0xFFf97316)),
        _menuItem(8, Icons.auto_awesome_rounded,    'Assistente IA',const Color(0xFF6366f1)),
        _menuItem(9, Icons.settings_rounded,        'Configurações',const Color(0xFF64748b)),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: -1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Builder(builder: (ctx) {
            final auth = Provider.of<AuthService>(ctx, listen: false);
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sair',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(auth.email,
                          style: const TextStyle(color: Color(0xFF64748b), fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    ).then((val) async {
      if (val == null) return;
      if (val == -1) {
        final auth = context.read<AuthService>();
        final sync = context.read<SyncService>();
        await sync.limparFila();
        await auth.logout();
      } else {
        onSelect(val);
      }
    });
  }

  PopupMenuItem<int> _menuItem(int val, IconData icon, String label, Color color) {
    return PopupMenuItem<int>(
      value: val,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Configuração de item da barra ─────────────────────────────────────────────

class _NavConfig {
  final IconData icon;
  final String label;
  final int index;
  const _NavConfig({required this.icon, required this.label, required this.index});
}

// ── Item da barra inferior ────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    const Color activeColor   = AppColors.accentOrange;
    const Color inactiveColor = Color(0xFFBDD3EA);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon,
                    color: selected ? activeColor : inactiveColor,
                    size: selected ? 24 : 22),
                if (badge != null)
                  Positioned(
                    right: -6, top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: AppColors.danger, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(badge! > 99 ? '99+' : '$badge',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  color: selected ? activeColor : inactiveColor,
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

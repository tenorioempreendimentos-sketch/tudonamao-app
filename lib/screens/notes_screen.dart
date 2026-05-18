import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';

// ── Paleta de cores das anotações ────────────────────────────────────────────
const _kCores = [
  '#1E3A5F', // azul escuro (padrão)
  '#1a3a2a', // verde escuro
  '#3a1a2a', // vinho
  '#2a2a1a', // mostarda
  '#1a2a3a', // azul petróleo
  '#2d1a3a', // roxo
  '#3a2a1a', // marrom
  '#1a3a3a', // teal
];

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// ── Tela principal de Anotações ───────────────────────────────────────────────
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final notes = _query.isEmpty ? provider.notes : provider.buscar(_query);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F3A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, provider.notes.length),
            _buildSearchBar(),
            Expanded(
              child: notes.isEmpty ? _buildEmpty() : _buildGrid(notes),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirEditor(context),
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova nota',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1F3A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sticky_note_2_rounded,
                color: Color(0xFFFF7A00), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Anotações',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                Text(
                  total == 0
                      ? 'Nenhuma anotação'
                      : '$total anotaç${total == 1 ? 'ão' : 'ões'}',
                  style: const TextStyle(
                      color: Color(0xFF64748b), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F2240),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: const Color(0xFFFF7A00),
            decoration: const InputDecoration(
              hintText: 'Buscar anotações...',
              hintStyle: TextStyle(color: Color(0xFF64748b), fontSize: 14),
              prefixIcon:
                  Icon(Icons.search_rounded, color: Color(0xFF64748b), size: 20),
              filled: false,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sticky_note_2_outlined,
              size: 72, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          Text(
            _query.isNotEmpty ? 'Nenhuma nota encontrada' : 'Nenhuma anotação ainda',
            style: const TextStyle(color: Color(0xFF64748b), fontSize: 16),
          ),
          if (_query.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Toque em "Nova nota" para começar',
              style: TextStyle(color: Color(0xFF475569), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid(List<Note> notes) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: notes.length,
      itemBuilder: (context, i) => _buildCard(context, notes[i]),
    );
  }

  Widget _buildCard(BuildContext context, Note note) {
    final bgColor = _hexToColor(note.cor);
    final dataFmt = _formatarData(note.atualizadoEm);

    return GestureDetector(
      onTap: () => _abrirEditor(context, note: note),
      onLongPress: () => _menuOpcoes(context, note),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: fixada + título
            Row(
              children: [
                if (note.fixada)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.push_pin_rounded,
                        size: 14,
                        color: const Color(0xFFFF7A00).withValues(alpha: 0.9)),
                  ),
                Expanded(
                  child: Text(
                    note.titulo.isEmpty ? 'Sem título' : note.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Conteúdo
            Expanded(
              child: Text(
                note.conteudo.isEmpty ? '' : note.conteudo,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  height: 1.5,
                ),
                overflow: TextOverflow.fade,
              ),
            ),
            const SizedBox(height: 8),
            // Data
            Text(
              dataFmt,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
    return DateFormat('dd/MM/yy', 'pt_BR').format(dt);
  }

  void _menuOpcoes(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2240),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                note.fixada
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                color: const Color(0xFFFF7A00),
              ),
              title: Text(
                note.fixada ? 'Desafixar nota' : 'Fixar nota',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.read<NotesProvider>().toggleFixar(note);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.edit_rounded, color: Color(0xFF6366f1)),
              title: const Text('Editar',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _abrirEditor(context, note: note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_rounded,
                  color: Color(0xFF10b981)),
              title: const Text('Mudar cor',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _selecionarCor(context, note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Color(0xFFef4444)),
              title: const Text('Excluir',
                  style: TextStyle(color: Color(0xFFef4444))),
              onTap: () {
                Navigator.pop(ctx);
                _confirmarExclusao(context, note);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _selecionarCor(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2240),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Escolher cor',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _kCores.map((hex) {
            final selected = note.cor == hex;
            return GestureDetector(
              onTap: () {
                context.read<NotesProvider>().editarNota(note, cor: hex);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _hexToColor(hex),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFFF7A00)
                        : Colors.white.withValues(alpha: 0.15),
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2240),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir nota?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'A nota "${note.titulo.isEmpty ? 'Sem título' : note.titulo}" será excluída permanentemente.',
          style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF64748b))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              context.read<NotesProvider>().excluirNota(note);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _abrirEditor(BuildContext context, {Note? note}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NoteEditorScreen(note: note),
        fullscreenDialog: true,
      ),
    );
  }
}

// ── Editor de nota (tela cheia) ───────────────────────────────────────────────
class _NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const _NoteEditorScreen({this.note});

  @override
  State<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<_NoteEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late String _cor;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.note?.titulo ?? '');
    _bodyCtrl =
        TextEditingController(text: widget.note?.conteudo ?? '');
    _cor = widget.note?.cor ?? '#1E3A5F';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final provider = context.read<NotesProvider>();
    final titulo = _titleCtrl.text.trim();
    final conteudo = _bodyCtrl.text.trim();

    if (titulo.isEmpty && conteudo.isEmpty) return;

    if (widget.note == null) {
      await provider.adicionarNota(
        titulo: titulo,
        conteudo: conteudo,
        cor: _cor,
      );
    } else {
      await provider.editarNota(
        widget.note!,
        titulo: titulo,
        conteudo: conteudo,
        cor: _cor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _hexToColor(_cor);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) await _salvar();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () async {
              await _salvar();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          actions: [
            // Paleta de cores
            IconButton(
              icon: const Icon(Icons.palette_rounded, color: Colors.white70),
              onPressed: () => _selecionarCor(context),
              tooltip: 'Mudar cor',
            ),
            // Salvar explícito
            TextButton.icon(
              onPressed: () async {
                await _salvar();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Nota salva!'),
                      backgroundColor: const Color(0xFF16a34a),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  setState(() {});
                }
              },
              icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
              label: const Text('Salvar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        body: Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: const InputDecorationTheme(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          child: Column(
            children: [
              // Campo título
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  cursorColor: const Color(0xFFFF7A00),
                  maxLines: 2,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Título',
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              // Divider
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
              // Campo conteúdo (expansível)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                  child: TextField(
                    controller: _bodyCtrl,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      height: 1.7,
                    ),
                    cursorColor: const Color(0xFFFF7A00),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Escreva sua nota aqui...',
                      hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25),
                          fontSize: 16),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selecionarCor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2240),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cor da nota',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _kCores.map((hex) {
                  final selected = _cor == hex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _cor = hex);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _hexToColor(hex),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFFF7A00)
                              : Colors.white.withValues(alpha: 0.15),
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

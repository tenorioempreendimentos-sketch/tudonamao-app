import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/pet.dart';
import '../providers/pet_provider.dart';

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  Pet? _petSelecionado;
  int _tabIndex = 0; // 0=vacinas 1=consultas 2=medicamentos

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PetProvider>();
    final pets = provider.pets;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 110,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF7C3AED),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFf97316), Color(0xFFea580c)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🐾 MeuPet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              pets.isEmpty
                                  ? 'Nenhum pet cadastrado'
                                  : '${pets.length} pet${pets.length != 1 ? "s" : ""} cadastrado${pets.length != 1 ? "s" : ""}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _abrirModalPet(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Novo Pet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFea580c),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Corpo ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grid de pets
                  if (pets.isEmpty)
                    _EmptyPets(onAdd: () => _abrirModalPet(context))
                  else ...[
                    _PetsGrid(
                      pets: pets,
                      selecionado: _petSelecionado,
                      onSelect: (pet) {
                        setState(() {
                          _petSelecionado = pet;
                          _tabIndex = 0;
                        });
                      },
                      onAdd: () => _abrirModalPet(context),
                    ),
                    const SizedBox(height: 20),

                    // Detalhe do pet selecionado
                    if (_petSelecionado != null) ...[
                      _PetDetalhe(
                        pet: _petSelecionado!,
                        onEditar: () => _editarPet(context, _petSelecionado!),
                        onDeletar: () => _deletarPet(context, _petSelecionado!),
                      ),
                      const SizedBox(height: 12),

                      // Abas
                      _PetTabs(
                        tabIndex: _tabIndex,
                        onTab: (i) => setState(() => _tabIndex = i),
                      ),
                      const SizedBox(height: 12),

                      // Conteúdo da aba
                      if (_tabIndex == 0)
                        _VacinasTab(pet: _petSelecionado!)
                      else if (_tabIndex == 1)
                        _ConsultasTab(pet: _petSelecionado!)
                      else
                        _MedicamentosTab(pet: _petSelecionado!),
                    ],
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Modal Cadastrar/Editar Pet ─────────────────────────────────────────────
  void _abrirModalPet(BuildContext context, {Pet? pet}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalPet(pet: pet),
    ).then((saved) {
      if (saved == true && pet != null) {
        // recarregar pet atualizado
        final provider = context.read<PetProvider>();
        final atualizado = provider.pets.where((p) => p.id == pet.id).firstOrNull;
        if (atualizado != null) setState(() => _petSelecionado = atualizado);
      }
    });
  }

  void _editarPet(BuildContext context, Pet pet) {
    _abrirModalPet(context, pet: pet);
  }

  Future<void> _deletarPet(BuildContext context, Pet pet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Excluir ${pet.nome}?'),
        content: const Text(
          'Todas as vacinas, consultas e medicamentos também serão removidos.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<PetProvider>().deletePet(pet.id);
      setState(() => _petSelecionado = null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pet.nome} removido'), backgroundColor: Colors.red.shade600),
        );
      }
    }
  }
}

// ── Grid de Pets ──────────────────────────────────────────────────────────────

class _PetsGrid extends StatelessWidget {
  final List<Pet> pets;
  final Pet? selecionado;
  final void Function(Pet) onSelect;
  final VoidCallback onAdd;

  const _PetsGrid({
    required this.pets,
    required this.selecionado,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: pets.length + 1,
      itemBuilder: (context, i) {
        if (i == pets.length) {
          return _AddPetCard(onAdd: onAdd);
        }
        final pet = pets[i];
        final selected = selecionado?.id == pet.id;
        return _PetCard(pet: pet, selected: selected, onTap: () => onSelect(pet));
      },
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;
  final bool selected;
  final VoidCallback onTap;
  const _PetCard({required this.pet, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFfff7ed) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFf97316) : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: const Color(0xFFf97316).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 3))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(pet.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 6),
            Text(
              pet.nome,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFFea580c) : AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              pet.idade,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPetCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _AddPetCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 1.5, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 32, color: AppColors.textLight),
            SizedBox(height: 6),
            Text('Adicionar', style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EmptyPets extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyPets({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Text('🐾', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Nenhum pet cadastrado ainda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text('Cadastre seu pet para registrar\nvacinas, consultas e medicamentos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar Pet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf97316),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detalhe do Pet ────────────────────────────────────────────────────────────

class _PetDetalhe extends StatelessWidget {
  final Pet pet;
  final VoidCallback onEditar;
  final VoidCallback onDeletar;
  const _PetDetalhe({required this.pet, required this.onEditar, required this.onDeletar});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFf97316), Color(0xFFea580c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFFf97316).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Hero
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Text(pet.emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet.nome,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text(
                        '${_cap(pet.especie)}${pet.raca.isNotEmpty ? " · ${pet.raca}" : ""} · ${pet.sexo == "femea" ? "Fêmea" : "Macho"}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _HeroBtn(icon: Icons.edit_outlined, label: 'Editar', onTap: onEditar),
                    const SizedBox(width: 8),
                    _HeroBtn(icon: Icons.delete_outline, label: 'Excluir', onTap: onDeletar, danger: true),
                  ],
                ),
              ],
            ),
          ),
          // Ficha
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _FichaItem(label: 'Idade', value: pet.idade),
                _FichaItem(label: 'Peso', value: pet.peso > 0 ? '${pet.peso.toStringAsFixed(1).replaceAll('.', ',')}kg' : '–'),
                _FichaItem(label: 'Cor', value: pet.cor.isNotEmpty ? pet.cor : '–'),
                _FichaItem(label: 'Castrado', value: pet.castrado ? 'Sim' : 'Não'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _HeroBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _HeroBtn({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: danger
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _FichaItem extends StatelessWidget {
  final String label;
  final String value;
  const _FichaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Abas ──────────────────────────────────────────────────────────────────────

class _PetTabs extends StatelessWidget {
  final int tabIndex;
  final void Function(int) onTab;
  const _PetTabs({required this.tabIndex, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _Tab(label: '💉 Vacinas',      index: 0, active: tabIndex == 0, onTap: onTab),
          _Tab(label: '🩺 Consultas',    index: 1, active: tabIndex == 1, onTap: onTab),
          _Tab(label: '💊 Medicamentos', index: 2, active: tabIndex == 2, onTap: onTab),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int index;
  final bool active;
  final void Function(int) onTap;
  const _Tab({required this.label, required this.index, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFfff7ed) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xFFea580c) : AppColors.textLight,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab Vacinas ───────────────────────────────────────────────────────────────

class _VacinasTab extends StatelessWidget {
  final Pet pet;
  const _VacinasTab({required this.pet});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PetProvider>();
    final vacinas = provider.getVacinas(pet.id);
    final fmt = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Histórico de Vacinas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            TextButton.icon(
              onPressed: () => _modalVacina(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nova'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFf97316)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (vacinas.isEmpty)
          _HealthEmpty(emoji: '💉', msg: 'Nenhuma vacina registrada',
              onAdd: () => _modalVacina(context))
        else
          ...vacinas.map((v) {
            Color tagColor = Colors.green;
            String tagLabel = '';
            if (v.proximaDose != null) {
              if (v.isVencida) {
                tagColor = Colors.red;
                tagLabel = '⚠️ Vencida';
              } else if (v.isProxima) {
                tagColor = Colors.orange;
                final d = v.proximaDose!.difference(DateTime.now()).inDays;
                tagLabel = '⏰ em ${d}d';
              } else {
                tagLabel = '✓ ${fmt.format(v.proximaDose!)}';
              }
            }
            return _HealthItem(
              emoji: '💉',
              title: v.nome,
              subtitle: fmt.format(v.dataAplicacao),
              extra: v.veterinario.isNotEmpty ? '👨‍⚕️ ${v.veterinario}' : null,
              notas: v.notas.isNotEmpty ? v.notas : null,
              tagLabel: tagLabel,
              tagColor: tagColor,
              onDelete: () async {
                await context.read<PetProvider>().deleteVacina(v.id);
              },
            );
          }),
      ],
    );
  }

  void _modalVacina(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalVacina(petId: pet.id),
    );
  }
}

// ── Tab Consultas ─────────────────────────────────────────────────────────────

class _ConsultasTab extends StatelessWidget {
  final Pet pet;
  const _ConsultasTab({required this.pet});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PetProvider>();
    final consultas = provider.getConsultas(pet.id);
    final fmt = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Histórico de Consultas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            TextButton.icon(
              onPressed: () => _modalConsulta(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nova'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFf97316)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (consultas.isEmpty)
          _HealthEmpty(emoji: '🩺', msg: 'Nenhuma consulta registrada',
              onAdd: () => _modalConsulta(context))
        else
          ...consultas.map((c) => _HealthItem(
            emoji: '🩺',
            title: c.motivo,
            subtitle: fmt.format(c.data),
            extra: c.veterinario.isNotEmpty
                ? '👨‍⚕️ ${c.veterinario}${c.clinica.isNotEmpty ? " · ${c.clinica}" : ""}'
                : null,
            notas: c.diagnostico.isNotEmpty ? '📋 ${c.diagnostico}' : (c.notas.isNotEmpty ? c.notas : null),
            tagLabel: c.proximaConsulta != null ? '🔄 Retorno: ${fmt.format(c.proximaConsulta!)}' : null,
            tagColor: Colors.green,
            onDelete: () async {
              await context.read<PetProvider>().deleteConsulta(c.id);
            },
          )),
      ],
    );
  }

  void _modalConsulta(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalConsulta(petId: pet.id),
    );
  }
}

// ── Tab Medicamentos ──────────────────────────────────────────────────────────

class _MedicamentosTab extends StatelessWidget {
  final Pet pet;
  const _MedicamentosTab({required this.pet});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PetProvider>();
    final meds = provider.getMedicamentos(pet.id);
    final fmt = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Medicamentos & Antiparasitários',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            TextButton.icon(
              onPressed: () => _modalMedicamento(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Novo'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFf97316)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (meds.isEmpty)
          _HealthEmpty(emoji: '💊', msg: 'Nenhum medicamento registrado',
              onAdd: () => _modalMedicamento(context))
        else
          ...meds.map((m) {
            final extra = [
              if (m.dose.isNotEmpty) '💊 ${m.dose}',
              if (m.frequencia.isNotEmpty) '🔄 ${m.frequencia}',
              if (m.dataInicio != null) 'Início: ${fmt.format(m.dataInicio!)}',
            ].join(' · ');
            return _MedItem(med: m, extra: extra.isNotEmpty ? extra : null);
          }),
      ],
    );
  }

  void _modalMedicamento(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalMedicamento(petId: pet.id),
    );
  }
}

// ── Health Item ───────────────────────────────────────────────────────────────

class _HealthItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? extra;
  final String? notas;
  final String? tagLabel;
  final Color tagColor;
  final Future<void> Function() onDelete;

  const _HealthItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.extra,
    this.notas,
    this.tagLabel,
    this.tagColor = Colors.grey,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _SmallTag(label: '📅 $subtitle', color: AppColors.primaryBlue),
                    if (extra != null) _SmallTag(label: extra!),
                    if (tagLabel != null && tagLabel!.isNotEmpty) _SmallTag(label: tagLabel!, color: tagColor),
                  ],
                ),
                if (notas != null) ...[
                  const SizedBox(height: 6),
                  Text(notas!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textLight),
            visualDensity: VisualDensity.compact,
            tooltip: 'Remover',
          ),
        ],
      ),
    );
  }
}

class _MedItem extends StatelessWidget {
  final PetMedicamento med;
  final String? extra;
  const _MedItem({required this.med, this.extra});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(med.tipoEmoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.nome,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _SmallTag(
                      label: med.ativo ? '✅ Ativo' : '⏸ Inativo',
                      color: med.ativo ? Colors.green : Colors.grey,
                    ),
                    if (med.tipo != 'medicamento') _SmallTag(label: _cap(med.tipo), color: Colors.purple),
                    if (extra != null && extra!.isNotEmpty) _SmallTag(label: extra!),
                  ],
                ),
                if (med.notas.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(med.notas,
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          Column(
            children: [
              // Toggle ativo/inativo
              GestureDetector(
                onTap: () => context.read<PetProvider>().toggleMedicamento(med.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 20,
                  decoration: BoxDecoration(
                    color: med.ativo ? Colors.green : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: med.ativo ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => context.read<PetProvider>().deleteMedicamento(med.id),
                child: const Icon(Icons.delete_outline, size: 18, color: AppColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _SmallTag extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallTag({required this.label, this.color = const Color(0xFF6B7280)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _HealthEmpty extends StatelessWidget {
  final String emoji;
  final String msg;
  final VoidCallback onAdd;
  const _HealthEmpty({required this.emoji, required this.msg, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Registrar agora'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFf97316),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODAIS
// ══════════════════════════════════════════════════════════════════════════════

// ── Modal Pet ─────────────────────────────────────────────────────────────────

class _ModalPet extends StatefulWidget {
  final Pet? pet;
  const _ModalPet({this.pet});

  @override
  State<_ModalPet> createState() => _ModalPetState();
}

class _ModalPetState extends State<_ModalPet> {
  final _nomeCtrl   = TextEditingController();
  final _racaCtrl   = TextEditingController();
  final _pesoCtrl   = TextEditingController();
  final _corCtrl    = TextEditingController();
  final _notasCtrl  = TextEditingController();
  String _especie   = 'cachorro';
  String _sexo      = 'macho';
  bool   _castrado  = false;
  DateTime? _nascimento;
  bool _saving = false;

  final _especies = [
    ('cachorro', '🐶 Cachorro'),
    ('gato',     '🐱 Gato'),
    ('ave',      '🐦 Ave'),
    ('peixe',    '🐠 Peixe'),
    ('roedor',   '🐹 Roedor'),
    ('reptil',   '🦎 Réptil'),
    ('outro',    '🐾 Outro'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      final p = widget.pet!;
      _nomeCtrl.text  = p.nome;
      _racaCtrl.text  = p.raca;
      _pesoCtrl.text  = p.peso > 0 ? p.peso.toString() : '';
      _corCtrl.text   = p.cor;
      _notasCtrl.text = p.notas;
      _especie        = p.especie;
      _sexo           = p.sexo;
      _castrado       = p.castrado;
      _nascimento     = p.nascimento;
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose(); _racaCtrl.dispose(); _pesoCtrl.dispose();
    _corCtrl.dispose(); _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do pet')));
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<PetProvider>();
    if (widget.pet != null) {
      final p = widget.pet!;
      p.nome       = _nomeCtrl.text.trim();
      p.especie    = _especie;
      p.raca       = _racaCtrl.text.trim();
      p.sexo       = _sexo;
      p.nascimento = _nascimento;
      p.peso       = double.tryParse(_pesoCtrl.text) ?? 0;
      p.castrado   = _castrado;
      p.cor        = _corCtrl.text.trim();
      p.notas      = _notasCtrl.text.trim();
      await provider.updatePet(p);
    } else {
      await provider.addPet(
        nome:       _nomeCtrl.text.trim(),
        especie:    _especie,
        raca:       _racaCtrl.text.trim(),
        sexo:       _sexo,
        nascimento: _nascimento,
        peso:       double.tryParse(_pesoCtrl.text) ?? 0,
        castrado:   _castrado,
        cor:        _corCtrl.text.trim(),
        notas:      _notasCtrl.text.trim(),
      );
    }
    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pet != null;
    return _ModalShell(
      title: isEdit ? 'Editar Pet' : 'Cadastrar Pet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(label: 'Nome do pet *', child: TextField(
            controller: _nomeCtrl,
            decoration: _dec('Ex: Rex, Mel, Bolinha...'),
          )),
          const SizedBox(height: 12),
          const _Label('Espécie'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _especies.map((e) {
              final sel = _especie == e.$1;
              return GestureDetector(
                onTap: () => setState(() => _especie = e.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFfff7ed) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? const Color(0xFFf97316) : AppColors.divider, width: sel ? 2 : 1),
                  ),
                  child: Text(e.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: sel ? const Color(0xFFea580c) : AppColors.textLight)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(label: 'Raça', child: TextField(controller: _racaCtrl, decoration: _dec('Ex: Labrador, SRD')))),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Sexo', child: DropdownButtonFormField<String>(
              value: _sexo,
              decoration: _dec(''),
              items: const [
                DropdownMenuItem(value: 'macho', child: Text('Macho')),
                DropdownMenuItem(value: 'femea', child: Text('Fêmea')),
              ],
              onChanged: (v) => setState(() => _sexo = v!),
            ))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(label: 'Nascimento', child: GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _nascimento ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _nascimento = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  _nascimento != null ? DateFormat('dd/MM/yyyy').format(_nascimento!) : 'Selecionar data',
                  style: TextStyle(fontSize: 14, color: _nascimento != null ? AppColors.textDark : AppColors.textLight),
                ),
              ),
            ))),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Peso (kg)', child: TextField(
              controller: _pesoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec('Ex: 4.5'),
            ))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(label: 'Cor / pelagem', child: TextField(controller: _corCtrl, decoration: _dec('Ex: Caramelo')))),
            const SizedBox(width: 16),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: GestureDetector(
                onTap: () => setState(() => _castrado = !_castrado),
                child: Row(children: [
                  Checkbox(
                    value: _castrado,
                    activeColor: const Color(0xFFf97316),
                    onChanged: (v) => setState(() => _castrado = v!),
                  ),
                  const Text('Castrado(a)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            )),
          ]),
          const SizedBox(height: 12),
          _Field(label: 'Notas', child: TextField(
            controller: _notasCtrl,
            maxLines: 2,
            decoration: _dec('Informações adicionais...'),
          )),
          const SizedBox(height: 20),
          _SaveBtn(saving: _saving, onSave: _salvar),
        ],
      ),
    );
  }
}

// ── Modal Vacina ──────────────────────────────────────────────────────────────

class _ModalVacina extends StatefulWidget {
  final String petId;
  const _ModalVacina({required this.petId});

  @override
  State<_ModalVacina> createState() => _ModalVacinaState();
}

class _ModalVacinaState extends State<_ModalVacina> {
  final _nomeCtrl = TextEditingController();
  final _vetCtrl  = TextEditingController();
  final _notasCtrl = TextEditingController();
  DateTime? _dataAplicacao;
  DateTime? _proximaDose;
  bool _saving = false;

  @override
  void dispose() {
    _nomeCtrl.dispose(); _vetCtrl.dispose(); _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty || _dataAplicacao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios')));
      return;
    }
    setState(() => _saving = true);
    await context.read<PetProvider>().addVacina(
      petId: widget.petId,
      nome: _nomeCtrl.text.trim(),
      dataAplicacao: _dataAplicacao!,
      proximaDose: _proximaDose,
      veterinario: _vetCtrl.text.trim(),
      notas: _notasCtrl.text.trim(),
    );
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _ModalShell(
      title: '💉 Registrar Vacina',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(label: 'Nome da vacina *', child: TextField(
            controller: _nomeCtrl,
            decoration: _dec('Ex: V10, Antirrábica, Giárdia...'),
          )),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(label: 'Data de aplicação *', child: _DatePicker(
              value: _dataAplicacao,
              hint: 'Selecionar',
              onPick: (d) => setState(() => _dataAplicacao = d),
            ))),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Próxima dose', child: _DatePicker(
              value: _proximaDose,
              hint: 'Opcional',
              onPick: (d) => setState(() => _proximaDose = d),
            ))),
          ]),
          const SizedBox(height: 12),
          _Field(label: 'Veterinário', child: TextField(controller: _vetCtrl, decoration: _dec('Dr(a). Nome'))),
          const SizedBox(height: 12),
          _Field(label: 'Notas', child: TextField(controller: _notasCtrl, maxLines: 2, decoration: _dec('Lote, observações...'))),
          const SizedBox(height: 20),
          _SaveBtn(saving: _saving, onSave: _salvar),
        ],
      ),
    );
  }
}

// ── Modal Consulta ────────────────────────────────────────────────────────────

class _ModalConsulta extends StatefulWidget {
  final String petId;
  const _ModalConsulta({required this.petId});

  @override
  State<_ModalConsulta> createState() => _ModalConsultaState();
}

class _ModalConsultaState extends State<_ModalConsulta> {
  final _motivoCtrl    = TextEditingController();
  final _vetCtrl       = TextEditingController();
  final _clinicaCtrl   = TextEditingController();
  final _diagCtrl      = TextEditingController();
  final _notasCtrl     = TextEditingController();
  DateTime? _data;
  DateTime? _proxima;
  bool _saving = false;

  @override
  void dispose() {
    _motivoCtrl.dispose(); _vetCtrl.dispose(); _clinicaCtrl.dispose();
    _diagCtrl.dispose(); _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_data == null || _motivoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios')));
      return;
    }
    setState(() => _saving = true);
    await context.read<PetProvider>().addConsulta(
      petId: widget.petId,
      data: _data!,
      motivo: _motivoCtrl.text.trim(),
      veterinario: _vetCtrl.text.trim(),
      clinica: _clinicaCtrl.text.trim(),
      diagnostico: _diagCtrl.text.trim(),
      proximaConsulta: _proxima,
      notas: _notasCtrl.text.trim(),
    );
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _ModalShell(
      title: '🩺 Registrar Consulta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _Field(label: 'Data *', child: _DatePicker(value: _data, hint: 'Selecionar', onPick: (d) => setState(() => _data = d)))),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Próxima consulta', child: _DatePicker(value: _proxima, hint: 'Opcional', onPick: (d) => setState(() => _proxima = d)))),
          ]),
          const SizedBox(height: 12),
          _Field(label: 'Motivo / Queixa *', child: TextField(controller: _motivoCtrl, decoration: _dec('Ex: Check-up, Dor na pata...'))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(label: 'Veterinário', child: TextField(controller: _vetCtrl, decoration: _dec('Dr(a). Nome')))),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Clínica', child: TextField(controller: _clinicaCtrl, decoration: _dec('Nome da clínica')))),
          ]),
          const SizedBox(height: 12),
          _Field(label: 'Diagnóstico / Tratamento', child: TextField(controller: _diagCtrl, maxLines: 2, decoration: _dec('Diagnóstico e tratamento...'))),
          const SizedBox(height: 12),
          _Field(label: 'Notas', child: TextField(controller: _notasCtrl, maxLines: 2, decoration: _dec('Observações...'))),
          const SizedBox(height: 20),
          _SaveBtn(saving: _saving, onSave: _salvar),
        ],
      ),
    );
  }
}

// ── Modal Medicamento ─────────────────────────────────────────────────────────

class _ModalMedicamento extends StatefulWidget {
  final String petId;
  const _ModalMedicamento({required this.petId});

  @override
  State<_ModalMedicamento> createState() => _ModalMedicamentoState();
}

class _ModalMedicamentoState extends State<_ModalMedicamento> {
  final _nomeCtrl  = TextEditingController();
  final _doseCtrl  = TextEditingController();
  final _freqCtrl  = TextEditingController();
  final _notasCtrl = TextEditingController();
  String _tipo = 'medicamento';
  DateTime? _inicio;
  DateTime? _fim;
  bool _saving = false;

  @override
  void dispose() {
    _nomeCtrl.dispose(); _doseCtrl.dispose(); _freqCtrl.dispose(); _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do medicamento')));
      return;
    }
    setState(() => _saving = true);
    await context.read<PetProvider>().addMedicamento(
      petId: widget.petId,
      nome: _nomeCtrl.text.trim(),
      tipo: _tipo,
      dose: _doseCtrl.text.trim(),
      frequencia: _freqCtrl.text.trim(),
      dataInicio: _inicio,
      dataFim: _fim,
      notas: _notasCtrl.text.trim(),
    );
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _ModalShell(
      title: '💊 Registrar Medicamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _Field(label: 'Nome *', child: TextField(controller: _nomeCtrl, decoration: _dec('Ex: Frontline, Simparic...')))),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Tipo', child: DropdownButtonFormField<String>(
              value: _tipo,
              decoration: _dec(''),
              items: const [
                DropdownMenuItem(value: 'medicamento', child: Text('Medicamento')),
                DropdownMenuItem(value: 'antipulgas',  child: Text('Antipulgas')),
                DropdownMenuItem(value: 'vermifugo',   child: Text('Vermífugo')),
                DropdownMenuItem(value: 'suplemento',  child: Text('Suplemento')),
                DropdownMenuItem(value: 'outro',       child: Text('Outro')),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
            ))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(label: 'Dose', child: TextField(controller: _doseCtrl, decoration: _dec('Ex: 1 comprimido')))),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Frequência', child: TextField(controller: _freqCtrl, decoration: _dec('Ex: Diário')))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(label: 'Data início', child: _DatePicker(value: _inicio, hint: 'Opcional', onPick: (d) => setState(() => _inicio = d)))),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Data fim', child: _DatePicker(value: _fim, hint: 'Opcional', onPick: (d) => setState(() => _fim = d)))),
          ]),
          const SizedBox(height: 12),
          _Field(label: 'Notas', child: TextField(controller: _notasCtrl, maxLines: 2, decoration: _dec('Observações...'))),
          const SizedBox(height: 20),
          _SaveBtn(saving: _saving, onSave: _salvar),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares dos modais ──────────────────────────────────────────────

class _ModalShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _ModalShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 16),
          SingleChildScrollView(child: child),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight));
  }
}

InputDecoration _dec(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
  filled: true,
  fillColor: const Color(0xFFF5F7FA),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.divider)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFf97316))),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
);

class _DatePicker extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final void Function(DateTime) onPick;
  const _DatePicker({required this.value, required this.hint, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2035),
        );
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textLight),
            const SizedBox(width: 6),
            Text(
              value != null ? DateFormat('dd/MM/yyyy').format(value!) : hint,
              style: TextStyle(fontSize: 13, color: value != null ? AppColors.textDark : AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveBtn extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  const _SaveBtn({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: saving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf97316),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

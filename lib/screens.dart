import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'state.dart';

const _accent = Color(0xFF00E5CC);
const _cardColor = Color(0xFF1E1E2C);
const _bg = Color(0xFF12121C);

// ═══════════════════════════════════════════════════════════════════════════
// Levels Screen
// ═══════════════════════════════════════════════════════════════════════════

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});
  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filteredLevels = state.levels
        .where((l) => l.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    final ungrouped = filteredLevels.where((l) => l.groupId == null).toList();
    final groupedMap = <String, List<Level>>{};
    for (var g in state.groups) {
      groupedMap[g.id] = filteredLevels
          .where((l) => l.groupId == g.id)
          .toList();
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _SearchBar(
            onChanged: (v) => setState(() => _search = v),
            onAction: () => _showAddGroup(context),
            actionIcon: Icons.folder_outlined,
            actionTooltip: 'Add Group',
          ),
          Expanded(
            child: state.levels.isEmpty
                ? _empty('No levels yet.\nTap + to add a class or grade.')
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...state.groups.map(
                        (g) => _GroupCard(
                          group: g,
                          levels: groupedMap[g.id] ?? [],
                          allLevels: state.levels,
                          state: state,
                        ),
                      ),
                      if (ungrouped.isNotEmpty) ...[
                        if (state.groups.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8, bottom: 4),
                            child: Text(
                              'Ungrouped',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ...ungrouped.map(
                          (level) => _LevelCard(level: level, state: state),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        onPressed: () => _showAddLevel(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddGroup(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _Dialog(
        title: 'Add Group',
        fields: [_field(nameCtrl, 'Group name (e.g. Standard 1)')],
        onSave: () {
          if (nameCtrl.text.trim().isEmpty) return;
          ctx.read<AppState>().addGroup(
            LevelGroup(id: UniqueKey().toString(), name: nameCtrl.text.trim()),
          );
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showAddLevel(BuildContext context) {
    final state = context.read<AppState>();
    final nameCtrl = TextEditingController();
    final periodsCtrl = TextEditingController(text: '6');
    String? selectedGroupId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Add Level',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Level name (e.g. 1A)'),
                const SizedBox(height: 10),
                _field(periodsCtrl, 'Periods per day', isNumber: true),
                if (state.groups.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    dropdownColor: _cardColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDec('Assign to group (optional)'),
                    value: selectedGroupId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('— No group —'),
                      ),
                      ...state.groups.map(
                        (g) =>
                            DropdownMenuItem(value: g.id, child: Text(g.name)),
                      ),
                    ],
                    onChanged: (v) => setS(() => selectedGroupId = v),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final ppd = int.tryParse(periodsCtrl.text) ?? 6;
                  ctx.read<AppState>().addLevel(
                    Level(
                      id: UniqueKey().toString(),
                      name: nameCtrl.text.trim(),
                      groupId: selectedGroupId,
                      periodsPerDay: ppd.clamp(1, kPeriodsPerDay),
                    ),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Group Card
// ═══════════════════════════════════════════════════════════════════════════

class _GroupCard extends StatelessWidget {
  final LevelGroup group;
  final List<Level> levels;
  final List<Level> allLevels;
  final AppState state;

  const _GroupCard({
    required this.group,
    required this.levels,
    required this.allLevels,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _accent.withOpacity(0.25)),
      ),
      child: ExpansionTile(
        iconColor: _accent,
        collapsedIconColor: Colors.white54,
        leading: const Icon(Icons.folder_outlined, color: _accent),
        title: Text(
          group.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${levels.length} divisions',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            if (group.allowedTeacherIds.isNotEmpty)
              Text(
                '${group.allowedTeacherIds.length} group teachers assigned',
                style: TextStyle(color: _accent.withOpacity(0.7), fontSize: 11),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.people_alt_outlined,
                color: _accent,
                size: 18,
              ),
              tooltip: 'Assign teachers to group',
              onPressed: () => _showTeacherPicker(context),
            ),
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.white54,
                size: 18,
              ),
              onPressed: () => _renameGroup(context),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 18,
              ),
              onPressed: () => state.removeGroup(group.id),
            ),
            const Icon(Icons.expand_more, color: Colors.white54),
          ],
        ),
        children: [
          ...levels.map(
            (level) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _LevelCard(level: level, state: state),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Assign existing level to this group'),
              onPressed: () => _assignLevel(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showTeacherPicker(BuildContext context) {
    final selected = Set<String>.from(group.allowedTeacherIds);
    String search = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final visible = state.teachers
              .where(
                (t) =>
                    t.name.toLowerCase().contains(search.toLowerCase()) ||
                    t.employeeId.toLowerCase().contains(search.toLowerCase()),
              )
              .toList();
          return AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Group Teachers',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Teachers allowed in "${group.name}"',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _infoChip(
                    'Leave empty to allow all qualified teachers. '
                    'Group teachers are inherited by all levels in this group.',
                  ),
                  const SizedBox(height: 10),
                  _teacherSearchBox(search, (v) => setState(() => search = v)),
                  const SizedBox(height: 6),
                  _teacherCheckList(visible, selected, ctx, setState),
                ],
              ),
            ),
            actions: [
              if (selected.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => selected.clear()),
                  child: const Text(
                    'Clear all',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  ctx.read<AppState>().updateGroupAllowedTeachers(
                    group.id,
                    selected.toList(),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _renameGroup(BuildContext context) {
    final ctrl = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (ctx) => _Dialog(
        title: 'Rename Group',
        fields: [_field(ctrl, 'Group name')],
        onSave: () {
          if (ctrl.text.trim().isEmpty) return;
          ctx.read<AppState>().renameGroup(group.id, ctrl.text.trim());
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _assignLevel(BuildContext context) {
    final unassigned = allLevels.where((l) => l.groupId == null).toList();
    if (unassigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ungrouped levels available.')),
      );
      return;
    }
    String? chosen = unassigned.first.id;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Assign Level to Group',
              style: TextStyle(color: Colors.white),
            ),
            content: DropdownButtonFormField<String>(
              dropdownColor: _cardColor,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDec('Level'),
              value: chosen,
              items: unassigned
                  .map(
                    (l) => DropdownMenuItem(value: l.id, child: Text(l.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => chosen = v),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  if (chosen != null)
                    ctx.read<AppState>().setLevelGroup(chosen!, group.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Assign'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Level Card
// ═══════════════════════════════════════════════════════════════════════════

class _LevelCard extends StatelessWidget {
  final Level level;
  final AppState state;

  const _LevelCard({required this.level, required this.state});

  @override
  Widget build(BuildContext context) {
    final allowedSet = <String>{...level.allowedTeacherIds};
    if (level.groupId != null) {
      try {
        allowedSet.addAll(
          state.groups
              .firstWhere((g) => g.id == level.groupId)
              .allowedTeacherIds,
        );
      } catch (_) {}
    }

    return Card(
      color: _cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        iconColor: _accent,
        collapsedIconColor: Colors.white54,
        title: Text(
          level.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${level.subjects.length} subjects · ${level.periodsPerDay} periods/day',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (allowedSet.isNotEmpty)
              Text(
                '${allowedSet.length} teachers assigned',
                style: TextStyle(color: _accent.withOpacity(0.7), fontSize: 11),
              )
            else
              Text(
                'All qualified teachers allowed',
                style: TextStyle(
                  color: Colors.white38.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.people_alt_outlined,
                color: _accent,
                size: 18,
              ),
              tooltip: 'Assign teachers to level',
              onPressed: () => _showTeacherPicker(context),
            ),
            IconButton(
              icon: const Icon(Icons.tune, color: Colors.white54, size: 18),
              tooltip: 'Edit level',
              onPressed: () => _editLevel(context),
            ),
            if (level.groupId != null)
              IconButton(
                icon: const Icon(
                  Icons.folder_off_outlined,
                  color: Colors.white38,
                  size: 18,
                ),
                tooltip: 'Remove from group',
                onPressed: () =>
                    context.read<AppState>().setLevelGroup(level.id, null),
              ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () => context.read<AppState>().removeLevel(level.id),
            ),
            const Icon(Icons.expand_more, color: Colors.white54),
          ],
        ),
        children: [
          ...level.subjects.map(
            (s) => ListTile(
              dense: true,
              leading: const Icon(
                Icons.book_outlined,
                color: _accent,
                size: 18,
              ),
              title: Text(
                s.name,
                style: const TextStyle(color: Colors.white70),
              ),
              subtitle: Text(
                '${s.hoursPerWeek.toStringAsFixed(s.hoursPerWeek == s.hoursPerWeek.roundToDouble() ? 0 : 1)} hrs/week',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
                onPressed: () => context
                    .read<AppState>()
                    .removeSubjectFromLevel(level.id, s.id),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: const BorderSide(color: _accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Subject'),
                    onPressed: () => _showAddSubject(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('Copy from'),
                    onPressed: () => _showCopyFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTeacherPicker(BuildContext context) {
    final selected = Set<String>.from(level.allowedTeacherIds);
    String search = '';
    Set<String> groupTeachers = {};
    if (level.groupId != null) {
      try {
        groupTeachers = state.groups
            .firstWhere((g) => g.id == level.groupId)
            .allowedTeacherIds
            .toSet();
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final visible = state.teachers
              .where(
                (t) =>
                    t.name.toLowerCase().contains(search.toLowerCase()) ||
                    t.employeeId.toLowerCase().contains(search.toLowerCase()),
              )
              .toList();

          return AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Level Teachers',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Teachers allowed in "${level.name}"',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _infoChip(
                    'Leave empty to allow all qualified teachers. '
                    'Teachers marked ★ are already allowed via the group.',
                  ),
                  const SizedBox(height: 10),
                  _teacherSearchBox(search, (v) => setState(() => search = v)),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12121C),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: visible.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'No teachers match.',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: visible.length,
                            itemBuilder: (_, i) {
                              final t = visible[i];
                              final isGroup = groupTeachers.contains(t.id);
                              final isSelected =
                                  selected.contains(t.id) || isGroup;
                              return InkWell(
                                onTap: isGroup
                                    ? null
                                    : () => setState(() {
                                        if (selected.contains(t.id)) {
                                          selected.remove(t.id);
                                        } else {
                                          selected.add(t.id);
                                        }
                                      }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  child: Row(
                                    children: [
                                      _checkbox(isSelected),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          t.name,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white70,
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isGroup)
                                        _chip('★ group')
                                      else
                                        Text(
                                          'ID: ${t.employeeId}',
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (selected.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${selected.length + groupTeachers.difference(selected).length} effective '
                      '(${selected.length} level + ${groupTeachers.length} group)',
                      style: TextStyle(
                        color: _accent.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (selected.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => selected.clear()),
                  child: const Text(
                    'Clear level teachers',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  ctx.read<AppState>().updateLevelAllowedTeachers(
                    level.id,
                    selected.toList(),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editLevel(BuildContext context) {
    final nameCtrl = TextEditingController(text: level.name);
    final periodsCtrl = TextEditingController(
      text: level.periodsPerDay.toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => _Dialog(
        title: 'Edit Level — ${level.name}',
        fields: [
          _field(nameCtrl, 'Level name'),
          _field(periodsCtrl, 'Periods per day', isNumber: true),
        ],
        onSave: () {
          final newName = nameCtrl.text.trim();
          if (newName.isEmpty) return;
          final val = int.tryParse(periodsCtrl.text) ?? level.periodsPerDay;
          ctx.read<AppState>().updateLevel(
            Level(
              id: level.id,
              name: newName,
              subjects: level.subjects,
              groupId: level.groupId,
              periodsPerDay: val.clamp(1, kPeriodsPerDay),
              allowedTeacherIds: level.allowedTeacherIds,
            ),
          );
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showAddSubject(BuildContext context) {
    final nameCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '3');
    showDialog(
      context: context,
      builder: (ctx) => _Dialog(
        title: 'Add Subject to ${level.name}',
        fields: [
          _field(nameCtrl, 'Subject name'),
          _field(hoursCtrl, 'Hours per week', isNumber: true, isDecimal: true),
        ],
        onSave: () {
          if (nameCtrl.text.trim().isEmpty) return;
          final hrs = double.tryParse(hoursCtrl.text) ?? 3.0;
          ctx.read<AppState>().addSubjectToLevel(
            level.id,
            Subject(
              id: UniqueKey().toString(),
              name: nameCtrl.text.trim(),
              hoursPerWeek: hrs.clamp(0.5, 99),
            ),
          );
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showCopyFrom(BuildContext context) {
    final sources = state.levels
        .where((l) => l.id != level.id && l.subjects.isNotEmpty)
        .toList();
    if (sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other levels with subjects found.')),
      );
      return;
    }
    Level? selected = sources.first;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final preview = selected?.subjects ?? [];
          return AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Copy subjects from…',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Level>(
                    dropdownColor: _cardColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDec('Source level'),
                    value: selected,
                    items: sources
                        .map(
                          (l) =>
                              DropdownMenuItem(value: l, child: Text(l.name)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                  const SizedBox(height: 14),
                  if (preview.isNotEmpty) ...[
                    const Text(
                      'Subjects to copy:',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: Column(
                          children: preview
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.book_outlined,
                                        color: _accent,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          s.name,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${s.hoursPerWeek.toStringAsFixed(1)} h/w',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duplicates (by name) will be skipped.',
                      style: TextStyle(
                        color: Colors.white38.withOpacity(0.7),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text('Copy'),
                onPressed: () {
                  if (selected != null) {
                    ctx.read<AppState>().copySubjectsFromLevel(
                      level.id,
                      selected!,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green.shade800,
                        content: Text(
                          'Subjects copied from ${selected!.name} to ${level.name}.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared teacher picker helpers
// ═══════════════════════════════════════════════════════════════════════════

Widget _infoChip(String text) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: _accent.withOpacity(0.08),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _accent.withOpacity(0.25)),
  ),
  child: Row(
    children: [
      Icon(Icons.info_outline, color: _accent.withOpacity(0.7), size: 14),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ),
    ],
  ),
);

Widget _chip(String label) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(
    color: _accent.withOpacity(0.15),
    borderRadius: BorderRadius.circular(6),
  ),
  child: Text(
    label,
    style: TextStyle(color: _accent.withOpacity(0.8), fontSize: 10),
  ),
);

Widget _checkbox(bool checked) => AnimatedContainer(
  duration: const Duration(milliseconds: 150),
  width: 18,
  height: 18,
  decoration: BoxDecoration(
    color: checked ? _accent : Colors.transparent,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: checked ? _accent : Colors.white38),
  ),
  child: checked
      ? const Icon(Icons.check, size: 12, color: Colors.black)
      : null,
);

Widget _teacherSearchBox(String current, ValueChanged<String> onChanged) =>
    TextField(
      style: const TextStyle(color: Colors.white, fontSize: 13),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search teachers...',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
        filled: true,
        fillColor: const Color(0xFF12121C),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
    );

Widget _teacherCheckList(
  List<Teacher> teachers,
  Set<String> selected,
  BuildContext ctx,
  StateSetter setState,
) {
  return Container(
    constraints: const BoxConstraints(maxHeight: 260),
    decoration: BoxDecoration(
      color: const Color(0xFF12121C),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white12),
    ),
    child: teachers.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No teachers match.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: teachers.length,
            itemBuilder: (_, i) {
              final t = teachers[i];
              final isSelected = selected.contains(t.id);
              return InkWell(
                onTap: () => setState(
                  () => isSelected ? selected.remove(t.id) : selected.add(t.id),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      _checkbox(isSelected),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        'ID: ${t.employeeId}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Teachers Screen
// ═══════════════════════════════════════════════════════════════════════════

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});
  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filtered = state.teachers
        .where(
          (t) =>
              t.name.toLowerCase().contains(_search.toLowerCase()) ||
              t.employeeId.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();

    final seen = <String>{};
    final allSubjects = state.levels
        .expand((l) => l.subjects)
        .where((s) => seen.add(s.name.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _SearchBar(onChanged: (v) => setState(() => _search = v)),
          Expanded(
            child: filtered.isEmpty
                ? _empty(
                    state.teachers.isEmpty
                        ? 'No teachers yet.\nTap + to add a teacher.'
                        : 'No results found.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _TeacherCard(
                      teacher: filtered[i],
                      allSubjects: allSubjects,
                      state: state,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        onPressed: () => _showTeacherDialog(context, null, allSubjects, state),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTeacherDialog(
    BuildContext context,
    Teacher? existing,
    List<Subject> allSubjects,
    AppState state,
  ) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final idCtrl = TextEditingController(text: existing?.employeeId ?? '');
    final hoursCtrl = TextEditingController(
      text: existing?.maxHoursPerWeek.toString() ?? '20',
    );

    final seen = <String>{};
    final unique = <Subject>[];
    for (final s in allSubjects) {
      final key = s.name.trim().toLowerCase();
      if (seen.add(key)) unique.add(s);
    }

    final nameToIds = <String, List<String>>{};
    for (final s in allSubjects) {
      nameToIds.putIfAbsent(s.name.trim().toLowerCase(), () => []).add(s.id);
    }

    bool nameSelected(String nl) =>
        nameToIds[nl]?.any(
          (id) => existing?.subjectIds.contains(id) ?? false,
        ) ??
        false;

    final selectedNames = <String>{
      for (final s in unique)
        if (nameSelected(s.name.trim().toLowerCase()))
          s.name.trim().toLowerCase(),
    };

    String? idError;
    String subSearch = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final visible = unique
              .where(
                (s) => s.name.toLowerCase().contains(subSearch.toLowerCase()),
              )
              .toList();
          return AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              existing == null ? 'Add Teacher' : 'Edit Teacher',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(nameCtrl, 'Full name'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: idCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDec('Employee ID').copyWith(
                        errorText: idError,
                        errorStyle: const TextStyle(color: Colors.redAccent),
                      ),
                      onChanged: (_) => setState(() => idError = null),
                    ),
                    const SizedBox(height: 10),
                    _field(hoursCtrl, 'Max hours/week', isNumber: true),
                    if (unique.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Can teach:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          if (selectedNames.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _accent.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                '${selectedNames.length} selected',
                                style: const TextStyle(
                                  color: _accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _teacherSearchBox(
                        subSearch,
                        (v) => setState(() => subSearch = v),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12121C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: visible.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'No subjects match.',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: visible.length,
                                itemBuilder: (_, i) {
                                  final s = visible[i];
                                  final key = s.name.trim().toLowerCase();
                                  final sel = selectedNames.contains(key);
                                  return InkWell(
                                    onTap: () => setState(
                                      () => sel
                                          ? selectedNames.remove(key)
                                          : selectedNames.add(key),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          _checkbox(sel),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              s.name,
                                              style: TextStyle(
                                                color: sel
                                                    ? Colors.white
                                                    : Colors.white70,
                                                fontSize: 13,
                                                fontWeight: sel
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final empId = idCtrl.text.trim();
                  if (state.employeeIdExists(
                    empId,
                    excludeTeacherId: existing?.id,
                  )) {
                    setState(() => idError = 'Employee ID already exists');
                    return;
                  }
                  final resolved = <String>{};
                  for (final name in selectedNames) {
                    nameToIds[name]?.forEach(resolved.add);
                  }
                  final teacher = Teacher(
                    id: existing?.id ?? UniqueKey().toString(),
                    name: nameCtrl.text.trim(),
                    employeeId: empId,
                    maxHoursPerWeek: int.tryParse(hoursCtrl.text) ?? 20,
                    subjectIds: resolved.toList(),
                  );
                  if (existing == null) {
                    ctx.read<AppState>().addTeacher(teacher);
                  } else {
                    ctx.read<AppState>().updateTeacher(teacher);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final List<Subject> allSubjects;
  final AppState state;

  const _TeacherCard({
    required this.teacher,
    required this.allSubjects,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final subjectNames = state.teacherSubjectNames(teacher.id).toList();
    return Card(
      color: _cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _accent.withOpacity(0.15),
          child: Text(
            teacher.name[0].toUpperCase(),
            style: const TextStyle(color: _accent, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          teacher.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${teacher.employeeId} · Max ${teacher.maxHoursPerWeek}h/week',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (subjectNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: subjectNames.map((name) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'No subjects assigned',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: () {
                final seen = <String>{};
                final subs = state.levels
                    .expand((l) => l.subjects)
                    .where((s) => seen.add(s.name.toLowerCase()))
                    .toList();
                _TeachersScreenState()._showTeacherDialog(
                  context,
                  teacher,
                  subs,
                  state,
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () =>
                  context.read<AppState>().removeTeacher(teacher.id),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Timetable Screen
// ═══════════════════════════════════════════════════════════════════════════

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String? _selectedLevelId;
  bool _showTeacher = false;
  String _levelSearch = '';
  bool _searchExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.levels.isEmpty) return _empty('Add levels first.');

    if (_selectedLevelId == null ||
        !state.levels.any((l) => l.id == _selectedLevelId)) {
      _selectedLevelId = state.levels.first.id;
    }

    final level = state.levels.firstWhere((l) => l.id == _selectedLevelId);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildControls(state, level),
          Expanded(child: _buildGrid(state, level)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'auto',
            backgroundColor: _accent,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Auto-Schedule'),
            onPressed: () => _confirmAndGenerate(context, state, level),
          ),
        ],
      ),
    );
  }

  // ── Timing dialog ─────────────────────────────────────────────────────────

  void _showTimingDialog(BuildContext context, AppState state, Level level) {
    final existing = state.dayTiming;
    TimeOfDay startTime = existing != null
        ? TimeOfDay(hour: existing.startHour, minute: existing.startMinute)
        : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = existing != null
        ? TimeOfDay(hour: existing.endHour, minute: existing.endMinute)
        : const TimeOfDay(hour: 14, minute: 0);
    final breakCtrl = TextEditingController(
      text: existing?.breakMinutes.toString() ?? '0',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          // Preview: compute period duration
          final startMins = startTime.hour * 60 + startTime.minute;
          final endMins = endTime.hour * 60 + endTime.minute;
          final breakMins = int.tryParse(breakCtrl.text) ?? 0;
          final totalMins = endMins - startMins;
          final ppd = level.periodsPerDay;
          final usable = totalMins - breakMins * (ppd - 1);
          final periodDur = ppd > 0 ? (usable / ppd).floor() : 0;

          return AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.schedule, color: _accent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Period Timings',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoChip(
                    'Set the school day start & end time. '
                    'Periods are calculated automatically and shown in the timetable.',
                  ),
                  const SizedBox(height: 16),
                  // Start time
                  _timingRow(
                    label: 'Day starts at',
                    time: startTime,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: startTime,
                        builder: (c, child) => _timePickerTheme(c, child),
                      );
                      if (picked != null) setState(() => startTime = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  // End time
                  _timingRow(
                    label: 'Day ends at',
                    time: endTime,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: endTime,
                        builder: (c, child) => _timePickerTheme(c, child),
                      );
                      if (picked != null) setState(() => endTime = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Break
                  Row(
                    children: [
                      const Text(
                        'Break between periods',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 64,
                        child: TextField(
                          controller: breakCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            isDense: true,
                            suffix: const Text(
                              'min',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: _accent),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Preview
                  if (totalMins > 0 && ppd > 0 && periodDur > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _accent.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preview — ${level.name} ($ppd periods/day)',
                            style: TextStyle(
                              color: _accent.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...List.generate(ppd, (i) {
                            final tmpTiming = DayTiming(
                              startHour: startTime.hour,
                              startMinute: startTime.minute,
                              endHour: endTime.hour,
                              endMinute: endTime.minute,
                              breakMinutes: breakMins,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  Text(
                                    'P${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${tmpTiming.periodStartLabel(i, ppd)} – ${tmpTiming.periodEndLabel(i, ppd)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (breakMins > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '+ $breakMins min break between each period',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ] else if (totalMins <= 0) ...[
                    Text(
                      'End time must be after start time.',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (state.dayTiming != null)
                TextButton(
                  onPressed: () {
                    ctx.read<AppState>().setDayTiming(
                      DayTiming(
                        startHour: 0,
                        startMinute: 0,
                        endHour: 0,
                        endMinute: 0,
                      ),
                    );
                    // Clear by setting null-equivalent — we'll treat 0-duration as "not set"
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: totalMins > 0 && periodDur > 0
                    ? () {
                        final bm = int.tryParse(breakCtrl.text) ?? 0;
                        ctx.read<AppState>().setDayTiming(
                          DayTiming(
                            startHour: startTime.hour,
                            startMinute: startTime.minute,
                            endHour: endTime.hour,
                            endMinute: endTime.minute,
                            breakMinutes: bm,
                          ),
                        );
                        Navigator.pop(ctx);
                      }
                    : null,
                child: const Text('Save Timings'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _timingRow({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _accent.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: _accent, size: 15),
                const SizedBox(width: 6),
                Text(
                  '$h:$m',
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _timePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          onPrimary: Colors.black,
          surface: _cardColor,
          onSurface: Colors.white,
        ),
        dialogBackgroundColor: _cardColor,
      ),
      child: child!,
    );
  }

  Future<void> _confirmAndGenerate(
    BuildContext context,
    AppState state,
    Level level,
  ) async {
    final hasExisting = state.timetable.any((s) => s.levelId == level.id);
    if (hasExisting) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Regenerate Timetable?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'This will clear the existing timetable for "${level.name}" '
            'and reassign from scratch. Other classes are NOT affected.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Regenerate'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final result = state.generateTimetableForLevel(level.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: result == null
            ? Colors.green.shade800
            : Colors.red.shade800,
        content: Text(result ?? 'Timetable generated for ${level.name}!'),
      ),
    );
  }

  Widget _buildControls(AppState state, Level current) {
    return Container(
      color: _cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _searchExpanded
                    ? TextField(
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (v) {
                          setState(() => _levelSearch = v);
                          final matches = state.levels
                              .where(
                                (l) => l.name.toLowerCase().contains(
                                  v.toLowerCase(),
                                ),
                              )
                              .toList();
                          if (matches.isNotEmpty) {
                            setState(() => _selectedLevelId = matches.first.id);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Search class...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white38,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF12121C),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white38,
                              size: 18,
                            ),
                            onPressed: () => setState(() {
                              _searchExpanded = false;
                              _levelSearch = '';
                            }),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              dropdownColor: _cardColor,
                              value: _selectedLevelId,
                              isExpanded: true,
                              style: const TextStyle(color: Colors.white),
                              underline: const SizedBox(),
                              items: state.levels
                                  .map(
                                    (l) => DropdownMenuItem(
                                      value: l.id,
                                      child: Text(l.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedLevelId = v),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.search,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _searchExpanded = true),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 4),
              Row(
                children: [
                  const Text(
                    'Teacher',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  Switch(
                    value: _showTeacher,
                    activeColor: _accent,
                    onChanged: (v) => setState(() => _showTeacher = v),
                  ),
                ],
              ),
              // ── 3-dot menu ──────────────────────────────────────────────
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                color: _cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'timing') {
                    _showTimingDialog(
                      context,
                      context.read<AppState>(),
                      current,
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'timing',
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: _accent, size: 18),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Period Timings',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              context.read<AppState>().dayTiming != null &&
                                      context
                                              .read<AppState>()
                                              .dayTiming!
                                              .totalMinutes >
                                          0
                                  ? 'Configured'
                                  : 'Not set',
                              style: TextStyle(
                                color: _accent.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_searchExpanded && _levelSearch.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: state.levels
                    .where(
                      (l) => l.name.toLowerCase().contains(
                        _levelSearch.toLowerCase(),
                      ),
                    )
                    .map(
                      (l) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            l.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: _selectedLevelId == l.id,
                          selectedColor: _accent,
                          backgroundColor: const Color(0xFF12121C),
                          labelStyle: TextStyle(
                            color: _selectedLevelId == l.id
                                ? Colors.black
                                : Colors.white70,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedLevelId = l.id),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(AppState state, Level level) {
    final ppd = level.periodsPerDay;
    final timing = state.dayTiming;
    final hasTiming = timing != null && timing.totalMinutes > 0;

    return SingleChildScrollView(
      key: ValueKey('${level.id}_$_showTeacher'),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Table(
            border: TableBorder.all(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            defaultColumnWidth: const FixedColumnWidth(110),
            children: [
              // Header row: Period | Mon | Tue | ...
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF1A1A2E)),
                children: [_headerCell('Period'), ...kDays.map(_headerCell)],
              ),
              // One row per period
              ...List.generate(ppd, (p) {
                return TableRow(
                  children: [
                    // Period label + optional time
                    _periodLabelCell(p, ppd, hasTiming ? timing : null),
                    ...List.generate(kDays.length, (d) {
                      final slot = state.getSlot(level.id, d, p);
                      return _SlotCell(
                        key: ValueKey('${level.id}_${d}_${p}_$_showTeacher'),
                        slot: slot,
                        level: level,
                        state: state,
                        day: d,
                        period: p,
                        showTeacher: _showTeacher,
                        onTap: () =>
                            _editSlot(context, state, level, d, p, slot),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _editSlot(
    BuildContext context,
    AppState state,
    Level level,
    int day,
    int period,
    TimetableSlot? current,
  ) {
    String? subjectId = current?.subjectId;
    String? teacherId = current?.teacherId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Edit ${kDays[day]} · Period ${period + 1}',
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  dropdownColor: _cardColor,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDec('Subject'),
                  value: subjectId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('— None —'),
                    ),
                    ...level.subjects.map(
                      (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => subjectId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  dropdownColor: _cardColor,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDec('Teacher'),
                  value: teacherId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('— None —'),
                    ),
                    ...state.teachers.map(
                      (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => teacherId = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  final err = ctx.read<AppState>().editSlot(
                    level.id,
                    day,
                    period,
                    subjectId,
                    teacherId,
                  );
                  Navigator.pop(ctx);
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red.shade800,
                        content: Text(err),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Period label cell — shows P1 and optionally the time range below
// ═══════════════════════════════════════════════════════════════════════════

Widget _periodLabelCell(int periodIndex, int periodsPerDay, DayTiming? timing) {
  final start = timing?.periodStartLabel(periodIndex, periodsPerDay);
  final end = timing?.periodEndLabel(periodIndex, periodsPerDay);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'P${periodIndex + 1}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (start != null && end != null) ...[
          const SizedBox(height: 3),
          Text(
            start,
            textAlign: TextAlign.center,
            style: TextStyle(color: _accent.withOpacity(0.7), fontSize: 9),
          ),
          Text(
            end,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38.withOpacity(0.7),
              fontSize: 9,
            ),
          ),
        ],
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Slot Cell
// ═══════════════════════════════════════════════════════════════════════════

class _SlotCell extends StatelessWidget {
  final TimetableSlot? slot;
  final Level level;
  final AppState state;
  final int day, period;
  final bool showTeacher;
  final VoidCallback onTap;

  const _SlotCell({
    super.key,
    required this.slot,
    required this.level,
    required this.state,
    required this.day,
    required this.period,
    required this.showTeacher,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Subject? subject;
    Teacher? teacher;
    if (slot?.subjectId != null) {
      try {
        subject = level.subjects.firstWhere((s) => s.id == slot!.subjectId);
      } catch (_) {}
    }
    if (slot?.teacherId != null) {
      try {
        teacher = state.teachers.firstWhere((t) => t.id == slot!.teacherId);
      } catch (_) {}
    }

    final unassigned = subject != null && teacher == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: subject != null
              ? (unassigned
                    ? Colors.orange.withOpacity(0.08)
                    : _accent.withOpacity(0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: subject != null
                ? (unassigned
                      ? Colors.orange.withOpacity(0.4)
                      : _accent.withOpacity(0.3))
                : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: subject == null
            ? const Icon(Icons.add, color: Colors.white12, size: 16)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subject.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: unassigned ? Colors.orange : _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showTeacher)
                    Text(
                      teacher?.name ?? '—',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: teacher != null
                            ? Colors.white54
                            : Colors.orange.withOpacity(0.7),
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Teacher Schedule Screen
// ═══════════════════════════════════════════════════════════════════════════

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});
  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  String? _selectedTeacherId;
  String _search = '';
  bool _searchExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.teachers.isEmpty) return _empty('Add teachers first.');

    if (_selectedTeacherId == null ||
        !state.teachers.any((t) => t.id == _selectedTeacherId)) {
      _selectedTeacherId = state.teachers.first.id;
    }

    final teacher = state.teachers.firstWhere(
      (t) => t.id == _selectedTeacherId,
    );
    final slots = state.getTeacherSlots(teacher.id);
    final timing = state.dayTiming;
    final hasTiming = timing != null && timing.totalMinutes > 0;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Container(
            color: _cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _searchExpanded
                          ? TextField(
                              autofocus: true,
                              style: const TextStyle(color: Colors.white),
                              onChanged: (v) {
                                setState(() => _search = v);
                                final matches = state.teachers
                                    .where(
                                      (t) =>
                                          t.name.toLowerCase().contains(
                                            v.toLowerCase(),
                                          ) ||
                                          t.employeeId.toLowerCase().contains(
                                            v.toLowerCase(),
                                          ),
                                    )
                                    .toList();
                                if (matches.isNotEmpty) {
                                  setState(
                                    () => _selectedTeacherId = matches.first.id,
                                  );
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by name or ID...',
                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF12121C),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white38,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(() {
                                    _searchExpanded = false;
                                    _search = '';
                                  }),
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: DropdownButton<String>(
                                    dropdownColor: _cardColor,
                                    value: _selectedTeacherId,
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.white),
                                    underline: const SizedBox(),
                                    items: state.teachers
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t.id,
                                            child: Text(
                                              '${t.name}  ·  ${t.employeeId}',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedTeacherId = v),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _searchExpanded = true),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                if (_searchExpanded && _search.isNotEmpty)
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: state.teachers
                          .where(
                            (t) =>
                                t.name.toLowerCase().contains(
                                  _search.toLowerCase(),
                                ) ||
                                t.employeeId.toLowerCase().contains(
                                  _search.toLowerCase(),
                                ),
                          )
                          .map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(
                                  '${t.name} (${t.employeeId})',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                selected: _selectedTeacherId == t.id,
                                selectedColor: _accent,
                                backgroundColor: const Color(0xFF12121C),
                                labelStyle: TextStyle(
                                  color: _selectedTeacherId == t.id
                                      ? Colors.black
                                      : Colors.white70,
                                ),
                                onSelected: (_) =>
                                    setState(() => _selectedTeacherId = t.id),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                if (!_searchExpanded || _search.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          color: _accent,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ID: ${teacher.employeeId}',
                          style: const TextStyle(color: _accent, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.schedule,
                          color: Colors.white38,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${slots.length} periods assigned',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: slots.isEmpty
                ? _empty('No periods assigned to ${teacher.name} yet.')
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: kDays.asMap().entries.map((entry) {
                        final dayIndex = entry.key;
                        final dayName = entry.value;
                        final daySlots =
                            slots.where((s) => s.day == dayIndex).toList()
                              ..sort((a, b) => a.period.compareTo(b.period));
                        if (daySlots.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: _accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _accent.withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  dayName,
                                  style: const TextStyle(
                                    color: _accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Table(
                                  border: TableBorder.all(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  columnWidths: {
                                    0: const FixedColumnWidth(55),
                                    if (hasTiming)
                                      1: const FixedColumnWidth(100),
                                    if (hasTiming)
                                      2: const FlexColumnWidth()
                                    else
                                      1: const FlexColumnWidth(),
                                    if (hasTiming)
                                      3: const FlexColumnWidth()
                                    else
                                      2: const FlexColumnWidth(),
                                  },
                                  children: [
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1A1A2E),
                                      ),
                                      children: [
                                        _headerCell('Per.'),
                                        if (hasTiming) _headerCell('Time'),
                                        _headerCell('Subject'),
                                        _headerCell('Class'),
                                      ],
                                    ),
                                    ...daySlots.map((s) {
                                      Level? lvl;
                                      Subject? sub;
                                      try {
                                        lvl = state.levels.firstWhere(
                                          (l) => l.id == s.levelId,
                                        );
                                      } catch (_) {}
                                      try {
                                        sub = lvl?.subjects.firstWhere(
                                          (su) => su.id == s.subjectId,
                                        );
                                      } catch (_) {}

                                      String? timeLabel;
                                      if (hasTiming && lvl != null) {
                                        final st = timing.periodStartLabel(
                                          s.period,
                                          lvl.periodsPerDay,
                                        );
                                        final en = timing.periodEndLabel(
                                          s.period,
                                          lvl.periodsPerDay,
                                        );
                                        timeLabel = '$st–$en';
                                      }

                                      return TableRow(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1E1E2C),
                                        ),
                                        children: [
                                          _cell('P${s.period + 1}'),
                                          if (hasTiming)
                                            _cell(timeLabel ?? '—'),
                                          _cell(sub?.name ?? '—', accent: true),
                                          _cell(lvl?.name ?? '—'),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared helpers
// ═══════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final String? actionTooltip;

  const _SearchBar({
    required this.onChanged,
    this.onAction,
    this.actionIcon,
    this.actionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white38,
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFF12121C),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: actionTooltip ?? '',
              child: IconButton(
                onPressed: onAction,
                icon: Icon(actionIcon, color: _accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _headerCell(String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
  child: Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: _accent,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    ),
  ),
);

Widget _cell(String text, {bool accent = false}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
  child: Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(color: accent ? _accent : Colors.white70, fontSize: 12),
  ),
);

Widget _empty(String msg) => Center(
  child: Text(
    msg,
    textAlign: TextAlign.center,
    style: const TextStyle(color: Colors.white38, fontSize: 15),
  ),
);

Widget _field(
  TextEditingController ctrl,
  String label, {
  bool isNumber = false,
  bool isDecimal = false,
}) => TextField(
  controller: ctrl,
  keyboardType: isDecimal
      ? const TextInputType.numberWithOptions(decimal: true)
      : isNumber
      ? TextInputType.number
      : TextInputType.text,
  style: const TextStyle(color: Colors.white),
  decoration: _inputDec(label),
);

InputDecoration _inputDec(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: Colors.white54),
  enabledBorder: const UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.white24),
  ),
  focusedBorder: const UnderlineInputBorder(
    borderSide: BorderSide(color: _accent),
  ),
);

class _Dialog extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final VoidCallback onSave;

  const _Dialog({
    required this.title,
    required this.fields,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: fields
            .map(
              (f) =>
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: f),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.black,
          ),
          onPressed: onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

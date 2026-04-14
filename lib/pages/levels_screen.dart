import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models.dart';
import '/state.dart';
import '/shared_widgets.dart';

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
      backgroundColor: kBg,
      body: Column(
        children: [
          AppSearchBar(
            onChanged: (v) => setState(() => _search = v),
            onAction: () => _showAddGroup(context),
            actionIcon: Icons.folder_outlined,
            actionTooltip: 'Add Group',
          ),
          Expanded(
            child: state.levels.isEmpty
                ? kEmpty('No levels yet.\nTap + to add a class or grade.')
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
        backgroundColor: kAccent,
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
      builder: (ctx) => AppDialog(
        title: 'Add Group',
        fields: [appField(nameCtrl, 'Group name (e.g. Standard 1)')],
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
    String? selectedGroupId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return AlertDialog(
            backgroundColor: kCardColor,
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
                appField(nameCtrl, 'Level name (e.g. 1A)'),
                if (state.groups.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    dropdownColor: kCardColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: appInputDec('Assign to group (optional)'),
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
                  backgroundColor: kAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  ctx.read<AppState>().addLevel(
                    Level(
                      id: UniqueKey().toString(),
                      name: nameCtrl.text.trim(),
                      groupId: selectedGroupId,
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
        side: BorderSide(color: kAccent.withOpacity(0.25)),
      ),
      child: ExpansionTile(
        iconColor: kAccent,
        collapsedIconColor: Colors.white54,
        leading: const Icon(Icons.folder_outlined, color: kAccent),
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
                style: TextStyle(color: kAccent.withOpacity(0.7), fontSize: 11),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.people_alt_outlined,
                color: kAccent,
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
                foregroundColor: kAccent,
                side: const BorderSide(color: kAccent),
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
            backgroundColor: kCardColor,
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
                  infoChip(
                    'Leave empty to allow all qualified teachers. '
                    'Group teachers are inherited by all levels in this group.',
                  ),
                  const SizedBox(height: 10),
                  teacherSearchBox(search, (v) => setState(() => search = v)),
                  const SizedBox(height: 6),
                  teacherCheckList(visible, selected, ctx, setState),
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
                  backgroundColor: kAccent,
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
      builder: (ctx) => AppDialog(
        title: 'Rename Group',
        fields: [appField(ctrl, 'Group name')],
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
            backgroundColor: kCardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Assign Level to Group',
              style: TextStyle(color: Colors.white),
            ),
            content: DropdownButtonFormField<String>(
              dropdownColor: kCardColor,
              style: const TextStyle(color: Colors.white),
              decoration: appInputDec('Level'),
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
                  backgroundColor: kAccent,
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
      color: kCardColor,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        iconColor: kAccent,
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
            if (allowedSet.isNotEmpty)
              Text(
                '${allowedSet.length} teachers assigned',
                style: TextStyle(color: kAccent.withOpacity(0.7), fontSize: 11),
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
                color: kAccent,
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
                color: kAccent,
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
                      foregroundColor: kAccent,
                      side: const BorderSide(color: kAccent),
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
            backgroundColor: kCardColor,
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
                  infoChip(
                    'Leave empty to allow all qualified teachers. '
                    'Teachers marked ★ are already allowed via the group.',
                  ),
                  const SizedBox(height: 10),
                  teacherSearchBox(search, (v) => setState(() => search = v)),
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
                                      appCheckbox(isSelected),
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
                                        appChip('★ group')
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
                        color: kAccent.withOpacity(0.7),
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
                  backgroundColor: kAccent,
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
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Edit Level — ${level.name}',
        fields: [appField(nameCtrl, 'Level name')],
        onSave: () {
          final newName = nameCtrl.text.trim();
          if (newName.isEmpty) return;
          ctx.read<AppState>().updateLevel(
            Level(
              id: level.id,
              name: newName,
              subjects: level.subjects,
              groupId: level.groupId,
              periodsPerDay: level.periodsPerDay,
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
      builder: (ctx) => AppDialog(
        title: 'Add Subject to ${level.name}',
        fields: [
          appField(nameCtrl, 'Subject name'),
          appField(
            hoursCtrl,
            'Hours per week',
            isNumber: true,
            isDecimal: true,
          ),
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
            backgroundColor: kCardColor,
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
                    dropdownColor: kCardColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: appInputDec('Source level'),
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
                                        color: kAccent,
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
                  backgroundColor: kAccent,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models.dart';
import '/state.dart';
import '/shared_widgets.dart';

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
      backgroundColor: kBg,
      body: Column(
        children: [
          AppSearchBar(onChanged: (v) => setState(() => _search = v)),
          Expanded(
            child: filtered.isEmpty
                ? kEmpty(
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
        backgroundColor: kAccent,
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
            backgroundColor: kCardColor,
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
                    appField(nameCtrl, 'Full name'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: idCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: appInputDec('Employee ID').copyWith(
                        errorText: idError,
                        errorStyle: const TextStyle(color: Colors.redAccent),
                      ),
                      onChanged: (_) => setState(() => idError = null),
                    ),
                    const SizedBox(height: 10),
                    appField(hoursCtrl, 'Max hours/week', isNumber: true),
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
                                color: kAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: kAccent.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                '${selectedNames.length} selected',
                                style: const TextStyle(
                                  color: kAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      teacherSearchBox(
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
                                          appCheckbox(sel),
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
                  backgroundColor: kAccent,
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

// ═══════════════════════════════════════════════════════════════════════════
// Teacher Card
// ═══════════════════════════════════════════════════════════════════════════

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
      color: kCardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: kAccent.withOpacity(0.15),
          child: Text(
            teacher.name[0].toUpperCase(),
            style: const TextStyle(color: kAccent, fontWeight: FontWeight.bold),
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
                        color: kAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: kAccent,
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

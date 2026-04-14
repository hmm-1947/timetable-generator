import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '/models.dart';
import '/state.dart';
import '/shared_widgets.dart';

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
    if (state.teachers.isEmpty) return kEmpty('Add teachers first.');

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

    int periodCount = kDefaultPeriodsPerDay;
    if (hasTiming) {
      periodCount = (timing.totalMinutes / 60).floor().clamp(1, 24);
    }

    final usedDayIndices = slots.map((s) => s.day).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildHeader(context, state, teacher, slots),
          Expanded(
            child: slots.isEmpty
                ? kEmpty('No periods assigned to ${teacher.name} yet.')
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: usedDayIndices.map((dayIndex) {
                        final dayName = dayIndex < kAllDays.length
                            ? kAllDays[dayIndex]
                            : 'Day $dayIndex';

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
                                  color: kAccent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: kAccent.withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  dayName,
                                  style: const TextStyle(
                                    color: kAccent,
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
                                      1: const FixedColumnWidth(110),
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
                                        appHeaderCell('Per.'),
                                        if (hasTiming) appHeaderCell('Time'),
                                        appHeaderCell('Subject'),
                                        appHeaderCell('Class'),
                                      ],
                                    ),
                                    ...daySlots.map((s) {
                                      Level? lvl;
                                      try {
                                        lvl = state.levels.firstWhere(
                                          (l) => l.id == s.levelId,
                                        );
                                      } catch (_) {}

                                      Subject? sub;
                                      try {
                                        sub = lvl?.subjects.firstWhere(
                                          (su) => su.id == s.subjectId,
                                        );
                                      } catch (_) {}

                                      String? timeLabel;
                                      if (hasTiming && lvl != null) {
                                        final lvlPeriodCount =
                                            (timing.totalMinutes / 60)
                                                .floor()
                                                .clamp(1, 24);
                                        final st = timing.periodStartLabel(
                                          s.period,
                                          lvlPeriodCount,
                                        );
                                        final en = timing.periodEndLabel(
                                          s.period,
                                          lvlPeriodCount,
                                        );
                                        timeLabel = '$st–$en';
                                      }

                                      return TableRow(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1E1E2C),
                                        ),
                                        children: [
                                          appCell('P${s.period + 1}'),
                                          if (hasTiming)
                                            appCell(timeLabel ?? '—'),
                                          appCell(
                                            sub?.name ?? '—',
                                            accent: true,
                                          ),
                                          appCell(lvl?.name ?? '—'),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'teacherSavePdf',
        backgroundColor: const Color(0xFF1E1E2C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Save PDF'),
        onPressed: () => _showSavePdfDialog(context, state),
      ),
    );
  }

  // ── Save PDF Dialog ───────────────────────────────────────────────────────

  void _showSavePdfDialog(BuildContext context, AppState state) {
    final Set<String> selected = {
      if (_selectedTeacherId != null) _selectedTeacherId!,
    };
    String search = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final filtered = state.teachers
              .where(
                (t) =>
                    t.name.toLowerCase().contains(search.toLowerCase()) ||
                    t.employeeId.toLowerCase().contains(search.toLowerCase()),
              )
              .toList();
          final allIds = filtered.map((t) => t.id).toSet();
          final allSelected =
              allIds.isNotEmpty && allIds.every((id) => selected.contains(id));

          return AlertDialog(
            backgroundColor: kCardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: kAccent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Save Schedule as PDF',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search
                  TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onChanged: (v) => setDlg(() => search = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name or ID...',
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white38,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF12121C),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Select / Deselect All
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => setDlg(() {
                          if (allSelected) {
                            selected.removeAll(allIds);
                          } else {
                            selected.addAll(allIds);
                          }
                        }),
                        icon: Icon(
                          allSelected ? Icons.deselect : Icons.select_all,
                          size: 16,
                          color: kAccent,
                        ),
                        label: Text(
                          allSelected ? 'Deselect All' : 'Select All',
                          style: TextStyle(color: kAccent, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${selected.length} selected',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // List
                  Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12121C),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: filtered.isEmpty
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
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final t = filtered[i];
                              final isSelected = selected.contains(t.id);
                              final slotCount = state
                                  .getTeacherSlots(t.id)
                                  .length;
                              return InkWell(
                                onTap: () => setDlg(() {
                                  if (isSelected) {
                                    selected.remove(t.id);
                                  } else {
                                    selected.add(t.id);
                                  }
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      appCheckbox(isSelected),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
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
                                      Text(
                                        '$slotCount slots',
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
                  backgroundColor: selected.isEmpty ? Colors.grey : kAccent,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.save_alt, size: 16),
                label: const Text('Save as PDF'),
                onPressed: selected.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _exportTeachersPdf(
                          context,
                          state,
                          selected.toList(),
                        );
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportTeachersPdf(
    BuildContext context,
    AppState state,
    List<String> teacherIds,
  ) async {
    int success = 0;
    String? lastPath;
    final timing = state.dayTiming;
    final hasTiming = timing != null && timing.totalMinutes > 0;

    for (final teacherId in teacherIds) {
      final teacher = state.teachers.firstWhere((t) => t.id == teacherId);
      final slots = state.getTeacherSlots(teacherId);

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (pw.Context pdfCtx) {
            final List<pw.Widget> content = [];

            // Title block
            content.add(
              pw.Text(
                teacher.name,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
            content.add(pw.SizedBox(height: 2));
            content.add(
              pw.Text(
                'Employee ID: ${teacher.employeeId}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            );
            content.add(
              pw.Text(
                'Weekly load: ${slots.length} / ${teacher.maxHoursPerWeek} hrs',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            );
            content.add(
              pw.Text(
                'Generated: ${DateTime.now().toString().substring(0, 16)}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey500,
                ),
              ),
            );
            content.add(pw.SizedBox(height: 16));

            if (slots.isEmpty) {
              content.add(
                pw.Text(
                  'No periods assigned.',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey600,
                  ),
                ),
              );
              return content;
            }

            // Group slots by day
            final usedDays = slots.map((s) => s.day).toSet().toList()..sort();
            for (final dayIdx in usedDays) {
              final dayName = dayIdx < kAllDays.length
                  ? kAllDays[dayIdx]
                  : 'Day $dayIdx';
              final daySlots = slots.where((s) => s.day == dayIdx).toList()
                ..sort((a, b) => a.period.compareTo(b.period));

              content.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    dayName,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                ),
              );

              // Build headers dynamically
              final headers = <String>['Period'];
              if (hasTiming) headers.add('Time');
              headers.addAll(['Subject', 'Class']);

              final colWidths = <int, pw.TableColumnWidth>{
                0: const pw.FixedColumnWidth(42),
              };
              if (hasTiming) {
                colWidths[1] = const pw.FixedColumnWidth(80);
                colWidths[2] = const pw.FlexColumnWidth();
                colWidths[3] = const pw.FlexColumnWidth();
              } else {
                colWidths[1] = const pw.FlexColumnWidth();
                colWidths[2] = const pw.FlexColumnWidth();
              }

              content.add(
                pw.Table(
                  columnWidths: colWidths,
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blueGrey800,
                      ),
                      children: headers
                          .map(
                            (h) => pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 6,
                              ),
                              child: pw.Text(
                                h,
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    // Rows
                    ...daySlots.asMap().entries.map((entry) {
                      final s = entry.value;
                      final even = entry.key % 2 == 0;

                      Level? lvl;
                      try {
                        lvl = state.levels.firstWhere((l) => l.id == s.levelId);
                      } catch (_) {}
                      Subject? sub;
                      try {
                        sub = lvl?.subjects.firstWhere(
                          (su) => su.id == s.subjectId,
                        );
                      } catch (_) {}

                      String? timeLabel;
                      if (hasTiming && lvl != null) {
                        final lpc = (timing.totalMinutes / 60).floor().clamp(
                          1,
                          24,
                        );
                        timeLabel =
                            '${timing.periodStartLabel(s.period, lpc)} - ${timing.periodEndLabel(s.period, lpc)}';
                      }

                      final cells = <String>['P${s.period + 1}'];
                      if (hasTiming) cells.add(timeLabel ?? '—');
                      cells.addAll([sub?.name ?? '—', lvl?.name ?? '—']);

                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: even ? PdfColors.grey100 : PdfColors.white,
                        ),
                        children: cells
                            .map(
                              (c) => pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 5,
                                ),
                                child: pw.Text(
                                  c,
                                  style: const pw.TextStyle(fontSize: 9),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            )
                            .toList(),
                      );
                    }),
                  ],
                ),
              );
              content.add(pw.SizedBox(height: 14));
            }
            return content;
          },
        ),
      );

      try {
        final dir = await _getSaveDir();
        final safeName = '${teacher.name}_${teacher.employeeId}'.replaceAll(
          RegExp(r'[^a-zA-Z0-9_\-]'),
          '_',
        );
        final file = File('${dir.path}${Platform.pathSeparator}$safeName.pdf');
        await file.writeAsBytes(await pdf.save());
        lastPath = file.path;
        success++;
      } catch (e) {
        debugPrint('PDF export error: $e');
      }
    }

    if (!context.mounted) return;
    if (success > 0) {
      final dir = lastPath != null ? File(lastPath!).parent.path : 'unknown';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          backgroundColor: Colors.green.shade800,
          content: Text(
            '$success PDF${success > 1 ? 's' : ''} saved to:\n$dir',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to save PDFs.'),
        ),
      );
    }
  }

  Future<Directory> _getSaveDir() async {
    String base;
    if (Platform.isWindows) {
      base =
          Platform.environment['USERPROFILE'] ??
          Platform.environment['APPDATA'] ??
          '.';
      final dir = Directory(
        '${base}${Platform.pathSeparator}Documents${Platform.pathSeparator}TeacherScheduler${Platform.pathSeparator}TeacherSchedules',
      );
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    } else if (Platform.isMacOS) {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/TeacherScheduler/TeacherSchedules');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    } else if (Platform.isAndroid || Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/TeacherSchedules');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    } else {
      base = Platform.environment['HOME'] ?? '.';
      final dir = Directory('$base/TeacherScheduler/TeacherSchedules');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    }
  }

  Widget _buildHeader(
    BuildContext context,
    AppState state,
    Teacher teacher,
    List<TimetableSlot> slots,
  ) {
    final weeklyHours = slots.length;
    final maxHours = teacher.maxHoursPerWeek;
    final overload = weeklyHours > maxHours;

    return Container(
      color: kCardColor,
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
                              _search = '';
                            }),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              dropdownColor: kCardColor,
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
                          selectedColor: kAccent,
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
                  const Icon(Icons.badge_outlined, color: kAccent, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'ID: ${teacher.employeeId}',
                    style: const TextStyle(color: kAccent, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.schedule, color: Colors.white38, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '$weeklyHours / $maxHours hrs/week',
                    style: TextStyle(
                      color: overload ? Colors.orange : Colors.white38,
                      fontSize: 12,
                      fontWeight: overload
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (overload) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

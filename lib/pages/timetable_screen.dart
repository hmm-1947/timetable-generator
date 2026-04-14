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
    if (state.levels.isEmpty) return kEmpty('Add levels first.');

    if (_selectedLevelId == null ||
        !state.levels.any((l) => l.id == _selectedLevelId)) {
      _selectedLevelId = state.levels.first.id;
    }

    final level = state.levels.firstWhere((l) => l.id == _selectedLevelId);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildControls(state, level),
          Expanded(child: _buildGrid(state, level)),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Save PDF ──────────────────────────────────────────────────
          FloatingActionButton.extended(
            heroTag: 'savepdf',
            backgroundColor: const Color(0xFF1E1E2C),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Save PDF'),
            onPressed: () => _showSavePdfDialog(context, state),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'workdays',
            backgroundColor: const Color(0xFF1E1E2C),
            foregroundColor: kAccent,
            icon: const Icon(Icons.calendar_month),
            label: const Text('Work Days'),
            onPressed: () => _showWorkingDaysDialog(context, state, level),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'timing',
            backgroundColor:
                state.dayTiming != null && state.dayTiming!.totalMinutes > 0
                ? const Color(0xFF1E1E2C)
                : Colors.orange,
            foregroundColor:
                state.dayTiming != null && state.dayTiming!.totalMinutes > 0
                ? kAccent
                : Colors.black,
            icon: const Icon(Icons.schedule),
            label: Text(
              state.dayTiming != null && state.dayTiming!.totalMinutes > 0
                  ? 'Timings'
                  : 'Set Timings',
            ),
            onPressed: () => _showTimingDialog(context, state, level),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'auto',
            backgroundColor: kAccent,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Auto-Schedule'),
            onPressed: () {
              if (state.dayTiming == null ||
                  state.dayTiming!.totalMinutes <= 0) {
                _showTimingDialog(context, state, level);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.orange,
                    content: Text(
                      'Set school timings first, then tap Auto-Schedule.',
                    ),
                  ),
                );
                return;
              }
              _confirmAndGenerate(context, state, level);
            },
          ),
        ],
      ),
    );
  }

  // ── Save PDF Dialog ───────────────────────────────────────────────────────

  void _showSavePdfDialog(BuildContext context, AppState state) {
    final Set<String> selected = {
      if (_selectedLevelId != null) _selectedLevelId!,
    };
    String search = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final filtered = state.levels
              .where((l) => l.name.toLowerCase().contains(search.toLowerCase()))
              .toList();
          final allIds = filtered.map((l) => l.id).toSet();
          final allSelected = allIds.every((id) => selected.contains(id));

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
                  'Save Timetable as PDF',
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
                      hintText: 'Search classes...',
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
                  // Select all / Deselect all
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
                                'No classes match.',
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
                              final level = filtered[i];
                              final isSelected = selected.contains(level.id);
                              return InkWell(
                                onTap: () => setDlg(() {
                                  if (isSelected) {
                                    selected.remove(level.id);
                                  } else {
                                    selected.add(level.id);
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
                                        child: Text(
                                          level.name,
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
                                      Text(
                                        '${state.timetable.where((s) => s.levelId == level.id).length} slots',
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
                        await _exportLevelsPdf(
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

  Future<void> _exportLevelsPdf(
    BuildContext context,
    AppState state,
    List<String> levelIds,
  ) async {
    int success = 0;
    String? lastPath;

    for (final levelId in levelIds) {
      final level = state.levels.firstWhere((l) => l.id == levelId);
      final timing = state.dayTiming;
      final hasTiming = timing != null && timing.totalMinutes > 0;
      int periodCount = level.periodsPerDay;
      if (hasTiming) {
        periodCount = (timing.totalMinutes / 60).floor().clamp(1, 24);
      }
      final workingDays = level.workingDays.isNotEmpty
          ? level.workingDays
          : [0, 1, 2, 3, 4];

      final slotsForLevel = state.timetable
          .where((s) => s.levelId == levelId)
          .toList();
      final maxUsed = slotsForLevel.isEmpty
          ? periodCount - 1
          : slotsForLevel.map((s) => s.period).reduce((a, b) => a > b ? a : b);
      final effectivePeriodCount = maxUsed >= periodCount
          ? maxUsed + 1
          : periodCount;

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context pdfCtx) {
            final List<pw.Widget> content = [];

            content.add(
              pw.Text(
                level.name,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
            content.add(pw.SizedBox(height: 4));
            content.add(
              pw.Text(
                'Generated: ${DateTime.now().toString().substring(0, 16)}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            );
            content.add(pw.SizedBox(height: 16));

            // Header row: blank corner + P1, P2, P3...
            final headerCells = <pw.Widget>[
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 6,
                ),
                child: pw.Text(''),
              ),
            ];
            for (int p = 0; p < effectivePeriodCount; p++) {
              String label = 'P${p + 1}';
              if (hasTiming) {
                final st = timing.periodStartLabelExtended(
                  p,
                  periodCount,
                ); // periodCount before extra slots
                final en = timing.periodEndLabelExtended(p, periodCount);
                label = 'P${p + 1}\n$st - $en';
              }
              headerCells.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: pw.Text(
                    label,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              );
            }

            // Column widths: first col fixed for day name, rest flex
            final colWidths = <int, pw.TableColumnWidth>{
              0: const pw.FixedColumnWidth(52),
            };
            for (int c = 1; c <= effectivePeriodCount; c++) {
              colWidths[c] = const pw.FlexColumnWidth();
            }

            // One row per working day
            final dataRows = <pw.TableRow>[];
            for (int ri = 0; ri < workingDays.length; ri++) {
              final dayIdx = workingDays[ri];
              final dayName = kAllDays[dayIdx];
              final even = ri % 2 == 0;

              final cells = <pw.Widget>[
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 6,
                  ),
                  child: pw.Text(
                    dayName,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                ),
              ];

              for (int p = 0; p < effectivePeriodCount; p++) {
                final slot = state.getSlot(levelId, dayIdx, p);
                String cellText = '';
                if (slot?.subjectId != null) {
                  Subject? sub;
                  try {
                    sub = level.subjects.firstWhere(
                      (s) => s.id == slot!.subjectId,
                    );
                  } catch (_) {}
                  Teacher? teacher;
                  try {
                    if (slot?.teacherId != null) {
                      teacher = state.teachers.firstWhere(
                        (t) => t.id == slot!.teacherId,
                      );
                    }
                  } catch (_) {}
                  final subjectName = sub?.name ?? '';
                  final teacherName = teacher?.name ?? '';

                  cellText = teacherName.isEmpty
                      ? subjectName
                      : '$subjectName\n$teacherName';
                }
                cells.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 5,
                    ),
                    child: pw.Text(
                      cellText,
                      style: const pw.TextStyle(fontSize: 7),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                );
              }

              dataRows.add(
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: even ? PdfColors.grey100 : PdfColors.white,
                  ),
                  children: cells,
                ),
              );
            }

            content.add(
              pw.Table(
                columnWidths: colWidths,
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blueGrey800,
                    ),
                    children: headerCells,
                  ),
                  ...dataRows,
                ],
              ),
            );

            return content;
          },
        ),
      );

      try {
        final dir = await _getSaveDir();
        final safeName = level.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
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
        '${base}${Platform.pathSeparator}Documents${Platform.pathSeparator}TeacherScheduler${Platform.pathSeparator}ClassTimetables',
      );
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    } else if (Platform.isMacOS) {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/TeacherScheduler/ClassTimetables');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    } else if (Platform.isAndroid || Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/ClassTimetables');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    } else {
      base = Platform.environment['HOME'] ?? '.';
      final dir = Directory('$base/TeacherScheduler/ClassTimetables');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    }
  }

  // ── Working Days Dialog ───────────────────────────────────────────────────

  void _showWorkingDaysDialog(
    BuildContext context,
    AppState state,
    Level level,
  ) {
    final selected = Set<int>.from(
      level.workingDays.isNotEmpty ? level.workingDays : [0, 1, 2, 3, 4],
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: kCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.calendar_month, color: kAccent, size: 20),
              const SizedBox(width: 8),
              const Text('Working Days', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                infoChip(
                  'Select working days for "${level.name}". Only these days will be scheduled.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(kAllDays.length, (i) {
                    final isSelected = selected.contains(i);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (isSelected) {
                          if (selected.length > 1) selected.remove(i);
                        } else {
                          selected.add(i);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? kAccent.withOpacity(0.18)
                              : const Color(0xFF12121C),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? kAccent : Colors.white12,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          kAllDays[i],
                          style: TextStyle(
                            color: isSelected ? kAccent : Colors.white54,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: kAccent.withOpacity(0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${selected.length} day${selected.length == 1 ? '' : 's'} selected',
                        style: TextStyle(
                          color: kAccent.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                ctx.read<AppState>().updateLevelWorkingDays(
                  level.id,
                  selected.toList()..sort(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
        : const TimeOfDay(hour: 20, minute: 0);
    final breakCtrl = TextEditingController(
      text: existing?.breakMinutes.toString() ?? '0',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final breakMins = int.tryParse(breakCtrl.text) ?? 0;
          final previewTiming = DayTiming(
            startHour: startTime.hour,
            startMinute: startTime.minute,
            endHour: endTime.hour,
            endMinute: endTime.minute,
            breakMinutes: breakMins,
          );
          final previewPeriodCount = previewTiming.totalMinutes > 0
              ? (previewTiming.totalMinutes / 60).floor().clamp(0, 24)
              : 0;

          return AlertDialog(
            backgroundColor: kCardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.schedule, color: kAccent, size: 20),
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
                  infoChip(
                    'Each period = 1 hour. Set start & end time to define how many periods fit in the day.',
                  ),
                  const SizedBox(height: 16),
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
                              borderSide: BorderSide(color: kAccent),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (previewPeriodCount > 0) ...[
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kAccent.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kAccent.withOpacity(0.2)),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preview — $previewPeriodCount periods/day',
                              style: TextStyle(
                                color: kAccent.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...List.generate(previewPeriodCount, (i) {
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
                                      '${previewTiming.periodStartLabel(i, previewPeriodCount)} – ${previewTiming.periodEndLabel(i, previewPeriodCount)}',
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
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'End time must be after start time.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
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
                  backgroundColor: kAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: previewPeriodCount > 0
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
              color: kAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kAccent.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: kAccent, size: 15),
                const SizedBox(width: 6),
                Text(
                  '$h:$m',
                  style: const TextStyle(
                    color: kAccent,
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

  Widget _timePickerTheme(BuildContext context, Widget? child) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: const ColorScheme.dark(
        primary: kAccent,
        onPrimary: Colors.black,
        surface: kCardColor,
        onSurface: Colors.white,
      ),
      dialogBackgroundColor: kCardColor,
    ),
    child: child!,
  );

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
          backgroundColor: kCardColor,
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
                              dropdownColor: kCardColor,
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
                    activeColor: kAccent,
                    onChanged: (v) => setState(() => _showTeacher = v),
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
                          selectedColor: kAccent,
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
    final hasTiming =
        state.dayTiming != null && state.dayTiming!.totalMinutes > 0;
    final timing = hasTiming ? state.dayTiming! : null;

    int periodCount = level.periodsPerDay;
    if (timing != null && timing.totalMinutes > 0) {
      periodCount = (timing.totalMinutes / 60).floor().clamp(1, 24);
    }

    final workingDays = level.workingDays.isNotEmpty
        ? level.workingDays
        : [0, 1, 2, 3, 4];

    final slotsForLevel = state.timetable
        .where((s) => s.levelId == level.id)
        .toList();
    final maxUsedPeriod = slotsForLevel.isEmpty
        ? periodCount - 1
        : slotsForLevel.map((s) => s.period).reduce((a, b) => a > b ? a : b);
    final effectivePeriodCount = maxUsedPeriod >= periodCount
        ? maxUsedPeriod + 1
        : periodCount;

    const double dayColW = 64;
    const double periodColW = 120;
    const double rowH = 72.0;
    const double headerH = 48.0;

    // Build header row
    Widget buildHeader() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dayColW,
            height: headerH,
            decoration: BoxDecoration(
              color: const Color(0xFF12121C),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
              ),
              border: Border.all(color: Colors.white10),
            ),
          ),
          ...List.generate(effectivePeriodCount, (p) {
            String label = 'P${p + 1}';
            String? timingLabel;
            if (timing != null) {
              final st = timing.periodStartLabelExtended(p, periodCount);
              final en = timing.periodEndLabelExtended(p, periodCount);
              timingLabel = '$st–$en';
            }
            return Container(
              width: periodColW,
              height: headerH,
              decoration: BoxDecoration(
                color: const Color(0xFF12121C),
                border: Border(
                  top: const BorderSide(color: Colors.white10),
                  right: const BorderSide(color: Colors.white10),
                  bottom: BorderSide(color: kAccent.withOpacity(0.4)),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: kAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (timingLabel != null)
                    Text(
                      timingLabel,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
            );
          }),
          // blank cell above the add-column
          Container(
            width: periodColW,
            height: headerH,
            decoration: const BoxDecoration(
              color: Color(0xFF12121C),
              border: Border(
                top: BorderSide(color: Colors.white10),
                right: BorderSide(color: Colors.white10),
                bottom: BorderSide(color: Colors.white10),
              ),
            ),
          ),
        ],
      );
    }

    // Build a single day row
    Widget buildDayRow(int ri, int dayIdx) {
      final dayName = kAllDays[dayIdx];
      final isLastRow = ri == workingDays.length - 1;

      final daySlots = slotsForLevel.where((s) => s.day == dayIdx).toList();
      final maxDayPeriod = daySlots.isEmpty
          ? effectivePeriodCount - 1
          : daySlots.map((s) => s.period).reduce((a, b) => a > b ? a : b);
      final dayPeriodCount = maxDayPeriod >= effectivePeriodCount
          ? maxDayPeriod + 1
          : effectivePeriodCount;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day label cell
          ClipRRect(
            borderRadius: isLastRow
                ? const BorderRadius.only(bottomLeft: Radius.circular(8))
                : BorderRadius.zero,
            child: Container(
              width: dayColW,
              height: rowH,
              decoration: BoxDecoration(
                color: const Color(0xFF12121C),
                border: Border(
                  left: const BorderSide(color: Colors.white10),
                  right: BorderSide(color: kAccent.withOpacity(0.3)),
                  bottom: const BorderSide(color: Colors.white10),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                dayName,
                style: const TextStyle(
                  color: kAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),

          // Period cells
          ...List.generate(dayPeriodCount, (p) {
            final slot = state.getSlot(level.id, dayIdx, p);
            Subject? subject;
            Teacher? teacher;
            if (slot?.subjectId != null) {
              try {
                subject = level.subjects.firstWhere(
                  (s) => s.id == slot!.subjectId,
                );
              } catch (_) {}
            }
            if (slot?.teacherId != null) {
              try {
                teacher = state.teachers.firstWhere(
                  (t) => t.id == slot!.teacherId,
                );
              } catch (_) {}
            }
            final unassigned = subject != null && teacher == null;

            return GestureDetector(
              onTap: () => _editSlot(context, state, level, dayIdx, p, slot),
              child: Container(
                width: periodColW,
                height: rowH,
                decoration: BoxDecoration(
                  color: subject != null
                      ? (unassigned
                            ? Colors.orange.withOpacity(0.06)
                            : kAccent.withOpacity(0.07))
                      : (ri % 2 == 0
                            ? const Color(0xFF1A1A28)
                            : const Color(0xFF16161F)),
                  border: Border(
                    right: const BorderSide(color: Colors.white10),
                    bottom: const BorderSide(color: Colors.white10),
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: subject == null
                    ? const Center(
                        child: Icon(Icons.add, color: Colors.white12, size: 18),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            subject.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unassigned ? Colors.orange : kAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          if (_showTeacher) ...[
                            const SizedBox(height: 3),
                            Text(
                              teacher?.name ?? '—',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: teacher != null
                                    ? Colors.white54
                                    : Colors.orange.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            );
          }),

          // Add extra period button
          GestureDetector(
            onTap: () =>
                _editSlot(context, state, level, dayIdx, dayPeriodCount, null),
            child: ClipRRect(
              borderRadius: isLastRow
                  ? const BorderRadius.only(bottomRight: Radius.circular(8))
                  : BorderRadius.zero,
              child: Container(
                width: periodColW,
                height: rowH,
                decoration: const BoxDecoration(
                  color: Color(0xFF14141E),
                  border: Border(
                    right: BorderSide(color: Colors.white10),
                    bottom: BorderSide(color: Colors.white10),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_circle_outline,
                    color: Colors.white12,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(),
            ...workingDays.asMap().entries.map(
              (e) => buildDayRow(e.key, e.value),
            ),
          ],
        ),
      ),
    );
  }
  // ── Edit slot dialog with search ──────────────────────────────────────────

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
    String subjectSearch = '';
    String teacherSearch = '';
    final dayName = day < kAllDays.length ? kAllDays[day] : 'Day $day';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final filteredSubjects = level.subjects
              .where(
                (s) =>
                    s.name.toLowerCase().contains(subjectSearch.toLowerCase()),
              )
              .toList();

          final filteredTeachers = state.teachers
              .where(
                (t) =>
                    t.name.toLowerCase().contains(
                      teacherSearch.toLowerCase(),
                    ) ||
                    t.employeeId.toLowerCase().contains(
                      teacherSearch.toLowerCase(),
                    ),
              )
              .toList();

          return AlertDialog(
            backgroundColor: kCardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Edit $dayName · Period ${period + 1}',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 340,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Subject ─────────────────────────────────────────
                    const Text(
                      'Subject',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      onChanged: (v) => setDlgState(() => subjectSearch = v),
                      decoration: InputDecoration(
                        hintText: 'Search subjects...',
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
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12121C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          _selectableTile(
                            label: '— None —',
                            subtitle: null,
                            isSelected: subjectId == null,
                            onTap: () => setDlgState(() => subjectId = null),
                          ),
                          ...filteredSubjects.map(
                            (s) => _selectableTile(
                              label: s.name,
                              subtitle:
                                  '${s.hoursPerWeek.toStringAsFixed(0)} hrs/wk',
                              isSelected: subjectId == s.id,
                              onTap: () => setDlgState(() => subjectId = s.id),
                            ),
                          ),
                          if (filteredSubjects.isEmpty &&
                              subjectSearch.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'No subjects match.',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Teacher ─────────────────────────────────────────
                    const Text(
                      'Teacher',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      onChanged: (v) => setDlgState(() => teacherSearch = v),
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
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12121C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          _selectableTile(
                            label: '— None —',
                            subtitle: null,
                            isSelected: teacherId == null,
                            onTap: () => setDlgState(() => teacherId = null),
                          ),
                          ...filteredTeachers.map(
                            (t) => _selectableTile(
                              label: t.name,
                              subtitle: 'ID: ${t.employeeId}',
                              isSelected: teacherId == t.id,
                              onTap: () => setDlgState(() => teacherId = t.id),
                            ),
                          ),
                          if (filteredTeachers.isEmpty &&
                              teacherSearch.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'No teachers match.',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
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

  Widget _selectableTile({
    required String label,
    required String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kAccent.withOpacity(0.12) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? kAccent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? kAccent : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 10, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? kAccent : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}

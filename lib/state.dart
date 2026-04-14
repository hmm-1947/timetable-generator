import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';
import 'storage.dart';

class AppState extends ChangeNotifier {
  final List<Level> levels = [];
  final List<LevelGroup> groups = [];
  final List<Teacher> teachers = [];
  final List<TimetableSlot> timetable = [];

  DayTiming? dayTiming; // null = not configured yet

  bool _loaded = false;
  bool get loaded => _loaded;

  AppState() {
    _load();
  }

  static const _kLevels = 'sched_levels';
  static const _kGroups = 'sched_groups';
  static const _kTeachers = 'sched_teachers';
  static const _kTimetable = 'sched_timetable';
  static const _kTiming = 'sched_timing';

  Future<void> _load() async {
    final store = await AppStorage.getInstance();
    _fromJson(
      await store.getString(_kGroups),
      groups,
      (j) => LevelGroup.fromJson(j as Map<String, dynamic>),
    );
    _fromJson(
      await store.getString(_kLevels),
      levels,
      (j) => Level.fromJson(j as Map<String, dynamic>),
    );
    _fromJson(
      await store.getString(_kTeachers),
      teachers,
      (j) => Teacher.fromJson(j as Map<String, dynamic>),
    );
    _fromJson(
      await store.getString(_kTimetable),
      timetable,
      (j) => TimetableSlot.fromJson(j as Map<String, dynamic>),
    );
    final timingRaw = await store.getString(_kTiming);
    if (timingRaw != null) {
      try {
        dayTiming = DayTiming.fromJson(jsonDecode(timingRaw));
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  void _fromJson<T>(String? raw, List<T> list, T Function(dynamic) fromJson) {
    if (raw == null) return;
    try {
      final d = jsonDecode(raw) as List;
      list.addAll(d.map(fromJson));
    } catch (_) {}
  }

  Future<void> _save() async {
    final store = await AppStorage.getInstance();
    await store.setString(
      _kLevels,
      jsonEncode(levels.map((e) => e.toJson()).toList()),
    );
    await store.setString(
      _kGroups,
      jsonEncode(groups.map((e) => e.toJson()).toList()),
    );
    await store.setString(
      _kTeachers,
      jsonEncode(teachers.map((e) => e.toJson()).toList()),
    );
    await store.setString(
      _kTimetable,
      jsonEncode(timetable.map((e) => e.toJson()).toList()),
    );
    if (dayTiming != null) {
      await store.setString(_kTiming, jsonEncode(dayTiming!.toJson()));
    }
  }

  void _notify() {
    notifyListeners();
    _save();
  }

  // ── Day Timing ─────────────────────────────────────────────────────────────

  void setDayTiming(DayTiming timing) {
    dayTiming = timing;
    _notify();
  }

  /// How many periods a subject needs — 1 period = 1 hour.
  int periodsNeeded(Subject s) {
    return s.hoursPerWeek.round().clamp(1, 99);
  }

  Future<Directory> _getStorageDir() async {
    String base;
    if (Platform.isWindows) {
      base =
          Platform.environment['APPDATA'] ??
          Platform.environment['USERPROFILE'] ??
          '.';
    } else if (Platform.isMacOS) {
      base =
          '${Platform.environment['HOME'] ?? '.'}/Library/Application Support';
    } else {
      base = Platform.environment['HOME'] ?? '.';
    }
    final dir = Directory('$base${Platform.pathSeparator}teacher_scheduler');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  // ── Export ─────────────────────────────────────────────────────────────────

  Future<String?> exportTimetableJson(String levelId) async {
    final level = levels.firstWhere((l) => l.id == levelId);
    final slots = timetable.where((s) => s.levelId == levelId).toList()
      ..sort(
        (a, b) => a.day != b.day
            ? a.day.compareTo(b.day)
            : a.period.compareTo(b.period),
      );

    final workingDayNames = level.workingDays.map((i) => kAllDays[i]).toList();
    final Map<String, List<Map<String, dynamic>>> byDay = {
      for (final d in workingDayNames) d: [],
    };

    int assigned = 0, unassigned = 0;
    for (final slot in slots) {
      Subject? sub;
      try {
        sub = level.subjects.firstWhere((s) => s.id == slot.subjectId);
      } catch (_) {}
      Teacher? teacher;
      try {
        if (slot.teacherId != null)
          teacher = teachers.firstWhere((t) => t.id == slot.teacherId);
      } catch (_) {}
      teacher != null ? assigned++ : unassigned++;

      final dayName = slot.day < kAllDays.length
          ? kAllDays[slot.day]
          : 'Day${slot.day}';
      final entry = <String, dynamic>{
        'period': slot.period + 1,
        'subject': sub?.name ?? '(unknown)',
        'teacher': teacher?.name ?? 'UNASSIGNED',
        'teacher_employee_id': teacher?.employeeId ?? '',
      };
      if (dayTiming != null) {
        entry['start'] = dayTiming!.periodStartLabel(
          slot.period,
          level.periodsPerDay,
        );
        entry['end'] = dayTiming!.periodEndLabel(
          slot.period,
          level.periodsPerDay,
        );
      }
      byDay[dayName]?.add(entry);
    }

    final export = {
      'generated_at': DateTime.now().toIso8601String(),
      'level': level.name,
      'periods_per_day': level.periodsPerDay,
      'working_days': workingDayNames,
      'total_slots': slots.length,
      'assigned': assigned,
      'unassigned': unassigned,
      'schedule': byDay,
    };
    try {
      final dir = await _getStorageDir();
      final safeName = level.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final file = File(
        '${dir.path}${Platform.pathSeparator}timetable_$safeName.json',
      );
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(export),
        encoding: utf8,
        flush: true,
      );
      return file.path;
    } catch (_) {
      return null;
    }
  }

  // ── Groups ─────────────────────────────────────────────────────────────────

  void addGroup(LevelGroup group) {
    groups.add(group);
    _notify();
  }

  void removeGroup(String id) {
    groups.removeWhere((g) => g.id == id);
    for (var l in levels) {
      if (l.groupId == id) l.groupId = null;
    }
    _notify();
  }

  void renameGroup(String id, String newName) {
    groups.firstWhere((g) => g.id == id).name = newName;
    _notify();
  }

  void setLevelGroup(String levelId, String? groupId) {
    levels.firstWhere((l) => l.id == levelId).groupId = groupId;
    _notify();
  }

  void updateGroupAllowedTeachers(String groupId, List<String> teacherIds) {
    groups.firstWhere((g) => g.id == groupId).allowedTeacherIds = teacherIds;
    _notify();
  }

  // ── Levels ─────────────────────────────────────────────────────────────────

  void addLevel(Level level) {
    levels.add(level);
    _notify();
  }

  void removeLevel(String id) {
    levels.removeWhere((l) => l.id == id);
    timetable.removeWhere((s) => s.levelId == id);
    _notify();
  }

  void updateLevel(Level updated) {
    final idx = levels.indexWhere((l) => l.id == updated.id);
    if (idx >= 0) levels[idx] = updated;
    _notify();
  }

  void updateLevelAllowedTeachers(String levelId, List<String> teacherIds) {
    levels.firstWhere((l) => l.id == levelId).allowedTeacherIds = teacherIds;
    _notify();
  }

  void updateLevelWorkingDays(String levelId, List<int> workingDays) {
    levels.firstWhere((l) => l.id == levelId).workingDays = workingDays;
    _notify();
  }

  void addSubjectToLevel(String levelId, Subject subject) {
    levels.firstWhere((l) => l.id == levelId).subjects.add(subject);
    _notify();
  }

  void removeSubjectFromLevel(String levelId, String subjectId) {
    levels
        .firstWhere((l) => l.id == levelId)
        .subjects
        .removeWhere((s) => s.id == subjectId);
    _notify();
  }

  void copySubjectsFromLevel(String targetLevelId, Level sourceLevel) {
    final target = levels.firstWhere((l) => l.id == targetLevelId);
    final existing = target.subjects.map((s) => s.name.toLowerCase()).toSet();
    for (final s in sourceLevel.subjects) {
      if (!existing.contains(s.name.toLowerCase())) {
        target.subjects.add(
          Subject(
            id: UniqueKey().toString(),
            name: s.name,
            hoursPerWeek: s.hoursPerWeek,
          ),
        );
        existing.add(s.name.toLowerCase());
      }
    }
    _notify();
  }

  // ── Teachers ───────────────────────────────────────────────────────────────

  bool employeeIdExists(String empId, {String? excludeTeacherId}) =>
      teachers.any(
        (t) =>
            t.employeeId.trim().toLowerCase() == empId.trim().toLowerCase() &&
            t.id != excludeTeacherId,
      );

  void addTeacher(Teacher t) {
    teachers.add(t);
    _notify();
  }

  void updateTeacher(Teacher updated) {
    final idx = teachers.indexWhere((t) => t.id == updated.id);
    if (idx >= 0) teachers[idx] = updated;
    _notify();
  }

  void removeTeacher(String id) {
    teachers.removeWhere((t) => t.id == id);
    _notify();
  }

  Set<String> teacherSubjectNames(String teacherId) {
    final t = teachers.firstWhere(
      (t) => t.id == teacherId,
      orElse: () =>
          Teacher(id: '', name: '', employeeId: '', maxHoursPerWeek: 0),
    );
    final names = <String>{};
    for (final sid in t.subjectIds) {
      for (final lv in levels) {
        for (final s in lv.subjects) {
          if (s.id == sid) names.add(s.name.trim().toLowerCase());
        }
      }
    }
    return names;
  }

  Set<String> _allowedForLevel(Level level) {
    final s = <String>{...level.allowedTeacherIds};
    if (level.groupId != null) {
      try {
        s.addAll(
          groups.firstWhere((g) => g.id == level.groupId).allowedTeacherIds,
        );
      } catch (_) {}
    }
    return s;
  }

  // ── Timetable generation ───────────────────────────────────────────────────

  String? generateTimetableForLevel(String levelId) {
    timetable.removeWhere((s) => s.levelId == levelId);
    final level = levels.firstWhere((l) => l.id == levelId);

    if (level.subjects.isEmpty) {
      _notify();
      return 'No subjects added to ${level.name}.';
    }

    final rng = Random();
    if (dayTiming == null || dayTiming!.totalMinutes <= 0) {
      _notify();
      return 'School timings not set.';
    }

    // Each period = 1 hour; ppd = number of one-hour slots in the school day
    final int ppd = (dayTiming!.totalMinutes / 60).floor().clamp(1, 24);

    // Use the level's working days (indices into kAllDays)
    final workingDays = level.workingDays.isNotEmpty
        ? level.workingDays
        : [0, 1, 2, 3, 4];

    final int numDays = workingDays.length;
    final int total = ppd * numDays;
    final allowed = _allowedForLevel(level);

    final allSubjectIdToName = <String, String>{};
    for (final lv in levels) {
      for (final s in lv.subjects) {
        allSubjectIdToName[s.id] = s.name.trim().toLowerCase();
      }
    }
    final qualMap = <String, Set<String>>{
      for (final t in teachers)
        t.id: {
          for (final sid in t.subjectIds)
            if (allSubjectIdToName.containsKey(sid)) allSubjectIdToName[sid]!,
        },
    };

    final queue = <Subject>[];
    for (final s in level.subjects) {
      final count = periodsNeeded(s);
      for (int i = 0; i < count; i++) queue.add(s);
    }

    if (queue.length > total) {
      queue.shuffle(rng);
      final counts = <String, int>{};
      for (final s in queue) {
        counts[s.id] = (counts[s.id] ?? 0) + 1;
      }
      final scale = total / queue.length;
      final newCounts = <String, int>{};
      for (final entry in counts.entries) {
        newCounts[entry.key] = (entry.value * scale).floor().clamp(
          1,
          entry.value,
        );
      }
      final trimmed = <Subject>[];
      for (final s in level.subjects) {
        final n = newCounts[s.id] ?? 0;
        for (int i = 0; i < n; i++) trimmed.add(s);
      }
      queue
        ..clear()
        ..addAll(trimmed.take(total));
    }

    queue.shuffle(rng);
    queue.sort((a, b) {
      int count(Subject s) => teachers.where((t) {
        if (allowed.isNotEmpty && !allowed.contains(t.id)) return false;
        return qualMap[t.id]?.contains(s.name.trim().toLowerCase()) ?? false;
      }).length;
      return count(a).compareTo(count(b));
    });

    // Build slot pool using actual working day indices
    final slotPool = <_DP>[
      for (final dayIdx in workingDays)
        for (int p = 0; p < ppd; p++) _DP(dayIdx, p),
    ]..shuffle(rng);

    final trimmedPool = slotPool.take(queue.length).toList();

    final subjectDays = <String, Set<int>>{
      for (final s in level.subjects) s.id: {},
    };
    final assignments = <_Assign>[];
    final pool = List<_DP>.from(trimmedPool);

    for (final subject in queue) {
      final used = subjectDays[subject.id] ?? {};
      pool.sort(
        (a, b) => (used.contains(a.day) ? 1 : 0).compareTo(
          used.contains(b.day) ? 1 : 0,
        ),
      );
      if (pool.isEmpty) break;
      final chosen = pool.removeAt(0);
      subjectDays[subject.id]?.add(chosen.day);
      assignments.add(_Assign(slot: chosen, subject: subject));
    }

    final globalBusy = <String, Map<int, Set<int>>>{
      for (final t in teachers)
        t.id: {for (int d = 0; d < kAllDays.length; d++) d: {}},
    };
    for (final slot in timetable) {
      if (slot.teacherId != null)
        globalBusy[slot.teacherId!]?[slot.day]?.add(slot.period);
    }

    final hoursUsed = <String, int>{
      for (final t in teachers)
        t.id: timetable.where((s) => s.teacherId == t.id).length,
    };

    final result = <TimetableSlot>[];

    _solve(
      assignments: assignments,
      index: 0,
      result: result,
      levelId: level.id,
      qualMap: qualMap,
      allowed: allowed,
      globalBusy: globalBusy,
      hoursUsed: hoursUsed,
      rng: rng,
    );

    timetable.addAll(result);
    _notify();
    return null;
  }

  bool _solve({
    required List<_Assign> assignments,
    required int index,
    required List<TimetableSlot> result,
    required String levelId,
    required Map<String, Set<String>> qualMap,
    required Set<String> allowed,
    required Map<String, Map<int, Set<int>>> globalBusy,
    required Map<String, int> hoursUsed,
    required Random rng,
  }) {
    if (index == assignments.length) return true;

    int bestIdx = index;
    int bestCnt = _eligible(
      assignments[index],
      qualMap,
      allowed,
      globalBusy,
      hoursUsed,
    ).length;
    for (int i = index + 1; i < assignments.length; i++) {
      final c = _eligible(
        assignments[i],
        qualMap,
        allowed,
        globalBusy,
        hoursUsed,
      ).length;
      if (c < bestCnt) {
        bestCnt = c;
        bestIdx = i;
      }
    }
    if (bestIdx != index) {
      final tmp = assignments[index];
      assignments[index] = assignments[bestIdx];
      assignments[bestIdx] = tmp;
    }

    final cur = assignments[index];
    final sl = cur.slot;
    var eligible = _eligible(cur, qualMap, allowed, globalBusy, hoursUsed);

    if (eligible.isEmpty) {
      for (int j = index + 1; j < assignments.length; j++) {
        final other = assignments[j];
        final othElig = _eligibleForSubject(
          other.subject,
          sl,
          qualMap,
          allowed,
          globalBusy,
          hoursUsed,
        );
        if (othElig.isEmpty) continue;
        final curCanBePlaced = teachers.any((t) {
          if (allowed.isNotEmpty && !allowed.contains(t.id)) return false;
          return qualMap[t.id]?.contains(
                cur.subject.name.trim().toLowerCase(),
              ) ??
              false;
        });
        if (!curCanBePlaced) continue;
        assignments[index] = _Assign(slot: sl, subject: other.subject);
        assignments[j] = _Assign(slot: other.slot, subject: cur.subject);
        eligible = _eligible(
          assignments[index],
          qualMap,
          allowed,
          globalBusy,
          hoursUsed,
        );
        if (eligible.isNotEmpty) break;
        assignments[index] = cur;
        assignments[j] = other;
      }
    }

    if (eligible.isEmpty) {
      result.add(
        TimetableSlot(
          levelId: levelId,
          day: sl.day,
          period: sl.period,
          subjectId: assignments[index].subject.id,
          teacherId: null,
        ),
      );
      final ok = _solve(
        assignments: assignments,
        index: index + 1,
        result: result,
        levelId: levelId,
        qualMap: qualMap,
        allowed: allowed,
        globalBusy: globalBusy,
        hoursUsed: hoursUsed,
        rng: rng,
      );
      if (!ok) result.removeLast();
      return ok;
    }

    eligible.shuffle(rng);
    eligible.sort((a, b) {
      final aRem = a.maxHoursPerWeek - (hoursUsed[a.id] ?? 0);
      final bRem = b.maxHoursPerWeek - (hoursUsed[b.id] ?? 0);
      if (aRem != bRem) return bRem.compareTo(aRem);
      return _futureDemand(
        b.id,
        assignments,
        index + 1,
        qualMap,
      ).compareTo(_futureDemand(a.id, assignments, index + 1, qualMap));
    });

    for (final teacher in eligible) {
      globalBusy[teacher.id]![sl.day]!.add(sl.period);
      hoursUsed[teacher.id] = (hoursUsed[teacher.id] ?? 0) + 1;
      result.add(
        TimetableSlot(
          levelId: levelId,
          day: sl.day,
          period: sl.period,
          subjectId: assignments[index].subject.id,
          teacherId: teacher.id,
        ),
      );
      final ok = _solve(
        assignments: assignments,
        index: index + 1,
        result: result,
        levelId: levelId,
        qualMap: qualMap,
        allowed: allowed,
        globalBusy: globalBusy,
        hoursUsed: hoursUsed,
        rng: rng,
      );
      if (ok) return true;
      globalBusy[teacher.id]![sl.day]!.remove(sl.period);
      hoursUsed[teacher.id] = (hoursUsed[teacher.id] ?? 0) - 1;
      result.removeLast();
    }

    return false;
  }

  List<Teacher> _eligible(
    _Assign item,
    Map<String, Set<String>> qualMap,
    Set<String> allowed,
    Map<String, Map<int, Set<int>>> globalBusy,
    Map<String, int> hoursUsed,
  ) => _eligibleForSubject(
    item.subject,
    item.slot,
    qualMap,
    allowed,
    globalBusy,
    hoursUsed,
  );

  List<Teacher> _eligibleForSubject(
    Subject subject,
    _DP slot,
    Map<String, Set<String>> qualMap,
    Set<String> allowed,
    Map<String, Map<int, Set<int>>> globalBusy,
    Map<String, int> hoursUsed,
  ) {
    final name = subject.name.trim().toLowerCase();
    return teachers.where((t) {
      if (allowed.isNotEmpty && !allowed.contains(t.id)) return false;
      if (!(qualMap[t.id]?.contains(name) ?? false)) return false;
      if (globalBusy[t.id]?[slot.day]?.contains(slot.period) ?? false)
        return false;
      if ((hoursUsed[t.id] ?? 0) >= t.maxHoursPerWeek) return false;
      return true;
    }).toList();
  }

  int _futureDemand(
    String teacherId,
    List<_Assign> assignments,
    int from,
    Map<String, Set<String>> qualMap,
  ) {
    final names = qualMap[teacherId] ?? {};
    int c = 0;
    for (int i = from; i < assignments.length; i++) {
      if (names.contains(assignments[i].subject.name.trim().toLowerCase())) c++;
    }
    return c;
  }

  // ── Manual edit ────────────────────────────────────────────────────────────

  String? editSlot(
    String levelId,
    int day,
    int period,
    String? subjectId,
    String? teacherId,
  ) {
    if (teacherId != null) {
      final conflict = timetable.any(
        (s) =>
            s.teacherId == teacherId &&
            s.day == day &&
            s.period == period &&
            !(s.levelId == levelId && s.day == day && s.period == period),
      );
      if (conflict) {
        final teacher = teachers.firstWhere((t) => t.id == teacherId);
        return 'Teacher "${teacher.name}" is already assigned at this time slot.';
      }
    }
    final idx = timetable.indexWhere(
      (s) => s.levelId == levelId && s.day == day && s.period == period,
    );
    if (idx >= 0) {
      timetable[idx].subjectId = subjectId;
      timetable[idx].teacherId = teacherId;
    } else {
      timetable.add(
        TimetableSlot(
          levelId: levelId,
          day: day,
          period: period,
          subjectId: subjectId,
          teacherId: teacherId,
        ),
      );
    }
    _notify();
    return null;
  }

  TimetableSlot? getSlot(String levelId, int day, int period) {
    try {
      return timetable.firstWhere(
        (s) => s.levelId == levelId && s.day == day && s.period == period,
      );
    } catch (_) {
      return null;
    }
  }

  List<TimetableSlot> getTeacherSlots(String teacherId) =>
      timetable.where((s) => s.teacherId == teacherId).toList();
}

class _DP {
  final int day, period;
  const _DP(this.day, this.period);
}

class _Assign {
  final _DP slot;
  final Subject subject;
  const _Assign({required this.slot, required this.subject});
}

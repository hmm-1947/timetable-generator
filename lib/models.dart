class Subject {
  String id;
  String name;
  double hoursPerWeek; // renamed from periodsPerWeek

  Subject({required this.id, required this.name, required this.hoursPerWeek});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hoursPerWeek': hoursPerWeek,
    // keep backward compat alias
    'periodsPerWeek': hoursPerWeek,
  };

  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
    id: j['id'],
    name: j['name'],
    // support both old 'periodsPerWeek' and new 'hoursPerWeek' keys
    hoursPerWeek: (j['hoursPerWeek'] ?? j['periodsPerWeek'] ?? 1).toDouble(),
  );
}

class Level {
  String id;
  String name;
  List<Subject> subjects;
  String? groupId;
  int periodsPerDay;

  /// Teacher IDs allowed to teach in this level.
  /// Empty list = no restriction (all qualified teachers allowed).
  List<String> allowedTeacherIds;

  Level({
    required this.id,
    required this.name,
    List<Subject>? subjects,
    this.groupId,
    this.periodsPerDay = 6,
    List<String>? allowedTeacherIds,
  }) : subjects = subjects ?? [],
       allowedTeacherIds = allowedTeacherIds ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subjects': subjects.map((s) => s.toJson()).toList(),
    'groupId': groupId,
    'periodsPerDay': periodsPerDay,
    'allowedTeacherIds': allowedTeacherIds,
  };

  factory Level.fromJson(Map<String, dynamic> j) => Level(
    id: j['id'],
    name: j['name'],
    subjects: (j['subjects'] as List)
        .map((s) => Subject.fromJson(s as Map<String, dynamic>))
        .toList(),
    groupId: j['groupId'],
    periodsPerDay: j['periodsPerDay'] ?? 6,
    allowedTeacherIds: List<String>.from(j['allowedTeacherIds'] ?? []),
  );
}

class LevelGroup {
  String id;
  String name;

  /// Teacher IDs allowed for ALL levels in this group (union with level list).
  List<String> allowedTeacherIds;

  LevelGroup({
    required this.id,
    required this.name,
    List<String>? allowedTeacherIds,
  }) : allowedTeacherIds = allowedTeacherIds ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'allowedTeacherIds': allowedTeacherIds,
  };

  factory LevelGroup.fromJson(Map<String, dynamic> j) => LevelGroup(
    id: j['id'],
    name: j['name'],
    allowedTeacherIds: List<String>.from(j['allowedTeacherIds'] ?? []),
  );
}

class Teacher {
  String id;
  String name;
  String employeeId;
  int maxHoursPerWeek;
  List<String> subjectIds;

  Teacher({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.maxHoursPerWeek,
    List<String>? subjectIds,
  }) : subjectIds = subjectIds ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'employeeId': employeeId,
    'maxHoursPerWeek': maxHoursPerWeek,
    'subjectIds': subjectIds,
  };

  factory Teacher.fromJson(Map<String, dynamic> j) => Teacher(
    id: j['id'],
    name: j['name'],
    employeeId: j['employeeId'],
    maxHoursPerWeek: j['maxHoursPerWeek'],
    subjectIds: List<String>.from(j['subjectIds'] ?? []),
  );
}

class TimetableSlot {
  String levelId;
  int day;
  int period;
  String? subjectId;
  String? teacherId;

  TimetableSlot({
    required this.levelId,
    required this.day,
    required this.period,
    this.subjectId,
    this.teacherId,
  });

  Map<String, dynamic> toJson() => {
    'levelId': levelId,
    'day': day,
    'period': period,
    'subjectId': subjectId,
    'teacherId': teacherId,
  };

  factory TimetableSlot.fromJson(Map<String, dynamic> j) => TimetableSlot(
    levelId: j['levelId'],
    day: j['day'],
    period: j['period'],
    subjectId: j['subjectId'],
    teacherId: j['teacherId'],
  );
}

/// Stores the daily schedule timing (same for all days).
class DayTiming {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  /// Break duration in minutes inserted between each period (0 = no break).
  final int breakMinutes;

  const DayTiming({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.breakMinutes = 0,
  });

  Map<String, dynamic> toJson() => {
    'startHour': startHour,
    'startMinute': startMinute,
    'endHour': endHour,
    'endMinute': endMinute,
    'breakMinutes': breakMinutes,
  };

  factory DayTiming.fromJson(Map<String, dynamic> j) => DayTiming(
    startHour: j['startHour'] ?? 8,
    startMinute: j['startMinute'] ?? 0,
    endHour: j['endHour'] ?? 14,
    endMinute: j['endMinute'] ?? 0,
    breakMinutes: j['breakMinutes'] ?? 0,
  );

  /// Total available minutes in the school day.
  int get totalMinutes =>
      (endHour * 60 + endMinute) - (startHour * 60 + startMinute);

  /// Duration of each period given [periodsPerDay].
  int periodDurationMinutes(int periodsPerDay) {
    if (periodsPerDay <= 0) return 0;
    final usable = totalMinutes - breakMinutes * (periodsPerDay - 1);
    return (usable / periodsPerDay).floor();
  }

  /// Start time string for period [index] (0-based).
  String periodStartLabel(int index, int periodsPerDay) {
    final dur = periodDurationMinutes(periodsPerDay);
    final offset = index * (dur + breakMinutes);
    final total = startHour * 60 + startMinute + offset;
    return _fmt(total ~/ 60, total % 60);
  }

  /// End time string for period [index] (0-based).
  String periodEndLabel(int index, int periodsPerDay) {
    final dur = periodDurationMinutes(periodsPerDay);
    final offset = index * (dur + breakMinutes) + dur;
    final total = startHour * 60 + startMinute + offset;
    return _fmt(total ~/ 60, total % 60);
  }

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

const List<String> kDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
const int kPeriodsPerDay = 8;

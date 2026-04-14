import 'package:flutter/material.dart';
import 'models.dart';

// ═══════════════════════════════════════════════════════════════════════════
// App-wide constants
// ═══════════════════════════════════════════════════════════════════════════

const kAccent = Color(0xFF00E5CC);
const kCardColor = Color(0xFF1E1E2C);
const kBg = Color(0xFF12121C);

// ═══════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═══════════════════════════════════════════════════════════════════════════

class AppSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final String? actionTooltip;

  const AppSearchBar({
    super.key,
    required this.onChanged,
    this.onAction,
    this.actionIcon,
    this.actionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kCardColor,
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
                icon: Icon(actionIcon, color: kAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppDialog extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final VoidCallback onSave;

  const AppDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kCardColor,
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
            backgroundColor: kAccent,
            foregroundColor: Colors.black,
          ),
          onPressed: onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared helper functions
// ═══════════════════════════════════════════════════════════════════════════

Widget infoChip(String text) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: kAccent.withOpacity(0.08),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: kAccent.withOpacity(0.25)),
  ),
  child: Row(
    children: [
      Icon(Icons.info_outline, color: kAccent.withOpacity(0.7), size: 14),
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

Widget appChip(String label) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(
    color: kAccent.withOpacity(0.15),
    borderRadius: BorderRadius.circular(6),
  ),
  child: Text(
    label,
    style: TextStyle(color: kAccent.withOpacity(0.8), fontSize: 10),
  ),
);

Widget appCheckbox(bool checked) => AnimatedContainer(
  duration: const Duration(milliseconds: 150),
  width: 18,
  height: 18,
  decoration: BoxDecoration(
    color: checked ? kAccent : Colors.transparent,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: checked ? kAccent : Colors.white38),
  ),
  child: checked
      ? const Icon(Icons.check, size: 12, color: Colors.black)
      : null,
);

Widget teacherSearchBox(String current, ValueChanged<String> onChanged) =>
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

Widget teacherCheckList(
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
                      appCheckbox(isSelected),
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

Widget appHeaderCell(String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
  child: Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: kAccent,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    ),
  ),
);

Widget appCell(String text, {bool accent = false}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
  child: Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(color: accent ? kAccent : Colors.white70, fontSize: 12),
  ),
);

Widget kEmpty(String msg) => Center(
  child: Text(
    msg,
    textAlign: TextAlign.center,
    style: const TextStyle(color: Colors.white38, fontSize: 15),
  ),
);

Widget appField(
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
  decoration: appInputDec(label),
);

InputDecoration appInputDec(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: Colors.white54),
  enabledBorder: const UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.white24),
  ),
  focusedBorder: const UnderlineInputBorder(
    borderSide: BorderSide(color: kAccent),
  ),
);

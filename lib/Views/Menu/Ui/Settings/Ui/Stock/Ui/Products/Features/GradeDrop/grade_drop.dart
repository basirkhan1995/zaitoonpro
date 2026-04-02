import 'package:flutter/material.dart';
import '../../../../../../../../../../Features/Generic/zaitoon_drop.dart';


class GradeDropdown extends StatefulWidget {
  final String? selectedGrade;
  final ValueChanged<String> onGradeSelected;

  const GradeDropdown({
    super.key,
    this.selectedGrade,
    required this.onGradeSelected,
  });

  @override
  State<GradeDropdown> createState() => _GradeDropdownState();
}

class _GradeDropdownState extends State<GradeDropdown> {
  final List<String> _grades = ['A', 'B', 'C', 'D'];

  String? _selected;

  @override
  void initState() {
    super.initState();

    _selected = widget.selectedGrade ?? _grades.first;

    // Notify initial value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onGradeSelected(_selected!);
    });
  }

  @override
  void didUpdateWidget(covariant GradeDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedGrade != oldWidget.selectedGrade) {
      setState(() {
        _selected = widget.selectedGrade ?? _grades.first;
      });
    }
  }

  void _onSelect(String grade) {
    setState(() => _selected = grade);
    widget.onGradeSelected(grade);
  }

  @override
  Widget build(BuildContext context) {
    return ZDropdown<String>(
      title: "Grade",
      items: _grades,
      selectedItem: _selected,
      itemLabel: (g) => g,
      onItemSelected: _onSelect,
      leadingBuilder: (_) => const Icon(Icons.grade, size: 18),
    );
  }
}
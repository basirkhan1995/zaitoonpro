import 'package:equatable/equatable.dart';

class ProjectStatsModel extends Equatable {
  final int activeProjects;
  final int completedProjects;
  final int allProjects;
  final double completedIncome;
  final double completedExpenses;
  final double completedNetProfit;

  const ProjectStatsModel({
    required this.activeProjects,
    required this.completedProjects,
    required this.allProjects,
    required this.completedIncome,
    required this.completedExpenses,
    required this.completedNetProfit,
  });

  factory ProjectStatsModel.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ProjectStatsModel(
      activeProjects: toInt(map['active_projects']),
      completedProjects: toInt(map['completed_projects']),
      allProjects: toInt(map['all_projects']),
      completedIncome: toDouble(map['completed_income']),
      completedExpenses: toDouble(map['completed_expenses']),
      completedNetProfit: toDouble(map['completed_net_profit']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'active_projects': activeProjects,
      'completed_projects': completedProjects,
      'all_projects': allProjects,
      'completed_income': completedIncome,
      'completed_expenses': completedExpenses,
      'completed_net_profit': completedNetProfit,
    };
  }

  bool get hasData {
    return activeProjects > 0 ||
        completedProjects > 0 ||
        allProjects > 0 ||
        completedIncome > 0 ||
        completedExpenses > 0 ||
        completedNetProfit > 0;
  }

  @override
  List<Object?> get props => [
    activeProjects,
    completedProjects,
    allProjects,
    completedIncome,
    completedExpenses,
    completedNetProfit,
  ];
}
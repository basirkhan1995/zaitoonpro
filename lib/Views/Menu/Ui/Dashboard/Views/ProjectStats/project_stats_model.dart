import 'package:equatable/equatable.dart';

class ProjectStatsModel extends Equatable {
  // Project Stats
  final int activeProjects;
  final int completedProjects;
  final int allProjects;

  // Financial Stats (from entire ERP)
  final double totalIncome;
  final double totalExpense;
  final double netProfit;

  const ProjectStatsModel({
    required this.activeProjects,
    required this.completedProjects,
    required this.allProjects,
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfit,
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
      totalIncome: toDouble(map['total_income']),
      totalExpense: toDouble(map['total_expense']),
      netProfit: toDouble(map['net_profit']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'active_projects': activeProjects,
      'completed_projects': completedProjects,
      'all_projects': allProjects,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'net_profit': netProfit,
    };
  }

  bool get hasData {
    return activeProjects > 0 ||
        completedProjects > 0 ||
        allProjects > 0 ||
        totalIncome > 0 ||
        totalExpense > 0 ||
        netProfit > 0;
  }

  @override
  List<Object?> get props => [
    activeProjects,
    completedProjects,
    allProjects,
    totalIncome,
    totalExpense,
    netProfit,
  ];
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/alert_dialog.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/search_field.dart';
import 'package:zaitoonpro/Features/Widgets/status_badge.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/AllProjects/model/pjr_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/project_view.dart';
import '../../../../../../Features/Generic/zaitoon_drop.dart';
import '../../../../../../Features/Widgets/zcard_mobile.dart';
import '../../../../../Auth/models/login_model.dart';
import 'add_project.dart';
import 'bloc/projects_bloc.dart';

class AllProjectsView extends StatelessWidget {
  const AllProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _Mobile(),
      desktop: _Desktop(),
      tablet: _Tablet(),
    );
  }
}

enum ProjectStatus { all, inProgress, completed }

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final String _filterStatus = 'All';
  List<String> _selectedStatuses = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsBloc>().add(LoadProjectsEvent());
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> onRefresh() async {
    context.read<ProjectsBloc>().add(LoadProjectsEvent());
  }

  final findProjectById = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = authState.loginData;
    return Scaffold(
      backgroundColor: color.surface,
      body: Column(
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.projects,
                          style: textTheme.headlineSmall?.copyWith(
                            color: color.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage and track all your projects',
                          style: textTheme.bodyMedium?.copyWith(
                            color: color.onSurface.withValues(alpha: .8),
                          ),
                        ),
                      ],
                    ),
                    if (login.hasPermission(47) ?? false)
                    ZOutlineButton(
                      isActive: true,
                      icon: Icons.add,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddNewProjectView(),
                        );
                      },

                      label: Text(tr.newProject),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search and filter bar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Search field
                    Expanded(
                      flex: 3,
                      child: ZSearchField(
                        title: "",
                        hint: "Search project name",
                        icon: Icons.search,
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ZTextFieldEntitled(
                        controller: findProjectById,
                        title: "",
                        hint: "Find project by ID",
                        onSubmit: (e) {
                          context.read<ProjectsBloc>().add(
                            LoadProjectsEvent(
                              prjId: int.tryParse(findProjectById.text),
                            ),
                          );
                        },
                        trailing: IconButton(
                          onPressed: () {
                            findProjectById.clear();
                            context.read<ProjectsBloc>().add(
                              LoadProjectsEvent(),
                            );
                          },
                          icon: Icon(Icons.clear),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      flex: 1,
                      child: ZDropdown<String>(
                        onItemSelected: (e) {},
                        title: "",
                        items: [tr.inProgress, tr.completed],
                        itemLabel: (item) => item,
                        multiSelect: true,
                        selectedItems: _selectedStatuses,
                        onMultiSelectChanged: (selected) {
                          setState(() {
                            _selectedStatuses = selected;
                          });
                        },
                        initialValue: tr.all,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ZOutlineButton(
                      onPressed: onRefresh,
                      icon: Icons.refresh,
                      height: 47,
                      label: Text(tr.refresh),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            child: BlocBuilder<ProjectsBloc, ProjectsState>(
              builder: (context, state) {
                if (state is ProjectsLoadedState) {
                  final totalProjects = state.pjr.length;
                  final completed = state.pjr
                      .where((p) => p.prjStatus == 1)
                      .length;
                  final pending = state.pjr
                      .where((p) => p.prjStatus == 0)
                      .length;

                  return Row(
                    children: [
                      _buildStatCard(
                        title: tr.totalProjectTitle,
                        value: totalProjects.toString(),
                        icon: Icons.folder_copy,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(),
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        title: tr.completed,
                        value: completed.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        title: tr.inProgress,
                        value: pending.toString(),
                        icon: Icons.pending,
                        color: Colors.orange,
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ),

          // Projects list
          Expanded(
            child: BlocConsumer<ProjectsBloc, ProjectsState>(
              listener: (context, state) {
                if (state is ProjectSuccessState) {
                  ToastManager.show(
                    context: context,
                    title: tr.successTitle,
                    message: tr.successMessage,
                    type: ToastType.success,
                  );
                }
                if (state is ProjectsErrorState) {
                  ToastManager.show(
                    context: context,
                    title: tr.errorTitle,
                    message: state.message,
                    type: ToastType.error,
                  );
                }
              },
              builder: (context, state) {
                if (state is ProjectsLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProjectsErrorState) {
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                    onRefresh: onRefresh,
                  );
                }
                if (state is ProjectsLoadedState) {
                  // Filter projects based on search and status
                  var filteredProjects = state.pjr.where((project) {
                    final matchesSearch =
                        _searchQuery.isEmpty ||
                        (project.prjName?.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ??
                            false) ||
                        (project.prjDetails?.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ??
                            false);

                    final matchesStatus =
                        _selectedStatuses.isEmpty ||
                        _selectedStatuses.contains(
                          project.prjStatus == 1 ? 'Completed' : 'In Progress',
                        );

                    return matchesSearch && matchesStatus;
                  }).toList();

                  if (filteredProjects.isEmpty) {
                    return NoDataWidget(
                      title: "No Projects Found",
                      message: _searchQuery.isNotEmpty || _filterStatus != 'All'
                          ? "Try adjusting your search or filters"
                          : "Click the button above to create your first project",
                      enableAction: false,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: onRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final pjr = filteredProjects[index];
                        return _buildProjectCard(
                          pjr,
                          index,
                          color,
                          textTheme,
                          tr,
                        );
                      },
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withValues(alpha: .2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(
    ProjectsModel pjr,
    int index,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations tr,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: index.isOdd
            ? color.primary.withValues(alpha: .02)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey.withValues(alpha: .1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => ProjectView(project: pjr),
            );
          },
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${pjr.prjId}',
                        style: TextStyle(
                          color: color.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pjr.prjName ?? '',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (pjr.prjDetails != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            pjr.prjDetails ?? "",
                            style: textTheme.bodySmall?.copyWith(
                              color: color.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: color.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pjr.prjDateLine.toFormattedDate(),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDeadlineColor(
                        pjr.prjDateLine,
                      ).withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getDeadlineIcon(pjr.prjDateLine),
                          size: 14,
                          color: _getDeadlineColor(pjr.prjDateLine),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pjr.prjDateLine?.daysLeftText ?? '',
                          style: textTheme.bodySmall?.copyWith(
                            color: _getDeadlineColor(pjr.prjDateLine),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 115,
                  child: StatusBadge(
                    status: pjr.prjStatus!,
                    trueValue: tr.completed,
                    falseValue: tr.inProgress,
                  ),
                ),

                Expanded(
                  flex: 0,
                  child: IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    onPressed: () {
                      _showProjectMenu(context, pjr);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDeadlineColor(DateTime? deadline) {
    if (deadline == null) return Colors.grey;
    final days = deadline.daysLeft ?? 0;
    if (days > 7) return Colors.green;
    if (days > 3) return Colors.orange;
    if (days >= 0) return Colors.deepOrange;
    return Colors.red;
  }

  IconData _getDeadlineIcon(DateTime? deadline) {
    if (deadline == null) return Icons.help_outline;
    final days = deadline.daysLeft ?? 0;
    if (days > 7) return Icons.check_circle_outline;
    if (days > 3) return Icons.access_time;
    if (days >= 0) return Icons.warning_amber;
    return Icons.error_outline;
  }

  void _showProjectMenu(BuildContext context, dynamic project) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => ProjectView(project: project),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, project);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProjectsModel project) {
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {

          String? userName;

          if (state is AuthenticatedState) {
            userName = state.loginData.usrName;
          }

          return ZAlertDialog(
            title: AppLocalizations.of(context)!.areYouSure,
            content: 'Do you want to delete "${project.prjName}"?',
            onYes: () {

              if (userName != null) {
                context.read<ProjectsBloc>().add(
                  DeleteProjectEvent(
                    project.prjId!,
                    userName,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedStatuses = [];
  bool _showFilters = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsBloc>().add(LoadProjectsEvent());
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> onRefresh() async {
    context.read<ProjectsBloc>().add(LoadProjectsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = authState.loginData;
    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(
          tr.projects,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Filter button with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
              ),
              if (_selectedStatuses.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_selectedStatuses.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
            ],
          ),
          if (login.hasPermission(47) ?? false)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddNewProjectView(),
              );
            },
          ),
        ],
        bottom: _showFilters
            ? PreferredSize(
                preferredSize: const Size.fromHeight(30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ZDropdown<String>(
                    onItemSelected: (e) {},
                    title: "",
                    items: [tr.inProgress, tr.completed],
                    itemLabel: (item) => item,
                    multiSelect: true,
                    selectedItems: _selectedStatuses,
                    onMultiSelectChanged: (selected) {
                      setState(() {
                        _selectedStatuses = selected;
                      });
                    },
                    initialValue: 'All Status',
                    height: 40,
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ZSearchField(
              title: "",
              hint: "Search projects",
              icon: Icons.search,
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Stats cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: BlocBuilder<ProjectsBloc, ProjectsState>(
              builder: (context, state) {
                if (state is ProjectsLoadedState) {
                  final totalProjects = state.pjr.length;
                  final completed = state.pjr
                      .where((p) => p.prjStatus == 1)
                      .length;
                  final pending = state.pjr
                      .where((p) => p.prjStatus == 0)
                      .length;

                  return Row(
                    children: [
                      _buildStatCard(
                        title: 'Total',
                        value: totalProjects.toString(),
                        icon: Icons.folder_copy,
                        color: color.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        title: tr.completed,
                        value: completed.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        title: tr.inProgress,
                        value: pending.toString(),
                        icon: Icons.pending,
                        color: Colors.orange,
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ),

          const SizedBox(height: 8),

          // Projects list
          Expanded(
            child: BlocConsumer<ProjectsBloc, ProjectsState>(
              listener: (context, state) {
                if (state is ProjectSuccessState) {
                  ToastManager.show(
                    context: context,
                    message: tr.successMessage,
                    type: ToastType.success,
                  );
                }
                if (state is ProjectsErrorState) {
                  ToastManager.show(
                    context: context,
                    message: state.message,
                    type: ToastType.error,
                  );
                }
              },
              builder: (context, state) {
                if (state is ProjectsLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProjectsErrorState) {
                  return NoDataWidget(
                    title: "Error",
                    message: state.message,
                    onRefresh: onRefresh,
                  );
                }
                if (state is ProjectsLoadedState) {
                  // Filter projects
                  var filteredProjects = state.pjr.where((project) {
                    final matchesSearch =
                        _searchQuery.isEmpty ||
                        (project.prjName?.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ??
                            false) ||
                        (project.prjDetails?.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ??
                            false);

                    final matchesStatus =
                        _selectedStatuses.isEmpty ||
                        _selectedStatuses.contains(
                          project.prjStatus == 1 ? tr.completed : tr.inProgress,
                        );

                    return matchesSearch && matchesStatus;
                  }).toList();

                  if (filteredProjects.isEmpty) {
                    return NoDataWidget(
                      title: "No Projects Found",
                      message:
                          _searchQuery.isNotEmpty ||
                              _selectedStatuses.isNotEmpty
                          ? "Try adjusting your search or filters"
                          : "Tap the + button to create your first project",
                      enableAction: false,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: onRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final pjr = filteredProjects[index];
                        return _buildMobileProjectCard(pjr, context, tr);
                      },
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileProjectCard(
    ProjectsModel pjr,
    BuildContext context,
    AppLocalizations tr,
  ) {
    final color = Theme.of(context).colorScheme;

    // Create info items for the card
    final List<MobileInfoItem> infoItems = [
      MobileInfoItem(
        icon: Icons.calendar_today,
        text: pjr.prjDateLine.toFormattedDate(),
        iconColor: color.primary,
      ),
      MobileInfoItem(
        icon: Icons.timer,
        text: pjr.prjDateLine?.daysLeftText ?? 'No deadline',
        iconColor: _getDeadlineColor(pjr.prjDateLine),
      ),
      if (pjr.prjLocation != null && pjr.prjLocation!.isNotEmpty)
        MobileInfoItem(
          icon: Icons.location_on,
          text: pjr.prjLocation!,
          iconColor: Colors.blue,
        ),
    ];

    return MobileInfoCard(
      title: pjr.prjName ?? 'Unnamed Project',
      subtitle: pjr.prjDetails,
      imageUrl: null, // You can add project image if available
      infoItems: infoItems,
      status: MobileStatus(
        label: pjr.prjStatus == 1 ? tr.completed : tr.inProgress,
        color: pjr.prjStatus == 1 ? Colors.green : Colors.orange,
        backgroundColor: (pjr.prjStatus == 1 ? Colors.green : Colors.orange)
            .withValues(alpha: .1),
      ),
      onTap: () {
        Utils.goto(context, ProjectView(project: pjr));
      },
      accentColor: color.primary,
      showActions: true,
    );
  }

  Color _getDeadlineColor(DateTime? deadline) {
    if (deadline == null) return Colors.grey;
    final days = deadline.daysLeft ?? 0;
    if (days > 7) return Colors.green;
    if (days > 3) return Colors.orange;
    if (days >= 0) return Colors.deepOrange;
    return Colors.red;
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}
class _TabletState extends State<_Tablet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedStatuses = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsBloc>().add(LoadProjectsEvent());
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> onRefresh() async {
    context.read<ProjectsBloc>().add(LoadProjectsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = authState.loginData;
    return Scaffold(
      backgroundColor: color.surface,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.projects,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage and track all your projects',
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.onSurface.withValues(alpha: .8),
                      ),
                    ),
                  ],
                ),
                if (login.hasPermission(47) ?? false)
                ZOutlineButton(
                  isActive: true,
                  icon: Icons.add,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddNewProjectView(),
                    );
                  },
                  label: Text(tr.newProject),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search and filter in one row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: ZSearchField(
                    title: "",
                    hint: "Search projects",
                    icon: Icons.search,
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ZDropdown<String>(
                    onItemSelected: (e) {},
                    title: "",
                    items: [tr.inProgress, tr.completed],
                    itemLabel: (item) => item,
                    multiSelect: true,
                    selectedItems: _selectedStatuses,
                    onMultiSelectChanged: (selected) {
                      setState(() {
                        _selectedStatuses = selected;
                      });
                    },
                    initialValue: 'All Status',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats cards
            BlocBuilder<ProjectsBloc, ProjectsState>(
              builder: (context, state) {
                if (state is ProjectsLoadedState) {
                  final totalProjects = state.pjr.length;
                  final completed = state.pjr
                      .where((p) => p.prjStatus == 1)
                      .length;
                  final pending = state.pjr
                      .where((p) => p.prjStatus == 0)
                      .length;

                  return Row(
                    children: [
                      _buildStatCard(
                        title: 'Total Projects',
                        value: totalProjects.toString(),
                        icon: Icons.folder_copy,
                        color: color.primary,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: tr.completed,
                        value: completed.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: tr.inProgress,
                        value: pending.toString(),
                        icon: Icons.pending,
                        color: Colors.orange,
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 20),

            // Projects list - Using ListView like mobile
            Expanded(
              child: BlocConsumer<ProjectsBloc, ProjectsState>(
                listener: (context, state) {
                  if (state is ProjectSuccessState) {
                    ToastManager.show(
                      context: context,
                      message: tr.successMessage,
                      type: ToastType.success,
                    );
                    Navigator.of(context).pop();
                  }
                  if (state is ProjectsErrorState) {
                    ToastManager.show(
                      context: context,
                      message: state.message,
                      type: ToastType.error,
                    );
                  }
                },
                builder: (context, state) {
                  if (state is ProjectsLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ProjectsErrorState) {
                    return NoDataWidget(
                      title: "Error",
                      message: state.message,
                      onRefresh: onRefresh,
                    );
                  }
                  if (state is ProjectsLoadedState) {
                    // Filter projects
                    var filteredProjects = state.pjr.where((project) {
                      final matchesSearch =
                          _searchQuery.isEmpty ||
                          (project.prjName?.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ??
                              false) ||
                          (project.prjDetails?.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ??
                              false);

                      final matchesStatus =
                          _selectedStatuses.isEmpty ||
                          _selectedStatuses.contains(
                            project.prjStatus == 1
                                ? tr.completed
                                : tr.inProgress,
                          );

                      return matchesSearch && matchesStatus;
                    }).toList();

                    if (filteredProjects.isEmpty) {
                      return NoDataWidget(
                        title: "No Projects Found",
                        message:
                            _searchQuery.isNotEmpty ||
                                _selectedStatuses.isNotEmpty
                            ? "Try adjusting your search or filters"
                            : "Click the button above to create your first project",
                        enableAction: false,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: onRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final pjr = filteredProjects[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildTabletProjectCard(pjr, context, tr),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletProjectCard(
    ProjectsModel pjr,
    BuildContext context,
    AppLocalizations tr,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.outline.withValues(alpha: .1), width: 1),
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => ProjectView(project: pjr),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with ID, name and status
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${pjr.prjId}',
                        style: TextStyle(
                          color: color.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pjr.prjName ?? '',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (pjr.prjStatus == 1 ? Colors.green : Colors.orange)
                          .withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pjr.prjStatus == 1 ? tr.completed : tr.inProgress,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: pjr.prjStatus == 1
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),

              // Details
              if (pjr.prjDetails != null && pjr.prjDetails!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  pjr.prjDetails!,
                  style: textTheme.bodySmall?.copyWith(color: color.outline),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 14),

              // Info row with date, deadline and location
              Row(
                children: [
                  // Date
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: color.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pjr.prjDateLine.toFormattedDate(),
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // Days left
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDeadlineColor(
                        pjr.prjDateLine,
                      ).withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getDeadlineIcon(pjr.prjDateLine),
                          size: 14,
                          color: _getDeadlineColor(pjr.prjDateLine),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pjr.prjDateLine?.daysLeftText ?? '',
                          style: textTheme.bodySmall?.copyWith(
                            color: _getDeadlineColor(pjr.prjDateLine),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Location if available
              if (pjr.prjLocation != null && pjr.prjLocation!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pjr.prjLocation!,
                        style: textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ProjectView(project: pjr),
                      );
                    },
                    icon: Icon(
                      Icons.visibility,
                      size: 16,
                      color: color.primary,
                    ),
                    label: Text('View Details'),
                    style: TextButton.styleFrom(foregroundColor: color.primary),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmation(context, pjr);
                    },
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDeadlineColor(DateTime? deadline) {
    if (deadline == null) return Colors.grey;
    final days = deadline.daysLeft ?? 0;
    if (days > 7) return Colors.green;
    if (days > 3) return Colors.orange;
    if (days >= 0) return Colors.deepOrange;
    return Colors.red;
  }

  IconData _getDeadlineIcon(DateTime? deadline) {
    if (deadline == null) return Icons.help_outline;
    final days = deadline.daysLeft ?? 0;
    if (days > 7) return Icons.check_circle_outline;
    if (days > 3) return Icons.access_time;
    if (days >= 0) return Icons.warning_amber;
    return Icons.error_outline;
  }

  void _showDeleteConfirmation(BuildContext context, ProjectsModel project) {
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {

          String? userName;

          if (state is AuthenticatedState) {
            userName = state.loginData.usrName;
          }

          return ZAlertDialog(
            title: AppLocalizations.of(context)!.areYouSure,
            content: 'Do you want to delete "${project.prjName}"?',
            onYes: () {

              if (userName != null) {
                context.read<ProjectsBloc>().add(
                  DeleteProjectEvent(
                    project.prjId!,
                    userName,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

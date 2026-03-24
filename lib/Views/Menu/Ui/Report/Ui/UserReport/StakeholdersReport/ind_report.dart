import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/search_field.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/UserReport/StakeholdersReport/bloc/stakeholders_report_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/UserReport/StakeholdersReport/features/gender_drop.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../../Features/Widgets/z_dragable_sheet.dart';
import '../../../../../../../Features/Widgets/zcard_mobile.dart';
import 'model/ind_report_model.dart';

class StakeholdersReportView extends StatelessWidget {
  const StakeholdersReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _Mobile(),
      desktop: const _Desktop(),
      tablet: const _Tablet(),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  final searchController = TextEditingController();
  final phoneController = TextEditingController();
  String? gender;
  String? dob;

  bool get hasActiveFilters {
    return searchController.text.isNotEmpty ||
        phoneController.text.isNotEmpty ||
        gender != null ||
        dob != null;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((e){
      context.read<StakeholdersReportBloc>().add(ResetStakeholdersReportEvent());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Individuals Report"),
        titleSpacing: 0,
        actions: [
          // Filter button
          IconButton(
            onPressed: () {
              _showFilterBottomSheet(context);
            },
            icon: const Icon(Icons.filter_alt),
          ),
          // Clear filters button - only shown when filters are active
          if (hasActiveFilters)
            IconButton(
              onPressed: () {
                setState(() {
                  searchController.clear();
                  phoneController.clear();
                  gender = null;
                  dob = DateTime.now().toFormattedDate();
                });
                context.read<StakeholdersReportBloc>().add(
                  ResetStakeholdersReportEvent(),
                );
              },
              icon: const Icon(Icons.filter_alt_off),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search field - always visible
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ZSearchField(
              controller: searchController,
              title: "",
              hint: "Search by name",
              icon: Icons.search,
              onSubmit: (e) {
                _applyFilters();
              },
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BlocBuilder<StakeholdersReportBloc, StakeholdersReportState>(
                  builder: (context, state) {
                    if (state is StakeholdersReportLoadedState) {
                      return Text(
                        '${state.ind.length} ${state.ind.length == 1 ? 'individual' : 'individuals'} found',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }
                    return const SizedBox();
                  },
                ),
                // Active filters indicator
                if (hasActiveFilters)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Filters active',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Results list
          Expanded(
            child: BlocBuilder<StakeholdersReportBloc, StakeholdersReportState>(
              builder: (context, state) {
                if (state is StakeholdersReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is StakeholdersReportErrorState) {
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                    enableAction: false,
                  );
                }
                if (state is StakeholdersReportLoadedState) {
                  if (state.ind.isEmpty) {
                    return NoDataWidget(
                      title: "No individuals found",
                      message: hasActiveFilters
                          ? "Try adjusting your filters"
                          : "Add individuals to get started",
                      enableAction: false,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.ind.length,
                    itemBuilder: (context, index) {
                      final ind = state.ind[index];
                      return _buildMobileCard(ind);
                    },
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

  Widget _buildMobileCard(IndReportModel ind) {
    // Build info items for the card
    List<MobileInfoItem> infoItems = [];

    if (ind.perPhone != null && ind.perPhone!.isNotEmpty) {
      infoItems.add(
        MobileInfoItem(
          icon: Icons.phone,
          text: ind.perPhone!,
        ),
      );
    }

    if (ind.perEmail != null && ind.perEmail!.isNotEmpty) {
      infoItems.add(
        MobileInfoItem(
          icon: Icons.email,
          text: ind.perEmail!,
        ),
      );
    }

    if (ind.perEnidNo != null && ind.perEnidNo!.isNotEmpty) {
      infoItems.add(
        MobileInfoItem(
          icon: Icons.badge,
          text: ind.perEnidNo!,
        ),
      );
    }

    if (ind.perDoB != null) {
      infoItems.add(
        MobileInfoItem(
          icon: Icons.cake,
          text: _formatDate(ind.perDoB!),
        ),
      );
    }

    // Create status based on gender
    MobileStatus? status;
    if (ind.perGender != null && ind.perGender!.isNotEmpty) {
      status = MobileStatus(
        label: ind.perGender!,
        color: ind.perGender == "Male" ? Colors.blue : Colors.pink,
        backgroundColor: ind.perGender == "Male"
            ? Colors.blue.withValues(alpha: .1)
            : Colors.pink.withValues(alpha: .1),
      );
    }

    return MobileInfoCard(
      title: "${ind.perName ?? ''} ${ind.perLastName ?? ''}".trim(),
      subtitle: ind.perEmail,
      infoItems: infoItems,
      status: status,
      onTap: () => _showIndividualDetails(ind),
      accentColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    ZDraggableSheet.show(
      context: context,
      title: "Filter Individuals",
      showCloseButton: true,
      showDragHandle: true,
      initialChildSize: 0.7,
      estimatedContentHeight: 400,
      bodyBuilder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 8),

            // Phone filter
            ZSearchField(
              controller: phoneController,
              title: "",
              hint: tr.mobile1,
              icon: Icons.numbers,
            ),
            const SizedBox(height: 16),

            // Date of birth filter
            ZDatePicker(
              label: tr.dob,
              value: dob,
              onDateChanged: (v) {
                setState(() {
                  dob = v;
                });
              },
            ),
            const SizedBox(height: 16),

            // Gender filter
            GenderDropdown(
              title: "Gender",
              onSelected: (e) {
                setState(() {
                  gender = e;
                });
              },
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        phoneController.clear();
                        gender = null;
                        dob = DateTime.now().toFormattedDate();
                      });
                      Navigator.pop(context);
                    },
                    child: Text(tr.clearFilters),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: Text(tr.applyFilter),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _applyFilters() {
    context.read<StakeholdersReportBloc>().add(
      LoadStakeholdersReportEvent(
        phone: phoneController.text,
        dob: dob,
        search: searchController.text,
        gender: gender,
      ),
    );
  }

  void _showIndividualDetails(IndReportModel ind) {
    ZDraggableSheet.show(
      context: context,
      title: "Individual Details",
      showCloseButton: true,
      showDragHandle: true,
      initialChildSize: 0.8,
      estimatedContentHeight: 500,
      bodyBuilder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 16),

            // Header with avatar
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    (ind.perName ?? '?')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${ind.perName ?? ''} ${ind.perLastName ?? ''}".trim(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (ind.perGender != null && ind.perGender!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ind.perGender == "Male"
                                ? Colors.blue.withValues(alpha: .1)
                                : Colors.pink.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ind.perGender!,
                            style: TextStyle(
                              fontSize: 12,
                              color: ind.perGender == "Male"
                                  ? Colors.blue
                                  : Colors.pink,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // Details
            _buildDetailTile(Icons.person, "ID", ind.perId?.toString() ?? 'N/A'),
            if (ind.perPhone != null && ind.perPhone!.isNotEmpty)
              _buildDetailTile(Icons.phone, "Phone", ind.perPhone!),
            if (ind.perEmail != null && ind.perEmail!.isNotEmpty)
              _buildDetailTile(Icons.email, "Email", ind.perEmail!),
            if (ind.perEnidNo != null && ind.perEnidNo!.isNotEmpty)
              _buildDetailTile(Icons.credit_card, "ENID No", ind.perEnidNo!),
            if (ind.perDoB != null)
              _buildDetailTile(Icons.cake, "Date of Birth", _formatDate(ind.perDoB!)),
            if (ind.address != null &&
                ind.address!.isNotEmpty &&
                ind.address != "    ")
              _buildDetailTile(Icons.location_on, "Address", ind.address!, multiline: true),
          ],
        );
      },
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // You can add Shamsi conversion here if needed
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}
class _TabletState extends State<_Tablet> {
  final searchController = TextEditingController();
  final phoneController = TextEditingController();
  String? gender;
  String? dob;

  bool get hasActiveFilters {
    return searchController.text.isNotEmpty ||
        phoneController.text.isNotEmpty ||
        gender != null ||
        dob != null;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((e){
      context.read<StakeholdersReportBloc>().add(ResetStakeholdersReportEvent());
    });
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Individuals Report"),
        titleSpacing: 0,
        actions: [
          // Filter button
          IconButton(
            onPressed: () {
              _showFilterBottomSheet(context);
            },
            icon: const Icon(Icons.filter_alt),
          ),
          // Clear filters button
          if (hasActiveFilters)
            IconButton(
              onPressed: () {
                setState(() {
                  searchController.clear();
                  phoneController.clear();
                  gender = null;
                  dob = DateTime.now().toFormattedDate();
                });
                context.read<StakeholdersReportBloc>().add(
                  ResetStakeholdersReportEvent(),
                );
              },
              icon: const Icon(Icons.filter_alt_off),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search field - always visible
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ZSearchField(
                    controller: searchController,
                    title: "",
                    hint: "Search by name",
                    icon: Icons.search,
                    onSubmit: (e) {
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Quick filter indicators
                if (hasActiveFilters)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Filters active',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: BlocBuilder<StakeholdersReportBloc, StakeholdersReportState>(
              builder: (context, state) {
                if (state is StakeholdersReportLoadedState) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${state.ind.length} ${state.ind.length == 1 ? 'individual' : 'individuals'} found',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),

          const SizedBox(height: 8),

          // Results grid
          Expanded(
            child: BlocBuilder<StakeholdersReportBloc, StakeholdersReportState>(
              builder: (context, state) {
                if (state is StakeholdersReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is StakeholdersReportErrorState) {
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                    enableAction: false,
                  );
                }
                if (state is StakeholdersReportLoadedState) {
                  if (state.ind.isEmpty) {
                    return NoDataWidget(
                      title: "No individuals found",
                      message: hasActiveFilters
                          ? "Try adjusting your filters"
                          : "Add individuals to get started",
                      enableAction: false,
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: state.ind.length,
                    itemBuilder: (context, index) {
                      final ind = state.ind[index];
                      return _buildTabletCard(ind);
                    },
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

  Widget _buildTabletCard(IndReportModel ind) {
    // Build info items for the card
    List<MobileInfoItem> infoItems = [];

    if (ind.perPhone != null && ind.perPhone!.isNotEmpty) {
      infoItems.add(
        MobileInfoItem(
          icon: Icons.phone,
          text: ind.perPhone!,
        ),
      );
    }

    if (ind.perEmail != null && ind.perEmail!.isNotEmpty) {
      infoItems.add(
        MobileInfoItem(
          icon: Icons.email,
          text: ind.perEmail!,
        ),
      );
    }

    // Create status based on gender
    MobileStatus? status;
    if (ind.perGender != null && ind.perGender!.isNotEmpty) {
      status = MobileStatus(
        label: ind.perGender!,
        color: ind.perGender == "Male" ? Colors.blue : Colors.pink,
        backgroundColor: ind.perGender == "Male"
            ? Colors.blue.withValues(alpha: .1)
            : Colors.pink.withValues(alpha: .1),
      );
    }

    return MobileInfoCard(
      title: "${ind.perName ?? ''} ${ind.perLastName ?? ''}".trim(),
      subtitle: ind.perEmail,
      infoItems: infoItems,
      status: status,
      onTap: () => _showIndividualDetails(ind),
      accentColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    ZDraggableSheet.show(
      context: context,
      title: "Filter Individuals",
      showCloseButton: true,
      showDragHandle: true,
      initialChildSize: 0.6,
      estimatedContentHeight: 350,
      bodyBuilder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 8),

            // Phone filter
            ZSearchField(
              controller: phoneController,
              title: "",
              hint: tr.mobile1,
              icon: Icons.numbers,
            ),
            const SizedBox(height: 16),

            // Date of birth filter
            ZDatePicker(
              label: tr.dob,
              value: dob,
              onDateChanged: (v) {
                setState(() {
                  dob = v;
                });
              },
            ),
            const SizedBox(height: 16),

            // Gender filter
            GenderDropdown(
              title: "Gender",
              onSelected: (e) {
                setState(() {
                  gender = e;
                });
              },
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        phoneController.clear();
                        gender = null;
                        dob = DateTime.now().toFormattedDate();
                      });
                      Navigator.pop(context);
                    },
                    child: Text(tr.clearFilters),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: Text(tr.applyFilter),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _applyFilters() {
    context.read<StakeholdersReportBloc>().add(
      LoadStakeholdersReportEvent(
        phone: phoneController.text,
        dob: dob,
        search: searchController.text,
        gender: gender,
      ),
    );
  }

  void _showIndividualDetails(IndReportModel ind) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        (ind.perName ?? '?')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${ind.perName ?? ''} ${ind.perLastName ?? ''}".trim(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (ind.perGender != null && ind.perGender!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ind.perGender == "Male"
                                    ? Colors.blue.withValues(alpha: .1)
                                    : Colors.pink.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                ind.perGender!,
                                style: TextStyle(
                                  color: ind.perGender == "Male"
                                      ? Colors.blue
                                      : Colors.pink,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Details in two columns
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildDialogDetailItem("ID", ind.perId?.toString() ?? 'N/A'),
                          if (ind.perPhone != null && ind.perPhone!.isNotEmpty)
                            _buildDialogDetailItem("Phone", ind.perPhone!),
                          if (ind.perEnidNo != null && ind.perEnidNo!.isNotEmpty)
                            _buildDialogDetailItem("ENID No", ind.perEnidNo!),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          if (ind.perEmail != null && ind.perEmail!.isNotEmpty)
                            _buildDialogDetailItem("Email", ind.perEmail!),
                          if (ind.perDoB != null)
                            _buildDialogDetailItem("Date of Birth", _formatDate(ind.perDoB!)),
                        ],
                      ),
                    ),
                  ],
                ),

                if (ind.address != null &&
                    ind.address!.isNotEmpty &&
                    ind.address != "    ")
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildDialogDetailItem("Address", ind.address!, multiline: true),
                  ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogDetailItem(String label, String value, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  final searchController = TextEditingController();
  final phoneController = TextEditingController();
  String? gender;
  String? dob;

  bool get hasActiveFilters {
    return searchController.text.isNotEmpty ||
        phoneController.text.isNotEmpty ||
        gender != null ||
        dob != null;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((e){
      context.read<StakeholdersReportBloc>().add(ResetStakeholdersReportEvent());
    });
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    phoneController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text("${tr.individuals} ${tr.report}"),
        titleSpacing: 0,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8),
        actions: [
          // Clear filters button - only shown when filters are active
          if (hasActiveFilters)
            ZOutlineButton(
              onPressed: () {
                setState(() {
                  searchController.clear();
                  phoneController.clear();
                  gender = null;
                  dob = DateTime.now().toFormattedDate();
                });
                context.read<StakeholdersReportBloc>().add(
                  ResetStakeholdersReportEvent(),
                );
              },
              isActive: true,
              backgroundHover: Theme.of(context).colorScheme.error,
              icon: Icons.filter_alt_off_outlined,
              label: Text(tr.clearFilters),
            ),

          if (hasActiveFilters) const SizedBox(width: 8),

          ZOutlineButton(
            onPressed: () {
              _applyFilters();
            },
            isActive: true,
            icon: Icons.filter_alt,
            label: Text(tr.applyFilter),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Row - Desktop optimized
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 8,
              children: [
                Expanded(
                  flex: 7,
                  child: ZSearchField(
                    controller: searchController,
                    title: "",
                    hint: "Individual name",
                    icon: Icons.search,
                    onSubmit: (e) {
                      _applyFilters();
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ZSearchField(
                    controller: phoneController,
                    title: "",
                    hint: tr.mobile1,
                    icon: Icons.numbers,
                    onSubmit: (e) {
                      _applyFilters();
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ZDatePicker(
                    label: tr.dob,
                    value: dob,
                    onDateChanged: (v) {
                      setState(() {
                        dob = v;
                      });
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: GenderDropdown(
                    title: tr.gender,
                    onSelected: (e) {
                      setState(() {
                        gender = e;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Results count and filter indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BlocBuilder<StakeholdersReportBloc, StakeholdersReportState>(
                  builder: (context, state) {
                    if (state is StakeholdersReportLoadedState) {
                      return Text(
                        '${state.ind.length} ${state.ind.length == 1 ? 'individual' : tr.individuals} found',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }
                    return const SizedBox();
                  },
                ),
                if (hasActiveFilters)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Filters active',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Results List - Simple row-based list
          Expanded(
            child: BlocBuilder<StakeholdersReportBloc, StakeholdersReportState>(
              builder: (context, state) {
                if(state is StakeholdersReportInitial){
                  return NoDataWidget(
                    title: "Stakeholders Report",
                    message: "Apply filter to see individuals",
                    enableAction: false,
                  );
                }
                if (state is StakeholdersReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is StakeholdersReportErrorState) {
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                    enableAction: false,
                  );
                }
                if (state is StakeholdersReportLoadedState) {
                  if (state.ind.isEmpty) {
                    return NoDataWidget(
                      title: "No individuals found",
                      message: hasActiveFilters
                          ? "Try adjusting your filters"
                          : "Add individuals to get started",
                      enableAction: false,
                    );
                  }

                  // Header row
                  return Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .2),
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: .2),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text(tr.id, style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Text(tr.fullName, style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text(tr.gender, style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text(tr.dob, style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Text(tr.mobile1, style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 4, child: Text(tr.email, style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text(tr.nationalId, style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 4, child: Text(tr.address, style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),

                      // List of records
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.ind.length,
                          itemBuilder: (context, index) {
                            final ind = state.ind[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: index.isOdd
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: .05)
                                    : Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).colorScheme.outline.withValues(alpha: .1),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(flex: 1, child: Text(ind.perId?.toString() ?? 'N/A')),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "${ind.perName ?? ''} ${ind.perLastName ?? ''}".trim(),
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: ind.perGender != null && ind.perGender!.isNotEmpty
                                        ? Text(
                                          ind.perGender!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: ind.perGender == "Male"
                                                ? Colors.blue
                                                : Colors.pink,
                                          ),
                                        )
                                        : const Text('N/A'),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      ind.perDoB != null
                                          ? _formatDate(ind.perDoB!)
                                          : 'N/A',
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      ind.perPhone?.isNotEmpty == true
                                          ? ind.perPhone!
                                          : 'N/A',
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      ind.perEmail?.isNotEmpty == true
                                          ? ind.perEmail!
                                          : 'N/A',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      ind.perEnidNo?.isNotEmpty == true
                                          ? ind.perEnidNo!
                                          : 'N/A',
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      ind.address?.isNotEmpty == true && ind.address != "    "
                                          ? ind.address!
                                          : 'N/A',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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

  void _applyFilters() {
    context.read<StakeholdersReportBloc>().add(
      LoadStakeholdersReportEvent(
        phone: phoneController.text,
        dob: dob,
        search: searchController.text,
        gender: gender,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
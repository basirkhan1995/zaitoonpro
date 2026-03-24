import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/status_badge.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Services/bloc/services_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/search_field.dart';
import 'add_edit_services.dart';

class ServicesView extends StatelessWidget {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileServicesView(),
      tablet: _TabletServicesView(),
      desktop: _DesktopServicesView(),
    );
  }
}

// Base class to share common functionality
class _BaseServicesView extends StatefulWidget {
  final bool isMobile;
  final bool isTablet;

  const _BaseServicesView({
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseServicesView> createState() => _BaseServicesViewState();
}

class _BaseServicesViewState extends State<_BaseServicesView> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ServicesBloc>().add(LoadServicesEvent());
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<ServicesBloc>().add(LoadServicesEvent());
  }

  // Build header for different screen sizes
  Widget _buildHeader(AppLocalizations tr, TextTheme textTheme, ColorScheme color) {
    if (widget.isMobile) {
      // Mobile header - stacked layout
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.services, style: textTheme.titleLarge),
            Text(
              'Manage your services',
              style: textTheme.bodySmall?.copyWith(color: color.outline),
            ),
            const SizedBox(height: 12),
            ZSearchField(
              controller: searchController,
              hint: "Service name",
              title: '',
              end: searchController.text.isNotEmpty
                  ? InkWell(
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  setState(() {
                    searchController.clear();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.clear, size: 15),
                ),
              )
                  : const SizedBox(),
              onChanged: (e) {
                setState(() {});
              },
              icon: FontAwesomeIcons.magnifyingGlass,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ZOutlineButton(
                    icon: Icons.refresh,
                    onPressed: onRefresh,
                    label: Text(tr.refresh),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ZOutlineButton(
                    isActive: true,
                    icon: Icons.add,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddEditServiceView(),
                      );
                    },
                    label: Text(tr.newKeyword),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (widget.isTablet) {
      // Tablet header - compact row layout
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.services, style: textTheme.titleLarge),
                      Text(
                        'Manage your services',
                        style: textTheme.bodySmall?.copyWith(color: color.outline),
                      ),
                    ],
                  ),
                ),
                ZOutlineButton(
                  width: 100,
                  icon: Icons.refresh,
                  onPressed: onRefresh,
                  label: Text(tr.refresh),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  width: 100,
                  isActive: true,
                  icon: Icons.add,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddEditServiceView(),
                    );
                  },
                  label: Text(tr.newKeyword),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ZSearchField(
              controller: searchController,
              hint: "Service name",
              title: '',
              end: searchController.text.isNotEmpty
                  ? InkWell(
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  setState(() {
                    searchController.clear();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.clear, size: 15),
                ),
              )
                  : const SizedBox(),
              onChanged: (e) {
                setState(() {});
              },
              icon: FontAwesomeIcons.magnifyingGlass,
            ),
          ],
        ),
      );
    } else {
      // Desktop header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
        child: Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.services, style: textTheme.titleLarge),
                  Text(
                    'Manage your services',
                    style: textTheme.bodySmall?.copyWith(color: color.outline),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ZSearchField(
                controller: searchController,
                hint: "Service name",
                title: '',
                end: searchController.text.isNotEmpty
                    ? InkWell(
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    setState(() {
                      searchController.clear();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.clear, size: 15),
                  ),
                )
                    : const SizedBox(),
                onChanged: (e) {
                  setState(() {});
                },
                icon: FontAwesomeIcons.magnifyingGlass,
              ),
            ),
            ZOutlineButton(
              width: 110,
              icon: Icons.refresh,
              onPressed: onRefresh,
              label: Text(tr.refresh),
            ),
            ZOutlineButton(
              width: 110,
              isActive: true,
              icon: Icons.add,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddEditServiceView(),
                );
              },
              label: Text(tr.newKeyword),
            ),
          ],
        ),
      );
    }
  }

  // Build table header for different screen sizes
  Widget _buildTableHeader(AppLocalizations tr, TextStyle? titleStyle, ColorScheme color) {
    if (widget.isMobile) {
      // Mobile card view doesn't need table header
      return const SizedBox.shrink();
    } else if (widget.isTablet) {
      // Tablet table header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text('Service Name', style: titleStyle),
            ),
            SizedBox(
              width: 80,
              child: Text(tr.status, style: titleStyle, textAlign: TextAlign.right),
            ),
          ],
        ),
      );
    } else {
      // Desktop table header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text('Service Name', style: titleStyle)),
            SizedBox(
              width: 60,
              child: Text(tr.status, style: titleStyle, textAlign: TextAlign.right),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildServiceItem(
      dynamic service,
      int index,
      TextTheme textTheme,
      ColorScheme color,
      AppLocalizations tr,
      ) {
    final rowColor = index.isEven
        ? color.primary.withValues(alpha: .05)
        : Colors.transparent;

    if (widget.isMobile) {
      // ✅ MOBILE — CARD STYLE CONTAINER
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          child: InkWell(
            borderRadius: BorderRadius.circular(2),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AddEditServiceView(model: service),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: rowColor,
                borderRadius: BorderRadius.circular(2), // ✅ radius = 2
                border: Border.all(
                  color: color.outline.withValues(alpha: .15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ID + Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          "${tr.id}: ${service.srvId}",
                          style: textTheme.bodySmall?.copyWith(
                            color: color.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      StatusBadge(
                        status: service.srvStatus!,
                        trueValue: tr.active,
                        falseValue: tr.inactive,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// Service name
                  Text(
                    service.srvName ?? "",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // ✅ TABLET + DESKTOP ROW STYLE
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          child: InkWell(
            borderRadius: BorderRadius.circular(2),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AddEditServiceView(model: service),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: rowColor,
                borderRadius: BorderRadius.circular(2),
              ),
              child: ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: widget.isTablet
                    ? Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      service.srvId.toString(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                    : Text(service.srvId.toString()),
                title: Text(service.srvName ?? ""),
                trailing: SizedBox(
                  width: widget.isTablet ? 110 : 100,
                  child: StatusBadge(
                    status: service.srvStatus!,
                    trueValue: tr.active,
                    falseValue: tr.inactive,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;
    final titleStyle = textTheme.titleMedium;

    return Scaffold(
      body: Column(
        children: [
          // Header Section
          _buildHeader(tr, textTheme, color),

          if (!widget.isMobile) ...[
            // Table Header
            _buildTableHeader(tr, titleStyle, color),
            const SizedBox(height: 4),
          ],

          // Services List
          Expanded(
            child: BlocConsumer<ServicesBloc, ServicesState>(
              listener: (context, state) {
                if (state is ServicesSuccessState) {
                  Navigator.of(context).pop();
                }
              },
              builder: (context, state) {
                if (state is ServicesLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ServicesErrorState) {
                  return NoDataWidget(
                    message: state.message,
                    onRefresh: onRefresh,
                  );
                }
                if (state is ServicesLoadedState) {
                  final query = searchController.text.toLowerCase().trim();

                  final filteredList = state.services.where((item) {
                    final name = item.srvName?.toLowerCase() ?? '';
                    final id = item.srvId.toString();
                    return name.contains(query) || id.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: tr.noDataFound,
                      onRefresh: onRefresh,
                    );
                  }

                  return ListView.builder(
                    padding: widget.isMobile
                        ? const EdgeInsets.symmetric(vertical: 8)
                        : EdgeInsets.zero,
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final service = filteredList[index];
                      return _buildServiceItem(service, index, textTheme, color, tr);
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
}

// Mobile View
class _MobileServicesView extends StatelessWidget {
  const _MobileServicesView();

  @override
  Widget build(BuildContext context) {
    return const _BaseServicesView(
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletServicesView extends StatelessWidget {
  const _TabletServicesView();

  @override
  Widget build(BuildContext context) {
    return const _BaseServicesView(
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopServicesView extends StatelessWidget {
  const _DesktopServicesView();

  @override
  Widget build(BuildContext context) {
    return const _BaseServicesView(
      isMobile: false,
      isTablet: false,
    );
  }
}
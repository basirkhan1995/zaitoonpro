import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/add_edit_storage.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/bloc/storage_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/search_field.dart';

class StorageView extends StatelessWidget {
  const StorageView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileStorageView(),
      tablet: _TabletStorageView(),
      desktop: _DesktopStorageView(),
    );
  }
}

// Base class to share common functionality
class _BaseStorageView extends StatefulWidget {
  final bool isMobile;
  final bool isTablet;

  const _BaseStorageView({
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseStorageView> createState() => _BaseStorageViewState();
}

class _BaseStorageViewState extends State<_BaseStorageView> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StorageBloc>().add(LoadStorageEvent());
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Build header row with search and buttons
  Widget _buildHeaderRow(AppLocalizations locale) {
    if (widget.isMobile) {
      // Mobile header - stacked layout
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ZSearchField(
              icon: FontAwesomeIcons.magnifyingGlass,
              controller: searchController,
              hint: locale.search,
              onChanged: (e) {
                setState(() {});
              },
              title: "",
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ZOutlineButton(
                    toolTip: "F5",
                    icon: Icons.refresh,
                    onPressed: () {
                      context.read<StorageBloc>().add(LoadStorageEvent());
                    },
                    label: Text(locale.refresh),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ZOutlineButton(
                    toolTip: "F1",
                    icon: Icons.add,
                    isActive: true,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const StorageAddEditView(),
                      );
                    },
                    label: Text(locale.newKeyword),
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
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ZSearchField(
                icon: FontAwesomeIcons.magnifyingGlass,
                controller: searchController,
                hint: locale.search,
                onChanged: (e) {
                  setState(() {});
                },
                title: "",
              ),
            ),
            const SizedBox(width: 8),
            ZOutlineButton(
              toolTip: "F5",
              width: 100,
              icon: Icons.refresh,
              onPressed: () {
                context.read<StorageBloc>().add(LoadStorageEvent());
              },
              label: Text(locale.refresh),
            ),
            const SizedBox(width: 8),
            ZOutlineButton(
              toolTip: "F1",
              width: 100,
              icon: Icons.add,
              isActive: true,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const StorageAddEditView(),
                );
              },
              label: Text(locale.newKeyword),
            ),
          ],
        ),
      );
    } else {
      // Desktop header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
        child: Row(
          spacing: 8,
          children: [
            Expanded(
              child: ZSearchField(
                icon: FontAwesomeIcons.magnifyingGlass,
                controller: searchController,
                hint: locale.search,
                onChanged: (e) {
                  setState(() {});
                },
                title: "",
              ),
            ),
            ZOutlineButton(
              toolTip: "F5",
              width: 120,
              icon: Icons.refresh,
              onPressed: () {
                context.read<StorageBloc>().add(LoadStorageEvent());
              },
              label: Text(locale.refresh),
            ),
            ZOutlineButton(
              toolTip: "F1",
              width: 120,
              icon: Icons.add,
              isActive: true,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const StorageAddEditView(),
                );
              },
              label: Text(locale.newKeyword),
            ),
          ],
        ),
      );
    }
  }

  // Build table header for different screen sizes
  Widget _buildTableHeader(
      AppLocalizations locale, TextTheme textTheme, ColorScheme color) {
    final titleStyle = textTheme.titleSmall?.copyWith();

    if (widget.isMobile) {
      // Mobile card view doesn't need a table header
      return const SizedBox.shrink();
    } else if (widget.isTablet) {
      // Tablet table header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(locale.storage, style: titleStyle),
            ),
            SizedBox(
              width: 180,
              child: Text(locale.status, style: titleStyle),
            ),
          ],
        ),
      );
    } else {
      // Desktop table header
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Row(
          children: [
            Expanded(
              child: Text(locale.storage, style: titleStyle),
            ),
            SizedBox(
              width: 300,
              child: Text(locale.details, style: titleStyle),
            ),
            SizedBox(
              width: 280,
              child: Text(locale.address, style: titleStyle),
            ),
            SizedBox(
              width: 60,
              child: Text(locale.status, style: titleStyle),
            ),
          ],
        ),
      );
    }
  }

  // Build storage item based on screen size
  Widget _buildStorageItem(dynamic storage, int index, TextTheme textTheme,
      ColorScheme color, AppLocalizations locale) {
    final bodyStyle = textTheme.bodyMedium?.copyWith(color: color.secondary);

    if (widget.isMobile) {
      // Mobile card view
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) =>
                  StorageAddEditView(selectedStorage: storage),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        storage.stgName ?? "",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: storage.stgStatus == 1
                            ? Colors.green.withValues(alpha: .1)
                            : Colors.red.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        storage.stgStatus == 1
                            ? locale.active
                            : locale.inactive,
                        style: textTheme.bodySmall?.copyWith(
                          color: storage.stgStatus == 1
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (storage.stgDetails != null &&
                    storage.stgDetails!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 16,
                        color: color.primary.withValues(alpha: .7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          storage.stgDetails!,
                          style: bodyStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                if (storage.stgLocation != null &&
                    storage.stgLocation!.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: color.primary.withValues(alpha: .7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          storage.stgLocation!,
                          style: bodyStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    } else if (widget.isTablet) {
      // Tablet row view
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => StorageAddEditView(selectedStorage: storage),
          );
        },
        hoverColor: color.primary.withValues(alpha: .05),
        highlightColor: color.primary.withValues(alpha: .05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: index.isOdd
                ? color.primary.withValues(alpha: .05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  storage.stgName ?? "",
                  style: bodyStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 180,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: storage.stgStatus == 1
                        ? Colors.green.withValues(alpha: .1)
                        : Colors.red.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    storage.stgStatus == 1 ? locale.active : locale.inactive,
                    style: textTheme.bodySmall?.copyWith(
                      color: storage.stgStatus == 1 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Desktop row view
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => StorageAddEditView(selectedStorage: storage),
          );
        },
        hoverColor: color.primary.withValues(alpha: .05),
        highlightColor: color.primary.withValues(alpha: .05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          decoration: BoxDecoration(
            color: index.isOdd
                ? color.primary.withValues(alpha: .05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  storage.stgName ?? "",
                  style: bodyStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 300,
                child: Text(
                  storage.stgDetails ?? "",
                  style: bodyStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 280,
                child: Text(
                  storage.stgLocation ?? "",
                  style: bodyStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  storage.stgStatus == 1 ? locale.active : locale.inactive,
                  style: bodyStyle?.copyWith(
                    color: storage.stgStatus == 1 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Scaffold(

      appBar: widget.isMobile
          ? AppBar(
        title: Text(locale.storage),

      )
          : null,
      body: Column(
        children: [
          // Header Section
          _buildHeaderRow(locale),

          if (!widget.isMobile) ...[
            const SizedBox(height: 5),
            // Table Header
            _buildTableHeader(locale, textTheme, color),
            Divider(
              indent: widget.isTablet ? 12 : 15,
              endIndent: widget.isTablet ? 12 : 15,
              color: color.outline.withValues(alpha: .4),
            ),
          ],

          const SizedBox(height: 2),

          // Storage List
          Expanded(
            child: BlocBuilder<StorageBloc, StorageState>(
              builder: (context, state) {
                if (state is StorageLoadingState) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (state is StorageErrorState) {
                  return NoDataWidget(
                    title: locale.accessDenied,
                    message: state.error,
                    onRefresh: () {
                      context.read<StorageBloc>().add(LoadStorageEvent());
                    },
                  );
                }
                if (state is StorageLoadedState) {
                  final query = searchController.text.toLowerCase().trim();
                  final filteredList = state.storage.where((item) {
                    final name = item.stgName?.toLowerCase() ?? '';
                    final details = item.stgDetails?.toLowerCase() ?? '';
                    final location = item.stgLocation?.toLowerCase() ?? '';
                    return name.contains(query) ||
                        details.contains(query) ||
                        location.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: locale.noDataFound,
                      onRefresh: () {
                        context.read<StorageBloc>().add(LoadStorageEvent());
                      },
                    );
                  }

                  return ListView.builder(
                    padding: widget.isMobile
                        ? const EdgeInsets.symmetric(vertical: 8)
                        : EdgeInsets.zero,
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final storage = filteredList[index];
                      return _buildStorageItem(
                          storage, index, textTheme, color, locale);
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
class _MobileStorageView extends StatelessWidget {
  const _MobileStorageView();

  @override
  Widget build(BuildContext context) {
    return const _BaseStorageView(
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletStorageView extends StatelessWidget {
  const _TabletStorageView();

  @override
  Widget build(BuildContext context) {
    return const _BaseStorageView(
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopStorageView extends StatelessWidget {
  const _DesktopStorageView();

  @override
  Widget build(BuildContext context) {
    return const _BaseStorageView(
      isMobile: false,
      isTablet: false,
    );
  }
}
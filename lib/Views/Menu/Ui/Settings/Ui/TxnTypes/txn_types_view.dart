import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/alert_dialog.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/TxnTypes/add_edit_type.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/TxnTypes/bloc/txn_types_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../Features/Widgets/search_field.dart';

class TxnTypesView extends StatelessWidget {
  const TxnTypesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _Mobile(),
      desktop: _Desktop(),
      tablet: _Tablet(),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TxnTypesBloc>().add(LoadTxnTypesEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(
          "Transaction Types",
          style: textTheme.titleMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddEditTxnTypesView(),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ZSearchField(
              controller: searchController,
              hint: tr.search,
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
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
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return BlocConsumer<TxnTypesBloc, TxnTypesState>(
      listener: (context, state) {
        if (state is TxnTypeSuccessState) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        if (state is TxnTypeLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TxnTypeErrorState) {
          return NoDataWidget(
            title: AppLocalizations.of(context)!.noData,
            message: state.message,
          );
        }
        if (state is TxnTypesLoadedState) {
          final query = searchController.text.toLowerCase().trim();

          final filteredList = state.types.where((item) {
            final name = item.trntName?.toLowerCase() ?? '';
            final number = item.trntCode?.toString() ?? '';

            return name.contains(query.toLowerCase()) ||
                number.contains(query);
          }).toList();

          if (filteredList.isEmpty) {
            return NoDataWidget(
              title: tr.noData,
              message: tr.noDataFound,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: filteredList.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final type = filteredList[index];
              return _buildTransactionCard(context, type, index);
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildTransactionCard(BuildContext context, dynamic type, int index) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: index.isEven
          ? color.primary.withValues(alpha: .02)
          : color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: color.outline.withValues(alpha: .1),
        ),
      ),
      child: ListTile(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AddEditTxnTypesView(model: type),
          );
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              type.trntCode ?? "",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color.primary,
              ),
            ),
          ),
        ),
        title: Text(
          type.trntName ?? "",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          type.trntDetails ?? "",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return ZAlertDialog(
                  title: tr.areYouSure,
                  content: "Do you want to delete this transaction type?",
                  onYes: () {
                    context
                        .read<TxnTypesBloc>()
                        .add(DeleteTxnTypeEvent(type.trntCode!));
                  },
                );
              },
            );
          },
          icon: Icon(
            Icons.delete_outline_rounded,
            color: color.error,
          ),
        ),
      ),
    );
  }

  void _onRefresh() {
    context.read<TxnTypesBloc>().add(LoadTxnTypesEvent());
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TxnTypesBloc>().add(LoadTxnTypesEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(
          "Transaction Types",
          style: textTheme.titleMedium,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ZOutlineButton(
              width: 100,
              icon: Icons.refresh,
              onPressed: _onRefresh,
              label: Text(tr.refresh),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ZOutlineButton(
              width: 100,
              isActive: true,
              icon: Icons.add,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddEditTxnTypesView(),
                );
              },
              label: Text(tr.newKeyword),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 400,
              child: ZSearchField(
                controller: searchController,
                hint: tr.search,
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
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
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
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return BlocConsumer<TxnTypesBloc, TxnTypesState>(
      listener: (context, state) {
        if (state is TxnTypeSuccessState) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        if (state is TxnTypeLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TxnTypeErrorState) {
          return NoDataWidget(
            title: AppLocalizations.of(context)!.noData,
            message: state.message,
          );
        }
        if (state is TxnTypesLoadedState) {
          final query = searchController.text.toLowerCase().trim();

          final filteredList = state.types.where((item) {
            final name = item.trntName?.toLowerCase() ?? '';
            final number = item.trntCode?.toString() ?? '';

            return name.contains(query.toLowerCase()) ||
                number.contains(query);
          }).toList();

          if (filteredList.isEmpty) {
            return NoDataWidget(
              title: tr.noData,
              message: tr.noDataFound,
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final type = filteredList[index];
                return _buildTabletCard(context, type, index);
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildTabletCard(BuildContext context, dynamic type, int index) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Card(
      elevation: 1,
      color: index.isEven
          ? color.primary.withValues(alpha: .02)
          : color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: color.outline.withValues(alpha: .1),
        ),
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AddEditTxnTypesView(model: type),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    type.trntCode ?? "",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      type.trntName ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.trntDetails ?? "",
                      style: TextStyle(
                        fontSize: 13,
                        color: color.onSurface.withValues(alpha: .7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return ZAlertDialog(
                        title: tr.areYouSure,
                        content: "Do you want to delete this transaction type?",
                        onYes: () {
                          context
                              .read<TxnTypesBloc>()
                              .add(DeleteTxnTypeEvent(type.trntCode!));
                        },
                      );
                    },
                  );
                },
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: color.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onRefresh() {
    context.read<TxnTypesBloc>().add(LoadTxnTypesEvent());
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TxnTypesBloc>().add(LoadTxnTypesEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
            child: Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Transaction Types",
                    style: textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ZSearchField(
                    controller: searchController,
                    hint: tr.search,
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
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
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
                  onPressed: _onRefresh,
                  label: Text(tr.refresh),
                ),
                ZOutlineButton(
                  width: 110,
                  isActive: true,
                  icon: Icons.add,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddEditTxnTypesView(),
                    );
                  },
                  label: Text(tr.newKeyword),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<TxnTypesBloc, TxnTypesState>(
              listener: (context, state) {
                if (state is TxnTypeSuccessState) {
                  Navigator.of(context).pop();
                }
              },
              builder: (context, state) {
                if (state is TxnTypeLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TxnTypeErrorState) {
                  return NoDataWidget(
                    title: AppLocalizations.of(context)!.noData,
                    message: state.message,
                  );
                }
                if (state is TxnTypesLoadedState) {
                  final query = searchController.text.toLowerCase().trim();

                  final filteredList = state.types.where((item) {
                    final name = item.trntName?.toLowerCase() ?? '';
                    final number = item.trntCode?.toString() ?? '';

                    return name.contains(query.toLowerCase()) ||
                        number.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final type = filteredList[index];
                      return ListTile(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                AddEditTxnTypesView(model: type),
                          );
                        },
                        tileColor: index.isEven
                            ? color.primary.withValues(alpha: .05)
                            : Colors.transparent,
                        leading: Text(type.trntCode ?? ""),
                        title: Text(type.trntName ?? ""),
                        subtitle: Text(type.trntDetails ?? ""),
                        trailing: IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return ZAlertDialog(
                                  title: tr.areYouSure,
                                  content:
                                  "Do you want to delete this transaction type?",
                                  onYes: () {
                                    context.read<TxnTypesBloc>().add(
                                        DeleteTxnTypeEvent(type.trntCode!));
                                  },
                                );
                              },
                            );
                          },
                          icon: Icon(
                            Icons.delete,
                            color: color.error,
                          ),
                        ),
                      );
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

  void _onRefresh() {
    context.read<TxnTypesBloc>().add(LoadTxnTypesEvent());
  }
}
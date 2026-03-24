import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/Estimate/bloc/estimate_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../View/EstimateById/estimate_details.dart';

class EstimateView extends StatelessWidget {
  const EstimateView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileEstimateView(),
      tablet: _TabletEstimateView(),
      desktop: _DesktopEstimateView(),
    );
  }
}

// Mobile View
class _MobileEstimateView extends StatefulWidget {
  const _MobileEstimateView();

  @override
  State<_MobileEstimateView> createState() => _MobileEstimateViewState();
}

class _MobileEstimateViewState extends State<_MobileEstimateView> {
  String? baseCurrency;
  EstimatesLoaded? _cachedEstimates;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EstimateBloc>().add(LoadEstimatesEvent());
    });

    final companyState = context.read<AuthBloc>().state;
    if (companyState is AuthenticatedState) {
      baseCurrency = companyState.loginData.company?.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<EstimateBloc>().add(LoadEstimatesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ZSearchField(
              icon: FontAwesomeIcons.magnifyingGlass,
              controller: searchController,
              hint: AppLocalizations.of(context)!.search,
              onChanged: (e) {
                setState(() {});
              },
              title: "",
            ),
          ),

          // Estimates List
          Expanded(
            child: BlocConsumer<EstimateBloc, EstimateState>(
              listener: (context, state) {
                if (state is EstimateDeleted || state is EstimateConverted) {
                  if (state is EstimatesLoaded) {
                    _cachedEstimates = state;
                  }
                }
                if (state is EstimateError) {
                  Utils.showOverlayMessage(context, message: state.message, isError: true);
                }
                if (state is EstimateSaved) {
                  context.read<EstimateBloc>().add(LoadEstimatesEvent());
                }
              },
              builder: (context, state) {
                if (state is EstimatesLoaded) {
                  _cachedEstimates = state;
                }

                final shouldUseCached = state is EstimateDetailLoading ||
                    state is EstimateDetailLoaded ||
                    state is EstimateSaving ||
                    state is EstimateDeleting ||
                    state is EstimateConverting;

                final displayState = shouldUseCached ? _cachedEstimates : state;

                if (shouldUseCached && _cachedEstimates == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (displayState is EstimateError) {
                  return NoDataWidget(
                    imageName: 'error.png',
                    message: displayState.message,
                    onRefresh: onRefresh,
                  );
                }

                if (displayState is EstimateLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (displayState is EstimatesLoaded) {
                  final query = searchController.text.toLowerCase().trim();
                  final filteredList = displayState.estimates.where((item) {
                    final ref = item.ordxRef?.toLowerCase() ?? '';
                    final ordId = item.ordId?.toString() ?? '';
                    final customerName = item.ordPersonalName?.toLowerCase() ?? '';
                    final reference = item.ordTrnRef?.toLowerCase() ?? '';
                    return ref.contains(query) ||
                        ordId.contains(query) ||
                        customerName.contains(query) ||
                        reference.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: tr.noDataFound,
                      onRefresh: onRefresh,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final estimate = filteredList[index];

                      return ZCover(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        radius: 4,
                        child: InkWell(
                          onTap: () {
                            Utils.goto(
                              context,
                              EstimateDetailView(estimateId: estimate.ordId!),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row with ID
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.primary.withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "#${estimate.ordId}",
                                        style: TextStyle(
                                          color: color.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Reference Number
                                Row(
                                  children: [
                                    Icon(
                                      Icons.receipt,
                                      size: 16,
                                      color: color.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        estimate.ordxRef ?? "",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Customer Name
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: color.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        estimate.ordPersonalName ?? "",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Amount
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tr.totalInvoice,
                                      style: TextStyle(
                                        color: color.outline,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.primary.withValues(alpha: .05),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        "${estimate.total?.toAmount()} $baseCurrency",
                                        style: TextStyle(
                                          color: color.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Tablet View
class _TabletEstimateView extends StatefulWidget {
  const _TabletEstimateView();

  @override
  State<_TabletEstimateView> createState() => _TabletEstimateViewState();
}

class _TabletEstimateViewState extends State<_TabletEstimateView> {
  String? baseCurrency;
  EstimatesLoaded? _cachedEstimates;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EstimateBloc>().add(LoadEstimatesEvent());
    });

    final companyState = context.read<AuthBloc>().state;
    if (companyState is AuthenticatedState) {
      baseCurrency = companyState.loginData.company?.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<EstimateBloc>().add(LoadEstimatesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Header with Title and Search
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.estimateTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tr.ordersSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: color.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ZSearchField(
                    icon: FontAwesomeIcons.magnifyingGlass,
                    controller: searchController,
                    hint: AppLocalizations.of(context)!.search,
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
                  onPressed: onRefresh,
                  label: Text(tr.refresh),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: .9),
              ),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text("#", style: titleStyle)),
                  Expanded(
                    flex: 2,
                    child: Text(tr.referenceNumber, style: titleStyle),
                  ),
                  Expanded(child: Text(tr.party, style: titleStyle)),
                  SizedBox(
                    width: 120,
                    child: Text(tr.totalInvoice, style: titleStyle),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            // Estimates List
            Expanded(
              child: BlocConsumer<EstimateBloc, EstimateState>(
                listener: (context, state) {
                  if (state is EstimateDeleted || state is EstimateConverted) {
                    if (state is EstimatesLoaded) {
                      _cachedEstimates = state;
                    }
                  }
                  if (state is EstimateError) {
                    Utils.showOverlayMessage(context, message: state.message, isError: true);
                  }
                  if (state is EstimateSaved) {
                    context.read<EstimateBloc>().add(LoadEstimatesEvent());
                  }
                },
                builder: (context, state) {
                  if (state is EstimatesLoaded) {
                    _cachedEstimates = state;
                  }

                  final shouldUseCached = state is EstimateDetailLoading ||
                      state is EstimateDetailLoaded ||
                      state is EstimateSaving ||
                      state is EstimateDeleting ||
                      state is EstimateConverting;

                  final displayState = shouldUseCached ? _cachedEstimates : state;

                  if (shouldUseCached && _cachedEstimates == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (displayState is EstimateError) {
                    return NoDataWidget(
                      imageName: 'error.png',
                      message: displayState.message,
                      onRefresh: onRefresh,
                    );
                  }

                  if (displayState is EstimateLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (displayState is EstimatesLoaded) {
                    final query = searchController.text.toLowerCase().trim();
                    final filteredList = displayState.estimates.where((item) {
                      final ref = item.ordxRef?.toLowerCase() ?? '';
                      final ordId = item.ordId?.toString() ?? '';
                      final customerName = item.ordPersonalName?.toLowerCase() ?? '';
                      final reference = item.ordTrnRef?.toLowerCase() ?? '';
                      return ref.contains(query) ||
                          ordId.contains(query) ||
                          customerName.contains(query) ||
                          reference.contains(query);
                    }).toList();

                    if (filteredList.isEmpty) {
                      return NoDataWidget(
                        message: tr.noDataFound,
                        onRefresh: onRefresh,
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final estimate = filteredList[index];

                        return InkWell(
                          onTap: () {
                            Utils.goto(
                              context,
                              EstimateDetailView(estimateId: estimate.ordId!),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? color.primary.withValues(alpha: .05)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text(estimate.ordId.toString()),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    estimate.ordxRef ?? "",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    estimate.ordPersonalName ?? "",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    "${estimate.total?.toAmount()} $baseCurrency",
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Desktop View - Keep exactly as original
class _DesktopEstimateView extends StatefulWidget {
  const _DesktopEstimateView();

  @override
  State<_DesktopEstimateView> createState() => _DesktopEstimateViewState();
}

class _DesktopEstimateViewState extends State<_DesktopEstimateView> {
  String? baseCurrency;
  EstimatesLoaded? _cachedEstimates;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EstimateBloc>().add(LoadEstimatesEvent());
    });

    final companyState = context.read<AuthBloc>().state;
    if (companyState is AuthenticatedState) {
      baseCurrency = companyState.loginData.company?.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<EstimateBloc>().add(LoadEstimatesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  flex: 5,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    tileColor: Colors.transparent,
                    title: Text(
                      tr.estimateTitle,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 20),
                    ),
                    subtitle: Text(
                      tr.ordersSubtitle,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ZSearchField(
                    icon: FontAwesomeIcons.magnifyingGlass,
                    controller: searchController,
                    hint: AppLocalizations.of(context)!.search,
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
                  onPressed: onRefresh,
                  label: Text(tr.refresh),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .9),
            ),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text("#", style: titleStyle)),
                SizedBox(
                  width: 215,
                  child: Text(tr.referenceNumber, style: titleStyle),
                ),
                Expanded(child: Text(tr.party, style: titleStyle)),
                SizedBox(
                  width: 150,
                  child: Text(tr.totalInvoice, style: titleStyle),
                ),
              ],
            ),
          ),

          Expanded(
            child: BlocConsumer<EstimateBloc, EstimateState>(
              listener: (context, state) {
                if (state is EstimateDeleted || state is EstimateConverted) {
                  if (state is EstimatesLoaded) {
                    _cachedEstimates = state;
                  }
                }
                if (state is EstimateError) {
                  Utils.showOverlayMessage(context, message: state.message, isError: true);
                }
                if (state is EstimateSaved) {
                  context.read<EstimateBloc>().add(LoadEstimatesEvent());
                }
              },
              builder: (context, state) {
                if (state is EstimatesLoaded) {
                  _cachedEstimates = state;
                }

                final shouldUseCached = state is EstimateDetailLoading ||
                    state is EstimateDetailLoaded ||
                    state is EstimateSaving ||
                    state is EstimateDeleting ||
                    state is EstimateConverting;

                final displayState = shouldUseCached ? _cachedEstimates : state;

                if (shouldUseCached && _cachedEstimates == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (displayState is EstimateError) {
                  return NoDataWidget(
                    imageName: 'error.png',
                    message: displayState.message,
                    onRefresh: onRefresh,
                  );
                }

                if (displayState is EstimateLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (displayState is EstimatesLoaded) {
                  final query = searchController.text.toLowerCase().trim();
                  final filteredList = displayState.estimates.where((item) {
                    final ref = item.ordxRef?.toLowerCase() ?? '';
                    final ordId = item.ordId?.toString() ?? '';
                    final customerName = item.ordPersonalName?.toLowerCase() ?? '';
                    final reference = item.ordTrnRef?.toLowerCase() ?? '';
                    return ref.contains(query) ||
                        ordId.contains(query) ||
                        customerName.contains(query) ||
                        reference.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: tr.noDataFound,
                      onRefresh: onRefresh,
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final estimate = filteredList[index];

                      return InkWell(
                        onTap: () {
                          Utils.goto(
                            context,
                            EstimateDetailView(estimateId: estimate.ordId!),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? color.primary.withValues(alpha: .05)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Text(estimate.ordId.toString()),
                              ),
                              SizedBox(
                                width: 215,
                                child: Text(
                                  estimate.ordxRef ?? "",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  estimate.ordPersonalName ?? "",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  "${estimate.total?.toAmount()} $baseCurrency",
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/toast.dart';
import 'package:zaitoon_petroleum/Features/Widgets/no_data_widget.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../Features/Other/extensions.dart';
import '../../../../../../../../Features/Other/utils.dart';
import '../../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../Finance/Ui/GlAccounts/GlCategories/category_view.dart';
import '../../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../Print/print.dart';
import '../bloc/all_balances_bloc.dart';
import '../model/all_balances_model.dart';

class AllBalancesView extends StatelessWidget {
  const AllBalancesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(), desktop: _Desktop(), tablet: _Tablet(),);
  }
}


class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}
class _TabletState extends State<_Tablet> {
  int? catId;
  String? selectedCategory;
  bool _showFilters = true;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: color.surface,
      fontWeight: FontWeight.w500,
    );

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text("All Balances"),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          if (catId != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                setState(() {
                  catId = null;
                  selectedCategory = null;
                });
                context.read<AllBalancesBloc>().add(ResetAllBalancesEvent());
              },
            ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              context.read<AllBalancesBloc>().add(
                LoadAllBalancesEvent(catId: catId),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible Filters
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: GlSubCategoriesDrop(
                      title: tr.accountCategory,
                      mainCategoryId: 0,
                      onChanged: (e) {
                        setState(() {
                          catId = e?.acgId;
                          selectedCategory = e?.acgName;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: ZOutlineButton(
                      height: 47,
                      icon: Icons.filter_alt_outlined,
                      isActive: true,
                      onPressed: catId != null
                          ? () {
                        context.read<AllBalancesBloc>().add(
                          LoadAllBalancesEvent(catId: catId),
                        );
                      } : null,
                      label: Text(tr.apply),
                    ),
                  ),
                ],
              ),
            ),

          // Selected Filter Chip (when filters collapsed)
          if (selectedCategory != null && !_showFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${tr.accountCategory}: $selectedCategory',
                          style: TextStyle(
                            fontSize: 12,
                            color: color.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            setState(() {
                              catId = null;
                              selectedCategory = null;
                            });
                            context.read<AllBalancesBloc>().add(
                              ResetAllBalancesEvent(),
                            );
                          },
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: color.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(tr.accountNumber, style: titleStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(tr.accountName, style: titleStyle),
                ),
                SizedBox(
                  width: 80,
                  child: Text(tr.branchId, style: titleStyle),
                ),
                SizedBox(
                  width: 30,
                  child: Text('ID', style: titleStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(tr.accountCategory, style: titleStyle),
                ),
                SizedBox(
                  width: 150,
                  child: Text(tr.balance, style: titleStyle, textAlign: TextAlign.right),
                ),
              ],
            ),
          ),

          // Data Rows
          Expanded(
            child: BlocBuilder<AllBalancesBloc, AllBalancesState>(
              builder: (context, state) {
                if (state is AllBalancesInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 80,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "All Balances",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "View all accounts balances here",
                          style: TextStyle(color: color.outline),
                        ),
                      ],
                    ),
                  );
                }
                if (state is AllBalancesLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AllBalancesLoadedState) {
                  if (state.balances.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                    itemCount: state.balances.length,
                    itemBuilder: (context, index) {
                      final ab = state.balances[index];
                      return _buildTabletBalanceRow(ab, index, color);
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

  Widget _buildTabletBalanceRow(dynamic ab, int index, ColorScheme color) {
    final isEven = index.isEven;
    final balanceValue = double.tryParse(ab.balance ?? '0') ?? 0;
    final isPositive = balanceValue >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isEven ? color.primary.withValues(alpha: .02) : Colors.transparent,
        border: index == 0
            ? null
            : Border(
          top: BorderSide(color: color.outline.withValues(alpha: .1)),
        ),
      ),
      child: Row(
        children: [
          // Account Number
          SizedBox(
            width: 100,
            child: Text(
              ab.trdAccount.toString(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          // Account Name
          Expanded(
            flex: 2,
            child: Text(
              ab.accName ?? "",
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Branch
          SizedBox(
            width: 80,
            child: Text(
              ab.trdBranch.toString(),
              style: TextStyle(color: color.outline),
            ),
          ),

          // Category ID
          SizedBox(
            width: 30,
            child: Text(
              ab.acgId.toString(),
              style: TextStyle(color: color.outline),
            ),
          ),

          // Category Name
          Expanded(
            flex: 2,
            child: Text(
              ab.acgName ?? "",
              style: TextStyle(color: color.outline),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Balance
          SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    ab.balance ?? "0.00",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : color.error,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  ab.trdCcy ?? "",
                  style: TextStyle(
                    fontSize: 11,
                    color: Utils.currencyColors(ab.trdCcy ?? ""),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  int? catId;
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text("All Balances"),
        actions: [
          if (catId != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                setState(() {
                  catId = null;
                  selectedCategory = null;
                });
                context.read<AllBalancesBloc>().add(ResetAllBalancesEvent());
              },
            ),

        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: GlSubCategoriesDrop(
                    title: tr.accountCategory,
                    mainCategoryId: 0,
                    onChanged: (e) {
                      setState(() {
                        catId = e?.acgId;
                        selectedCategory = e?.acgName;
                      });
                      context.read<AllBalancesBloc>().add(
                        LoadAllBalancesEvent(catId: catId),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Selected Filter Chip
          if (selectedCategory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${tr.accountCategory}: $selectedCategory',
                        style: TextStyle(
                          fontSize: 12,
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          setState(() {
                            catId = null;
                            selectedCategory = null;
                          });
                          context.read<AllBalancesBloc>().add(
                            ResetAllBalancesEvent(),
                          );
                        },
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: color.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          Expanded(
            child: BlocBuilder<AllBalancesBloc, AllBalancesState>(
              builder: (context, state) {
                if (state is AllBalancesInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "All Balances",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "View all accounts balances here",
                          style: TextStyle(color: color.outline),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<AllBalancesBloc>().add(
                              LoadAllBalancesEvent(catId: catId),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Load Data'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is AllBalancesLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AllBalancesLoadedState) {
                  if (state.balances.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.balances.length,
                    itemBuilder: (context, index) {
                      final ab = state.balances[index];
                      return _buildMobileBalanceCard(ab, index, color, tr);
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

  Widget _buildMobileBalanceCard(dynamic ab, int index, ColorScheme color, AppLocalizations tr) {
    // Parse balance to double for comparison
    final balanceValue = double.tryParse(ab.balance ?? '0') ?? 0;
    final isPositive = balanceValue >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.outline.withValues(alpha: .1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: index.isOdd ? color.primary.withValues(alpha: .02) : color.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Number and Branch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${tr.accountNumber}: ${ab.trdAccount}",
                      style: TextStyle(
                        color: color.primary,
                        fontSize: 12,
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
                      color: color.secondary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${tr.branchId}: ${ab.trdBranch}",
                      style: TextStyle(
                        color: color.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Account Name
              Text(
                ab.accName ?? "",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              // Category
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: 14,
                    color: color.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ab.acgName ?? "",
                      style: TextStyle(
                        fontSize: 13,
                        color: color.outline,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr.balance,
                    style: TextStyle(
                      fontSize: 14,
                      color: color.outline,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withValues(alpha: .1)
                          : color.error.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ab.balance ?? "0.00",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : color.error,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ab.trdCcy ?? "",
                          style: TextStyle(
                            fontSize: 11,
                            color: Utils.currencyColors(ab.trdCcy ?? ""),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {

  int? catId;
  @override
  Widget build(BuildContext context) {
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.surface);
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text("All Balances"),
        actionsPadding: EdgeInsets.symmetric(horizontal: 10),
        actions: [
          if(catId !=null)
          ZOutlineButton(
              width: 130,
              backgroundHover: Theme.of(context).colorScheme.error,
              isActive: true,
              onPressed: (){
                setState(() {
                  catId = null;
                });
                context.read<AllBalancesBloc>().add(ResetAllBalancesEvent());
              },
              icon: Icons.filter_alt_off_outlined,
              label: Text(tr.clearFilters)),
          SizedBox(width: 8),
          ZOutlineButton(
              width: 100,
              onPressed: _printAllBalances,
              icon: Icons.print,
              label: Text(tr.print)),
          SizedBox(width: 8),
          ZOutlineButton(
            width: 120,
              onPressed: (){
              context.read<AllBalancesBloc>().add(LoadAllBalancesEvent(catId: catId));
              },
              isActive: true,
              icon: Icons.filter_alt,
              label: Text(tr.apply)),


        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                SizedBox(
                  width: 300,
                  child: GlSubCategoriesDrop(
                      title: tr.accountCategory,
                      mainCategoryId: 0,
                      onChanged: (e){
                        setState(() {
                          catId = e?.acgId;
                        });
                        context.read<AllBalancesBloc>().add(LoadAllBalancesEvent(catId: catId));
                      }),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8,horizontal: 5),
            margin: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: .9),
            ),
            child: Row(
              children: [
                SizedBox(
                    width: 100,
                    child: Text(tr.accountNumber,style: titleStyle)),

                Expanded(
                    child: Text(tr.accountName,style: titleStyle)),

                SizedBox(
                    width: 100,
                    child: Text(tr.branchId,style: titleStyle)),

                SizedBox(
                    width: 250,
                    child: Text(tr.accountCategory,style: titleStyle)),

                SizedBox(
                    width: 150,
                    child: Text(tr.balance,style: titleStyle)),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<AllBalancesBloc, AllBalancesState>(
              builder: (context, state) {
                if(state is AllBalancesInitial){
                  return NoDataWidget(
                    title: "All Balances",
                    message: "View all accounts balances here",
                    enableAction: false,
                  );
                }
                if(state is AllBalancesLoadingState){
                  return Center(child: CircularProgressIndicator());
                }
                if(state is AllBalancesLoadedState){
                  if(state.balances.isEmpty){
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                    );
                  }
                  return ListView.builder(
                      itemCount: state.balances.length,
                      itemBuilder: (context,index){
                      final ab = state.balances[index];
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 8,horizontal: 5),
                          margin: EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: index.isOdd? Theme.of(context).colorScheme.primary.withValues(alpha: .05) : Colors.transparent
                          ),
                          child: Row(
                          children: [
                            SizedBox(
                                width: 100,
                                child: Text(ab.trdAccount.toString())),

                            Expanded(
                                child: Text(ab.accName.toString())),
                            SizedBox(
                                width: 100,
                                child: Text(ab.trdBranch.toString())),
                            SizedBox(
                                width: 30,
                                child: Text(ab.acgId.toString())),
                            SizedBox(
                                width: 220,
                                child: Text(ab.acgName.toString())),

                            SizedBox(
                                width: 150,
                                child: Text("${ab.balance.toAmount()} ${ab.trdCcy}")),
                          ],
                                          ),
                        );
                  });
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

// Add this method to _DesktopState
  Future<void> _printAllBalances() async {
    final state = context.read<AllBalancesBloc>().state;

    if (state is AllBalancesLoadedState) {
      // Get company info from CompanyProfileBloc
      final companyState = context.read<CompanyProfileBloc>().state;
      ReportModel company = ReportModel();

      if (companyState is CompanyProfileLoadedState) {
        company = ReportModel(
          comName: companyState.company.comName ?? '',
          comAddress: companyState.company.addName ?? '',
          compPhone: companyState.company.comPhone ?? '',
          comEmail: companyState.company.comEmail ?? '',
          statementDate: DateTime.now().toFullDateTime,
          comLogo: companyState.company.comLogo != null
              ? base64Decode(companyState.company.comLogo!)
              : null,
        );
      }



      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => PrintPreviewDialog<List<AllBalancesModel>>(
            data: state.balances,
            company: company,
            buildPreview: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return AllBalancesPrintSettings().printPreview(
                balances: data,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,

              );
            },
            onPrint: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
              required selectedPrinter,
              required copies,
              required pages,
            }) {
              return AllBalancesPrintSettings().printDocument(
                balances: data,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
                selectedPrinter: selectedPrinter,
                copies: copies,
                pages: pages,
              );
            },
            onSave: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return AllBalancesPrintSettings().createDocument(
                balances: data,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
              );
            },
          ),
        );
      }
    } else {
     ToastManager.show(context: context, title: "Attention", message: "Please load the data first.", type: ToastType.warning);
    }
  }
}

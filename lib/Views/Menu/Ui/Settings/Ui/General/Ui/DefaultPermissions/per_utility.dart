import 'package:flutter/material.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';

class PermissionMapper {
  PermissionMapper._();

  static final Map<String, String Function(AppLocalizations)> _mappings = {
    // Dashboard
    "Dashboard": (l) => l.dashboard,
    "Counts": (l) => l.counts,
    "Exchange Rate Graph": (l) => l.exchangeRateGraph,
    "Daily Transactions Graph": (l) => l.dailyTransactionsGraph,
    "Daily Transaction Totals": (l) => l.dailyTransactionTotals,
    "Digital Clock": (l) => l.digitalClock,
    "Exchange Rates": (l) => l.exchangeRates,
    "Profit Loss Graph": (l) => l.profitLossGraph,
    "Reminder Notifications": (l) => l.reminderNotifications,

    // Finance
    "Finance": (l) => l.finance,
    "Currency Tab": (l) => l.currencyTab,
    "Currency": (l) => l.currency,
    "GL Accounts": (l) => l.glAccounts,
    "Payroll": (l) => l.payroll,
    "EOY Operation": (l) => l.eoyOperation,
    "Reminders": (l) => l.reminders,

    // Journal
    "Journal": (l) => l.journal,
    "All Transactions": (l) => l.allTransactions,
    "Authorized Transaction": (l) => l.authorizedTransaction,
    "Pending Transaction": (l) => l.pendingTransaction,
    "Cash Deposit": (l) => l.cashDeposit,
    "Cash Withdraw": (l) => l.cashWithdraw,
    "Income Entry": (l) => l.incomeEntry,
    "Expense Entry": (l) => l.expenseEntry,
    "GL Debit": (l) => l.glDebit,
    "GL Credit": (l) => l.glCredit,
    "FT Single Account": (l) => l.ftSingleAccount,
    "FT Multi Account": (l) => l.ftMultiAccount,
    "FX Transactions": (l) => l.fxTransactions,

    // Stakeholders
    "Stakeholders": (l) => l.stakeholders,
    "Individuals": (l) => l.individuals,
    "Accounts": (l) => l.accounts,
    "Users": (l) => l.users,

    // HR
    "HR - Human Resource": (l) => l.hrTitle,
    "Employees": (l) => l.employees,
    "Attendance": (l) => l.attendance,
    "All Users": (l) => l.allUsers,
    "Overview": (l) => l.overview,
    "Permissions": (l) => l.permissions,
    "User Log": (l) => l.userLog,

    // Transport
    "Transport": (l) => l.transport,
    "Shipping": (l) => l.shipping,
    "Drivers": (l) => l.drivers,
    "Vehicles": (l) => l.vehicles,

    // Inventory
    "Inventory": (l) => l.inventory,
    "Orders Tab": (l) => l.ordersTab,
    "Estimate Tab": (l) => l.estimateTab,
    "Goods Shift Tab": (l) => l.goodsShiftTab,
    "Adjustment Tab": (l) => l.adjustmentTab,
    "Purchase": (l) => l.purchase,
    "Sale": (l) => l.sale,
    "Estimate": (l) => l.estimate,
    "Goods Shift": (l) => l.goodsShift,
    "Adjustment": (l) => l.adjustment,
    "Find Invoice": (l) => l.findInvoice,

    // Settings
    "Settings": (l) => l.settings,
    "General Tab": (l) => l.generalTab,
    "System Settings": (l) => l.systemSettings,
    "Password Change": (l) => l.passwordChange,
    "User Profile": (l) => l.userProfile,
    "Roles and Permissions": (l) => l.rolesAndPermissions,
    "Company Tab": (l) => l.companyTab,
    "Profile": (l) => l.profile,
    "Branches": (l) => l.branches,
    "Storage": (l) => l.storage,
    "Transaction Type": (l) => l.transactionType,
    "Stock": (l) => l.stock,
    "Products": (l) => l.products,
    "Category": (l) => l.category,
    "Backup": (l) => l.backup,
    "About": (l) => l.about,

    // Reports
    "Reports": (l) => l.reports,
    "Account Statement Single Date": (l) => l.accountStatementSingleDate,
    "GL Statement Single Date": (l) => l.glStatementSingleDate,
    "GL Statement Periodic Date": (l) => l.glStatementPeriodicDate,
    "Creditors": (l) => l.creditors,
    "Debtors": (l) => l.debtors,
    "Stock Availability": (l) => l.stockAvailability,
    "Product Movement": (l) => l.productMovement,
    "Purchase Invoices": (l) => l.purchaseInvoices,
    "Sale Invoices": (l) => l.saleInvoices,
    "All Invoices": (l) => l.allInvoices,
    "Cash Balance All Branch": (l) => l.cashBalanceAllBranch,
    "Cash Balance Single Branch": (l) => l.cashBalanceSingleBranch,
    "Trial Balance": (l) => l.trialBalance,
    "Transaction Details": (l) => l.transactionDetails,
    "Transactions Report": (l) => l.transactionsReport,
    "All Balances": (l) => l.allBalances,
    "User Role and Permission": (l) => l.userRoleAndPermission,
    "Stakeholder Account": (l) => l.stakeholderAccount,
    "Currencies": (l) => l.currencies,
    "Balance Sheet": (l) => l.balanceSheet,

    // Actions
    "Create": (l) => l.create,
    "Read": (l) => l.read,
    "Update": (l) => l.update,
    "Delete": (l) => l.delete,
  };

  static String localize(BuildContext context, String apiName) {
    final locale = AppLocalizations.of(context)!;
    final mapper = _mappings[apiName];

    if (mapper != null) {
      return mapper(locale);
    }

    // Fallback: Return formatted API name
    return apiName
        .split(' ')
        .map((word) => word.isNotEmpty
        ? word[0].toUpperCase() + word.substring(1).toLowerCase()
        : '')
        .join(' ');
  }
}
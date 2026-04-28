// order_parser.dart

class OrderParser {
  // Account definitions
  static const int cashAccount = 10101010;
  static const int cogsAccount = 10101011;
  static const int extraChargesAccount = 10101018;
  static const int revenueAccount = 30303031;
  static const int discountAccount = 40404053;
  static const int stakeholderMin = 500000;


// Get expenses - take the Dr entries for expense accounts (40404040 - 40404999)
  static List<Map<String, dynamic>> getExpenses(List<Map<String, dynamic>> payments) {
    return payments.where((p) {
      final account = p['account'];
      final drCr = p['drCr'];

      // Expense accounts range (40404040 to 40404999)
      // Exclude stakeholder accounts (>= 500000)
      return account is int &&
          account >= 40404040 &&
          account <= 40404999 &&
          drCr == 'Dr';
    }).toList();
  }

// Get expense total (for landed price calculation)
  static double getExpensesTotal(List<Map<String, dynamic>> payments) {
    final expenses = getExpenses(payments);
    return expenses.fold(0.0, (sum, expense) => sum + (expense['amount'] as double));
  }

// Check if a payment is an expense
  static bool isExpensePayment(Map<String, dynamic> payment) {
    final account = payment['account'];
    final drCr = payment['drCr'];
    return account is int &&
        account >= 40404040 &&
        account <= 40404999 &&
        drCr == 'Dr';
  }

// Get all expense accounts from payments (Dr side, range 40404040-40404999)
  static List<Map<String, dynamic>> getExpensePayments(List<Map<String, dynamic>> payments) {
    return payments.where((p) {
      final account = p['account'];
      final drCr = p['drCr'];
      return account is int &&
          account >= 40404040 &&
          account <= 40404999 &&
          drCr == 'Dr';
    }).toList();
  }

  // Parse complete order response
  static Map<String, dynamic> parseOrderResponse(Map<String, dynamic> response) {
    return {
      'orderId': response['ordID'],
      'orderType': response['ordName'],
      'partyId': response['ordPersonal'],
      'partyName': response['ordPersonalName'],
      'reference': response['ordxRef'] ?? '',
      'remarks': response['ordRemarks'] ?? '',
      'entryDate': response['ordEntryDate'],
      'records': _parseRecords(response['records']),
      'payments': _parsePayments(response['payments']),
    };
  }

  // Parse records (items)
  static List<Map<String, dynamic>> _parseRecords(dynamic recordsData) {
    final records = <Map<String, dynamic>>[];
    if (recordsData is! List) return records;

    for (var record in recordsData) {
      records.add({
        'stkID': record['stkID'],
        'productId': record['stkProduct'],
        'storageId': record['stkStorage'],
        'quantity': double.tryParse(record['stkQuantity']?.toString() ?? '0') ?? 0,
        'batch': double.tryParse(record['stkQtyInBatch']?.toString() ?? '0') ?? 0,
        'productName': record['proName'] ?? '',
        'storageName': record['stgName'] ?? '',
        'unit': record['proUnit'] ?? '',
        'purchasePrice': double.tryParse(record['stkPurPrice']?.toString() ?? '0') ?? 0,
        'salePrice': double.tryParse(record['stkSalePrice']?.toString() ?? '0') ?? 0,
        'landedPrice': double.tryParse(record['stkLandedPurPrice']?.toString() ?? '0') ?? 0,
        'discount': double.tryParse(record['stkDiscount']?.toString() ?? '0') ?? 0,
      });
    }
    return records;
  }

  // Parse payments
  static List<Map<String, dynamic>> _parsePayments(dynamic paymentsData) {
    final payments = <Map<String, dynamic>>[];
    if (paymentsData is! List) return payments;

    for (var payment in paymentsData) {
      payments.add({
        'trdID': payment['trdID'],
        'account': int.tryParse(payment['trdAccount'].toString()) ?? 0,
        'amount': double.tryParse(payment['trdAmount']?.toString() ?? '0') ?? 0.0,
        'currency': payment['trdCcy']?.toString() ?? '',
        'drCr': payment['trdDrCr']?.toString() ?? '',
        'narration': payment['trdNarration']?.toString() ?? '',
      });
    }

    return payments;
  }

  // ============ SALE INVOICE SPECIFIC ============

  // Add this for purchase cash currency
  static String getPurchaseCashCurrency(List<Map<String, dynamic>> payments) {
    for (var payment in payments) {
      final account = payment['account'];
      final drCr = payment['drCr'];
      final narration = payment['narration'] as String;

      if (account == cashAccount && drCr == 'Cr' &&
          (narration.contains('Cash payment to supplier') || narration.contains('Cash payment'))) {
        return payment['currency'] as String;
      }
    }
    return '';
  }

// Get total invoice amount from supplier account (what we owe)
  static double getSupplierInvoiceAmount(List<Map<String, dynamic>> payments) {
    final supplierAccount = getSupplierAccount(payments);
    if (supplierAccount != null) {
      return supplierAccount['amount'] as double;
    }
    return 0.0;
  }


// Add this method to get supplier credit amount
  static double getSupplierCreditAmount(List<Map<String, dynamic>> payments) {
    final supplierAccount = getSupplierAccount(payments);
    return supplierAccount?['amount'] as double? ?? 0.0;
  }
  // Get cash payment (account 10101010) - Dr side means customer paid cash
  static double getCashPayment(List<Map<String, dynamic>> payments) {
    final cashPayment = payments.firstWhere(
          (p) => p['account'] == cashAccount && p['drCr'] == 'Dr',
      orElse: () => {'amount': 0.0},
    );
    return cashPayment['amount'] as double;
  }

  // Get cash currency
  static String getCashCurrency(List<Map<String, dynamic>> payments) {
    final cashPayment = payments.firstWhere(
          (p) => p['account'] == cashAccount,
      orElse: () => {'currency': 'USD'},
    );
    return cashPayment['currency'] as String;
  }

  // Get customer account (stakeholder) - Dr side means customer owes money (credit sale)
  static Map<String, dynamic>? getCustomerAccount(List<Map<String, dynamic>> payments) {
    final excludedAccounts = [cashAccount, cogsAccount, extraChargesAccount, revenueAccount, discountAccount];

    final customerAccount = payments.firstWhere(
          (p) {
        final account = p['account'];
        return account >= stakeholderMin &&
            !excludedAccounts.contains(account) &&
            p['drCr'] == 'Dr'; // Debit means customer owes us (receivable)
      },
      orElse: () => {},
    );
    return customerAccount.isEmpty ? null : customerAccount;
  }

  // Get extra charges (account 10101018) - Cr side means we charged customer extra
  // This amount is ADDED to the invoice total
  static double getExtraCharges(List<Map<String, dynamic>> payments) {
    final extra = payments.firstWhere(
          (p) => p['account'] == extraChargesAccount && p['drCr'] == 'Cr',
      orElse: () => {'amount': 0.0},
    );
    return extra['amount'] as double;
  }

  // Get general discount (account 40404053) - Dr side means we gave discount to customer
  // This amount is SUBTRACTED from the invoice total
  static double getGeneralDiscount(List<Map<String, dynamic>> payments) {
    final discount = payments.firstWhere(
          (p) => p['account'] == discountAccount && p['drCr'] == 'Dr',
      orElse: () => {'amount': 0.0},
    );
    return discount['amount'] as double;
  }

  // ============ PURCHASE INVOICE SPECIFIC ============


  // Get cash payment for PURCHASE (Cr side - WE paid cash TO supplier)
  static double getPurchaseCashPayment(List<Map<String, dynamic>> payments) {
    double cashPayment = 0;
    for (var payment in payments) {
      final account = payment['account'];
      final drCr = payment['drCr'];
      final narration = payment['narration'] as String;

      // We pay supplier in cash → Credit (Cr) entry to cash account
      if (account == cashAccount && drCr == 'Cr') {
        // This could be the main invoice payment
        if (narration.contains('Cash payment to supplier') ||
            narration.contains('Cash payment')) {
          cashPayment = payment['amount'] as double;
        }
      }
    }
    return cashPayment;
  }

// Get supplier account (Cr side - we owe supplier)
  static Map<String, dynamic>? getSupplierAccount(List<Map<String, dynamic>> payments) {
    final excludedAccounts = [cashAccount, cogsAccount, extraChargesAccount, revenueAccount, discountAccount];

    final supplierAccount = payments.firstWhere(
          (p) {
        final account = p['account'];
        return account >= stakeholderMin &&
            !excludedAccounts.contains(account) &&
            p['drCr'] == 'Cr'; // Credit means we owe supplier (Payable)
      },
      orElse: () => {},
    );
    return supplierAccount.isEmpty ? null : supplierAccount;
  }



  // Get total expenses amount
  static double getTotalExpenses(List<Map<String, dynamic>> payments) {
    final expenses = getExpensePayments(payments);
    return expenses.fold(0.0, (sum, e) => sum + (e['amount'] as double));
  }




  // ============ COMMON ============

  // Get exchange rate from narration
  static double getExchangeRate(List<Map<String, dynamic>> payments) {
    for (var payment in payments) {
      final narration = payment['narration'] as String;
      final match = RegExp(r'@Rate:\s*([\d.]+)').firstMatch(narration);
      if (match != null) {
        return double.parse(match.group(1)!);
      }
    }
    return 1.0;
  }

  // Check if payment is credit (customer owes)
  static bool hasCreditPayment(List<Map<String, dynamic>> payments) {
    final customerAccount = getCustomerAccount(payments);
    return customerAccount != null && (customerAccount['amount'] as double) > 0;
  }

  // Get credit amount from customer account
  static double getCreditAmount(List<Map<String, dynamic>> payments) {
    final customerAccount = getCustomerAccount(payments);
    return customerAccount?['amount'] as double? ?? 0.0;
  }
}
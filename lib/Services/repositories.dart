import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http/http.dart' hide MultipartFile;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Services/api_services.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/ExchangeRate/model/rate_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/GlAccounts/GlCategories/model/cat_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/GlAccounts/model/gl_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/model/emp_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/Ui/Log/model/user_log_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/model/usr_report_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchATAT/model/fetch_atat_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/TxnByReference/model/txn_ref_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/model/transaction_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/ProjectsById/model/project_by_id_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/IncomeExpense/model/prj_inc_exp_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/ProjectServices/model/project_services_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/AccountStatement/model/stmt_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/GLStatement/model/gl_statement_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/Treasury/model/cash_balance_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/TrialBalance/model/trial_balance_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/Cardx/model/cardx_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/TotalDailyTxn/model/daily_txn_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/model/com_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/model/storage_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Services/model/services_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/ProductCategory/model/pro_cat_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/model/product_stock_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/TxnTypes/model/txn_types_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/model/acc_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/model/stk_acc_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/Adjustment/model/adjustment_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/Estimate/model/estimate_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/NewSale/model/sale_invoice_items.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/Orders/model/orders_model.dart';
import '../Views/Auth/Subscription/model/sub_model.dart';
import '../Views/Menu/Ui/Dashboard/Views/DailyGross/model/gross_model.dart';
import '../Views/Menu/Ui/Dashboard/Views/Stats/model/stats_model.dart';
import '../Views/Menu/Ui/Finance/Ui/EndOfYear/model/eoy_model.dart';
import '../Views/Menu/Ui/Finance/Ui/Payroll/model/payroll_model.dart';
import '../Views/Menu/Ui/HR/Ui/Attendance/model/attendance_model.dart';
import '../Views/Menu/Ui/HR/Ui/UserDetail/Ui/Permissions/per_model.dart';
import '../Views/Menu/Ui/HR/Ui/Users/model/user_model.dart';
import '../Views/Menu/Ui/Journal/Ui/FetchGLAT/model/glat_model.dart';
import '../Views/Menu/Ui/Journal/Ui/GetOrder/model/get_order_model.dart';
import '../Views/Menu/Ui/Journal/Ui/ProjectTxn/model/project_txn_model.dart';
import '../Views/Menu/Ui/Projects/Ui/AllProjects/model/pjr_model.dart';
import '../Views/Menu/Ui/Reminder/model/reminder_model.dart';
import '../Views/Menu/Ui/Report/Ui/Finance/Accounts/model/accounts_report_model.dart';
import '../Views/Menu/Ui/Report/Ui/Finance/AllBalances/model/all_balances_model.dart';
import '../Views/Menu/Ui/Report/Ui/Finance/ArApReport/model/ar_ap_model.dart';
import '../Views/Menu/Ui/Report/Ui/Finance/BalanceSheet/model/bs_model.dart';
import '../Views/Menu/Ui/Report/Ui/Finance/ExchangeRate/model/rate_report_model.dart';
import '../Views/Menu/Ui/Report/Ui/HR/AttendanceReport/model/attendance_report_model.dart';
import '../Views/Menu/Ui/Report/Ui/Stock/OrdersReport/model/order_report_model.dart';
import '../Views/Menu/Ui/Report/Ui/Stock/StockAvailability/model/product_report_model.dart';
import '../Views/Menu/Ui/Report/Ui/TransactionRef/model/txn_report_model.dart';
import '../Views/Menu/Ui/Report/Ui/TxnReport/model/txn_report_model.dart';
import '../Views/Menu/Ui/Report/Ui/UserReport/StakeholdersReport/model/ind_report_model.dart';
import '../Views/Menu/Ui/Settings/Ui/Company/Branch/Ui/BranchLimits/model/limit_model.dart';
import '../Views/Menu/Ui/Settings/Ui/Company/Branches/model/branch_model.dart';
import '../Views/Menu/Ui/Settings/Ui/General/Ui/DefaultPermissions/model/permission_settings_model.dart';
import '../Views/Menu/Ui/Settings/Ui/General/Ui/UserProfileSettings/model/usr_profile_model.dart';
import '../Views/Menu/Ui/Settings/Ui/General/Ui/UserRole/model/role_model.dart';
import '../Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/model/product_model.dart';
import '../Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../Views/Menu/Ui/Stock/Ui/GoodsShift/model/shift_model.dart';
import '../Views/Menu/Ui/Stock/Ui/OrderScreen/GetOrderById/model/ord_by_id_model.dart';
import '../Views/Menu/Ui/Stock/Ui/OrderScreen/NewPurchase/model/purchase_invoice_items.dart';

class Repositories {
  final ApiServices api;

  const Repositories(this.api);

  ///Authentication ............................................................
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await api.post(
      endpoint: "/user/login.php",
      data: {"usrName": username, "usrPass": password},
    );

    return response.data;
  }

  ///Finance ...................................................................
  Future<Map<String, dynamic>> eoyOperationProcess({
    required String usrName,
    required String remark,
    required int branchCode,
  }) async {
    final response = await api.post(
      endpoint: "/finance/eoyOperation.php",
      data: {"usrName": usrName, "remark": remark, "parkingBranch": branchCode},
    );
    return response.data;
  }

  Future<List<PAndLModel>> getProfitAndLoss({CancelToken? cancelToken}) async {
    // Fetch data from API
    final response = await api.get(
      endpoint: "/finance/eoyOperation.php",
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => PAndLModel.fromMap(json))
          .toList();
    }

    return [];
  }

  ///Get Company ...............................................................
  Future<CompanySettingsModel> getCompanyProfile({
    CancelToken? cancelToken,
  }) async {
    final response = await api.get(
      endpoint: "/setting/companyProfile.php",
      cancelToken: cancelToken,
    );

    final data = response.data;

    // Case 3: API returns a single object instead of list
    if (data is Map<String, dynamic>) {
      return CompanySettingsModel.fromMap(data);
    }
    // Case 4: API returns a list with first object as map
    if (data is List && data.first is Map<String, dynamic>) {
      return CompanySettingsModel.fromMap(data.first);
    }
    throw Exception("Invalid API response format");
  }

  Future<Map<String, dynamic>> editCompanyProfile({
    required CompanySettingsModel newData,
  }) async {
    final response = await api.put(
      endpoint: "/setting/companyProfile.php",
      data: newData.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> uploadCompanyProfile({
    required Uint8List image,
  }) async {
    // Create a valid filename like Postman does
    final String fileName = "photo_${DateTime.now().millisecondsSinceEpoch}.jpg";

    FormData formData = FormData.fromMap({
      "image": MultipartFile.fromBytes(
        image,
        filename: fileName,
        contentType: MediaType("image", "jpeg"),
      ),
    });

    final response = await api.uploadFile(
      endpoint: "/setting/companyProfile.php",
      data: formData,
    );

    return response.data;
  }

  ///Stakeholder | Individuals .................................................
  Future<List<IndividualsModel>> getStakeholders({int? indId, String? query, CancelToken? cancelToken}) async {
    // Build query parameters dynamically
    final queryParams =  {'perID': indId, 'search': query};

    // Fetch data from API
    final response = await api.get(
      endpoint: "/stakeholder/personal.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => IndividualsModel.fromMap(json))
          .toList();
    }

    return [];
  }
  Future<Map<String, dynamic>> addStakeholder({required IndividualsModel stk}) async {
    final response = await api.post(
      endpoint: "/stakeholder/personal.php",
      data: stk.toMap(),
    );
    return response.data;
  }
  Future<Map<String, dynamic>> editStakeholder({required IndividualsModel stk}) async {
    final response = await api.put(
      endpoint: "/stakeholder/personal.php",
      data: stk.toMap(),
    );
    return response.data;
  }
  Future<IndividualsModel> getPersonProfileById({required int perId, CancelToken? cancelToken}) async {
    final response = await api.get(
      endpoint: "/stakeholder/personal.php",
      queryParams: {'perID': perId},
      cancelToken: cancelToken,
    );

    final data = response.data;

    // Case 1: API returns an error message
    if (data is Map && data['msg'] != null) {
      throw Exception(data['msg']);
    }

    // Case 2: API returns a list, but empty
    if (data is List && data.isEmpty) {
      throw Exception("Person not found");
    }

    // Case 3: API returns a single object instead of list
    if (data is Map<String, dynamic>) {
      return IndividualsModel.fromMap(data);
    }

    // Case 4: API returns a list with first object as map
    if (data is List && data.first is Map<String, dynamic>) {
      return IndividualsModel.fromMap(data.first);
    }

    throw Exception("Invalid API response format");
  }
  Future<Map<String, dynamic>> uploadPersonalPhoto({required int perID, required Uint8List image}) async {
    final String fileName = "photo_${DateTime.now().millisecondsSinceEpoch}.jpg";
    FormData formData = FormData.fromMap({
      "perID": perID.toString(),
      "image": MultipartFile.fromBytes(
        image,
        filename: fileName,
        contentType: MediaType("image", "jpeg"),
      ),
    });

    final response = await api.uploadFile(
      endpoint: "/stakeholder/uploadPersonalPhoto.php",
      data: formData,
    );

    return response.data;
  }

  ///Accounts | Stakeholder's Account ..........................................
  Future<List<AccountsModel>> getAccounts({int? ownerId, CancelToken? cancelToken}) async {
    // Build query parameters dynamically
    final queryParams = ownerId != null ? {'perID': ownerId} : null;

    // Fetch data from API
    final response = await api.get(
      endpoint: "/journal/allAccounts.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => AccountsModel.fromMap(json))
          .toList();
    }

    return [];
  }
  Future<List<StakeholdersAccountsModel>> getStakeholdersAccounts({String? search}) async {
    final response = await api.post(
      endpoint: "/journal/accountDetails.php",
      data: {"searchValue": search},
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => StakeholdersAccountsModel.fromMap(json))
          .toList();
    }

    return [];
  }
  Future<Map<String, dynamic>> addAccount({required AccountsModel newAccount}) async {
    final response = await api.post(
      endpoint: "/stakeholder/account.php",
      data: newAccount.toMap(),
    );
    return response.data;
  }
  Future<Map<String, dynamic>> editAccount({required AccountsModel newAccount}) async {
    final response = await api.put(
      endpoint: "/stakeholder/account.php",
      data: newAccount.toMap(),
    );
    return response.data;
  }

  Future<List<AccountsModel>> getAccountFilter({
    final String? include,
    final String? input,
    final String? exclude,
    final String? ccy,
  }) async {
    // Fetch data from API
    final response = await api.post(
      endpoint: "/journal/allAccounts.php",
      data: {
        "ccy": ccy,
        "input": input,
        "include": include,
        "account": exclude,
      },
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => AccountsModel.fromMap(json))
          .toList();
    }

    return [];
  }

  /// GL Accounts | System .....................................................
  Future<List<GlAccountsModel>> getGl({String? input, CancelToken? cancelToken}) async {

    // Fetch data from API
    final response = await api.get(
      endpoint: "/finance/glAccount.php",
      queryParams: {
      "input": input
      },
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => GlAccountsModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> addGl({
    required GlAccountsModel newAccount,
  }) async {
    final response = await api.post(
      endpoint: "/finance/glAccount.php",
      data: newAccount.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> editGl({
    required GlAccountsModel newAccount,
  }) async {
    final response = await api.put(
      endpoint: "/finance/glAccount.php",
      data: newAccount.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteGl({required int accNumber}) async {
    final response = await api.delete(
      endpoint: "/finance/glAccount.php",
      data: {"acc": accNumber},
    );

    return response.data;
  }

  /// GL Sub Categories ........................................................
  Future<List<GlCategoriesModel>> getGlSubCategories({
    required int catId,
    CancelToken? cancelToken,
  }) async {
    // Fetch data from API
    final response = await api.get(
      endpoint: "/finance/accountCategory.php",
      queryParams: {"cat": catId},
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => GlCategoriesModel.fromMap(json))
          .toList();
    }

    return [];
  }

  ///Users .....................................................................
  Future<List<UsersModel>> getUsers({int? usrOwner, CancelToken? cancelToken,}) async {
    // Build query parameters dynamically
    final queryParams = usrOwner != null ? {'perID': usrOwner} : null;

    // Fetch data from API
    final response = await api.get(
      endpoint: "/HR/users.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => UsersModel.fromMap(json))
          .toList();
    }

    return [];
  }
  Future<Map<String, dynamic>> addUser({required UsersModel newUser}) async {
    final response = await api.post(
      endpoint: "/HR/users.php",
      data: newUser.toMap(),
    );
    return response.data;
  }
  Future<Map<String, dynamic>> editUser({required UsersModel newUser}) async {
    final response = await api.put(
      endpoint: "/HR/users.php",
      data: newUser.toMap(),
    );
    return response.data;
  }

  ///Roles .....................................................................
  Future<List<UserRoleModel>> getUserRole({int? usrOwner, CancelToken? cancelToken,}) async {

    // Fetch data from API
    final response = await api.get(
      endpoint: "/setting/roles.php",
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => UserRoleModel.fromMap(json))
          .toList();
    }

    return [];
  }
  Future<Map<String, dynamic>> addNewRole({required String usrName, required String roleName}) async {
    final response = await api.post(
      endpoint: "/setting/roles.php",
      data: {
        "usrName": usrName,
        "rolName": roleName
      }
    );
    return response.data;
  }
  Future<Map<String, dynamic>> editUserRole({required UserRoleModel newRole}) async {
    final response = await api.put(
      endpoint: "/setting/roles.php",
      data: newRole.toMap()
    );
    return response.data;
  }
  Future<Map<String, dynamic>> deleteUserRole({required int roleId}) async {
    final response = await api.delete(
      endpoint: "/setting/roles.php",
      data:  {
        "rolID": roleId
      },
    );
    return response.data;
  }

  ///User Role Settings ........................................................
  Future<List<UserRolePermissionSettingModel>> getPermissionSettings({CancelToken? cancelToken,}) async {
    final response = await api.get(
      endpoint: "/setting/userRoles.php",
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => UserRolePermissionSettingModel.fromMap(json))
          .toList();
    }

    return [];
  }
  Future<Map<String, dynamic>> updatePermissionSettings({required PermissionActionModel permissions,}) async {

    final response = await api.put(
      endpoint: "/setting/userRoles.php",
      data: permissions.toMap(),
    );
    return response.data;
  }

  ///Employees .................................................................
  Future<List<EmployeeModel>> getEmployees({String? cat, CancelToken? cancelToken,}) async {
    // Build query parameters dynamically
    final queryParams = cat != null ? {'cat': cat} : null;

    // Fetch data from API
    final response = await api.get(
      endpoint: "/HR/employees.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => EmployeeModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> addEmployee({
    required EmployeeModel newEmployee,
  }) async {
    final response = await api.post(
      endpoint: "/HR/employees.php",
      data: newEmployee.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateEmployee({
    required EmployeeModel newEmployee,
  }) async {
    final response = await api.put(
      endpoint: "/HR/employees.php",
      data: newEmployee.toMap(),
    );
    return response.data;
  }

  ///Permissions ..............................................................
  Future<List<UserPermissionsModel>> getPermissions({
    required String usrName,
    CancelToken? cancelToken,
  }) async {
    // Build query parameters dynamically
    final queryParams = {'username': usrName};

    // Fetch data from API
    final response = await api.get(
      endpoint: "/user/permissions.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => UserPermissionsModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> updatePermissions({
    required int usrId,
    required String usrName,
    required List<Map<String, dynamic>> permissions,
  }) async {
    final response = await api.put(
      endpoint: "/user/permissions.php",
      data: {
        "LogedInUser": usrName,
        "uprUserID": usrId,
        "records": {
          "records": permissions.map((p) => {
            "uprRole": p["uprRole"],
            "uprStatus": p["uprStatus"],
          }).toList(),
        },
      },
    );
    return response.data;
  }

  ///Currencies ................................................................
  Future<List<CurrenciesModel>> getCurrencies({
    required int? status,
    CancelToken? cancelToken,
  }) async {
    // Build query parameters dynamically
    final queryParams = {'status': status};

    // Fetch data from API
    final response = await api.get(
      endpoint: "/finance/currency.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => CurrenciesModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> updateCcyStatus({
    required bool status,
    required String? ccyCode,
  }) async {
    final response = await api.put(
      endpoint: "/finance/currency.php",
      data: {"ccyStatus": status, "ccyCode": ccyCode},
    );
    return response.data;
  }

  ///Exchange Rate .............................................................
  Future<List<ExchangeRateModel>> getExchangeRate({
    required String? ccyCode,
    CancelToken? cancelToken,
  }) async {
    // Build query parameters dynamically
    final queryParams = {'ccy': ccyCode};

    // Fetch data from API
    final response = await api.get(
      endpoint: "/finance/exchangeRate.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => ExchangeRateModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> addExchangeRate({
    required ExchangeRateModel newRate,
  }) async {
    final response = await api.post(
      endpoint: "/finance/exchangeRate.php",
      data: newRate.toMap(),
    );
    return response.data;
  }

  Future<String?> getSingleRate({
    required String fromCcy,
    required String toCcy,
  }) async {
    final response = await api.post(
      endpoint: "/journal/getSingleExRate.php",
      data: {'ccyFrom': fromCcy, 'ccyTo': toCcy},
    );

    // Handle server error response
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // Expecting a Map: { "crExchange": "66.300000" }
    if (response.data is Map<String, dynamic>) {
      return response.data["crExchange"]?.toString();
    }

    return null;
  }

  /// Fetch GL transaction by Vehicle ID
  Future<GlatModel> getGlatTransaction(String ref, {CancelToken? cancelToken,}) async {
    final response = await api.get(
      endpoint: "/transport/vehicleTransaction.php",
      queryParams: {"ref": ref},
      cancelToken: cancelToken,
    );

    // The API already returns your JSON object
    final data = response.data;

    // Parse into model
    return GlatModel.fromMap(data);
  }

  /// Transactions | Cash Deposit | Withdraw ...................................
  Future<List<TransactionsModel>> getTransactionsByStatus({
    String? status,
    CancelToken? cancelToken,
  }) async {
    // Build query parameters dynamically
    final queryParams = {'status': status};

    // Fetch data from API
    final response = await api.get(
      endpoint: "/journal/getTransactions.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => TransactionsModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<TxnByReferenceModel> getTxnByReference({
    required String reference,
    CancelToken? cancelToken,
  }) async {
    final queryParams = {'ref': reference};
    final response = await api.get(
      endpoint: '/journal/getSingleTransaction.php',
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    final data = response.data;

    // Case 3: API returns a single object instead of list
    if (data is Map<String, dynamic>) {
      return TxnByReferenceModel.fromMap(data);
    }
    // Case 4: API returns a list with first object as map
    if (data is List && data.first is Map<String, dynamic>) {
      return TxnByReferenceModel.fromMap(data.first);
    }
    throw Exception("Invalid API response format");
  }

  Future<FetchAtatModel> getATATByReference({
    required String reference,
    CancelToken? cancelToken,
  }) async {
    final queryParams = {'ref': reference};
    final response = await api.get(
      endpoint: '/journal/fundTransfer.php',
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return FetchAtatModel.fromMap(data);
    }

    // Optional: handle case where API accidentally wraps in a list
    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return FetchAtatModel.fromMap(data.first);
    }

    throw Exception("Invalid API response format: $data");
  }

  Future<Map<String, dynamic>> cashFlowOperations({
    required TransactionsModel newTransaction,
  }) async {
    final response = await api.post(
      endpoint: "/journal/cashWD.php",
      data: newTransaction.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> fundTransfer({
    required TransactionsModel newTransaction,
  }) async {
    final response = await api.post(
      endpoint: "/journal/fundTransfer.php",
      data: newTransaction.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> bulkTransfer({
    required String userName,
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await api.post(
      endpoint: '/journal/fundTransferMA.php',
      data: {'usrName': userName, 'records': records},
    );

    // Parse response
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      return responseData;
    } else if (responseData is String) {
      // If response is a simple string message
      return {'msg': responseData};
    }

    return {'msg': 'Unknown response format'};
  }

  Future<Map<String, dynamic>> fxTransfer({
    required String userName,
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await api.post(
      endpoint: '/journal/crossCurrency.php',
      data: {'usrName': userName, 'records': records},
    );

    // Parse response
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      return responseData;
    } else if (responseData is String) {
      // If response is a simple string message
      return {'msg': responseData, 'account': responseData};
    }

    return {'msg': 'Unknown response format'};
  }

  Future<Map<String, dynamic>> authorizeTxn({
    required String reference,
    required String? usrName,
  }) async {
    final response = await api.put(
      endpoint: "/journal/transactionActivity.php",
      data: {"reference": reference, "username": usrName},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> reverseTxn({
    required String reference,
    required String? usrName,
  }) async {
    final response = await api.post(
      endpoint: "/journal/transactionActivity.php",
      data: {"reference": reference, "username": usrName},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteTxn({
    required String reference,
    required String? usrName,
  }) async {
    final response = await api.delete(
      endpoint: "/journal/transactionActivity.php",
      data: {"reference": reference, "username": usrName},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateTxn({
    required TransactionsModel newTxn,
  }) async {
    final response = await api.put(
      endpoint: "/journal/cashWD.php",
      data: newTxn.toMap(),
    );
    return response.data;
  }

  ///Password Settings .........................................................
  Future<Map<String, dynamic>> forceChangePassword({
    required String credential,
    required String newPassword,
  }) async {
    final response = await api.put(
      endpoint: "/user/changePass.php",
      data: {"usrName": credential, "usrPass": newPassword},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> changePassword({
    required String credential,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await api.post(
      endpoint: "/user/changePass.php",
      data: {
        "usrName": credential,
        "usrPass": oldPassword,
        "usrNewPass": newPassword,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String credential,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await api.put(
      endpoint: "/user/users.php",
      data: {"credential": credential, "newPassword": newPassword},
    );
    return response.data;
  }

  ///Branches & Limits  .................................................
  Future<List<BranchModel>> getBranches({
    int? brcId,
    CancelToken? cancelToken,
  }) async {
    // Build query parameters dynamically
    final queryParams = {'brcID': brcId};

    // Fetch data from API
    final response = await api.get(
      endpoint: "/setting/branch.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => BranchModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> addBranch({
    required BranchModel newBranch,
  }) async {
    final response = await api.post(
      endpoint: "/setting/branch.php",
      data: newBranch.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateBranch({
    required BranchModel newBranch,
  }) async {
    final response = await api.put(
      endpoint: "/setting/branch.php",
      data: newBranch.toMap(),
    );
    return response.data;
  }

  Future<List<BranchLimitModel>> getBranchLimits({
    int? brcCode,
    CancelToken? cancelToken,
  }) async {
    // Build query parameters dynamically
    final queryParams = {'code': brcCode};

    // Fetch data from API
    final response = await api.get(
      endpoint: "/setting/branchAuthLimit.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => BranchLimitModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> addEditBranchLimit({
    required BranchLimitModel newLimit,
  }) async {
    final response = await api.post(
      endpoint: "/setting/branchAuthLimit.php",
      data: newLimit.toMap(),
    );
    return response.data;
  }

  /// Storage ..................................................................
  Future<List<StorageModel>> getStorage({CancelToken? cancelToken}) async {
    // Fetch data from API
    final response = await api.get(
      endpoint: "/setting/storage.php",
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => StorageModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> addStorage({
    required StorageModel newStorage,
  }) async {
    final response = await api.post(
      endpoint: "/setting/storage.php",
      data: newStorage.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateStorage({
    required StorageModel newStorage,
  }) async {
    final response = await api.put(
      endpoint: "/setting/storage.php",
      data: newStorage.toMap(),
    );
    return response.data;
  }

  /// StockAvailability .................................................................
  Future<Map<String, dynamic>> addProduct({
    required ProductsModel newProduct,
  }) async {
    final response = await api.post(
      endpoint: "/inventory/product.php",
      data: newProduct.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateProduct({
    required ProductsModel newProduct,
  }) async {
    final response = await api.put(
      endpoint: "/inventory/product.php",
      data: newProduct.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteProduct({required int proId}) async {
    final response = await api.delete(
      endpoint: "/inventory/product.php",
      data: {"proID": proId},
    );
    return response.data;
  }

  Future<List<ProductsModel>> getProduct({
    int? proId,
    CancelToken? cancelToken,
  }) async {
    final queryParams = {'proID': proId};
    final response = await api.get(
      endpoint: "/inventory/product.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null) {
      return [];
    }

    // Handle single product
    if (response.data is Map<String, dynamic>) {
      if (response.data.containsKey('proID') ||
          response.data.containsKey('proId')) {
        return [ProductsModel.fromMap(response.data)];
      }
    }

    // Handle list of products
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => ProductsModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<List<ProductsStockModel>> getProductStock({
    int? proId,
    int? noStock,
    String? proName,
    CancelToken? cancelToken,
  }) async {
    final queryParams = {
      'proID': proId,
      'av': noStock ?? 0,
      "proName": proName,
    };
    // Fetch data from API
    final response = await api.get(
      endpoint: "/inventory/availableProducts.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => ProductsStockModel.fromMap(json))
          .toList();
    }
    return [];
  }

  /// Product Category .........................................................
  Future<Map<String, dynamic>> addProCategory({
    required ProCategoryModel newCategory,
  }) async {
    final response = await api.post(
      endpoint: "/setting/productCategory.php",
      data: newCategory.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateProCategory({
    required ProCategoryModel newCategory,
  }) async {
    final response = await api.put(
      endpoint: "/setting/productCategory.php",
      data: newCategory.toMap(),
    );
    return response.data;
  }

  Future<List<ProCategoryModel>> getProCategory({
    int? catId,
    CancelToken? cancelToken,
  }) async {
    final queryParams = {'pcID': catId};
    // Fetch data from API
    final response = await api.get(
      endpoint: "/setting/productCategory.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => ProCategoryModel.fromMap(json))
          .toList();
    }

    return [];
  }

  /// Orders ...................................................................
  Future<List<OrdersModel>> getOrders({
    int? orderId,
    CancelToken? cancelToken,
  }) async {
    final queryParams = {'ordID': orderId};
    final response = await api.get(
      endpoint: "/inventory/ordersView.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => OrdersModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<List<OrderByIdModel>> getOrderById({
    int? orderId,
    CancelToken? cancelToken,
  }) async {
    final queryParams = {'ordID': orderId};
    final response = await api.get(
      endpoint: "/inventory/salePurchase.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null) {
      return [];
    }

    // Your API returns a single order with records included
    if (response.data is Map<String, dynamic>) {
      final orderData = response.data as Map<String, dynamic>;
      if (orderData.containsKey('ordID') || orderData.containsKey('ordId')) {
        final order = OrderByIdModel.fromMap(orderData);
        return [order];
      }
    }

    // If it's a list (though your API doesn't seem to return this)
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => OrderByIdModel.fromMap(json))
          .toList();
    }

    return [];
  }

  ///Adjustment
  Future<List<AdjustmentModel>> allAdjustments() async {
    final response = await api.get(endpoint: "/inventory/adjustment.php");

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<AdjustmentModel>.from(
        response.data.map((x) => AdjustmentModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic>) {
      return [AdjustmentModel.fromMap(response.data)];
    }

    return [];
  }

  Future<Map<String, dynamic>> addAdjustment({
    required String usrName,
    required String xReference,
    required int xAccount,
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await api.post(
      endpoint: "/inventory/adjustment.php",
      data: {
        "usrName": usrName,
        "ordxRef": xReference,
        "account": xAccount,
        "records": records,
      },
    );
    return response.data;
  }

  Future<AdjustmentModel?> getAdjustmentById({
    int? orderId,
    CancelToken? cancelToken,
  }) async {
    final queryParams = {'ordID': orderId};
    final response = await api.get(
      endpoint: "/inventory/adjustment.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Check for error message
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // Check if response is empty
    if (response.data == null) {
      return null;
    }

    // The response is a single AdjustmentModel object, not a list
    if (response.data is Map<String, dynamic>) {
      return AdjustmentModel.fromMap(response.data);
    }

    // If somehow the response is a list, take the first item
    if (response.data is List && response.data.isNotEmpty) {
      return AdjustmentModel.fromMap(response.data[0]);
    }

    return null;
  }

  Future<Map<String, dynamic>> deleteAdjustment({
    required int orderId,
    required String usrName,
  }) async {
    final response = await api.delete(
      endpoint: "/inventory/adjustment.php",
      data: {"usrName": usrName, "ordID": orderId.toString()},
    );
    return response.data;
  }

  ///Shift Goods ...............................................................
  Future<List<GoodShiftModel>> getShifts({
    int? orderId,
    CancelToken? cancelToken,
  }) async {
    final queryParams = {'ordID': orderId};
    final response = await api.get(
      endpoint: "/inventory/goodsShifting.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null) {
      return [];
    }

    // Handle single shift detail with records
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final shift = GoodShiftModel.fromMap(data);

      // Parse records if they exist
      if (data.containsKey('records') && data['records'] is List) {
        shift.records = (data['records'] as List)
            .whereType<Map<String, dynamic>>()
            .map((record) => ShiftRecord.fromMap(record))
            .toList();
      }

      return [shift];
    }

    // Handle list of shifts
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => GoodShiftModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> addShift({
    required String usrName,
    required String account,
    required String amount,
    required List<ShiftRecord> records,
  }) async {
    final data = {
      "usrName": usrName,
      "account": account,
      "amount": amount,
      "records": records.map((r) => r.toMap()).toList(),
    };

    final response = await api.post(
      endpoint: "/inventory/goodsShifting.php",
      data: data,
    );

    return response.data is Map<String, dynamic>
        ? response.data
        : {'msg': 'Invalid response format'};
  }

  Future<Map<String, dynamic>> deleteShift({
    required int orderId,
    required String usrName,
  }) async {
    final response = await api.delete(
      endpoint: "/inventory/goodsShifting.php",
      data: {"usrName": usrName, "ordID": orderId.toString()},
    );
    return response.data;
  }

  ///Estimate ..................................................................
  Future<List<EstimateModel>> getAllEstimates({
    CancelToken? cancelToken,
  }) async {
    final response = await api.get(
      endpoint: "/inventory/estimate.php",
      cancelToken: cancelToken,
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => EstimateModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<EstimateModel?> getEstimateById({
    required int orderId,
    CancelToken? cancelToken,
  }) async {
    final queryParams = {'ordID': orderId};
    final response = await api.get(
      endpoint: "/inventory/estimate.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null) {
      return null;
    }

    if (response.data is Map<String, dynamic>) {
      return EstimateModel.fromMap(response.data);
    }

    return null;
  }

  Future<Map<String, dynamic>> addEstimate({
    required String usrName,
    required int perID,
    required String? xRef,
    required List<EstimateRecord> records,
  }) async {
    final data = {
      "usrName": usrName,
      "ordName": "Estimate",
      "ordPersonal": perID,
      "ordxRef": xRef ?? "",
      "records": records.map((r) => r.toMap()).toList(),
    };

    final response = await api.post(
      endpoint: "/inventory/estimate.php",
      data: data,
    );

    return response.data is Map<String, dynamic>
        ? response.data
        : {'msg': 'Invalid response format'};
  }

  Future<Map<String, dynamic>> updateEstimate({
    required String usrName,
    required int orderId,
    required int perID,
    required String? xRef,
    required List<EstimateRecord> records,
  }) async {
    final data = {
      "usrName": usrName,
      "ordName": "Estimate",
      "ordID": orderId,
      "ordPersonal": perID,
      "ordxRef": xRef ?? "",
      "records": records.map((r) => r.toMap()).toList(),
    };

    final response = await api.put(
      endpoint: "/inventory/estimate.php",
      data: data,
    );
    return response.data is Map<String, dynamic>
        ? response.data
        : {'msg': 'Invalid response format'};
  }

  Future<Map<String, dynamic>> deleteEstimate({
    required int orderId,
    required String usrName,
  }) async {
    final response = await api.delete(
      endpoint: "/inventory/estimate.php",
      data: {"ordID": orderId, "usrName": usrName},
    );

    return response.data is Map<String, dynamic>
        ? response.data
        : {'msg': 'Invalid response format'};
  }

  Future<Map<String, dynamic>> convertEstimateToSale({
    required String usrName,
    required int orderId,
    required int perID,
    required int account,
    required String amount,
  }) async {
    final data = {
      "usrName": usrName,
      "ordID": orderId,
      "ordPersonal": perID,
      "account": account,
      "amount": amount,
    };

    final response = await api.post(
      endpoint: "/inventory/estimateToSale.php",
      data: data,
    );

    return response.data is Map<String, dynamic>
        ? response.data
        : {'msg': 'Invalid response format'};
  }

  /// Purchase Invoice...........................................................................
  Future<Map<String, dynamic>> addPurchaseInvoice({
    required String usrName,
    required int perID,
    required String? xRef,
    required String orderName, //Purchase or Sale
    int? account,
    double? amount,
    required List<PurchaseInvoiceRecord> records,
    required List<PurExpenseRecord> expRecord,
  }) async {
    final data = {
      "usrName": usrName,
      "ordName": orderName,
      "ordPersonal": perID,
      "ordxRef": xRef ?? "",
      "oRemark": "",
      "account": account ?? 0,
      "amount": amount ?? 0.0,
      "records": records.map((r) => r.toJson()).toList(),
      "expenses": expRecord.map((r) => r.toJson()).toList(),
    };

    final response = await api.post(
      endpoint: "/inventory/salePurchase.php",
      data: data,
    );
    // Return the full response data
    return response.data is Map<String, dynamic>
        ? response.data
        : {'msg': 'Invalid response format'};
  }

  Future<Map<String, dynamic>> addSaleInvoice({
    required String usrName,
    required int perID,
    required String? xRef,
    required String orderName,
    int? account,
    double? amount,
    required List<SaleInvoiceRecord> records,
  }) async {
    final data = {
      "usrName": usrName,
      "ordName": orderName,
      "ordPersonal": perID,
      "ordxRef": xRef ?? "",
      "account": account ?? 0,
      "amount": amount ?? 0.0,
      "records": records.map((r) => r.toJson()).toList(),
    };

    final response = await api.post(
      endpoint: "/inventory/salePurchase.php",
      data: data,
    );

    return response.data is Map<String, dynamic>
        ? response.data
        : {'msg': 'Invalid response format'};
  }

  // In repositories.dart or similar
  Future<bool> updatePurchaseOrder({
    required int orderId,
    required String usrName,
    required List<Map<String, dynamic>> records,
    required Map<String, dynamic> orderData, // Add this
  }) async {
    final response = await api.put(
      endpoint: "/inventory/salePurchase.php",
      data: orderData,
    );
    final message = response.data['msg']?.toString() ?? '';
    return message.toLowerCase().contains('success') ||
        message.toLowerCase().contains('authorized');
  }

  Future<bool> deleteOrder({
    required int orderId,
    required String usrName,
    required String? ref,
    required String? ordName,
  }) async {
    final data = {
      "ordID": orderId,
      "usrName": usrName,
      "ordTrnRef": ref,
      "ordName": ordName,
    };

    final response = await api.delete(
      endpoint: "/inventory/salePurchase.php",
      data: data,
    );

    return response.data['msg'] == 'success';
  }

  Future<OrderTxnModel> fetchOrderTxn({
    required String reference,
    CancelToken? cancelToken,
  }) async {
    final response = await api.get(
      endpoint: "/inventory/spTransaction.php",
      queryParams: {'ref': reference},
      cancelToken: cancelToken,
    );

    // Convert the response data to OrderTxnModel
    return OrderTxnModel.fromMap(response.data);
  }

  /// Transaction Types ........................................................
  Future<Map<String, dynamic>> addTxnType({
    required TxnTypeModel newType,
  }) async {
    final response = await api.post(
      endpoint: "/setting/trnType.php",
      data: newType.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateTxnType({
    required TxnTypeModel newType,
  }) async {
    final response = await api.put(
      endpoint: "/setting/trnType.php",
      data: newType.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteTxnType({required String trnCode}) async {
    final response = await api.delete(
      endpoint: "/setting/trnType.php",
      data: {"trntCode": trnCode},
    );
    return response.data;
  }

  Future<List<TxnTypeModel>> getTxnTypes({
    String? trnCode,
    CancelToken? cancelToken,
  }) async {
    final queryParams = {'trntCode': trnCode};
    // Fetch data from API
    final response = await api.get(
      endpoint: "/setting/trnType.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => TxnTypeModel.fromMap(json))
          .toList();
    }

    return [];
  }

  /// User Log .................................................................
  Future<List<UserLogModel>> getUserLog({
    String? usrName,
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = {
      'usrName': usrName,
      'fromDate': fromDate,
      'toDate': toDate,
    };
    // Fetch data from API
    final response = await api.post(
      endpoint: "/reports/userLogs.php",
      data: queryParams,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => UserLogModel.fromMap(json))
          .toList();
    }

    return [];
  }

  ///Reports ...................................................................
  // Account Statement
  Future<AccountStatementModel> getAccountStatement({
    required int account,
    required String fromDate,
    required String toDate,
  }) async {
    final response = await api.post(
      endpoint: "/reports/accountStatement.php",
      data: {"account": account, "fromDate": fromDate, "toDate": toDate},
    );

    // Handle message response
    if (response.data is Map && response.data['msg'] != null) {
      throw response.data['msg'];
    }

    // Handle empty response
    if (response.data == null || response.data.isEmpty) {
      throw "No data received";
    }

    // Convert response to string and back to ensure proper typing
    final jsonString = json.encode(response.data);
    final decodedData = json.decode(jsonString) as dynamic;

    return AccountStatementModel.fromApiResponse(decodedData);
  }

  Future<GlStatementModel> getGlStatement({
    required int account,
    required String currency,
    required int branchCode,
    required String fromDate,
    required String toDate,
  }) async {
    final response = await api.post(
      endpoint: "/reports/glStatement.php",
      data: {
        "ccy": currency,
        "branch": branchCode,
        "account": account,
        "fromDate": fromDate,
        "toDate": toDate,
      },
    );

    // Handle message response
    if (response.data is Map && response.data['msg'] != null) {
      throw response.data['msg'];
    }

    // Handle empty response
    if (response.data == null || response.data.isEmpty) {
      throw "No data received";
    }

    // Convert response to string and back to ensure proper typing
    final jsonString = json.encode(response.data);
    final decodedData = json.decode(jsonString) as dynamic;

    return GlStatementModel.fromApiResponse(decodedData);
  }

  //Get Transaction Details By Ref
  Future<TxnReportByRefModel> getTransactionByRefReport({
    required String ref,
    CancelToken? cancelToken,
  }) async {
    final response = await api.get(
      endpoint: "/reports/referenceHistory.php",
      queryParams: {"ref": ref},
      cancelToken: cancelToken,
    );

    // Handle message response
    if (response.data is Map && response.data['msg'] != null) {
      throw response.data['msg'];
    }

    // Handle empty response
    if (response.data == null || response.data.isEmpty) {
      throw "No data received";
    }

    // Convert response to string and back to ensure proper typing
    final jsonString = json.encode(response.data);
    final decodedData = json.decode(jsonString) as dynamic;

    return TxnReportByRefModel.fromMap(decodedData);
  }

  /// Dashboard Statistics.....................................................
  Future<List<DailyGrossModel>> getDailyGross({
    required String from,
    required String to,
    required int startGroup,
    required int stopGroup,
  }) async {
    final response = await api.post(
      endpoint: "/reports/dailyGrossing.php",
      data: {
        "from": from,
        "to": to,
        "startGroup": startGroup,
        "stopGroup": stopGroup,
      },
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => DailyGrossModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<DashboardStatsModel> getDashboardStats({
    CancelToken? cancelToken,
  }) async {
    final response = await api.get(
      endpoint: "/reports/counts.php",
      cancelToken: cancelToken,
    );

    if (response.data is Map && response.data['msg'] != null) {
      throw response.data['msg'];
    }

    if (response.data == null || response.data.isEmpty) {
      throw "No data received";
    }

    return DashboardStatsModel.fromMap(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<ArApModel>> getArApReport({String? name, String? ccy}) async {
    final response = await api.post(
      endpoint: "/reports/stakeholderBalances.php",
      data: {"name": name, "ccy": ccy},
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => ArApModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<List<TrialBalanceModel>> getTrialBalance({
    required String date,
    int? branchCode,
  }) async {
    final response = await api.post(
      endpoint: "/reports/trialBalance.php",
      data: {"date": date, "branch": branchCode},
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => TrialBalanceModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<List<TotalDailyTxnModel>> totalDailyTxnReport({
    required String fromDate,
    required String toDate,
  }) async {
    final response = await api.post(
      endpoint: "/reports/dailyTotalTransactions.php",
      data: {"fromDate": fromDate, "toDate": toDate},
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => TotalDailyTxnModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<BalanceSheetModel> balanceSheet({int? branchCode, CancelToken? cancelToken}) async {
    final response = await api.get(
      endpoint: "/reports/balanceSheet.php",
      queryParams: {"branch": branchCode},
      cancelToken: cancelToken,
    );

    // Check if API returned a message
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If response is null
    if (response.data == null) {
      throw Exception("No data found");
    }

    // Convert the JSON to BalanceSheetModel
    if (response.data is Map<String, dynamic>) {
      return BalanceSheetModel.fromMap(response.data);
    }

    throw Exception("Unexpected response format");
  }

  Future<List<ExchangeRateReportModel>> exchangeRateReport({
    String? fromDate,
    String? toDate,
    String? fromCcy,
    String? toCcy,
  }) async {
    final response = await api.post(
      endpoint: "/reports/currencyRate.php",
      data: {
        "fromDate": fromDate,
        "toDate": toDate,
        "fromCcy": fromCcy,
        "toCcy": toCcy,
      },
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => ExchangeRateReportModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<List<UsersReportModel>> getUsersReport({
    String? usrName,
    int? status,
    int? branch,
    int? role,
  }) async {
    final response = await api.post(
      endpoint: "/reports/usersList.php",
      data: {
        "username": usrName,
        "status": status,
        "branch": branch,
        "role": role,
      },
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => UsersReportModel.fromMap(json))
          .toList();
    }

    return [];
  }

  ///Cash Balances .............................................................
  Future<CashBalancesModel> cashBalances({
    int? branchId,
    CancelToken? cancelToken,
  }) async {
    final response = await api.get(
      endpoint: "/reports/cashBalance.php",
      queryParams: {"brcID": branchId},
      cancelToken: cancelToken,
    );

    // Check if API returned a message
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If response is null
    if (response.data == null) {
      throw Exception("No data found");
    }

    // Handle the List response from API
    if (response.data is List) {
      final List dataList = response.data;
      if (dataList.isEmpty) {
        throw Exception("No cash balance data found for this branch");
      }

      // Convert the first item in the list to CashBalancesModel
      return CashBalancesModel.fromMap(dataList.first);
    }

    // Handle single Map response (fallback)
    if (response.data is Map<String, dynamic>) {
      return CashBalancesModel.fromMap(response.data);
    }

    throw Exception("Unexpected response format: ${response.data.runtimeType}");
  }

  Future<List<CashBalancesModel>> allCashBalances({
    CancelToken? cancelToken,
  }) async {
    final response = await api.get(
      endpoint: "/reports/cashBalance.php",
      cancelToken: cancelToken,
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null) {
      throw Exception("No data found");
    }

    // Parse as list
    if (response.data is List) {
      return List<CashBalancesModel>.from(
        response.data.map((x) => CashBalancesModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic>) {
      return [CashBalancesModel.fromMap(response.data)];
    }

    throw Exception("Unexpected response format");
  }

  Future<List<TransactionReportModel>> transactionReport({
    String? fromDate,
    String? toDate,
    String? txnType,
    int? status,
    String? maker,
    String? checker,
    String? currency,
  }) async {
    final response = await api.post(
      endpoint: "/reports/transactionsReport.php",
      data: {
        "fromDate": fromDate,
        "toDate": toDate,
        "type": txnType,
        "status": status,
        "maker": maker,
        "checker": checker,
        "currency": currency,
      },
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<TransactionReportModel>.from(
        response.data.map((x) => TransactionReportModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic>) {
      return [TransactionReportModel.fromMap(response.data)];
    }

    return [];
  }

  Future<List<AllBalancesModel>> allBalances({
    int? catId,
    CancelToken? cancelToken,
  }) async {
    final response = await api.get(
      endpoint: "/reports/allBalances.php",
      queryParams: {"cat": catId},
      cancelToken: cancelToken,
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<AllBalancesModel>.from(
        response.data.map((x) => AllBalancesModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic>) {
      return [AllBalancesModel.fromMap(response.data)];
    }

    return [];
  }

  Future<List<ProductReportModel>> stockAvailabilityReport({
    int? productId,
    int? storageId,
    int? isNoStock,
  }) async {
    final response = await api.post(
      endpoint: "/reports/stockAvailability.php",
      data: {
        "product": productId,
        "storage": storageId,
        "availability": isNoStock,
      },
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<ProductReportModel>.from(
        response.data.map((x) => ProductReportModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic>) {
      return [ProductReportModel.fromMap(response.data)];
    }

    return [];
  }

  Future<List<OrderReportModel>> ordersReport({
    String? fromDate,
    String? toDate,
    int? ordID,
    int? customerId,
    int? branchId,
    String? orderName,
  }) async {
    final response = await api.post(
      endpoint: "/reports/allOrders.php",
      data: {
        "fromDate": fromDate,
        "toDate": toDate,
        "orderName": orderName,
        "ordID": ordID,
        "customer": customerId,
        "branch": branchId,
      },
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<OrderReportModel>.from(
        response.data.map((x) => OrderReportModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic>) {
      return [OrderReportModel.fromMap(response.data)];
    }

    return [];
  }

  Future<List<StockRecordModel>> stockRecord({
    String? fromDate,
    String? toDate,
    int? proId,
    int? storageId,
    int? partyId,
    String? inOut,
  }) async {
    final response = await api.post(
      endpoint: "/reports/runningStock.php",
      data: {
        "fromDate": fromDate,
        "toDate": toDate,
        "proID": proId,
        "stgID": storageId,
        "perID": partyId,
        "io": inOut,
      },
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<StockRecordModel>.from(
        response.data.map((x) => StockRecordModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic>) {
      return [StockRecordModel.fromMap(response.data)];
    }

    return [];
  }

  ///Reminder ..................................................................
  Future<List<ReminderModel>> getAlertReminders({int? alert}) async {
    final response = await api.get(
      endpoint: "/finance/reminders.php",
      queryParams: {"alerts": alert},
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<ReminderModel>.from(
        response.data.map((x) => ReminderModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic>) {
      return [ReminderModel.fromMap(response.data)];
    }

    return [];
  }
  Future<Map<String, dynamic>> addNewReminder({required ReminderModel newData,}) async {
    final response = await api.post(
      endpoint: "/finance/reminders.php",
      data: newData.toMap(),
    );

    return response.data;
  }
  Future<Map<String, dynamic>> updateReminder({required ReminderModel newData,}) async {
    final response = await api.put(
      endpoint: "/finance/reminders.php",
      data: newData.toMap(),
    );
    return response.data;
  }

  ///Back up ...................................................................
  Future<Directory> _getBackupBaseDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
      return (await getExternalStorageDirectory())!;
    }

    if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    }

    // Windows / macOS / Linux
    return await getApplicationDocumentsDirectory();
  }
  Future<File> downloadBackup() async {
    Directory baseDir;

    // 🔹 ANDROID
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }

      final androidDownload = Directory('/storage/emulated/0/Download');
      if (await androidDownload.exists()) {
        baseDir = androidDownload;
      } else {
        baseDir = (await getExternalStorageDirectory())!;
      }
    }
    // 🔹 iOS
    else if (Platform.isIOS) {
      baseDir = await getApplicationDocumentsDirectory();
    }
    // 🔹 Windows / macOS / Linux
    else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final backupDir = Directory('${baseDir.path}/ZaitoonBackups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final now = DateTime.now();
    final formattedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day
        .toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(
        2, '0')}';

    final filePath = '${backupDir.path}/zaitoon_backup_$formattedDate.db';

    await api.downloadFile(
      endpoint: "/setting/backupLocally.php",
      savePath: filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          // progress callback
        }
      },
    );

    return File(filePath);
  }
  Future<List<FileSystemEntity>> getBackupFiles() async {
    final baseDir = await _getBackupBaseDirectory();
    final backupDir = Directory('${baseDir.path}/ZaitoonBackups');
    if (!await backupDir.exists()) return [];
    final files = backupDir.listSync().whereType<File>().toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }
  Future<void> deleteBackup(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  ///Attendance ...............................................................
  Future<List<AttendanceRecord>> getAllAttendance({String? date}) async {
    final response = await api.get(
      endpoint: "/HR/attendence.php",
      queryParams: {"date": date ?? DateTime.now().toFormattedDate()},
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      // If no records found, return empty list
      if (response.data['msg'] == 'failed') {
        return [];
      }
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<AttendanceRecord>.from(
        response.data.map((x) => AttendanceRecord.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic> && response.data.isNotEmpty) {
      return [AttendanceRecord.fromMap(response.data)];
    }

    return [];
  }
  Future<Map<String, dynamic>> addNewAttendance({required String usrName, required String checkIn, required String checkOut, required String date,}) async {
    final response = await api.post(
      endpoint: "/HR/attendence.php",
      data: {
        "usrName": usrName,
        "emaDate": date,
        "emaCheckedIn": checkIn,
        "empCheckedOut": checkOut,
      },
    );
    return response.data;
  }
  Future<Map<String, dynamic>> updateAttendance({required AttendanceModel newData,}) async {
    final response = await api.put(
      endpoint: "/HR/attendence.php",
      data: newData.toMap(),
    );
    return response.data;
  }
  Future<List<AttendanceReportModel>> attendanceReport({String? fromDate, String? toDate, int? empId, int? status, CancelToken? cancelToken,}) async {
    final queryParams = {
      "fromDate": fromDate,
      "toDate": toDate,
      "empID": empId,
      "status": status,
    };

    // Fetch data from API
    final response = await api.post(
      endpoint: "/reports/attendenceReport.php",
      data: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => AttendanceReportModel.fromMap(json))
          .toList();
    }
    return [];
  }

  ///Payroll ...................................................................
  Future<List<PayrollModel>> getPayroll({String? date}) async {
    final response = await api.get(
      endpoint: "/finance/payroll.php",
      queryParams: {"date": date},
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      // If no records found, return empty list
      if (response.data['msg'] == 'failed') {
        return [];
      }
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<PayrollModel>.from(
        response.data.map((x) => PayrollModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic> && response.data.isNotEmpty) {
      return [PayrollModel.fromMap(response.data)];
    }

    return [];
  }
  Future<Map<String, dynamic>> postPayroll({required String usrName, required List<PayrollModel> records,}) async {
    final response = await api.post(
      endpoint: "/finance/payroll.php",
      data: {
        "usrName": usrName,
        "records": records.map((r) => r.toMap()).toList(),
      },
    );
    return response.data;
  }

  ///Forgot Password ...........................................................
  Future<Map<String, dynamic>> requestResetPassword({required String identity,}) async {
    final response = await api.post(
      endpoint: "/HR/resetPassword.php",
      data: {"identity": identity},
    );
    return response.data;
  }
  Future<Map<String, dynamic>> verifyOtp({required String otp,}) async {
    final response = await api.get(
      endpoint: "/HR/resetPassword.php",
      queryParams: {"otp": otp},
    );
    return response.data;
  }
  Future<Map<String, dynamic>> resetPasswordMethod({required String usrName, required String usrPass, required int? otp,}) async {
    final response = await api.put(
      endpoint: "/HR/resetPassword.php",
      data: {"usrName": usrName, "usrPass": usrPass, "otp": otp},
    );
    return response.data;
  }

  /// Projects .................................................................
  Future<List<ProjectsModel>> getProjects({int? prjId}) async {
    final response = await api.get(
      endpoint: "/project/project.php",
      queryParams: {"prjID": prjId},
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      // If no records found, return empty list
      if (response.data['msg'] == 'failed') {
        return [];
      }
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<ProjectsModel>.from(
        response.data.map((x) => ProjectsModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic> && response.data.isNotEmpty) {
      return [ProjectsModel.fromMap(response.data)];
    }

    return [];
  }
  Future<Map<String, dynamic>> addProject({required ProjectsModel newData,}) async {
    final response = await api.post(
      endpoint: "/project/project.php",
      data: newData.toMap(),
    );
    return response.data;
  }
  Future<Map<String, dynamic>> updateProject({required ProjectsModel newData}) async {
    final response = await api.put(
      endpoint: "/project/project.php",
      data: newData.toMap(),
    );
    return response.data;
  }
  Future<Map<String, dynamic>> deleteProject({required int projectId, required String usrName}) async {
    final response = await api.delete(
      endpoint: "/project/project.php",
      data: {
        "prjID": projectId,
        "usrName": usrName,
      },
    );
    return response.data;
  }

  ///Project Services ..........................................................
  Future<List<ServicesModel>> getServices({String? search}) async {
    final response = await api.get(
      endpoint: "/project/projectServices.php",
      queryParams: {"search": search},
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      // If no records found, return empty list
      if (response.data['msg'] == 'failed') {
        return [];
      }
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<ServicesModel>.from(
        response.data.map((x) => ServicesModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic> && response.data.isNotEmpty) {
      return [ServicesModel.fromMap(response.data)];
    }

    return [];
  }
  Future<Map<String, dynamic>> addService({required ServicesModel newData,}) async {
    final response = await api.post(
      endpoint: "/project/projectServices.php",
      data: newData.toMap(),
    );
    return response.data;
  }
  Future<Map<String, dynamic>> updateService({required ServicesModel newData}) async {
    final response = await api.put(
      endpoint: "/project/projectServices.php",
      data: newData.toMap(),
    );
    return response.data;
  }
  Future<Map<String, dynamic>> deleteService({required int servicesId, required String usrName}) async {
    final response = await api.delete(
      endpoint: "/project/projectServices.php",
      data: {
        "srvID": servicesId,
        "usrName": usrName
      },
    );
    return response.data;
  }

  ///Project Services ...........................................................
  Future<List<ProjectServicesModel>> getProjectServices({int? projectId}) async {
    final response = await api.get(
      endpoint: "/project/projectDetails.php",
      queryParams: {"prjID": projectId},
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      // If no records found, return empty list
      if (response.data['msg'] == 'failed') {
        return [];
      }
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<ProjectServicesModel>.from(
        response.data.map((x) => ProjectServicesModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic> && response.data.isNotEmpty) {
      return [ProjectServicesModel.fromMap(response.data)];
    }

    return [];
  }
  Future<Map<String, dynamic>> addProjectServices({required ProjectServicesModel newData}) async {
    final response = await api.post(
      endpoint: "/project/projectDetails.php",
      data: newData.toMap(),
    );
    return response.data;
  }
  Future<Map<String, dynamic>> updateProjectServices({required ProjectServicesModel newData}) async {
    final response = await api.put(
      endpoint: "/project/projectDetails.php",
      data: newData.toMap(),
    );
    return response.data;
  }
  Future<Map<String, dynamic>> deleteProjectServices({required int pjdID, required String usrName}) async {
    final response = await api.delete(
      endpoint: "/project/projectDetails.php",
      data: {
        "pjdID": pjdID,
        "usrName": usrName
      },
    );
    return response.data;
  }

  ///Project Income & Expenses
  Future<ProjectInOutModel?> getProjectIncomeExpense({int? projectId}) async {
    final response = await api.get(
      endpoint: "/project/projectPayments.php",
      queryParams: {"prjID": projectId},
    );

    // Check if response has data
    if (response.data == null) {
      return null;
    }

    // Check for error message
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      if (response.data['msg'] == 'failed') {
        return null; // No records found
      }
      throw Exception(response.data['msg']);
    }

    // Parse the response as a single ProjectInOutModel
    if (response.data is Map<String, dynamic>) {
      return ProjectInOutModel.fromMap(response.data);
    }

    return null;
  }
  Future<Map<String, dynamic>> addProjectIncomeExpense({required ProjectInOutModel newData}) async {
    final response = await api.post(
      endpoint: "/project/projectPayments.php",
      data: newData.toMap(),
    );
    return response.data;
  }
  Future<Map<String, dynamic>> updateProjectIncomeExpense({required ProjectInOutModel newData}) async {
    final response = await api.put(
      endpoint: "/project/projectPayments.php",
      data: newData.toMap(),
    );
    return response.data;
  }
  Future<Map<String, dynamic>> deleteProjectIncomeExpense({required String ref, required String usrName}) async {
    final response = await api.delete(
      endpoint: "/project/projectPayments.php",
      data: {
        "prpTrnRef": ref,
        "usrName": usrName
      },
    );
    return response.data;
  }

  ///Accounts Report ...........................................................
  Future<List<AccountsReportModel>?> getAccountsReport({String? search, String? currency, double? limit, int? status}) async {
    final response = await api.post(
        endpoint: "/reports/stakeholderAccounts.php",
        data: {
          "accNameSearch": search,
          "currency": currency,
          "limit": limit,
          "status": status
        }
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      // If no records found, return empty list
      if (response.data['msg'] == 'failed') {
        return [];
      }
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<AccountsReportModel>.from(
        response.data.map((x) => AccountsReportModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic> && response.data.isNotEmpty) {
      return [AccountsReportModel.fromMap(response.data)];
    }

    return [];
  }

  ///Project By ID ..............................................................
  Future<ProjectByIdModel> getProjectById({required int prjId, CancelToken? cancelToken}) async {
    final queryParams = {'prjID': prjId};
    final response = await api.get(
      endpoint: '/reports/projectDetails.php',
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    final data = response.data;

    // Check for error messages
    if (data is Map<String, dynamic> && data['msg'] != null) {
      final msg = data['msg'];
      if (msg == 'failed' || msg == 'error') {
        throw Exception('Failed to load shipping details');
      }
    }

    // Handle different response formats
    if (data is Map<String, dynamic>) {
      // Direct object response (your API format for single shipping)
      return ProjectByIdModel.fromMap(data);
    } else if (data is List) {
      // List response - take first item
      if (data.isEmpty) {
        throw Exception("No shipping found with ID: $prjId");
      }

      final firstItem = data.first;
      if (firstItem is Map<String, dynamic>) {
        return ProjectByIdModel.fromMap(firstItem);
      }
      throw Exception("Invalid data format in list response");
    }

    throw Exception("Invalid API response format");
  }
  Future<ProjectTxnModel> getProjectTxn({required String ref, CancelToken? cancelToken}) async {
    final queryParams = {'ref': ref};
    final response = await api.get(
      endpoint: '/project/projectTransaction.php',
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    final data = response.data;

    // Check for error messages
    if (data is Map<String, dynamic> && data['msg'] != null) {
      final msg = data['msg'];
      if (msg == 'failed' || msg == 'error') {
        throw Exception('Failed to load shipping details');
      }
    }

    // Handle different response formats
    if (data is Map<String, dynamic>) {
      // Direct object response (your API format for single shipping)
      return ProjectTxnModel.fromMap(data);
    } else if (data is List) {
      // List response - take first item
      if (data.isEmpty) {
        throw Exception("No shipping found with ID: $ref");
      }

      final firstItem = data.first;
      if (firstItem is Map<String, dynamic>) {
        return ProjectTxnModel.fromMap(firstItem);
      }
      throw Exception("Invalid data format in list response");
    }

    throw Exception("Invalid API response format");
  }

  ///Subscription ..............................................................
  Future<List<SubscriptionModel>> getSubscriptions() async {

    // Fetch data from API
    final response = await api.get(
      endpoint: "/setting/subscription.php",

    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => SubscriptionModel.fromMap(json))
          .toList();
    }

    return [];
  }
  Future<Map<String, dynamic>> addSubscription({required String oldKey, required String newKey, required String expireDate}) async {
    final response = await api.post(
        endpoint: "/setting/subscription.php",
        data: {
          "oldKey": oldKey,
          "newKey": newKey,
          "subExpireDate": expireDate,
        }
    );
    return response.data;
  }

  ///Stakeholders Report........................................................
  Future<List<IndReportModel>> getStakeholdersReport({String? search, String? dob, String? phone, String? gender}) async {
    final response = await api.post(
      endpoint: "/reports/allPersonal.php",
      data: {
        "flNameSearch": search,
        "dob": dob,
        "phone": phone,
        "gender": gender
      },
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      // If no records found, return empty list
      if (response.data['msg'] == 'failed') {
        return [];
      }
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<IndReportModel>.from(
        response.data.map((x) => IndReportModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic> && response.data.isNotEmpty) {
      return [IndReportModel.fromMap(response.data)];
    }

    return [];
  }

  Future<UsrProfileModel> getProfile({
    required String usrName,
    CancelToken? cancelToken,
  }) async {
    final response = await api.get(
      endpoint: '/setting/personalProfile.php',
      queryParams: {'user': usrName},
      cancelToken: cancelToken,
    );

    return UsrProfileModel.fromMap(response.data);
  }

}

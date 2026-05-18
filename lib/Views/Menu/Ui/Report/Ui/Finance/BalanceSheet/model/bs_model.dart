import 'dart:convert';

BalanceSheetModel balanceSheetModelFromMap(String str) => BalanceSheetModel.fromMap(json.decode(str));

String balanceSheetModelToMap(BalanceSheetModel data) => json.encode(data.toMap());

class BalanceSheetModel {
  final Assets? assets;
  final Liability? liability;

  BalanceSheetModel({
    this.assets,
    this.liability,
  });

  BalanceSheetModel copyWith({
    Assets? assets,
    Liability? liability,
  }) =>
      BalanceSheetModel(
        assets: assets ?? this.assets,
        liability: liability ?? this.liability,
      );

  factory BalanceSheetModel.fromMap(Map<String, dynamic> json) => BalanceSheetModel(
    assets: json["Assets"] == null ? null : Assets.fromMap(json["Assets"]),
    liability: json["Liability"] == null ? null : Liability.fromMap(json["Liability"]),
  );

  Map<String, dynamic> toMap() => {
    "Assets": assets?.toMap(),
    "Liability": liability?.toMap(),
  };
}

class Assets {
  final List<AssetItem>? currentAsset;
  final List<AssetItem>? fixedAsset;
  final List<AssetItem>? intangibleAsset;

  Assets({
    this.currentAsset,
    this.fixedAsset,
    this.intangibleAsset,
  });

  Assets copyWith({
    List<AssetItem>? currentAsset,
    List<AssetItem>? fixedAsset,
    List<AssetItem>? intangibleAsset,
  }) =>
      Assets(
        currentAsset: currentAsset ?? this.currentAsset,
        fixedAsset: fixedAsset ?? this.fixedAsset,
        intangibleAsset: intangibleAsset ?? this.intangibleAsset,
      );

  factory Assets.fromMap(Map<String, dynamic> json) => Assets(
    currentAsset: json["Current Asset"] == null ? [] : List<AssetItem>.from(json["Current Asset"]!.map((x) => AssetItem.fromMap(x))),
    fixedAsset: json["Fixed Asset"] == null ? [] : List<AssetItem>.from(json["Fixed Asset"]!.map((x) => AssetItem.fromMap(x))),
    intangibleAsset: json["Intangible Asset"] == null ? [] : List<AssetItem>.from(json["Intangible Asset"]!.map((x) => AssetItem.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "Current Asset": currentAsset == null ? [] : List<dynamic>.from(currentAsset!.map((x) => x.toMap())),
    "Fixed Asset": fixedAsset == null ? [] : List<dynamic>.from(fixedAsset!.map((x) => x.toMap())),
    "Intangible Asset": intangibleAsset == null ? [] : List<dynamic>.from(intangibleAsset!.map((x) => x.toMap())),
  };
}

class Liability {
  final List<AssetItem>? currentLiability;
  final List<dynamic>? longTermLiability;
  final List<AssetItem>? ownersEquity;
  final List<dynamic>? shareholders;
  final List<AssetItem>? stakeholders;
  final List<AssetItem>? netProfit;

  Liability({
    this.currentLiability,
    this.longTermLiability,
    this.ownersEquity,
    this.shareholders,
    this.stakeholders,
    this.netProfit,
  });

  Liability copyWith({
    List<AssetItem>? currentLiability,
    List<dynamic>? longTermLiability,
    List<AssetItem>? ownersEquity,
    List<dynamic>? shareholders,
    List<AssetItem>? stakeholders,
    List<AssetItem>? netProfit,
  }) =>
      Liability(
        currentLiability: currentLiability ?? this.currentLiability,
        longTermLiability: longTermLiability ?? this.longTermLiability,
        ownersEquity: ownersEquity ?? this.ownersEquity,
        shareholders: shareholders ?? this.shareholders,
        stakeholders: stakeholders ?? this.stakeholders,
        netProfit: netProfit ?? this.netProfit,
      );

  factory Liability.fromMap(Map<String, dynamic> json) => Liability(
    currentLiability: json["Current Liability"] == null ? [] : List<AssetItem>.from(json["Current Liability"]!.map((x) => AssetItem.fromMap(x))),
    longTermLiability: json["Long-Term Liability"] == null ? [] : List<dynamic>.from(json["Long-Term Liability"]!.map((x) => x)),
    ownersEquity: json["Owner’s Equity"] == null ? [] : List<AssetItem>.from(json["Owner’s Equity"]!.map((x) => AssetItem.fromMap(x))),
    shareholders: json["Shareholders"] == null ? [] : List<dynamic>.from(json["Shareholders"]!.map((x) => x)),
    stakeholders: json["Stakeholders"] == null ? [] : List<AssetItem>.from(json["Stakeholders"]!.map((x) => AssetItem.fromMap(x))),
    netProfit: json["Net Profit"] == null ? [] : List<AssetItem>.from(json["Net Profit"]!.map((x) => AssetItem.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "Current Liability": currentLiability == null ? [] : List<dynamic>.from(currentLiability!.map((x) => x.toMap())),
    "Long-Term Liability": longTermLiability == null ? [] : List<dynamic>.from(longTermLiability!.map((x) => x)),
    "Owner’s Equity": ownersEquity == null ? [] : List<dynamic>.from(ownersEquity!.map((x) => x.toMap())),
    "Shareholders": shareholders == null ? [] : List<dynamic>.from(shareholders!.map((x) => x)),
    "Stakeholders": stakeholders == null ? [] : List<dynamic>.from(stakeholders!.map((x) => x.toMap())),
    "Net Profit": netProfit == null ? [] : List<dynamic>.from(netProfit!.map((x) => x.toMap())),
  };
}

class AssetItem {
  final String? accName;
  final dynamic trdAccount;
  final String? acgName;
  final String? lastYear;
  final String? currentYear;

  AssetItem({
    this.accName,
    this.trdAccount,
    this.acgName,
    this.lastYear,
    this.currentYear,
  });

  AssetItem copyWith({
    String? accName,
    dynamic trdAccount,
    String? acgName,
    String? lastYear,
    String? currentYear,
  }) =>
      AssetItem(
        accName: accName ?? this.accName,
        trdAccount: trdAccount ?? this.trdAccount,
        acgName: acgName ?? this.acgName,
        lastYear: lastYear ?? this.lastYear,
        currentYear: currentYear ?? this.currentYear,
      );

  factory AssetItem.fromMap(Map<String, dynamic> json) => AssetItem(
    accName: json["accName"],
    trdAccount: json["trdAccount"],
    acgName: json["acgName"],
    lastYear: json["last_year"],
    currentYear: json["current_year"],
  );

  Map<String, dynamic> toMap() => {
    "accName": accName,
    "trdAccount": trdAccount,
    "acgName": acgName,
    "last_year": lastYear,
    "current_year": currentYear,
  };
}
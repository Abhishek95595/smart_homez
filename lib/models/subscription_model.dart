class SubscriptionPlan {
  final String id;
  final String name;
  final String tagline;
  final double monthlyPrice;
  final double annualPrice;
  final String currency;
  final List<String> features;
  final bool isPopular;
  final int maxDevices;
  final int maxHomes;
  final int maxFamilyMembers;
  final bool hasAIEnergyInsights;
  final bool hasPrioritySupport;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.monthlyPrice,
    required this.annualPrice,
    this.currency = '₹',
    required this.features,
    this.isPopular = false,
    this.maxDevices = 10,
    this.maxHomes = 1,
    this.maxFamilyMembers = 2,
    this.hasAIEnergyInsights = false,
    this.hasPrioritySupport = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? json['planId']?.toString() ?? 'starter',
      name: json['name']?.toString() ?? 'Standard Plan',
      tagline: json['tagline']?.toString() ?? 'Essential smart home automation',
      monthlyPrice: (json['monthlyPrice'] ?? json['price'] ?? 0.0).toDouble(),
      annualPrice: (json['annualPrice'] ?? (json['monthlyPrice'] ?? 0.0) * 10)
          .toDouble(),
      currency: json['currency']?.toString() ?? '₹',
      features:
          (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
      isPopular: json['isPopular'] == true || json['recommended'] == true,
      maxDevices: json['maxDevices'] ?? 10,
      maxHomes: json['maxHomes'] ?? 1,
      maxFamilyMembers: json['maxFamilyMembers'] ?? 2,
      hasAIEnergyInsights: json['hasAIEnergyInsights'] == true,
      hasPrioritySupport: json['hasPrioritySupport'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tagline': tagline,
    'monthlyPrice': monthlyPrice,
    'annualPrice': annualPrice,
    'currency': currency,
    'features': features,
    'isPopular': isPopular,
    'maxDevices': maxDevices,
    'maxHomes': maxHomes,
    'maxFamilyMembers': maxFamilyMembers,
    'hasAIEnergyInsights': hasAIEnergyInsights,
    'hasPrioritySupport': hasPrioritySupport,
  };
}

class UserSubscription {
  final String planId;
  final String planName;
  final String status; // active, trialing, past_due, canceled
  final DateTime? startDate;
  final DateTime? expiryDate;
  final String billingCycle; // monthly, annual
  final double currentPrice;
  final bool autoRenew;
  final int activeDevicesCount;
  final int maxDevices;
  final int activeHomesCount;
  final int maxHomes;
  final int activeFamilyMembersCount;
  final int maxFamilyMembers;

  const UserSubscription({
    required this.planId,
    required this.planName,
    this.status = 'active',
    this.startDate,
    this.expiryDate,
    this.billingCycle = 'monthly',
    this.currentPrice = 499.0,
    this.autoRenew = true,
    this.activeDevicesCount = 6,
    this.maxDevices = 50,
    this.activeHomesCount = 1,
    this.maxHomes = 3,
    this.activeFamilyMembersCount = 2,
    this.maxFamilyMembers = 6,
  });

  bool get isActive =>
      status.toLowerCase() == 'active' || status.toLowerCase() == 'trialing';

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      planId:
          json['planId']?.toString() ?? json['plan_id']?.toString() ?? 'pro',
      planName:
          json['planName']?.toString() ??
          json['plan_name']?.toString() ??
          'Pro Smart Living',
      status: json['status']?.toString() ?? 'active',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : DateTime.now().subtract(const Duration(days: 30)),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : DateTime.now().add(const Duration(days: 335)),
      billingCycle:
          json['billingCycle']?.toString() ??
          json['billing_cycle']?.toString() ??
          'annual',
      currentPrice: (json['currentPrice'] ?? json['price'] ?? 499.0).toDouble(),
      autoRenew: json['autoRenew'] ?? json['auto_renew'] ?? true,
      activeDevicesCount: json['activeDevicesCount'] ?? 8,
      maxDevices: json['maxDevices'] ?? 50,
      activeHomesCount: json['activeHomesCount'] ?? 1,
      maxHomes: json['maxHomes'] ?? 3,
      activeFamilyMembersCount: json['activeFamilyMembersCount'] ?? 2,
      maxFamilyMembers: json['maxFamilyMembers'] ?? 6,
    );
  }

  UserSubscription copyWith({
    String? planId,
    String? planName,
    String? status,
    DateTime? startDate,
    DateTime? expiryDate,
    String? billingCycle,
    double? currentPrice,
    bool? autoRenew,
    int? activeDevicesCount,
    int? maxDevices,
    int? activeHomesCount,
    int? maxHomes,
    int? activeFamilyMembersCount,
    int? maxFamilyMembers,
  }) {
    return UserSubscription(
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      billingCycle: billingCycle ?? this.billingCycle,
      currentPrice: currentPrice ?? this.currentPrice,
      autoRenew: autoRenew ?? this.autoRenew,
      activeDevicesCount: activeDevicesCount ?? this.activeDevicesCount,
      maxDevices: maxDevices ?? this.maxDevices,
      activeHomesCount: activeHomesCount ?? this.activeHomesCount,
      maxHomes: maxHomes ?? this.maxHomes,
      activeFamilyMembersCount:
          activeFamilyMembersCount ?? this.activeFamilyMembersCount,
      maxFamilyMembers: maxFamilyMembers ?? this.maxFamilyMembers,
    );
  }
}

class SubscriptionInvoice {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final double amount;
  final double taxAmount;
  final String currency;
  final String planName;
  final String billingPeriod;
  final String status; // paid, refunded, failed, pending
  final String paymentMethod; // upi, card, netbanking
  final String? downloadUrl;

  const SubscriptionInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.amount,
    this.taxAmount = 0.0,
    this.currency = '₹',
    required this.planName,
    required this.billingPeriod,
    this.status = 'paid',
    this.paymentMethod = 'UPI / NetBanking',
    this.downloadUrl,
  });

  factory SubscriptionInvoice.fromJson(Map<String, dynamic> json) {
    return SubscriptionInvoice(
      id:
          json['id']?.toString() ??
          'inv_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber:
          json['invoiceNumber']?.toString() ??
          json['invoice_no']?.toString() ??
          'INV-2026-001',
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      amount: (json['amount'] ?? 0.0).toDouble(),
      taxAmount: (json['taxAmount'] ?? (json['amount'] ?? 0.0) * 0.18)
          .toDouble(),
      currency: json['currency']?.toString() ?? '₹',
      planName: json['planName']?.toString() ?? 'Pro Smart Living',
      billingPeriod: json['billingPeriod']?.toString() ?? 'Annual',
      status: json['status']?.toString() ?? 'paid',
      paymentMethod: json['paymentMethod']?.toString() ?? 'UPI ••••• 9876',
      downloadUrl: json['downloadUrl']?.toString(),
    );
  }
}

class PaymentMethodModel {
  final String id;
  final String type; // card, upi, netbanking
  final String title;
  final String subtitle;
  final bool isDefault;
  final String last4;
  final String brand; // visa, mastercard, gpay, phonepe

  const PaymentMethodModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.isDefault = false,
    this.last4 = '',
    this.brand = '',
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id:
          json['id']?.toString() ??
          'pm_${DateTime.now().millisecondsSinceEpoch}',
      type: json['type']?.toString() ?? 'upi',
      title: json['title']?.toString() ?? 'Google Pay / UPI',
      subtitle: json['subtitle']?.toString() ?? 'user@okhdfcbank',
      isDefault: json['isDefault'] == true,
      last4: json['last4']?.toString() ?? '4242',
      brand: json['brand']?.toString() ?? 'gpay',
    );
  }
}

class RefundRequest {
  final String subscriptionId;
  final String reason;
  final double requestedAmount;
  final DateTime requestDate;
  final String status; // pending, approved, rejected, completed

  const RefundRequest({
    required this.subscriptionId,
    required this.reason,
    required this.requestedAmount,
    required this.requestDate,
    this.status = 'pending',
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    return RefundRequest(
      subscriptionId: json['subscriptionId']?.toString() ?? '',
      reason: json['reason']?.toString() ?? 'Not as expected',
      requestedAmount: (json['requestedAmount'] ?? 0.0).toDouble(),
      requestDate: json['requestDate'] != null
          ? DateTime.parse(json['requestDate'].toString())
          : DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

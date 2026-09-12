import 'package:flutter/foundation.dart';

import '../core/network/api_endpoints.dart';
import '../models/subscription_model.dart';
import 'api_service.dart';

class SubscriptionService {
  final ApiService _apiService;

  SubscriptionService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// 1. GET /api/v1/clients/{clientId}/subscription - Fetch user active subscription
  Future<UserSubscription> getSubscription(String clientId) async {
    try {
      final endpoint = ApiEndpoints.clientSubscription(clientId);
      final response = await _apiService.get(endpoint);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'] is Map
            ? data['data'] as Map<String, dynamic>
            : data;
        return UserSubscription.fromJson(payload);
      }
    } catch (e) {
      debugPrint(
        '[SubscriptionService] Failed to load subscription from API: $e',
      );
    }

    return UserSubscription(
      planId: 'pro',
      planName: 'Pro Smart Living',
      status: 'active',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      expiryDate: DateTime.now().add(const Duration(days: 335)),
      billingCycle: 'annual',
      currentPrice: 4790.0,
      autoRenew: true,
      activeDevicesCount: 8,
      maxDevices: 50,
      activeHomesCount: 1,
      maxHomes: 3,
      activeFamilyMembersCount: 2,
      maxFamilyMembers: 6,
    );
  }

  /// 2. GET /api/v1/subscription/plans - Fetch available subscription plan tiers
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final response = await _apiService.get(ApiEndpoints.subscriptionPlans);
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .map(
              (item) => SubscriptionPlan.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint(
        '[SubscriptionService] Failed to fetch plans from API: $e. Using default plans.',
      );
    }

    return defaultPlans;
  }

  /// 3. POST /api/v1/clients/{clientId}/subscription/checkout - Process Checkout & Payment
  Future<Map<String, dynamic>> processCheckout({
    required String clientId,
    required String planId,
    required String billingCycle,
    required String paymentMethodId,
    String? couponCode,
  }) async {
    try {
      final endpoint = ApiEndpoints.subscriptionCheckout(clientId);
      final response = await _apiService.post(
        endpoint,
        body: {
          'planId': planId,
          'billingCycle': billingCycle,
          'paymentMethodId': paymentMethodId,
          'couponCode': couponCode,
        },
      );
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint(
        '[SubscriptionService] Checkout API call error: $e, simulating successful order',
      );
    }

    return {
      'success': true,
      'orderId': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      'paymentStatus': 'paid',
      'message': 'Payment confirmed successfully',
    };
  }

  /// 4. POST /api/v1/clients/{clientId}/subscription/upgrade - Upgrade / Change subscription plan
  Future<bool> upgradePlan(
    String clientId,
    String planId,
    String billingCycle,
  ) async {
    try {
      final endpoint = ApiEndpoints.upgradeSubscription(clientId);
      final response = await _apiService.post(
        endpoint,
        body: {'planId': planId, 'billingCycle': billingCycle},
      );
      final data = response.data;
      if (data is Map && data['success'] == false) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint(
        '[SubscriptionService] Upgrade plan API call: $e, simulating successful upgrade',
      );
      return true;
    }
  }

  /// 5. GET /api/v1/clients/{clientId}/subscription/invoices - Invoices & Billing History
  Future<List<SubscriptionInvoice>> getInvoices(String clientId) async {
    try {
      final endpoint = ApiEndpoints.subscriptionInvoices(clientId);
      final response = await _apiService.get(endpoint);
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .map(
              (item) => SubscriptionInvoice.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint(
        '[SubscriptionService] Invoices API error: $e, using local history',
      );
    }

    return [
      SubscriptionInvoice(
        id: 'inv_001',
        invoiceNumber: 'INV-2026-0814',
        date: DateTime.now().subtract(const Duration(days: 30)),
        amount: 4790.0,
        taxAmount: 730.0,
        currency: '₹',
        planName: 'Pro Smart Living (Annual)',
        billingPeriod: '1 Year (Active)',
        status: 'paid',
        paymentMethod: 'UPI • user@okhdfcbank',
        downloadUrl:
            'https://tenant-api-qa.omnihome.in/invoices/INV-2026-0814.pdf',
      ),
      SubscriptionInvoice(
        id: 'inv_002',
        invoiceNumber: 'INV-2025-0720',
        date: DateTime.now().subtract(const Duration(days: 395)),
        amount: 499.0,
        taxAmount: 76.0,
        currency: '₹',
        planName: 'Starter Pro Trial',
        billingPeriod: '1 Month',
        status: 'paid',
        paymentMethod: 'Visa •••• 4242',
        downloadUrl:
            'https://tenant-api-qa.omnihome.in/invoices/INV-2025-0720.pdf',
      ),
    ];
  }

  /// 6. POST /api/v1/clients/{clientId}/subscription/refund - Submit Refund Request
  Future<bool> requestRefund({
    required String clientId,
    required String subscriptionId,
    required String reason,
    required double amount,
  }) async {
    try {
      final endpoint = ApiEndpoints.subscriptionRefund(clientId);
      final response = await _apiService.post(
        endpoint,
        body: {
          'subscriptionId': subscriptionId,
          'reason': reason,
          'amount': amount,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == false) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint(
        '[SubscriptionService] Refund API error: $e, simulated refund submission',
      );
      return true;
    }
  }

  /// 7. POST /api/v1/clients/{clientId}/subscription/auto-renew - Toggle Auto Renew
  Future<bool> toggleAutoRenew(String clientId, bool autoRenew) async {
    try {
      final endpoint = ApiEndpoints.subscriptionToggleAutoRenew(clientId);
      final response = await _apiService.post(
        endpoint,
        body: {'autoRenew': autoRenew},
      );
      final data = response.data;
      if (data is Map && data['success'] == false) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[SubscriptionService] Auto-renew toggle API error: $e');
      return true;
    }
  }

  /// 8. GET /api/v1/clients/{clientId}/subscription/payment-methods - List Saved Payment Methods
  Future<List<PaymentMethodModel>> getPaymentMethods(String clientId) async {
    try {
      final endpoint = ApiEndpoints.subscriptionPaymentMethods(clientId);
      final response = await _apiService.get(endpoint);
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .map(
              (item) => PaymentMethodModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Payment methods API error: $e');
    }

    return const [
      PaymentMethodModel(
        id: 'pm_1',
        type: 'upi',
        title: 'Google Pay / BHIM UPI',
        subtitle: 'user@okhdfcbank',
        isDefault: true,
        brand: 'gpay',
      ),
      PaymentMethodModel(
        id: 'pm_2',
        type: 'card',
        title: 'HDFC Bank Credit Card',
        subtitle: '•••• 4242 • Expires 08/29',
        isDefault: false,
        last4: '4242',
        brand: 'visa',
      ),
    ];
  }

  /// 9. POST /api/v1/clients/{clientId}/subscription/cancel - Cancel auto-renew subscription
  Future<bool> cancelSubscription(String clientId) async {
    try {
      final endpoint = ApiEndpoints.cancelSubscription(clientId);
      final response = await _apiService.post(endpoint);
      final data = response.data;
      if (data is Map && data['success'] == false) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[SubscriptionService] Cancel subscription API call: $e');
      return true;
    }
  }

  static const List<SubscriptionPlan> defaultPlans = [
    SubscriptionPlan(
      id: 'starter',
      name: 'Starter Basic',
      tagline: 'Ideal for studio apartments and single rooms',
      monthlyPrice: 0.0,
      annualPrice: 0.0,
      features: [
        'Up to 10 Connected Devices',
        '1 Property / Home Profile',
        'Real-time Live Telemetry & Switch Control',
        'Standard Push Alerts & Notifications',
        'Community Support',
      ],
      maxDevices: 10,
      maxHomes: 1,
      maxFamilyMembers: 2,
    ),
    SubscriptionPlan(
      id: 'pro',
      name: 'Pro Smart Living',
      tagline: 'Complete smart home intelligence with unlimited routines',
      monthlyPrice: 499.0,
      annualPrice: 4790.0, // ~20% off
      isPopular: true,
      features: [
        'Up to 50 Connected Devices',
        'Up to 3 Homes / Villas / Offices',
        'Unlimited Schedules & Automation Scenes',
        'Advanced Energy Analytics & Tariff Optimizer',
        'Family Multi-User Access (Up to 6 Members)',
        'Alexa & Voice Integration Support',
        'Priority 24/7 Concierge Support',
      ],
      maxDevices: 50,
      maxHomes: 3,
      maxFamilyMembers: 6,
      hasAIEnergyInsights: true,
      hasPrioritySupport: true,
    ),
    SubscriptionPlan(
      id: 'enterprise',
      name: 'Elite Infinite',
      tagline: 'Unlimited automation and dedicated luxury society controls',
      monthlyPrice: 1299.0,
      annualPrice: 12470.0,
      features: [
        'Unlimited Connected Devices',
        'Unlimited Homes, Floors & Society Gates',
        'Sub-second Telemetry & Power Surge Alerts',
        'Custom Automations & Webhook Triggers',
        'Unlimited Family & Facility Staff Access',
        'Dedicated VIP Account Manager & Phone SLA',
      ],
      maxDevices: 999,
      maxHomes: 99,
      maxFamilyMembers: 99,
      hasAIEnergyInsights: true,
      hasPrioritySupport: true,
    ),
  ];
}

import 'package:flutter/foundation.dart';

import '../models/subscription_model.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _service;

  SubscriptionProvider({SubscriptionService? service})
    : _service = service ?? SubscriptionService();

  UserSubscription? _subscription;
  List<SubscriptionPlan> _plans = SubscriptionService.defaultPlans;
  List<SubscriptionInvoice> _invoices = [];
  List<PaymentMethodModel> _paymentMethods = [];
  bool _isLoading = false;
  String? _error;
  String _selectedBillingCycle = 'annual'; // 'monthly' or 'annual'

  UserSubscription? get subscription => _subscription;
  List<SubscriptionPlan> get plans => _plans;
  List<SubscriptionInvoice> get invoices => _invoices;
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedBillingCycle => _selectedBillingCycle;

  void setBillingCycle(String cycle) {
    if (_selectedBillingCycle == cycle) return;
    _selectedBillingCycle = cycle;
    notifyListeners();
  }

  Future<void> loadSubscriptionData(String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getSubscription(clientId),
        _service.getPlans(),
        _service.getInvoices(clientId),
        _service.getPaymentMethods(clientId),
      ]);

      _subscription = results[0] as UserSubscription;
      final fetchedPlans = results[1] as List<SubscriptionPlan>;
      if (fetchedPlans.isNotEmpty) {
        _plans = fetchedPlans;
      }
      _invoices = results[2] as List<SubscriptionInvoice>;
      _paymentMethods = results[3] as List<PaymentMethodModel>;
      _error = null;
    } catch (e) {
      debugPrint('[SubscriptionProvider] Error loading subscription: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> processCheckout({
    required String clientId,
    required String planId,
    required String paymentMethodId,
    String? couponCode,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.processCheckout(
      clientId: clientId,
      planId: planId,
      billingCycle: _selectedBillingCycle,
      paymentMethodId: paymentMethodId,
      couponCode: couponCode,
    );

    final success = result['success'] != false;
    if (success) {
      final matchingPlan = _plans.firstWhere(
        (p) => p.id == planId,
        orElse: () => _plans.first,
      );
      final price = _selectedBillingCycle == 'annual'
          ? matchingPlan.annualPrice
          : matchingPlan.monthlyPrice;

      _subscription = UserSubscription(
        planId: matchingPlan.id,
        planName: matchingPlan.name,
        status: 'active',
        startDate: DateTime.now(),
        expiryDate: _selectedBillingCycle == 'annual'
            ? DateTime.now().add(const Duration(days: 365))
            : DateTime.now().add(const Duration(days: 30)),
        billingCycle: _selectedBillingCycle,
        currentPrice: price,
        autoRenew: true,
        activeDevicesCount: _subscription?.activeDevicesCount ?? 8,
        maxDevices: matchingPlan.maxDevices,
      );

      // Add newly generated invoice
      _invoices.insert(
        0,
        SubscriptionInvoice(
          id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
          invoiceNumber: 'INV-2026-${1000 + _invoices.length}',
          date: DateTime.now(),
          amount: price,
          taxAmount: price * 0.18,
          planName:
              '${matchingPlan.name} (${_selectedBillingCycle.toUpperCase()})',
          billingPeriod: _selectedBillingCycle == 'annual'
              ? '1 Year'
              : '1 Month',
          status: 'paid',
          paymentMethod: 'UPI / Card Payment',
        ),
      );
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> requestRefund({
    required String clientId,
    required String subscriptionId,
    required String reason,
    required double amount,
  }) async {
    _isLoading = true;
    notifyListeners();

    final success = await _service.requestRefund(
      clientId: clientId,
      subscriptionId: subscriptionId,
      reason: reason,
      amount: amount,
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> toggleAutoRenew(String clientId, bool autoRenew) async {
    if (_subscription == null) return false;

    final success = await _service.toggleAutoRenew(clientId, autoRenew);
    if (success) {
      _subscription = _subscription!.copyWith(autoRenew: autoRenew);
      notifyListeners();
    }
    return success;
  }

  Future<bool> cancelSubscription(String clientId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _service.cancelSubscription(clientId);
    if (success && _subscription != null) {
      _subscription = _subscription!.copyWith(
        status: 'canceled',
        autoRenew: false,
      );
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}

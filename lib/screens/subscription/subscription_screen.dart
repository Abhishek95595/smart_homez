import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/subscription_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/app_navigation_leading.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final clientId =
          auth.resolvedClientId ??
          auth.resolvedClientUuid ??
          '6782976c-e9a4-41c9-a754-05e4ba0a97b2';
      context.read<SubscriptionProvider>().loadSubscriptionData(clientId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCheckout(SubscriptionPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckoutModal(plan: plan),
    );
  }

  void _openRefundModal(UserSubscription sub) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RefundModal(sub: sub),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final sub = subscriptionProvider.subscription;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppNavigationDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x10000000),
        leading: Builder(
          builder: (ctx) => AppNavigationLeading.drawer(
            color: const Color(0xFF0F172A),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscriptions & Billing',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 18.5,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Plans, Invoices, Refunds & Quotas',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF00A38E),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          indicatorColor: const Color(0xFF00A38E),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Plans & Upgrade'),
            Tab(text: 'Current Plan & Quotas'),
            Tab(text: 'Invoices & History'),
            Tab(text: 'Payment Methods'),
          ],
        ),
      ),
      body: subscriptionProvider.isLoading && sub == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A38E)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Plans & Upgrade
                _PlansTab(onCheckout: _openCheckout),

                // Tab 2: Current Plan & Limits
                _CurrentPlanTab(
                  onOpenRefund: () =>
                      sub != null ? _openRefundModal(sub) : null,
                ),

                // Tab 3: Invoices & History
                const _InvoicesTab(),

                // Tab 4: Payment Methods
                const _PaymentMethodsTab(),
              ],
            ),
    );
  }
}

// ============================================================================
// TAB 1: PLANS & UPGRADE
// ============================================================================
class _PlansTab extends StatelessWidget {
  final void Function(SubscriptionPlan plan) onCheckout;

  const _PlansTab({required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final plans = subscriptionProvider.plans;
    final sub = subscriptionProvider.subscription;
    final isAnnual = subscriptionProvider.selectedBillingCycle == 'annual';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // Billing Cycle Toggle
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BillingCyclePill(
                  title: 'Monthly',
                  isSelected: !isAnnual,
                  onTap: () => subscriptionProvider.setBillingCycle('monthly'),
                ),
                _BillingCyclePill(
                  title: 'Annual (Save 20%)',
                  isSelected: isAnnual,
                  badge: 'BEST VALUE',
                  onTap: () => subscriptionProvider.setBillingCycle('annual'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Plan Cards
        ...plans.map((plan) {
          final isCurrent = sub?.planId.toLowerCase() == plan.id.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _PlanCard(
              plan: plan,
              isCurrent: isCurrent,
              isAnnual: isAnnual,
              onSelect: () => onCheckout(plan),
            ),
          );
        }),
      ],
    );
  }
}

// ============================================================================
// TAB 2: CURRENT PLAN & LIMITS
// ============================================================================
class _CurrentPlanTab extends StatelessWidget {
  final VoidCallback onOpenRefund;

  const _CurrentPlanTab({required this.onOpenRefund});

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final sub = subscriptionProvider.subscription;
    final auth = context.read<AuthProvider>();
    final clientId = auth.resolvedClientId ?? 'client_main';

    if (sub == null) {
      return const Center(child: Text('No active subscription found.'));
    }

    final devProgress = sub.maxDevices > 0
        ? (sub.activeDevicesCount / sub.maxDevices).clamp(0.0, 1.0)
        : 0.0;
    final homeProgress = sub.maxHomes > 0
        ? (sub.activeHomesCount / sub.maxHomes).clamp(0.0, 1.0)
        : 0.0;
    final famProgress = sub.maxFamilyMembers > 0
        ? (sub.activeFamilyMembersCount / sub.maxFamilyMembers).clamp(0.0, 1.0)
        : 0.0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // Current Plan Hero
        _ActiveSubscriptionHero(sub: sub),

        const SizedBox(height: 20),

        // Resource Limits Breakdown
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 14,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plan Resource Quotas',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              _ResourceProgressBar(
                title: 'Connected Devices',
                current: sub.activeDevicesCount,
                max: sub.maxDevices,
                progress: devProgress,
                color: const Color(0xFF00A38E),
              ),
              const SizedBox(height: 14),
              _ResourceProgressBar(
                title: 'Configured Properties / Homes',
                current: sub.activeHomesCount,
                max: sub.maxHomes,
                progress: homeProgress,
                color: const Color(0xFF0284C7),
              ),
              const SizedBox(height: 14),
              _ResourceProgressBar(
                title: 'Family Members Access',
                current: sub.activeFamilyMembersCount,
                max: sub.maxFamilyMembers,
                progress: famProgress,
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Auto Renew & Subscription Controls
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Renewal',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Renews automatically before expiry',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: sub.autoRenew,
                    activeColor: const Color(0xFF00A38E),
                    onChanged: (val) async {
                      await subscriptionProvider.toggleAutoRenew(clientId, val);
                    },
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenRefund,
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text('Request Refund'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel Subscription?'),
                            content: const Text(
                              'You will keep access until the end of your current billing period.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Keep Plan'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Cancel Plan'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await subscriptionProvider.cancelSubscription(
                            clientId,
                          );
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel Plan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 3: INVOICES & BILLING HISTORY
// ============================================================================
class _InvoicesTab extends StatelessWidget {
  const _InvoicesTab();

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final invoices = subscriptionProvider.invoices;

    if (invoices.isEmpty) {
      return const Center(
        child: Text(
          'No invoice records found.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final inv = invoices[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      inv.invoiceNumber,
                      style: const TextStyle(
                        color: Color(0xFF00A38E),
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: inv.status == 'paid'
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      inv.status.toUpperCase(),
                      style: TextStyle(
                        color: inv.status == 'paid'
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.planName,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dateFormat.format(inv.date)} • ${inv.paymentMethod}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${inv.currency} ${inv.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Includes GST/Tax: ${inv.currency} ${inv.taxAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Downloading ${inv.invoiceNumber}.pdf...',
                          ),
                          backgroundColor: const Color(0xFF00A38E),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(
                          Icons.download_rounded,
                          size: 15,
                          color: Color(0xFF00A38E),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Download PDF',
                          style: TextStyle(
                            color: Color(0xFF00A38E),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// TAB 4: PAYMENT METHODS
// ============================================================================
class _PaymentMethodsTab extends StatelessWidget {
  const _PaymentMethodsTab();

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final methods = subscriptionProvider.paymentMethods;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        ...methods.map(
          (pm) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: pm.isDefault
                    ? const Color(0xFF00A38E)
                    : const Color(0xFFE2E8F0),
                width: pm.isDefault ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(
                    pm.type == 'card'
                        ? Icons.credit_card_rounded
                        : Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF0F172A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pm.title,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        pm.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pm.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        color: Color(0xFF00A38E),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add Payment Method dialog ready.'),
                backgroundColor: Color(0xFF0F172A),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add New Payment Method / UPI'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CHECKOUT MODAL & PAYMENT FLOW
// ============================================================================
class _CheckoutModal extends StatefulWidget {
  final SubscriptionPlan plan;

  const _CheckoutModal({required this.plan});

  @override
  State<_CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<_CheckoutModal> {
  String _selectedMethod = 'pm_1';
  final TextEditingController _couponController = TextEditingController();
  double _discount = 0.0;
  bool _isProcessing = false;

  void _applyCoupon() {
    if (_couponController.text.trim().toUpperCase() == 'SMART20') {
      setState(() => _discount = 0.20);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Promo Code SMART20 Applied! (20% OFF)'),
          backgroundColor: Color(0xFF00A38E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coupon code.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    final auth = context.read<AuthProvider>();
    final clientId = auth.resolvedClientId ?? 'client_main';
    final provider = context.read<SubscriptionProvider>();

    final success = await provider.processCheckout(
      clientId: clientId,
      planId: widget.plan.id,
      paymentMethodId: _selectedMethod,
      couponCode: _couponController.text.trim(),
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🎉 Subscribed to ${widget.plan.name} successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00A38E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAnnual =
        context.watch<SubscriptionProvider>().selectedBillingCycle == 'annual';
    final basePrice = isAnnual
        ? widget.plan.annualPrice
        : widget.plan.monthlyPrice;
    final discountAmount = basePrice * _discount;
    final discountedBase = basePrice - discountAmount;
    final gst = discountedBase * 0.18;
    final totalPayable = discountedBase + gst;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        16,
        22,
        MediaQuery.of(context).viewInsets.bottom + 34,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart_checkout_rounded,
                  color: Color(0xFF00A38E),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checkout: ${widget.plan.name}',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Billed ${isAnnual ? 'Annually (Save 20%)' : 'Monthly'}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Order Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Plan Subtotal',
                  value: '₹ ${basePrice.toStringAsFixed(0)}',
                ),
                if (_discount > 0) ...[
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: 'Discount (SMART20)',
                    value: '- ₹ ${discountAmount.toStringAsFixed(0)}',
                    color: const Color(0xFF16A34A),
                  ),
                ],
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Applicable GST (18%)',
                  value: '₹ ${gst.toStringAsFixed(0)}',
                ),
                const Divider(height: 18, color: Color(0xFFE2E8F0)),
                _SummaryRow(
                  label: 'Total Payable',
                  value: '₹ ${totalPayable.toStringAsFixed(0)}',
                  isBold: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Coupon Code Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Promo Code (try SMART20)',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Pay Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A38E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Pay ₹ ${totalPayable.toStringAsFixed(0)} & Activate',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REFUND MODAL
// ============================================================================
class _RefundModal extends StatefulWidget {
  final UserSubscription sub;

  const _RefundModal({required this.sub});

  @override
  State<_RefundModal> createState() => _RefundModalState();
}

class _RefundModalState extends State<_RefundModal> {
  String _selectedReason = 'Plan not matching my requirements';
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Plan not matching my requirements',
    'Accidental upgrade / wrong tier selected',
    'Moving out / no longer needed',
    'Device compatibility issues',
    'Other reason',
  ];

  Future<void> _submitRefund() async {
    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final clientId = auth.resolvedClientId ?? 'client_main';
    final provider = context.read<SubscriptionProvider>();

    final success = await provider.requestRefund(
      clientId: clientId,
      subscriptionId: widget.sub.planId,
      reason: _selectedReason,
      amount: widget.sub.currentPrice,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Refund request submitted. You will receive an update in 24 hours.'
                : 'Failed to submit refund request.',
          ),
          backgroundColor: success
              ? const Color(0xFF00A38E)
              : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Icon(
                Icons.assignment_return_rounded,
                color: Color(0xFFD97706),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Request Subscription Refund',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Eligible Refund Amount: ₹ ${widget.sub.currentPrice.toStringAsFixed(0)} (Pro-rata calculated)',
            style: const TextStyle(
              color: Color(0xFF00A38E),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Select Reason:',
            style: TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ..._reasons.map(
            (r) => RadioListTile<String>(
              value: r,
              groupValue: _selectedReason,
              onChanged: (val) => setState(() => _selectedReason = val!),
              title: Text(r, style: const TextStyle(fontSize: 13)),
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: const Color(0xFF00A38E),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRefund,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Refund Request',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER COMPONENTS
// ============================================================================
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            fontSize: isBold ? 14 : 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color:
                color ??
                (isBold ? const Color(0xFF00A38E) : const Color(0xFF0F172A)),
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ResourceProgressBar extends StatelessWidget {
  final String title;
  final int current;
  final int max;
  final double progress;
  final Color color;

  const _ResourceProgressBar({
    required this.title,
    required this.current,
    required this.max,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$current / $max',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _ActiveSubscriptionHero extends StatelessWidget {
  final UserSubscription sub;

  const _ActiveSubscriptionHero({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x200F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A38E).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00A38E).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E5BF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sub.status.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF00E5BF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFFFD700),
                size: 26,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            sub.planName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Billed ${sub.billingCycle.toUpperCase()} • Valid until ${sub.expiryDate != null ? '${sub.expiryDate!.day}/${sub.expiryDate!.month}/${sub.expiryDate!.year}' : 'Active'}',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingCyclePill extends StatelessWidget {
  final String title;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  const _BillingCyclePill({
    required this.title,
    required this.isSelected,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (badge != null && isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A38E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;
  final bool isAnnual;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isAnnual,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final price = isAnnual ? plan.annualPrice : plan.monthlyPrice;
    final periodText = isAnnual ? '/ year' : '/ month';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: plan.isPopular
              ? const Color(0xFF00A38E)
              : const Color(0xFFE2E8F0),
          width: plan.isPopular ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: plan.isPopular
                ? const Color(0x1200A38E)
                : const Color(0x06000000),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              if (plan.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      color: Color(0xFF00A38E),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            plan.tagline,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${plan.currency} ${price.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                periodText,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          ...plan.features.map(
            (feat) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE6F7F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF00A38E),
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feat,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent ? null : onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.isPopular
                    ? const Color(0xFF00A38E)
                    : const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFF1F5F9),
                disabledForegroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                isCurrent ? 'Current Active Plan' : 'Select ${plan.name}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

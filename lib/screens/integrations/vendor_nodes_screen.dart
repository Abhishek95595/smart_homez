import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vendor_account_model.dart';
import '../../models/vendor_node_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../services/hierarchy_service.dart';
import '../../theme/app_theme.dart';
import '../properties/management_dialogs.dart';

class VendorNodesScreen extends StatefulWidget {
  const VendorNodesScreen({super.key});

  @override
  State<VendorNodesScreen> createState() => _VendorNodesScreenState();
}

class _VendorNodesScreenState extends State<VendorNodesScreen> {
  final HierarchyService _service = HierarchyService();

  bool _isLoadingAccounts = false;
  bool _isLoadingNodes = false;
  String? _accountsError;
  String? _nodesError;

  List<VendorAccountModel> _accounts = [];
  List<VendorNodeModel> _unpairedNodes = [];

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final clientId = context.read<AuthProvider>().resolvedClientId;

    if (clientId == null || clientId.trim().isEmpty) {
      debugPrint('Vendor clientId is missing or invalid.');
      if (mounted) {
        setState(() {
          _accountsError = 'Client ID is missing.';
          _nodesError = 'Client ID is missing.';
          _isLoadingAccounts = false;
          _isLoadingNodes = false;
        });
      }
      return;
    }

    debugPrint('Loading vendor data for clientId: $clientId');

    setState(() {
      _isLoadingAccounts = true;
      _isLoadingNodes = true;
      _accountsError = null;
      _nodesError = null;
    });

    await Future.wait([_loadAccounts(clientId), _loadNodes(clientId)]);
  }

  Future<void> _loadAccounts(String clientId) async {
    try {
      final accounts = await _service.getVendorAccounts(clientId);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _accountsError = null;
        _isLoadingAccounts = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Vendor accounts error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      setState(() {
        _accountsError = 'Unable to load vendor accounts.';
        _isLoadingAccounts = false;
      });
    }
  }

  Future<void> _loadNodes(String clientId) async {
    try {
      final nodes = await _service.getUnpairedVendorNodes(clientId);
      if (!mounted) return;
      setState(() {
        _unpairedNodes = nodes;
        _nodesError = null;
        _isLoadingNodes = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Vendor nodes error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      setState(() {
        _nodesError = 'Unable to load unpaired nodes.';
        _isLoadingNodes = false;
      });
    }
  }

  Future<void> _addAccount() async {
    final clientId = context.read<AuthProvider>().resolvedClientId;
    if (clientId == null) return;

    final idCtrl = TextEditingController();
    final keyCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vendor Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(
                labelText: 'Vendor Definition ID',
                hintText: 'UUID of the vendor definition',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: 'API Key (Optional)',
                hintText: 'Key provided by the vendor',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await _service.addVendorAccount(
          clientId: clientId,
          vendorDefinitionId: idCtrl.text.trim(),
          apiKey: keyCtrl.text.trim().isEmpty ? null : keyCtrl.text.trim(),
        );
        _loadAccounts(clientId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to add vendor account. Please try again.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _sync() async {
    final clientId = context.read<AuthProvider>().resolvedClientId;
    if (clientId == null) return;

    setState(() {
      _isLoadingAccounts = true;
      _isLoadingNodes = true;
    });

    try {
      await _service.syncVendorAccounts(clientId);
      await _loadVendorData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sync successful')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync failed. Please try again.')),
        );
      }
      setState(() {
        _isLoadingAccounts = false;
        _isLoadingNodes = false;
      });
    }
  }

  Future<void> _deleteAccount(VendorAccountModel account) async {
    final clientId = context.read<AuthProvider>().resolvedClientId;
    if (clientId == null) return;

    final approved = await confirmDelete(
      context,
      title: 'Remove Account?',
      message: 'This will remove the vendor account and its unpaired devices.',
    );

    if (approved && mounted) {
      try {
        await _service.deleteVendorAccount(
          clientId: clientId,
          accountId: account.id,
        );
        _loadAccounts(clientId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to remove account. Please try again.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _pairNode(VendorNodeModel node) async {
    final clientId = context.read<AuthProvider>().resolvedClientId;
    if (clientId == null) return;

    final propertyProvider = context.read<PropertyProvider>();

    final result = await showDeviceForm(
      context,
      nameExists: (_) => false,
      macExists: (_) => false,
      showLocationFields: true,
      properties: propertyProvider.properties,
      floors: propertyProvider.floors,
      rooms: propertyProvider.rooms,
    );

    if (result != null && mounted) {
      try {
        if (result.roomId != null) {
          await _service.pairVendorNodeToRoom(
            clientId: clientId,
            nodeId: node.id,
            roomId: result.roomId!,
          );
        } else if (result.floorId != null) {
          await _service.pairVendorNodeToFloor(
            clientId: clientId,
            nodeId: node.id,
            floorId: result.floorId!,
          );
        }
        _loadVendorData();
        if (mounted) {
          await propertyProvider.syncFromApi(clientId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pairing failed. Please try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Nodes'),
        actions: [
          IconButton(
            tooltip: 'Sync accounts',
            onPressed: (_isLoadingAccounts || _isLoadingNodes) ? null : _sync,
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAccount,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Account'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVendorData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader('Accounts'),
            if (_isLoadingAccounts)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_accountsError != null)
              _ErrorState(
                message: _accountsError!,
                onRetry: () {
                  final id = context.read<AuthProvider>().resolvedClientId;
                  if (id != null) _loadAccounts(id);
                },
              )
            else if (_accounts.isEmpty)
              const _EmptyState(message: 'No vendor accounts added.')
            else
              ..._accounts.map(
                (a) =>
                    _AccountCard(account: a, onDelete: () => _deleteAccount(a)),
              ),
            const SizedBox(height: 24),
            _sectionHeader('Unpaired Nodes'),
            if (_isLoadingNodes)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_nodesError != null)
              _ErrorState(
                message: _nodesError!,
                onRetry: () {
                  final id = context.read<AuthProvider>().resolvedClientId;
                  if (id != null) _loadNodes(id);
                },
              )
            else if (_unpairedNodes.isEmpty)
              const _EmptyState(message: 'No unpaired nodes found.')
            else
              ..._unpairedNodes.map(
                (n) => _NodeCard(node: n, onPair: () => _pairNode(n)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final VendorAccountModel account;
  final VoidCallback onDelete;

  const _AccountCard({required this.account, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.hub_outlined)),
        title: Text(account.vendorName),
        subtitle: Text(
          'Added on ${account.createdAt.toString().split(' ').first}',
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.danger,
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  final VendorNodeModel node;
  final VoidCallback onPair;

  const _NodeCard({required this.node, required this.onPair});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Icon(Icons.sensors_rounded, color: AppColors.primary),
        ),
        title: Text(node.name),
        subtitle: Text(node.type ?? 'Unknown type'),
        trailing: FilledButton.tonal(
          onPressed: onPair,
          child: const Text('Pair'),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textFaint),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Text(message, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

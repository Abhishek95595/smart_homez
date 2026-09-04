import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/scene_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/scene_provider.dart';
import '../../widgets/app_navigation_drawer.dart';
import 'scene_editor_screen.dart';

class ScenesScreen extends StatefulWidget {
  const ScenesScreen({super.key});

  @override
  State<ScenesScreen> createState() => _ScenesScreenState();
}

class _ScenesScreenState extends State<ScenesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String? _currentClientId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<SceneProvider>().setSearchQuery(_searchController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadScenes();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newId = _getClientId();
    if (newId != null && newId != _currentClientId) {
      _currentClientId = newId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadScenes();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _getClientId() {
    final auth = context.read<AuthProvider>();
    final property = context.read<PropertyProvider>();
    final id = property.clientId ?? auth.resolvedClientUuid;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  Future<void> _loadScenes() async {
    final clientId = _getClientId();
    _currentClientId = clientId;
    await context.read<SceneProvider>().fetchScenes(clientId);
  }

  IconData _getIconData(String? iconId) {
    switch (iconId?.toLowerCase()) {
      case 'sun':
        return Icons.wb_sunny_rounded;
      case 'film':
        return Icons.movie_rounded;
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'briefcase':
        return Icons.work_rounded;
      case 'bed':
        return Icons.bed_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'moon':
      default:
        return Icons.nightlight_round;
    }
  }

  Future<void> _activateScene(SceneModel scene) async {
    final clientId = _getClientId();
    final provider = context.read<SceneProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.activateScene(clientId, scene.id);

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '“${scene.name}” activated successfully'
              : (provider.errorMessage ?? 'Failed to activate “${scene.name}”'),
        ),
        backgroundColor: success ? const Color(0xFF00897B) : Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openEditor([SceneModel? scene]) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SceneEditorScreen(scene: scene)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sceneProvider = context.watch<SceneProvider>();
    final scenes = sceneProvider.filteredScenes;
    final isLoading = sceneProvider.isLoading;
    final clientId = _getClientId();

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppNavigationDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.menu_rounded, color: colorScheme.onSurface),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Menu',
          ),
        title: Text(
          'Scenes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurface),
            onPressed: _loadScenes,
            tooltip: 'Refresh Scenes',
          ),
        ],
      ),
      body: SafeArea(
        child: clientId == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 44,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Unable to determine the active client.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please sign in or select an active home property.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadScenes,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                color: colorScheme.primary,
                onRefresh: _loadScenes,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    // Hero Section
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outlineVariant),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer.withValues(alpha: 0.4),
                            colorScheme.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your home, set in one tap.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Create simple scenes by choosing devices and the state you want.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Quick Scenes ready',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Scenes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openEditor(),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Create'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Search Bar
                    TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search scenes',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (scenes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 40,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.trim().isNotEmpty
                                  ? 'No scenes found.'
                                  : 'No scenes yet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a scene to control multiple devices in one tap.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...scenes.map((scene) => _buildSceneCard(scene)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSceneCard(SceneModel scene) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<SceneProvider>();
    final isActivating = provider.isActivating(scene.id);
    final count = scene.actions.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(scene.icon),
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count device${count == 1 ? '' : 's'} configured',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  scene.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: scene.isFavorite
                      ? Colors.amber
                      : colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  final clientId = _getClientId();
                  provider.toggleFavorite(clientId, scene);
                },
                tooltip: 'Toggle Quick Scene',
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Chip(
                label: Text('$count device${count == 1 ? '' : 's'}'),
                labelStyle: const TextStyle(fontSize: 10),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
              Chip(
                label: Text(
                  scene.isScheduleEnabled && scene.scheduledTime != null
                      ? 'Scheduled ${scene.scheduledTime}'
                      : 'Manual',
                ),
                labelStyle: TextStyle(
                  fontSize: 10,
                  color: scene.isScheduleEnabled
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
              if (scene.isFavorite)
                Chip(
                  label: const Text('Quick Scene'),
                  labelStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colorScheme.primaryContainer,
                ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 10),

          // Card Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: isActivating
                        ? null
                        : () => _activateScene(scene),
                    icon: isActivating
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(isActivating ? 'Activating...' : 'Activate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _openEditor(scene),
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: colorScheme.onSurfaceVariant,
                tooltip: 'Edit Scene',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

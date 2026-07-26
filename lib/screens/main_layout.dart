import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';

class _NavItem {
  final String route;
  final String label;
  final IconData icon;

  const _NavItem({
    required this.route,
    required this.label,
    required this.icon,
  });
}

class MainLayout extends StatelessWidget {
  final Widget? child;

  const MainLayout({super.key, this.child});

  // Dashboard uses '/' to match GoRouter — all others match their GoRoute path
  static const List<_NavItem> _navItems = [
    _NavItem(route: '/', label: 'Dashboard', icon: LucideIcons.layoutDashboard),
    _NavItem(
        route: '/packet-tracing',
        label: 'Packet Tracing',
        icon: LucideIcons.activity),
    _NavItem(
        route: '/firewall-logs',
        label: 'Firewall Logs',
        icon: LucideIcons.shield),
    _NavItem(
        route: '/threat-response',
        label: 'Threat Response',
        icon: LucideIcons.shieldAlert),
    _NavItem(
        route: '/reports',
        label: 'Reports & Intelligence',
        icon: LucideIcons.fileText),
    _NavItem(route: '/ai-analyst', label: 'AI Analyst', icon: LucideIcons.bot),
    _NavItem(
        route: '/virus-scanner',
        label: 'Virus Scanner',
        icon: LucideIcons.scanSearch),
    _NavItem(
        route: '/ip-analysis',
        label: 'Threat Intelligence',
        icon: LucideIcons.globe),
    _NavItem(route: '/settings', label: 'Settings', icon: LucideIcons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    // Sync AppStateProvider with GoRouter's actual current location.
    // This keeps the sidebar highlight and page title correct on deep links,
    // browser back/forward, and programmatic navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final location = GoRouterState.of(context).matchedLocation;
      context.read<AppStateProvider>().setCurrentRoute(location);
    });

    return Consumer<AuthProvider>(
      builder: (context, authState, _) {
        if (authState.isLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.bgPrimary,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        if (authState.user != null && authState.profile == null) {
          return Scaffold(
            backgroundColor: AppTheme.bgPrimary,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.triangleAlert,
                      size: 48, color: AppTheme.error),
                  const SizedBox(height: 16),
                  Text(
                    authState.error ??
                        'Your CyberSentinel profile could not be loaded.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          authState.retryProfileBootstrap();
                        },
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        icon: const Icon(LucideIcons.logOut, size: 16),
                        label: const Text('Sign Out'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          authState.signOut();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Consumer<AppStateProvider>(
          builder: (context, appState, _) {
            return Scaffold(
              backgroundColor: AppTheme.bgPrimary,
              body: Stack(
                children: [
                  Row(
                    children: [
                      _Sidebar(
                        navItems: _navItems,
                        currentRoute: appState.currentRoute,
                        onRouteSelected: (route) {
                          context.go(route);
                          appState.setCurrentRoute(route);
                        },
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _TopBar(title: appState.pageTitle),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(AppTheme.spacing24),
                                // [child] is the screen GoRouter injects via ShellRoute.
                                // Fallback to DashboardScreen never fires in practice
                                // because GoRouter always provides a child, but keeps
                                // the widget tree valid during hot reload edge cases.
                                child: child ?? const SizedBox.shrink(),
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
      },
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final List<_NavItem> navItems;
  final String currentRoute;
  final ValueChanged<String> onRouteSelected;

  const _Sidebar({
    required this.navItems,
    required this.currentRoute,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppTheme.bgSecondary,
      child: Column(
        children: [
          _buildLogo(),
          const Divider(color: AppTheme.borderPrimary, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
              children: navItems
                  .map((item) => _NavTile(
                        item: item,
                        isSelected: currentRoute == item.route,
                        onTap: () => onRouteSelected(item.route),
                      ))
                  .toList(),
            ),
          ),
          const Divider(color: AppTheme.borderPrimary, height: 1),
          _buildUserFooter(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(LucideIcons.shield, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'CyberSentinel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserFooter() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Consumer<AuthProvider>(
        builder: (context, authState, child) {
          final profile = authState.profile;
          final email = authState.user?.email ?? '';
          final role = profile?.role ?? '';

          return Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: const Icon(LucideIcons.user,
                    size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.logOut,
                    size: 18, color: AppTheme.textSecondary),
                tooltip: 'Logout',
                onPressed: () {
                  context.read<AuthProvider>().signOut();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Nav Tile ───────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing8, vertical: 2),
      child: Material(
        color: isSelected
            ? AppTheme.primary.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
            decoration: isSelected
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppTheme.primary, width: 3),
                    ),
                  )
                : null,
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;

  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(bottom: BorderSide(color: AppTheme.borderPrimary)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.settings,
                    size: 20, color: AppTheme.textSecondary),
                onPressed: () {
                  context.go('/settings');
                  context.read<AppStateProvider>().setCurrentRoute('/settings');
                },
                tooltip: 'Settings',
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                offset: const Offset(0, 40),
                color: AppTheme.bgSecondary,
                icon: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                  child: const Icon(LucideIcons.user,
                      size: 14, color: AppTheme.primary),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    context.read<AuthProvider>().signOut();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: const [
                        Icon(LucideIcons.user,
                            size: 16, color: AppTheme.textSecondary),
                        SizedBox(width: 8),
                        Text('Profile',
                            style: TextStyle(color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: const [
                        Icon(LucideIcons.logOut,
                            size: 16, color: AppTheme.error),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: AppTheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

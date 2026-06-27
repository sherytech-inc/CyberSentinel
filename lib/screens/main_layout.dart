import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../widgets/chatbot/chatbot_widget.dart';

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
        route: '/virus-scanner',
        label: 'Virus Scanner',
        icon: LucideIcons.scanSearch),
    _NavItem(
        route: '/ip-analysis', label: 'IP Analysis', icon: LucideIcons.globe),
    _NavItem(route: '/reports', label: 'Reports', icon: LucideIcons.chartBar),
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
                            padding: const EdgeInsets.all(AppTheme.spacing24),
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
              const ChatbotWidget(),
            ],
          ),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary.withOpacity(0.2),
            child:
                const Icon(LucideIcons.user, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOC Analyst',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  'analyst@cybersentinel.io',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
                icon: const Icon(LucideIcons.bell,
                    size: 20, color: AppTheme.textSecondary),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.settings,
                    size: 20, color: AppTheme.textSecondary),
                onPressed: () {},
                tooltip: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

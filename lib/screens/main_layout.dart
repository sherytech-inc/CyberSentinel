import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common/common.dart';

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

    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    return Consumer<AuthProvider>(
      builder: (context, authState, _) {
        if (authState.isLoading) {
          return Scaffold(
            backgroundColor: colors.backgroundPrimary,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CyberSentinelLogo(size: 40),
                  const SizedBox(height: CsSpacing.xl),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (authState.user != null && authState.profile == null) {
          return Scaffold(
            backgroundColor: colors.backgroundPrimary,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.triangleAlert,
                      size: 40, color: colors.error),
                  const SizedBox(height: CsSpacing.lg),
                  Text(
                    authState.error ??
                        'Your CyberSentinel profile could not be loaded.',
                    textAlign: TextAlign.center,
                    style: text.title.copyWith(color: colors.textPrimary),
                  ),
                  const SizedBox(height: CsSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Retry'),
                        // No global button theme exists on purpose, so this
                        // button carries its own tokens.
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.primaryForeground,
                          shape: const RoundedRectangleBorder(
                            borderRadius: CsRadius.mediumBorder,
                          ),
                        ),
                        onPressed: () {
                          authState.retryProfileBootstrap();
                        },
                      ),
                      const SizedBox(width: CsSpacing.lg),
                      TextButton.icon(
                        icon: const Icon(LucideIcons.logOut, size: 16),
                        label: const Text('Sign Out'),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.textSecondary,
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
              backgroundColor: colors.backgroundPrimary,
              body: Row(
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
                            padding: const EdgeInsets.all(CsSpacing.xl),
                            // [child] is the screen GoRouter injects via ShellRoute.
                            // The empty fallback never fires in practice because
                            // GoRouter always provides a child, but keeps the
                            // widget tree valid during hot reload edge cases.
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
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
    final colors = CsColors.of(context);

    return Container(
      width: CsBreakpoints.sidebarExpanded,
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        border: Border(right: BorderSide(color: colors.borderSubtle)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
                CsSpacing.lg, CsSpacing.lg, CsSpacing.lg, CsSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CyberSentinelLockup(size: 20),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: CsSpacing.md, vertical: CsSpacing.sm),
              children: [
                for (final item in navItems)
                  _NavTile(
                    item: item,
                    isSelected: currentRoute == item.route,
                    onTap: () => onRouteSelected(item.route),
                  ),
              ],
            ),
          ),
          Divider(color: colors.borderSubtle, height: 1, thickness: 1),
          const _UserFooter(),
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
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Semantics(
        selected: isSelected,
        button: true,
        label: item.label,
        child: Material(
          color: isSelected ? colors.surfaceHover : Colors.transparent,
          borderRadius: CsRadius.mediumBorder,
          child: InkWell(
            borderRadius: CsRadius.mediumBorder,
            hoverColor: colors.surfaceHover.withValues(alpha: 0.6),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: CsSpacing.md, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 17,
                    color: isSelected ? colors.primary : colors.textSecondary,
                  ),
                  const SizedBox(width: CsSpacing.md),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color:
                            isSelected ? colors.textPrimary : colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── User footer ────────────────────────────────────────────────────────────

class _UserFooter extends StatelessWidget {
  const _UserFooter();

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);

    return Padding(
      padding: const EdgeInsets.all(CsSpacing.md),
      child: Consumer<AuthProvider>(
        builder: (context, authState, _) {
          final profile = authState.profile;
          final email = authState.user?.email ?? '';
          final role = profile?.role ?? '';
          final initial =
              email.isNotEmpty ? email.characters.first.toUpperCase() : '?';

          return Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: CsColors.tint(colors.primary, alpha: 0.15),
                child: Text(
                  initial,
                  style: text.labelMedium.copyWith(color: colors.primary),
                ),
              ),
              const SizedBox(width: CsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.isEmpty ? 'Signed in' : role.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          text.labelMedium.copyWith(color: colors.textPrimary),
                    ),
                    Text(
                      email,
                      style: text.caption.copyWith(color: colors.textTertiary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.logOut,
                    size: 17, color: colors.textSecondary),
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

// ── Top Bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;

  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = CsColors.of(context);
    final text = CsTypography.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 57,
      padding: const EdgeInsets.symmetric(horizontal: CsSpacing.xl),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.headline.copyWith(color: colors.textPrimary),
            ),
          ),
          IconButton(
            icon: Icon(
              isDark ? LucideIcons.sun : LucideIcons.moon,
              size: 18,
              color: colors.textSecondary,
            ),
            tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
            onPressed: () {
              context
                  .read<SettingsProvider>()
                  .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.settings,
                size: 18, color: colors.textSecondary),
            tooltip: 'Settings',
            onPressed: () {
              context.go('/settings');
              context.read<AppStateProvider>().setCurrentRoute('/settings');
            },
          ),
          const SizedBox(width: CsSpacing.xs),
          PopupMenuButton<String>(
            offset: const Offset(0, 44),
            color: colors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: CsRadius.mediumBorder,
              side: BorderSide(color: colors.border),
            ),
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: CsColors.tint(colors.primary, alpha: 0.15),
              child: Icon(LucideIcons.user, size: 14, color: colors.primary),
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
                  children: [
                    Icon(LucideIcons.user,
                        size: 16, color: colors.textSecondary),
                    const SizedBox(width: CsSpacing.sm),
                    Text('Profile',
                        style: text.body.copyWith(color: colors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, size: 16, color: colors.error),
                    const SizedBox(width: CsSpacing.sm),
                    Text('Logout',
                        style: text.body.copyWith(color: colors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

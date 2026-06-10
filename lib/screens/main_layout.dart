import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../widgets/chatbot/chatbot_widget.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppTheme.isDesktop(context);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Stack(
        children: [
          isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
          const ChatbotWidget(),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _buildSidebar(context),
        Expanded(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: Container(
                  color: AppTheme.bgPrimary,
                  padding: const EdgeInsets.all(AppTheme.spacing32),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildMobileHeader(context),
        Expanded(
          child: Container(
            color: AppTheme.bgPrimary,
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: AppTheme.sidebarWidth,
      color: AppTheme.bgSecondary,
      child: Column(
        children: [
          _buildLogo(),
          Expanded(
            child: _buildNavigation(context),
          ),
          _buildSystemStatus(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderPrimary),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.shield,
            color: AppTheme.primary,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spacing12),
          const Text(
            'CyberSentinel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(BuildContext context) {
    final navItems = [
      NavItem(path: '/', label: 'Dashboard', icon: LucideIcons.layoutDashboard),
      NavItem(path: '/packet-tracing', label: 'Packet Tracing', icon: LucideIcons.network),
      NavItem(path: '/firewall-logs', label: 'Firewall Logs', icon: LucideIcons.shield),
      NavItem(path: '/virus-scanner', label: 'Virus Scanner', icon: LucideIcons.scanSearch),
      NavItem(path: '/ip-analysis', label: 'IP Analysis', icon: LucideIcons.mapPin),
      NavItem(path: '/reports', label: 'Reports', icon: LucideIcons.fileText),
      NavItem(path: '/settings', label: 'Settings', icon: LucideIcons.settings),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      children: navItems.map((item) => _buildNavItem(context, item)).toList(),
    );
  }

  Widget _buildNavItem(BuildContext context, NavItem item) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final isActive = item.path == '/'
        ? currentLocation == '/'
        : currentLocation.startsWith(item.path);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(item.path),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing12,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
              border: Border.all(
                color: isActive ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderPrimary),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.borderPrimary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'System Status',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderPrimary),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            appState.getPageTitle(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Global search...',
                    hintStyle: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AppTheme.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppTheme.borderPrimary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(color: AppTheme.borderSecondary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(color: AppTheme.borderSecondary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing24),
              _buildNotificationButton(),
              const SizedBox(width: AppTheme.spacing12),
              _buildProfileButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            LucideIcons.bell,
            color: AppTheme.textSecondary,
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileButton() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: const Icon(
        LucideIcons.user,
        color: AppTheme.primary,
        size: 20,
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderPrimary),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.shield,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacing8),
              const Text(
                'CyberSentinel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  LucideIcons.bell,
                  color: AppTheme.textSecondary,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    final navItems = [
      NavItem(path: '/', label: 'Dashboard', icon: LucideIcons.layoutDashboard),
      NavItem(path: '/packet-tracing', label: 'Packet', icon: LucideIcons.network),
      NavItem(path: '/firewall-logs', label: 'Firewall', icon: LucideIcons.shield),
      NavItem(path: '/virus-scanner', label: 'Scanner', icon: LucideIcons.scanSearch),
      NavItem(path: '/reports', label: 'Reports', icon: LucideIcons.fileText),
    ];

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(
          top: BorderSide(color: AppTheme.borderPrimary),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems.map((item) {
          final isActive = item.path == '/'
              ? currentLocation == '/'
              : currentLocation.startsWith(item.path);

          return InkWell(
            onTap: () => context.go(item.path),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isActive ? AppTheme.primary : AppTheme.textTertiary,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? AppTheme.primary : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class NavItem {
  final String path;
  final String label;
  final IconData icon;

  NavItem({required this.path, required this.label, required this.icon});
}

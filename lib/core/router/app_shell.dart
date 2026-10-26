import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/brand.dart';
import 'sections.dart';

/// Phone layout of the web app (`src/components/Layout.tsx` below `md`): white header
/// with the logo and a logout button, and a 64 px bottom bar filtered by permission.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final permissions = context.watch<AuthController>().session?.permissions ?? const <String>{};
    final items = allowedSections(permissions);
    final current = sectionFor(location);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(57),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.neutral200)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const BrandLogo(),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    icon: const Icon(Icons.logout, size: 20, color: AppColors.neutral600),
                    onPressed: () => context.read<AuthController>().logout(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: child,
      bottomNavigationBar: items.length < 2
          ? null
          : _BottomBar(items: items, current: current, onSelect: (section) => context.go(section.path)),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.items, required this.current, required this.onSelect});

  final List<Section> items;
  final Section? current;
  final ValueChanged<Section> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _BottomBarItem(
                    section: item,
                    active: item.path == current?.path,
                    onTap: () => onSelect(item),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({required this.section, required this.active, required this.onTap});

  final Section section;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.green800 : AppColors.neutral500;
    return Semantics(
      selected: active,
      button: true,
      child: InkResponse(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: active ? AppColors.green100 : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(section.icon, size: 20, color: color),
            ),
            const SizedBox(height: 2),
            Text(section.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

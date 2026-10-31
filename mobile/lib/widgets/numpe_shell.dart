import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class NumpeShell extends StatelessWidget {
  const NumpeShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  static const _destinations = [
    _Destination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      location: '/home',
    ),
    _Destination(
      label: 'Activity',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      location: '/activity',
    ),
    _Destination(
      label: 'Shield',
      icon: Icons.shield_outlined,
      selectedIcon: Icons.shield_rounded,
      location: '/shield',
    ),
    _Destination(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      location: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(location);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NUMPE',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Center(child: _SimulatedBadge()),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 700) {
              return Row(
                children: [
                  NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) => _navigate(context, index),
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final destination in _destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: child),
                ],
              );
            }

            return Column(
              children: [
                Expanded(child: child),
                NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _navigate(context, index),
                  destinations: [
                    for (final destination in _destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _selectedIndex(String location) {
    final index = _destinations.indexWhere(
      (destination) => destination.location == location,
    );
    return index < 0 ? 0 : index;
  }

  void _navigate(BuildContext context, int index) {
    context.go(_destinations[index].location);
  }
}

class _SimulatedBadge extends StatelessWidget {
  const _SimulatedBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x144361EE),
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, size: 14, color: AppColors.blue),
            SizedBox(width: 5),
            Text(
              'SIMULATED',
              style: TextStyle(
                color: AppColors.blue,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.location,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String location;
}

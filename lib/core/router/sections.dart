import 'package:flutter/material.dart';

import '../auth/session.dart';

/// Navigation section of the bottom bar and the permission that enables it.
class Section {
  const Section({required this.path, required this.label, required this.icon, required this.permission});

  final String path;
  final String label;
  final IconData icon;
  final String permission;
}

/// Sections in menu order, as the web app's `SECCIONES` (user and role admin stay on the web).
const sections = [
  Section(path: '/captura', label: 'Captura', icon: Icons.photo_camera_outlined, permission: Permissions.captureRecord),
  Section(path: '/animales', label: 'Rodeo', icon: Icons.pets_outlined, permission: Permissions.herdRead),
  Section(path: '/lotes', label: 'Lotes', icon: Icons.grid_view_outlined, permission: Permissions.herdRead),
  Section(path: '/panel', label: 'Panel', icon: Icons.bar_chart_outlined, permission: Permissions.analyticsRead),
  Section(path: '/alertas', label: 'Alertas', icon: Icons.notifications_outlined, permission: Permissions.analyticsRead),
];

/// The first permission of this list decides the home screen.
const _homePriority = [
  (Permissions.captureRecord, '/captura'),
  (Permissions.analyticsRead, '/panel'),
  (Permissions.herdRead, '/animales'),
];

List<Section> allowedSections(Set<String> permissions) =>
    sections.where((section) => permissions.contains(section.permission)).toList();

/// Home path of the user, or null when no permission opens a screen of the app.
String? homePathFor(Set<String> permissions) {
  for (final (permission, path) in _homePriority) {
    if (permissions.contains(permission)) return path;
  }
  return null;
}

/// Section that owns [path] (nested paths included), or null.
Section? sectionFor(String path) {
  for (final section in sections) {
    if (path == section.path || path.startsWith('${section.path}/')) return section;
  }
  return null;
}

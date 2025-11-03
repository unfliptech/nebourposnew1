class SyncFlags {
  const SyncFlags({
    required this.menuOutdated,
    required this.themeOutdated,
  });

  final bool menuOutdated;
  final bool themeOutdated;

  SyncFlags copyWith({
    bool? menuOutdated,
    bool? themeOutdated,
  }) {
    return SyncFlags(
      menuOutdated: menuOutdated ?? this.menuOutdated,
      themeOutdated: themeOutdated ?? this.themeOutdated,
    );
  }
}

library;

/// Defines the visual variant of [AppButton].
enum AppButtonType {
  filled,
  filledTonal,
  elevated,
  outlined,
  text,
  icon,
  fab,
  extendedFab,
}

/// Backwards-compatible enum used across the codebase for button sizes.
enum AppSize {
  small,
  medium,
  large,
  custom,
}

// Centralized size constants so multiple widgets can share the same values.
const double kFieldHeightSmall = 40.0;
const double kFieldHeightMedium = 48.0;
const double kFieldHeightLarge = 56.0;
const double kFieldHeightDefault = kFieldHeightMedium;

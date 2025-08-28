class UpgradeConfig {
  // Maximum upgrade multipliers
  static const double maxBulletSizeMultiplier = 2.0;   // Max 2x size (100% increase)
  static const double maxFireRateMultiplier = 3.0;     // Max 3x fire rate (200% increase)
  static const double maxAllyCount = 5.0;              // Max 3 allies (including main player = 4 total)

  // Base values
  static const double baseBulletWidth = 3.0;
  static const double baseBulletHeight = 8.0;
  static const double baseFireRate = 5.0;              // Shots per second (instead of seconds between shots)

// Future upgrade types can be added here
// static const double maxBulletSpeedMultiplier = 2.0;
// static const double maxBulletDamageMultiplier = 5.0;
// static const int maxMultiShotCount = 3;
}
import '../base_boss.dart';

/// Abstract base class for boss abilities
abstract class BossAbility {
  /// Called when the phase containing this ability starts
  void onPhaseEnter(BaseBoss boss) {}

  /// Called every frame while the phase is active
  void update(double dt, BaseBoss boss) {}

  /// Called when the phase ends
  void onPhaseExit(BaseBoss boss) {}
}

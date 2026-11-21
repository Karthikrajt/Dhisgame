/// Tunable numbers shared by the battle simulation.
///
/// The battle runs in a fixed virtual world of [worldWidth] x [worldHeight]
/// units. The camera scales it to the device screen, so all gameplay values
/// below are resolution independent.
abstract final class GameConstants {
  static const double worldWidth = 1280;
  static const double worldHeight = 720;

  /// Y coordinate of the floor. Fighter positions are measured at the feet.
  static const double groundY = 590;
  static const double arenaLeft = 80;
  static const double arenaRight = 1200;

  static const double gravity = 2700;
  static const double jumpVelocity = -1180;
  static const double airControl = 0.75;
  static const double groundFriction = 9;

  static const double fighterHalfWidth = 42;
  static const double fighterHeight = 250;

  /// Drawing scale applied to the vector hero artwork in battle.
  static const double fighterArtScale = 1.18;

  /// Minimum horizontal distance kept between two fighters' centres.
  static const double minSeparation = 92;

  static const double maxHealth = 100;
  static const double roundSeconds = 60;

  /// Seconds a fighter cannot be damaged after taking a hit.
  static const double hitInvulnerability = 0.4;

  /// Fraction of damage that still goes through a block.
  static const double blockDamageFactor = 0.15;

  static const double maxEnergy = 100;

  /// Energy gained per second just by playing.
  static const double energyPerSecond = 7;
  static const double energyPerHitDealt = 8;
  static const double energyPerHitTaken = 5;

  /// Length of the "Ready / Fight" intro before control is given.
  static const double introSeconds = 1.8;

  /// Pause after a knockout before the result screen is shown.
  static const double outroSeconds = 2.6;
}

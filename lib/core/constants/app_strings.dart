/// All user-facing text in one place.
///
/// Milestone 4 replaces this with generated ARB-based localizations
/// (English and Tamil). Keeping every string here makes that a mechanical
/// swap rather than a hunt through the widgets.
abstract final class AppStrings {
  static const String appName = 'Superhero Showdown';
  static const String startGame = 'Start Game';
  static const String howToPlay = 'How to Play';
  static const String selectHero = 'Select Your Hero';
  static const String selectOpponent = 'Choose Your Opponent';
  static const String startBattle = 'Start Battle';
  static const String difficulty = 'Difficulty';
  static const String you = 'YOU';
  static const String cpu = 'CPU';
  static const String ready = 'READY?';
  static const String fight = 'FIGHT!';
  static const String knockout = 'K.O.!';
  static const String timeUp = 'TIME!';
  static const String victory = 'VICTORY!';
  static const String defeat = 'Nice Try!';
  static const String draw = 'It\'s a Draw!';
  static const String victoryLine = 'You are a true superhero!';
  static const String defeatLine = 'Heroes never give up. Try again!';
  static const String drawLine = 'What a close match!';
  static const String tryAgain = 'Try Again';
  static const String changeHeroes = 'Change Heroes';
  static const String mainMenu = 'Main Menu';
  static const String paused = 'Paused';
  static const String resume = 'Resume';
  static const String restart = 'Restart';
  static const String close = 'Got it!';
  static const String punch = 'Punch';
  static const String kick = 'Kick';
  static const String block = 'Block';
  static const String jump = 'Jump';

  static const List<String> howToPlaySteps = [
    'Hold the arrow buttons on the left to walk.',
    'Tap the up button to jump.',
    'Tap Punch for a quick hit, Kick for a strong hit.',
    'Hold Block to guard against attacks.',
    'Empty your opponent\'s health bar to win!',
  ];
}

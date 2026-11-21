# Art and audio assets

Milestone 1 ships with **no external asset files**. Everything on screen is
drawn procedurally in Dart, so nothing is missing at runtime, but the items
below are needed to reach the final art and sound targets.

## Currently procedural (to be replaced or upgraded in Milestone 4)

| Item | Current implementation | Target |
| --- | --- | --- |
| Spider Shadow | Vector skeleton renderer (`hero_renderer.dart`) | Sprite sheets per action (idle 4-6, walk 6-8, run 6-8, jump 4-6, punch 4-6, kick 4-6, block 3-4, special 6-10, victory 6-8, hit 3-4 frames) |
| Dark Knight, Solar Man, Thunder Giant, Iron Falcon | Same renderer with their own helmets, emblems, capes and wings | Same sprite sheet set |
| Superpower effects (web, moon dash, sun beam, thunder wave, plasma) | Procedural (`power_effects.dart`) | Effect sprite sheets |
| Neon City Rooftop | Procedural skyline, signs, props, particles | Painted parallax layers (sky, far city, mid city, rooftop, foreground) |
| Hit, block and KO effects | Procedural bursts, ripples and smoke | Effect sprite sheets |
| Portraits | Procedural head render | Painted portrait per hero |
| Title logo | Outlined system font | Designed logo |
| App icon | Flutter default icon | Custom adaptive launcher icon |

## Missing entirely

| Item | Needed for |
| --- | --- |
| Arena music (one loop per arena) | Milestone 4 |
| Menu music | Milestone 4 |
| Punch, kick, block, jump, land, KO sound effects | Milestone 4 |
| UI sounds (button tap, select, VS sting) | Milestone 4 |
| English and Tamil voice lines ("Ready", "Fight", "Victory", "Try again", hero names) | Milestone 4 |
| Display font with Tamil glyph support | Milestone 4 |

## Folder layout reserved for assets

```
assets/
  sprites/heroes/<hero_id>/   one sheet per action
  sprites/enemies/
  sprites/effects/
  backgrounds/<arena_id>/
  audio/music/
  audio/sound_effects/
  audio/voice/en/  audio/voice/ta/
  fonts/
```

All assets must be original or licensed for commercial use, and must not
resemble existing superhero characters, costumes or logos.

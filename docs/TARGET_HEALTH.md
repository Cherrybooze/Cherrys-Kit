# Target HP and percentage

RWA's stock Target health bar shows the target's name on the left, its **HP number at the right end inside the bar**, and its **percentage centred just above the bar** (since rom weakauras 0.9.28). This happens for any bar whose second text is the stock `%v / %t`; another second text keeps the normal bar layout. Rule comparisons and the bar's fill keep the original `value`, `total` and `percent` the game reports.

| Available data | Inside the bar | Above the bar | `%v / %t` in other displays |
| --- | --- | --- | --- |
| Direct HP (players, owned pets) | `3,000` | `75%` | `3,000 / 4,000 (75%)` |
| Monster percentage and a learned maximum | `3,000` | `75%` | `3,000 / 4,000 (75%)` |
| Monster percentage, maximum not learned yet | `?` | `75%` | `? / ? (75%)` |
| No HP or maximum from the game | `?` | `?%` | `? / ? (?%)` |

The percentage follows the game's rule for monsters: rounded down, but never 0 while the target lives, so a nearly full player target reads 99%, not 100%.

## What the client exposes

In the inspected [OneForAll UnitFrame.cpp](https://github.com/Cherrybooze/OneForAll/blob/cdf2d7e58ac0563a1ec2922527837bc4149246b2/SourceCodeVS2019/Client/Ispania_English/Interface/WorldFrames/UnitFrame.cpp):

- `LuaFunc_UnitHealth` returns actual HP for players and owned units. For unowned NPCs it returns an integer percentage, with a minimum of 1 while alive and 0 when dead.
- `LuaFunc_UnitMaxHealth` returns 100 for those unowned NPCs, rather than their absolute maximum HP.
- `LuaFunc_UnitChangeHealth` is **current HP minus last HP**. A unit's last HP starts at 0, so for a monster first seen at full health the change is its whole HP.
- `LuaFunc_UnitIsPlayer` returns `true` for players and **nothing** for every other unit. Before 0.9.28 RWA read that "nothing" as "unknown", so monsters always showed `? / ?`.
- `UnitMaster` can identify owned units whose HP is exposed directly.

This explains why displaying an unowned NPC's raw `UnitHealth / UnitMaxHealth` as HP would be wrong. Client forks may expose different data; installed-client behaviour still needs in-game checks.

## The HP number: pbInfo's method

The number comes the way the original [pbInfo](https://www.curseforge.com/rom/addons/pbinfo) target frame (`Includes/inc.TargetFrame.lua` with `inc.MobDB.lua`) gets it: when a monster is at 100%, `UnitChangeHealth` is remembered as its maximum HP, stored by name, level and class; the HP shown is `maximum × percentage / 100`, rounded up. The project is by p.b. / novayuna and its contributors; its original notices remain with the bundled addon.

RWA keeps its own list of learned maxima for the session, by name, level and class, so a second monster of the same kind already shows a number when you target it hurt. The list holds up to 300 kinds and then starts over. When pbInfo is on, RWA also reads pbInfo's saved MobDB (without calling its updater or writing to it) and uses the larger maximum.

A learned maximum only grows: a heal back to full gives a small change, and that never lowers what was learned. A damage change is never taken as a maximum. Without a learned maximum RWA shows `?`; it does not invent HP. When the game cannot say whether the target is a player (the function is missing or fails), an ambiguous 100-point pool also stays `?`.

The number is an estimate for monsters, as pbInfo's was: the percentage is whole numbers only, and a maximum learned from a heal rather than a fresh monster is too small until a fresh one of that kind is seen.

## Native checks

Compare a player, an owned pet, a fresh monster, the same monster after damage, a second monster of the same kind targeted while hurt, and a dead target. Repeat with pbInfo on and off, change targets quickly, and check monsters with the same name at different levels or classes. Clear the target to confirm the stock aura hides. Check that the percentage sits just above the bar and the HP number inside its right end at different UI and aura scales, and that a custom second text keeps the normal layout.

# Target HP and percentage

RWA's stock Target health display uses `%v / %t` to show a health summary, with the target name on the bar and a full-width HP/percentage line below it. Existing custom text remains editable. Rule comparisons and fill progress keep the original `value`, `total` and `percent` observations.

| Available data | Example display |
| --- | --- |
| Direct HP/max HP | `3000 / 4000 (75%)` |
| Rounded NPC percentage and a learned maximum | `~3000 / 4000 (75%)` |
| NPC percentage with no learned maximum | `? / ? (75%)` |
| Unavailable HP/max APIs | `? / ? (?%)` |

## What the client exposes

In the inspected [OneForAll UnitFrame.cpp](https://github.com/Cherrybooze/OneForAll/blob/cdf2d7e58ac0563a1ec2922527837bc4149246b2/SourceCodeVS2019/Client/Ispania_English/Interface/WorldFrames/UnitFrame.cpp):

- `LuaFunc_UnitHealth` returns actual HP for players and owned units. For unowned NPCs it returns an integer percentage, with a minimum of 1 while alive and 0 when dead.
- `LuaFunc_UnitMaxHealth` returns 100 for those unowned NPCs, rather than their absolute maximum HP.
- `LuaFunc_UnitChangeHealth` is **current HP minus last HP**. It is a change, not a general-purpose maximum/current-HP API.
- `UnitMaster` can identify owned units whose HP is exposed directly.

This explains why displaying an unowned NPC's raw `UnitHealth / UnitMaxHealth` as HP would be wrong. Client forks may expose different data; installed-client behavior still needs in-game checks.

## pbInfo comparison and estimates

Checked the public [pbInfo project](https://www.curseforge.com/rom/addons/pbinfo) and its distributed `pbInfo-0.60-2-g9d3c4cd.zip`, especially `Includes/inc.MobDB.lua`, `inc.Tooltip.lua` and `inc.TargetFrame.lua`. pbInfo learns positive full-health observations, stores maxima by name/level/class, and reconstructs current HP from percentage. The project is by p.b. / novayuna and its contributors; its original notices remain with the bundled addon.

RWA reads an available pbInfo cache without calling its updater or writing its data. It can also retain the largest positive full-health observation for the current identified target. It never treats a partial-health damage delta as max HP or lets a smaller full-health heal shrink an already learned maximum. Target identity/profile changes and target loss discard the per-target estimate.

The `~` prefix is intentional: percentage rounding and an incomplete/old learned maximum can make reconstructed HP inaccurate. A heal alone is not proof of max HP. Without usable data, RWA shows `?`; it does not invent absolute HP. Missing player/NPC classification also leaves an ambiguous 100-point pool unknown.

## Native checks

Compare a player, an owned pet, a fresh NPC, the same NPC after a full-health observation, a previously learned NPC and a dead target. Repeat with pbInfo on/off, change targets rapidly, and check different name/level/class combinations. Clear the target to confirm the stock aura hides. Verify the HP line stays readable at different UI/aura scales and that custom text keeps its chosen layout.

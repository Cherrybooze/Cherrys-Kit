RWA RESOURCE ASSETS v1
Artwork and implementation handoff

STATUS

This pack supplies five transparent PNG artwork masters, reference boards and a
design specification for the accompanying Astra GPT 6.0 Max implementation
prompt. It is not an installed addon or an importable RWA aura profile. Native
TGA/downscaled PNG exports, resource providers, default auras and in-game
validation are integration tasks, not already delivered features.
The source audit used the uploaded CherrysKit 0.11.79 candidate, including
RomWeakAuras 0.9.17 and KittyCombo 1.7.9. Reconcile this guidance with newer work
before making code changes.

DISPLAY RULES

1. Show a resource aura only when that resource is available to the current
   character/build. Availability is separate from the current amount. An active
   resource at zero is valid; an unavailable resource must hide its whole aura.
2. Cover Mana, Rage, Focus, Energy and Warlock PSI/soul points with shared resource
   presets. Use the same tintable artwork for additional class resources once a
   verified provider exists. Do not duplicate the same resource aura once per
   class. This pack does not implement or claim a verified Druid Naturepower
   provider.
3. Bars can use Beveled Metal, Glass or Minimal styling. PSI also offers an
   optional bar. The default PSI presentation remains a number plus diamonds.
4. In the default PSI presentation, an active resource with N points draws the
   number N and exactly N filled diamonds. At zero, draw only the number 0:
   no diamonds, empty slots, ghost diamonds, bar, frame or Max label. This zero
   treatment also applies when the optional PSI bar style is selected.
   If PSI is unavailable, draw nothing, including no zero.
5. At a valid resource maximum, show the separate yellow cartoon-style italic
   "Max" asset. Never show Max for mana. For energy, show Max only out of combat.
   All other supported resources may show Max at their cap, including PSI.
   Entering combat must hide energy's Max immediately even if its value has not
   changed; leaving combat must restore it if energy is still capped.
6. Max requires resource availability, a valid positive capacity and a current
   amount at least that capacity. A missing provider, invalid capacity or 0/0
   must never count as maximum.

RESOURCE IDENTIFICATION

UnitMana/UnitMaxMana are the primary resource slot. UnitSkill/UnitMaxSkill are the
secondary resource slot. Their names do not guarantee which resource they hold.
Identify the resource with UnitManaType/UnitSkillType before reading its value:

  1 = Mana     2 = Rage     3 = Focus     4 = Energy

Search the live primary and secondary slots by type, validate their readings and
capacity, and emit one aura per available resource identity. A valid amount of
zero must not disable the aura. Re-evaluate eligibility on class/build changes.
The reviewed KittyCombo ClassManager already uses these type checks. RWA's
reviewed status.mana and status.skill sources read the two slots directly and
do not yet provide adequate typed-resource availability detection: their shared
resource helper can report show=true even when the capacity is zero.

PSI / SOUL POINTS

Under the standard contract, PSI requires primary class HARPSYN (Warlock).
Verify this eligibility on the target client/server. A secondary Warlock class,
the existence of GetSoulPoint(), or a returned zero does not prove availability.

GetSoulPoint() returns count and STATUS, NOT CAPACITY. The cited example describes
status 0/1/2 as Normal / Willpower Blade / Willpower Construct. Never use status
as the denominator or Max threshold. Prefer a separately verified capacity
provider. KittyCombo's reviewed 0-6 range supplies a fallback of 6 to validate
on the client; no fixed capacity is baked into the artwork.

Repeat the approved diamond sprite using pooled instances. The number and diamond
count use one resource observation; do not create images for individual values.

DELIVERED ARTWORK AND REFERENCES

Exactly five transparent PNG masters are supplied:

  masters/soul-diamond.png       Approved diamond; keep its design unchanged
  masters/max-label.png          Yellow italic cartoon "Max"
  masters/bar-frame-metal.png    Fixed angular beveled metal frame
  masters/bar-fill-bevel.png     Tintable bevel fill
  masters/bar-fill-glass.png     Tintable glass/highlight fill

Reference boards:

  references/resource-defaults.png
  references/bar-styles-and-psi.png

The boards illustrate composition and behavior. Use the individual masters for
runtime textures; do not cut runtime assets or bake values from the boards.

Style composition:

  Beveled Metal = bar-frame-metal + bar-fill-bevel.
  Glass         = bar-fill-glass + a restrained native border.
  Minimal       = existing Square_FullWhite + a thin native border.

Minimal requires no new generated frame or fill asset. Resource colour comes
from the fill tint. Numbers and Max remain independent layers.

EXPORTS TO PRODUCE DURING INTEGRATION

The pack does not yet contain native TGA or downscaled PNG exports. Astra should
prepare those from the supplied masters, preserving alpha and the approved
diamond artwork. Suggested runtime canvases, subject to visual verification:

  soul-diamond       64 x 64       max-label        256 x 128
  bar-frame-metal   512 x 64       bar-fill-bevel   256 x 32
  bar-fill-glass     256 x 32

Use 32-bit RGBA TGA for the established native texture path. Optional downscaled
PNGs are inspection counterparts. Do not mistake these suggested runtime sizes
for the dimensions of the supplied source masters.

RENDERING LAYERS

Compose each bar from a fixed background/frame, a variable fill, native numeric
text and the independently controlled Max label. Decorative end caps stay fixed;
live values are never baked into a texture.

The reviewed RWA renderer resizes the entire fill WIDTH instead of progressively
cropping its texture coordinates. Use stretch-safe fills and fixed frame layers;
otherwise details squash at partial values. Detailed segments would need explicit
crop/segment handling. The candidate has texture/font regions but no dedicated
diamond/pip region. Native text supports value %v or %p, total %t and percent %pct.

IMPLEMENTATION SCOPE AND PERFORMANCE

Reuse small shared textures, cached observations and pooled diamonds. Update on
relevant value, capacity, class, combat or visibility changes; no new broad
framework is needed. Before shipping, verify native alpha/orientation, HUD-scale
legibility, slot selection, active zero versus absence, class changes, PSI
capacity and the mana/energy Max exceptions in game. This pack is not evidence
that those integration checks have already passed.

SOURCE REFERENCES

Repository: https://github.com/Cherrybooze/Cherrys-Kit

Paths below are relative to Interface/AddOns/CherrysKit in the repository:

  RomWeakAuras/Triggers.lua: current resource sources and availability limitation.
  KittyCombo/lib/managers/BuildManager.lua: typed slots and GetSoulPoint wrapper.
  KittyCombo/combo/KittyConditions.lua: reviewed 0-6 soul-point range.
  RomWeakAuras/ClassIcons.lua: canonical class IDs/tokens.
  RomWeakAuras/Engine.lua: current load gates.
  RomWeakAuras/Regions.lua: width-resized bars and native text.
  RomWeakAuras/Widgets.lua: texture-path handling, default .tga extension.
  RomWeakAuras/Media/Textures/Statusbar_Clean.tga and Statusbar_Stripes.tga:
    inspected 256 x 32, 32-bit RGBA TGA examples.

Primary community API examples on the official Gameforge forum:

  https://forum.runesofmagic.gameforge.com/forum/thread/8221-saces-knackzauber-per-makro-und-psi-abfrage/
    Author's post #2, 9 April 2021: local psi_punkte,status = GetSoulPoint();
    describes status 0/1/2 and includes a six-point example. This supports
    distinguishing status from capacity; it does not establish a dynamic cap API.

  https://forum.runesofmagic.gameforge.com/forum/thread/11861-tirasmacros-de-eng/
    Author's post #6 documents primary/secondary resource handling.

These are source-authored community examples, not proof that every custom server
has identical behavior. The supplied artwork does not depend on numeric status
values or a fixed six-point capacity.

design_rules.json records the intended behavior for handoff. It is a design
specification, not a loadable addon configuration or an RWA import string.

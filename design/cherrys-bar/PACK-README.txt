STUDIO PANEL ASSETS
Titan Panel-style artwork pack

PURPOSE

Reusable panel textures, status icons and utility controls based on the asset
roles and compact proportions in the supplied TitanPanel-9.3.5.zip. This is an
artwork pack, not a complete addon or an automatic installer. The uploaded
Titan artwork and software are not included.

CONTENTS

Six material themes: Ironstone, Blacksteel, Froststeel, Darkwood, Verdant and
Arcane. Each has separate Top and Bottom textures.

  Titan/Artwork/Custom/Studio<Theme>/
    TitanPanelBackgroundTop0.tga       256 x 32, RGBA
    TitanPanelBackgroundBottom0.tga    256 x 32, RGBA

  PNG/Skins/<Theme>/256x32/Top.png and Bottom.png
  PNG/Skins/<Theme>/512x64/Top.png and Bottom.png

Sixteen status icons: Bag, Gold, Clock, Location, Performance, Repair,
Regeneration, Mail, Characters, Loot, Ammo, Experience, Storage, Potion, Map
and Guild.

  PNG/Icons/{16|24|32|64|128}/<Name>.png
  TGA/Icons/{16|24|32|64}/<Name>.tga

Twenty utility controls: PinIn, PinOut, Lock, Unlock, Save, SaveDisabled,
Reload, Broom, Plus, Minus, Close, Trash, Run, Resize, TagGreen, TagRed,
TagGold, TagDark, CheckboxOn and CheckboxOff.

  PNG/Controls/{16|24|32|64|128}/<Name>.png
  TGA/Controls/{16|24|32|64}/<Name>.tga

Four volume states: VolumeMute, VolumeLow, VolumeMedium and VolumeHigh.

  PNG/Volume/{32x16|64x32|128x64}/<Name>.png
  TGA/Volume/{32x16|64x32}/<Name>.tga

Braces above describe alternative directories; they are not literal folder
names. Square icon and control sizes are width x height in pixels. Volume
artwork deliberately uses a 2:1 canvas.

The pack also includes source-art atlases and generation prompts, preview
sheets, and an asset manifest. TITAN_MAPPING.txt describes the corresponding
source artwork and intended opt-in paths.

USING A SKIN WITH TITAN PANEL 9.3.5

1. Copy a Studio<Theme> folder from this pack's Titan/Artwork/Custom/ directory
   into the installed Titan/Artwork/Custom/ directory. For Ironstone, the two
   texture files must end up at:

   Interface/AddOns/Titan/Artwork/Custom/StudioIronstone/
     TitanPanelBackgroundTop0.tga
     TitanPanelBackgroundBottom0.tga

2. Open Titan Panel's options and the "Skins - Custom" section. Under "Add New
   Skin", enter a display name such as "Studio Ironstone". In "<Skin Folder>",
   enter StudioIronstone only, then choose "Add Skin". The provided code adds
   the Titan/Artwork/Custom/ prefix itself.

3. Select the registered skin in the relevant bar's skin options and adjust
   its opacity to suit the game scene. Register other themes the same way.

Copying a folder alone does not register a skin. The custom-skin files use the
basenames expected by the supplied version; the general PNG files are for
preview and reuse, not an alternative automatic Titan installation route.

USING ICONS AND CONTROLS

Icons are opt-in assets. Install selected TGA files under your addon's artwork
directory and update that addon's texture references. TITAN_MAPPING.txt gives
suggested counterparts; this pack does not overwrite the existing plugins.

Use the 16 px exports for compact status-bar icons and inspect their appearance
at actual display size. Larger exports are available for scaled interfaces.
The supplied Titan templates normally display icons at 16 px high; the volume
plugin instead uses a 32 x 16 canvas. Keep all four volume states on the same
canvas and anchor to avoid movement when the state changes.

PinIn means a pinned bar; PinOut means auto-hide is enabled. SaveDisabled is
the inactive/no-pending-edits state. Changing artwork does not implement any
state transitions or behavior in the consuming addon.

TEXTURE AND VALIDATION NOTES

The supplied Titan version uses 256 x 32 background files for bars with a
nominal height of 24 px. It loads Top and Bottom separately and requests
texture repetition. The new horizontal strips use mirrored image-generated
material samples so their left and right edge pixels match exactly. Keep
endcaps outside a repeating strip if you build a different panel system.

Matching edge pixels supports horizontal repetition; final scale, filtering,
opacity, visual rhythm and text contrast still need an in-game check. The
artwork has not been tested in a running game client. No addon logic, runtime
integration or performance behavior is supplied or claimed.

REFERENCE

Dimensions, filenames and integration notes were checked against the user's
TitanPanel-9.3.5.zip, especially Titan/Titan.lua (Set_Skin),
Titan/TitanGlobal.lua (bar height), Titan/TitanTemplate.xml (icon dimensions),
Titan/TitanConfig.lua (AddNewSkin), and the individual plugin registrations.

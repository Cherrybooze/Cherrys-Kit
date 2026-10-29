# Emoji pictures in overhead speech bubbles

Cherry's Chat draws emoji pictures in its selectable chat windows. The requested matching pictures in the speech bubbles above players' heads need a client-side hook; **overhead emoji rendering is not implemented by this addon build**.

## Verified client limitation

Inspected the supplied [OneForAll client snapshot](https://github.com/Cherrybooze/OneForAll/tree/cdf2d7e58ac0563a1ec2922527837bc4149246b2/SourceCodeVS2019/Client/Ispania_English):

- [`Interface/WorldFrames/SpeakFrame.cpp`](https://github.com/Cherrybooze/OneForAll/blob/cdf2d7e58ac0563a1ec2922527837bc4149246b2/SourceCodeVS2019/Client/Ispania_English/Interface/WorldFrames/SpeakFrame.cpp): `CSpeakFrame::AddText` constructs unnamed native frames, textures and font strings directly. It owns their five-second lifetime, world-to-screen placement and fading.
- [`netwaker_member/net_talk/NetCli_TalkChild.cpp`](https://github.com/Cherrybooze/OneForAll/blob/cdf2d7e58ac0563a1ec2922527837bc4149246b2/SourceCodeVS2019/Client/Ispania_English/netwaker_member/net_talk/NetCli_TalkChild.cpp): the native bubble is populated before the Say message is sent through the Lua chat event. Decorating that event's text therefore does not replace the existing bubble.
- [`ui/core/ui.cpp`](https://github.com/Cherrybooze/OneForAll/blob/cdf2d7e58ac0563a1ec2922527837bc4149246b2/SourceCodeVS2019/Client/Ispania_English/ui/core/ui.cpp): the Lua-backed creation path makes widget tables, while the native bubble uses its own construction path. The unnamed bubble widgets are not exposed as ordinary addon globals.
- [`ui/core/lua/uiluaframe.cpp`](https://github.com/Cherrybooze/OneForAll/blob/cdf2d7e58ac0563a1ec2922527837bc4149246b2/SourceCodeVS2019/Client/Ispania_English/ui/core/lua/uiluaframe.cpp): the registered frame API does not include child/region enumeration for discovering those bubbles.
- [`ui/core/uifontstring.cpp`](https://github.com/Cherrybooze/OneForAll/blob/cdf2d7e58ac0563a1ec2922527837bc4149246b2/SourceCodeVS2019/Client/Ispania_English/ui/core/uifontstring.cpp): `SetCharData` parses hyperlinks and colour/outline/reset tags; it has no inline image tag. Sending `|T...|t` texture text would not supply emoji pictures to that renderer.

The empty squares in the screenshot are consistent with the native font lacking the emoji glyphs. Cherry's Chat's window overlay can draw separate texture widgets over its own text; it cannot safely attach them to the private native bubbles through the inspected API.

This is a source-inspected limitation, not a claim that a different/custom installed client cannot provide an extension. No new overhead-bubble capability has been validated in game.

## Required client integration

A client bridge would need to expose stable bubble frame/font handles, the current message and creation/update/retirement notifications. Overlay textures could then inherit native placement and fading, and the addon could hide only the replaced text. Retirement notifications must clear references before the native widgets are destroyed or reused.

That bridge is a proposed integration requirement, **not an API present in the inspected client**. The chat text and network message bytes should retain their existing meaning; no shop, targeting or server protocol changes are involved.

## Checks once a bridge is available

1. Say mixed ordinary text, Unicode emoji, shortcode emoji and multiple repeated emoji. Verify wrapping and picture placement.
2. Have two nearby players speak at once. Pictures must remain attached to the correct speaker.
3. Move both players and the camera; test different UI scales and screen edges.
4. Send another message before the five-second bubble expires. Check replacement, sizing and final fade.
5. Let the speaker leave view or the zone, and Reload UI during an active bubble. No stale textures or deleted-widget references should remain.
6. Check native NPC speech and disabling Cherry's Chat; ordinary speech must still render correctly.

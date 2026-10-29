-- Cherry's KittyCombo: Changelog window (what changed since KittyCombo 0.973, bug reports).
--------------------------------------------------------------------------------
-- Create the namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
Kitty.Changelog = {};
-- Where to report bugs (shown on the last page and in the copy box)
Kitty.Changelog.DISCORD_NAME = "cherry";
Kitty.Changelog.DISCORD_SERVER = "the Runes of Magic Discord";
Kitty.Changelog.DISCORD_INVITE = "";
Kitty.Changelog.page = 1;

Kitty.Changelog.getPages = function()
	local contact = Kitty.Changelog.DISCORD_NAME .. " on " .. Kitty.Changelog.DISCORD_SERVER;
	return {
		{
			title = "New in 1.7: modes",
			text = table.concat({
				"- Mode button: Kitty options > Show the mode button. It sits near",
				"  the minimap (right-drag it anywhere, or lock it in the options) and",
				"  shows the mode that is on. Click it to see every mode as a",
				"  picture, click one to switch to it (the others turn off).",
				"- \"Mode is on\" rows pick the mode from a list. Add new mode...",
				"  lets you type a new name. aoe, single, burst, tank, heal,",
				"  interrupt, pvp, dps, farm, boss and request have pictures.",
				"- Request mode (Shift + Kitty macro) is now the mode called",
				"  request: your rows were changed for you. Shift no longer flips",
				"  it; the new condition \"Shift is held\" checks the key instead.",
				"- /kc mode aoe, /kc mode none, /kc mode list (macros work too).",
				"- Show current mode (Kitty options): click it for the mode pictures.",
				"  rom weakauras has a \"KittyCombo mode\" aura too (off at first).",
			}, "\n"),
		},
		{
			title = "New in 1.6",
			text = table.concat({
				"- New look: dark blue windows with gold borders, shared with",
				"  rom weakauras, and the kitty in the corner.",
				"- Every window can be resized: drag the gold corner at the bottom",
				"  right (60% to 160%). Each window remembers its size.",
				"- Easier conditions: plain names (\"Skill is ready\", \"In combat\"),",
				"  yes/no instead of true/false, and one sentence under each row",
				"  saying what it checks. Hover any menu entry for help.",
				"- New conditions:",
				"  Target is casting (interrupts; empty name = a built-in list),",
				"  which you can grow in game: /kc interrupt last (or add <name>),",
				"  Target debuff stacks, Cast in last X sec (no double debuffs),",
				"  Mode is on (switch modes with /kc toggle aoe, also in macros).",
				"- The target debuff count check stops at the last debuff instead",
				"  of asking the game about all 100 slots.",
			}, "\n"),
		},
		{
			title = "What's new for you",
			text = table.concat({
				"Cherry's KittyCombo is based on KittyCombo 0.973 by Miranda.",
				"Your old kitties, the /kc commands and your settings still work.",
				"",
				"- weakaura condition: a kitty command can check any aura you made in",
				"  /rwa (showing or not, time left, stacks, percent, value).",
				"- Priority made clear: every command has a rank number. The top ready",
				"  command fires first.",
				"- Share codes: Export and Import boxes in the kitty editor. Codes are",
				"  short (CKC2), and the editor counts characters and warns when a code",
				"  is too long for one chat line (255).",
				"  The kitty list has an Import button (it replaces Initialization,",
				"  which swapped all your kitties for the defaults without asking).",
				"- Create macro: one click makes a macro for the kitty with a random",
				"  icon, and shows whether one already exists.",
				"- Friendlier menus: hover any entry for a plain-words explanation, and",
				"  menus stay open until you click somewhere else.",
				"- Class icons next to each kitty's class in the list.",
				"- canCast/canUse can also check that something is on cooldown.",
				"- Kitty tracker: rom weakauras can show the next skill a kitty fires.",
			}, "\n"),
		},
		{
			title = "Under the hood",
			text = table.concat({
				"- Lazy skill reads: only skills used by the priority walk are queried.",
				"  Dispatch uses a 0.2 s window; successful-cast gains are unmeasured.",
				"- While you cast, eligible skills and items can still be attempted.",
				"  Conditions and the 1.1 s prediction lookahead retain their meaning.",
				"- Skill book positions and buff lookups are remembered, and refreshed",
				"  when you learn or change skills.",
				"- The damage report skips other players' hits and only adds up damage",
				"  when it is turned on. Fewer game events are watched.",
				"- Removed the automatic party/say chat messages.",
				"- Code cleaned up: all comments in English, big files split by topic.",
				"- Part of Cherry's Kit: install one folder, turn addons on or off with",
				"  /ck.",
				"- /kc probe checks in game that everything works and prints the result.",
				"- Windows keep their spot when you close them or switch between them.",
			}, "\n"),
		},
		{
			title = "Found a bug?",
			text = table.concat({
				"Please tell me! Send a message to",
				contact .. ".",
				"",
				"Helpful to include:",
				"- What you did and what happened (a screenshot helps).",
				"- Any red error text in chat.",
				"- The output of /kc probe.",
				"- For a kitty problem: its Export code from the kitty editor.",
				"",
				"The box below can be copied with Ctrl+C.",
			}, "\n"),
		},
	};
end;

-- Text for the copy box on the bug page
Kitty.Changelog.getContactText = function()
	if(Kitty.Changelog.DISCORD_INVITE ~= "") then
		return Kitty.Changelog.DISCORD_NAME .. "  " .. Kitty.Changelog.DISCORD_INVITE;
	end
	return Kitty.Changelog.DISCORD_NAME;
end;

Kitty.Changelog.open = function()
	Kitty.Changelog.page = 1;
	KittyChangelogFrame:Show();
	Kitty.Changelog.redraw();
end;

Kitty.Changelog.turn = function(delta)
	local count = #Kitty.Changelog.getPages();
	Kitty.Changelog.page = math.max(1, math.min(count, Kitty.Changelog.page + delta));
	Kitty.Changelog.redraw();
end;

Kitty.Changelog.redraw = function()
	local pages = Kitty.Changelog.getPages();
	local page = pages[Kitty.Changelog.page];
	KittyChangelogFrame_TitleLabel:SetText(Kitty.getTitle() .. " - " .. page.title);
	KittyChangelogFrame_BodyLabel:SetText(page.text);
	KittyChangelogFrame_PageLabel:SetText(Kitty.Changelog.page .. " / " .. #pages);
	if(Kitty.Changelog.page == #pages) then
		KittyChangelogFrame_ContactEditBox:SetText(Kitty.Changelog.getContactText());
		KittyChangelogFrame_ContactEditBox:Show();
	else
		KittyChangelogFrame_ContactEditBox:Hide();
	end
	if(Kitty.Changelog.page > 1) then KittyChangelogFrame_PrevButton:Enable(); else KittyChangelogFrame_PrevButton:Disable(); end
	if(Kitty.Changelog.page < #pages) then KittyChangelogFrame_NextButton:Enable(); else KittyChangelogFrame_NextButton:Disable(); end
end;

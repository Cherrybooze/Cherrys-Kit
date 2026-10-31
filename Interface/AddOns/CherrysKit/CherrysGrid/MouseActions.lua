-- Written by tools/mouse_actions.py from the client's Bindings.xml.
-- What each key binding runs. hold: the client runs it on press and on release, with keystate set.
CherrysGrid_MouseActions = {
  MOVEFORWARD = { hold = true, code = [==[if ( keystate == "down" ) then
MoveForwardStart();
else
MoveForwardStop();
end]==] },
  MOVEBACKWARD = { hold = true, code = [==[if ( keystate == "down" ) then
MoveBackwardStart();
else
MoveBackwardStop();
end]==] },
  STRAFELEFT = { hold = true, code = [==[if ( keystate == "down" ) then
StrafeLeftStart();
else
StrafeLeftStop();
end]==] },
  STRAFERIGHT = { hold = true, code = [==[if ( keystate == "down" ) then
StrafeRightStart();
else
StrafeRightStop();
end]==] },
  TURNLEFT = { hold = true, code = [==[if ( keystate == "down" ) then
TurnLeftStart();
else
TurnLeftStop();
end]==] },
  TURNRIGHT = { hold = true, code = [==[if ( keystate == "down" ) then
TurnRightStart();
else
TurnRightStop();
end]==] },
  JUMP = { hold = false, code = [==[Jump();]==] },
  SITORSTAND = { hold = false, code = [==[SitOrStand();]==] },
  TOGGLEAUTORUN = { hold = false, code = [==[ToggleAutoRun();]==] },
  TOGGLERUN = { hold = false, code = [==[ToggleRun();]==] },
  TOGGLESHEATH = { hold = false, code = [==[ToggleSheath();]==] },
  FOLLOWTARGET = { hold = false, code = [==[FollowUnit("target");]==] },
  SCREENSHOT = { hold = false, code = [==[TakeScreenshot();]==] },
  PUSHTOTALK = { hold = true, code = [==[if ( keystate == "down" ) then
VoiceChat_PushToTalk_Start();
PMF_MicIconButton:GetNormalTexture():SetFile( "Interface\\PlayerFrame\\MicIcon_StartSpeak" );
else
VoiceChat_PushToTalk_Stop();
PMF_MicIconButton:GetNormalTexture():SetFile( "Interface\\PlayerFrame\\MicIcon_Normal" );
end]==] },
  TOGGLEBACKPACK = { hold = false, code = [==[ToggleBackpack();]==] },
  TOGGLECHARACTER0 = { hold = false, code = [==[ToggleCharacter("EquipmentFrame");]==] },
  TOGGLECHARACTER1 = { hold = false, code = [==[ToggleCharacter("PracticedFrame");]==] },
  TOGGLECHARACTER2 = { hold = false, code = [==[ToggleCharacter("CCFrame");]==] },
  TOGGLECHARACTER3 = { hold = false, code = [==[ToggleUIFrame( AchievementTitleFrame );]==] },
  TOGGLECHARACTER4 = { hold = false, code = [==[ToggleCharacter("CEFrame");]==] },
  TOGGLECHARACTER5 = { hold = false, code = [==[ToggleCharacter("CharacterClassListFrame");]==] },
  TOGGLESPELLBOOK = { hold = false, code = [==[ToggleUIFrame(UI_SkillBook);]==] },
  TOGGLEQUESTBOOK = { hold = false, code = [==[ToggleUIFrame(UI_QuestBook);]==] },
  TOGGLEGUILD = { hold = false, code = [==[ToggleUIFrame(GuildFrame);]==] },
  TOGGLEINSTANCERECORD = { hold = false, code = [==[ToggleUIFrame(InstanceRecordFrame);]==] },
  TOGGLEPARTERFRAME = { hold = false, code = [==[ToggleUIFrame(PartnerFrame);]==] },
  TOGGLESOCIALFRAME = { hold = false, code = [==[ToggleSocialFrame("Friend");]==] },
  TOGGLEBLACKLISTFRAME = { hold = false, code = [==[ToggleSocialFrame("BadFriend");]==] },
  TOGGLEHATEFRIEND = { hold = false, code = [==[ToggleSocialFrame("HateFriend");]==] },
  TOGGLESEARCHGROUP = { hold = false, code = [==[ToggleSocialFrame("SearchGroup");]==] },
  TOGGLECHARTBOOK = { hold = false, code = [==[ToggleUIFrame(CardBookFrame);]==] },
  TOGGLEBEAUTYSTUDIO = { hold = false, code = [==[if (IsEnableMerchant()) then
ToggleUIFrame(BeautyStudioFrame);
end]==] },
  TOGGLEITEMMALL = { hold = false, code = [==[if ( not IsBattleGroundZone() and IsEnableMerchant() ) then
ToggleUIFrame(ItemMallFrame);
end]==] },
  TOGGLEBULLETINBOARD = { hold = false, code = [==[ToggleUIFrame(BulletinBoard);]==] },
  TOGGLEWORLDMAP = { hold = false, code = [==[ToggleWorldMap();]==] },
  TOGGLEAREAMAP = { hold = false, code = [==[ToggleAreaMap();]==] },
  TOGGLENPCTRACK = { hold = false, code = [==[ToggleUIFrame(NpcTrackFrame);]==] },
  TOGGLETEACHING = { hold = false, code = [==[if ( GetLanguage() ~= "TW" and GetLocation() ~= "TW" ) then
ToggleUIFrame(TeachingFrame);
end]==] },
  TOGGLEGAMEHELP = { hold = false, code = [==[ToggleUIFrame(GameIconFrame);]==] },
  TOGGLESORTSCOREBOARD = { hold = false, code = [==[ToggleUIFrame(SortScoreBoard);]==] },
  TOGGLEDRAWOUTRUNE = { hold = false, code = [==[ToggleUIFrame(DrawRuneFrame);]==] },
  TOGGLESKILLSUIT = { hold = false, code = [==[ToggleUIFrame(SkillSuitFrame);]==] },
  TOGGLETUTORIALEXPLAIN = { hold = false, code = [==[if ( GetLanguage() ~= "TW" and GetLocation() ~= "TW" ) then
ToggleUIFrame(TutorialExplainFrame);
end]==] },
  TOGGLEFPSTEXT = { hold = false, code = [==[if ( FramerateText:IsVisible() ) then
FramerateText:Hide();
else
FramerateText:Show();
end]==] },
  TOGGLEUI = { hold = false, code = [==[if ( UIParent:IsVisible() ) then
CloseAllWindows();
UIParent:Hide();
else
UIParent:Show();
end]==] },
  TOGGLEGAMEMENU = { hold = false, code = [==[if (ToggleMsnWin()==false)then
ToggleGameMenu();
end]==] },
  TOGGLENPCNAME = { hold = false, code = [==[ToggleUI_NPCNAME();]==] },
  TOGGLEHEALTH = { hold = false, code = [==[ToggleUI_ObjectBloodBar();]==] },
  TOGGLEPLATES = { hold = false, code = [==[ToggleUI_TITLE();]==] },
  OPENCHAT = { hold = false, code = [==[ChatEdit_OpenEditBox("");]==] },
  REPLY = { hold = false, code = [==[ChatEdit_ReplyTell();]==] },
  REPEAT = { hold = false, code = [==[ChatEdit_RepeatTell();]==] },
  CHATPAGEUP = { hold = false, code = [==[DEFAULT_CHAT_FRAME:ScrollUp();]==] },
  CHATPAGEDOWN = { hold = false, code = [==[DEFAULT_CHAT_FRAME:ScrollDown();]==] },
  CHATTOP = { hold = false, code = [==[DEFAULT_CHAT_FRAME:ScrollTop();]==] },
  CHATBOTTOM = { hold = false, code = [==[DEFAULT_CHAT_FRAME:ScrollBottom();]==] },
  CHAT_PARTY = { hold = false, code = [==[ChatEditMenu_Party();]==] },
  CHAT_GUILD = { hold = false, code = [==[ChatEditMenu_Guild();]==] },
  CHAT_SAY = { hold = false, code = [==[ChatEditMenu_Say();]==] },
  CHAT_YELL = { hold = false, code = [==[ChatEditMenu_Yell();]==] },
  CHAT_ZONE = { hold = false, code = [==[ChatEditMenu_Zone();]==] },
  MINIMAPZOOMIN = { hold = false, code = [==[MiniMapZoomIn();]==] },
  MINIMAPZOOMOUT = { hold = false, code = [==[MiniMapZoomOut();]==] },
  TARGETNEARESTENEMY = { hold = false, code = [==[TargetNearestEnemy();]==] },
  TARGETPREVIOUSENEMY = { hold = false, code = [==[TargetNearestEnemy(true);]==] },
  TARGETNEARESTFRIEND = { hold = false, code = [==[TargetNearestFriend();]==] },
  TARGETPREVIOUSFRIEND = { hold = false, code = [==[TargetNearestFriend(true);]==] },
  TARGETSELF = { hold = false, code = [==[TargetUnit("player");]==] },
  TARGETPARTY1 = { hold = false, code = [==[TargetUnit("party1");]==] },
  TARGETPARTY2 = { hold = false, code = [==[TargetUnit("party2");]==] },
  TARGETPARTY3 = { hold = false, code = [==[TargetUnit("party3");]==] },
  TARGETPARTY4 = { hold = false, code = [==[TargetUnit("party4");]==] },
  TARGETPARTY5 = { hold = false, code = [==[TargetUnit("party5");]==] },
  TARGETPLAYERPET = { hold = false, code = [==[TargetUnit("playerpet");]==] },
  TARGETPARTY1PET = { hold = false, code = [==[TargetUnit("party1pet");]==] },
  TARGETPARTY2PET = { hold = false, code = [==[TargetUnit("party2pet");]==] },
  TARGETPARTY3PET = { hold = false, code = [==[TargetUnit("party3pet");]==] },
  TARGETPARTY4PET = { hold = false, code = [==[TargetUnit("party4pet");]==] },
  TARGETPARTY5PET = { hold = false, code = [==[TargetUnit("party5pet");]==] },
  ASSISTTARGET = { hold = false, code = [==[AssistUnit("target");]==] },
  RAIDTARGET1 = { hold = false, code = [==[SetRaidTarget("target", 1);]==] },
  RAIDTARGET2 = { hold = false, code = [==[SetRaidTarget("target", 2);]==] },
  RAIDTARGET3 = { hold = false, code = [==[SetRaidTarget("target", 3);]==] },
  RAIDTARGET4 = { hold = false, code = [==[SetRaidTarget("target", 4);]==] },
  RAIDTARGET5 = { hold = false, code = [==[SetRaidTarget("target", 5);]==] },
  RAIDTARGET6 = { hold = false, code = [==[SetRaidTarget("target", 6);]==] },
  RAIDTARGET7 = { hold = false, code = [==[SetRaidTarget("target", 7);]==] },
  RAIDTARGET8 = { hold = false, code = [==[SetRaidTarget("target", 8);]==] },
  ACTIONBAR1BUTTON1 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(1);
else
ActionButtonUp(1);
end]==] },
  ACTIONBAR1BUTTON2 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(2);
else
ActionButtonUp(2);
end]==] },
  ACTIONBAR1BUTTON3 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(3);
else
ActionButtonUp(3);
end]==] },
  ACTIONBAR1BUTTON4 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(4);
else
ActionButtonUp(4);
end]==] },
  ACTIONBAR1BUTTON5 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(5);
else
ActionButtonUp(5);
end]==] },
  ACTIONBAR1BUTTON6 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(6);
else
ActionButtonUp(6);
end]==] },
  ACTIONBAR1BUTTON7 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(7);
else
ActionButtonUp(7);
end]==] },
  ACTIONBAR1BUTTON8 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(8);
else
ActionButtonUp(8);
end]==] },
  ACTIONBAR1BUTTON9 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(9);
else
ActionButtonUp(9);
end]==] },
  ACTIONBAR1BUTTON10 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(10);
else
ActionButtonUp(10);
end]==] },
  ACTIONBAR1BUTTON11 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(11);
else
ActionButtonUp(11);
end]==] },
  ACTIONBAR1BUTTON12 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(12);
else
ActionButtonUp(12);
end]==] },
  ACTIONBAR1BUTTON13 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(13);
else
ActionButtonUp(13);
end]==] },
  ACTIONBAR1BUTTON14 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(14);
else
ActionButtonUp(14);
end]==] },
  ACTIONBAR1BUTTON15 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(15);
else
ActionButtonUp(15);
end]==] },
  ACTIONBAR1BUTTON16 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(16);
else
ActionButtonUp(16);
end]==] },
  ACTIONBAR1BUTTON17 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(17);
else
ActionButtonUp(17);
end]==] },
  ACTIONBAR1BUTTON18 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(18);
else
ActionButtonUp(18);
end]==] },
  ACTIONBAR1BUTTON19 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(19);
else
ActionButtonUp(19);
end]==] },
  ACTIONBAR1BUTTON20 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(20);
else
ActionButtonUp(20);
end]==] },
  ACTIONBAR2BUTTON1 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(21);
else
ActionButtonUp(21);
end]==] },
  ACTIONBAR2BUTTON2 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(22);
else
ActionButtonUp(22);
end]==] },
  ACTIONBAR2BUTTON3 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(23);
else
ActionButtonUp(23);
end]==] },
  ACTIONBAR2BUTTON4 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(24);
else
ActionButtonUp(24);
end]==] },
  ACTIONBAR2BUTTON5 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(25);
else
ActionButtonUp(25);
end]==] },
  ACTIONBAR2BUTTON6 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(26);
else
ActionButtonUp(26);
end]==] },
  ACTIONBAR2BUTTON7 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(27);
else
ActionButtonUp(27);
end]==] },
  ACTIONBAR2BUTTON8 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(28);
else
ActionButtonUp(28);
end]==] },
  ACTIONBAR2BUTTON9 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(29);
else
ActionButtonUp(29);
end]==] },
  ACTIONBAR2BUTTON10 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(30);
else
ActionButtonUp(30);
end]==] },
  ACTIONBAR2BUTTON11 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(31);
else
ActionButtonUp(31);
end]==] },
  ACTIONBAR2BUTTON12 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(32);
else
ActionButtonUp(32);
end]==] },
  ACTIONBAR2BUTTON13 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(33);
else
ActionButtonUp(33);
end]==] },
  ACTIONBAR2BUTTON14 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(34);
else
ActionButtonUp(34);
end]==] },
  ACTIONBAR2BUTTON15 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(35);
else
ActionButtonUp(35);
end]==] },
  ACTIONBAR2BUTTON16 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(36);
else
ActionButtonUp(36);
end]==] },
  ACTIONBAR2BUTTON17 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(37);
else
ActionButtonUp(37);
end]==] },
  ACTIONBAR2BUTTON18 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(38);
else
ActionButtonUp(38);
end]==] },
  ACTIONBAR2BUTTON19 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(39);
else
ActionButtonUp(39);
end]==] },
  ACTIONBAR2BUTTON20 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(40);
else
ActionButtonUp(40);
end]==] },
  ACTIONBAR3BUTTON1 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(41);
else
ActionButtonUp(41);
end]==] },
  ACTIONBAR3BUTTON2 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(42);
else
ActionButtonUp(42);
end]==] },
  ACTIONBAR3BUTTON3 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(43);
else
ActionButtonUp(43);
end]==] },
  ACTIONBAR3BUTTON4 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(44);
else
ActionButtonUp(44);
end]==] },
  ACTIONBAR3BUTTON5 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(45);
else
ActionButtonUp(45);
end]==] },
  ACTIONBAR3BUTTON6 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(46);
else
ActionButtonUp(46);
end]==] },
  ACTIONBAR3BUTTON7 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(47);
else
ActionButtonUp(47);
end]==] },
  ACTIONBAR3BUTTON8 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(48);
else
ActionButtonUp(48);
end]==] },
  ACTIONBAR3BUTTON9 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(49);
else
ActionButtonUp(49);
end]==] },
  ACTIONBAR3BUTTON10 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(50);
else
ActionButtonUp(50);
end]==] },
  ACTIONBAR3BUTTON11 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(51);
else
ActionButtonUp(51);
end]==] },
  ACTIONBAR3BUTTON12 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(52);
else
ActionButtonUp(52);
end]==] },
  ACTIONBAR3BUTTON13 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(53);
else
ActionButtonUp(53);
end]==] },
  ACTIONBAR3BUTTON14 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(54);
else
ActionButtonUp(54);
end]==] },
  ACTIONBAR3BUTTON15 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(55);
else
ActionButtonUp(55);
end]==] },
  ACTIONBAR3BUTTON16 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(56);
else
ActionButtonUp(56);
end]==] },
  ACTIONBAR3BUTTON17 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(57);
else
ActionButtonUp(57);
end]==] },
  ACTIONBAR3BUTTON18 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(58);
else
ActionButtonUp(58);
end]==] },
  ACTIONBAR3BUTTON19 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(59);
else
ActionButtonUp(59);
end]==] },
  ACTIONBAR3BUTTON20 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(60);
else
ActionButtonUp(60);
end]==] },
  ACTIONBAR4BUTTON1 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(61);
else
ActionButtonUp(61);
end]==] },
  ACTIONBAR4BUTTON2 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(62);
else
ActionButtonUp(62);
end]==] },
  ACTIONBAR4BUTTON3 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(63);
else
ActionButtonUp(63);
end]==] },
  ACTIONBAR4BUTTON4 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(64);
else
ActionButtonUp(64);
end]==] },
  ACTIONBAR4BUTTON5 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(65);
else
ActionButtonUp(65);
end]==] },
  ACTIONBAR4BUTTON6 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(66);
else
ActionButtonUp(66);
end]==] },
  ACTIONBAR4BUTTON7 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(67);
else
ActionButtonUp(67);
end]==] },
  ACTIONBAR4BUTTON8 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(68);
else
ActionButtonUp(68);
end]==] },
  ACTIONBAR4BUTTON9 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(69);
else
ActionButtonUp(69);
end]==] },
  ACTIONBAR4BUTTON10 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(70);
else
ActionButtonUp(70);
end]==] },
  ACTIONBAR4BUTTON11 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(71);
else
ActionButtonUp(71);
end]==] },
  ACTIONBAR4BUTTON12 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(72);
else
ActionButtonUp(72);
end]==] },
  ACTIONBAR4BUTTON13 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(73);
else
ActionButtonUp(73);
end]==] },
  ACTIONBAR4BUTTON14 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(74);
else
ActionButtonUp(74);
end]==] },
  ACTIONBAR4BUTTON15 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(75);
else
ActionButtonUp(75);
end]==] },
  ACTIONBAR4BUTTON16 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(76);
else
ActionButtonUp(76);
end]==] },
  ACTIONBAR4BUTTON17 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(77);
else
ActionButtonUp(77);
end]==] },
  ACTIONBAR4BUTTON18 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(78);
else
ActionButtonUp(78);
end]==] },
  ACTIONBAR4BUTTON19 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(79);
else
ActionButtonUp(79);
end]==] },
  ACTIONBAR4BUTTON20 = { hold = true, code = [==[if ( keystate == "down" ) then
ActionButtonDown(80);
else
ActionButtonUp(80);
end]==] },
  PETACTIONBARBUTTON1 = { hold = false, code = [==[UsePetAction(1);]==] },
  PETACTIONBARBUTTON2 = { hold = false, code = [==[UsePetAction(2);]==] },
  PETACTIONBARBUTTON3 = { hold = false, code = [==[UsePetAction(3);]==] },
  PETACTIONBARBUTTON4 = { hold = false, code = [==[UsePetAction(4);]==] },
  PETACTIONBARBUTTON5 = { hold = false, code = [==[UsePetAction(5);]==] },
  PETACTIONBARBUTTON6 = { hold = false, code = [==[UsePetAction(6);]==] },
  PETACTIONBARBUTTON7 = { hold = false, code = [==[UsePetAction(7);]==] },
  PETACTIONBARBUTTON8 = { hold = false, code = [==[UsePetAction(8);]==] },
  PETACTIONBARBUTTON9 = { hold = false, code = [==[UsePetAction(9);]==] },
  PETACTIONBARBUTTON10 = { hold = false, code = [==[UsePetAction(10);]==] },
  EXTRAACTIONBUTTON1 = { hold = true, code = [==[ExtraActionButton_Click( 1, keystate );]==] },
  EXTRAACTIONBUTTON2 = { hold = true, code = [==[ExtraActionButton_Click( 2, keystate );]==] },
  EXTRAACTIONBUTTON3 = { hold = true, code = [==[ExtraActionButton_Click( 3, keystate );]==] },
  EXTRAACTIONBUTTON4 = { hold = true, code = [==[ExtraActionButton_Click( 4, keystate );]==] },
  EXTRAACTIONBUTTON5 = { hold = true, code = [==[ExtraActionButton_Click( 5, keystate );]==] },
  EXTRAACTIONBUTTON6 = { hold = true, code = [==[ExtraActionButton_Click( 6, keystate );]==] },
  EXTRAACTIONBUTTON7 = { hold = true, code = [==[ExtraActionButton_Click( 7, keystate );]==] },
  EXTRAACTIONBUTTON8 = { hold = true, code = [==[ExtraActionButton_Click( 8, keystate );]==] },
  EXTRAACTIONBUTTON9 = { hold = true, code = [==[ExtraActionButton_Click( 9, keystate );]==] },
  EXTRAACTIONBUTTON10 = { hold = true, code = [==[ExtraActionButton_Click( 10, keystate );]==] },
}

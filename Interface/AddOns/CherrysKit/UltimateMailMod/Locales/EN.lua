-- 2021-11-07

-- #############################################################################
-- ##                                                                         ##
-- ##  Language     : English (EN/EU)                                         ##
-- ##  Locale       : EN                                                      ##
-- ##  Last updated : 24 jul 2012                                             ##
-- ##  Origin       : Original default language                               ##
-- ##  Author       : Maxeem of Muinin (DE)                                   ##
-- ##  Credits      : Shardea of Siochain (EN/EU)                             ##
-- ##                                                                         ##
-- #############################################################################

-- General
UMM_TITLE                           = "Ultimate Mail Mod 2";
UMM_PROMPT                          = "UltimateMailMod";
UMM_LOADED                          = " loaded.";

-- Slash settings
UMM_SLASH_HELP1                     = "Help for commands:";
UMM_SLASH_HELP2                     = "/umm sound : toggles audio warning on/off.";
UMM_SLASH_HELP3                     = "/umm reset : resets the list of own characters.";
UMM_SLASH_AUDIODISABLED             = "Audio warning when receiving new mails is now disabled.";
UMM_SLASH_AUDIOENABLED              = "Audio warning when receiving new mails is now enabled.";
UMM_SLASH_CHARSRESET                = "List of own characters has been reset.";

-- New mail notify
UMM_NOTIFY_NEWMAILARRIVED           = "New mail has arrived";
UMM_NOTIFY_TOOLTIP_TITLE            = "New mail";
UMM_NOTIFY_TOOLTIP_NEWMAIL          = "You have new mail waiting.";
UMM_NOTIFY_TOOLTIP_NEWMAILS         = "You have %d new mails waiting.";
UMM_NOTIFY_TOOLTIP_MOVETIP          = "Shift+Right-mouse: move this icon.";

-- Menu tabs
UMM_MENU_TAB1                       = MAIL_INBOX; -- Game default string
UMM_MENU_TAB2                       = MAIL_SENTMAIL; -- Game default string
UMM_MENU_TAB3                       = "Mass Send Items";
-- UMM_MENU_TAB4                       = "Mass Send Mail";

-- Tooltip specific
UMM_TOOLTIP_BOUND                   = "Bound%s";

-- https://forum.runesofmagic.gameforge.com/forum/thread/6231-fixing-umm-to-send-certain-vortis-items/


-- Setting
--UMM_SETTINGS_AUDIOWARNING           = "Sound                       Item-Mehrfachauswahl im Massenversand  [STRG] + [Item] anklicken";	--= "Play a sound when I receive new mails.";
UMM_SETTINGS_AUDIOWARNING           = "Sound                         Selection multiple same items in bulk shipping [STRG or CTRL] + [Item]";	--= "Sound                       Item-Mehrfachauswahl im Massenversand  [STRG] + [Item] anklicken";


-- Inbox
UMM_HELP_INBOX_LINE1                = "You can multi-select mails for :";
UMM_HELP_INBOX_LINE2                = "1) Take items / money /diamonds.";
UMM_HELP_INBOX_LINE3                = "2) Mass return mails.";
UMM_HELP_INBOX_LINE4                = "3) Mass delete mails.";
UMM_HELP_INBOX_LINE5                = "Ctrl + Left-click to tag / untag a mail.";
UMM_HELP_INBOX_RETURNTAGGED         = "Returns all tagged mails.";
UMM_HELP_INBOX_DELETETAGGED         = "Deletes all tagged mails.";

UMM_INBOX_LOADING                   = "Loading inbox - please wait ...";
UMM_INBOX_EMPTY                     = "Your inbox is empty.";

UMM_INBOX_BUTTON_TAGCHARS           = "Chars";
UMM_INBOX_BUTTON_TAGFRIENDS         = "Friends";
UMM_INBOX_BUTTON_TAGGUILDIES        = "Guildies";
UMM_INBOX_BUTTON_TAGOTHER           = "Other";
UMM_INBOX_BUTTON_TAGEMPTY           = "Empty";
UMM_INBOX_BUTTON_TAKE               = "Take";
UMM_INBOX_BUTTON_RETURN             = "Return";
UMM_INBOX_BUTTON_DELETE             = "Delete";

UMM_INBOX_OPTION_1                  = "Everything.";
UMM_INBOX_OPTION_2                  = "Items.";
UMM_INBOX_OPTION_3                  = "Money.";
UMM_INBOX_OPTION_4                  = "Diamonds.";

UMM_INBOX_CHECK_TOOLTIP				= "Enable Tooltip display.";
UMM_INBOX_CHECK_DELETEDONE          = "Delete mails when done taking.";

UMM_INBOX_LABEL_MASSTAG             = "Mass tag mails:";
UMM_INBOX_LABEL_TOTALMONEY          = "Total money in inbox:";
UMM_INBOX_LABEL_TOTALDIAMONDS       = "Total diamonds in inbox:";

UMM_INBOX_STATUS_TAKEALLTAGGED      = "Automatically opening mails - please wait ...";
UMM_INBOX_STATUS_PREPARETAKEDELETE  = "Preparing to delete opened mails - please wait ...";
UMM_INBOX_STATUS_RETURNTAGGED       = "Automatically returning mails - please wait ...";
UMM_INBOX_STATUS_DELETETAGGED       = "Automatically deleting mails - please wait ...";

-- Viewer
UMM_VIEWER_LABEL_FROM               = "From: ";
UMM_VIEWER_LABEL_SUBJECT            = "Subject:";

UMM_VIEWER_BUTTON_REPLY             = "Reply";
UMM_VIEWER_BUTTON_RETURN            = "Return";
UMM_VIEWER_BUTTON_DELETE            = "Delete";
UMM_VIEWER_BUTTON_CLOSE             = "Close";

UMM_VIEWER_ATTACHED                 = "Attached:";
UMM_VIEWER_ATTACHMENTCOD            = "C.O.D. price:";
UMM_VIEWER_ATTACHMENTACCEPT         = "I accept C.O.D.";
UMM_VIEWER_ATTACHMENT_NOT_ACCEPTED  = "Please check accept the C.O.D. and try again.";

-- Composer
UMM_COMPOSER_ADDRESSEE              = "To:";
UMM_COMPOSER_SUBJECT                = "Subject:";
UMM_COMPOSER_BUTTON_RESET           = "Reset";
UMM_COMPOSER_BUTTON_SEND            = "Send";
UMM_COMPOSER_ATTACHMENT             = "Attachment:";
UMM_COMPOSER_AUTOSUBJECT            = "Money: ";
UMM_COMPOSER_SENDGOLD               = "Send Gold";
UMM_COMPOSER_SENDCOD                = "C.O.D.";

UMM_COMPOSER_CONFIRM_TEXT1          = "Are you sure you want to send the amount";
UMM_COMPOSER_CONFIRM_TEXT2          = "shown bellow to %s ?";
UMM_COMPOSER_CONFIRM_YES            = "Yes";
UMM_COMPOSER_CONFIRM_NO             = "No";

UMM_RECIPIENT_OWN                   = "Characters";
UMM_RECIPIENT_FRIEND                = "Friends";
UMM_RECIPIENT_GUILD                 = "Guildies";

-- Mass Send Items

UMM_MSI_MARKBUTTON1                 = "Runes";				--= "Rune";
UMM_MSI_MARKBUTTON2                 = "P. Runes";			--= "P. Rune";
UMM_MSI_MARKBUTTON3                 = "F. Stones";			--= "F. Stein";
UMM_MSI_MARKBUTTON4                 = "M. Stones";				--= "M. Stein";
UMM_MSI_MARKBUTTON5                 = "Gen. Mat.";			--= "Allg. Mat.";
UMM_MSI_MARKBUTTON6                 = "R. Mats.";			--= "R. Mat.";
UMM_MSI_MARKBUTTON7                 = "Foods/Desserts";				--= "Essen";		-- = "Desserts";
UMM_MSI_MARKBUTTON8                 = "Potions";			--= "Trank";
UMM_MSI_MARKBUTTON9 				= "T6 Bag";				--= "T6 Beutel";   = "Bag Stats"; 
UMM_MSI_MARKBUTTON10                = "T6 Clean";			--= "T6 Clean";
UMM_MSI_MARKBUTTON11                = "Danger! T6";			--= "Gefahr! T6";
UMM_MSI_MARKBUTTON12                = "T6 Rest";			--= "T6 Rest";

UMM_MSI_MARKBUTTON13                = "Rec. Alchemy";		--= "Rez. Alche.";
UMM_MSI_MARKBUTTON14                = "Rec. Cooking";		--= "Rez. Koch";
UMM_MSI_MARKBUTTON15                = "Rec. Tailoring.";	--= "Rez. Schn.";
UMM_MSI_MARKBUTTON16                = "Rec. Carpentry";		--= "Rez. Schr.";
UMM_MSI_MARKBUTTON17                = "Rec. Armorcrafting";	--= "Rez. Rüstu.";
UMM_MSI_MARKBUTTON18                = "Rec. Blacksmithing";	--= "Rez. Waffe.";
UMM_MSI_MARKBUTTON19                = "Rec. Others.";		--= "Rez. Sonst.";
UMM_MSI_MARKBUTTON20                = "Ores";				--= "Erz";
UMM_MSI_MARKBUTTON21                = "Wood";				--= "Holz";
UMM_MSI_MARKBUTTON22                = "Herbs";				--= "Kraut";
UMM_MSI_MARKBUTTON23                = "Map";				--= "Karte";
UMM_MSI_MARKBUTTON24 				= "Guild";				--= "Gildemat.";

UMM_MSI_MARKBUTTON25                = "Dark Pets";			--= "Dunkel Ei";
UMM_MSI_MARKBUTTON26                = "Earth Pets";			--= "Erde Ei";
UMM_MSI_MARKBUTTON27                = "Fire Pets";			--= "Feuer Ei";
UMM_MSI_MARKBUTTON28                = "Light Pets";			--= "Licht Ei";
UMM_MSI_MARKBUTTON29                = "Water Pets";			--= "Wasser Ei";
UMM_MSI_MARKBUTTON30                = "Rune Pets";			--= "Rune Ei";
UMM_MSI_MARKBUTTON31 				= "Wind Pets";			--= "Wind Ei";
UMM_MSI_MARKBUTTON32 				= "Dyn.. Cen..";		--= "Dyn. Cene.";
UMM_MSI_MARKBUTTON33 				= "Mys.. Cen..";		--= "Mys. Cene.";
UMM_MSI_MARKBUTTON34 				= "Std.. Cen..";		--= "Weh. Cene.";
UMM_MSI_MARKBUTTON35 				= "TQ-Mat.";			--= "TQ-Mat.";
UMM_MSI_MARKBUTTON36 				= "All Button";			--= "Alle Button";

UMM_MSI_MARKBUTTON37                = "37";
UMM_MSI_MARKBUTTON38                = "38";
UMM_MSI_MARKBUTTON39                = "39";
UMM_MSI_MARKBUTTON40                = "40";
UMM_MSI_MARKBUTTON41 				= "41";
UMM_MSI_MARKBUTTON42 				= "42";
UMM_MSI_MARKBUTTON43 				= "43";
UMM_MSI_MARKBUTTON44 				= "44";
UMM_MSI_MARKBUTTON45 				= "45";
UMM_MSI_MARKBUTTON46 				= "46";
UMM_MSI_MARKBUTTON47 				= "47";
UMM_MSI_MARKBUTTON48 				= "48";



-- MassSendItems.xml → <Button name="$parentSlot29" inherits="UMMMassSendItemsSlotTemplate" id="29" />  einstellen 2x 29

UMM_MSI_MARK_LABEL                  = "Mark:";										--= "Wähle:";
UMM_MSI_MARK_TOOLTIP1               = "Runes";										--= "Rune";
UMM_MSI_MARK_TOOLTIP2               = "Production Runes";							--= "Produktionsrune";
UMM_MSI_MARK_TOOLTIP3               = "Fusion Stones";								--= "Fusionssteine";
UMM_MSI_MARK_TOOLTIP4               = "Manastones";									--= "Manasteine";
UMM_MSI_MARK_TOOLTIP5               = "General Material, Companion Food, Relationship, Sphere";							--= "Allgemeines Material, Begleiter-Futter, Beziehung, Sphäre" ;
UMM_MSI_MARK_TOOLTIP6               = "Raw Materials, Tools, Processed Goods";		--= "Rohmaterial, Werkzeug, Verarbeitete Güter";
UMM_MSI_MARK_TOOLTIP7               = "Foods and Desserts";							--= "Nahrung und Nachspeise";
UMM_MSI_MARK_TOOLTIP8               = "Potions";									--= "Trank";
UMM_MSI_MARK_TOOLTIP9				= "T6 pouch Items only / Bag Stat Items T6";	--= "Nur T6-Beutel-Item";
UMM_MSI_MARK_TOOLTIP10              = "Clean T6 Items only";						--= "Nur cleane T6-Item";
UMM_MSI_MARK_TOOLTIP11              = "CAUTION! T6-Items Clean (Ini), with ability or bound (quest reward → CANCEL when sending)";		--= "ACHTUNG!   T6-Item clean (Ini), mit Fähigkeit oder Gebunden (Questbelohnung → ABBRUCH beim Senden)";
UMM_MSI_MARK_TOOLTIP12              = "T6 items with ability only";					--= "Nur T6-Item mit Fähigkeit";

UMM_MSI_MARK_TOOLTIP13              = "Alchemy Recipes";							--= "Rezept für Alchemist";
UMM_MSI_MARK_TOOLTIP14              = "Cooking Recipes";							--= "Rezept für Koch";
UMM_MSI_MARK_TOOLTIP15              = "Tailoring Recipes";							--= "Rezept für Schneider";
UMM_MSI_MARK_TOOLTIP16              = "Carpentry Recipes";							--= "Rezept für Schreiner";
UMM_MSI_MARK_TOOLTIP17              = "Armorcrafting Recipes";						--= "Rezept für Rüstungsschmied";
UMM_MSI_MARK_TOOLTIP18				= "Blacksmithing Recipes";						--= "Rezept für Waffenschmied";
UMM_MSI_MARK_TOOLTIP19				= "Recipe Violet + for Furniture, Jewelry, General, Questitems ... (in progress)";		--= "Rezept Violett + für Möbel, Schmuck, Allgemein, Questgegenstände... (in Arbeit)";
UMM_MSI_MARK_TOOLTIP20				= "Ores";					--= "Erz";
UMM_MSI_MARK_TOOLTIP21				= "Wood";					--= "Holz";
UMM_MSI_MARK_TOOLTIP22				= "Herbs";					--= "Kraut";
UMM_MSI_MARK_TOOLTIP23				= "Map";					--= "Karte";
UMM_MSI_MARK_TOOLTIP24				= "Guild Contribution";		--= "Gildenbeitrag";

UMM_MSI_MARK_TOOLTIP25				= "Dark Pet Eggs";			--= "Dunkel-Begleiter-Ei";
UMM_MSI_MARK_TOOLTIP26				= "Earth Pet Eggs";			--= "Erde-Begleiter-Ei";
UMM_MSI_MARK_TOOLTIP27				= "Fire Pet Eggs";			--= "Feuer-Begleiter-Ei";
UMM_MSI_MARK_TOOLTIP28				= "Light Pet Eggs";			--= "Licht-Begleiter-Ei";
UMM_MSI_MARK_TOOLTIP29				= "Water Pet Eggs";			--= "Wasser-Begleiter-Ei";
UMM_MSI_MARK_TOOLTIP30				= "Rune Pet Eggs";			--= "Rune-Begleiter-Ei";
UMM_MSI_MARK_TOOLTIP31				= "Wind Pet Eggs";			--= "Wind-Begleiter-Ei";
UMM_MSI_MARK_TOOLTIP32				= "Dynamic Cenedril";		--= "Dynamisches Cenedril Material";
UMM_MSI_MARK_TOOLTIP33				= "Mystical Cenedril";		--= "Mystisches Cenedril Material";
UMM_MSI_MARK_TOOLTIP34				= "Steadfast Cenedril";		--= "Wehrhaftes Cenedril Material";
UMM_MSI_MARK_TOOLTIP35				= "Daily Quest Materials";	--= "Material für Tagesquest";
UMM_MSI_MARK_TOOLTIP36				= "All Buttons are used";	--= "Alle Button werden benutzt";

UMM_MSI_MARK_TOOLTIP37				= "37";
UMM_MSI_MARK_TOOLTIP38				= "38";
UMM_MSI_MARK_TOOLTIP39				= "39";
UMM_MSI_MARK_TOOLTIP40				= "40";
UMM_MSI_MARK_TOOLTIP41				= "41";
UMM_MSI_MARK_TOOLTIP42				= "42";
UMM_MSI_MARK_TOOLTIP43				= "43";
UMM_MSI_MARK_TOOLTIP44				= "44";
UMM_MSI_MARK_TOOLTIP45				= "45";
UMM_MSI_MARK_TOOLTIP46				= "46";
UMM_MSI_MARK_TOOLTIP47				= "47";
UMM_MSI_MARK_TOOLTIP48				= "48";



UMM_MSI_MARK_TOOLTIPCLICK           = "Click to mark all slots of items in this category.";

UMM_MSI_BUTTON_ADDRESSEE            = "To:";
UMM_MSI_BUTTON_RESET                = "Reset";

UMM_MSI_MAILSTOSEND                 = "Mails to send: %d";
UMM_MSI_ADDRESSEE                   = "To:";
UMM_MSI_SUBJECT                     = "Subject:";
UMM_MSI_COD                         = "C.O.D.";
UMM_MSI_STATUS                      = "Status:";
UMM_MSI_STATUS_SENDING              = "Sending...";
UMM_MSI_STATUS_QUEUED               = "Queued.";
UMM_MSI_BUTTON_SEND                 = "Send";
UMM_MSI_BUTTON_COD                  = "C.O.D.";
UMM_MSI_BUTTON_CANCEL               = "Cancel";
UMM_MSI_SEND_STATUS                 = "Sending %d of %d - please wait ...";
UMM_MSI_SEND_MAILBODY               = "Hi %s\n\nI used Ultimate Mail Mod to send this item to you.\n\nPlease enjoy.\n\nKind regards\n%s\n\n%s";



-- Error messages

UMM_ERROR_CANTSENDSELF              = "You can not send mails to yourself.";
UMM_ERROR_NOSUBJECT                 = "Please enter a subject for this mail.";
UMM_ERROR_CANTSENDBOUND             = "You can not send bound items.";

UMM_ERROR_AUTOMATIONFAILED          = "Automation process failed - process halted.";
UMM_ERROR_NOTHINGTAGGED             = "Please tag one or more mails !";
UMM_ERROR_CANTDELETE                = "Unable to delete mails with attachments !";
UMM_ERROR_CANTRETURN                = "Unable to return mail !";
UMM_ERROR_CANTTAKECOD               = "C.O.D. mails can not be auto-taken !";
UMM_ERROR_CANTTAKE                  = "Tagged mail does not meet required take conditions !";

-- Emoji as symbols the RoM chat font can draw. In game (2026-10-26) 4-byte emoji showed as two
-- boxes, but U+2764 and U+2600 came out as heart and sun outlines, so the font has many symbols
-- of the Basic Multilingual Plane. Faces use ASCII faces, which always draw.
-- Each entry: shortcode = { text, colour (RRGGBB) }. Emoji not listed here show as :shortcode:.

local GOLD, RED, PINK, BLUE, GREEN, WHITE, GREY = "ffd100", "ff4040", "ff7fa8", "60a0ff", "60e060", "ffffff", "a0a0a0"
local function u(text, colour)
  return { text, colour or GOLD }
end

CherrysChat_Symbols = {
  -- faces
  grinning = u("(^_^)"), smiley = u("(^o^)"), smile = u("(^_^)"), grin = u("(^v^)"), laughing = u("XD"),
  sweat_smile = u("(^_^;)"), rofl = u("XD"), joy = u("(T_T)XD"), slight_smile = u(":)"), upside_down = u("(:"),
  wink = u("(^_~)"), blush = u("(^///^)", PINK), innocent = u("O:)"), smiling_hearts = u("(^_^)\226\153\165", PINK),
  heart_eyes = u("(\226\153\165_\226\153\165)", PINK), star_struck = u("(\226\152\133_\226\152\133)"),
  kissing_heart = u(":*", PINK), yum = u("(^p^)"), stuck_out_tongue = u(":P"), stuck_out_tongue_winking_eye = u(";P"),
  zany = u("(@_~)"), money_mouth = u("($_$)"), hugs = u("(>^_^)>"), hand_over_mouth = u("(^m^)"), shush = u("(-_-)/"),
  thinking = u("(._.)?"), zipper_mouth = u(":X"), raised_eyebrow = u("(o_O)"), neutral = u(":|"),
  expressionless = u("(-_-)"), no_mouth = u("(._.)"), smirk = u("(-_^)"), unamused = u("(-_-)"), roll_eyes = u("(9_9)"),
  grimacing = u("(>_<)"), relieved = u("(^_^)~"), pensive = u("(._.)"), sleepy = u("(-_-)zz"), drooling = u("(*q*)"),
  sleeping = u("(-_-)zzz"), mask = u("(x_x)"), thermometer_face = u("(x_x)"), nauseated = u("(@_@)", GREEN),
  vomiting = u("(x_x)", GREEN), sneezing = u("(>o<)"), hot = u("(;_;)", RED), cold = u("(;_;)", BLUE), woozy = u("(@_@)"),
  dizzy_face = u("(@_@)"), exploding_head = u("(*_*)"), cowboy = u("(^_^)"), partying = u("\\(^o^)/"),
  sunglasses = u("B)"), nerd = u("(8-)"), confused = u(":/"), worried = u("(._.)"), slight_frown = u(":("),
  frowning = u(":("), open_mouth = u(":O"), astonished = u("(O_O)"), flushed = u("(O///O)", PINK), pleading = u("(;w;)"),
  fearful = u("(O_O;)"), cold_sweat = u("(._.;)"), cry = u("(;_;)", BLUE), sob = u("(T_T)", BLUE), scream = u("(O_O)!"),
  confounded = u("(>_<)"), persevere = u("(>_<)"), disappointed = u("(._.)"), sweat = u("(-_-;)"), weary = u("(>_<)"),
  tired_face = u("(=_=)"), yawning = u("(-o-)"), triumph = u("(`^')"), rage = u("(>_<)#", RED), angry = u("(>_<)", RED),
  cursing = u("(#@!)", RED), smiling_imp = u(">:)", "c060ff"), imp = u(">:(", "c060ff"),
  skull = u("\226\152\160", WHITE), clown = u("(o.O)"), robot = u("[o_o]", GREY),
  smiley_cat = u("(=^.^=)"), heart_eyes_cat = u("(=\226\153\165.\226\153\165=)", PINK), rofl_cat = u("(=^o^=)"),
  see_no_evil = u("(>_<)"), salute = u("(^_^)7"), melting = u("(._.)~"),
  -- hearts
  heart = u("\226\153\165", RED), orange_heart = u("\226\153\165", "ff9020"), yellow_heart = u("\226\153\165", "ffe040"),
  green_heart = u("\226\153\165", GREEN), blue_heart = u("\226\153\165", BLUE), purple_heart = u("\226\153\165", "c060ff"),
  black_heart = u("\226\153\165", "606060"), white_heart = u("\226\153\161", WHITE), broken_heart = u("</3", RED),
  two_hearts = u("\226\153\165\226\153\165", PINK), sparkling_heart = u("\226\153\165", PINK),
  heartpulse = u("\226\153\165", PINK), cupid = u("\226\153\165", PINK), love_letter = u("\226\156\137\226\153\165", PINK),
  heart_hands = u("<3", PINK), kiss = u(":*", RED),
  -- hands
  v = u("\226\156\140"), point_up = u("\226\152\157"), point_right = u("\226\152\158"), point_left = u("\226\152\156"),
  point_down = u("\226\134\147"), thumbsup = u("(b^_^)b"), thumbsdown = u("(-_-)p"), wave = u("(^_^)/"),
  clap = u("*clap*"), pray = u("(_/\\_)"), muscle = u("(9`_`)9"), ok_hand = u("(^_^)ok"), raised_hands = u("\\(^_^)/"),
  -- things
  star = u("\226\152\133"), star2 = u("\226\152\133"), sparkles = u("\226\156\167"), dizzy = u("\226\156\167"),
  sunny = u("\226\152\128", "ffb000"), cloud = u("\226\152\129", WHITE), snowflake = u("\226\157\132", "a0e0ff"),
  zap = u("\226\154\161"), crescent_moon = u("\226\152\190"), musical_note = u("\226\153\170"), notes = u("\226\153\170\226\153\170"),
  check = u("\226\156\148", GREEN), heavy_check_mark = u("\226\156\148", GREEN), x = u("\226\156\152", RED),
  warning = u("\226\154\160"), crossed_swords = u("\226\154\148", WHITE), crown = u("\226\153\155"),
  gem = u("\226\153\166", "60e0ff"), coffee = u("\226\152\149", "c08040"), cherry_blossom = u("\226\156\191", PINK),
  rose = u("\226\157\128", RED), sunflower = u("\226\157\128"), hourglass = u("\226\140\155"), gear = u("\226\154\153", GREY),
  arrow_up = u("\226\134\145", WHITE), arrow_down = u("\226\134\147", WHITE), arrow_left = u("\226\134\144", WHITE),
  arrow_right = u("\226\134\146", WHITE), question = u("?", RED), exclamation = u("!", RED), ["100"] = u("100", RED),
  fire = u("*fire*", "ff8020"), tada = u("\\(^o^)/"), zzz = u("zzz", BLUE),
  cat = u("(=^.^=)"), dog = u("(U^w^U)"), skull_crossbones = u("\226\152\160", WHITE),
}

-- Every symbol used above, for /cchat symbols: the ones that show as boxes get swapped out.
CherrysChat_SymbolTest = {
  "\226\153\165", "\226\153\161", "\226\152\133", "\226\156\167", "\226\152\128", "\226\152\129", "\226\157\132",
  "\226\154\161", "\226\152\190", "\226\153\170", "\226\153\171", "\226\156\148", "\226\156\152", "\226\154\160",
  "\226\154\148", "\226\153\155", "\226\153\166", "\226\152\149", "\226\156\191", "\226\157\128", "\226\140\155",
  "\226\154\153", "\226\134\145", "\226\134\147", "\226\134\144", "\226\134\146", "\226\152\160", "\226\156\140",
  "\226\152\157", "\226\152\158", "\226\152\156", "\226\156\137",
}

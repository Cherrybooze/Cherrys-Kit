-- 2021-11-07


local ResourceItemFilter = {
  
  ItemDB = {};
  
  priv_AddDB = function(self, type, itemID)
    if (not self.ItemDB[type]) then
      self.ItemDB[type] = {};
    end
    self.ItemDB[type][itemID] = true;
  end;
  
  Init = function(self)
    self.ItemDB = nil;
    self.ItemDB = {};
  end;
  
  IsItem = function(self, type, itemLink)
    if (self.ItemDB[type]) then
      local itemkind, itemData, itemName = ParseHyperlink(itemLink);
      local _, _, itemID = string.find(itemData, "^(%x+)");
      itemID = tonumber(itemID, 16); --max item id is 16 characters long
      if (self.ItemDB[type][itemID]) then
        --DEFAULT_CHAT_FRAME:AddMessage("1");
        return true;
      else
        --DEFAULT_CHAT_FRAME:AddMessage("2");
        return nil;
      end
    else
        --DEFAULT_CHAT_FRAME:AddMessage("0");
      return nil;
    end
  end;
  
  
--[[  
  GetTypeByID = function(self, id)
    local result = "None";
    if (id == 1) then
      result = "Runes";
    elseif (id == 2) then
      result = "FusionStones";
    elseif (id == 3) then
      result = "Juwels";
    elseif (id == 4) then
      result = "Ores";
    elseif (id == 5) then
      result = "Wood";
    elseif (id == 6) then
      result = "Herbs";
    elseif (id == 7) then
      result = "RawMaterials";
    elseif (id == 8) then
      result = "ProductionRunes";
    elseif (id == 9) then
      result = "Foods";
    elseif (id == 10) then
      result = "Desserts";
    elseif (id == 11) then
      result = "Potions";
    elseif (id == 12) then
      result = "WRecipes";		-- release 5.0.1.2553
    elseif (id == 13) then
      result = "GRecipes";		-- release 5.0.1.2553
    elseif (id == 14) then
      result = "BRecipes";		-- release 5.0.1.2553
    elseif (id == 15) then
      result = "MRecipes";		-- release 5.0.1.2553
    elseif (id == 16) then
      result = "Guild";			-- release 5.0.0.2545
    elseif (id == 17) then    
      result = "BagStat";       -- release 6.4.1.2752
    elseif (id == 18) then    
      result = "RunePetEgg";       -- release 6.4.1.2769
    elseif (id == 19) then    
      result = "EarthPetEgg";       -- release 6.4.1.2769
    elseif (id == 20) then    
      result = "WaterPetEgg";       -- release 6.4.1.2769
    elseif (id == 21) then    
      result = "FirePetEgg";       -- release 6.4.1.2769
    elseif (id == 22) then    
      result = "WindPetEgg";       -- release 6.4.1.2769
    elseif (id == 23) then    
      result = "lightPetEgg";       -- release 6.4.1.2769
    elseif (id == 24) then
      result = "DarkPetEgg";       -- release 6.4.1.2769
    elseif (id == 25) then
      result = "DynamicCenedril";       -- release 6.4.1.2769
    elseif (id == 26) then
      result = "SteadfastCenedril";       -- release 6.4.1.2769
    elseif (id == 27) then
      result = "MysticalCenedril";       -- release 6.4.1.2769
	elseif (id == 28) then
      result = "allitems";       -- release 6.4.1.2769
	  elseif (id == 29) then
	  result = "T6clean";
	  	  elseif (id == 30) then
	  result = "T6";
    end
    return result;
  end;
  
};
--]]

  GetTypeByID = function(self, id)
    local result = "None";
    if (id == 1) then
      result = "Runes";
    elseif (id == 2) then
      result = "ProductionRunes";
    elseif (id == 3) then
      result = "FusionStones";
    elseif (id == 4) then
      result = "ManaStones";
    elseif (id == 5) then
      result = "GeneralMaterials";
    elseif (id == 6) then
      result = "RawMaterials";
    elseif (id == 7) then
      result = "FoodsDesserts";
    elseif (id == 8) then
      result = "Potions";
    elseif (id == 9) then
      result = "BagStat";	  
    elseif (id == 10) then
      result = "T6clean";
    elseif (id == 11) then
      result = "T698er";
    elseif (id == 12) then
      result = "T6";
	  
    elseif (id == 13) then
      result = "RecipesAlchemist";
    elseif (id == 14) then
      result = "RecipesCook";
    elseif (id == 15) then
      result = "RecipesCutter";
    elseif (id == 16) then
      result = "RecipesCarpenter";
    elseif (id == 17) then
      result = "RecipesArmorsmith";
    elseif (id == 18) then    
      result = "RecipesWeaponsmith";
    elseif (id == 19) then    
      result = "RecipesOther";
	elseif (id == 20) then    
      result = "Ores";
    elseif (id == 21) then    
      result = "Wood";
    elseif (id == 22) then    
      result = "Herbs";
    elseif (id == 23) then    
      result = "Cards";
    elseif (id == 24) then
      result = "Guild";	  
	  	  
    elseif (id == 25) then    
      result = "DarkPetEgg";
    elseif (id == 26) then
      result = "EarthPetEgg";
    elseif (id == 27) then
      result = "FirePetEgg";
    elseif (id == 28) then
      result = "LightPetEgg";
    elseif (id == 29) then
      result = "WaterPetEgg";
	elseif (id == 30) then
      result = "RunePetEgg";
	elseif (id == 31) then
	  result = "WindPetEgg";
	elseif (id == 32) then
	  result = "DynamicCenedril";
	elseif (id == 33) then
	  result = "MysticalCenedril";
	elseif (id == 34) then
	  result = "SteadfastCenedril";
	elseif (id == 35) then
	  result = "TQMaterials";
	elseif (id == 36) then
	  result = "AllItems"; 
	  

    elseif (id == 37) then
      result = "Runes";
    elseif (id == 38) then
      result = "ProductionRunes";
    elseif (id == 39) then
      result = "WaterPetEgg";
	elseif (id == 40) then
      result = "RunePetEgg";
	elseif (id == 41) then
	  result = "WindPetEgg";
	elseif (id == 42) then
	  result = "DynamicCenedril";
	elseif (id == 43) then
	  result = "MysticalCenedril";
	elseif (id == 44) then
	  result = "SteadfastCenedril";
	elseif (id == 45) then
	  result = "TQMaterials";
	elseif (id == 46) then
	  result = "AllItems"; 	  
	elseif (id == 47) then
	  result = "TQMaterials";
	elseif (id == 48) then
	  result = "ProductionRunes"; 		  
	  
	  
	  
	  

	  
    end
    return result;
  end;
  
};


local function priv_AddProductionRunes(db)	-- P. Runen
  -- Purple
  db:priv_AddDB("ProductionRunes", 201086); -- Advanced Skill Reset Stone
  db:priv_AddDB("ProductionRunes", 202088); -- Bag of Activate-Runes
  db:priv_AddDB("ProductionRunes", 202091); -- Bag of Blend-Runes
  db:priv_AddDB("ProductionRunes", 202089); -- Bag of Disenchant-Runes
  db:priv_AddDB("ProductionRunes", 202087); -- Bag of Frost-Runes
  db:priv_AddDB("ProductionRunes", 202086); -- Bag of Link-Runes
  db:priv_AddDB("ProductionRunes", 202090); -- Bag of Purify-Runes
  db:priv_AddDB("ProductionRunes", 201971); -- Basic Skill Reset Stone
  db:priv_AddDB("ProductionRunes", 203035); -- Skill Reset Rune
  -- White
  db:priv_AddDB("ProductionRunes", 200852); -- Activate Rune
  db:priv_AddDB("ProductionRunes", 200855); -- Blend Rune
  db:priv_AddDB("ProductionRunes", 200856); -- Day & Night Rune
  db:priv_AddDB("ProductionRunes", 200853); -- Disenchant Rune
  db:priv_AddDB("ProductionRunes", 200851); -- Frost Rune
  db:priv_AddDB("ProductionRunes", 200850); -- Link Rune
  db:priv_AddDB("ProductionRunes", 200854); -- Purify Rune
  db:priv_AddDB("ProductionRunes", 200857); -- Season Rune
  db:priv_AddDB("ProductionRunes", 200858); -- Years Rune
end

local function priv_AddRunes(db)	-- Runen

  db:priv_AddDB("Runes", 520021); -- Power I
  db:priv_AddDB("Runes", 520022); -- Power II
  db:priv_AddDB("Runes", 520023); -- Power III
  db:priv_AddDB("Runes", 520024); -- Power IV
  db:priv_AddDB("Runes", 520025); -- Power V
  db:priv_AddDB("Runes", 520026); -- Power VI
  db:priv_AddDB("Runes", 520027); -- Power VII
  db:priv_AddDB("Runes", 520028); -- Power VIII
  db:priv_AddDB("Runes", 520029); -- Power IX
  db:priv_AddDB("Runes", 520030); -- Power X
  db:priv_AddDB("Runes", 520041); -- Resistance I
  db:priv_AddDB("Runes", 520042); -- Resistance II
  db:priv_AddDB("Runes", 520043); -- Resistance III
  db:priv_AddDB("Runes", 520044); -- Resistance IV
  db:priv_AddDB("Runes", 520045); -- Resistance V
  db:priv_AddDB("Runes", 520046); -- Resistance VI
  db:priv_AddDB("Runes", 520047); -- Resistance VII
  db:priv_AddDB("Runes", 520048); -- Resistance VIII
  db:priv_AddDB("Runes", 520049); -- Resistance IX
  db:priv_AddDB("Runes", 520050); -- Resistance X
  db:priv_AddDB("Runes", 520061); -- Mind I
  db:priv_AddDB("Runes", 520062); -- Mind II
  db:priv_AddDB("Runes", 520063); -- Mind III
  db:priv_AddDB("Runes", 520064); -- Mind IV
  db:priv_AddDB("Runes", 520065); -- Mind V
  db:priv_AddDB("Runes", 520066); -- Mind VI
  db:priv_AddDB("Runes", 520067); -- Mind VII
  db:priv_AddDB("Runes", 520068); -- Mind VIII
  db:priv_AddDB("Runes", 520069); -- Mind IX
  db:priv_AddDB("Runes", 520070); -- Mind X
  db:priv_AddDB("Runes", 520081); -- Vitality I
  db:priv_AddDB("Runes", 520082); -- Vitality II
  db:priv_AddDB("Runes", 520083); -- Vitality III
  db:priv_AddDB("Runes", 520084); -- Vitality IV
  db:priv_AddDB("Runes", 520085); -- Vitality V
  db:priv_AddDB("Runes", 520086); -- Vitality VI
  db:priv_AddDB("Runes", 520087); -- Vitality VII
  db:priv_AddDB("Runes", 520088); -- Vitality VIII
  db:priv_AddDB("Runes", 520089); -- Vitality IX
  db:priv_AddDB("Runes", 520090); -- Vitality X
  db:priv_AddDB("Runes", 520101); -- Quickness I
  db:priv_AddDB("Runes", 520102); -- Quickness II
  db:priv_AddDB("Runes", 520103); -- Quickness III
  db:priv_AddDB("Runes", 520104); -- Quickness IV
  db:priv_AddDB("Runes", 520105); -- Quickness V
  db:priv_AddDB("Runes", 520106); -- Quickness VI
  db:priv_AddDB("Runes", 520107); -- Quickness VII
  db:priv_AddDB("Runes", 520108); -- Quickness VIII
  db:priv_AddDB("Runes", 520109); -- Quickness IX
  db:priv_AddDB("Runes", 520110); -- Quickness X
  db:priv_AddDB("Runes", 520121); -- Endurance I
  db:priv_AddDB("Runes", 520122); -- Endurance II
  db:priv_AddDB("Runes", 520123); -- Endurance III
  db:priv_AddDB("Runes", 520124); -- Endurance IV
  db:priv_AddDB("Runes", 520125); -- Endurance V
  db:priv_AddDB("Runes", 520126); -- Endurance VI
  db:priv_AddDB("Runes", 520127); -- Endurance VII
  db:priv_AddDB("Runes", 520128); -- Endurance VIII
  db:priv_AddDB("Runes", 520129); -- Endurance IX
  db:priv_AddDB("Runes", 520130); -- Endurance X
  db:priv_AddDB("Runes", 520141); -- Magic I
  db:priv_AddDB("Runes", 520142); -- Magic II
  db:priv_AddDB("Runes", 520143); -- Magic III
  db:priv_AddDB("Runes", 520144); -- Magic IV
  db:priv_AddDB("Runes", 520145); -- Magic V
  db:priv_AddDB("Runes", 520146); -- Magic VI
  db:priv_AddDB("Runes", 520147); -- Magic VII
  db:priv_AddDB("Runes", 520148); -- Magic VIII
  db:priv_AddDB("Runes", 520149); -- Magic IX
  db:priv_AddDB("Runes", 520150); -- Magic X
  db:priv_AddDB("Runes", 520161); -- Harm I
  db:priv_AddDB("Runes", 520162); -- Harm II
  db:priv_AddDB("Runes", 520163); -- Harm III
  db:priv_AddDB("Runes", 520164); -- Harm IV
  db:priv_AddDB("Runes", 520165); -- Harm V
  db:priv_AddDB("Runes", 520166); -- Harm VI
  db:priv_AddDB("Runes", 520167); -- Harm VII
  db:priv_AddDB("Runes", 520168); -- Harm VIII
  db:priv_AddDB("Runes", 520169); -- Harm IX
  db:priv_AddDB("Runes", 520170); -- Harm X
  db:priv_AddDB("Runes", 520181); -- Strike I
  db:priv_AddDB("Runes", 520182); -- Strike II
  db:priv_AddDB("Runes", 520183); -- Strike III
  db:priv_AddDB("Runes", 520184); -- Strike IV
  db:priv_AddDB("Runes", 520185); -- Strike V
  db:priv_AddDB("Runes", 520186); -- Strike VI
  db:priv_AddDB("Runes", 520187); -- Strike VII
  db:priv_AddDB("Runes", 520188); -- Strike VIII
  db:priv_AddDB("Runes", 520189); -- Strike IX
  db:priv_AddDB("Runes", 520190); -- Strike X
  db:priv_AddDB("Runes", 520201); -- Defense I
  db:priv_AddDB("Runes", 520202); -- Defense II
  db:priv_AddDB("Runes", 520203); -- Defense III
  db:priv_AddDB("Runes", 520204); -- Defense IV
  db:priv_AddDB("Runes", 520205); -- Defense V
  db:priv_AddDB("Runes", 520206); -- Defense VI
  db:priv_AddDB("Runes", 520207); -- Defense VII
  db:priv_AddDB("Runes", 520208); -- Defense VIII
  db:priv_AddDB("Runes", 520209); -- Defense IX
  db:priv_AddDB("Runes", 520210); -- Defense X
  db:priv_AddDB("Runes", 520221); -- Shell I
  db:priv_AddDB("Runes", 520222); -- Shell II
  db:priv_AddDB("Runes", 520223); -- Shell III
  db:priv_AddDB("Runes", 520224); -- Shell IV
  db:priv_AddDB("Runes", 520225); -- Shell V
  db:priv_AddDB("Runes", 520226); -- Shell VI
  db:priv_AddDB("Runes", 520227); -- Shell VII
  db:priv_AddDB("Runes", 520228); -- Shell VIII
  db:priv_AddDB("Runes", 520229); -- Shell IX
  db:priv_AddDB("Runes", 520230); -- Shell X
  db:priv_AddDB("Runes", 520241); -- Atonement I
  db:priv_AddDB("Runes", 520242); -- Atonement II
  db:priv_AddDB("Runes", 520243); -- Atonement III
  db:priv_AddDB("Runes", 520244); -- Atonement IV
  db:priv_AddDB("Runes", 520245); -- Atonement V
  db:priv_AddDB("Runes", 520246); -- Atonement VI
  db:priv_AddDB("Runes", 520247); -- Atonement VII
  db:priv_AddDB("Runes", 520248); -- Atonement VIII
  db:priv_AddDB("Runes", 520249); -- Atonement IX
  db:priv_AddDB("Runes", 520250); -- Atonement X
  db:priv_AddDB("Runes", 520261); -- Payback I
  db:priv_AddDB("Runes", 520262); -- Payback II
  db:priv_AddDB("Runes", 520263); -- Payback III
  db:priv_AddDB("Runes", 520264); -- Payback IV
  db:priv_AddDB("Runes", 520265); -- Payback V
  db:priv_AddDB("Runes", 520266); -- Payback VI
  db:priv_AddDB("Runes", 520267); -- Payback VII
  db:priv_AddDB("Runes", 520268); -- Payback VIII
  db:priv_AddDB("Runes", 520269); -- Payback IX
  db:priv_AddDB("Runes", 520270); -- Payback X
  db:priv_AddDB("Runes", 520281); -- Excite I
  db:priv_AddDB("Runes", 520282); -- Excite II
  db:priv_AddDB("Runes", 520283); -- Excite III
  db:priv_AddDB("Runes", 520284); -- Excite IV
  db:priv_AddDB("Runes", 520285); -- Excite V
  db:priv_AddDB("Runes", 520286); -- Excite VI
  db:priv_AddDB("Runes", 520287); -- Excite VII
  db:priv_AddDB("Runes", 520288); -- Excite VIII
  db:priv_AddDB("Runes", 520289); -- Excite IX
  db:priv_AddDB("Runes", 520290); -- Excite X
  db:priv_AddDB("Runes", 520301); -- Guts I
  db:priv_AddDB("Runes", 520302); -- Guts II
  db:priv_AddDB("Runes", 520303); -- Guts III
  db:priv_AddDB("Runes", 520304); -- Guts IV
  db:priv_AddDB("Runes", 520305); -- Guts V
  db:priv_AddDB("Runes", 520306); -- Guts VI
  db:priv_AddDB("Runes", 520307); -- Guts VII
  db:priv_AddDB("Runes", 520308); -- Guts VIII
  db:priv_AddDB("Runes", 520309); -- Guts IX
  db:priv_AddDB("Runes", 520310); -- Guts X
  db:priv_AddDB("Runes", 520321); -- Rouse I
  db:priv_AddDB("Runes", 520322); -- Rouse II
  db:priv_AddDB("Runes", 520323); -- Rouse III
  db:priv_AddDB("Runes", 520324); -- Rouse IV
  db:priv_AddDB("Runes", 520325); -- Rouse V
  db:priv_AddDB("Runes", 520326); -- Rouse VI
  db:priv_AddDB("Runes", 520327); -- Rouse VII
  db:priv_AddDB("Runes", 520328); -- Rouse VIII
  db:priv_AddDB("Runes", 520329); -- Rouse IX
  db:priv_AddDB("Runes", 520330); -- Rouse X
  db:priv_AddDB("Runes", 520341); -- Triumph I
  db:priv_AddDB("Runes", 520342); -- Triumph II
  db:priv_AddDB("Runes", 520343); -- Triumph III
  db:priv_AddDB("Runes", 520344); -- Triumph IV
  db:priv_AddDB("Runes", 520345); -- Triumph V
  db:priv_AddDB("Runes", 520346); -- Triumph VI
  db:priv_AddDB("Runes", 520347); -- Triumph VII
  db:priv_AddDB("Runes", 520348); -- Triumph VIII
  db:priv_AddDB("Runes", 520349); -- Triumph IX
  db:priv_AddDB("Runes", 520350); -- Triumph X
  db:priv_AddDB("Runes", 520361); -- Anger I
  db:priv_AddDB("Runes", 520362); -- Anger II
  db:priv_AddDB("Runes", 520363); -- Anger III
  db:priv_AddDB("Runes", 520364); -- Anger IV
  db:priv_AddDB("Runes", 520365); -- Anger V
  db:priv_AddDB("Runes", 520366); -- Anger VI
  db:priv_AddDB("Runes", 520367); -- Anger VII
  db:priv_AddDB("Runes", 520368); -- Anger VIII
  db:priv_AddDB("Runes", 520369); -- Anger IX
  db:priv_AddDB("Runes", 520370); -- Anger X
  db:priv_AddDB("Runes", 520381); -- Barrier I
  db:priv_AddDB("Runes", 520382); -- Barrier II
  db:priv_AddDB("Runes", 520383); -- Barrier III
  db:priv_AddDB("Runes", 520384); -- Barrier IV
  db:priv_AddDB("Runes", 520385); -- Barrier V
  db:priv_AddDB("Runes", 520386); -- Barrier VI
  db:priv_AddDB("Runes", 520387); -- Barrier VII
  db:priv_AddDB("Runes", 520388); -- Barrier VIII
  db:priv_AddDB("Runes", 520389); -- Barrier IX
  db:priv_AddDB("Runes", 520390); -- Barrier X
  db:priv_AddDB("Runes", 520401); -- Resistor I
  db:priv_AddDB("Runes", 520402); -- Resistor II
  db:priv_AddDB("Runes", 520403); -- Resistor III
  db:priv_AddDB("Runes", 520404); -- Resistor IV
  db:priv_AddDB("Runes", 520405); -- Resistor V
  db:priv_AddDB("Runes", 520406); -- Resistor VI
  db:priv_AddDB("Runes", 520407); -- Resistor VII
  db:priv_AddDB("Runes", 520408); -- Resistor VIII
  db:priv_AddDB("Runes", 520409); -- Resistor IX
  db:priv_AddDB("Runes", 520410); -- Resistor X
  db:priv_AddDB("Runes", 520421); -- Mayhem I
  db:priv_AddDB("Runes", 520422); -- Mayhem II
  db:priv_AddDB("Runes", 520423); -- Mayhem III
  db:priv_AddDB("Runes", 520424); -- Mayhem IV
  db:priv_AddDB("Runes", 520425); -- Mayhem V
  db:priv_AddDB("Runes", 520426); -- Mayhem VI
  db:priv_AddDB("Runes", 520427); -- Mayhem VII
  db:priv_AddDB("Runes", 520428); -- Mayhem VIII
  db:priv_AddDB("Runes", 520429); -- Mayhem IX
  db:priv_AddDB("Runes", 520430); -- Mayhem X
  db:priv_AddDB("Runes", 520441); -- Passion I
  db:priv_AddDB("Runes", 520442); -- Passion II
  db:priv_AddDB("Runes", 520443); -- Passion III
  db:priv_AddDB("Runes", 520444); -- Passion IV
  db:priv_AddDB("Runes", 520445); -- Passion V
  db:priv_AddDB("Runes", 520446); -- Passion VI
  db:priv_AddDB("Runes", 520447); -- Passion VII
  db:priv_AddDB("Runes", 520448); -- Passion VIII
  db:priv_AddDB("Runes", 520449); -- Passion IX
  db:priv_AddDB("Runes", 520450); -- Passion X
  db:priv_AddDB("Runes", 520461); -- Fountain I
  db:priv_AddDB("Runes", 520462); -- Fountain II
  db:priv_AddDB("Runes", 520463); -- Fountain III
  db:priv_AddDB("Runes", 520464); -- Fountain IV
  db:priv_AddDB("Runes", 520465); -- Fountain V
  db:priv_AddDB("Runes", 520466); -- Fountain VI
  db:priv_AddDB("Runes", 520467); -- Fountain VII
  db:priv_AddDB("Runes", 520468); -- Fountain VIII
  db:priv_AddDB("Runes", 520469); -- Fountain IX
  db:priv_AddDB("Runes", 520470); -- Fountain X
  db:priv_AddDB("Runes", 520481); -- Fearless I
  db:priv_AddDB("Runes", 520482); -- Fearless II
  db:priv_AddDB("Runes", 520483); -- Fearless III
  db:priv_AddDB("Runes", 520484); -- Fearless IV
  db:priv_AddDB("Runes", 520485); -- Fearless V
  db:priv_AddDB("Runes", 520486); -- Fearless VI
  db:priv_AddDB("Runes", 520487); -- Fearless VII
  db:priv_AddDB("Runes", 520488); -- Fearless VIII
  db:priv_AddDB("Runes", 520489); -- Fearless IX
  db:priv_AddDB("Runes", 520490); -- Fearless X
  db:priv_AddDB("Runes", 520501); -- Might I
  db:priv_AddDB("Runes", 520502); -- Might II
  db:priv_AddDB("Runes", 520503); -- Might III
  db:priv_AddDB("Runes", 520504); -- Might IV
  db:priv_AddDB("Runes", 520505); -- Might V
  db:priv_AddDB("Runes", 520506); -- Might VI
  db:priv_AddDB("Runes", 520507); -- Might VII
  db:priv_AddDB("Runes", 520508); -- Might VIII
  db:priv_AddDB("Runes", 520509); -- Might IX
  db:priv_AddDB("Runes", 520510); -- Might X
  db:priv_AddDB("Runes", 520521); -- Agile I
  db:priv_AddDB("Runes", 520522); -- Agile II
  db:priv_AddDB("Runes", 520523); -- Agile III
  db:priv_AddDB("Runes", 520524); -- Agile IV
  db:priv_AddDB("Runes", 520525); -- Agile V
  db:priv_AddDB("Runes", 520526); -- Agile VI
  db:priv_AddDB("Runes", 520527); -- Agile VII
  db:priv_AddDB("Runes", 520528); -- Agile VIII
  db:priv_AddDB("Runes", 520529); -- Agile IX
  db:priv_AddDB("Runes", 520530); -- Agile X
  db:priv_AddDB("Runes", 520541); -- Sorcery I
  db:priv_AddDB("Runes", 520542); -- Sorcery II
  db:priv_AddDB("Runes", 520543); -- Sorcery III
  db:priv_AddDB("Runes", 520544); -- Sorcery IV
  db:priv_AddDB("Runes", 520545); -- Sorcery V
  db:priv_AddDB("Runes", 520546); -- Sorcery VI
  db:priv_AddDB("Runes", 520547); -- Sorcery VII
  db:priv_AddDB("Runes", 520548); -- Sorcery VIII
  db:priv_AddDB("Runes", 520549); -- Sorcery IX
  db:priv_AddDB("Runes", 520550); -- Sorcery X
  db:priv_AddDB("Runes", 520561); -- Aggression I
  db:priv_AddDB("Runes", 520562); -- Aggression II
  db:priv_AddDB("Runes", 520563); -- Aggression III
  db:priv_AddDB("Runes", 520564); -- Aggression IV
  db:priv_AddDB("Runes", 520565); -- Aggression V
  db:priv_AddDB("Runes", 520566); -- Aggression VI
  db:priv_AddDB("Runes", 520567); -- Aggression VII
  db:priv_AddDB("Runes", 520568); -- Aggression VIII
  db:priv_AddDB("Runes", 520569); -- Aggression IX
  db:priv_AddDB("Runes", 520570); -- Aggression X
  db:priv_AddDB("Runes", 520581); -- Advance I
  db:priv_AddDB("Runes", 520582); -- Advance II
  db:priv_AddDB("Runes", 520583); -- Advance III
  db:priv_AddDB("Runes", 520584); -- Advance IV
  db:priv_AddDB("Runes", 520585); -- Advance V
  db:priv_AddDB("Runes", 520586); -- Advance VI
  db:priv_AddDB("Runes", 520587); -- Advance VII
  db:priv_AddDB("Runes", 520588); -- Advance VIII
  db:priv_AddDB("Runes", 520589); -- Advance IX
  db:priv_AddDB("Runes", 520590); -- Advance X
  db:priv_AddDB("Runes", 520601); -- Revolution I
  db:priv_AddDB("Runes", 520602); -- Revolution II
  db:priv_AddDB("Runes", 520603); -- Revolution III
  db:priv_AddDB("Runes", 520604); -- Revolution IV
  db:priv_AddDB("Runes", 520605); -- Revolution V
  db:priv_AddDB("Runes", 520606); -- Revolution VI
  db:priv_AddDB("Runes", 520607); -- Revolution VII
  db:priv_AddDB("Runes", 520608); -- Revolution VIII
  db:priv_AddDB("Runes", 520609); -- Revolution IX
  db:priv_AddDB("Runes", 520610); -- Revolution X
  db:priv_AddDB("Runes", 520621); -- Block I
  db:priv_AddDB("Runes", 520621); -- Wall I
  db:priv_AddDB("Runes", 520622); -- Block II
  db:priv_AddDB("Runes", 520622); -- Wall II
  db:priv_AddDB("Runes", 520623); -- Block III
  db:priv_AddDB("Runes", 520623); -- Wall III
  db:priv_AddDB("Runes", 520624); -- Block IV
  db:priv_AddDB("Runes", 520624); -- Wall IV
  db:priv_AddDB("Runes", 520625); -- Block V
  db:priv_AddDB("Runes", 520625); -- Wall V
  db:priv_AddDB("Runes", 520626); -- Block VI
  db:priv_AddDB("Runes", 520626); -- Wall VI
  db:priv_AddDB("Runes", 520627); -- Block VII
  db:priv_AddDB("Runes", 520627); -- Wall VII
  db:priv_AddDB("Runes", 520628); -- Block VIII
  db:priv_AddDB("Runes", 520628); -- Wall VIII
  db:priv_AddDB("Runes", 520629); -- Block IX
  db:priv_AddDB("Runes", 520629); -- Wall IX
  db:priv_AddDB("Runes", 520630); -- Block X
  db:priv_AddDB("Runes", 520630); -- Wall X
  db:priv_AddDB("Runes", 520641); -- Shield I
  db:priv_AddDB("Runes", 520642); -- Shield II
  db:priv_AddDB("Runes", 520643); -- Shield III
  db:priv_AddDB("Runes", 520644); -- Shield IV
  db:priv_AddDB("Runes", 520645); -- Shield V
  db:priv_AddDB("Runes", 520646); -- Shield VI
  db:priv_AddDB("Runes", 520647); -- Shield VII
  db:priv_AddDB("Runes", 520648); -- Shield VIII
  db:priv_AddDB("Runes", 520649); -- Shield IX
  db:priv_AddDB("Runes", 520650); -- Shield X
  db:priv_AddDB("Runes", 520661); -- Potential I
  db:priv_AddDB("Runes", 520662); -- Potential II
  db:priv_AddDB("Runes", 520663); -- Potential III
  db:priv_AddDB("Runes", 520664); -- Potential IV
  db:priv_AddDB("Runes", 520665); -- Potential V
  db:priv_AddDB("Runes", 520666); -- Potential VI
  db:priv_AddDB("Runes", 520667); -- Potential VII
  db:priv_AddDB("Runes", 520668); -- Potential VIII
  db:priv_AddDB("Runes", 520669); -- Potential IX
  db:priv_AddDB("Runes", 520670); -- Potential X
  db:priv_AddDB("Runes", 520681); -- Hatred I
  db:priv_AddDB("Runes", 520682); -- Hatred II
  db:priv_AddDB("Runes", 520683); -- Hatred III
  db:priv_AddDB("Runes", 520684); -- Hatred IV
  db:priv_AddDB("Runes", 520685); -- Hatred V
  db:priv_AddDB("Runes", 520686); -- Hatred VI
  db:priv_AddDB("Runes", 520687); -- Hatred VII
  db:priv_AddDB("Runes", 520688); -- Hatred VIII
  db:priv_AddDB("Runes", 520689); -- Hatred IX
  db:priv_AddDB("Runes", 520690); -- Hatred X
  db:priv_AddDB("Runes", 520701); -- Reconciliation I
  db:priv_AddDB("Runes", 520702); -- Reconciliation II
  db:priv_AddDB("Runes", 520703); -- Reconciliation III
  db:priv_AddDB("Runes", 520704); -- Reconciliation IV
  db:priv_AddDB("Runes", 520705); -- Reconciliation V
  db:priv_AddDB("Runes", 520706); -- Reconciliation VI
  db:priv_AddDB("Runes", 520707); -- Reconciliation VII
  db:priv_AddDB("Runes", 520708); -- Reconciliation VIII
  db:priv_AddDB("Runes", 520709); -- Reconciliation IX
  db:priv_AddDB("Runes", 520710); -- Reconciliation X
  db:priv_AddDB("Runes", 520721); -- Loot I
  db:priv_AddDB("Runes", 520722); -- Loot II
  db:priv_AddDB("Runes", 520723); -- Loot III
  db:priv_AddDB("Runes", 520724); -- Loot IV
  db:priv_AddDB("Runes", 520725); -- Loot V
  db:priv_AddDB("Runes", 520726); -- Loot VI
  db:priv_AddDB("Runes", 520727); -- Loot VII
  db:priv_AddDB("Runes", 520728); -- Loot VIII
  db:priv_AddDB("Runes", 520729); -- Loot IX
  db:priv_AddDB("Runes", 520730); -- Loot X
  db:priv_AddDB("Runes", 520741); -- Experience I
  db:priv_AddDB("Runes", 520742); -- Experience II
  db:priv_AddDB("Runes", 520743); -- Experience III
  db:priv_AddDB("Runes", 520744); -- Experience IV
  db:priv_AddDB("Runes", 520745); -- Experience V
  db:priv_AddDB("Runes", 520746); -- Experience VI
  db:priv_AddDB("Runes", 520747); -- Experience VII
  db:priv_AddDB("Runes", 520748); -- Experience VIII
  db:priv_AddDB("Runes", 520749); -- Experience IX
  db:priv_AddDB("Runes", 520750); -- Experience X
  db:priv_AddDB("Runes", 520761); -- Fatal I
  db:priv_AddDB("Runes", 520762); -- Fatal II
  db:priv_AddDB("Runes", 520763); -- Fatal III
  db:priv_AddDB("Runes", 520764); -- Fatal IV
  db:priv_AddDB("Runes", 520765); -- Fatal V
  db:priv_AddDB("Runes", 520766); -- Fatal VI
  db:priv_AddDB("Runes", 520767); -- Fatal VII
  db:priv_AddDB("Runes", 520768); -- Fatal VIII
  db:priv_AddDB("Runes", 520769); -- Fatal IX
  db:priv_AddDB("Runes", 520770); -- Fatal X
  db:priv_AddDB("Runes", 520781); -- Burst I
  db:priv_AddDB("Runes", 520782); -- Burst II
  db:priv_AddDB("Runes", 520783); -- Burst III
  db:priv_AddDB("Runes", 520784); -- Burst IV
  db:priv_AddDB("Runes", 520785); -- Burst V
  db:priv_AddDB("Runes", 520786); -- Burst VI
  db:priv_AddDB("Runes", 520787); -- Burst VII
  db:priv_AddDB("Runes", 520788); -- Burst VIII
  db:priv_AddDB("Runes", 520789); -- Burst IX
  db:priv_AddDB("Runes", 520790); -- Burst X
  db:priv_AddDB("Runes", 520801); -- Wrath I
  db:priv_AddDB("Runes", 520802); -- Wrath II
  db:priv_AddDB("Runes", 520803); -- Wrath III
  db:priv_AddDB("Runes", 520804); -- Wrath IV
  db:priv_AddDB("Runes", 520805); -- Wrath V
  db:priv_AddDB("Runes", 520806); -- Wrath VI
  db:priv_AddDB("Runes", 520807); -- Wrath VII
  db:priv_AddDB("Runes", 520808); -- Wrath VIII
  db:priv_AddDB("Runes", 520809); -- Wrath IX
  db:priv_AddDB("Runes", 520810); -- Wrath X
  db:priv_AddDB("Runes", 520821); -- Miracle I
  db:priv_AddDB("Runes", 520822); -- Miracle II
  db:priv_AddDB("Runes", 520823); -- Miracle III
  db:priv_AddDB("Runes", 520824); -- Miracle IV
  db:priv_AddDB("Runes", 520825); -- Miracle V
  db:priv_AddDB("Runes", 520826); -- Miracle VI
  db:priv_AddDB("Runes", 520827); -- Miracle VII
  db:priv_AddDB("Runes", 520828); -- Miracle VIII
  db:priv_AddDB("Runes", 520829); -- Miracle IX
  db:priv_AddDB("Runes", 520830); -- Miracle X
  db:priv_AddDB("Runes", 520871); -- Savage I
  db:priv_AddDB("Runes", 520872); -- Savage II
  db:priv_AddDB("Runes", 520873); -- Savage III
  db:priv_AddDB("Runes", 520874); -- Savage IV
  db:priv_AddDB("Runes", 520875); -- Savage V
  db:priv_AddDB("Runes", 520876); -- Savage VI
  db:priv_AddDB("Runes", 520877); -- Savage VII
  db:priv_AddDB("Runes", 520878); -- Savage VIII
  db:priv_AddDB("Runes", 520879); -- Savage IX
  db:priv_AddDB("Runes", 520880); -- Savage X
  db:priv_AddDB("Runes", 520891); -- Stamina I
  db:priv_AddDB("Runes", 520892); -- Stamina II
  db:priv_AddDB("Runes", 520893); -- Stamina III
  db:priv_AddDB("Runes", 520894); -- Stamina IV
  db:priv_AddDB("Runes", 520895); -- Stamina V
  db:priv_AddDB("Runes", 520896); -- Stamina VI
  db:priv_AddDB("Runes", 520897); -- Stamina VII
  db:priv_AddDB("Runes", 520898); -- Stamina VIII
  db:priv_AddDB("Runes", 520899); -- Stamina IX
  db:priv_AddDB("Runes", 520900); -- Stamina X
  db:priv_AddDB("Runes", 520911); -- Intellect I
  db:priv_AddDB("Runes", 520912); -- Intellect II
  db:priv_AddDB("Runes", 520913); -- Intellect III
  db:priv_AddDB("Runes", 520914); -- Intellect IV
  db:priv_AddDB("Runes", 520915); -- Intellect V
  db:priv_AddDB("Runes", 520916); -- Intellect VI
  db:priv_AddDB("Runes", 520917); -- Intellect VII
  db:priv_AddDB("Runes", 520918); -- Intellect VIII
  db:priv_AddDB("Runes", 520919); -- Intellect IX
  db:priv_AddDB("Runes", 520920); -- Intellect X
  db:priv_AddDB("Runes", 520931); -- Spirit I
  db:priv_AddDB("Runes", 520932); -- Spirit II
  db:priv_AddDB("Runes", 520933); -- Spirit III
  db:priv_AddDB("Runes", 520934); -- Spirit IV
  db:priv_AddDB("Runes", 520935); -- Spirit V
  db:priv_AddDB("Runes", 520936); -- Spirit VI
  db:priv_AddDB("Runes", 520937); -- Spirit VII
  db:priv_AddDB("Runes", 520938); -- Spirit VIII
  db:priv_AddDB("Runes", 520939); -- Spirit IX
  db:priv_AddDB("Runes", 520940); -- Spirit X
  db:priv_AddDB("Runes", 520951); -- Dexterity I
  db:priv_AddDB("Runes", 520952); -- Dexterity II
  db:priv_AddDB("Runes", 520953); -- Dexterity III
  db:priv_AddDB("Runes", 520954); -- Dexterity IV
  db:priv_AddDB("Runes", 520955); -- Dexterity V
  db:priv_AddDB("Runes", 520956); -- Dexterity VI
  db:priv_AddDB("Runes", 520957); -- Dexterity VII
  db:priv_AddDB("Runes", 520958); -- Dexterity VIII
  db:priv_AddDB("Runes", 520959); -- Dexterity IX
  db:priv_AddDB("Runes", 520960); -- Dexterity X
  db:priv_AddDB("Runes", 520971); -- Life I
  db:priv_AddDB("Runes", 520972); -- Life II
  db:priv_AddDB("Runes", 520973); -- Life III
  db:priv_AddDB("Runes", 520974); -- Life IV
  db:priv_AddDB("Runes", 520975); -- Life V
  db:priv_AddDB("Runes", 520976); -- Life VI
  db:priv_AddDB("Runes", 520977); -- Life VII
  db:priv_AddDB("Runes", 520978); -- Life VIII
  db:priv_AddDB("Runes", 520979); -- Life IX
  db:priv_AddDB("Runes", 520980); -- Life X
  db:priv_AddDB("Runes", 520991); -- Spell I
  db:priv_AddDB("Runes", 520992); -- Spell II
  db:priv_AddDB("Runes", 520993); -- Spell III
  db:priv_AddDB("Runes", 520994); -- Spell IV
  db:priv_AddDB("Runes", 520995); -- Spell V
  db:priv_AddDB("Runes", 520996); -- Spell VI
  db:priv_AddDB("Runes", 520997); -- Spell VII
  db:priv_AddDB("Runes", 520998); -- Spell VIII
  db:priv_AddDB("Runes", 520999); -- Spell IX
  db:priv_AddDB("Runes", 521000); -- Spell X
  db:priv_AddDB("Runes", 521011); -- Cruelty I
  db:priv_AddDB("Runes", 521012); -- Cruelty II
  db:priv_AddDB("Runes", 521013); -- Cruelty III
  db:priv_AddDB("Runes", 521014); -- Cruelty IV
  db:priv_AddDB("Runes", 521015); -- Cruelty V
  db:priv_AddDB("Runes", 521016); -- Cruelty VI
  db:priv_AddDB("Runes", 521017); -- Cruelty VII
  db:priv_AddDB("Runes", 521018); -- Cruelty VIII
  db:priv_AddDB("Runes", 521019); -- Cruelty IX
  db:priv_AddDB("Runes", 521020); -- Cruelty X
  db:priv_AddDB("Runes", 521031); -- Charm I
  db:priv_AddDB("Runes", 521032); -- Charm II
  db:priv_AddDB("Runes", 521033); -- Charm III
  db:priv_AddDB("Runes", 521034); -- Charm IV
  db:priv_AddDB("Runes", 521035); -- Charm V
  db:priv_AddDB("Runes", 521036); -- Charm VI
  db:priv_AddDB("Runes", 521037); -- Charm VII
  db:priv_AddDB("Runes", 521038); -- Charm VIII
  db:priv_AddDB("Runes", 521039); -- Charm IX
  db:priv_AddDB("Runes", 521040); -- Charm X
  db:priv_AddDB("Runes", 521051); -- Safeguard I
  db:priv_AddDB("Runes", 521052); -- Safeguard II
  db:priv_AddDB("Runes", 521053); -- Safeguard III
  db:priv_AddDB("Runes", 521054); -- Safeguard IV
  db:priv_AddDB("Runes", 521055); -- Safeguard V
  db:priv_AddDB("Runes", 521056); -- Safeguard VI
  db:priv_AddDB("Runes", 521057); -- Safeguard VII
  db:priv_AddDB("Runes", 521058); -- Safeguard VIII
  db:priv_AddDB("Runes", 521059); -- Safeguard IX
  db:priv_AddDB("Runes", 521060); -- Safeguard X
  db:priv_AddDB("Runes", 521071); -- Ward I
  db:priv_AddDB("Runes", 521072); -- Ward II
  db:priv_AddDB("Runes", 521073); -- Ward III
  db:priv_AddDB("Runes", 521074); -- Ward IV
  db:priv_AddDB("Runes", 521075); -- Ward V
  db:priv_AddDB("Runes", 521076); -- Ward VI
  db:priv_AddDB("Runes", 521077); -- Ward VII
  db:priv_AddDB("Runes", 521078); -- Ward VIII
  db:priv_AddDB("Runes", 521079); -- Ward IX
  db:priv_AddDB("Runes", 521080); -- Ward X  
  db:priv_AddDB("Runes", 521091); -- Ferocity I
  db:priv_AddDB("Runes", 521092); -- Ferocity II
  db:priv_AddDB("Runes", 521093); -- Ferocity III
  db:priv_AddDB("Runes", 521094); -- Ferocity IV
  db:priv_AddDB("Runes", 521095); -- Ferocity V
  db:priv_AddDB("Runes", 521096); -- Ferocity VI
  db:priv_AddDB("Runes", 521097); -- Ferocity VII
  db:priv_AddDB("Runes", 521098); -- Ferocity VIII
  db:priv_AddDB("Runes", 521099); -- Ferocity IX
  db:priv_AddDB("Runes", 521100); -- Ferocity X
  db:priv_AddDB("Runes", 521111); -- Devil I
  db:priv_AddDB("Runes", 521112); -- Devil II
  db:priv_AddDB("Runes", 521113); -- Devil III
  db:priv_AddDB("Runes", 521114); -- Devil IV
  db:priv_AddDB("Runes", 521115); -- Devil V
  db:priv_AddDB("Runes", 521116); -- Devil VI
  db:priv_AddDB("Runes", 521117); -- Devil VII
  db:priv_AddDB("Runes", 521118); -- Devil VIII
  db:priv_AddDB("Runes", 521119); -- Devil IX
  db:priv_AddDB("Runes", 521120); -- Devil X
  db:priv_AddDB("Runes", 521131); -- Grasp I
  db:priv_AddDB("Runes", 521132); -- Grasp II
  db:priv_AddDB("Runes", 521133); -- Grasp III
  db:priv_AddDB("Runes", 521134); -- Grasp IV
  db:priv_AddDB("Runes", 521135); -- Grasp V
  db:priv_AddDB("Runes", 521136); -- Grasp VI
  db:priv_AddDB("Runes", 521137); -- Grasp VII
  db:priv_AddDB("Runes", 521138); -- Grasp VIII
  db:priv_AddDB("Runes", 521139); -- Grasp IX
  db:priv_AddDB("Runes", 521140); -- Grasp X
  db:priv_AddDB("Runes", 521151); -- Capability I
  db:priv_AddDB("Runes", 521152); -- Capability II
  db:priv_AddDB("Runes", 521153); -- Capability III
  db:priv_AddDB("Runes", 521154); -- Capability IV
  db:priv_AddDB("Runes", 521155); -- Capability V
  db:priv_AddDB("Runes", 521156); -- Capability VI
  db:priv_AddDB("Runes", 521157); -- Capability VII
  db:priv_AddDB("Runes", 521158); -- Capability VIII
  db:priv_AddDB("Runes", 521159); -- Capability IX
  db:priv_AddDB("Runes", 521160); -- Capability X
  db:priv_AddDB("Runes", 521171); -- Keenness I
  db:priv_AddDB("Runes", 521172); -- Keenness II
  db:priv_AddDB("Runes", 521173); -- Keenness III
  db:priv_AddDB("Runes", 521174); -- Keenness IV
  db:priv_AddDB("Runes", 521175); -- Keenness V
  db:priv_AddDB("Runes", 521176); -- Keenness VI
  db:priv_AddDB("Runes", 521177); -- Keenness VII
  db:priv_AddDB("Runes", 521178); -- Keenness VIII
  db:priv_AddDB("Runes", 521179); -- Keenness IX
  db:priv_AddDB("Runes", 521180); -- Keenness X
  db:priv_AddDB("Runes", 521191); -- Comprehension I
  db:priv_AddDB("Runes", 521192); -- Comprehension II
  db:priv_AddDB("Runes", 521193); -- Comprehension III
  db:priv_AddDB("Runes", 521194); -- Comprehension IV
  db:priv_AddDB("Runes", 521195); -- Comprehension V
  db:priv_AddDB("Runes", 521196); -- Comprehension VI
  db:priv_AddDB("Runes", 521197); -- Comprehension VII
  db:priv_AddDB("Runes", 521198); -- Comprehension VIII
  db:priv_AddDB("Runes", 521199); -- Comprehension IX
  db:priv_AddDB("Runes", 521200); -- Comprehension X
  db:priv_AddDB("Runes", 521211); -- Madness I
  db:priv_AddDB("Runes", 521212); -- Madness II
  db:priv_AddDB("Runes", 521213); -- Madness III
  db:priv_AddDB("Runes", 521214); -- Madness IV
  db:priv_AddDB("Runes", 521215); -- Madness V
  db:priv_AddDB("Runes", 521216); -- Madness VI
  db:priv_AddDB("Runes", 521217); -- Madness VII
  db:priv_AddDB("Runes", 521218); -- Madness VIII
  db:priv_AddDB("Runes", 521219); -- Madness IX
  db:priv_AddDB("Runes", 521220); -- Madness X
  db:priv_AddDB("Runes", 521231); -- Dauntlessness I
  db:priv_AddDB("Runes", 521232); -- Dauntlessness II
  db:priv_AddDB("Runes", 521233); -- Dauntlessness III
  db:priv_AddDB("Runes", 521234); -- Dauntlessness IV
  db:priv_AddDB("Runes", 521235); -- Dauntlessness V
  db:priv_AddDB("Runes", 521236); -- Dauntlessness VI
  db:priv_AddDB("Runes", 521237); -- Dauntlessness VII
  db:priv_AddDB("Runes", 521238); -- Dauntlessness VIII
  db:priv_AddDB("Runes", 521239); -- Dauntlessness IX
  db:priv_AddDB("Runes", 521240); -- Dauntlessness X
  db:priv_AddDB("Runes", 521251); -- Enchantment I
  db:priv_AddDB("Runes", 521252); -- Enchantment II
  db:priv_AddDB("Runes", 521253); -- Enchantment III
  db:priv_AddDB("Runes", 521254); -- Enchantment IV
  db:priv_AddDB("Runes", 521255); -- Enchantment V
  db:priv_AddDB("Runes", 521256); -- Enchantment VI
  db:priv_AddDB("Runes", 521257); -- Enchantment VII
  db:priv_AddDB("Runes", 521258); -- Enchantment VIII
  db:priv_AddDB("Runes", 521259); -- Enchantment IX
  db:priv_AddDB("Runes", 521260); -- Enchantment X
  db:priv_AddDB("Runes", 521271); -- Destruction I
  db:priv_AddDB("Runes", 521272); -- Destruction II
  db:priv_AddDB("Runes", 521273); -- Destruction III
  db:priv_AddDB("Runes", 521274); -- Destruction IV
  db:priv_AddDB("Runes", 521275); -- Destruction V
  db:priv_AddDB("Runes", 521276); -- Destruction VI
  db:priv_AddDB("Runes", 521277); -- Destruction VII
  db:priv_AddDB("Runes", 521278); -- Destruction VIII
  db:priv_AddDB("Runes", 521279); -- Destruction IX
  db:priv_AddDB("Runes", 521280); -- Destruction X
  db:priv_AddDB("Runes", 521291); -- Raid I
  db:priv_AddDB("Runes", 521292); -- Raid II
  db:priv_AddDB("Runes", 521293); -- Raid III
  db:priv_AddDB("Runes", 521294); -- Raid IV
  db:priv_AddDB("Runes", 521295); -- Raid V
  db:priv_AddDB("Runes", 521296); -- Raid VI
  db:priv_AddDB("Runes", 521297); -- Raid VII
  db:priv_AddDB("Runes", 521298); -- Raid VIII
  db:priv_AddDB("Runes", 521299); -- Raid IX
  db:priv_AddDB("Runes", 521300); -- Raid X
  db:priv_AddDB("Runes", 521311); -- Curse I
  db:priv_AddDB("Runes", 521312); -- Curse II
  db:priv_AddDB("Runes", 521313); -- Curse III
  db:priv_AddDB("Runes", 521314); -- Curse IV
  db:priv_AddDB("Runes", 521315); -- Curse V
  db:priv_AddDB("Runes", 521316); -- Curse VI
  db:priv_AddDB("Runes", 521317); -- Curse VII
  db:priv_AddDB("Runes", 521318); -- Curse VIII
  db:priv_AddDB("Runes", 521319); -- Curse IX
  db:priv_AddDB("Runes", 521320); -- Curse X
  db:priv_AddDB("Runes", 521331); -- Accuracy I
  db:priv_AddDB("Runes", 521332); -- Accuracy II
  db:priv_AddDB("Runes", 521333); -- Accuracy III
  db:priv_AddDB("Runes", 521334); -- Accuracy IV
  db:priv_AddDB("Runes", 521335); -- Accuracy V
  db:priv_AddDB("Runes", 521336); -- Accuracy VI
  db:priv_AddDB("Runes", 521337); -- Accuracy VII
  db:priv_AddDB("Runes", 521338); -- Accuracy VIII
  db:priv_AddDB("Runes", 521339); -- Accuracy IX
  db:priv_AddDB("Runes", 521340); -- Accuracy X
  db:priv_AddDB("Runes", 521351); -- Enlightenment I
  db:priv_AddDB("Runes", 521352); -- Enlightenment II
  db:priv_AddDB("Runes", 521353); -- Enlightenment III
  db:priv_AddDB("Runes", 521354); -- Enlightenment IV
  db:priv_AddDB("Runes", 521355); -- Enlightenment V
  db:priv_AddDB("Runes", 521356); -- Enlightenment VI
  db:priv_AddDB("Runes", 521357); -- Enlightenment VII
  db:priv_AddDB("Runes", 521358); -- Enlightenment VIII
  db:priv_AddDB("Runes", 521359); -- Enlightenment IX
  db:priv_AddDB("Runes", 521360); -- Enlightenment X

  db:priv_AddDB("Runes", 521371); -- Tyrann
  db:priv_AddDB("Runes", 521372); -- 
  db:priv_AddDB("Runes", 521373); -- 
  db:priv_AddDB("Runes", 521374); -- 
  db:priv_AddDB("Runes", 521375); -- 
  db:priv_AddDB("Runes", 521376); -- 
  db:priv_AddDB("Runes", 521377); -- 
  db:priv_AddDB("Runes", 521378); -- 
  db:priv_AddDB("Runes", 521379); -- 
  db:priv_AddDB("Runes", 521380); -- 

  db:priv_AddDB("Runes", 521391); -- Assassine
  db:priv_AddDB("Runes", 521392); -- 
  db:priv_AddDB("Runes", 521393); -- 
  db:priv_AddDB("Runes", 521394); -- 
  db:priv_AddDB("Runes", 521395); -- 
  db:priv_AddDB("Runes", 521396); -- 
  db:priv_AddDB("Runes", 521397); -- 
  db:priv_AddDB("Runes", 521398); -- 
  db:priv_AddDB("Runes", 521399); -- 
  db:priv_AddDB("Runes", 521400); -- 

  db:priv_AddDB("Runes", 521411); -- Weiser
  db:priv_AddDB("Runes", 521412); -- 
  db:priv_AddDB("Runes", 521413); -- 
  db:priv_AddDB("Runes", 521414); -- 
  db:priv_AddDB("Runes", 521415); -- 
  db:priv_AddDB("Runes", 521416); -- 
  db:priv_AddDB("Runes", 521417); -- 
  db:priv_AddDB("Runes", 521418); -- 
  db:priv_AddDB("Runes", 521419); -- 
  db:priv_AddDB("Runes", 521420); -- 

  db:priv_AddDB("Runes", 521431); -- Rätsel
  db:priv_AddDB("Runes", 521432); -- 
  db:priv_AddDB("Runes", 521433); -- 
  db:priv_AddDB("Runes", 521434); -- 
  db:priv_AddDB("Runes", 521435); -- 
  db:priv_AddDB("Runes", 521436); -- 
  db:priv_AddDB("Runes", 521437); -- 
  db:priv_AddDB("Runes", 521438); -- 
  db:priv_AddDB("Runes", 521439); -- 
  db:priv_AddDB("Runes", 521440); -- 

  db:priv_AddDB("Runes", 521451); -- Richter
  db:priv_AddDB("Runes", 521452); -- 
  db:priv_AddDB("Runes", 521453); -- 
  db:priv_AddDB("Runes", 521454); -- 
  db:priv_AddDB("Runes", 521455); -- 
  db:priv_AddDB("Runes", 521456); -- 
  db:priv_AddDB("Runes", 521457); -- 
  db:priv_AddDB("Runes", 521458); -- 
  db:priv_AddDB("Runes", 521459); -- 
  db:priv_AddDB("Runes", 521460); -- 

  db:priv_AddDB("Runes", 521471); -- Massaker
  db:priv_AddDB("Runes", 521472); -- 
  db:priv_AddDB("Runes", 521473); -- 
  db:priv_AddDB("Runes", 521474); -- 
  db:priv_AddDB("Runes", 521475); -- 
  db:priv_AddDB("Runes", 521476); -- 
  db:priv_AddDB("Runes", 521477); -- 
  db:priv_AddDB("Runes", 521478); -- 
  db:priv_AddDB("Runes", 521479); -- 
  db:priv_AddDB("Runes", 521480); -- 

  
end;

local function priv_AddFusionStones(db)	-- F. Steine
  -- Purple
  db:priv_AddDB("FusionStones", 202881); -- Purified Fusion Stone
  -- Fusion Stone
  db:priv_AddDB("FusionStones", 202882); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202883); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202885); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202995); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202996); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202997); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202998); -- Fusion Stone

  db:priv_AddDB("FusionStones", 203000); -- Fusion Stone
  db:priv_AddDB("FusionStones", 203001); -- Fusion Stone
  db:priv_AddDB("FusionStones", 203002); -- Fusion Stone
  db:priv_AddDB("FusionStones", 203003); -- Fusion Stone
  db:priv_AddDB("FusionStones", 203004); -- Fusion Stone

  db:priv_AddDB("FusionStones", 202880); -- Fusion Stone

  db:priv_AddDB("FusionStones", 202999); -- Random Fusion Stone

  db:priv_AddDB("FusionStones", 206219); -- Fusion Stone  
  db:priv_AddDB("FusionStones", 206220); -- Fusion Stone  
  
  db:priv_AddDB("FusionStones", 206227); -- Fusion Stone

end;


local function priv_AddManaStones(db)	-- F. Steine

  -- Mana Stone
  db:priv_AddDB("ManaStones", 202840); -- Mana Stone Tier 1
  db:priv_AddDB("ManaStones", 202841); -- Mana Stone Tier 2
  db:priv_AddDB("ManaStones", 202842); -- Mana Stone Tier 3
  db:priv_AddDB("ManaStones", 202843); -- Mana Stone Tier 4
  db:priv_AddDB("ManaStones", 202844); -- Mana Stone Tier 5
  db:priv_AddDB("ManaStones", 202845); -- Mana Stone Tier 6
  db:priv_AddDB("ManaStones", 202846); -- Mana Stone Tier 7
  db:priv_AddDB("ManaStones", 202847); -- Mana Stone Tier 8
  db:priv_AddDB("ManaStones", 202848); -- Mana Stone Tier 9
  db:priv_AddDB("ManaStones", 202849); -- Mana Stone Tier 10
  db:priv_AddDB("ManaStones", 202850); -- Mana Stone Tier 11
  db:priv_AddDB("ManaStones", 202851); -- Mana Stone Tier 12
  db:priv_AddDB("ManaStones", 202852); -- Mana Stone Tier 13
  db:priv_AddDB("ManaStones", 202853); -- Mana Stone Tier 14
  db:priv_AddDB("ManaStones", 202854); -- Mana Stone Tier 15
  db:priv_AddDB("ManaStones", 202855); -- Mana Stone Tier 16
  db:priv_AddDB("ManaStones", 202856); -- Mana Stone Tier 17
  db:priv_AddDB("ManaStones", 202857); -- Mana Stone Tier 18
  db:priv_AddDB("ManaStones", 202858); -- Mana Stone Tier 19
  db:priv_AddDB("ManaStones", 202859); -- Mana Stone Tier 20
end;


local function priv_AddJuwels(db)
  db:priv_AddDB("Juwels", 550000);
end;


local function priv_AddGeneralMaterials(db)   -- Allgemeines Material

  db:priv_AddDB("GeneralMaterials", 202861); -- Legenden von Taborea
  db:priv_AddDB("GeneralMaterials", 202862); -- Legenden von Taborea 
  db:priv_AddDB("GeneralMaterials", 202863); -- Legenden von Taborea
  db:priv_AddDB("GeneralMaterials", 202864); -- Legenden von Taborea 
  db:priv_AddDB("GeneralMaterials", 202865); -- Legenden von Taborea
  db:priv_AddDB("GeneralMaterials", 202866); -- Legenden von Taborea 
  db:priv_AddDB("GeneralMaterials", 202867); -- Legenden von Taborea
  db:priv_AddDB("GeneralMaterials", 202868); -- Legenden von Taborea 
  db:priv_AddDB("GeneralMaterials", 202869); -- Legenden von Taborea
  db:priv_AddDB("GeneralMaterials", 202870); -- Legenden von Taborea 
  db:priv_AddDB("GeneralMaterials", 202871); -- Legenden von Taborea
  db:priv_AddDB("GeneralMaterials", 202872); -- Legenden von Taborea 
  db:priv_AddDB("GeneralMaterials", 202873); -- Legenden von Taborea
  db:priv_AddDB("GeneralMaterials", 202874); -- Legenden von Taborea 
  db:priv_AddDB("GeneralMaterials", 202875); -- Legenden von Taborea
  db:priv_AddDB("GeneralMaterials", 202876); -- Legenden von Taborea 
  db:priv_AddDB("GeneralMaterials", 202877); -- Legenden von Taborea 
  
  db:priv_AddDB("GeneralMaterials", 202890); --  
  db:priv_AddDB("GeneralMaterials", 202891); --  

  db:priv_AddDB("GeneralMaterials", 202893); --    
  db:priv_AddDB("GeneralMaterials", 202894); --  
 
  
  
  db:priv_AddDB("GeneralMaterials", 202981); -- Kakao-Bohne
  
  db:priv_AddDB("GeneralMaterials", 202939); -- Lebenskristall
  db:priv_AddDB("GeneralMaterials", 202940); -- Lebenskristall  
  db:priv_AddDB("GeneralMaterials", 202941); -- Lebenskristall  
  db:priv_AddDB("GeneralMaterials", 202942); -- Essenz
  db:priv_AddDB("GeneralMaterials", 202943); -- Essenz 
  db:priv_AddDB("GeneralMaterials", 202944); -- Essenz   
  db:priv_AddDB("GeneralMaterials", 202945); -- Essenz  
  db:priv_AddDB("GeneralMaterials", 202946); -- Essenz
  db:priv_AddDB("GeneralMaterials", 202947); -- Essenz 
  db:priv_AddDB("GeneralMaterials", 202948); -- Essenz  
  
  db:priv_AddDB("GeneralMaterials", 208485); -- Rare Sage Stone
  db:priv_AddDB("GeneralMaterials", 208486); -- Mysterious Sage Stone
  db:priv_AddDB("GeneralMaterials", 203021); -- Heiliger Dunststein
  db:priv_AddDB("GeneralMaterials", 203022); -- Leidenschaftliche Liebe
--  db:priv_AddDB("GeneralMaterials", 203023); -- Liebes-Schokolade

  db:priv_AddDB("GeneralMaterials", 203064); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 203065); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 203066); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 203067); -- Sphäre
  


  db:priv_AddDB("GeneralMaterials", 203025); -- Leichtentz?ndliche Kletterpflanzen-Ranke
  db:priv_AddDB("GeneralMaterials", 203026); -- Flammende Kletterpflanze
  db:priv_AddDB("GeneralMaterials", 203027); -- Ausgezeichneter Schl?ssel

  db:priv_AddDB("GeneralMaterials", 203276); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 203277); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 203278); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 203279); -- Sphäre




  db:priv_AddDB("GeneralMaterials", 203396); -- 
  db:priv_AddDB("GeneralMaterials", 203397); -- 
  db:priv_AddDB("GeneralMaterials", 203398); -- 
  db:priv_AddDB("GeneralMaterials", 203399); -- 

  db:priv_AddDB("GeneralMaterials", 203466); -- Öl
  
  db:priv_AddDB("GeneralMaterials", 203580); -- Sphäre
 
  db:priv_AddDB("GeneralMaterials", 203606); -- Amulett des Lichts 

  db:priv_AddDB("GeneralMaterials", 203680); -- Kapitänsbrandy

  db:priv_AddDB("GeneralMaterials", 204510); --   

  db:priv_AddDB("GeneralMaterials", 204527); -- Nebelsmaragd  
  db:priv_AddDB("GeneralMaterials", 204528); -- Altes Fossil
  db:priv_AddDB("GeneralMaterials", 204529); -- Hormonkristall
  db:priv_AddDB("GeneralMaterials", 204530); -- Transparente Jade
  db:priv_AddDB("GeneralMaterials", 204531); -- Magische Hormone 

  db:priv_AddDB("GeneralMaterials", 204790); -- 
  
  db:priv_AddDB("GeneralMaterials", 204923); -- 
  db:priv_AddDB("GeneralMaterials", 204924); -- 
  db:priv_AddDB("GeneralMaterials", 204925); --  


  
  db:priv_AddDB("GeneralMaterials", 205618); -- Heftfragment
  db:priv_AddDB("GeneralMaterials", 205619); -- Energiefragment
  db:priv_AddDB("GeneralMaterials", 205620); -- Heftfragment
  db:priv_AddDB("GeneralMaterials", 205621); -- Energiefragment
  db:priv_AddDB("GeneralMaterials", 205622); -- Heftfragment
  db:priv_AddDB("GeneralMaterials", 205623); -- Energiefragment
  db:priv_AddDB("GeneralMaterials", 205624); -- Heftfragment
  db:priv_AddDB("GeneralMaterials", 205625); -- Energiefragment
  db:priv_AddDB("GeneralMaterials", 205626); -- Heftfragment
  db:priv_AddDB("GeneralMaterials", 205627); -- Energiefragment
  db:priv_AddDB("GeneralMaterials", 205628); -- Heftfragment
  db:priv_AddDB("GeneralMaterials", 205629); -- Energiefragment

  db:priv_AddDB("GeneralMaterials", 205718); -- Albtraum-Energiekristall
  
  db:priv_AddDB("GeneralMaterials", 205817); -- Beute des Siegers  

  db:priv_AddDB("GeneralMaterials", 205860); -- Albtraum-Kraftpulver

  db:priv_AddDB("GeneralMaterials", 206631); --
  db:priv_AddDB("GeneralMaterials", 206632); --
  db:priv_AddDB("GeneralMaterials", 206633); --
  db:priv_AddDB("GeneralMaterials", 206634); --
  db:priv_AddDB("GeneralMaterials", 206635); --
  db:priv_AddDB("GeneralMaterials", 206636); --
  db:priv_AddDB("GeneralMaterials", 206637); --
  db:priv_AddDB("GeneralMaterials", 206638); --
  db:priv_AddDB("GeneralMaterials", 206639); --
  db:priv_AddDB("GeneralMaterials", 206640); --
  db:priv_AddDB("GeneralMaterials", 206641); --

  db:priv_AddDB("GeneralMaterials", 206690); -- Fragment
  db:priv_AddDB("GeneralMaterials", 206691); -- Fragment
  db:priv_AddDB("GeneralMaterials", 206692); -- Moas
  db:priv_AddDB("GeneralMaterials", 206693); -- Moas


  db:priv_AddDB("GeneralMaterials", 206902); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 206903); -- Sphäre  


  
  
--  db:priv_AddDB("GeneralMaterials", 207921); --
--  db:priv_AddDB("GeneralMaterials", 207922); --
--  db:priv_AddDB("GeneralMaterials", 207923); --
--  db:priv_AddDB("GeneralMaterials", 207924); --
--  db:priv_AddDB("GeneralMaterials", 207925); --
--  db:priv_AddDB("GeneralMaterials", 207926); -- 
--  db:priv_AddDB("GeneralMaterials", 207927); -- 

  db:priv_AddDB("GeneralMaterials", 208156); --
  db:priv_AddDB("GeneralMaterials", 208157); --
  db:priv_AddDB("GeneralMaterials", 208158); --
 
  db:priv_AddDB("GeneralMaterials", 208473); --
  db:priv_AddDB("GeneralMaterials", 208474); --
  db:priv_AddDB("GeneralMaterials", 208475); --
  db:priv_AddDB("GeneralMaterials", 208476); --  
  db:priv_AddDB("GeneralMaterials", 208477); --
  db:priv_AddDB("GeneralMaterials", 208478); --
  db:priv_AddDB("GeneralMaterials", 208479); --	Weisenkraut 96 
  db:priv_AddDB("GeneralMaterials", 208480); --    
  db:priv_AddDB("GeneralMaterials", 208481); --
  db:priv_AddDB("GeneralMaterials", 208482); --
  db:priv_AddDB("GeneralMaterials", 208483); --
  db:priv_AddDB("GeneralMaterials", 208484); --  
  db:priv_AddDB("GeneralMaterials", 208485); --
  db:priv_AddDB("GeneralMaterials", 208486); --

 
  db:priv_AddDB("GeneralMaterials", 208520); -- Hundertgr?ser-Essenz  
  db:priv_AddDB("GeneralMaterials", 208521); -- G?ttlicher magischer Stein

  db:priv_AddDB("GeneralMaterials", 208679); -- Traumland-Kristall


  db:priv_AddDB("GeneralMaterials", 209065); -- Blaue Rosenblüte
 

  db:priv_AddDB("GeneralMaterials", 209715); --
  db:priv_AddDB("GeneralMaterials", 209716); --
  db:priv_AddDB("GeneralMaterials", 209717); --
  db:priv_AddDB("GeneralMaterials", 209718); -- 
  db:priv_AddDB("GeneralMaterials", 209719); --
  db:priv_AddDB("GeneralMaterials", 209720); --
  db:priv_AddDB("GeneralMaterials", 209721); -- 
  db:priv_AddDB("GeneralMaterials", 209722); --
  db:priv_AddDB("GeneralMaterials", 209723); --
  db:priv_AddDB("GeneralMaterials", 209724); --
  db:priv_AddDB("GeneralMaterials", 209725); --
  db:priv_AddDB("GeneralMaterials", 209726); --
  db:priv_AddDB("GeneralMaterials", 209727); --
  db:priv_AddDB("GeneralMaterials", 209728); -- 
  db:priv_AddDB("GeneralMaterials", 209729); --
  db:priv_AddDB("GeneralMaterials", 209730); --
  db:priv_AddDB("GeneralMaterials", 209731); -- 
  db:priv_AddDB("GeneralMaterials", 209732); --
  db:priv_AddDB("GeneralMaterials", 209733); --
  db:priv_AddDB("GeneralMaterials", 209734); --
  db:priv_AddDB("GeneralMaterials", 209735); -- Schneider
  db:priv_AddDB("GeneralMaterials", 209736); --
  db:priv_AddDB("GeneralMaterials", 209737); --
  db:priv_AddDB("GeneralMaterials", 209738); -- 
  db:priv_AddDB("GeneralMaterials", 209739); --
  db:priv_AddDB("GeneralMaterials", 209740); --
  db:priv_AddDB("GeneralMaterials", 209741); -- 
  db:priv_AddDB("GeneralMaterials", 209742); --
  db:priv_AddDB("GeneralMaterials", 209743); --
  db:priv_AddDB("GeneralMaterials", 209744); --
  db:priv_AddDB("GeneralMaterials", 209745); --
  db:priv_AddDB("GeneralMaterials", 209746); --
  db:priv_AddDB("GeneralMaterials", 209747); --
  db:priv_AddDB("GeneralMaterials", 209748); -- 
  db:priv_AddDB("GeneralMaterials", 209749); --
  db:priv_AddDB("GeneralMaterials", 209750); --
  db:priv_AddDB("GeneralMaterials", 209751); -- Rüstung
  db:priv_AddDB("GeneralMaterials", 209752); --
  db:priv_AddDB("GeneralMaterials", 209753); --
  db:priv_AddDB("GeneralMaterials", 209754); --
  db:priv_AddDB("GeneralMaterials", 209755); --
  db:priv_AddDB("GeneralMaterials", 209756); --
  db:priv_AddDB("GeneralMaterials", 209757); --
  db:priv_AddDB("GeneralMaterials", 209758); -- Kristall
--  db:priv_AddDB("GeneralMaterials", 209759); --
--  db:priv_AddDB("GeneralMaterials", 209760); -- lila
  
  db:priv_AddDB("GeneralMaterials", 209978); -- Sphäre  
  db:priv_AddDB("GeneralMaterials", 209979); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 209980); -- Sphäre  
  db:priv_AddDB("GeneralMaterials", 209981); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 209982); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 209983); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 209984); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 209985); -- Sphäre

  db:priv_AddDB("GeneralMaterials", 240255); -- Gew?hnliches Pergament aus Lammhaut
  db:priv_AddDB("GeneralMaterials", 240256); -- Gew?hnliches Pergament von Dalanis
  db:priv_AddDB("GeneralMaterials", 240258); -- Braunes Kohlepulver
  db:priv_AddDB("GeneralMaterials", 240261); -- Normale M?nze
  db:priv_AddDB("GeneralMaterials", 240262); -- Normales Boot
  db:priv_AddDB("GeneralMaterials", 240263); -- Unbekannte Fl?ssigkeit
  

  db:priv_AddDB("GeneralMaterials", 240269); -- Zwergenschnaps

  db:priv_AddDB("GeneralMaterials", 240502); -- 
  db:priv_AddDB("GeneralMaterials", 240503); -- 
  db:priv_AddDB("GeneralMaterials", 240504); -- 
  db:priv_AddDB("GeneralMaterials", 240505); -- 

  db:priv_AddDB("GeneralMaterials", 240520); -- 
  db:priv_AddDB("GeneralMaterials", 240521); -- 
  db:priv_AddDB("GeneralMaterials", 240522); -- 
  
  db:priv_AddDB("GeneralMaterials", 240568); -- Waffentruhe

  db:priv_AddDB("GeneralMaterials", 240584); -- Sphäre

  db:priv_AddDB("GeneralMaterials", 240600); --
  db:priv_AddDB("GeneralMaterials", 240601); --
  db:priv_AddDB("GeneralMaterials", 240602); --

  db:priv_AddDB("GeneralMaterials", 240607); -- Altes magisches Märchenbuch
  db:priv_AddDB("GeneralMaterials", 240608); -- Zerrissene Seite -
  db:priv_AddDB("GeneralMaterials", 240609); -- Zerrissene Seite -
  db:priv_AddDB("GeneralMaterials", 240610); -- Zerrissene Seite -
  db:priv_AddDB("GeneralMaterials", 240611); -- Zerrissene Seite -
  db:priv_AddDB("GeneralMaterials", 240612); -- Zerrissene Seite -
  db:priv_AddDB("GeneralMaterials", 240613); -- Zerrissene Seite -
  db:priv_AddDB("GeneralMaterials", 240614); -- Zerrissene Seite -
  db:priv_AddDB("GeneralMaterials", 240615); -- Zerrissene Seite -  
  db:priv_AddDB("GeneralMaterials", 240616); -- Zerrissene Seite -    


  db:priv_AddDB("GeneralMaterials", 240638); -- Meeresenergie-Kristall

  db:priv_AddDB("GeneralMaterials", 240640); -- Zerrissene Partitur    

  db:priv_AddDB("GeneralMaterials", 240772); -- 
  db:priv_AddDB("GeneralMaterials", 240773); --  

  db:priv_AddDB("GeneralMaterials", 240993); -- 
  db:priv_AddDB("GeneralMaterials", 240994); --  
  db:priv_AddDB("GeneralMaterials", 240995); -- 
  db:priv_AddDB("GeneralMaterials", 240996); -- 

  db:priv_AddDB("GeneralMaterials", 241100); --
  
  db:priv_AddDB("GeneralMaterials", 241111); -- Großmagierbrief
  db:priv_AddDB("GeneralMaterials", 241112); --
  db:priv_AddDB("GeneralMaterials", 241114); -- Erlesenes Band

  db:priv_AddDB("GeneralMaterials", 241119); --

  db:priv_AddDB("GeneralMaterials", 241124); --
  db:priv_AddDB("GeneralMaterials", 241125); --
--  db:priv_AddDB("GeneralMaterials", 241126); --
--  db:priv_AddDB("GeneralMaterials", 241127); --
--  db:priv_AddDB("GeneralMaterials", 241128); --
--  db:priv_AddDB("GeneralMaterials", 241129); --
--  db:priv_AddDB("GeneralMaterials", 241130); --

  db:priv_AddDB("GeneralMaterials", 241141); --
  db:priv_AddDB("GeneralMaterials", 241142); --
  db:priv_AddDB("GeneralMaterials", 241143); --
  db:priv_AddDB("GeneralMaterials", 241144); --
  
  db:priv_AddDB("GeneralMaterials", 241182); --
  db:priv_AddDB("GeneralMaterials", 241183); --
  
  db:priv_AddDB("GeneralMaterials", 241968); --
  db:priv_AddDB("GeneralMaterials", 241969); --
  db:priv_AddDB("GeneralMaterials", 241970); --

  db:priv_AddDB("GeneralMaterials", 242546); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 242547); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 242548); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 242549); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 242550); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 242551); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 242552); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 242553); -- Sphäre
  db:priv_AddDB("GeneralMaterials", 242554); -- Sphäre

  db:priv_AddDB("GeneralMaterials", 242673); -- Sphäre


  db:priv_AddDB("GeneralMaterials", 243223); -- Essenz
  db:priv_AddDB("GeneralMaterials", 243224); -- Essenz
  db:priv_AddDB("GeneralMaterials", 243225); -- Essenz
  db:priv_AddDB("GeneralMaterials", 243226); -- Essenz
  db:priv_AddDB("GeneralMaterials", 243227); -- Essenz
  db:priv_AddDB("GeneralMaterials", 243228); -- Fantastisches
  db:priv_AddDB("GeneralMaterials", 243229); -- Fantastisches  
  db:priv_AddDB("GeneralMaterials", 243230); -- 
  db:priv_AddDB("GeneralMaterials", 243231); -- 
  db:priv_AddDB("GeneralMaterials", 243232); -- 
  db:priv_AddDB("GeneralMaterials", 243233); -- 
  db:priv_AddDB("GeneralMaterials", 243234); -- 
  db:priv_AddDB("GeneralMaterials", 243235); -- 
  db:priv_AddDB("GeneralMaterials", 243236); -- 
  db:priv_AddDB("GeneralMaterials", 243237); -- 
  db:priv_AddDB("GeneralMaterials", 243238); -- 


  db:priv_AddDB("GeneralMaterials", 243255); -- Kristall der Komprimierung
  db:priv_AddDB("GeneralMaterials", 243256); -- Kristall des tiefen Wassers
  db:priv_AddDB("GeneralMaterials", 243257); -- Kristall der sengenden Hitze
  db:priv_AddDB("GeneralMaterials", 243258); -- Traumland-Kristall
  db:priv_AddDB("GeneralMaterials", 243259); -- Kristall der Resonanz
  db:priv_AddDB("GeneralMaterials", 243260); -- Kristall des Prismas
  db:priv_AddDB("GeneralMaterials", 243261); -- Kristall der Flammenr?te
  db:priv_AddDB("GeneralMaterials", 243262); -- Kristall der Illusion  
   
  db:priv_AddDB("GeneralMaterials", 243264); -- Spezialkatalysator von Haidon    



  
   
--  db:priv_AddDB("GeneralMaterials", 203024); -- Segnung des Blumengottes

end


local function priv_AddRawMaterials(db)  -- RohMaterial, Verarbeitete Güter

  db:priv_AddDB("RawMaterials", 200473); -- Apple
  db:priv_AddDB("RawMaterials", 200479); -- Grape
  db:priv_AddDB("RawMaterials", 200480); -- Pineapple
  db:priv_AddDB("RawMaterials", 200489); -- Lettuce
  db:priv_AddDB("RawMaterials", 200491); -- Celery
  db:priv_AddDB("RawMaterials", 200528); -- Small Fish
  db:priv_AddDB("RawMaterials", 200529); -- Salmon
  db:priv_AddDB("RawMaterials", 200530); -- Blue Trout
  db:priv_AddDB("RawMaterials", 200532); -- Bass
  db:priv_AddDB("RawMaterials", 200534); -- Arapaima
  db:priv_AddDB("RawMaterials", 200543); -- Spiny Lobster
  db:priv_AddDB("RawMaterials", 200766); -- Bird Meat
  db:priv_AddDB("RawMaterials", 200767); -- Delicious Worm Meat
  db:priv_AddDB("RawMaterials", 200782); -- Cream
  db:priv_AddDB("RawMaterials", 201534); -- Newborn Boar Tusk
  db:priv_AddDB("RawMaterials", 201536); -- Wandering Ent Bud
  db:priv_AddDB("RawMaterials", 201537); -- Snow Frog Placenta
  db:priv_AddDB("RawMaterials", 201538); -- Young Ostrich's Egg
  db:priv_AddDB("RawMaterials", 201539); -- Green-spotted Fungus Bread
  db:priv_AddDB("RawMaterials", 201540); -- Highlands Demon Weed Seed
  db:priv_AddDB("RawMaterials", 201950); -- Small Empty Bottle
  db:priv_AddDB("RawMaterials", 201951); -- Beaker
  db:priv_AddDB("RawMaterials", 201952); -- Alchemy Bottle
  db:priv_AddDB("RawMaterials", 201953); -- Philosopher's Egg
  db:priv_AddDB("RawMaterials", 201967); -- 
  db:priv_AddDB("RawMaterials", 202101); -- Stone of the Golden Planet
  db:priv_AddDB("RawMaterials", 202102); -- Stone of the Tree Planet
  db:priv_AddDB("RawMaterials", 202103); -- Stone of the Water Planet
  db:priv_AddDB("RawMaterials", 202104); -- Stone of Fire Planet
  db:priv_AddDB("RawMaterials", 202105); -- Stone of the Earth Planet
  db:priv_AddDB("RawMaterials", 202106); -- Stone of the Water King Planet
  db:priv_AddDB("RawMaterials", 202107); -- Stone of the Planet of the Heavnly King
  db:priv_AddDB("RawMaterials", 202108); -- Stone of the Planet of the King of Darkness
  db:priv_AddDB("RawMaterials", 202109); -- Wooden Nail
  db:priv_AddDB("RawMaterials", 202110); -- Copper Nail
  db:priv_AddDB("RawMaterials", 202111); -- Iron Nail
  db:priv_AddDB("RawMaterials", 202112); -- Aluminum Nail
  db:priv_AddDB("RawMaterials", 202113); -- Steel Nail
  db:priv_AddDB("RawMaterials", 202114); -- Silver Nail
  db:priv_AddDB("RawMaterials", 202115); -- Platinum Nail
  db:priv_AddDB("RawMaterials", 202116); -- Gold Nail
  db:priv_AddDB("RawMaterials", 202117); -- Alpha Metal Stone
  db:priv_AddDB("RawMaterials", 202118); -- Beta Metal Stone
  db:priv_AddDB("RawMaterials", 202119); -- Gamma Metal Stone
  db:priv_AddDB("RawMaterials", 202120); -- Delta Metal Stone
  db:priv_AddDB("RawMaterials", 202121); -- Epsilon Metal Stone
  db:priv_AddDB("RawMaterials", 202122); -- Zeta Metal Stone
  db:priv_AddDB("RawMaterials", 202123); -- Eta Metal Stone
  db:priv_AddDB("RawMaterials", 202124); -- Thet Metal Stone
  db:priv_AddDB("RawMaterials", 202125); -- Aloeswood Fiber
  db:priv_AddDB("RawMaterials", 202126); -- Calamus Fiber
  db:priv_AddDB("RawMaterials", 202127); -- Tulipwood Fiber
  db:priv_AddDB("RawMaterials", 202128); -- Balloonflower Fiber
  db:priv_AddDB("RawMaterials", 202129); -- Chestnut Fiber
  db:priv_AddDB("RawMaterials", 202130); -- Pine Fiber
  db:priv_AddDB("RawMaterials", 202131); -- Lapis Lazuli Fiber
  db:priv_AddDB("RawMaterials", 202132); -- Amber Fiber
  
  db:priv_AddDB("RawMaterials", 202984); -- Smashed Fire Essence Fragment
  db:priv_AddDB("RawMaterials", 202985); -- Smashed Water Essence Fragment
  db:priv_AddDB("RawMaterials", 202986); -- Crushed Purple Jade
  db:priv_AddDB("RawMaterials", 202987); -- Gloomy Crystal Sand
  db:priv_AddDB("RawMaterials", 202988); -- Flame Crystal Sand
  db:priv_AddDB("RawMaterials", 202989); -- Sharp Gravel
  db:priv_AddDB("RawMaterials", 202990); -- Refined Fire Essence Nugget
  db:priv_AddDB("RawMaterials", 202991); -- Refined Water Essence Nugget
  db:priv_AddDB("RawMaterials", 202992); -- Tempered Fire Essence Nugget
  db:priv_AddDB("RawMaterials", 202993); -- Tempered Water Essence Nugget
  db:priv_AddDB("RawMaterials", 202994); -- Very Low Magic Element
  db:priv_AddDB("RawMaterials", 203005); -- Low Magic Element
  db:priv_AddDB("RawMaterials", 203006); -- Very Low Rune Power
  db:priv_AddDB("RawMaterials", 203007); -- Low Rune Power
  db:priv_AddDB("RawMaterials", 203008); -- Crimson Hog Hide
  db:priv_AddDB("RawMaterials", 203009); -- Damaged Kobold Battle Axe
  db:priv_AddDB("RawMaterials", 203010); -- Worn Kobold Robe
  db:priv_AddDB("RawMaterials", 203011); -- Broken Goblin Staff
  db:priv_AddDB("RawMaterials", 203012); -- Damaged Fine Repeating Crossbow
  db:priv_AddDB("RawMaterials", 203013); -- Kobold Crown Fragment
  db:priv_AddDB("RawMaterials", 203014); -- Gem From Hammertooth Mask
  db:priv_AddDB("RawMaterials", 203015); -- Assassin's Sword Hilt
  db:priv_AddDB("RawMaterials", 203016); -- Gomio's Rucksack
  db:priv_AddDB("RawMaterials", 203017); -- Elemental Crystal
  db:priv_AddDB("RawMaterials", 203018); -- Rune Crystal
  db:priv_AddDB("RawMaterials", 203019); -- Medium Magic Element
  db:priv_AddDB("RawMaterials", 203020); -- Medium Rune Power
  db:priv_AddDB("RawMaterials", 203028); -- Handwerkerrezept-Gutschein
  db:priv_AddDB("RawMaterials", 203033); -- Pferde-Mietschein  
  db:priv_AddDB("RawMaterials", 203395); -- Magic Bottle
  db:priv_AddDB("RawMaterials", 203418); -- Frog Meat
  db:priv_AddDB("RawMaterials", 203419); -- Animal Meat
  db:priv_AddDB("RawMaterials", 203420); -- Rare Animal Meat
  db:priv_AddDB("RawMaterials", 203421); -- Flour
  db:priv_AddDB("RawMaterials", 203422); -- High Quality Flour
  db:priv_AddDB("RawMaterials", 203423); -- Golden Flour
  db:priv_AddDB("RawMaterials", 203424); -- Witchcraft Sugar
  db:priv_AddDB("RawMaterials", 203425); -- Kakao  
  db:priv_AddDB("RawMaterials", 203426); -- Garlic
  db:priv_AddDB("RawMaterials", 203427); -- Mushroom
  db:priv_AddDB("RawMaterials", 203428); -- Oriental Tea Leaves
  db:priv_AddDB("RawMaterials", 203635); -- Materialienpaket f?r magische Instrumente  
  db:priv_AddDB("RawMaterials", 204529); -- Hormone Crystal
  db:priv_AddDB("RawMaterials", 205689); -- 
  db:priv_AddDB("RawMaterials", 205690); -- Ehrenmedaille
  db:priv_AddDB("RawMaterials", 205691); -- 
  db:priv_AddDB("RawMaterials", 205692); -- 
  db:priv_AddDB("RawMaterials", 205693); -- 
  db:priv_AddDB("RawMaterials", 205694); -- 
  db:priv_AddDB("RawMaterials", 205695); -- 
  db:priv_AddDB("RawMaterials", 205696); -- 
  db:priv_AddDB("RawMaterials", 205697); -- 
  db:priv_AddDB("RawMaterials", 205698); -- Giftiges Skorpionbein
  db:priv_AddDB("RawMaterials", 205699); -- 
  
  db:priv_AddDB("RawMaterials", 205728); -- Feyenloth's Broken Soul
  db:priv_AddDB("RawMaterials", 205729); -- Feyenloth's Fear
  
  db:priv_AddDB("RawMaterials", 205811); -- Prayer of Resting
  
  db:priv_AddDB("RawMaterials", 205818); --  
  db:priv_AddDB("RawMaterials", 205819); --   
 

  
  db:priv_AddDB("RawMaterials", 205820); --  
  db:priv_AddDB("RawMaterials", 205821); --     
  db:priv_AddDB("RawMaterials", 205822); -- Prayer of Repletion
  db:priv_AddDB("RawMaterials", 205823); -- Payer of Life
  db:priv_AddDB("RawMaterials", 205824); -- Prayer of Weaving
  db:priv_AddDB("RawMaterials", 205825); -- Prayer of Struggle
  db:priv_AddDB("RawMaterials", 205826); -- Prayer of Protection
  db:priv_AddDB("RawMaterials", 205827); -- Feyenloth's Tranquility
  db:priv_AddDB("RawMaterials", 205828); -- Feyenloth's Rest
  db:priv_AddDB("RawMaterials", 205829); -- Feyenloth's Growth
  db:priv_AddDB("RawMaterials", 205830); -- Feyenloth's Return
  db:priv_AddDB("RawMaterials", 205831); -- Feyenloth's Rage
  db:priv_AddDB("RawMaterials", 205832); -- Strange Magical Leaf
  db:priv_AddDB("RawMaterials", 205844); -- Elementarer Hammerball
  db:priv_AddDB("RawMaterials", 205845); -- Seelenloser Androlier
  db:priv_AddDB("RawMaterials", 205846); -- Riesenkrebs-Schere

  db:priv_AddDB("RawMaterials", 205980); --
  db:priv_AddDB("RawMaterials", 205981); --
  db:priv_AddDB("RawMaterials", 205982); --
  db:priv_AddDB("RawMaterials", 205983); --
  db:priv_AddDB("RawMaterials", 205984); --
  db:priv_AddDB("RawMaterials", 205985); --
  db:priv_AddDB("RawMaterials", 205986); --
  db:priv_AddDB("RawMaterials", 205987); --
  db:priv_AddDB("RawMaterials", 205988); --
  db:priv_AddDB("RawMaterials", 205989); --

   
  db:priv_AddDB("RawMaterials", 206026); -- ?????
  db:priv_AddDB("RawMaterials", 206027); -- ?????
  db:priv_AddDB("RawMaterials", 206028); -- Resilient Dragon Skin
  db:priv_AddDB("RawMaterials", 206029); -- ?????
  db:priv_AddDB("RawMaterials", 206030); -- ?????
  db:priv_AddDB("RawMaterials", 206031); -- ?????
  db:priv_AddDB("RawMaterials", 206032); -- ?????
  db:priv_AddDB("RawMaterials", 206033); -- ?????
  db:priv_AddDB("RawMaterials", 206034); -- ?????
  db:priv_AddDB("RawMaterials", 206035); -- ?????
  db:priv_AddDB("RawMaterials", 206036); -- ?????
  db:priv_AddDB("RawMaterials", 206037); -- ?????
  db:priv_AddDB("RawMaterials", 206038); -- ?????
  db:priv_AddDB("RawMaterials", 206039); -- ?????
  db:priv_AddDB("RawMaterials", 206039); -- ?????
  db:priv_AddDB("RawMaterials", 206040); -- ?????
  db:priv_AddDB("RawMaterials", 206041); -- ?????
  db:priv_AddDB("RawMaterials", 207409); -- Harvest God Star Stone
  db:priv_AddDB("RawMaterials", 207410); -- Wisdom God Star Stone
  db:priv_AddDB("RawMaterials", 207411); -- White Gold Nail
  db:priv_AddDB("RawMaterials", 207412); -- Wolfram Nail
  db:priv_AddDB("RawMaterials", 207413); -- Soaring Tower Metal Stone
  db:priv_AddDB("RawMaterials", 207414); -- Shigassa Metal Stone
  db:priv_AddDB("RawMaterials", 207415); -- Soaring Tower Metal Stone
  db:priv_AddDB("RawMaterials", 207416); -- Sago Palm Fiber
  db:priv_AddDB("RawMaterials", 208252); -- Fertile Goddess Star Stone
  db:priv_AddDB("RawMaterials", 208253); -- Mottled Copper Nail
  db:priv_AddDB("RawMaterials", 208254); -- Ikes' Metal Stone
  db:priv_AddDB("RawMaterials", 208255); -- Flax
  db:priv_AddDB("RawMaterials", 240072); -- Secret Spice
  db:priv_AddDB("RawMaterials", 240073); -- Unicorn Tail
  db:priv_AddDB("RawMaterials", 240074); -- Silver Feather Silk
  db:priv_AddDB("RawMaterials", 240075); -- Dragon Skin
  db:priv_AddDB("RawMaterials", 240076); -- Spiritwood Branch
  db:priv_AddDB("RawMaterials", 240077); -- Colorful Iron Sand
  db:priv_AddDB("RawMaterials", 240410); -- Dark Planet Stone
  db:priv_AddDB("RawMaterials", 240411); -- White Iron Nail
  db:priv_AddDB("RawMaterials", 240412); -- Sigma Metal Stone
  db:priv_AddDB("RawMaterials", 240413); -- Palm Fiber
  db:priv_AddDB("RawMaterials", 241463); -- Star Of Discord
  db:priv_AddDB("RawMaterials", 241464); -- Dark Silver Nail
  db:priv_AddDB("RawMaterials", 241465); -- Ruite Metal Stone
  db:priv_AddDB("RawMaterials", 241466); -- Ginkgo Fiber
  db:priv_AddDB("RawMaterials", 241747); -- Mukhans Axt
  db:priv_AddDB("RawMaterials", 241748); -- Kristallquelle
  db:priv_AddDB("RawMaterials", 241749); -- Blumenranke
  db:priv_AddDB("RawMaterials", 241750); -- Staub der Erweckung
  db:priv_AddDB("RawMaterials", 241751); -- Fliegender Dolch des Jongleurs
  db:priv_AddDB("RawMaterials", 241752); -- Stoffpuppenf?llwatte
  db:priv_AddDB("RawMaterials", 241753); -- Kraftkern
  db:priv_AddDB("RawMaterials", 241754); -- Schwebekern
  db:priv_AddDB("RawMaterials", 241755); -- Quelle des Lebens
  db:priv_AddDB("RawMaterials", 241756); -- Fl?gel des Todes
  db:priv_AddDB("RawMaterials", 241818); -- Grabpuppe
  db:priv_AddDB("RawMaterials", 241819); -- Puppenfl?gel
  db:priv_AddDB("RawMaterials", 241820); -- Frost Breath
  db:priv_AddDB("RawMaterials", 241820); -- Frostatem
  db:priv_AddDB("RawMaterials", 241821); -- Giftige Fl?ssigkeit
  db:priv_AddDB("RawMaterials", 241822); -- Schattenkristall
  db:priv_AddDB("RawMaterials", 241823); -- Handwerkserz
  db:priv_AddDB("RawMaterials", 241824); -- Klebrige Spinnenf?den
  db:priv_AddDB("RawMaterials", 241825); -- Blitzenergie
  db:priv_AddDB("RawMaterials", 241826); -- T?ckische Energie
  db:priv_AddDB("RawMaterials", 241827); -- Lautloser Runenstein
  db:priv_AddDB("RawMaterials", 242063); -- Hebe
  db:priv_AddDB("RawMaterials", 242064); -- Silver Nail
  db:priv_AddDB("RawMaterials", 242065); -- Impeth Metal Stone
  db:priv_AddDB("RawMaterials", 242066); -- Mulberry Fiber
  db:priv_AddDB("RawMaterials", 242314); -- Siren Star
  db:priv_AddDB("RawMaterials", 242315); -- Tin Nail
  db:priv_AddDB("RawMaterials", 242316); -- Desny Metal Stone
  db:priv_AddDB("RawMaterials", 242317); -- Green Fibre
  db:priv_AddDB("RawMaterials", 242318); -- Peace Stone
  db:priv_AddDB("RawMaterials", 242319); -- Silver-Mercury Nail
  db:priv_AddDB("RawMaterials", 242320); -- Rogi Metal Stone
  db:priv_AddDB("RawMaterials", 242321); -- Cotton Fiber
  db:priv_AddDB("RawMaterials", 242322); -- Lotus Star
  db:priv_AddDB("RawMaterials", 242323); -- Wolfram Gold Nail
  db:priv_AddDB("RawMaterials", 242324); -- Floyd Metal Stone
  db:priv_AddDB("RawMaterials", 242325); -- Beach Fibre
  db:priv_AddDB("RawMaterials", 242326); -- Rainbow Star
  db:priv_AddDB("RawMaterials", 242327); -- Silver Copper Nail
  db:priv_AddDB("RawMaterials", 242328); -- Gutis Metal Stone
  db:priv_AddDB("RawMaterials", 242329); -- Mineral Wolf Fibre
  
  
  -- Boss Furniture
  
end

-- Supplies
local function priv_AddFoodsDesserts(db)   -- Essen

  db:priv_AddDB("FoodsDesserts", 200083); -- Roasted Fish
  db:priv_AddDB("FoodsDesserts", 200084); -- Roasted Meat
  db:priv_AddDB("FoodsDesserts", 200085); -- Roasted Salty Fish
  db:priv_AddDB("FoodsDesserts", 200086); -- Garlic Roasted Meat
  db:priv_AddDB("FoodsDesserts", 200089); -- Salted Fish
  db:priv_AddDB("FoodsDesserts", 200090); -- Smoked Bacon
  db:priv_AddDB("FoodsDesserts", 200091); -- Salted Fish with Sauce
  db:priv_AddDB("FoodsDesserts", 200092); -- Smoked Bacon with Herbs
  db:priv_AddDB("FoodsDesserts", 200095); -- Honey Roasted Chicken
  db:priv_AddDB("FoodsDesserts", 200096); -- Fish Egg Sandwich
  db:priv_AddDB("FoodsDesserts", 200097); -- Crisp Honey-roasted Chicken
  db:priv_AddDB("FoodsDesserts", 200098); -- Caviar Sandwich
  db:priv_AddDB("FoodsDesserts", 200101); -- Creamy Seafood Pie
  db:priv_AddDB("FoodsDesserts", 200102); -- Meatsauce Burrito
  db:priv_AddDB("FoodsDesserts", 200103); -- Deluxe Seafood
  db:priv_AddDB("FoodsDesserts", 200104); -- Spicy Meatsauce Burrito
  db:priv_AddDB("FoodsDesserts", 200107); -- Swamp Mix
  db:priv_AddDB("FoodsDesserts", 200108); -- Seaworm Salad
  db:priv_AddDB("FoodsDesserts", 200109); -- Delicious Swamp Mix
  db:priv_AddDB("FoodsDesserts", 200110); -- Unimaginable Salad
  db:priv_AddDB("FoodsDesserts", 200113); -- General's Three-color Sausage
  db:priv_AddDB("FoodsDesserts", 200114); -- Cheese Fishcake
  db:priv_AddDB("FoodsDesserts", 200115); -- Moti Blended Sausage
  db:priv_AddDB("FoodsDesserts", 200115); -- Motis gemischte Wurst  
  db:priv_AddDB("FoodsDesserts", 200116); -- Imperial Seafood Pie
  db:priv_AddDB("FoodsDesserts", 200119); -- Dragon's Banquet
  db:priv_AddDB("FoodsDesserts", 200121); -- Doom's Banquet
  db:priv_AddDB("FoodsDesserts", 200123); -- Sour Cheeseball
  db:priv_AddDB("FoodsDesserts", 200124); -- Herbal Fruit
  db:priv_AddDB("FoodsDesserts", 200125); -- Fruits and Cheese
  db:priv_AddDB("FoodsDesserts", 200126); -- Aromatic Fruit
  db:priv_AddDB("FoodsDesserts", 200127); -- Sweet Deep-fried Doughnuts
  db:priv_AddDB("FoodsDesserts", 200128); -- Bread and Jam
  db:priv_AddDB("FoodsDesserts", 200129); -- Crisp Doughnuts
  db:priv_AddDB("FoodsDesserts", 200130); -- Sweet Fruit Bread
  db:priv_AddDB("FoodsDesserts", 200131); -- Garlic Bread
  db:priv_AddDB("FoodsDesserts", 200132); -- Meat and Bread
  db:priv_AddDB("FoodsDesserts", 200133); -- Garlic Bread with Herbs
  db:priv_AddDB("FoodsDesserts", 200134); -- Excellent Meat and Bread
  db:priv_AddDB("FoodsDesserts", 200135); -- Mushroom Pie
  db:priv_AddDB("FoodsDesserts", 200136); -- Crystal Sugar
  db:priv_AddDB("FoodsDesserts", 200137); -- Delicious Mushroom Pie
  db:priv_AddDB("FoodsDesserts", 200138); -- Rainbow Crystal Candy
  db:priv_AddDB("FoodsDesserts", 200139); -- Exotic Fruit Pie
  db:priv_AddDB("FoodsDesserts", 200140); -- Green Soft Cake
  db:priv_AddDB("FoodsDesserts", 200141); -- Magic Fruit Pie
  db:priv_AddDB("FoodsDesserts", 200142); -- Forestsong Soft Cake
  db:priv_AddDB("FoodsDesserts", 200143); -- Tea-scented Waffle
  db:priv_AddDB("FoodsDesserts", 200144); -- Cocoa Shortbread with Herbs
  db:priv_AddDB("FoodsDesserts", 200145); -- Exquisite Tea-scented Muffins
  db:priv_AddDB("FoodsDesserts", 200146); -- Exquisite Cocoa Shortbread
  db:priv_AddDB("FoodsDesserts", 200147); -- Wizard's Rations
  db:priv_AddDB("FoodsDesserts", 200148); -- Dreamland Fruit
  db:priv_AddDB("FoodsDesserts", 200149); -- Laor Forest Tart
  db:priv_AddDB("FoodsDesserts", 200150); -- Serenstum
  db:priv_AddDB("FoodsDesserts", 200359); -- Hot Stew
  db:priv_AddDB("FoodsDesserts", 200776); -- Necropolis Cake
  db:priv_AddDB("FoodsDesserts", 201532); -- Surprising Broth
  db:priv_AddDB("FoodsDesserts", 201533); -- Little Magic Biscuit
  db:priv_AddDB("FoodsDesserts", 202239); -- Red Bean Rice Dumplings
  db:priv_AddDB("FoodsDesserts", 202240); -- Egg Rice Dumplings
  db:priv_AddDB("FoodsDesserts", 202241); -- Realgar Wine
  db:priv_AddDB("FoodsDesserts", 202242); -- Aged Realgar Wine
--  db:priv_AddDB("FoodsDesserts", 203023); -- Love Chocolate
  db:priv_AddDB("FoodsDesserts", 203127); -- Dexterity Pumpkin Pie
  
  db:priv_AddDB("FoodsDesserts", 203159); -- 
  db:priv_AddDB("FoodsDesserts", 203160); -- 
  
  db:priv_AddDB("FoodsDesserts", 203281); -- Chocolate
  db:priv_AddDB("FoodsDesserts", 203794); -- Roasted Bacon
  db:priv_AddDB("FoodsDesserts", 203795); -- Juicy Roasted Wing
  db:priv_AddDB("FoodsDesserts", 203796); -- Baked Seafood Pie
  db:priv_AddDB("FoodsDesserts", 203797); -- Cyclops Burrito
  db:priv_AddDB("FoodsDesserts", 203798); -- Flaming Sandwich
  db:priv_AddDB("FoodsDesserts", 203799); -- Delicious Seafood Salad
  db:priv_AddDB("FoodsDesserts", 203800); -- Superior Swamp Mix
  db:priv_AddDB("FoodsDesserts", 203801); -- Miracle Salad
  db:priv_AddDB("FoodsDesserts", 203802); -- Special Canyon Mix
  db:priv_AddDB("FoodsDesserts", 203803); -- Scalok Sausage
  db:priv_AddDB("FoodsDesserts", 203859); -- Wine
  db:priv_AddDB("FoodsDesserts", 203861); -- Cheese Cake
  db:priv_AddDB("FoodsDesserts", 203863); -- Chocolate Crisp
  db:priv_AddDB("FoodsDesserts", 206800); -- Spezial-K?sesuppe
  
  db:priv_AddDB("FoodsDesserts", 207595); -- Bitter Dark Chocolate
  db:priv_AddDB("FoodsDesserts", 207596); -- Ordinary Chocolate
  db:priv_AddDB("FoodsDesserts", 207597); -- Milk Chocolate
  

  db:priv_AddDB("FoodsDesserts", 207600); --
  db:priv_AddDB("FoodsDesserts", 207601); --
  db:priv_AddDB("FoodsDesserts", 207602); --
  db:priv_AddDB("FoodsDesserts", 207603); -- Tr?ffelschokolade
  db:priv_AddDB("FoodsDesserts", 207604); --
  db:priv_AddDB("FoodsDesserts", 207605); --
  db:priv_AddDB("FoodsDesserts", 207606); --
  db:priv_AddDB("FoodsDesserts", 207607); --
  db:priv_AddDB("FoodsDesserts", 207608); --
  db:priv_AddDB("FoodsDesserts", 207609); --  
  db:priv_AddDB("FoodsDesserts", 207610); --
  db:priv_AddDB("FoodsDesserts", 207611); --
  db:priv_AddDB("FoodsDesserts", 207612); --
  
  db:priv_AddDB("FoodsDesserts", 207612); -- Ged?nstetes Fischsteak
  db:priv_AddDB("FoodsDesserts", 207635); -- Loaf of Magic Hard Bread
  db:priv_AddDB("FoodsDesserts", 207636); -- Loaf of Handmade Black Bread
  db:priv_AddDB("FoodsDesserts", 207637); -- Light Fluffy Bread
  db:priv_AddDB("FoodsDesserts", 207638); -- Crispy Toast
  db:priv_AddDB("FoodsDesserts", 207639); -- Garlic Bread
  db:priv_AddDB("FoodsDesserts", 207640); -- Sesame Bread
  db:priv_AddDB("FoodsDesserts", 207641); -- Pasty Rolls With Cinnimon
  db:priv_AddDB("FoodsDesserts", 207642); -- Natural Bread
  db:priv_AddDB("FoodsDesserts", 207643); -- Bread with Pygerium Aroma
  db:priv_AddDB("FoodsDesserts", 207644); -- Lettuce Sandwich
  db:priv_AddDB("FoodsDesserts", 207645); -- Meat Sandwich
  db:priv_AddDB("FoodsDesserts", 207646); -- Fried Egg Sandwich
  db:priv_AddDB("FoodsDesserts", 207647); -- Huge Sandwich
  db:priv_AddDB("FoodsDesserts", 207648); -- Berry Sandwich
  db:priv_AddDB("FoodsDesserts", 207649); -- Ham Sandwich
  db:priv_AddDB("FoodsDesserts", 207650); -- Salted Meat Sandwich
  db:priv_AddDB("FoodsDesserts", 207651); -- Smoked Chicken Sandwich
  db:priv_AddDB("FoodsDesserts", 207652); -- Vegetable Sandwich
  db:priv_AddDB("FoodsDesserts", 207653); -- Lightly Burnt Ribs
  db:priv_AddDB("FoodsDesserts", 207654); -- Spiced Rack of Ribs
  db:priv_AddDB("FoodsDesserts", 207655); -- Broiled Ribs
  db:priv_AddDB("FoodsDesserts", 207656); -- Smoked Ribs
  db:priv_AddDB("FoodsDesserts", 207657); -- Fried Ribs
  db:priv_AddDB("FoodsDesserts", 207658); -- Juicy Spare Ribs
  db:priv_AddDB("FoodsDesserts", 207659); -- Peppered Ribs
  db:priv_AddDB("FoodsDesserts", 207660); -- Fried Ribs
  db:priv_AddDB("FoodsDesserts", 207661); -- Honey Ribs
  db:priv_AddDB("FoodsDesserts", 207662); -- Chocolate Cake
  db:priv_AddDB("FoodsDesserts", 207663); -- Cheesecake
  db:priv_AddDB("FoodsDesserts", 207664); -- Butter Cream Cake
  db:priv_AddDB("FoodsDesserts", 207665); -- Honey Cake
  db:priv_AddDB("FoodsDesserts", 207666); -- Berry Cake
  db:priv_AddDB("FoodsDesserts", 207667); -- Strawberry Cake with Cream
  db:priv_AddDB("FoodsDesserts", 207668); -- Vanilla Cake
  db:priv_AddDB("FoodsDesserts", 207669); -- Fruit Tart in a Local Style
  db:priv_AddDB("FoodsDesserts", 207670); -- Birthday Cake
  db:priv_AddDB("FoodsDesserts", 240365); -- Gebratenes Schweinekotlett
  db:priv_AddDB("FoodsDesserts", 240366); -- Schweinerippchen
  db:priv_AddDB("FoodsDesserts", 240368); -- Geschmortes Schweinefleisch
  db:priv_AddDB("FoodsDesserts", 240369); -- Fisch mit Essig
  db:priv_AddDB("FoodsDesserts", 240370); -- Pikantes Fischstaebchen
  db:priv_AddDB("FoodsDesserts", 240371); -- Gelbfisch sья-sauer
  db:priv_AddDB("FoodsDesserts", 240372); -- Tofu-Dorsch

  db:priv_AddDB("FoodsDesserts", 243911); -- Jubiläum-Kirschkuchen
  db:priv_AddDB("FoodsDesserts", 243912); -- Jubiläum-Obstkuchen
  db:priv_AddDB("FoodsDesserts", 243913); -- Jubiläum-Erdbeertorte
  
  -- db:priv_AddDB("FoodsDesserts", 203282); -- Lolllipop
  -- db:priv_AddDB("FoodsDesserts", 203469); -- Snowflake Festival Hat Biscuit
  -- db:priv_AddDB("FoodsDesserts", 203470); -- Snowflake Festival Stocking Biscuit
  -- db:priv_AddDB("FoodsDesserts", 203520); -- Snowflake Festival Candy Cane
  -- db:priv_AddDB("FoodsDesserts", 203521); -- Snowflake Festival Heart Candy
  -- db:priv_AddDB("FoodsDesserts", 203522); -- Snowflake Festival Chocolate
  -- db:priv_AddDB("FoodsDesserts", 203523); -- Snowflake Festival Soft Candy
  -- db:priv_AddDB("FoodsDesserts", 203524); -- Snowflake Festival Lollipop




  
--  db:priv_AddDB("FoodsDesserts", 240525); -- Rainbow Lollipop -- 212192 gebunden, fehlerhafte Anzeige
end


local function priv_AddPotions(db)   -- Tränke

  db:priv_AddDB("Potions", 200018); -- Mysterious Potion
  db:priv_AddDB("Potions", 200151); -- Basic Medicine
  db:priv_AddDB("Potions", 200152); -- Basic Spirit Potion
  db:priv_AddDB("Potions", 200154); -- Basic Healing Potion
  db:priv_AddDB("Potions", 200155); -- Basic Mana Potion
  db:priv_AddDB("Potions", 200159); -- Potion of Speed
  db:priv_AddDB("Potions", 200160); -- Stimulant
  db:priv_AddDB("Potions", 200172); -- Invisibility Potion
  db:priv_AddDB("Potions", 200173); -- Strong Stimulant
  db:priv_AddDB("Potions", 200174); -- Salve
  db:priv_AddDB("Potions", 200175); -- Mana Potion
  db:priv_AddDB("Potions", 200176); -- Witch Doctor Elixir
  db:priv_AddDB("Potions", 200178); -- Healing Potion
  db:priv_AddDB("Potions", 200179); -- Mana Potion
  db:priv_AddDB("Potions", 200192); -- Ancient Spirit Water
  db:priv_AddDB("Potions", 200194); -- Life Source
  db:priv_AddDB("Potions", 200195); -- Mana Source
  db:priv_AddDB("Potions", 200196); -- Superior Collection Potion I
  db:priv_AddDB("Potions", 200197); -- Superior Collection Potion II
  db:priv_AddDB("Potions", 200198); -- Superior Collection Potion III
  db:priv_AddDB("Potions", 200199); -- Touch of the Unicorn
  db:priv_AddDB("Potions", 200225); -- Embrace of the Muse
  db:priv_AddDB("Potions", 200229); -- Strong Medicine
  db:priv_AddDB("Potions", 200270); -- Powerful Spirit Potion
  db:priv_AddDB("Potions", 200271); -- Stimulant Scent
  db:priv_AddDB("Potions", 200272); -- Potion of Holy Power
  db:priv_AddDB("Potions", 200273); -- Potion of Fire Elemental Affinity
  db:priv_AddDB("Potions", 200274); -- Strong Healing Potion
  db:priv_AddDB("Potions", 200275); -- Strong Mana Potion
  db:priv_AddDB("Potions", 200276); -- Purified Stimulating Scent
  db:priv_AddDB("Potions", 200277); -- Hero Potion
  db:priv_AddDB("Potions", 200278); --
  db:priv_AddDB("Potions", 200279); --
  db:priv_AddDB("Potions", 200280); --
  db:priv_AddDB("Potions", 200281); --
  db:priv_AddDB("Potions", 200286); -- Shock Potion
  db:priv_AddDB("Potions", 200418); -- Collection Potion I
  db:priv_AddDB("Potions", 200420); -- Collection Potion II
  db:priv_AddDB("Potions", 200422); -- Collection Potion III
  db:priv_AddDB("Potions", 200424); -- Potion of Potential
  db:priv_AddDB("Potions", 200425); -- Elixir of the Sage
  db:priv_AddDB("Potions", 200426); -- Pacification Powder
  db:priv_AddDB("Potions", 200427); -- Tranquility Powder
  db:priv_AddDB("Potions", 200663); -- Simple First Aid Potion
  db:priv_AddDB("Potions", 200664); -- Basic First Aid Potion
  db:priv_AddDB("Potions", 200807); -- First Aid Potion
  db:priv_AddDB("Potions", 200808); -- Major First Aid Potion
  db:priv_AddDB("Potions", 200811); -- Barbarian Herbs
  db:priv_AddDB("Potions", 200812); -- Healer's First Aid Potion
  db:priv_AddDB("Potions", 200815); -- Regeneration Mixture
  db:priv_AddDB("Potions", 200816); -- Potent Regeneration Formula
  db:priv_AddDB("Potions", 200819); -- Military Regeneration Formula
  db:priv_AddDB("Potions", 200820); -- Ancestral Spirit Herbs
  db:priv_AddDB("Potions", 201042); -- Simple Magic Potion
  db:priv_AddDB("Potions", 201043); -- Basic Magic Potion
  db:priv_AddDB("Potions", 201046); -- Magic Potion
  db:priv_AddDB("Potions", 201047); -- Major Magic Potion
  db:priv_AddDB("Potions", 201052); -- Elemental Mana Stone
  db:priv_AddDB("Potions", 201053); -- Condensed Magic Potion
  db:priv_AddDB("Potions", 201056); -- Crystal Mana Medicine
  db:priv_AddDB("Potions", 201057); -- Potent Crystal Mana Medicine
  db:priv_AddDB("Potions", 201060); -- Refined Crystal Mana Medicine
  db:priv_AddDB("Potions", 201061); -- Elemental Spirit Stone
  db:priv_AddDB("Potions", 202153); -- Universal Potion
  db:priv_AddDB("Potions", 202886); -- Training First-aid Potion
  db:priv_AddDB("Potions", 202887); -- Training Magic Potion
  db:priv_AddDB("Potions", 202906); -- Bean Paste Mooncake
  db:priv_AddDB("Potions", 202907); -- Coconut Mooncake
  db:priv_AddDB("Potions", 203506); -- Potion of Rage
  db:priv_AddDB("Potions", 203507); -- Strength of Battle
  db:priv_AddDB("Potions", 203508); -- Potion of Energy
  db:priv_AddDB("Potions", 203509); -- Potion of Exquisite Skill
  db:priv_AddDB("Potions", 203510); -- Focus Potion
  db:priv_AddDB("Potions", 203511); -- Potion of Focused Will
  db:priv_AddDB("Potions", 203805); -- Fiery Medicine
  db:priv_AddDB("Potions", 203806); -- Powder of Peace
  db:priv_AddDB("Potions", 203807); -- Spellweaver Potion
  db:priv_AddDB("Potions", 203808); -- Transparence Potion
  db:priv_AddDB("Potions", 203809); -- Unicorn's Present
  db:priv_AddDB("Potions", 204130); -- Magical Wine
  db:priv_AddDB("Potions", 204889); -- Spirit Herb
  db:priv_AddDB("Potions", 204890); -- Elemental Spirit Stone
  db:priv_AddDB("Potions", 205861); -- Strength Potion
  db:priv_AddDB("Potions", 205862); -- Potent Strength Potion
  db:priv_AddDB("Potions", 205863); -- Intelligence Potion
  db:priv_AddDB("Potions", 205864); -- Potent Intelligence Potion
  db:priv_AddDB("Potions", 205865); -- Wisdom Potion
  db:priv_AddDB("Potions", 205866); -- Potent Wisdom Potion
  db:priv_AddDB("Potions", 205867); -- Dexterity Potion
  db:priv_AddDB("Potions", 205868); -- Potent Dexterity Potion
  db:priv_AddDB("Potions", 205869); -- Health Potion
  db:priv_AddDB("Potions", 205870); -- Potent Health Potion
  db:priv_AddDB("Potions", 207671); -- Defense Potion
  db:priv_AddDB("Potions", 207672); -- Steel Potion
  db:priv_AddDB("Potions", 207673); -- Cleansing Potion
  db:priv_AddDB("Potions", 207674); -- Divine Healing Potion
  db:priv_AddDB("Potions", 207675); -- Madness Potion
  db:priv_AddDB("Potions", 207676); -- Super Salve
  db:priv_AddDB("Potions", 207677); -- Super Healing Potion
  db:priv_AddDB("Potions", 207678); -- Super Spirit Potion
  db:priv_AddDB("Potions", 207679); -- Super Mana Potion
  db:priv_AddDB("Potions", 207681); -- Strong Magic Potion
  db:priv_AddDB("Potions", 207682); -- Chainlink Strike
  db:priv_AddDB("Potions", 207683); --
  db:priv_AddDB("Potions", 207684); --
  db:priv_AddDB("Potions", 207685); --
  db:priv_AddDB("Potions", 207686); --
  db:priv_AddDB("Potions", 207687); --
  db:priv_AddDB("Potions", 208655); -- Basic Production Speed Potion (1 Day)
  db:priv_AddDB("Potions", 240532); -- Deadly Potion
  db:priv_AddDB("Potions", 240533); -- Strong Magic Potion
  db:priv_AddDB("Potions", 240534); -- Extinction Potion
  db:priv_AddDB("Potions", 240535); -- Extinguish Potion
  db:priv_AddDB("Potions", 242180); --
  db:priv_AddDB("Potions", 242191); --
  db:priv_AddDB("Potions", 242192); --
  db:priv_AddDB("Potions", 242222); --
  db:priv_AddDB("Potions", 242223); --
  db:priv_AddDB("Potions", 242498); --
  db:priv_AddDB("Potions", 242499); --
  db:priv_AddDB("Potions", 242500); --
  db:priv_AddDB("Potions", 242501); --
  db:priv_AddDB("Potions", 242502); --
  db:priv_AddDB("Potions", 242503); --
  db:priv_AddDB("Potions", 242504); --
  db:priv_AddDB("Potions", 242887); --
  db:priv_AddDB("Potions", 242888); --
  db:priv_AddDB("Potions", 242889); --
  db:priv_AddDB("Potions", 242890); --
  db:priv_AddDB("Potions", 242891); --
  db:priv_AddDB("Potions", 242892); --
  db:priv_AddDB("Potions", 242893); --
  db:priv_AddDB("Potions", 242894); --
  db:priv_AddDB("Potions", 242895); --
  db:priv_AddDB("Potions", 242896); --
  db:priv_AddDB("Potions", 242897); --
  db:priv_AddDB("Potions", 242898); --
  db:priv_AddDB("Potions", 242899); --
  db:priv_AddDB("Potions", 242900); --
  db:priv_AddDB("Potions", 242901); --
  db:priv_AddDB("Potions", 242902); --


end


local function priv_AddTQMaterials(db)	-- Material für Tagesquest

  -- Mana Stone


  
  db:priv_AddDB("TQMaterials", 200016);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 200188);   -- Material für TQ  
  
  
  db:priv_AddDB("TQMaterials", 200203);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 200211);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 200406);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 200579);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 200609);   -- Material für TQ  
  
  
  
  db:priv_AddDB("TQMaterials", 200616);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 200617);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 200619);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 200624);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 200670);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 200686);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 200881);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201108);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201109);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201110);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201111);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201112);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201113);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201119);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201120);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201121);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201122);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 201124);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 201126);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201127);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201168);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201169);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 201173);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201256);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201258);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201259);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201260);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201266);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201267);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201286);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 201426);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201427);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201428);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201429);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201430);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201431);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201432);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201433);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201434);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 201462);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201463);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201970);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201994);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201995);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201996);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201997);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201998);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 201999);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 202002);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 202005);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 202011);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 202969);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 202970);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 202971);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 202974);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 202975);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 202976);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 202977);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 202978);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 202979);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 203344);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203345);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203346);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203347);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203348);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203349);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203350);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203351);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203352);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203353);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 203359);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203360);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203361);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 203400);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203620);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203645);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 203709);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204016);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204354);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204355);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 204434);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204435);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204436);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204437);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204438);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204439);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204440);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204441);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204442);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204443);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204444);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204445);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204446);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 204448);   -- Material für TQ
   
  db:priv_AddDB("TQMaterials", 204834);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204835);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204836);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204837);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204838);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204839);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204840);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204841);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204842);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204843);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204844);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 204895);   -- Material für TQ  
  db:priv_AddDB("TQMaterials", 204980);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 204981);   -- Material für TQ
  
  db:priv_AddDB("TQMaterials", 205001);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205002);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205003);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205004);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 205010);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205011);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205012);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205013);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205014);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205015);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205016);   -- Material für TQ
 
  db:priv_AddDB("TQMaterials", 205661);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205662);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205663);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205664);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205665);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205666);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205667);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205668);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205669);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205670);   -- Material für TQ
  
  db:priv_AddDB("TQMaterials", 205727);   -- Material für TQ
 
  db:priv_AddDB("TQMaterials", 205833);   -- Material für TQ  
  db:priv_AddDB("TQMaterials", 205834);   -- Material für TQ  
  
  db:priv_AddDB("TQMaterials", 205915);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205916);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205917);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 205918);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 205954);   -- Material für TQ 
  
  db:priv_AddDB("TQMaterials", 206015);   -- Material für TQ 

  db:priv_AddDB("TQMaterials", 206167);   -- Material für TQ 

  db:priv_AddDB("TQMaterials", 206188);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206189);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206190);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 206392);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206393);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206394);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206395);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 206400);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206401);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206402);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 206404);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206405);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206406);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206407);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 206740);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 206752);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206753);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206754);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206755);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206756);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206757);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206758);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 206759);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 206868);   -- Material für TQ
  
  db:priv_AddDB("TQMaterials", 206915);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 207158);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 207163);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207164);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207165);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207166);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207167);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207168);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207169);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207170);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207171);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 207187);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 207190);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 207275);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 207417);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207418);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207419);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 207432);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207433);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207434);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207435);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207436);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207437);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207438);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207439);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207440);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207441);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207442);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207443);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207444);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207445);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 207446);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 208080);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208081);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208082);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208083);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208084);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208085);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208086);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208087);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208088);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208089);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208090);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208091);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208092);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208093);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208094);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 208488);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208489);   -- Material für TQ
  
  db:priv_AddDB("TQMaterials", 208522);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 208548);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 208550);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 208576);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 208920);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208921);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 208956);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 208977);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 208979);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208980);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208981);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208982);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208983);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208984);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208985);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208986);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 208993);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 208995);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 208996);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209004);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209005);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209006);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209007);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209008);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209009);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209010);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209053);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209060);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209061);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209062);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209063);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209071);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209072);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209078);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209079);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209080);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209081);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209082);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209083);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209084);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209086);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209100);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209101);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209192);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209193);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209425);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209426);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209427);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209428);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209429);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209430);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209431);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209432);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209434);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209435);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209436);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209437);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209438);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209439);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209440);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209441);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209444);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209445);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209446);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209447);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209448);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209449);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209450);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209451);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209452);   -- Material für TQ
--  db:priv_AddDB("TQMaterials", 209453);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209454);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209455);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209456);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209457);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209458);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209459);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209564);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209596);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209597);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 209637);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209638);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209639);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209640);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 209641);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240011);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240012);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240027);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240028);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240029);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240030);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240033);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240221);   -- Material für TQ
  
  db:priv_AddDB("TQMaterials", 240229);   -- Material für TQ
  
  db:priv_AddDB("TQMaterials", 240280);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240281);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240282);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240286);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240292);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240293);   -- Material für TQ
  
  db:priv_AddDB("TQMaterials", 240526);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240527);   -- Material für TQ 
  
  db:priv_AddDB("TQMaterials", 240542);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240543);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240551);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240558);   -- Material für TQ
 
  db:priv_AddDB("TQMaterials", 240591);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240592);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240594);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240596);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240597);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240598);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240606);   -- Material für TQ
 
  db:priv_AddDB("TQMaterials", 240628);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240629);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240630);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240636);   -- Material für TQ

  db:priv_AddDB("TQMaterials", 240653);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240654);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240655);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240656);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240657);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240658);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 240659);   -- Material für TQ
    
  db:priv_AddDB("TQMaterials", 241030);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 241031);   -- Material für TQ  
  
  db:priv_AddDB("TQMaterials", 242056);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 242057);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 242058);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 242059);   -- Material für TQ
  db:priv_AddDB("TQMaterials", 242060);   -- Material für TQ
  
  

end;


local function priv_AddBagStats(db) -- Beutel Item

  db:priv_AddDB("BagStat", 224451); -- Kette von Chassizz - 100 --Beutel
  db:priv_AddDB("BagStat", 227161); -- Ring von Chassizz - 100 --Beutel
  db:priv_AddDB("BagStat", 229868); -- Ohrringe von Chassizz - 100 --Beutel

  db:priv_AddDB("BagStat", 235642); -- Kette von Enoch - 100 --Beutel
  db:priv_AddDB("BagStat", 235643); -- Ring von Enoch - 100 --Beutel
  db:priv_AddDB("BagStat", 235644); -- Ohrringe von Enoch - 100 --Beutel

  db:priv_AddDB("BagStat", 225345); -- Kette von Vortis - 100 --Beutel
  db:priv_AddDB("BagStat", 225346); -- Ring von Vortis  - 100 --Beutel
  db:priv_AddDB("BagStat", 225347); -- Ohrringe von Vortis - 100 --Beutel


  db:priv_AddDB("BagStat", 221919); -- Kette von Korris - 99 --Beutel		xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  db:priv_AddDB("BagStat", 222440); -- Ring von Korris - 99 --Beutel
  db:priv_AddDB("BagStat", 227506); -- Ohrringe von Korris - 99 --Beutel
  
  db:priv_AddDB("BagStat", 222061); -- Tasuqian Necklace - 98
  db:priv_AddDB("BagStat", 222062); -- Tasuqian Ring - 98
  db:priv_AddDB("BagStat", 222063); -- Tasuqian Earring - 98


  db:priv_AddDB("BagStat", 226265); -- Kette von Korris - 97 --Beutel
  db:priv_AddDB("BagStat", 226266); -- Ring von Farsitan - 97 --Beutel
  db:priv_AddDB("BagStat", 226267); -- Ohrringe von Korris - 97 --Beutel

  db:priv_AddDB("BagStat", 233989); --  - 95
  db:priv_AddDB("BagStat", 233988); --  - 95
  db:priv_AddDB("BagStat", 233987); --  - 95
  
end;


local function priv_AddT6clean(db)  -- T6 clean






  db:priv_AddDB("T6clean", 212635);   -- grüne t6er clean   100	Waffe
  db:priv_AddDB("T6clean", 212636);   -- grüne t6er clean   100	Waffe
  db:priv_AddDB("T6clean", 212637);   -- grüne t6er clean   100	Waffe
  db:priv_AddDB("T6clean", 212638);   -- grüne t6er clean   100	Waffe
  db:priv_AddDB("T6clean", 212639);   -- grüne t6er clean   100	Waffe
  db:priv_AddDB("T6clean", 212640);   -- grüne t6er clean   100	Waffe
  db:priv_AddDB("T6clean", 212641);   -- grüne t6er clean   100	Waffe
  db:priv_AddDB("T6clean", 212642);   -- grüne t6er clean   100	Waffe
  db:priv_AddDB("T6clean", 212643);   -- grüne t6er clean   100	Waffe
  db:priv_AddDB("T6clean", 212644);   -- grüne t6er clean   100	Waffe

  db:priv_AddDB("T6clean", 213624);   -- grüne t6er clean   100	Waffe


  db:priv_AddDB("T6clean", 214074);   -- weiss t6er clean   98
  db:priv_AddDB("T6clean", 214075);   -- weiss t6er clean   98


  db:priv_AddDB("T6clean", 215000);  -- grüne t6er clean   100 Chassizz
  db:priv_AddDB("T6clean", 215001);
  db:priv_AddDB("T6clean", 215002);
  db:priv_AddDB("T6clean", 215003);
  db:priv_AddDB("T6clean", 215004);
  db:priv_AddDB("T6clean", 215005);
  db:priv_AddDB("T6clean", 215006);
  db:priv_AddDB("T6clean", 215007);
  db:priv_AddDB("T6clean", 215008);
  db:priv_AddDB("T6clean", 215009);
  db:priv_AddDB("T6clean", 215010);

  

  db:priv_AddDB("T6clean", 215022);  -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 215023);
  db:priv_AddDB("T6clean", 215024);
  db:priv_AddDB("T6clean", 215025);
  db:priv_AddDB("T6clean", 215026);
  db:priv_AddDB("T6clean", 215027);
  db:priv_AddDB("T6clean", 215028);
  db:priv_AddDB("T6clean", 215029);
  db:priv_AddDB("T6clean", 215030);
  db:priv_AddDB("T6clean", 215031);
  db:priv_AddDB("T6clean", 215032);



  db:priv_AddDB("T6clean", 229721);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 229722);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 229723);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 229724);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 229725);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 229726);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 229727);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 229728);   -- grüne t6er clean   100 
  db:priv_AddDB("T6clean", 229729);   -- grüne t6er clean   100 
  

  db:priv_AddDB("T6clean", 230841);   -- grüne t6er clean   100


  db:priv_AddDB("T6clean", 231919);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 231920);   -- grüne t6er clean   100


  db:priv_AddDB("T6clean", 235957);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 235958);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 235959);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 235960);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 235961);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 235962);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 235963);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 235964);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 235965);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 235966);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 235967);   -- grüne t6er clean   100
  db:priv_AddDB("T6clean", 235968);   -- grüne t6er clean   100 



 
  db:priv_AddDB("T6clean", 236331);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236332);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236333);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236334);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236335);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236336);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236337);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236338);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236339);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236340);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236341);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236342);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236343);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236344);   -- weiss t6er clean   99
  db:priv_AddDB("T6clean", 236345);   -- weiss t6er clean   99


  
end


local function priv_AddT698er(db)  -- T6 98/99 clean oder mit Fähigkeit


  db:priv_AddDB("T698er", 214843); -- grüne t6er 98
  db:priv_AddDB("T698er", 214844);
  db:priv_AddDB("T698er", 214845);
  db:priv_AddDB("T698er", 214846);
  db:priv_AddDB("T698er", 214847);
  db:priv_AddDB("T698er", 214848);
  db:priv_AddDB("T698er", 214849);
  db:priv_AddDB("T698er", 214850);
  db:priv_AddDB("T698er", 214851);

  db:priv_AddDB("T698er", 214911);   -- grün t6er   99	gebunden Questbelohnung
  db:priv_AddDB("T698er", 214912);   -- grün t6er   99
  db:priv_AddDB("T698er", 214913);   -- grün t6er   99
  db:priv_AddDB("T698er", 214914);   -- grün t6er   99
  db:priv_AddDB("T698er", 214915);   -- grün t6er   99
  db:priv_AddDB("T698er", 214916);   -- grün t6er   99
  db:priv_AddDB("T698er", 214917);   -- grün t6er   99
  db:priv_AddDB("T698er", 214918);   -- grün t6er   99
  db:priv_AddDB("T698er", 214919);   -- grün t6er   99
  db:priv_AddDB("T698er", 214920);   -- grün t6er   99
  db:priv_AddDB("T698er", 214921);   -- grün t6er   99
  
  db:priv_AddDB("T698er", 214933);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 214934);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 214935);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 214936);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 214937);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 214938);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 214939);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 214940);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 214941);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 214942);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 214943);   -- grün t6er clean   99

  db:priv_AddDB("T698er", 215000);   -- grün t6er 100	Waffe
  db:priv_AddDB("T698er", 215001);   -- grün t6er 100	
  db:priv_AddDB("T698er", 215002);   -- grün t6er 100	
  db:priv_AddDB("T698er", 215003);   -- grün t6er 100	
  db:priv_AddDB("T698er", 215004);   -- grün t6er 100	
  db:priv_AddDB("T698er", 215005);   -- grün t6er 100	
  db:priv_AddDB("T698er", 215006);   -- grün t6er 100	
  db:priv_AddDB("T698er", 215007);   -- grün t6er 100	
  db:priv_AddDB("T698er", 215008);   -- grün t6er 100	
  db:priv_AddDB("T698er", 215009);   -- grün t6er 100	
  db:priv_AddDB("T698er", 215010);   -- grün t6er 100	



  db:priv_AddDB("T698er", 215086); -- grüne lvl 100er Waffen aus Chassizz	gebunden Questbelohnung
  db:priv_AddDB("T698er", 215087);
  db:priv_AddDB("T698er", 215088);
  db:priv_AddDB("T698er", 215089);
  db:priv_AddDB("T698er", 215090);
  db:priv_AddDB("T698er", 215091);
  db:priv_AddDB("T698er", 215092);
  db:priv_AddDB("T698er", 215093);
  db:priv_AddDB("T698er", 215094);
  db:priv_AddDB("T698er", 215095);
  db:priv_AddDB("T698er", 215096);
  
  db:priv_AddDB("T698er", 224780);
  db:priv_AddDB("T698er", 224781);
  db:priv_AddDB("T698er", 224782);
  db:priv_AddDB("T698er", 224783);
  db:priv_AddDB("T698er", 224784);
  db:priv_AddDB("T698er", 224785);
  db:priv_AddDB("T698er", 224786);
  db:priv_AddDB("T698er", 224787);
  db:priv_AddDB("T698er", 224788);
  db:priv_AddDB("T698er", 224789);
  db:priv_AddDB("T698er", 224790);
  db:priv_AddDB("T698er", 224791);

  db:priv_AddDB("T698er", 234777);   -- grün t6er   98	gebunden Questbelohnung
  db:priv_AddDB("T698er", 234778);   -- grün t6er   98
  db:priv_AddDB("T698er", 234779);   -- grün t6er   98
  db:priv_AddDB("T698er", 234780);   -- grün t6er   98
  db:priv_AddDB("T698er", 234781);   -- grün t6er   98
  db:priv_AddDB("T698er", 234782);   -- grün t6er   98
  db:priv_AddDB("T698er", 234783);   -- grün t6er   98
  db:priv_AddDB("T698er", 234784);   -- grün t6er   98
  db:priv_AddDB("T698er", 234785);   -- grün t6er   98
  db:priv_AddDB("T698er", 234786);   -- grün t6er   98
  db:priv_AddDB("T698er", 234787);   -- grün t6er   98
  db:priv_AddDB("T698er", 234788);   -- grün t6er   98
  db:priv_AddDB("T698er", 234789);   -- grün t6er   98
  db:priv_AddDB("T698er", 234790);   -- grün t6er   98
  db:priv_AddDB("T698er", 234791);   -- grün t6er   98
  db:priv_AddDB("T698er", 234792);   -- grün t6er   98
  db:priv_AddDB("T698er", 234793);   -- grün t6er   98
  db:priv_AddDB("T698er", 234794);   -- grün t6er   98
  db:priv_AddDB("T698er", 234795);   -- grün t6er   98
  db:priv_AddDB("T698er", 234796);   -- grün t6er   98
  db:priv_AddDB("T698er", 234797);   -- grün t6er   98
  db:priv_AddDB("T698er", 234798);   -- grün t6er   98
  db:priv_AddDB("T698er", 234799);   -- grün t6er   98
  db:priv_AddDB("T698er", 234800);   -- grün t6er   98
  db:priv_AddDB("T698er", 234801);   -- grün t6er   98
  db:priv_AddDB("T698er", 234802);   -- grün t6er   98
  db:priv_AddDB("T698er", 234803);   -- grün t6er   98
  db:priv_AddDB("T698er", 234804);   -- grün t6er   98
  db:priv_AddDB("T698er", 234805);   -- grün t6er   98
  db:priv_AddDB("T698er", 234806);   -- grün t6er   98
  db:priv_AddDB("T698er", 234807);   -- grün t6er   98
  db:priv_AddDB("T698er", 234808);   -- grün t6er   98
  db:priv_AddDB("T698er", 234809);   -- grün t6er   98
  db:priv_AddDB("T698er", 234810);   -- grün t6er   98
  db:priv_AddDB("T698er", 234811);   -- grün t6er   98
  db:priv_AddDB("T698er", 234812);   -- grün t6er   98
  db:priv_AddDB("T698er", 234813);   -- grün t6er   98
  db:priv_AddDB("T698er", 234814);   -- grün t6er   98
  db:priv_AddDB("T698er", 234815);   -- grün t6er   98
  db:priv_AddDB("T698er", 234816);   -- grün t6er   98
  db:priv_AddDB("T698er", 234817);   -- grün t6er   98
  db:priv_AddDB("T698er", 234818);   -- grün t6er   98
  db:priv_AddDB("T698er", 234819);   -- grün t6er   98
  db:priv_AddDB("T698er", 234820);   -- grün t6er   98
  db:priv_AddDB("T698er", 234821);   -- grün t6er   98
  db:priv_AddDB("T698er", 234822);   -- grün t6er   98

  db:priv_AddDB("T698er", 235167);   -- grün t6er   98	gebunden Questbelohnung	
  db:priv_AddDB("T698er", 235168);   -- grün t6er   98
  db:priv_AddDB("T698er", 235169);   -- grün t6er   98
  db:priv_AddDB("T698er", 235170);   -- grün t6er   98
  db:priv_AddDB("T698er", 235171);   -- grün t6er   98
  db:priv_AddDB("T698er", 235172);   -- grün t6er   98
  db:priv_AddDB("T698er", 235173);   -- grün t6er   98
  db:priv_AddDB("T698er", 235174);   -- grün t6er   98
  db:priv_AddDB("T698er", 235175);   -- grün t6er   98
  db:priv_AddDB("T698er", 235176);   -- grün t6er   98
  db:priv_AddDB("T698er", 235177);   -- grün t6er   98
  db:priv_AddDB("T698er", 235178);   -- grün t6er   98
  db:priv_AddDB("T698er", 235179);   -- grün t6er   98
  db:priv_AddDB("T698er", 235180);   -- grün t6er   98
  db:priv_AddDB("T698er", 235181);   -- grün t6er   98
  db:priv_AddDB("T698er", 235182);   -- grün t6er   98
  db:priv_AddDB("T698er", 235183);   -- grün t6er   98
  db:priv_AddDB("T698er", 235184);   -- grün t6er   98
  db:priv_AddDB("T698er", 235185);   -- grün t6er   98
  db:priv_AddDB("T698er", 235186);   -- grün t6er   98
  db:priv_AddDB("T698er", 235187);   -- grün t6er   98
  db:priv_AddDB("T698er", 235188);   -- grün t6er   98
  db:priv_AddDB("T698er", 235189);   -- grün t6er   98
  db:priv_AddDB("T698er", 235190);   -- grün t6er   98
  db:priv_AddDB("T698er", 235191);   -- grün t6er   98
  db:priv_AddDB("T698er", 235192);   -- grün t6er   98
  db:priv_AddDB("T698er", 235193);   -- grün t6er   98
  db:priv_AddDB("T698er", 235194);   -- grün t6er   98
  db:priv_AddDB("T698er", 235195);   -- grün t6er   98
  db:priv_AddDB("T698er", 235196);   -- grün t6er   98
  db:priv_AddDB("T698er", 235197);   -- grün t6er   98
  db:priv_AddDB("T698er", 235198);   -- grün t6er   98
  db:priv_AddDB("T698er", 235199);   -- grün t6er   98
  db:priv_AddDB("T698er", 235200);   -- grün t6er   98
  db:priv_AddDB("T698er", 235201);   -- grün t6er   98
  db:priv_AddDB("T698er", 235202);   -- grün t6er   98
  db:priv_AddDB("T698er", 235203);   -- grün t6er   98
  db:priv_AddDB("T698er", 235204);   -- grün t6er   98
  db:priv_AddDB("T698er", 235205);   -- grün t6er   98
  db:priv_AddDB("T698er", 235206);   -- grün t6er   98
  db:priv_AddDB("T698er", 235207);   -- grün t6er   98
  db:priv_AddDB("T698er", 235208);   -- grün t6er   98
  db:priv_AddDB("T698er", 235209);   -- grün t6er   98
  db:priv_AddDB("T698er", 235210);   -- grün t6er   98
  db:priv_AddDB("T698er", 235211);   -- grün t6er   98
  db:priv_AddDB("T698er", 235212);   -- grün t6er   98


  db:priv_AddDB("T698er", 235486);   -- grün t6er   99	gebunden Questbelohnung	
  db:priv_AddDB("T698er", 235487);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235488);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235489);   -- grün t6er   99
  db:priv_AddDB("T698er", 235490);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235491);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235492);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235493);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235494);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235495);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235496);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235497);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235498);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235499);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235500);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235501);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235502);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235503);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235504);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235505);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235506);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235507);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235508);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235509);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235510);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235511);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235512);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235513);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235514);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235515);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235516);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235517);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235518);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235519);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235520);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235521);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235522);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235523);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235524);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235525);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235526);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235527);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235528);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235529);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235530);   -- grün t6er   99	
  db:priv_AddDB("T698er", 235531);   -- grün t6er   99	


  db:priv_AddDB("T698er", 235618);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 235619);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 235620);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 235621);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 235622);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 235623);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 235624);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 235625);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 235626);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 235627);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 235628);   -- grün t6er clean   99
  db:priv_AddDB("T698er", 235629);   -- grün t6er clean   99

  db:priv_AddDB("T698er", 235825);   -- grün t6er 100	gebunden Questbelohnung
  db:priv_AddDB("T698er", 235826);   -- grün t6er 100
  db:priv_AddDB("T698er", 235827);   -- grün t6er 100
  db:priv_AddDB("T698er", 235828);   -- grün t6er 100
  db:priv_AddDB("T698er", 235829);   -- grün t6er 100
  db:priv_AddDB("T698er", 235830);   -- grün t6er 100
  db:priv_AddDB("T698er", 235831);   -- grün t6er 100
  db:priv_AddDB("T698er", 235832);   -- grün t6er 100
  db:priv_AddDB("T698er", 235833);   -- grün t6er 100
  db:priv_AddDB("T698er", 235834);   -- grün t6er 100
  db:priv_AddDB("T698er", 235835);   -- grün t6er 100
  db:priv_AddDB("T698er", 235836);   -- grün t6er 100
  db:priv_AddDB("T698er", 235837);   -- grün t6er 100
  db:priv_AddDB("T698er", 235838);   -- grün t6er 100
  db:priv_AddDB("T698er", 235839);   -- grün t6er 100
  db:priv_AddDB("T698er", 235840);   -- grün t6er 100
  db:priv_AddDB("T698er", 235841);   -- grün t6er 100
  db:priv_AddDB("T698er", 235842);   -- grün t6er 100
  db:priv_AddDB("T698er", 235843);   -- grün t6er 100
  db:priv_AddDB("T698er", 235844);   -- grün t6er 100
  db:priv_AddDB("T698er", 235845);   -- grün t6er 100
  db:priv_AddDB("T698er", 235846);   -- grün t6er 100
  db:priv_AddDB("T698er", 235847);   -- grün t6er 100
  db:priv_AddDB("T698er", 235848);   -- grün t6er 100
  db:priv_AddDB("T698er", 235849);   -- grün t6er 100
  db:priv_AddDB("T698er", 235850);   -- grün t6er 100
  db:priv_AddDB("T698er", 235851);   -- grün t6er 100
  db:priv_AddDB("T698er", 235852);   -- grün t6er 100
  db:priv_AddDB("T698er", 235853);   -- grün t6er 100
  db:priv_AddDB("T698er", 235854);   -- grün t6er 100
  db:priv_AddDB("T698er", 235855);   -- grün t6er 100
  db:priv_AddDB("T698er", 235856);   -- grün t6er 100
  db:priv_AddDB("T698er", 235857);   -- grün t6er 100
  db:priv_AddDB("T698er", 235858);   -- grün t6er 100
  db:priv_AddDB("T698er", 235859);   -- grün t6er 100
  db:priv_AddDB("T698er", 235860);   -- grün t6er 100
  db:priv_AddDB("T698er", 235861);   -- grün t6er 100
  db:priv_AddDB("T698er", 235862);   -- grün t6er 100
  db:priv_AddDB("T698er", 235863);   -- grün t6er 100
  db:priv_AddDB("T698er", 235864);   -- grün t6er 100
  db:priv_AddDB("T698er", 235865);   -- grün t6er 100
  db:priv_AddDB("T698er", 235866);   -- grün t6er 100
  db:priv_AddDB("T698er", 235867);   -- grün t6er 100
  db:priv_AddDB("T698er", 235868);   -- grün t6er 100
  db:priv_AddDB("T698er", 235869);   -- grün t6er 100
  db:priv_AddDB("T698er", 235870);   -- grün t6er 100


  db:priv_AddDB("T698er", 236177); -- grün lvl 100er Items aus Chassizz	gebunden Questbelohnung
  db:priv_AddDB("T698er", 236178); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236179); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236180); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236181); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236182); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236183); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236184); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236185); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236186); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236187); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236188); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236189); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236190); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236191); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236192); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236193); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236194); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236195); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236196); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236197); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236198); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236199); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236200); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236201); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236202); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236203); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236204); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236205); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236206); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236207); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236208); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236209); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236210); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236211); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236212); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236213); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236214); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236215); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236216); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236217); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236218); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236219); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236220); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236221); -- grün lvl 100er Items aus Chassizz
  db:priv_AddDB("T698er", 236222); -- grün lvl 100er Items aus Chassizz





  
end


local function priv_AddT6(db)		-- T6

  db:priv_AddDB("T6", 210438); -- blaue lvl 100er Items aus Chassizz

  
  db:priv_AddDB("T6", 211988); -- T6s = blau t6 Items von 95-98
  
  db:priv_AddDB("T6", 212468);
  
  



  db:priv_AddDB("T6", 213225); -- blaue lvl 100er Items aus Chassizz
  db:priv_AddDB("T6", 213226);
  db:priv_AddDB("T6", 213227);
  db:priv_AddDB("T6", 213228);
  db:priv_AddDB("T6", 213229);
  db:priv_AddDB("T6", 213230);
  db:priv_AddDB("T6", 213231);
  db:priv_AddDB("T6", 213232);
  db:priv_AddDB("T6", 213233);
  db:priv_AddDB("T6", 213234);


  db:priv_AddDB("T6", 214187); -- T6s = blau t6 Items von 97
  
  db:priv_AddDB("T6", 214294); -- T6s = blau t6 Items von 96
  db:priv_AddDB("T6", 214295);
  db:priv_AddDB("T6", 214296);
  
  db:priv_AddDB("T6", 214699); -- T6s = blau t6 Items von 97
  db:priv_AddDB("T6", 214700);
  db:priv_AddDB("T6", 214701);
  db:priv_AddDB("T6", 214702);
  db:priv_AddDB("T6", 214703);
  db:priv_AddDB("T6", 214704);
  db:priv_AddDB("T6", 214705);
  db:priv_AddDB("T6", 214706);
  db:priv_AddDB("T6", 214707);
  db:priv_AddDB("T6", 214708);
  db:priv_AddDB("T6", 214708);
  db:priv_AddDB("T6", 214709);
  
  
  db:priv_AddDB("T6", 214790); -- T6s = blau t6 Items von 97
  db:priv_AddDB("T6", 214791);
  db:priv_AddDB("T6", 214792);
  db:priv_AddDB("T6", 214793);
  db:priv_AddDB("T6", 214794);
  db:priv_AddDB("T6", 214795);
  db:priv_AddDB("T6", 214796);
  
  
  db:priv_AddDB("T6", 214815);
  db:priv_AddDB("T6", 214816);
  db:priv_AddDB("T6", 214817);
  db:priv_AddDB("T6", 214818);
  db:priv_AddDB("T6", 214819);
  db:priv_AddDB("T6", 214820);
  db:priv_AddDB("T6", 214821);
  db:priv_AddDB("T6", 214822);
  db:priv_AddDB("T6", 214823);
  db:priv_AddDB("T6", 214824);
  db:priv_AddDB("T6", 214825);

  db:priv_AddDB("T6", 214852); -- blaue lvl 99er Items aus der InI
  db:priv_AddDB("T6", 214853);
  db:priv_AddDB("T6", 214854);
  db:priv_AddDB("T6", 214855);
  db:priv_AddDB("T6", 214856);
  db:priv_AddDB("T6", 214857);
  db:priv_AddDB("T6", 214858);
  db:priv_AddDB("T6", 214859);
  db:priv_AddDB("T6", 214860);
  db:priv_AddDB("T6", 214861);
  db:priv_AddDB("T6", 214862);



  db:priv_AddDB("T6", 214922);   -- blau t6er 100
  db:priv_AddDB("T6", 214923);   -- blau t6er 100
  db:priv_AddDB("T6", 214924);   -- blau t6er 100
  db:priv_AddDB("T6", 214925);   -- blau t6er 100
  db:priv_AddDB("T6", 214926);   -- blau t6er 100
  db:priv_AddDB("T6", 214927);   -- blau t6er 100
  db:priv_AddDB("T6", 214928);   -- blau t6er 100
  db:priv_AddDB("T6", 214929);   -- blau t6er 100
  db:priv_AddDB("T6", 214930);   -- blau t6er 100
  db:priv_AddDB("T6", 214931);   -- blau t6er 100
  db:priv_AddDB("T6", 214932);   -- blau t6er 100
  db:priv_AddDB("T6", 214944);   -- blau t6er 100 Items aus Enoch
  db:priv_AddDB("T6", 214945);   -- blau t6er 100
  db:priv_AddDB("T6", 214946);   -- blau t6er 100
  db:priv_AddDB("T6", 214947);   -- blau t6er 100
  db:priv_AddDB("T6", 214948);   -- blau t6er 100
  db:priv_AddDB("T6", 214949);   -- blau t6er 100
  db:priv_AddDB("T6", 214950);   -- blau t6er 100
  db:priv_AddDB("T6", 214951);   -- blau t6er 100
  db:priv_AddDB("T6", 214952);   -- blau t6er 100
  db:priv_AddDB("T6", 214953);   -- blau t6er 100
  db:priv_AddDB("T6", 214954);   -- blau t6er 100

 
  db:priv_AddDB("T6", 215011);   -- blau t6er 100	Waffe
  db:priv_AddDB("T6", 215012);   -- blau t6er 100
  db:priv_AddDB("T6", 215013);   -- blau t6er 100
  db:priv_AddDB("T6", 215014);   -- blau t6er 100
  db:priv_AddDB("T6", 215015);   -- blau t6er 100
  db:priv_AddDB("T6", 215016);   -- blau t6er 100
  db:priv_AddDB("T6", 215017);   -- blau t6er 100
  db:priv_AddDB("T6", 215018);   -- blau t6er 100
  db:priv_AddDB("T6", 215019);   -- blau t6er 100
  db:priv_AddDB("T6", 215020);   -- blau t6er 100
  db:priv_AddDB("T6", 215021);   -- blau t6er 100



  db:priv_AddDB("T6", 215033);   -- blau t6er 100	Waffe
  db:priv_AddDB("T6", 215034);   -- blau t6er 100
  db:priv_AddDB("T6", 215035);   -- blau t6er 100
  db:priv_AddDB("T6", 215036);   -- blau t6er 100
  db:priv_AddDB("T6", 215037);   -- blau t6er 100
  db:priv_AddDB("T6", 215038);   -- blau t6er 100
  db:priv_AddDB("T6", 215039);   -- blau t6er 100
  db:priv_AddDB("T6", 215040);   -- blau t6er 100
  db:priv_AddDB("T6", 215041);   -- blau t6er 100
  db:priv_AddDB("T6", 215042);   -- blau t6er 100
  db:priv_AddDB("T6", 215043);   -- blau t6er 100

--[[
  db:priv_AddDB("T6", 215086);   -- grüne t6er 100	Waffe
  db:priv_AddDB("T6", 215087);   -- grüne t6er 100
  db:priv_AddDB("T6", 215088);   -- grüne t6er 100
  db:priv_AddDB("T6", 215089);   -- grüne t6er 100
  db:priv_AddDB("T6", 215090);   -- grüne t6er 100
  db:priv_AddDB("T6", 215091);   -- grüne t6er 100
  db:priv_AddDB("T6", 215092);   -- grüne t6er 100
  db:priv_AddDB("T6", 215093);   -- grüne t6er 100
  db:priv_AddDB("T6", 215094);   -- grüne t6er 100
  db:priv_AddDB("T6", 215095);   -- grüne t6er 100
  db:priv_AddDB("T6", 215096);   -- grüne t6er 100
--]]




  db:priv_AddDB("T6", 212327);   -- grün t6er   98
  db:priv_AddDB("T6", 212328);   -- grün t6er   98
  db:priv_AddDB("T6", 212329);   -- grün t6er   98
  db:priv_AddDB("T6", 212330);   -- grün t6er   98
  db:priv_AddDB("T6", 212331);   -- grün t6er   98
  db:priv_AddDB("T6", 212332);   -- grün t6er   98
  db:priv_AddDB("T6", 212333);   -- grün t6er   98
  db:priv_AddDB("T6", 212334);   -- grün t6er   98
  db:priv_AddDB("T6", 212335);   -- grün t6er   98
  db:priv_AddDB("T6", 212336);   -- grün t6er   98

  db:priv_AddDB("T6", 212544);   -- grün t6er   98
  db:priv_AddDB("T6", 212684);   -- grün t6er   98
  db:priv_AddDB("T6", 212685);   -- grün t6er   98




  
  db:priv_AddDB("T6", 213535);   -- grün t6er   98
  db:priv_AddDB("T6", 213536);   -- grün t6er   98
  db:priv_AddDB("T6", 213537);   -- grün t6er   98
  db:priv_AddDB("T6", 213538);   -- grün t6er   98
  db:priv_AddDB("T6", 213539);   -- grün t6er   98
  db:priv_AddDB("T6", 213540);   -- grün t6er   98
  db:priv_AddDB("T6", 213541);   -- grün t6er   98
  db:priv_AddDB("T6", 213542);   -- grün t6er   98
  db:priv_AddDB("T6", 213543);   -- grün t6er   98


  db:priv_AddDB("T6", 214815);   -- blau t6er   98
  db:priv_AddDB("T6", 214816);   -- blau t6er   98
  db:priv_AddDB("T6", 214817);   -- blau t6er   98
  db:priv_AddDB("T6", 214818);   -- blau t6er   98
  db:priv_AddDB("T6", 214819);   -- blau t6er   98
  db:priv_AddDB("T6", 214820);   -- blau t6er   98
  db:priv_AddDB("T6", 214821);   -- blau t6er   98
  db:priv_AddDB("T6", 214822);   -- blau t6er   98
  db:priv_AddDB("T6", 214823);   -- blau t6er   98
  db:priv_AddDB("T6", 214824);   -- blau t6er   98
  db:priv_AddDB("T6", 214825);   -- blau t6er   98
  db:priv_AddDB("T6", 214826);   -- blau t6er   98
  db:priv_AddDB("T6", 214827);   -- blau t6er   98
  db:priv_AddDB("T6", 214828);   -- blau t6er   98
  db:priv_AddDB("T6", 214829);   -- blau t6er   98
  db:priv_AddDB("T6", 214830);   -- blau t6er   98
  db:priv_AddDB("T6", 214831);   -- blau t6er   98
  db:priv_AddDB("T6", 214832);   -- blau t6er   98
  db:priv_AddDB("T6", 214833);   -- blau t6er   98
  db:priv_AddDB("T6", 214834);   -- blau t6er   98
  db:priv_AddDB("T6", 214835);   -- blau t6er   98
  db:priv_AddDB("T6", 214836);   -- blau t6er   98




  db:priv_AddDB("T6", 214944); -- blaue lvl 100er Items aus Enoch
  db:priv_AddDB("T6", 214945);
  db:priv_AddDB("T6", 214946);
  db:priv_AddDB("T6", 214947);
  db:priv_AddDB("T6", 214948);
  db:priv_AddDB("T6", 214949);
  db:priv_AddDB("T6", 214950);
  db:priv_AddDB("T6", 214951);
  db:priv_AddDB("T6", 214952);
  db:priv_AddDB("T6", 214953);
  db:priv_AddDB("T6", 214954);    
 

 
  db:priv_AddDB("T6", 221425);   -- blau t6er   99
  db:priv_AddDB("T6", 221426);
  db:priv_AddDB("T6", 221427);
  db:priv_AddDB("T6", 221428);
  db:priv_AddDB("T6", 221429);
  db:priv_AddDB("T6", 221430);


  db:priv_AddDB("T6", 221661);   -- blau t6er   99
  db:priv_AddDB("T6", 221662);
  db:priv_AddDB("T6", 221663);
  db:priv_AddDB("T6", 221664);
  db:priv_AddDB("T6", 221665);
  db:priv_AddDB("T6", 221666);



  db:priv_AddDB("T6", 227174);   -- blau t6er   98
  db:priv_AddDB("T6", 227175);   -- blau t6er   98
  db:priv_AddDB("T6", 227176);   -- blau t6er   98
  db:priv_AddDB("T6", 227177);   -- blau t6er   98
  db:priv_AddDB("T6", 227178);   -- blau t6er   98
  db:priv_AddDB("T6", 227179);   -- blau t6er   98
  db:priv_AddDB("T6", 227180);   -- blau t6er   98

 
  db:priv_AddDB("T6", 228052);   -- blau t6er   98
  db:priv_AddDB("T6", 228053);   -- blau t6er   98
  db:priv_AddDB("T6", 228054);   -- blau t6er   98
  db:priv_AddDB("T6", 228055);   -- blau t6er   98
  db:priv_AddDB("T6", 228056);   -- blau t6er   98


  db:priv_AddDB("T6", 233975);
  db:priv_AddDB("T6", 233976);
  db:priv_AddDB("T6", 233977);
  db:priv_AddDB("T6", 233978);
  db:priv_AddDB("T6", 233979);
  db:priv_AddDB("T6", 233980);
  db:priv_AddDB("T6", 233981);
  db:priv_AddDB("T6", 233982);
  db:priv_AddDB("T6", 233983);
  db:priv_AddDB("T6", 233984);
  db:priv_AddDB("T6", 233985);
  db:priv_AddDB("T6", 233986);
  
  db:priv_AddDB("T6", 234256); -- T6s = blau t6 Items von 96
  db:priv_AddDB("T6", 234257);
  db:priv_AddDB("T6", 234258);
  db:priv_AddDB("T6", 234259);
  db:priv_AddDB("T6", 234260);
  db:priv_AddDB("T6", 234261);
  db:priv_AddDB("T6", 234262);
  db:priv_AddDB("T6", 234263);
  db:priv_AddDB("T6", 234264);
  db:priv_AddDB("T6", 234265);
  db:priv_AddDB("T6", 234266);
  db:priv_AddDB("T6", 234267);
  db:priv_AddDB("T6", 234268);
  db:priv_AddDB("T6", 234269);
  db:priv_AddDB("T6", 234270);
  db:priv_AddDB("T6", 234271);
  db:priv_AddDB("T6", 234272);
  db:priv_AddDB("T6", 234273);
  
  db:priv_AddDB("T6", 234485);
  db:priv_AddDB("T6", 234486);
  db:priv_AddDB("T6", 234487);
  db:priv_AddDB("T6", 234488);
  db:priv_AddDB("T6", 234489);
  db:priv_AddDB("T6", 234490);
  db:priv_AddDB("T6", 234491);
  db:priv_AddDB("T6", 234492);
  db:priv_AddDB("T6", 234493);
  db:priv_AddDB("T6", 234494);
  db:priv_AddDB("T6", 234495);
  db:priv_AddDB("T6", 234496);
  db:priv_AddDB("T6", 234686);
  db:priv_AddDB("T6", 234687);
  db:priv_AddDB("T6", 234688);
  db:priv_AddDB("T6", 234689);
  db:priv_AddDB("T6", 234690);
  db:priv_AddDB("T6", 234691);
  db:priv_AddDB("T6", 234692);
  db:priv_AddDB("T6", 234693);
  db:priv_AddDB("T6", 234694);
  db:priv_AddDB("T6", 234695);
  db:priv_AddDB("T6", 234696);
  db:priv_AddDB("T6", 234697);
  db:priv_AddDB("T6", 234698);
  db:priv_AddDB("T6", 234699);
  db:priv_AddDB("T6", 234700);
  db:priv_AddDB("T6", 234701);
  db:priv_AddDB("T6", 234702);
  db:priv_AddDB("T6", 234703);









  db:priv_AddDB("T6", 235630);   -- blau t6er 100 evtl gebunden
  db:priv_AddDB("T6", 235631);   -- blau t6er 100
  db:priv_AddDB("T6", 235632);   -- blau t6er 100
  db:priv_AddDB("T6", 235633);   -- blau t6er 100
  db:priv_AddDB("T6", 235634);   -- blau t6er 100
  db:priv_AddDB("T6", 235635);   -- blau t6er 100
  db:priv_AddDB("T6", 235636);   -- blau t6er 100
  db:priv_AddDB("T6", 235637);   -- blau t6er 100
  db:priv_AddDB("T6", 235638);   -- blau t6er 100
  db:priv_AddDB("T6", 235639);   -- blau t6er 100
  db:priv_AddDB("T6", 235640);   -- blau t6er 100
  db:priv_AddDB("T6", 235641);   -- blau t6er 100

  db:priv_AddDB("T6", 235969);   -- blau t6er 100
  db:priv_AddDB("T6", 235970);   -- blau t6er 100
  db:priv_AddDB("T6", 235971);   -- blau t6er 100
  db:priv_AddDB("T6", 235972);   -- blau t6er 100
  db:priv_AddDB("T6", 235973);   -- blau t6er 100
  db:priv_AddDB("T6", 235974);   -- blau t6er 100
  db:priv_AddDB("T6", 235975);   -- blau t6er 100
  db:priv_AddDB("T6", 235976);   -- blau t6er 100
  db:priv_AddDB("T6", 235977);   -- blau t6er 100
  db:priv_AddDB("T6", 235978);   -- blau t6er 100
  db:priv_AddDB("T6", 235979);   -- blau t6er 100
  db:priv_AddDB("T6", 235980);   -- blau t6er 100





--  db:priv_AddDB("T6", 236263); -- blaue lvl 100er Items aus Chassizz
--  db:priv_AddDB("T6", 236264); -- blaue lvl 100er Items aus Chassizz
--  db:priv_AddDB("T6", 236265); -- blaue lvl 100er Items aus Chassizz
--  db:priv_AddDB("T6", 236266); -- blaue lvl 100er Items aus Chassizz
--  db:priv_AddDB("T6", 236267); -- blaue lvl 100er Items aus Chassizz
--  db:priv_AddDB("T6", 236268); -- blaue lvl 100er Items aus Chassizz

 
  db:priv_AddDB("T6", 236309); -- blaue lvl 100er Items aus Chassizz
  db:priv_AddDB("T6", 236310);
  db:priv_AddDB("T6", 236311);
  db:priv_AddDB("T6", 236312);
  db:priv_AddDB("T6", 236313);
  db:priv_AddDB("T6", 236314);
  db:priv_AddDB("T6", 236315);
  db:priv_AddDB("T6", 236316);
  db:priv_AddDB("T6", 236317);
  db:priv_AddDB("T6", 236318);
  db:priv_AddDB("T6", 236319);  
  db:priv_AddDB("T6", 236320);
 
end

local function priv_AddRecipesAlchemist(db)   -- Rezepte Allchemist

  db:priv_AddDB("RecipesAlchemist", 550676);   -- Rezeptur - Einfacher Heiltrank
  db:priv_AddDB("RecipesAlchemist", 550677);   -- Rezeptur - Einfache Medizin
  db:priv_AddDB("RecipesAlchemist", 550678);   -- Rezeptur - Einfacher Manatrank
  db:priv_AddDB("RecipesAlchemist", 550679);   -- Rezeptur - Einfacher Geist-Trank
  db:priv_AddDB("RecipesAlchemist", 550681);   -- Rezeptur - Sammeltrank I
  db:priv_AddDB("RecipesAlchemist", 550683);   -- Rezeptur - Sammeltrank II
  db:priv_AddDB("RecipesAlchemist", 550685);   -- Rezeptur - Sammeltrank III
  db:priv_AddDB("RecipesAlchemist", 550690);   -- Rezeptur - Unsichtbarkeitstrank
  db:priv_AddDB("RecipesAlchemist", 550691);   -- Rezeptur - Spruchweber-Trank
  db:priv_AddDB("RecipesAlchemist", 550692);   -- Rezeptur - Starkes Anregungsmittel
  db:priv_AddDB("RecipesAlchemist", 550693);   -- Rezeptur - Anregungsmittel
  db:priv_AddDB("RecipesAlchemist", 550694);   -- Rezeptur - Elixier des Weisen
  db:priv_AddDB("RecipesAlchemist", 550695);   -- Rezeptur - Trank des Potenzials
  db:priv_AddDB("RecipesAlchemist", 550696);   -- Rezeptur - Trank der Windelementar-Anziehung
  db:priv_AddDB("RecipesAlchemist", 550697);   -- Rezeptur - Trank der Wasserelementar-Anziehung
  db:priv_AddDB("RecipesAlchemist", 550698);   -- Rezeptur - Trank der Erdelementar-Anziehung
  db:priv_AddDB("RecipesAlchemist", 550701);   -- Rezeptur - Quelle des Elements
  db:priv_AddDB("RecipesAlchemist", 550702);   -- Rezeptur - Heiltrank
  db:priv_AddDB("RecipesAlchemist", 550703);   -- Rezeptur - Salbe
  db:priv_AddDB("RecipesAlchemist", 550704);   -- Rezeptur - Manatrank
  db:priv_AddDB("RecipesAlchemist", 550705);   -- Rezeptur - Manatrank
  db:priv_AddDB("RecipesAlchemist", 550706);   -- Rezeptur - Ruhepulver
  db:priv_AddDB("RecipesAlchemist", 550707);   -- Rezeptur - Beruhigungspulver
  db:priv_AddDB("RecipesAlchemist", 550708);   -- Rezeptur - Wasser der alten Geister
  db:priv_AddDB("RecipesAlchemist", 550709);   -- Rezeptur - Hexendoktor-Elixier
  db:priv_AddDB("RecipesAlchemist", 550712);   -- Rezeptur - Ber?hrung des Einhorns
  db:priv_AddDB("RecipesAlchemist", 550713);   -- Rezeptur - Lebensquelle
  db:priv_AddDB("RecipesAlchemist", 550714);   -- Rezeptur - Umarmung der Muse
  db:priv_AddDB("RecipesAlchemist", 550715);   -- Rezeptur - Manaquelle
  db:priv_AddDB("RecipesAlchemist", 550717);   -- Rezeptur - Besserer Sammeltrank I
  db:priv_AddDB("RecipesAlchemist", 550719);   -- Rezeptur - Besserer Sammeltrank II
  db:priv_AddDB("RecipesAlchemist", 550721);   -- Rezeptur - Besserer Sammeltrank III
  db:priv_AddDB("RecipesAlchemist", 550722);   -- Rezeptur - Starker Heiltrank
  db:priv_AddDB("RecipesAlchemist", 550723);   -- Rezeptur - Starke Medizin
  db:priv_AddDB("RecipesAlchemist", 550724);   -- Rezeptur - Starker Manatrank
  db:priv_AddDB("RecipesAlchemist", 550725);   -- Rezeptur - M?chtiger Geist-Trank
  db:priv_AddDB("RecipesAlchemist", 550726);   -- Rezeptur - Gereinigter anregender Duft
  db:priv_AddDB("RecipesAlchemist", 550727);   -- Rezeptur - Anregender Duft
  db:priv_AddDB("RecipesAlchemist", 550729);   -- Rezeptur - Trank der heiligen Macht
  db:priv_AddDB("RecipesAlchemist", 550730);   -- Rezeptur - Trank der Feuerelementar-Anziehung
  db:priv_AddDB("RecipesAlchemist", 551032);   -- Rezeptur - Trank des Zorns
  db:priv_AddDB("RecipesAlchemist", 551033);   -- Rezeptur - Kampfst?rke
  db:priv_AddDB("RecipesAlchemist", 551035);   -- Rezeptur - Trank der herausragenden Fertigkeit
  db:priv_AddDB("RecipesAlchemist", 551036);   -- Rezeptur - Fokustrank
  db:priv_AddDB("RecipesAlchemist", 551037);   -- Rezeptur - Trank des konzentrierten Willens
  db:priv_AddDB("RecipesAlchemist", 551321);   -- Rezeptur - Trank der St?rke
  db:priv_AddDB("RecipesAlchemist", 551322);   -- Rezeptur - Wirksamer Trank der St?rke
  db:priv_AddDB("RecipesAlchemist", 551323);   -- Rezeptur - Trank der Intelligenz
  db:priv_AddDB("RecipesAlchemist", 551324);   -- Rezeptur - Wirksamer Trank der Intelligenz
  db:priv_AddDB("RecipesAlchemist", 551325);   -- Rezeptur - Trank der Weisheit
  db:priv_AddDB("RecipesAlchemist", 551326);   -- Rezeptur - Wirksamer Trank der Weisheit
  db:priv_AddDB("RecipesAlchemist", 551327);   -- Rezeptur - Trank der Geschicklichkeit
  db:priv_AddDB("RecipesAlchemist", 551328);   -- Rezeptur - Wirksamer Trank der Geschicklichkeit
  db:priv_AddDB("RecipesAlchemist", 551329);   -- Rezeptur - Trank der Ausdauer
  db:priv_AddDB("RecipesAlchemist", 551330);   -- Rezeptur - Wirksamer Trank der Ausdauer
  db:priv_AddDB("RecipesAlchemist", 551458);   -- Rezeptur - Fantastische Salbe
  db:priv_AddDB("RecipesAlchemist", 551459);   -- Rezeptur - Fantastischer Geist-Trank
  db:priv_AddDB("RecipesAlchemist", 551460);   -- Rezeptur - Ausl?schungstrank
  db:priv_AddDB("RecipesAlchemist", 551461);   -- Rezeptur - L?schtrank
  db:priv_AddDB("RecipesAlchemist", 551462);   -- Rezeptur - T?dliches Gift
  db:priv_AddDB("RecipesAlchemist", 551463);   -- Rezeptur - Starker magischer Trank
  db:priv_AddDB("RecipesAlchemist", 551625);   -- Rezeptur - Fantastischer Heiltrank
  db:priv_AddDB("RecipesAlchemist", 551626);   -- Rezeptur - Fantastischer Manatrank
  db:priv_AddDB("RecipesAlchemist", 551717);   -- Rezeptur - Geheimnisvoller Trank
  db:priv_AddDB("RecipesAlchemist", 551718);   -- Rezeptur - Hochgradig geheimnisvoller Trank
  db:priv_AddDB("RecipesAlchemist", 551719);   -- Rezeptur - Segnungstrank
  db:priv_AddDB("RecipesAlchemist", 551720);   -- Rezeptur - Pr?sent-Trank
  db:priv_AddDB("RecipesAlchemist", 551737);   -- Rezeptur - Schnell wirkender Heiltrank
  db:priv_AddDB("RecipesAlchemist", 551738);   -- Rezeptur - Schnell wirkender Manatrank
  db:priv_AddDB("RecipesAlchemist", 552031);   -- Rezeptur - Gesegneter Heiltrank
  db:priv_AddDB("RecipesAlchemist", 552032);   -- Rezeptur - Gebetsmanaquelle
  db:priv_AddDB("RecipesAlchemist", 552280);   -- Rezeptur - Gesegneter Besserungstrank
  db:priv_AddDB("RecipesAlchemist", 552281);   -- Rezeptur - Gesegneter magischer Trank
  db:priv_AddDB("RecipesAlchemist", 552293);   -- Rezeptur - Stahlhauttrank
  db:priv_AddDB("RecipesAlchemist", 552294);   -- Rezeptur - Heiliger Trank
  db:priv_AddDB("RecipesAlchemist", 552670);   -- Rezeptur - Trank der R?stung
  db:priv_AddDB("RecipesAlchemist", 552671);   -- Rezeptur - Genesungstrank
  db:priv_AddDB("RecipesAlchemist", 552672);   -- Rezeptur - Heiltrank der Lebenskraft
  db:priv_AddDB("RecipesAlchemist", 552673);   -- Rezeptur - Magischer Trank der Lebenskraft
  db:priv_AddDB("RecipesAlchemist", 552814);   -- Rezeptur - Trank des Walls
  db:priv_AddDB("RecipesAlchemist", 552815);   -- Rezeptur - Trank der Seelenz?hmung
  db:priv_AddDB("RecipesAlchemist", 552816);   -- Rezeptur - Heiltrank der Hoffnung
  db:priv_AddDB("RecipesAlchemist", 552817);   -- Rezeptur - Magischer Trank der Hoffnung
  db:priv_AddDB("RecipesAlchemist", 552832);   -- Rezeptur - Quell der Heilung
  db:priv_AddDB("RecipesAlchemist", 552833);   -- Rezeptur - Magischer Trank der Quelle
  db:priv_AddDB("RecipesAlchemist", 552834);   -- Rezeptur - Trank des Felsens
  db:priv_AddDB("RecipesAlchemist", 552835);   -- Rezeptur - Fl?geltrank

end

local function priv_AddRecipesCook(db)   -- Rezepte Koch

  db:priv_AddDB("RecipesCook", 550431);   -- Rezeptur - Gebratener salziger Fisch
  db:priv_AddDB("RecipesCook", 550432);   -- Rezeptur - Gebratener Fisch
  db:priv_AddDB("RecipesCook", 550433);   -- Rezeptur - Obst und K?se
  db:priv_AddDB("RecipesCook", 550434);   -- Rezeptur - Saurer K?seball
  db:priv_AddDB("RecipesCook", 550435);   -- Rezeptur - Gebratenes Fleisch mit Knoblauch
  db:priv_AddDB("RecipesCook", 550436);   -- Rezeptur - Gebratenes Fleisch
  db:priv_AddDB("RecipesCook", 550437);   -- Rezeptur - Aromatische Frucht
  db:priv_AddDB("RecipesCook", 550438);   -- Rezeptur - Kr?uterfrucht
  db:priv_AddDB("RecipesCook", 550439);   -- Rezeptur - Gesalzener Fisch mit So?e
  db:priv_AddDB("RecipesCook", 550440);   -- Rezeptur - Gesalzener Fisch
  db:priv_AddDB("RecipesCook", 550441);   -- Rezeptur - Knusprige Donuts
  db:priv_AddDB("RecipesCook", 550442);   -- Rezeptur - S??e frittierte Donuts
  db:priv_AddDB("RecipesCook", 550443);   -- Rezeptur - Ger?ucherter Speck mit Kr?utern
  db:priv_AddDB("RecipesCook", 550444);   -- Rezeptur - Ger?ucherter Speck
  db:priv_AddDB("RecipesCook", 550445);   -- Rezeptur - S??es Fr?chtebrot
  db:priv_AddDB("RecipesCook", 550446);   -- Rezeptur - Brot und Marmelade
  db:priv_AddDB("RecipesCook", 550447);   -- Rezeptur - Knusprig gebratenes H?hnchen mit Honig
  db:priv_AddDB("RecipesCook", 550448);   -- Rezeptur - Gebratenes H?hnchen mit Honig
  db:priv_AddDB("RecipesCook", 550449);   -- Rezeptur - Knoblauchbrot mit Kr?utern
  db:priv_AddDB("RecipesCook", 550450);   -- Rezeptur - Knoblauchbrot
  db:priv_AddDB("RecipesCook", 550451);   -- Rezeptur - Kaviar-Sandwich
  db:priv_AddDB("RecipesCook", 550452);   -- Rezeptur - Fischei-Sandwich
  db:priv_AddDB("RecipesCook", 550453);   -- Rezeptur - Hervorragendes Fleisch und Brot
  db:priv_AddDB("RecipesCook", 550454);   -- Rezeptur - Fleisch und Brot
  db:priv_AddDB("RecipesCook", 550455);   -- Rezeptur - Ausgezeichnete Meeresfr?chte
  db:priv_AddDB("RecipesCook", 550456);   -- Rezeptur - Cremige Meeresfr?chte-Pastete
  db:priv_AddDB("RecipesCook", 550457);   -- Rezeptur - K?stliche Pilzpastete
  db:priv_AddDB("RecipesCook", 550458);   -- Rezeptur - Pilzpastete
  db:priv_AddDB("RecipesCook", 550460);   -- Rezeptur - Burrito mit Fleischso?e
  db:priv_AddDB("RecipesCook", 550461);   -- Rezeptur - Regenbogen-Kristallbonbon
  db:priv_AddDB("RecipesCook", 550462);   -- Rezeptur - Kristallzucker
  db:priv_AddDB("RecipesCook", 550463);   -- Rezeptur - K?stliches Sumpf-Allerlei
  db:priv_AddDB("RecipesCook", 550464);   -- Rezeptur - Sumpf-Allerlei
  db:priv_AddDB("RecipesCook", 550465);   -- Rezeptur - Magische Fr?chtepastete
  db:priv_AddDB("RecipesCook", 550466);   -- Rezeptur - Exotische Fr?chtepastete
  db:priv_AddDB("RecipesCook", 550467);   -- Rezeptur - Unvorstellbarer Salat
  db:priv_AddDB("RecipesCook", 550468);   -- Rezeptur - Seewurmsalat
  db:priv_AddDB("RecipesCook", 550469);   -- Rezeptur - Kuchen der singenden W?lder
  db:priv_AddDB("RecipesCook", 550470);   -- Rezeptur - Gr?ner weicher Kuchen
  db:priv_AddDB("RecipesCook", 550471);   -- Rezeptur - Motis gemischte Wurst
  db:priv_AddDB("RecipesCook", 550472);   -- Rezeptur - Dreifarbige Wurst des Generals
  db:priv_AddDB("RecipesCook", 550473);   -- Rezeptur - Exquisite Teeduft-Waffel
  db:priv_AddDB("RecipesCook", 550474);   -- Rezeptur - Teeduft-Waffel
  db:priv_AddDB("RecipesCook", 550475);   -- Rezeptur - Kaiserliche Meeresfr?chte-Pastete
  db:priv_AddDB("RecipesCook", 550476);   -- Rezeptur - Fischfrikadelle mit K?se
  db:priv_AddDB("RecipesCook", 550477);   -- Rezeptur - Exquisites Kakaobuttergeb?ck
  db:priv_AddDB("RecipesCook", 550478);   -- Rezeptur - Kakaobuttergeb?ck mit Kr?utern
  db:priv_AddDB("RecipesCook", 550479);   -- Rezeptur - Mahl des Schicksals
  db:priv_AddDB("RecipesCook", 550480);   -- Rezeptur - Mahl des Drachens
  db:priv_AddDB("RecipesCook", 550481);   -- Rezeptur - Laorwald-Obstkuchen
  db:priv_AddDB("RecipesCook", 550482);   -- Rezeptur - Zaubererverpflegung
  db:priv_AddDB("RecipesCook", 551225);   -- Rezeptur - Rituelle Eucharistie
  db:priv_AddDB("RecipesCook", 551226);   -- Rezeptur - Abendessen der G?tter
  db:priv_AddDB("RecipesCook", 551227);   -- Rezeptur - Traumlandfrucht
  db:priv_AddDB("RecipesCook", 551228);   -- Rezeptur - Serenstum
  db:priv_AddDB("RecipesCook", 551464);   -- Rezeptur - Schokoladenkuchen
  db:priv_AddDB("RecipesCook", 551465);   -- Rezeptur - Zartbitterschokolade
  db:priv_AddDB("RecipesCook", 551466);   -- Rezeptur - Laib magisches Hartbrot
  db:priv_AddDB("RecipesCook", 551467);   -- Rezeptur - Geschw?rztes Fischfilet
  db:priv_AddDB("RecipesCook", 551468);   -- Rezeptur - Salatsandwich
  db:priv_AddDB("RecipesCook", 551469);   -- Rezeptur - Geschw?rztes Rippchen
  db:priv_AddDB("RecipesCook", 551628);   -- Rezeptur - Laib hausgemachtes Schwarzbrot
  db:priv_AddDB("RecipesCook", 551629);   -- Rezeptur - Gew?rzte Rippchen
  db:priv_AddDB("RecipesCook", 551631);   -- Rezeptur - K?sekuchen
  db:priv_AddDB("RecipesCook", 551632);   -- Rezeptur - Gew?hnliche Schokolade
  db:priv_AddDB("RecipesCook", 551721);   -- Rezeptur - Gebratenes Schweinekotelett
  db:priv_AddDB("RecipesCook", 551722);   -- Rezeptur - Schweinerippchen
  db:priv_AddDB("RecipesCook", 551723);   -- Rezeptur - Schweinefleisch mit schwarzem Pfeffer
  db:priv_AddDB("RecipesCook", 551724);   -- Rezeptur - Geschmortes Schweinefleisch
  db:priv_AddDB("RecipesCook", 551725);   -- Rezeptur - Fisch mit Essig
  db:priv_AddDB("RecipesCook", 551726);   -- Rezeptur - Pikantes Fischst?bchen
  db:priv_AddDB("RecipesCook", 551727);   -- Rezeptur - Gelbfisch s??-sauer
  db:priv_AddDB("RecipesCook", 551728);   -- Rezeptur - Tofu-Dorsch
  db:priv_AddDB("RecipesCook", 551739);   -- Rezeptur - Gebratener Fisch
  db:priv_AddDB("RecipesCook", 551740);   -- Rezeptur - Frisches Brot
  db:priv_AddDB("RecipesCook", 551741);   -- Rezeptur - Gebratene Rippchen
  db:priv_AddDB("RecipesCook", 551742);   -- Rezeptur - Spiegelei-Sandwich
  db:priv_AddDB("RecipesCook", 551743);   -- Rezeptur - Buttercremetorte
  db:priv_AddDB("RecipesCook", 551744);   -- Rezeptur - Milchschokolade
  db:priv_AddDB("RecipesCook", 552033);   -- Rezeptur - Knuspriger Toast
  db:priv_AddDB("RecipesCook", 552034);   -- Rezeptur - Riesensandwich
  db:priv_AddDB("RecipesCook", 552035);   -- Rezeptur - R?ucherfisch
  db:priv_AddDB("RecipesCook", 552036);   -- Rezeptur - Ger?ucherte Rippchen
  db:priv_AddDB("RecipesCook", 552037);   -- Rezeptur - Edle Schokolade
  db:priv_AddDB("RecipesCook", 552038);   -- Rezeptur - Honigkuchen
  db:priv_AddDB("RecipesCook", 552282);   -- Rezeptur - Cremige Schokolade
  db:priv_AddDB("RecipesCook", 552283);   -- Rezeptur - Beerenkuchen
  db:priv_AddDB("RecipesCook", 552284);   -- Rezeptur - Knoblauchbrot
  db:priv_AddDB("RecipesCook", 552285);   -- Rezeptur - Beerensandwich
  db:priv_AddDB("RecipesCook", 552286);   -- Rezeptur - Gebratener Salzfisch
  db:priv_AddDB("RecipesCook", 552287);   -- Rezeptur - Gebratene Rippchen
  db:priv_AddDB("RecipesCook", 552664);   -- Rezeptur - Erdbeerkuchen mit Sahne
  db:priv_AddDB("RecipesCook", 552665);   -- Rezeptur - Handgemachte Schokolade
  db:priv_AddDB("RecipesCook", 552666);   -- Rezeptur - Saftiger Backfisch
  db:priv_AddDB("RecipesCook", 552667);   -- Rezeptur - Sesambrot
  db:priv_AddDB("RecipesCook", 552668);   -- Rezeptur - Saftiges Rippchen
  db:priv_AddDB("RecipesCook", 552669);   -- Rezeptur - Schinken-Sandwich
  db:priv_AddDB("RecipesCook", 552808);   -- Rezeptur - Vanillekuchen
  db:priv_AddDB("RecipesCook", 552809);   -- Rezeptur - Erdbeerschokolade
  db:priv_AddDB("RecipesCook", 552810);   -- Rezeptur - Fischfilet mit Pfeffer
  db:priv_AddDB("RecipesCook", 552811);   -- Rezeptur - Teigr?llchen mit Zimt
  db:priv_AddDB("RecipesCook", 552813);   -- Rezeptur - P?kelfleisch-Sandwich
  db:priv_AddDB("RecipesCook", 552826);   -- Rezeptur - Fruchttorte nach Art der Einheimischen
  db:priv_AddDB("RecipesCook", 552828);   -- Rezeptur - Pfannengebratenes Fischsteak
  db:priv_AddDB("RecipesCook", 552829);   -- Rezeptur - Naturbrot
  db:priv_AddDB("RecipesCook", 552830);   -- Rezeptur - Gebratene Rippchen
  db:priv_AddDB("RecipesCook", 552831);   -- Rezeptur - R?ucherh?hnchen-Sandwich
  db:priv_AddDB("RecipesCook", 552844);   -- Rezeptur - Geburtstagskuchen
  db:priv_AddDB("RecipesCook", 552845);   -- Rezeptur - Tr?ffelschokolade
  db:priv_AddDB("RecipesCook", 552846);   -- Rezeptur - Ged?nstetes Fischsteak
  db:priv_AddDB("RecipesCook", 552847);   -- Rezeptur - Brot mit Pygmierum-Aroma
  db:priv_AddDB("RecipesCook", 552848);   -- Rezeptur - Rippchen mit Honig
  db:priv_AddDB("RecipesCook", 552849);   -- Rezeptur - Gem?se-Sandwich

end

local function priv_AddRecipesCutter(db)   -- Rezepte Schneider

  db:priv_AddDB("RecipesCutter", 550483);   -- Rezeptur - Verbesserte grobe Stoffhose
  db:priv_AddDB("RecipesCutter", 550484);   -- Rezeptur - Derbe Stoffhose
  db:priv_AddDB("RecipesCutter", 550485);   -- Rezeptur - Verbesserter grober Stoffmantel
  db:priv_AddDB("RecipesCutter", 550486);   -- Rezeptur - Derbes Stoffgewand
  db:priv_AddDB("RecipesCutter", 550487);   -- Rezeptur - Verbesserter magischer violetter Umhang
  db:priv_AddDB("RecipesCutter", 550488);   -- Rezeptur - Violetter magischer Umhang
  db:priv_AddDB("RecipesCutter", 550489);   -- Rezeptur - Gewebte Hose
  db:priv_AddDB("RecipesCutter", 550490);   -- Rezeptur - Strickmantel
  db:priv_AddDB("RecipesCutter", 550491);   -- Rezeptur - Verbesserte gewebte Kleidung
  db:priv_AddDB("RecipesCutter", 550492);   -- Rezeptur - Wollkleidung
  db:priv_AddDB("RecipesCutter", 550493);   -- Rezeptur - Gr?ne Lotushose
  db:priv_AddDB("RecipesCutter", 550494);   -- Rezeptur - Verbessertes Gewand der Verzauberung
  db:priv_AddDB("RecipesCutter", 550495);   -- Rezeptur - Gewand der Verzauberung
  db:priv_AddDB("RecipesCutter", 550496);   -- Rezeptur - Farbiger leichter Umhang
  db:priv_AddDB("RecipesCutter", 550497);   -- Rezeptur - Verbesserte wei?e Baumwollhose
  db:priv_AddDB("RecipesCutter", 550498);   -- Rezeptur - Wei?e Baumwollhose
  db:priv_AddDB("RecipesCutter", 550499);   -- Rezeptur - Umhang der Ruhe
  db:priv_AddDB("RecipesCutter", 550500);   -- Rezeptur - Violette Baumwollkleidung
  db:priv_AddDB("RecipesCutter", 550501);   -- Rezeptur - Verbesserter wei?er Baumwollmantel
  db:priv_AddDB("RecipesCutter", 550502);   -- Rezeptur - Wei?e Baumwollkleidung
  db:priv_AddDB("RecipesCutter", 550503);   -- Rezeptur - Überhose der Reflexion
  db:priv_AddDB("RecipesCutter", 550504);   -- Rezeptur - Verbesserte rote Lotushose
  db:priv_AddDB("RecipesCutter", 550505);   -- Rezeptur - Rote Lotushose
  db:priv_AddDB("RecipesCutter", 550506);   -- Rezeptur - Roter Lotusmantel
  db:priv_AddDB("RecipesCutter", 550507);   -- Rezeptur - Verbesserter Umhang der ?therischen Stimme
  db:priv_AddDB("RecipesCutter", 550508);   -- Rezeptur - Umhang der ?therischen Stimme
  db:priv_AddDB("RecipesCutter", 550509);   -- Rezeptur - Laubkleidung
  db:priv_AddDB("RecipesCutter", 550511);   -- Rezeptur - Hochwertige Leinenkappe
  db:priv_AddDB("RecipesCutter", 550512);   -- Rezeptur - Verbesserte Flachskappe
  db:priv_AddDB("RecipesCutter", 550513);   -- Rezeptur - Leinenkappe
  db:priv_AddDB("RecipesCutter", 550514);   -- Rezeptur - Ruhmesumhang
  db:priv_AddDB("RecipesCutter", 550515);   -- Rezeptur - Verbesserte Adelsjacke
  db:priv_AddDB("RecipesCutter", 550516);   -- Rezeptur - Adelsgewand
  db:priv_AddDB("RecipesCutter", 550517);   -- Rezeptur - Samthut
  db:priv_AddDB("RecipesCutter", 550518);   -- Rezeptur - Blauflammenumhang
  db:priv_AddDB("RecipesCutter", 550519);   -- Rezeptur - Elegante Dunkelheithose
  db:priv_AddDB("RecipesCutter", 550520);   -- Rezeptur - Verbesserte dunkle Hose
  db:priv_AddDB("RecipesCutter", 550521);   -- Rezeptur - Dunkelheithose
  db:priv_AddDB("RecipesCutter", 550522);   -- Rezeptur - Verbesserter dunkler Mantel
  db:priv_AddDB("RecipesCutter", 550523);   -- Rezeptur - Umhang der Dunkelheit
  db:priv_AddDB("RecipesCutter", 550524);   -- Rezeptur - Ph?nixfederkappe
  db:priv_AddDB("RecipesCutter", 550525);   -- Rezeptur - Verbesserte Federkapuze
  db:priv_AddDB("RecipesCutter", 550526);   -- Rezeptur - Federkappe
  db:priv_AddDB("RecipesCutter", 550527);   -- Rezeptur - Pr?chtige Hose
  db:priv_AddDB("RecipesCutter", 550528);   -- Rezeptur - Elley-Robe
  db:priv_AddDB("RecipesCutter", 550529);   -- Rezeptur - Verbesserter pr?chtiger Mantel
  db:priv_AddDB("RecipesCutter", 550530);   -- Rezeptur - Pr?chtiger Mantel
  db:priv_AddDB("RecipesCutter", 550531);   -- Rezeptur - Verbesserter purpurroter Federumhang
  db:priv_AddDB("RecipesCutter", 550532);   -- Rezeptur - Purpurroter Federumhang
  db:priv_AddDB("RecipesCutter", 550533);   -- Rezeptur - Nietenzaubererkappe
  db:priv_AddDB("RecipesCutter", 550534);   -- Rezeptur - Seidenhose
  db:priv_AddDB("RecipesCutter", 550535);   -- Rezeptur - Verbesserte magische Hose
  db:priv_AddDB("RecipesCutter", 550536);   -- Rezeptur - Magische Überhose
  db:priv_AddDB("RecipesCutter", 550537);   -- Rezeptur - Verbesserte Robe
  db:priv_AddDB("RecipesCutter", 550538);   -- Rezeptur - Kurzrobe
  db:priv_AddDB("RecipesCutter", 550539);   -- Rezeptur - Verbesserte gr?ne Lotusrobe
  db:priv_AddDB("RecipesCutter", 550540);   -- Rezeptur - Gr?ne Lotusrobe
  db:priv_AddDB("RecipesCutter", 550541);   -- Rezeptur - Überhose der Woge
  db:priv_AddDB("RecipesCutter", 550542);   -- Rezeptur - Verbesserte Gezeiten-Überhose
  db:priv_AddDB("RecipesCutter", 550543);   -- Rezeptur - Gezeitenhose
  db:priv_AddDB("RecipesCutter", 550544);   -- Rezeptur - Gezeitenrobe
  db:priv_AddDB("RecipesCutter", 550545);   -- Rezeptur - Überhose der Verlockung
  db:priv_AddDB("RecipesCutter", 550546);   -- Rezeptur - Robe des Irrglaubens
  db:priv_AddDB("RecipesCutter", 550547);   -- Rezeptur - Verbesserte Überhose der Verlockung
  db:priv_AddDB("RecipesCutter", 550548);   -- Rezeptur - Robe der Verlockung
  db:priv_AddDB("RecipesCutter", 550549);   -- Rezeptur - Polarstern-Überhose
  db:priv_AddDB("RecipesCutter", 550550);   -- Rezeptur - Verbesserte Sternenhose
  db:priv_AddDB("RecipesCutter", 550551);   -- Rezeptur - Sternenhose
  db:priv_AddDB("RecipesCutter", 550552);   -- Rezeptur - Verbesserte Sternenrobe
  db:priv_AddDB("RecipesCutter", 550553);   -- Rezeptur - Kurzrobe der Sterne
  db:priv_AddDB("RecipesCutter", 550554);   -- Rezeptur - Verbesserte Staubhose
  db:priv_AddDB("RecipesCutter", 550555);   -- Rezeptur - Staubhose
  db:priv_AddDB("RecipesCutter", 550556);   -- Rezeptur - Staublangrobe
  db:priv_AddDB("RecipesCutter", 550557);   -- Rezeptur - Verbesserte Überhose der Konzentration
  db:priv_AddDB("RecipesCutter", 550558);   -- Rezeptur - Überhose der Konzentration
  db:priv_AddDB("RecipesCutter", 550559);   -- Rezeptur - Zwielichtkurzrobe
  db:priv_AddDB("RecipesCutter", 550560);   -- Rezeptur - Zwielichthose
  db:priv_AddDB("RecipesCutter", 550562);   -- Rezeptur - Verbesserte Flanellkappe
  db:priv_AddDB("RecipesCutter", 550563);   -- Rezeptur - Flanellkapuze
  db:priv_AddDB("RecipesCutter", 550564);   -- Rezeptur - Verbesserte Hose des Glaubens
  db:priv_AddDB("RecipesCutter", 550565);   -- Rezeptur - Überhose des Glaubens
  db:priv_AddDB("RecipesCutter", 550566);   -- Rezeptur - Langrobe des Glaubens
  db:priv_AddDB("RecipesCutter", 550567);   -- Rezeptur - Magischer Hut
  db:priv_AddDB("RecipesCutter", 550568);   -- Rezeptur - Verbesserte Kappe der Heimlichkeit
  db:priv_AddDB("RecipesCutter", 550569);   -- Rezeptur - Kopftuch der Heimlichkeit
  db:priv_AddDB("RecipesCutter", 550570);   -- Rezeptur - Verbesserte Regenbogen-Hose
  db:priv_AddDB("RecipesCutter", 550571);   -- Rezeptur - Sternenregenbogen-Hose
  db:priv_AddDB("RecipesCutter", 550572);   -- Rezeptur - Verbesserte Regenbogenrobe
  db:priv_AddDB("RecipesCutter", 550573);   -- Rezeptur - Regenbogenlangrobe
  db:priv_AddDB("RecipesCutter", 550574);   -- Rezeptur - Regenbogenhut
  db:priv_AddDB("RecipesCutter", 550575);   -- Rezeptur - Verbesserter Hut der Abendr?te
  db:priv_AddDB("RecipesCutter", 550576);   -- Rezeptur - Zwielichthut
  db:priv_AddDB("RecipesCutter", 550902);   -- Rezeptur - Gr?ne Baumhose
  db:priv_AddDB("RecipesCutter", 550903);   -- Rezeptur - Kranichfederhut
  db:priv_AddDB("RecipesCutter", 550904);   -- Rezeptur - Layses Kurzrobe
  db:priv_AddDB("RecipesCutter", 550905);   -- Rezeptur - Hut der urzeitlichen Macht
  db:priv_AddDB("RecipesCutter", 550969);   -- Rezeptur - Ventis-Krone
  db:priv_AddDB("RecipesCutter", 550970);   -- Rezeptur - Ventis-Magierkrone
  db:priv_AddDB("RecipesCutter", 550971);   -- Rezeptur - Ventis-Erzmagierkrone
  db:priv_AddDB("RecipesCutter", 550978);   -- Rezeptur - Ventis-Robe
  db:priv_AddDB("RecipesCutter", 550979);   -- Rezeptur - Ventis-Magierrobe
  db:priv_AddDB("RecipesCutter", 550980);   -- Rezeptur - Ventis-Erzmagierrobe
  db:priv_AddDB("RecipesCutter", 550987);   -- Rezeptur - Ventis-Überhose
  db:priv_AddDB("RecipesCutter", 550988);   -- Rezeptur - Ventis-MagierÜberhose
  db:priv_AddDB("RecipesCutter", 550989);   -- Rezeptur - Ventis-ErzmagierÜberhose
  db:priv_AddDB("RecipesCutter", 550996);   -- Rezeptur - Ventis-Stiefel
  db:priv_AddDB("RecipesCutter", 550997);   -- Rezeptur - Ventis-Magierstiefel
  db:priv_AddDB("RecipesCutter", 550998);   -- Rezeptur - Ventis-Erzmagierstiefel
  db:priv_AddDB("RecipesCutter", 551010);   -- Rezeptur - Raltes Drachenfl?gelrobe
  db:priv_AddDB("RecipesCutter", 551011);   -- Rezeptur - Raltes Drachenfl?gelstiefel
  db:priv_AddDB("RecipesCutter", 551012);   -- Rezeptur - Raltes Drachenfl?gelhose
  db:priv_AddDB("RecipesCutter", 551013);   -- Rezeptur - Raltes Drachenfl?gelhandschuhe
  db:priv_AddDB("RecipesCutter", 551039);   -- Rezeptur - Verbesserter Samt-Hut
  db:priv_AddDB("RecipesCutter", 551045);   -- Rezeptur - Verbesserte gr?ne Lotushose
  db:priv_AddDB("RecipesCutter", 551046);   -- Rezeptur - Verbesserter Staubrobe
  db:priv_AddDB("RecipesCutter", 551108);   -- Rezeptur - Einfache Schneidertruhe des Anf?ngersch?lers
  db:priv_AddDB("RecipesCutter", 551109);   -- Rezeptur - Einfache Schneidertruhe des Nachwuchssch?lers
  db:priv_AddDB("RecipesCutter", 551110);   -- Rezeptur - Einfache Schneidertruhe des erfahrenen Sch?lers
  db:priv_AddDB("RecipesCutter", 551111);   -- Rezeptur - Einfache Schneidertruhe des Anf?ngerhandwerkers
  db:priv_AddDB("RecipesCutter", 551112);   -- Rezeptur - Einfache Schneidertruhe des Nachwuchshandwerkers
  db:priv_AddDB("RecipesCutter", 551113);   -- Rezeptur - Einfache Schneidertruhe des erfahrenen Handwerkers
  db:priv_AddDB("RecipesCutter", 551114);   -- Rezeptur - Einfache Schneidertruhe des fachkundigen Handwerkers
  db:priv_AddDB("RecipesCutter", 551115);   -- Rezeptur - Einfache Schneidertruhe des Experten
  db:priv_AddDB("RecipesCutter", 551116);   -- Rezeptur - Einfache Schneidertruhe des erfahrenen Experten
  db:priv_AddDB("RecipesCutter", 551117);   -- Rezeptur - Einfache Schneidertruhe des gebildeten Experten
  db:priv_AddDB("RecipesCutter", 551118);   -- Rezeptur - Funktionale Schneidertruhe des Anf?ngersch?lers
  db:priv_AddDB("RecipesCutter", 551119);   -- Rezeptur - Funktionale Schneidertruhe des Nachwuchssch?lers
  db:priv_AddDB("RecipesCutter", 551120);   -- Rezeptur - Funktionale Schneidertruhe des erfahrenen Sch?lers
  db:priv_AddDB("RecipesCutter", 551121);   -- Rezeptur - Funktionale Schneidertruhe des Anf?ngerhandwerkers
  db:priv_AddDB("RecipesCutter", 551122);   -- Rezeptur - Funktionale Schneidertruhe des Nachwuchshandwerkers
  db:priv_AddDB("RecipesCutter", 551123);   -- Rezeptur - Funktionale Schneidertruhe des erfahrenen Handwerkers
  db:priv_AddDB("RecipesCutter", 551124);   -- Rezeptur - Funktionale Schneidertruhe des fachkundigen Handwerkers
  db:priv_AddDB("RecipesCutter", 551125);   -- Rezeptur - Funktionale Schneidertruhe des Experten
  db:priv_AddDB("RecipesCutter", 551126);   -- Rezeptur - Funktionale Schneidertruhe des erfahrenen Experten
  db:priv_AddDB("RecipesCutter", 551127);   -- Rezeptur - Funktionale Schneidertruhe des gebildeten Experten
  db:priv_AddDB("RecipesCutter", 551128);   -- Rezeptur - Exquisite Schneidertruhe des Anf?ngersch?lers
  db:priv_AddDB("RecipesCutter", 551129);   -- Rezeptur - Exquisite Schneidertruhe des Nachwuchssch?lers
  db:priv_AddDB("RecipesCutter", 551130);   -- Rezeptur - Exquisite Schneidertruhe des erfahrenen Sch?lers
  db:priv_AddDB("RecipesCutter", 551131);   -- Rezeptur - Exquisite Schneidertruhe des Anf?ngerhandwerkers
  db:priv_AddDB("RecipesCutter", 551132);   -- Rezeptur - Exquisite Schneidertruhe des Nachwuchshandwerkers
  db:priv_AddDB("RecipesCutter", 551133);   -- Rezeptur - Exquisite Schneidertruhe des erfahrenen Handwerkers
  db:priv_AddDB("RecipesCutter", 551134);   -- Rezeptur - Exquisite Schneidertruhe des fachkundigen Handwerkers
  db:priv_AddDB("RecipesCutter", 551135);   -- Rezeptur - Exquisite Schneidertruhe des Experten
  db:priv_AddDB("RecipesCutter", 551137);   -- Rezeptur - Exquisite Schneidertruhe des gebildeten Experten
  db:priv_AddDB("RecipesCutter", 551195);   -- Rezeptur - Samthaube
  db:priv_AddDB("RecipesCutter", 551199);   -- Rezeptur - Aguars Flaggenumhang
  db:priv_AddDB("RecipesCutter", 551200);   -- Rezeptur - Tadors Umhang der Zustimmung
  db:priv_AddDB("RecipesCutter", 551201);   -- Rezeptur - Krone von Henolids Ode
  db:priv_AddDB("RecipesCutter", 551214);   -- Rezeptur - Einfache Forscher-Schneidertruhe
  db:priv_AddDB("RecipesCutter", 551215);   -- Rezeptur - Funktionale Forscher-Schneidertruhe
  db:priv_AddDB("RecipesCutter", 551216);   -- Rezeptur - Exquisite Forscher-Schneidertruhe
  db:priv_AddDB("RecipesCutter", 551261);   -- Rezeptur - Sternenkrone
  db:priv_AddDB("RecipesCutter", 551262);   -- Rezeptur - Leuchtsternenkrone
  db:priv_AddDB("RecipesCutter", 551263);   -- Rezeptur - Drachenmusterjacke
  db:priv_AddDB("RecipesCutter", 551264);   -- Rezeptur - Drachenmusterhose
  db:priv_AddDB("RecipesCutter", 551272);   -- Rezeptur - Farbiger Kristallumhang
  db:priv_AddDB("RecipesCutter", 551273);   -- Rezeptur - Verbesserte Sternenkappe
  db:priv_AddDB("RecipesCutter", 551276);   -- Rezeptur - Verbesserte Drachenmusterjacke
  db:priv_AddDB("RecipesCutter", 551277);   -- Rezeptur - Heilige Drachenmusterjacke
  db:priv_AddDB("RecipesCutter", 551286);   -- Rezeptur - Verbesserte Drachenmuster-Hosen
  db:priv_AddDB("RecipesCutter", 551287);   -- Rezeptur - Heilige Drachenmuster-Hosen
  db:priv_AddDB("RecipesCutter", 551296);   -- Rezeptur - Regenbogen-Umhang
  db:priv_AddDB("RecipesCutter", 551348);   -- Rezeptur - Einfache Schneidertruhe des Arkanen Experten
  db:priv_AddDB("RecipesCutter", 551349);   -- Rezeptur - Funktionale Schneidertruhe des Arkanen Experten
  db:priv_AddDB("RecipesCutter", 551350);   -- Rezeptur - Schöne Schneidertruhe des Arkanen Experten
  db:priv_AddDB("RecipesCutter", 551374);   -- Rezeptur - Hut des magischen Waldes
  db:priv_AddDB("RecipesCutter", 551375);   -- Rezeptur - Gewand des magischen Waldes
  db:priv_AddDB("RecipesCutter", 551376);   -- Rezeptur - Beinschützer des magischen Waldes
  db:priv_AddDB("RecipesCutter", 551377);   -- Rezeptur - Schutzumhang des Waldes
  db:priv_AddDB("RecipesCutter", 551452);   -- Rezeptur - Kopfbedeckung des Hüters
  db:priv_AddDB("RecipesCutter", 551453);   -- Rezeptur - Beinschützer des Hüters
  db:priv_AddDB("RecipesCutter", 551454);   -- Rezeptur - Gewand des Hüters
  db:priv_AddDB("RecipesCutter", 551455);   -- Rezeptur - Umhang des Helden
  db:priv_AddDB("RecipesCutter", 551479);   -- Rezeptur - Kopfschmuck des Forschers
  db:priv_AddDB("RecipesCutter", 551480);   -- Rezeptur - Robe des Forschers
  db:priv_AddDB("RecipesCutter", 551481);   -- Rezeptur - Überhose des Forschers
  db:priv_AddDB("RecipesCutter", 551482);   -- Rezeptur - Umhang der Freude
  db:priv_AddDB("RecipesCutter", 551505);   -- Rezeptur - Verstärkte Kopfbedeckung des Forschers
  db:priv_AddDB("RecipesCutter", 551506);   -- Rezeptur - Verstärkte Robe des Forschers
  db:priv_AddDB("RecipesCutter", 551507);   -- Rezeptur - Verstärkte Überhose des Forschers
  db:priv_AddDB("RecipesCutter", 551508);   -- Rezeptur - Verstärkter Umhang der Freude
  db:priv_AddDB("RecipesCutter", 551531);   -- Rezeptur - Seltene Kopfbedeckung des Forschers
  db:priv_AddDB("RecipesCutter", 551532);   -- Rezeptur - Seltene Robe des Forschers
  db:priv_AddDB("RecipesCutter", 551533);   -- Rezeptur - Seltene Überhose des Forschers
  db:priv_AddDB("RecipesCutter", 551534);   -- Rezeptur - Seltener Umhang der Freude
  db:priv_AddDB("RecipesCutter", 551563);   -- Rezeptur - Kopfbedeckung des Entwicklers
  db:priv_AddDB("RecipesCutter", 551564);   -- Rezeptur - Robe des Entwicklers
  db:priv_AddDB("RecipesCutter", 551565);   -- Rezeptur - Überhose des Entwicklers
  db:priv_AddDB("RecipesCutter", 551566);   -- Rezeptur - Umhang der endlosen Freude

  db:priv_AddDB("RecipesCutter", 551593);   -- Rezeptur - 
  db:priv_AddDB("RecipesCutter", 551594);   -- Rezeptur - 
  db:priv_AddDB("RecipesCutter", 551595);   -- Rezeptur - 
  db:priv_AddDB("RecipesCutter", 551596);   -- Rezeptur -  
  db:priv_AddDB("RecipesCutter", 551597);   -- Rezeptur - 
  db:priv_AddDB("RecipesCutter", 551598);   -- Rezeptur - 
  db:priv_AddDB("RecipesCutter", 551599);   -- Rezeptur -  
  
  db:priv_AddDB("RecipesCutter", 551600);   -- Rezeptur - Einfache Schneidertruhe des Rätselexperten
  db:priv_AddDB("RecipesCutter", 551601);   -- Rezeptur - Funktionale Schneidertruhe des Rätselexperten
  db:priv_AddDB("RecipesCutter", 551602);   -- Rezeptur - Exquisite Schneidertruhe des Rätselexperten
  db:priv_AddDB("RecipesCutter", 551697);   -- Rezeptur - Gestreifte Bortenjacke
  db:priv_AddDB("RecipesCutter", 551698);   -- Rezeptur - Leichtes Einführungsset
  db:priv_AddDB("RecipesCutter", 551699);   -- Rezeptur - Blaubandl?ufer-Reitausr?stung
  db:priv_AddDB("RecipesCutter", 551700);   -- Rezeptur - Jadebrise
  db:priv_AddDB("RecipesCutter", 551701);   -- Rezeptur - Handwerksrobe des Donners
  db:priv_AddDB("RecipesCutter", 551702);   -- Rezeptur - Schutz der Roten Sonne
  db:priv_AddDB("RecipesCutter", 551703);   -- Rezeptur - Extravagante gestreifte Robe
  db:priv_AddDB("RecipesCutter", 551704);   -- Rezeptur - Set des Himmlischen Drachen
  db:priv_AddDB("RecipesCutter", 551734);   -- Rezeptur - Einfache Schneidertruhe des fachkundigen Handwerks
  db:priv_AddDB("RecipesCutter", 551735);   -- Rezeptur - Funktionale Schneidertruhe des fachkundigen Handwerks
  db:priv_AddDB("RecipesCutter", 551736);   -- Rezeptur - Exquisite Schneidertruhe des fachkundigen Handwerks
  db:priv_AddDB("RecipesCutter", 551751);   -- Rezeptur - Vollkommene einfache Schneidertruhe des Experten
  db:priv_AddDB("RecipesCutter", 551752);   -- Rezeptur - Vollkommene funktionale Schneidertruhe des Experten
  db:priv_AddDB("RecipesCutter", 551753);   -- Rezeptur - Vollkommene exquisite Schneidertruhe des Experten
  
  db:priv_AddDB("RecipesCutter", 551783);   -- Rezeptur - Höhlenrobe
  db:priv_AddDB("RecipesCutter", 551784);   -- Rezeptur - HöhlenBeinschützer
  db:priv_AddDB("RecipesCutter", 551785);   -- Rezeptur - Mantel der Kalon
  
  db:priv_AddDB("RecipesCutter", 551808);   -- Rezeptur - Verstärkte Höhlenkopfbedeckung
  db:priv_AddDB("RecipesCutter", 551809);   -- Rezeptur - Verstärkte Höhlenrobe
  db:priv_AddDB("RecipesCutter", 551810);   -- Rezeptur - Verstärkte HöhlenBeinschützer
  db:priv_AddDB("RecipesCutter", 551811);   -- Rezeptur - Verstärkter Mantel der Kalon
  
  db:priv_AddDB("RecipesCutter", 551834);   -- Rezeptur - Seltene Höhlenkopfbedeckung
  db:priv_AddDB("RecipesCutter", 551835);   -- Rezeptur - Seltene Höhlenrobe
  db:priv_AddDB("RecipesCutter", 551836);   -- Rezeptur - Seltene HöhlenBeinschützer
  db:priv_AddDB("RecipesCutter", 551837);   -- Rezeptur - Seltener Mantel der Kalon
  
  db:priv_AddDB("RecipesCutter", 551860);   -- Rezeptur - Rissige Kopfbedeckung
  db:priv_AddDB("RecipesCutter", 551861);   -- Rezeptur - Rissige Robe
  db:priv_AddDB("RecipesCutter", 551862);   -- Rezeptur - Rissige Überhose
  db:priv_AddDB("RecipesCutter", 551863);   -- Rezeptur - Mantel des Feldzugs
  
  db:priv_AddDB("RecipesCutter", 551921);   -- Rezeptur - Kopfschmuck der Zuflucht
  db:priv_AddDB("RecipesCutter", 551922);   -- Rezeptur - Robe der Zuflucht
  db:priv_AddDB("RecipesCutter", 551923);   -- Rezeptur - Beinschützer der Zuflucht
  db:priv_AddDB("RecipesCutter", 551924);   -- Rezeptur - Umhang der Versorgung
  
  db:priv_AddDB("RecipesCutter", 551947);   -- Rezeptur - Verbesserter Kopfschmuck der Zuflucht
  db:priv_AddDB("RecipesCutter", 551948);   -- Rezeptur - Verbesserte Robe der Zuflucht
  db:priv_AddDB("RecipesCutter", 551949);   -- Rezeptur - Verbesserter Beinschützer der Zuflucht
  db:priv_AddDB("RecipesCutter", 551950);   -- Rezeptur - Verbesserter Umhang der Versorgung
  
  db:priv_AddDB("RecipesCutter", 551988);   -- Rezeptur - Seltener Kopfschmuck der Zuflucht
  
  db:priv_AddDB("RecipesCutter", 551990);   -- Rezeptur - Seltener Beinschützer der Zuflucht
  db:priv_AddDB("RecipesCutter", 551991);   -- Rezeptur - Seltener Umhang der Versorgung
  
  db:priv_AddDB("RecipesCutter", 552014);   -- Rezeptur - Kopfbedeckung der Hemmnis
  db:priv_AddDB("RecipesCutter", 552015);   -- Rezeptur - Robe der Hemmnis
  db:priv_AddDB("RecipesCutter", 552016);   -- Rezeptur - Beinschützer der Hemmnis
  db:priv_AddDB("RecipesCutter", 552017);   -- Rezeptur - Umhang der Elfe
  
  db:priv_AddDB("RecipesCutter", 552061);   -- Rezeptur - Große einfache Schneidertruhe des Novizen
  db:priv_AddDB("RecipesCutter", 552062);   -- Rezeptur - Große funktionale Schneidertruhe des Novizen
  db:priv_AddDB("RecipesCutter", 552063);   -- Rezeptur - Große exquisite Schneidertruhe des Novizen
  db:priv_AddDB("RecipesCutter", 552064);   -- Rezeptur - Große einfache Schneidertruhe des Fortgeschrittenen
  db:priv_AddDB("RecipesCutter", 552065);   -- Rezeptur - Große funktionale Schneidertruhe des Fortgeschrittenen
  db:priv_AddDB("RecipesCutter", 552066);   -- Rezeptur - Große exquisite Schneidertruhe des Fortgeschrittenen
  db:priv_AddDB("RecipesCutter", 552067);   -- Rezeptur - Große einfache Schneidertruhe des Erhabenen
  db:priv_AddDB("RecipesCutter", 552068);   -- Rezeptur - Große funktionale Schneidertruhe des Erhabenen
  db:priv_AddDB("RecipesCutter", 552069);   -- Rezeptur - Große exquisite Schneidertruhe des Erhabenen
  
  db:priv_AddDB("RecipesCutter", 552111);   -- Rezeptur - Gezeitenkopfbedeckung
  db:priv_AddDB("RecipesCutter", 552112);   -- Rezeptur - Gezeitenrobe
  db:priv_AddDB("RecipesCutter", 552113);   -- Rezeptur - Gezeitenhose
  
  db:priv_AddDB("RecipesCutter", 552116);   -- Rezeptur - Sternenhimmelumhang
  
  db:priv_AddDB("RecipesCutter", 552137);   -- Rezeptur - Verbesserte Gezeitenkopfbedeckung
  db:priv_AddDB("RecipesCutter", 552138);   -- Rezeptur - Verbesserte Gezeitenrobe
  db:priv_AddDB("RecipesCutter", 552139);   -- Rezeptur - Verbesserte Gezeitenhose
  
  db:priv_AddDB("RecipesCutter", 552163);   -- Rezeptur - Seltene Gezeitenkopfbedeckung
  db:priv_AddDB("RecipesCutter", 552164);   -- Rezeptur - Seltene Gezeitenrobe
  db:priv_AddDB("RecipesCutter", 552165);   -- Rezeptur - Seltene Gezeitenhose
  
  db:priv_AddDB("RecipesCutter", 552168);   -- Rezeptur - Seltener Sternenhimmelumhang
  
  db:priv_AddDB("RecipesCutter", 552190);   -- Rezeptur - Goldener Plattenumhang
  
  db:priv_AddDB("RecipesCutter", 552198);   -- Rezeptur - Dschungelumhang der Entdeckung
  db:priv_AddDB("RecipesCutter", 552199);   -- Rezeptur - Goldene Samthandschuhe
  db:priv_AddDB("RecipesCutter", 552200);   -- Rezeptur - Goldene Samthose
  db:priv_AddDB("RecipesCutter", 552201);   -- Rezeptur - Goldener SamtGürtel
  db:priv_AddDB("RecipesCutter", 552202);   -- Rezeptur - Goldener Samtumhang
  
  db:priv_AddDB("RecipesCutter", 552213);   -- Rezeptur - Verbesserter Goldener Plattenumhang
  
  db:priv_AddDB("RecipesCutter", 552217);   -- Rezeptur - Verbesserter Purpurroter Dornenumhang
  
  db:priv_AddDB("RecipesCutter", 552221);   -- Rezeptur - Verbesserter Dschungelumhang der Entdeckung
  db:priv_AddDB("RecipesCutter", 552222);   -- Rezeptur - Verbesserte Goldene Samthandschuhe
  db:priv_AddDB("RecipesCutter", 552223);   -- Rezeptur - Verbesserte Goldene Samthose
  db:priv_AddDB("RecipesCutter", 552224);   -- Rezeptur - Verbesserter Goldener SamtGürtel
  db:priv_AddDB("RecipesCutter", 552225);   -- Rezeptur - Verbesserter Goldener Samtumhang
  
  db:priv_AddDB("RecipesCutter", 552236);   -- Rezeptur - Seltener Goldener Plattenumhang
  
  db:priv_AddDB("RecipesCutter", 552240);   -- Rezeptur - Seltener Purpurroter Dornenumhang
  
  db:priv_AddDB("RecipesCutter", 552245);   -- Rezeptur - Seltene Goldene Samthandschuhe
  db:priv_AddDB("RecipesCutter", 552246);   -- Rezeptur - Seltene Goldene Samthose
  db:priv_AddDB("RecipesCutter", 552247);   -- Rezeptur - Seltener Goldener SamtGürtel
  db:priv_AddDB("RecipesCutter", 552248);   -- Rezeptur - Seltener Goldener Samtumhang
  
  db:priv_AddDB("RecipesCutter", 552259);   -- Rezeptur - Transformierter Eisenlicht-Umhang
  
  db:priv_AddDB("RecipesCutter", 552263);   -- Rezeptur - Umhang der Transformierten Geisterbestie
  
  db:priv_AddDB("RecipesCutter", 552267);   -- Rezeptur - Umhang der Transformierten Giftigkeit
  
  db:priv_AddDB("RecipesCutter", 552271);   -- Rezeptur - Umhang des Transformierten Lindwurms
  
  db:priv_AddDB("RecipesCutter", 552275);   -- Rezeptur - Umhang des Transformierten Heulers
  db:priv_AddDB("RecipesCutter", 552276);   -- Rezeptur - Handschuhe des Transformierten Lenkers
  db:priv_AddDB("RecipesCutter", 552277);   -- Rezeptur - Hose des Transformierten Lenkers
  db:priv_AddDB("RecipesCutter", 552278);   -- Rezeptur - Gürtel des Transformierten Lenkers
  db:priv_AddDB("RecipesCutter", 552279);   -- Rezeptur - Umhang des Transformierten Lenkers

  db:priv_AddDB("RecipesCutter", 552288);   -- Rezeptur -
  
  db:priv_AddDB("RecipesCutter", 552292);   -- Rezeptur - Schneidertruhe des Rätsels
  
  db:priv_AddDB("RecipesCutter", 552457);   -- Rezeptur - Goldene Samtkrone
  db:priv_AddDB("RecipesCutter", 552458);   -- Rezeptur - Goldene Samtschuhe
  db:priv_AddDB("RecipesCutter", 552459);   -- Rezeptur - Goldene Samtrobe
  db:priv_AddDB("RecipesCutter", 552460);   -- Rezeptur - Goldene SamtSchulterglücksbringer
  
  db:priv_AddDB("RecipesCutter", 552475);   -- Rezeptur - Verbesserte goldene Samtkrone
  db:priv_AddDB("RecipesCutter", 552476);   -- Rezeptur - Verbesserte goldene Samtschuhe
  db:priv_AddDB("RecipesCutter", 552477);   -- Rezeptur - Verbesserte goldene Samtrobe
  db:priv_AddDB("RecipesCutter", 552478);   -- Rezeptur - Verbesserter goldener SamtSchulterglücksbringer
  
  db:priv_AddDB("RecipesCutter", 552493);   -- Rezeptur - Seltene goldene Samtkrone
  db:priv_AddDB("RecipesCutter", 552494);   -- Rezeptur - Seltene goldene Samtschuhe
  db:priv_AddDB("RecipesCutter", 552495);   -- Rezeptur - Seltene goldene Samtrobe
  db:priv_AddDB("RecipesCutter", 552496);   -- Rezeptur - Seltener goldener SamtSchulterglücksbringer
  
  db:priv_AddDB("RecipesCutter", 552515);   -- Rezeptur - Kopfbedeckung des transformierten K?nigs des Feuers
  db:priv_AddDB("RecipesCutter", 552516);   -- Rezeptur - Schuhe des transformierten K?nigs des Feuers
  db:priv_AddDB("RecipesCutter", 552517);   -- Rezeptur - Robe des transformierten K?nigs des Feuers
  db:priv_AddDB("RecipesCutter", 552518);   -- Rezeptur - Schulterglücksbringer des transformierten K?nigs des Feuers
  db:priv_AddDB("RecipesCutter", 552519);   -- Rezeptur - Machtkopfbedeckung des transformierten D?monenkaisers
  db:priv_AddDB("RecipesCutter", 552520);   -- Rezeptur - Machtschuhe des transformierten D?monenkaisers
  db:priv_AddDB("RecipesCutter", 552521);   -- Rezeptur - Machtrobe des transformierten D?monenkaisers
  db:priv_AddDB("RecipesCutter", 552522);   -- Rezeptur - MachtSchulterglücksbringer des transformierten D?monenkaisers
  
  db:priv_AddDB("RecipesCutter", 552529);   -- Rezeptur - Runenschneidertruhe
  
  db:priv_AddDB("RecipesCutter", 552591);   -- Rezeptur - Umhang der Shotakpiraten
  
  db:priv_AddDB("RecipesCutter", 552595);   -- Rezeptur - Umhang der Frankopiraten
  
  db:priv_AddDB("RecipesCutter", 552599);   -- Rezeptur - Umhang des Schwarzzahn-Schn?blers
  db:priv_AddDB("RecipesCutter", 552600);   -- Rezeptur - Steppenhandschuhe
  db:priv_AddDB("RecipesCutter", 552601);   -- Rezeptur - SteppenGürtel
  
  db:priv_AddDB("RecipesCutter", 552603);   -- Rezeptur - Steppenumhang
  
  db:priv_AddDB("RecipesCutter", 552607);   -- Rezeptur - Verbesserter Umhang der Shotakpiraten
  
  db:priv_AddDB("RecipesCutter", 552611);   -- Rezeptur - Verbesserter Umhang der Frankopiraten
  
  db:priv_AddDB("RecipesCutter", 552615);   -- Rezeptur - Verbesserter Umhang des Schwarzzahn-Schn?blers
  db:priv_AddDB("RecipesCutter", 552616);   -- Rezeptur - Verbesserter Steppenhandschuh
  db:priv_AddDB("RecipesCutter", 552617);   -- Rezeptur - Verbesserter SteppenGürtel
  db:priv_AddDB("RecipesCutter", 552618);   -- Rezeptur - Verbesserte Steppenhose
  db:priv_AddDB("RecipesCutter", 552619);   -- Rezeptur - Verbesserter Steppenumhang
  
  db:priv_AddDB("RecipesCutter", 552623);   -- Rezeptur - Seltener Umhang der Shotakpiraten
  
  db:priv_AddDB("RecipesCutter", 552627);   -- Rezeptur - Seltener Umhang der Frankopiraten
  
  db:priv_AddDB("RecipesCutter", 552631);   -- Rezeptur - Seltener Umhang des Schwarzzahn-Schn?blers
  db:priv_AddDB("RecipesCutter", 552632);   -- Rezeptur - Seltener Steppenhandschuh
  db:priv_AddDB("RecipesCutter", 552633);   -- Rezeptur - Seltener SteppenGürtel
  db:priv_AddDB("RecipesCutter", 552634);   -- Rezeptur - Seltene Steppenhose
  db:priv_AddDB("RecipesCutter", 552635);   -- Rezeptur - Seltener Steppenumhang
  
  db:priv_AddDB("RecipesCutter", 552639);   -- Rezeptur - Transformierter Umhang der Stahlspinne
  
  db:priv_AddDB("RecipesCutter", 552643);   -- Rezeptur - Transformierter Metallumhang der Leere
  
  db:priv_AddDB("RecipesCutter", 552647);   -- Rezeptur - Transformierter Umhang der verbotenen Runen
  
  db:priv_AddDB("RecipesCutter", 552651);   -- Rezeptur - Transformierter Umhang des Meer-Elementars
  
  db:priv_AddDB("RecipesCutter", 552652);   -- Rezeptur - Transformierter Handschuh der gierigen G?ttin
  
  db:priv_AddDB("RecipesCutter", 552654);   -- Rezeptur - Transformierte Hose der gierigen G?ttin
  db:priv_AddDB("RecipesCutter", 552655);   -- Rezeptur - Transformierter Umhang der gierigen G?ttin
  db:priv_AddDB("RecipesCutter", 552656);   -- Rezeptur - Transformierter Handschuh der Stimme des Meeres
  db:priv_AddDB("RecipesCutter", 552657);   -- Rezeptur - Transformierter Gürtel der Stimme des Meeres
  db:priv_AddDB("RecipesCutter", 552658);   -- Rezeptur - Transformierte Hose der Stimme des Meeres
  db:priv_AddDB("RecipesCutter", 552659);   -- Rezeptur - Transformierter Umhang der Stimme des Meeres
  
  db:priv_AddDB("RecipesCutter", 552663);   -- Rezeptur - Geheimnisvolle Schneidertruhe
  
  db:priv_AddDB("RecipesCutter", 552716);   -- Rezeptur - Leordenkapuze
  db:priv_AddDB("RecipesCutter", 552717);   -- Rezeptur - Leordenrobe
  db:priv_AddDB("RecipesCutter", 552718);   -- Rezeptur - Leorden-Schultersch?tzer
  db:priv_AddDB("RecipesCutter", 552719);   -- Rezeptur - Leordenstiefel
  
  db:priv_AddDB("RecipesCutter", 552734);   -- Rezeptur - Verbesserte Leordenkapuze
  db:priv_AddDB("RecipesCutter", 552735);   -- Rezeptur - Verbesserte Leordenrobe
  db:priv_AddDB("RecipesCutter", 552736);   -- Rezeptur - Verbesserte Leorden-Schultersch?tzer
  db:priv_AddDB("RecipesCutter", 552737);   -- Rezeptur - Verbesserte Leordenstiefel
  
  db:priv_AddDB("RecipesCutter", 552752);   -- Rezeptur - Seltene Leordenkapuze
  db:priv_AddDB("RecipesCutter", 552753);   -- Rezeptur - Seltene Leordenrobe
  db:priv_AddDB("RecipesCutter", 552754);   -- Rezeptur - Seltene Leorden-Schultersch?tzer
  db:priv_AddDB("RecipesCutter", 552755);   -- Rezeptur - Seltene Leordenstiefel
  
  db:priv_AddDB("RecipesCutter", 552774);   -- Rezeptur - Transformierte Kappe der R?stung
  db:priv_AddDB("RecipesCutter", 552775);   -- Rezeptur - Transformierte Robe der R?stung
  db:priv_AddDB("RecipesCutter", 552776);   -- Rezeptur - Transformierte Schultersch?tzer der R?stung
  db:priv_AddDB("RecipesCutter", 552777);   -- Rezeptur - Transformierte Stiefel der R?stung
  db:priv_AddDB("RecipesCutter", 552778);   -- Rezeptur - Transformierte Kopfbedeckung des Wiederg?ngers
  db:priv_AddDB("RecipesCutter", 552779);   -- Rezeptur - Transformierte Robe des Wiederg?ngers
  db:priv_AddDB("RecipesCutter", 552780);   -- Rezeptur - Transformierte Schultersch?tzer des Wiederg?ngers
  db:priv_AddDB("RecipesCutter", 552781);   -- Rezeptur - Transformierte Stiefel des Wiederg?ngers
  
  db:priv_AddDB("RecipesCutter", 552803);   -- Rezeptur - Geh?rtete Schneidertruhe
  
  db:priv_AddDB("RecipesCutter", 552807);   -- Rezeptur - Meisterhafte Schneidertruhe
  
  db:priv_AddDB("RecipesCutter", 552821);   -- Rezeptur - Legend?re Schneidertruhe
  
  db:priv_AddDB("RecipesCutter", 552825);   -- Rezeptur - Ultimative Schneidertruhe
  
  db:priv_AddDB("RecipesCutter", 552839);   -- Rezeptur - Himmlische Schneidertruhe
  
  db:priv_AddDB("RecipesCutter", 552843);   -- Rezeptur - G?ttliche Schneidertruhe
  
  db:priv_AddDB("RecipesCutter", 552930);   -- Rezeptur - Kulang-Umhang
  
  db:priv_AddDB("RecipesCutter", 552934);   -- Rezeptur - Walu-Umhang
  
  db:priv_AddDB("RecipesCutter", 552938);   -- Rezeptur - Umhang von Alaine
  db:priv_AddDB("RecipesCutter", 552939);   -- Rezeptur - Smaub-Handschuhe
  db:priv_AddDB("RecipesCutter", 552940);   -- Rezeptur - Smaub-Gürtel
  db:priv_AddDB("RecipesCutter", 552941);   -- Rezeptur - Smaub-Hose
  db:priv_AddDB("RecipesCutter", 552942);   -- Rezeptur - Umhang der Krypta
  
  db:priv_AddDB("RecipesCutter", 552948);   -- Rezeptur - Verbesserter Kulang-Umhang
  
  db:priv_AddDB("RecipesCutter", 552952);   -- Rezeptur - Verbesserter Walu-Umhang
  
  db:priv_AddDB("RecipesCutter", 552956);   -- Rezeptur - Verbesserter Umhang von Alaine
  db:priv_AddDB("RecipesCutter", 552957);   -- Rezeptur - Verbesserte Smaub-Handschuhe
  db:priv_AddDB("RecipesCutter", 552958);   -- Rezeptur - Verbesserter Smaub-Gürtel
  db:priv_AddDB("RecipesCutter", 552959);   -- Rezeptur - Verbesserte Smaub-Hose
  db:priv_AddDB("RecipesCutter", 552960);   -- Rezeptur - Verbesserter Umhang der Krypta
  
  db:priv_AddDB("RecipesCutter", 552966);   -- Rezeptur - Seltener Kulang-Umhang
  
  db:priv_AddDB("RecipesCutter", 552974);   -- Rezeptur - Seltener Umhang von Alaine
  db:priv_AddDB("RecipesCutter", 552975);   -- Rezeptur - Seltene Smaub-Handschuhe
  db:priv_AddDB("RecipesCutter", 552976);   -- Rezeptur - Seltener Smaub-Gürtel
  db:priv_AddDB("RecipesCutter", 552977);   -- Rezeptur - Seltene Smaub-Hose
  db:priv_AddDB("RecipesCutter", 552978);   -- Rezeptur - Seltener Umhang der Krypta
  
  db:priv_AddDB("RecipesCutter", 552984);   -- Rezeptur - Transformierter Umhang des Wolfshammers
  
  db:priv_AddDB("RecipesCutter", 552988);   -- Rezeptur - Transformierter Umhang der Bleiche
  
  db:priv_AddDB("RecipesCutter", 552992);   -- Rezeptur - Transformierter Umhang der Blutranken
  
  db:priv_AddDB("RecipesCutter", 552996);   -- Rezeptur - Transformierter Umhang der Bestie
  db:priv_AddDB("RecipesCutter", 552997);   -- Rezeptur - Transformierte Handschuhe des Feuers
  db:priv_AddDB("RecipesCutter", 552998);   -- Rezeptur - Transformierter Gürtel des Feuers
  db:priv_AddDB("RecipesCutter", 552999);   -- Rezeptur - Transformierte Hose des Feuers
  db:priv_AddDB("RecipesCutter", 553000);   -- Rezeptur - Transformierter Umhang des Feuers
  db:priv_AddDB("RecipesCutter", 553001);   -- Rezeptur - Transformierte Handschuhe des Vogelwiederg?ngers
  db:priv_AddDB("RecipesCutter", 553002);   -- Rezeptur - Transformierter Gürtel des Vogelwiederg?ngers
  db:priv_AddDB("RecipesCutter", 553003);   -- Rezeptur - Transformierte Hose des Vogelwiederg?ngers
  db:priv_AddDB("RecipesCutter", 553004);   -- Rezeptur - Transformierter Umhang des Vogelwiederg?ngers
  
  db:priv_AddDB("RecipesCutter", 553050);   -- Rezeptur - Kapuze des Abwehrfluches
  db:priv_AddDB("RecipesCutter", 553051);   -- Rezeptur - Gewand des Abwehrfluches
  db:priv_AddDB("RecipesCutter", 553052);   -- Rezeptur - Schultersch?tzer des Abwehrfluches
  db:priv_AddDB("RecipesCutter", 553053);   -- Rezeptur - Stiefel des Abwehrfluches
  
  db:priv_AddDB("RecipesCutter", 553068);   -- Rezeptur - Verstärkte Kapuze des Abwehrfluches
  db:priv_AddDB("RecipesCutter", 553069);   -- Rezeptur - Verstärktes Gewand des Abwehrfluches
  db:priv_AddDB("RecipesCutter", 553070);   -- Rezeptur - Verstärkter Schultersch?tzer des Abwehrfluches
  db:priv_AddDB("RecipesCutter", 553071);   -- Rezeptur - Verstärkte Stiefel des Abwehrfluches
  
  db:priv_AddDB("RecipesCutter", 553086);   -- Rezeptur - Seltene Kapuze des Abwehrfluches
  db:priv_AddDB("RecipesCutter", 553087);   -- Rezeptur - Seltenes Gewand des Abwehrfluches
  db:priv_AddDB("RecipesCutter", 553088);   -- Rezeptur - Seltener Schultersch?tzer des Abwehrfluches
  db:priv_AddDB("RecipesCutter", 553089);   -- Rezeptur - Seltene Stiefel des Abwehrfluches
  
  db:priv_AddDB("RecipesCutter", 553108);   -- Rezeptur - Transformierte Kappe des Entrei?ens
  db:priv_AddDB("RecipesCutter", 553109);   -- Rezeptur - Transformiertes Gewand des Entrei?ens
  db:priv_AddDB("RecipesCutter", 553110);   -- Rezeptur - Transformierter Umhang des Entrei?ens
  db:priv_AddDB("RecipesCutter", 553111);   -- Rezeptur - Transformierte Stiefel des Entrei?ens
  db:priv_AddDB("RecipesCutter", 553112);   -- Rezeptur - Transformierte Kopfbedeckung der Leerenenergie
  db:priv_AddDB("RecipesCutter", 553113);   -- Rezeptur - Transformiertes Gewand der Leerenenergie
  db:priv_AddDB("RecipesCutter", 553114);   -- Rezeptur - Transformierter Umhang der Leerenenergie
  db:priv_AddDB("RecipesCutter", 553115);   -- Rezeptur - Transformierte Stiefel der Leerenenergie
  
  db:priv_AddDB("RecipesCutter", 553150);   -- Rezeptur - Umhang der Eisenschwinge
  
  db:priv_AddDB("RecipesCutter", 553154);   -- Rezeptur - Silberzimt-Umhang
  
  db:priv_AddDB("RecipesCutter", 553158);   -- Rezeptur - Bartasumhang
  db:priv_AddDB("RecipesCutter", 553159);   -- Rezeptur - Handschuhe des Crohnhofes
  db:priv_AddDB("RecipesCutter", 553160);   -- Rezeptur - Gürtel des Crohnhofes
  db:priv_AddDB("RecipesCutter", 553161);   -- Rezeptur - Hose des Crohnhofes
  db:priv_AddDB("RecipesCutter", 553162);   -- Rezeptur - Umhang des Crohnhofes
  
  db:priv_AddDB("RecipesCutter", 553168);   -- Rezeptur - Verbesserter Umhang der Eisenschwinge
  
  db:priv_AddDB("RecipesCutter", 553172);   -- Rezeptur - Verbesserter Silberzimt-Umhang
  
  db:priv_AddDB("RecipesCutter", 553176);   -- Rezeptur - Verbesserter Bartasumhang
  db:priv_AddDB("RecipesCutter", 553177);   -- Rezeptur - Verbesserte Handschuhe des Crohnhofes
  db:priv_AddDB("RecipesCutter", 553178);   -- Rezeptur - Verbesserter Gürtel des Crohnhofes
  db:priv_AddDB("RecipesCutter", 553179);   -- Rezeptur - Verbesserte Hose des Crohnhofes
  
  db:priv_AddDB("RecipesCutter", 553186);   -- Rezeptur - Seltener Umhang der Eisenschwinge
  
  db:priv_AddDB("RecipesCutter", 553190);   -- Rezeptur - Seltener Silberzimt-Umhang
  
  db:priv_AddDB("RecipesCutter", 553194);   -- Rezeptur - Seltener Bartasumhang
  db:priv_AddDB("RecipesCutter", 553195);   -- Rezeptur - Seltene Handschuhe des Crohnhofes
  db:priv_AddDB("RecipesCutter", 553196);   -- Rezeptur - Seltener Gürtel des Crohnhofes
  db:priv_AddDB("RecipesCutter", 553197);   -- Rezeptur - Seltene Hose des Crohnhofes
  db:priv_AddDB("RecipesCutter", 553198);   -- Rezeptur - Seltener Umhang des Crohnhofes
  
  db:priv_AddDB("RecipesCutter", 553204);   -- Rezeptur - Transformierter Umhang der Sirenenk?nigin
  
  db:priv_AddDB("RecipesCutter", 553208);   -- Rezeptur - Transformierter Umhang des Großen Koboldh?uptlings
  
  db:priv_AddDB("RecipesCutter", 553212);   -- Rezeptur - Transformierter Umhang des Splitterstromschurken
  
  db:priv_AddDB("RecipesCutter", 553216);   -- Rezeptur - Transformierter Umhang des Tiktaalikgenerals
  db:priv_AddDB("RecipesCutter", 553217);   -- Rezeptur - Transformierte Handschuhe von Lorl
  db:priv_AddDB("RecipesCutter", 553218);   -- Rezeptur - Transformierter Gürtel von Lorl
  db:priv_AddDB("RecipesCutter", 553219);   -- Rezeptur - Transformierte Hose von Lorl
  db:priv_AddDB("RecipesCutter", 553220);   -- Rezeptur - Transformierter Umhang von Lorl
  db:priv_AddDB("RecipesCutter", 553221);   -- Rezeptur - Transformierte Handschuhe der verlorenen Klinge
  db:priv_AddDB("RecipesCutter", 553222);   -- Rezeptur - Transformierter Gürtel der verlorenen Klinge
  db:priv_AddDB("RecipesCutter", 553223);   -- Rezeptur - Transformierte Hose der verlorenen Klinge
  db:priv_AddDB("RecipesCutter", 553224);   -- Rezeptur - Transformierter Umhang der verlorenen Klinge
  
  db:priv_AddDB("RecipesCutter", 553264);   -- Rezeptur - Kapuze von Shadis
  db:priv_AddDB("RecipesCutter", 553265);   -- Rezeptur - Robe von Shadis
  db:priv_AddDB("RecipesCutter", 553266);   -- Rezeptur - Schultersch?tzer von Shadis
  db:priv_AddDB("RecipesCutter", 553267);   -- Rezeptur - Stiefel von Shadis
  
  db:priv_AddDB("RecipesCutter", 553283);   -- Rezeptur - Verbesserte Robe von Shadis
  db:priv_AddDB("RecipesCutter", 553284);   -- Rezeptur - Verbesserte Schultersch?tzer von Shadis
  db:priv_AddDB("RecipesCutter", 553285);   -- Rezeptur - Verbesserte Stiefel von Shadis
  
  db:priv_AddDB("RecipesCutter", 553300);   -- Rezeptur - Seltene Kapuze von Shadis
  db:priv_AddDB("RecipesCutter", 553301);   -- Rezeptur - Seltene Robe von Shadis
  db:priv_AddDB("RecipesCutter", 553302);   -- Rezeptur - Seltene Schultersch?tzer von Shadis
  db:priv_AddDB("RecipesCutter", 553303);   -- Rezeptur - Seltene Stiefel von Shadis
  
  db:priv_AddDB("RecipesCutter", 553322);   -- Rezeptur - Transformierte Kappe des verlorenen Modders
  db:priv_AddDB("RecipesCutter", 553323);   -- Rezeptur - Transformierte Robe des verlorenen Modders
  db:priv_AddDB("RecipesCutter", 553324);   -- Rezeptur - Transformierte Schultersch?tzer des verlorenen Modders
  db:priv_AddDB("RecipesCutter", 553325);   -- Rezeptur - Transformierte Stiefel des verlorenen Modders
  db:priv_AddDB("RecipesCutter", 553326);   -- Rezeptur - Transformierte Kopfbedeckung des Gro?meisters der Toten
  db:priv_AddDB("RecipesCutter", 553327);   -- Rezeptur - Transformierte Robe des Gro?meisters der Toten
  db:priv_AddDB("RecipesCutter", 553328);   -- Rezeptur - Transformierte Schultersch?tzer des Gro?meisters der Toten
  db:priv_AddDB("RecipesCutter", 553329);   -- Rezeptur - Transformierte Stiefel des Gro?meisters der Toten

  db:priv_AddDB("RecipesCutter", 553364);   -- Rezeptur - Umhang der Silberspuren
  
  db:priv_AddDB("RecipesCutter", 553368);   -- Rezeptur - Umhang des Tals ohne Wiederkehr
  
  db:priv_AddDB("RecipesCutter", 553372);   -- Rezeptur - Staubkesselumhang
  db:priv_AddDB("RecipesCutter", 553373);   -- Rezeptur - Handschuhe des Dickichts
  db:priv_AddDB("RecipesCutter", 553374);   -- Rezeptur - Gürtel des Dickichts
  db:priv_AddDB("RecipesCutter", 553375);   -- Rezeptur - Langhose des Dickichts
  db:priv_AddDB("RecipesCutter", 553376);   -- Rezeptur - Umhang des Dickichts
  
  db:priv_AddDB("RecipesCutter", 553382);   -- Rezeptur - Verbesserter Umhang der Silberspuren
  
  db:priv_AddDB("RecipesCutter", 553386);   -- Rezeptur - Verbesserter Umhang des Tals ohne Wiederkehr
  
  db:priv_AddDB("RecipesCutter", 553390);   -- Rezeptur - Verbesserter Staubkesselumhang
  db:priv_AddDB("RecipesCutter", 553391);   -- Rezeptur - Verbesserte Handschuhe des Dickichts
  db:priv_AddDB("RecipesCutter", 553392);   -- Rezeptur - Verbesserter Gürtel des Dickichts
  db:priv_AddDB("RecipesCutter", 553393);   -- Rezeptur - Verbesserte Langhose des Dickichts
  db:priv_AddDB("RecipesCutter", 553394);   -- Rezeptur - Verbesserter Umhang des Dickichts
  
  db:priv_AddDB("RecipesCutter", 553400);   -- Rezeptur - Seltener Umhang der Silberspuren
  
  db:priv_AddDB("RecipesCutter", 553404);   -- Rezeptur - Seltener Umhang des Tals ohne Wiederkehr
  
  db:priv_AddDB("RecipesCutter", 553408);   -- Rezeptur - Seltener Staubkesselumhang
  db:priv_AddDB("RecipesCutter", 553409);   -- Rezeptur - Seltene Handschuhe des Dickichts
  db:priv_AddDB("RecipesCutter", 553410);   -- Rezeptur - Seltener Gürtel des Dickichts
  db:priv_AddDB("RecipesCutter", 553411);   -- Rezeptur - Seltene Langhosen des Dickichts
  db:priv_AddDB("RecipesCutter", 553412);   -- Rezeptur - Seltener Umhang des Dickichts
  db:priv_AddDB("RecipesCutter", 553418);   -- Rezeptur - Transformierter Umhang der Klingen
  db:priv_AddDB("RecipesCutter", 553422);   -- Rezeptur - Transformierter Umhang der Passage der Pr?fungen
  db:priv_AddDB("RecipesCutter", 553426);   -- Rezeptur - Transformierter Umhang der Energiestr?me
  
  db:priv_AddDB("RecipesCutter", 553430);   -- Rezeptur - Transformierter Hirntentakel-Umhang
  db:priv_AddDB("RecipesCutter", 553431);   -- Rezeptur - Transformierte Handschuhe des Kristallbogens
  db:priv_AddDB("RecipesCutter", 553432);   -- Rezeptur - Transformierter Gürtel des Kristallbogens
  db:priv_AddDB("RecipesCutter", 553433);   -- Rezeptur - Transformierte Langhose des Kristallbogens
  db:priv_AddDB("RecipesCutter", 553434);   -- Rezeptur - Transformierter Umhang des Kristallbogens
  db:priv_AddDB("RecipesCutter", 553435);   -- Rezeptur - Transformierte Handschuhe der Experimentalplattform
  db:priv_AddDB("RecipesCutter", 553436);   -- Rezeptur - Transformierter Gürtel der Experimentalplattform
  db:priv_AddDB("RecipesCutter", 553437);   -- Rezeptur - Transformierte Langhose der Experimentalplattform
  db:priv_AddDB("RecipesCutter", 553438);   -- Rezeptur - Transformierter Umhang der Experimentalplattform
  
  db:priv_AddDB("RecipesCutter", 553460);   -- Rezeptur - Transformierter mahnender Kopfschmuck der Toten
  db:priv_AddDB("RecipesCutter", 553461);   -- Rezeptur - Transformierte mahnende Robe der Toten
  db:priv_AddDB("RecipesCutter", 553462);   -- Rezeptur - Transformierte mahnende Schultersch?tzer der Toten
  db:priv_AddDB("RecipesCutter", 553463);   -- Rezeptur - Transformierte mahnende Stiefel der Toten
  db:priv_AddDB("RecipesCutter", 553464);   -- Rezeptur - Transformierter Kopfschmuck des D?monenauges
  db:priv_AddDB("RecipesCutter", 553465);   -- Rezeptur - Transformierte Robe des D?monenauges
  db:priv_AddDB("RecipesCutter", 553466);   -- Rezeptur - Transformierte Schultersch?tzer des D?monenauges
  db:priv_AddDB("RecipesCutter", 553467);   -- Rezeptur - Transformierte Stiefel des D?monenauges
  
  db:priv_AddDB("RecipesCutter", 553473);   -- Rezeptur - Transformierter Umhang des Tempelw?chters
  
  db:priv_AddDB("RecipesCutter", 553477);   -- Rezeptur - Transformierter Umhang der Säenden
  

  db:priv_AddDB("RecipesCutter", 553481);   -- Rezeptur - Transformierter Umhang des Meisterj?gers
  db:priv_AddDB("RecipesCutter", 553482);   -- Rezeptur - Transformierte Handschuhe der Modertentakel
  db:priv_AddDB("RecipesCutter", 553483);   -- Rezeptur - Transformierter Gürtel der Modertentakel
  db:priv_AddDB("RecipesCutter", 553484);   -- Rezeptur - Transformierte Hose der Modertentakel
  db:priv_AddDB("RecipesCutter", 553485);   -- Rezeptur - Transformierter Umhang der Modertentakel
  db:priv_AddDB("RecipesCutter", 553486);   -- Rezeptur - Transformierte Handschuhe des Elfenpriesters
  db:priv_AddDB("RecipesCutter", 553487);   -- Rezeptur - Transformierter Gürtel des Elfenpriesters
  db:priv_AddDB("RecipesCutter", 553488);   -- Rezeptur - Transformierte Hose des Elfenpriesters
  db:priv_AddDB("RecipesCutter", 553489);   -- Rezeptur - Transformierter Umhang des Elfenpriesters
  
  db:priv_AddDB("RecipesCutter", 553502);   -- Rezeptur - 236158
  db:priv_AddDB("RecipesCutter", 553506);   -- Rezeptur
  db:priv_AddDB("RecipesCutter", 553510);   -- Rezeptur
  db:priv_AddDB("RecipesCutter", 553511);   -- Rezeptur
  db:priv_AddDB("RecipesCutter", 553512);   -- Rezeptur
  db:priv_AddDB("RecipesCutter", 553513);   -- Rezeptur
  db:priv_AddDB("RecipesCutter", 553514);   -- Rezeptur
  db:priv_AddDB("RecipesCutter", 553515);   -- Rezeptur
  db:priv_AddDB("RecipesCutter", 553516);   -- Rezeptur
  db:priv_AddDB("RecipesCutter", 553517);   -- Rezeptur
  db:priv_AddDB("RecipesCutter", 553518);   -- Rezeptur

  
end

local function priv_AddRecipesCarpenter(db)   -- Rezepte Schreiner

  db:priv_AddDB("RecipesCarpenter", 549486);   -- Rezeptur - 
  db:priv_AddDB("RecipesCarpenter", 550256);   -- Rezeptur - Verbesserte einfache Armbrust
  db:priv_AddDB("RecipesCarpenter", 550257);   -- Rezeptur - Einfache Armbrust
  db:priv_AddDB("RecipesCarpenter", 550258);   -- Rezeptur - Stein-Armbrust
  db:priv_AddDB("RecipesCarpenter", 550259);   -- Rezeptur - Kopfj?ger-Armbrust
  db:priv_AddDB("RecipesCarpenter", 550260);   -- Rezeptur - Verbesserte Repetierarmbrust
  db:priv_AddDB("RecipesCarpenter", 550261);   -- Rezeptur - Repetierarmbrust
  db:priv_AddDB("RecipesCarpenter", 550262);   -- Rezeptur - Gezackte Armbrust
  db:priv_AddDB("RecipesCarpenter", 550263);   -- Rezeptur - Verbesserte Schmetterlingsarmbrust
  db:priv_AddDB("RecipesCarpenter", 550264);   -- Rezeptur - Schmetterlingsarmbrust
  db:priv_AddDB("RecipesCarpenter", 550265);   -- Rezeptur - Verbesserte Stahlarmbrust
  db:priv_AddDB("RecipesCarpenter", 550266);   -- Rezeptur - Stahlarmbrust
  db:priv_AddDB("RecipesCarpenter", 550267);   -- Rezeptur - Fl?gelarmbrust
  db:priv_AddDB("RecipesCarpenter", 550268);   -- Rezeptur - Drachenhorn-Armbrust
  db:priv_AddDB("RecipesCarpenter", 550269);   -- Rezeptur - Verbesserte Nachtschatten-Armbrust
  db:priv_AddDB("RecipesCarpenter", 550270);   -- Rezeptur - Nachtschatten-Armbrust
  db:priv_AddDB("RecipesCarpenter", 550271);   -- Rezeptur - Feiner Holzbogen
  db:priv_AddDB("RecipesCarpenter", 550272);   -- Rezeptur - Verbesserter harter Holzbogen
  db:priv_AddDB("RecipesCarpenter", 550273);   -- Rezeptur - Harter Holzbogen
  db:priv_AddDB("RecipesCarpenter", 550274);   -- Rezeptur - Verbesserter geh?rteter Kurzbogen
  db:priv_AddDB("RecipesCarpenter", 550275);   -- Rezeptur - Geh?rteter Kurzbogen
  db:priv_AddDB("RecipesCarpenter", 550276);   -- Rezeptur - Verbesserter Kriegsbogen
  db:priv_AddDB("RecipesCarpenter", 550277);   -- Rezeptur - Aufseher-Langbogen
  db:priv_AddDB("RecipesCarpenter", 550278);   -- Rezeptur - Hornbogen des gr?nen Zwergs
  db:priv_AddDB("RecipesCarpenter", 550279);   -- Rezeptur - Erstaunlicher Bogen
  db:priv_AddDB("RecipesCarpenter", 550280);   -- Rezeptur - Verbesserter harter Federbogen
  db:priv_AddDB("RecipesCarpenter", 550281);   -- Rezeptur - Harter Federbogen
  db:priv_AddDB("RecipesCarpenter", 550282);   -- Rezeptur - Verbesserter Bogen der Pr?zision
  db:priv_AddDB("RecipesCarpenter", 550283);   -- Rezeptur - Bogen der Pr?zision
  db:priv_AddDB("RecipesCarpenter", 550284);   -- Rezeptur - Silbermondbogen
  db:priv_AddDB("RecipesCarpenter", 550285);   -- Rezeptur - Verbesserter Bogen des Nachtd?mons
  db:priv_AddDB("RecipesCarpenter", 550286);   -- Rezeptur - Bogen des Nachtd?mons
  db:priv_AddDB("RecipesCarpenter", 550287);   -- Rezeptur - Geisterholz Bogen
  db:priv_AddDB("RecipesCarpenter", 550288);   -- Rezeptur - Pr?chtige Blume
  db:priv_AddDB("RecipesCarpenter", 550289);   -- Rezeptur - Verbesserte Spiegelblume
  db:priv_AddDB("RecipesCarpenter", 550290);   -- Rezeptur - Spiegelblume
  db:priv_AddDB("RecipesCarpenter", 550291);   -- Rezeptur - Totem der Zaubererseele
  db:priv_AddDB("RecipesCarpenter", 550292);   -- Rezeptur - Energiesteuerndes Ger?t
  db:priv_AddDB("RecipesCarpenter", 550293);   -- Rezeptur - Verbessertes Hexenhaar
  db:priv_AddDB("RecipesCarpenter", 550294);   -- Rezeptur - Hexenhaar
  db:priv_AddDB("RecipesCarpenter", 550295);   -- Rezeptur - Schwinge des dunklen Drachens
  db:priv_AddDB("RecipesCarpenter", 550296);   -- Rezeptur - Verbesserte Greifenschwinge
  db:priv_AddDB("RecipesCarpenter", 550297);   -- Rezeptur - Greifenschwinge
  db:priv_AddDB("RecipesCarpenter", 550298);   -- Rezeptur - Mahdis Buch
  db:priv_AddDB("RecipesCarpenter", 550299);   -- Rezeptur - Verbesserte Todesgedichte
  db:priv_AddDB("RecipesCarpenter", 550300);   -- Rezeptur - Todesgedichte
  db:priv_AddDB("RecipesCarpenter", 550301);   -- Rezeptur - Verbesserter Zweihand-Langstab
  db:priv_AddDB("RecipesCarpenter", 550302);   -- Rezeptur - Zweihand-Langstab
  db:priv_AddDB("RecipesCarpenter", 550303);   -- Rezeptur - Verbesserter ?bungs-Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550304);   -- Rezeptur - ?bungs-Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550305);   -- Rezeptur - Mond-Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550307);   -- Rezeptur - Verbesserter Zweihandstab von Sadis
  db:priv_AddDB("RecipesCarpenter", 550308);   -- Rezeptur - Zweihandstab von Sadis
  db:priv_AddDB("RecipesCarpenter", 550309);   -- Rezeptur - Hexenbiss-Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550310);   -- Rezeptur - Verbesserter Zweihandstab der Hexerei
  db:priv_AddDB("RecipesCarpenter", 550311);   -- Rezeptur - Zweihandstab der Hexerei
  db:priv_AddDB("RecipesCarpenter", 550312);   -- Rezeptur - Verbesserter Feder-Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550313);   -- Rezeptur - Feder-Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550314);   -- Rezeptur - Heiliger Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550315);   -- Rezeptur - Zweihandstab des Lasterhaften
  db:priv_AddDB("RecipesCarpenter", 550316);   -- Rezeptur - Zweihandstab der Best?ndigkeit
  db:priv_AddDB("RecipesCarpenter", 550317);   -- Rezeptur - Verbesserter Zweihandstab der Zeit
  db:priv_AddDB("RecipesCarpenter", 550318);   -- Rezeptur - Zweihandstab der Zeit
  db:priv_AddDB("RecipesCarpenter", 550319);   -- Rezeptur - Verbesserter Zweihandstab der Wunder
  db:priv_AddDB("RecipesCarpenter", 550320);   -- Rezeptur - Zweihandstab der Wunder
  db:priv_AddDB("RecipesCarpenter", 550321);   -- Rezeptur - Melins Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550322);   -- Rezeptur - Verbesserter Vogelgeist-Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550323);   -- Rezeptur - Vogelgeist-Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550324);   -- Rezeptur - Verbesserter Zweihandstab des Lebens
  db:priv_AddDB("RecipesCarpenter", 550325);   -- Rezeptur - Zweihandstab des Lebens
  db:priv_AddDB("RecipesCarpenter", 550326);   -- Rezeptur - Giris Zweihandstab der Konzentration
  db:priv_AddDB("RecipesCarpenter", 550327);   -- Rezeptur - H?lzerner Kurzstab
  db:priv_AddDB("RecipesCarpenter", 550328);   -- Rezeptur - Verbesserter Kurzstab der Magie
  db:priv_AddDB("RecipesCarpenter", 550329);   -- Rezeptur - Kurzstab der Magie
  db:priv_AddDB("RecipesCarpenter", 550330);   -- Rezeptur - Stab der magischen Fl?te
  db:priv_AddDB("RecipesCarpenter", 550331);   -- Rezeptur - Achatstab
  db:priv_AddDB("RecipesCarpenter", 550332);   -- Rezeptur - Verbesserter ?berlegener Stab
  db:priv_AddDB("RecipesCarpenter", 550333);   -- Rezeptur - ?berlegener Stab
  db:priv_AddDB("RecipesCarpenter", 550334);   -- Rezeptur - Verbesserter W?nschelstab
  db:priv_AddDB("RecipesCarpenter", 550335);   -- Rezeptur - W?nschelstab
  db:priv_AddDB("RecipesCarpenter", 550336);   -- Rezeptur - Magischer Knochenstab
  db:priv_AddDB("RecipesCarpenter", 550337);   -- Rezeptur - Mythischer Vogelstab
  db:priv_AddDB("RecipesCarpenter", 550338);   -- Rezeptur - Stab des heiligen Lichts
  db:priv_AddDB("RecipesCarpenter", 550339);   -- Rezeptur - Verbesserter Kurzstab des Geistes
  db:priv_AddDB("RecipesCarpenter", 550340);   -- Rezeptur - Kurzstab des Geistes
  db:priv_AddDB("RecipesCarpenter", 550341);   -- Rezeptur - Says Stab
  db:priv_AddDB("RecipesCarpenter", 550342);   -- Rezeptur - Verbesserter Blaufarn-Stab
  db:priv_AddDB("RecipesCarpenter", 550343);   -- Rezeptur - Blaufarn-Stab
  db:priv_AddDB("RecipesCarpenter", 550740);   -- Rezeptur - Verbesserte Stein-Armbrust
  db:priv_AddDB("RecipesCarpenter", 550741);   -- Rezeptur - Jessies Armbrust
  db:priv_AddDB("RecipesCarpenter", 550742);   -- Rezeptur - Verbesserte gezackte Armbrust
  db:priv_AddDB("RecipesCarpenter", 550743);   -- Rezeptur - Dreispitzen-Armbrust
  db:priv_AddDB("RecipesCarpenter", 550744);   -- Rezeptur - Orangefarbene Schmetterlingsarmbrust
  db:priv_AddDB("RecipesCarpenter", 550745);   -- Rezeptur - Himmelblaue Armbrust
  db:priv_AddDB("RecipesCarpenter", 550746);   -- Rezeptur - Verbesserte Gefl?gelte Armbrust
  db:priv_AddDB("RecipesCarpenter", 550747);   -- Rezeptur - D?monen-Armbrust
  db:priv_AddDB("RecipesCarpenter", 550748);   -- Rezeptur - Verbesserte Drachenhorn-Armbrust
  db:priv_AddDB("RecipesCarpenter", 550749);   -- Rezeptur - Geister-Armbrust
  db:priv_AddDB("RecipesCarpenter", 550750);   -- Rezeptur - Schwarzmond-Armbrust
  db:priv_AddDB("RecipesCarpenter", 550751);   -- Rezeptur - Langlebiger Holzbogen
  db:priv_AddDB("RecipesCarpenter", 550752);   -- Rezeptur - Federleichter geh?rteter Kurzbogen
  db:priv_AddDB("RecipesCarpenter", 550753);   -- Rezeptur - Larna-Gebirgskriegsbogen
  db:priv_AddDB("RecipesCarpenter", 550754);   -- Rezeptur - Verbesserter Hornbogen des gr?nen Zwergs
  db:priv_AddDB("RecipesCarpenter", 550755);   -- Rezeptur - Hornbogen des Erdgeistk?nigs
  db:priv_AddDB("RecipesCarpenter", 550756);   -- Rezeptur - Bogen des Falkenauges
  db:priv_AddDB("RecipesCarpenter", 550757);   -- Rezeptur - Verbesserter Geisterwaldbogen
  db:priv_AddDB("RecipesCarpenter", 550758);   -- Rezeptur - Moderholz-Geisterbogen
  db:priv_AddDB("RecipesCarpenter", 550759);   -- Rezeptur - Verbessertes Totem der Zaubererseele
  db:priv_AddDB("RecipesCarpenter", 550760);   -- Rezeptur - Totem des Zauberers
  db:priv_AddDB("RecipesCarpenter", 550761);   -- Rezeptur - Notizen des Schamanen
  db:priv_AddDB("RecipesCarpenter", 550762);   -- Rezeptur - Verbesserte Notizen des Schamanen
  db:priv_AddDB("RecipesCarpenter", 550763);   -- Rezeptur - Aufzeichnungen des Schamanen
  db:priv_AddDB("RecipesCarpenter", 550764);   -- Rezeptur - Giftschlangen-Rohrstock
  db:priv_AddDB("RecipesCarpenter", 550765);   -- Rezeptur - Verbessertes giftschlangenf?rmiges Rattan
  db:priv_AddDB("RecipesCarpenter", 550766);   -- Rezeptur - T?dlicher Giftschlangen-Rohrstock
  db:priv_AddDB("RecipesCarpenter", 550767);   -- Rezeptur - Puppe des Schamanen
  db:priv_AddDB("RecipesCarpenter", 550768);   -- Rezeptur - Verbesserte Puppe des Schamanen
  db:priv_AddDB("RecipesCarpenter", 550769);   -- Rezeptur - Voodoo-Puppe
  db:priv_AddDB("RecipesCarpenter", 550770);   -- Rezeptur - D?monen-Sammelgef??
  db:priv_AddDB("RecipesCarpenter", 550771);   -- Rezeptur - Verbessertes D?monen-Sammelgef??
  db:priv_AddDB("RecipesCarpenter", 550772);   -- Rezeptur - Jayangpasi
  db:priv_AddDB("RecipesCarpenter", 550773);   -- Rezeptur - Kleiner Magier-Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550774);   -- Rezeptur - Verbesserter Mond-Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550775);   -- Rezeptur - Vollmond-Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550776);   -- Rezeptur - Feder-Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550777);   -- Rezeptur - Verbesserter heiliger Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550778);   -- Rezeptur - Anlins Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 550780);   -- Rezeptur - Zweihandstab des Lebens
  db:priv_AddDB("RecipesCarpenter", 550781);   -- Rezeptur - Kurzstab der Zauberei
  db:priv_AddDB("RecipesCarpenter", 550782);   -- Rezeptur - Magischer Weidenstab
  db:priv_AddDB("RecipesCarpenter", 550783);   -- Rezeptur - Verbesserter magischer Weidenstab
  db:priv_AddDB("RecipesCarpenter", 550784);   -- Rezeptur - Dryadenstab
  db:priv_AddDB("RecipesCarpenter", 550785);   -- Rezeptur - Stab des Mystikers
  db:priv_AddDB("RecipesCarpenter", 550786);   -- Rezeptur - Verbesserter magischer Knochenstab
  db:priv_AddDB("RecipesCarpenter", 550787);   -- Rezeptur - Mawais Knochenstab
  db:priv_AddDB("RecipesCarpenter", 550788);   -- Rezeptur - Verbesserter Stab des mythischen Vogels
  db:priv_AddDB("RecipesCarpenter", 550789);   -- Rezeptur - Zauberstab des heiligen Wodar
  db:priv_AddDB("RecipesCarpenter", 550965);   -- Rezeptur - Zweihandstab von Gelant
  db:priv_AddDB("RecipesCarpenter", 550966);   -- Rezeptur - Heiliger Zweihandstab von Gelant
  db:priv_AddDB("RecipesCarpenter", 550967);   -- Rezeptur - Blitzbogen von Solice
  db:priv_AddDB("RecipesCarpenter", 550968);   -- Rezeptur - Tiefblauer Blitzbogen von Solice
  db:priv_AddDB("RecipesCarpenter", 551030);   -- Rezeptur - Dunkler Bogen des Verrats des Flammendrachen
  db:priv_AddDB("RecipesCarpenter", 551031);   -- Rezeptur - Pechklaue des Flammendrachen (Zweihandstab)
  db:priv_AddDB("RecipesCarpenter", 551047);   -- Rezeptur - Verbesserter feiner Holzbogen
  db:priv_AddDB("RecipesCarpenter", 551048);   -- Rezeptur - Einfache Holztruhe des Anf?ngersch?lers
  db:priv_AddDB("RecipesCarpenter", 551049);   -- Rezeptur - Einfache Holztruhe des Nachwuchssch?lers
  db:priv_AddDB("RecipesCarpenter", 551050);   -- Rezeptur - Einfache Holztruhe des erfahrenen Sch?lers
  db:priv_AddDB("RecipesCarpenter", 551051);   -- Rezeptur - Einfache Holztruhe des Anf?ngerhandwerkers
  db:priv_AddDB("RecipesCarpenter", 551052);   -- Rezeptur - Einfache Holztruhe des Nachwuchshandwerkers
  db:priv_AddDB("RecipesCarpenter", 551053);   -- Rezeptur - Einfache Holztruhe des erfahrenen Handwerkers
  db:priv_AddDB("RecipesCarpenter", 551054);   -- Rezeptur - Einfache Holztruhe des fachkundigen Handwerkers
  db:priv_AddDB("RecipesCarpenter", 551055);   -- Rezeptur - Einfache Holztruhe des Experten
  db:priv_AddDB("RecipesCarpenter", 551056);   -- Rezeptur - Einfache Holztruhe des erfahrenen Experten
  db:priv_AddDB("RecipesCarpenter", 551057);   -- Rezeptur - Einfache Holztruhe des gebildeten Experten
  db:priv_AddDB("RecipesCarpenter", 551058);   -- Rezeptur - Funktionale Holztruhe des Anf?ngersch?lers
  db:priv_AddDB("RecipesCarpenter", 551059);   -- Rezeptur - Funktionale Holztruhe des Nachwuchssch?lers
  db:priv_AddDB("RecipesCarpenter", 551060);   -- Rezeptur - Funktionale Holztruhe des erfahrenen Sch?lers
  db:priv_AddDB("RecipesCarpenter", 551061);   -- Rezeptur - Funktionale Holztruhe des Anf?ngerhandwerkers
  db:priv_AddDB("RecipesCarpenter", 551062);   -- Rezeptur - Funktionale Holztruhe des Nachwuchshandwerkers
  db:priv_AddDB("RecipesCarpenter", 551063);   -- Rezeptur - Funktionale Holztruhe des erfahrenen Handwerkers
  db:priv_AddDB("RecipesCarpenter", 551064);   -- Rezeptur - Funktionale Holztruhe des fachkundigen Handwerkers
  db:priv_AddDB("RecipesCarpenter", 551065);   -- Rezeptur - Funktionale Holztruhe des Experten
  db:priv_AddDB("RecipesCarpenter", 551066);   -- Rezeptur - Funktionale Holztruhe des erfahrenen Experten
  db:priv_AddDB("RecipesCarpenter", 551067);   -- Rezeptur - Funktionale Holztruhe des gebildeten Experten
  db:priv_AddDB("RecipesCarpenter", 551068);   -- Rezeptur - Exquisite Holztruhe des Anf?ngersch?lers
  db:priv_AddDB("RecipesCarpenter", 551069);   -- Rezeptur - Exquisite Holztruhe des Nachwuchssch?lers
  db:priv_AddDB("RecipesCarpenter", 551070);   -- Rezeptur - Exquisite Holztruhe des erfahrenen Sch?lers
  db:priv_AddDB("RecipesCarpenter", 551071);   -- Rezeptur - Exquisite Holztruhe des Anf?ngerhandwerkers
  db:priv_AddDB("RecipesCarpenter", 551072);   -- Rezeptur - Exquisite Holztruhe des Nachwuchshandwerkers
  db:priv_AddDB("RecipesCarpenter", 551073);   -- Rezeptur - Exquisite Holztruhe des erfahrenen Handwerkers
  db:priv_AddDB("RecipesCarpenter", 551074);   -- Rezeptur - Exquisite Holztruhe des fachkundigen Handwerkers
  db:priv_AddDB("RecipesCarpenter", 551075);   -- Rezeptur - Exquisite Holztruhe des Experten
  db:priv_AddDB("RecipesCarpenter", 551076);   -- Rezeptur - Exquisite Holztruhe des erfahrenen Experten
  db:priv_AddDB("RecipesCarpenter", 551077);   -- Rezeptur - Exquisite Holztruhe des gebildeten Experten

  db:priv_AddDB("RecipesCarpenter", 551188);   -- Rezeptur - 
  db:priv_AddDB("RecipesCarpenter", 551189);   -- Rezeptur - 
  
  db:priv_AddDB("RecipesCarpenter", 551190);   -- Rezeptur - Einfache Holztruhe des fachkundigen Handwerks
  db:priv_AddDB("RecipesCarpenter", 551191);   -- Rezeptur - Schwinge des Drachenk?nigs
  db:priv_AddDB("RecipesCarpenter", 551197);   -- Rezeptur - Schwarze Drachenarmbrust
  db:priv_AddDB("RecipesCarpenter", 551204);   -- Rezeptur - Hanoleders Zweihandstab der Bewunderung
  db:priv_AddDB("RecipesCarpenter", 551208);   -- Rezeptur - Einfache Forscher-Holztruhe
  db:priv_AddDB("RecipesCarpenter", 551209);   -- Rezeptur - Funktionale Forscher-Holztruhe
  db:priv_AddDB("RecipesCarpenter", 551210);   -- Rezeptur - Exquisite Forscher-Holztruhe
  db:priv_AddDB("RecipesCarpenter", 551223);   -- Rezeptur - Funktionale Holztruhe des fachkundigen Handwerks
  db:priv_AddDB("RecipesCarpenter", 551224);   -- Rezeptur - Exquisite Holztruhe des fachkundigen Handwerks
  db:priv_AddDB("RecipesCarpenter", 551231);   -- Rezeptur - Stab des B?sen
  db:priv_AddDB("RecipesCarpenter", 551232);   -- Rezeptur - Flinkschatten-Bogen
  db:priv_AddDB("RecipesCarpenter", 551236);   -- Rezeptur - Flammen-Armbrust
  db:priv_AddDB("RecipesCarpenter", 551237);   -- Rezeptur - Verbesserte Flammen-Armbrust
  db:priv_AddDB("RecipesCarpenter", 551238);   -- Rezeptur - Feuerbrunst-Armbrust
  db:priv_AddDB("RecipesCarpenter", 551242);   -- Rezeptur - Verbesserter Flinkschatten-Bogen
  db:priv_AddDB("RecipesCarpenter", 551248);   -- Rezeptur - Zweihandstab der hei?en Sonne
  db:priv_AddDB("RecipesCarpenter", 551249);   -- Rezeptur - Verbesserter Zweihandstab der hei?en Sonne
  db:priv_AddDB("RecipesCarpenter", 551250);   -- Rezeptur - Zweihandstab der Feurigen
  db:priv_AddDB("RecipesCarpenter", 551259);   -- Rezeptur - Verbesserter Stab des B?sen
  db:priv_AddDB("RecipesCarpenter", 551260);   -- Rezeptur - Stab des Knochend?monen
  db:priv_AddDB("RecipesCarpenter", 551270);   -- Rezeptur - Heilige rechte Hand
  db:priv_AddDB("RecipesCarpenter", 551271);   -- Rezeptur - Linke Hand des D?monenk?nigs
  db:priv_AddDB("RecipesCarpenter", 551275);   -- Rezeptur - Verbesserte g?ttliche rechte Hand
  db:priv_AddDB("RecipesCarpenter", 551331);   -- Rezeptur - Verbliebene Seele des Flammendrachen
  db:priv_AddDB("RecipesCarpenter", 551342);   -- Rezeptur - Einfache Holztruhe des Arkanen Experten
  db:priv_AddDB("RecipesCarpenter", 551343);   -- Rezeptur - Funktionale Holztruhe des Arkanen Experten
  db:priv_AddDB("RecipesCarpenter", 551344);   -- Rezeptur - Exquisite Holztruhe des Arkanen Experten
  db:priv_AddDB("RecipesCarpenter", 551356);   -- Rezeptur - Kurzstab der Flinkheit
  db:priv_AddDB("RecipesCarpenter", 551357);   -- Rezeptur - Langbogen der Flinkheit
  db:priv_AddDB("RecipesCarpenter", 551359);   -- Rezeptur - Harlan-Katapult
  db:priv_AddDB("RecipesCarpenter", 551362);   -- Rezeptur - Zweihandstab des Sonnenuntergangs
  db:priv_AddDB("RecipesCarpenter", 551378);   -- Rezeptur - Gr?nschlangenauge
  db:priv_AddDB("RecipesCarpenter", 551382);   -- Rezeptur - Verbesserter Stab der Flinkheit
  db:priv_AddDB("RecipesCarpenter", 551383);   -- Rezeptur - Verbesserter Langbogen der Flinkheit
  db:priv_AddDB("RecipesCarpenter", 551385);   -- Rezeptur - Verbessertes Harlan-Katapult
  db:priv_AddDB("RecipesCarpenter", 551388);   -- Rezeptur - Verbesserter Zweihandstab des Sonnenuntergangs
  db:priv_AddDB("RecipesCarpenter", 551456);   -- Rezeptur - Hauch des Terrors
  db:priv_AddDB("RecipesCarpenter", 551491);   -- Rezeptur - Zirkusbogen
  db:priv_AddDB("RecipesCarpenter", 551492);   -- Rezeptur - Zweihandstab des Forschers
  db:priv_AddDB("RecipesCarpenter", 551493);   -- Rezeptur - Zirkusarmbrust
  db:priv_AddDB("RecipesCarpenter", 551494);   -- Rezeptur - Stab des Forschers
  db:priv_AddDB("RecipesCarpenter", 551495);   -- Rezeptur - Auge der Transformation
  db:priv_AddDB("RecipesCarpenter", 551517);   -- Rezeptur - Verstärkter Zirkusbogen
  db:priv_AddDB("RecipesCarpenter", 551518);   -- Rezeptur - Verstärkter Zweihandstab des Forschers
  db:priv_AddDB("RecipesCarpenter", 551519);   -- Rezeptur - Verstärkte Zirkusarmbrust
  db:priv_AddDB("RecipesCarpenter", 551520);   -- Rezeptur - Verstärkter Stab des Forschers
  db:priv_AddDB("RecipesCarpenter", 551521);   -- Rezeptur - Verstärktes Auge der Transformation

  db:priv_AddDB("RecipesCarpenter", 551542);   -- Rezeptur - 

  db:priv_AddDB("RecipesCarpenter", 551549);   -- Rezeptur - Seltener Zirkusbogen
  db:priv_AddDB("RecipesCarpenter", 551550);   -- Rezeptur - Seltener Zweihandstab des Forschers
  db:priv_AddDB("RecipesCarpenter", 551551);   -- Rezeptur - Seltene Zirkusarmbrust
  db:priv_AddDB("RecipesCarpenter", 551552);   -- Rezeptur - Seltener Stab des Forschers
  db:priv_AddDB("RecipesCarpenter", 551553);   -- Rezeptur - Seltener Auge der Transformation
  db:priv_AddDB("RecipesCarpenter", 551575);   -- Rezeptur - Schwarzsumpf-Bogen
  db:priv_AddDB("RecipesCarpenter", 551576);   -- Rezeptur - Zweihandstab des Entwicklers
  db:priv_AddDB("RecipesCarpenter", 551577);   -- Rezeptur - Riesige Schwarzsumpf-Armbrust
  db:priv_AddDB("RecipesCarpenter", 551578);   -- Rezeptur - Stab des Entwicklers
  db:priv_AddDB("RecipesCarpenter", 551579);   -- Rezeptur - Auge der Magischen Bestie
  db:priv_AddDB("RecipesCarpenter", 551580);   -- Rezeptur - Einfache Holztruhe des Rätselexperten
  db:priv_AddDB("RecipesCarpenter", 551581);   -- Rezeptur - Funktionale Holztruhe des Rätselexperten
  db:priv_AddDB("RecipesCarpenter", 551582);   -- Rezeptur - Exquisite Holztruhe des Rätselexperten
  db:priv_AddDB("RecipesCarpenter", 551689);   -- Rezeptur - Bailey-Bogen
  db:priv_AddDB("RecipesCarpenter", 551690);   -- Rezeptur - Handwerks-Kristallzweihandstab
  db:priv_AddDB("RecipesCarpenter", 551691);   -- Rezeptur - Gr?ndornmacht
  db:priv_AddDB("RecipesCarpenter", 551692);   -- Rezeptur - Stab des Hellen Tags
  db:priv_AddDB("RecipesCarpenter", 551693);   -- Rezeptur - Gr?ner Federbogen
  db:priv_AddDB("RecipesCarpenter", 551694);   -- Rezeptur - Schwingen-Gebetszweihandstab
  db:priv_AddDB("RecipesCarpenter", 551695);   -- Rezeptur - Kleeblatt-Federbogen
  db:priv_AddDB("RecipesCarpenter", 551696);   -- Rezeptur - Aok-Gebet
  db:priv_AddDB("RecipesCarpenter", 551745);   -- Rezeptur - Vollkommene einfache funktionale Holztruhe
  db:priv_AddDB("RecipesCarpenter", 551746);   -- Rezeptur - Vollkommene funktionale Holztruhe des Experten
  db:priv_AddDB("RecipesCarpenter", 551747);   -- Rezeptur - Vollkommene exquisite Holztruhe des Experten
  db:priv_AddDB("RecipesCarpenter", 551794);   -- Rezeptur - Bogen der Rebellion
  db:priv_AddDB("RecipesCarpenter", 551795);   -- Rezeptur - Zweihandstab der R?ckkehr
  db:priv_AddDB("RecipesCarpenter", 551796);   -- Rezeptur - Finstere Armbrust
  db:priv_AddDB("RecipesCarpenter", 551797);   -- Rezeptur - Finsterer Stab
  db:priv_AddDB("RecipesCarpenter", 551798);   -- Rezeptur - Ahnengeist
  db:priv_AddDB("RecipesCarpenter", 551820);   -- Rezeptur - Verstärkter Bogen der Rebellion
  db:priv_AddDB("RecipesCarpenter", 551821);   -- Rezeptur - Verstärkter Zweihandstab der R?ckkehr
  db:priv_AddDB("RecipesCarpenter", 551822);   -- Rezeptur - Verstärkte finstere Armbrust
  db:priv_AddDB("RecipesCarpenter", 551823);   -- Rezeptur - Verstärkter finsterer Stab
  db:priv_AddDB("RecipesCarpenter", 551824);   -- Rezeptur - Verstärkter Ahnengeist
  db:priv_AddDB("RecipesCarpenter", 551846);   -- Rezeptur - Seltener Bogen der Rebellion
  db:priv_AddDB("RecipesCarpenter", 551847);   -- Rezeptur - Seltener Zweihandstab der R?ckkehr
  db:priv_AddDB("RecipesCarpenter", 551848);   -- Rezeptur - Seltene finstere Armbrust
  db:priv_AddDB("RecipesCarpenter", 551849);   -- Rezeptur - Seltener finsterer Stab
  db:priv_AddDB("RecipesCarpenter", 551850);   -- Rezeptur - Seltener Ahnengeist
  db:priv_AddDB("RecipesCarpenter", 551872);   -- Rezeptur - Bogen der Invasion
  db:priv_AddDB("RecipesCarpenter", 551873);   -- Rezeptur - Zweihandstab der Wanderschaft
  db:priv_AddDB("RecipesCarpenter", 551874);   -- Rezeptur - Armbrust der List
  db:priv_AddDB("RecipesCarpenter", 551875);   -- Rezeptur - Stab der Zerst?rung
  db:priv_AddDB("RecipesCarpenter", 551876);   -- Rezeptur - Zerbrechender Zweihandstab
  db:priv_AddDB("RecipesCarpenter", 551933);   -- Rezeptur - Bogen des Gesandten
  db:priv_AddDB("RecipesCarpenter", 551934);   -- Rezeptur - Zweihandstab des Gesandten
  db:priv_AddDB("RecipesCarpenter", 551935);   -- Rezeptur - Armbrust der Zuflucht
  db:priv_AddDB("RecipesCarpenter", 551937);   -- Rezeptur - Talisman des Gesandten
  db:priv_AddDB("RecipesCarpenter", 551959);   -- Rezeptur - Verbesserter Bogen des Gesandten
  db:priv_AddDB("RecipesCarpenter", 551960);   -- Rezeptur - Verbesserter Zweihandstab des Gesandten
  db:priv_AddDB("RecipesCarpenter", 551961);   -- Rezeptur - Verbesserte Armbrust der Zuflucht
  db:priv_AddDB("RecipesCarpenter", 551962);   -- Rezeptur - Verbesserter Stab der Zuflucht
  db:priv_AddDB("RecipesCarpenter", 551963);   -- Rezeptur - Verbesserter Talisman des Gesandten
  db:priv_AddDB("RecipesCarpenter", 552000);   -- Rezeptur - Seltener Bogen des Gesandten
  db:priv_AddDB("RecipesCarpenter", 552001);   -- Rezeptur - Seltener Zweihandstab des Gesandten
  db:priv_AddDB("RecipesCarpenter", 552002);   -- Rezeptur - Seltene Armbrust der Zuflucht
  db:priv_AddDB("RecipesCarpenter", 552003);   -- Rezeptur - Seltener Stab der Zuflucht
  db:priv_AddDB("RecipesCarpenter", 552004);   -- Rezeptur - Seltener Talisman des Gesandten
  db:priv_AddDB("RecipesCarpenter", 552026);   -- Rezeptur - Bogen des wahren Drachen
  db:priv_AddDB("RecipesCarpenter", 552027);   -- Rezeptur - Zweihandstab der Heimlichkeit
  db:priv_AddDB("RecipesCarpenter", 552028);   -- Rezeptur - Armbrust der Elfe
  db:priv_AddDB("RecipesCarpenter", 552029);   -- Rezeptur - Stab des wahren Drachen
  db:priv_AddDB("RecipesCarpenter", 552030);   -- Rezeptur - Buch der Elfe
  db:priv_AddDB("RecipesCarpenter", 552052);   -- Rezeptur - Große einfache Holztruhe des Novizen
  db:priv_AddDB("RecipesCarpenter", 552053);   -- Rezeptur - Große funktionale Holztruhe des Novizen
  db:priv_AddDB("RecipesCarpenter", 552054);   -- Rezeptur - Große exquisite Holztruhe des Novizen
  db:priv_AddDB("RecipesCarpenter", 552055);   -- Rezeptur - Große einfache Holztruhe des Fortgeschrittenen
  db:priv_AddDB("RecipesCarpenter", 552056);   -- Rezeptur - Große funktionale Holztruhe des Fortgeschrittenen
  db:priv_AddDB("RecipesCarpenter", 552057);   -- Rezeptur - Große exquisite Holztruhe des Fortgeschrittenen
  db:priv_AddDB("RecipesCarpenter", 552058);   -- Rezeptur - Große einfache Holztruhe des Erhabenen
  db:priv_AddDB("RecipesCarpenter", 552059);   -- Rezeptur - Große funktionale Holztruhe des Erhabenen
  db:priv_AddDB("RecipesCarpenter", 552060);   -- Rezeptur - Große exquisite Holztruhe des Erhabenen
  db:priv_AddDB("RecipesCarpenter", 552115);   -- Rezeptur - Geisterbeschw?rungsstein
  db:priv_AddDB("RecipesCarpenter", 552123);   -- Rezeptur - Zweifl?gellangbogen
  db:priv_AddDB("RecipesCarpenter", 552125);   -- Rezeptur - Zweihandstab des Ruhms
  db:priv_AddDB("RecipesCarpenter", 552126);   -- Rezeptur - Glanzvolle Repetierballiste
  db:priv_AddDB("RecipesCarpenter", 552127);   -- Rezeptur - Sternenstab
  db:priv_AddDB("RecipesCarpenter", 552141);   -- Rezeptur - Verbesserter Geisterbeschw?rungsstein
  db:priv_AddDB("RecipesCarpenter", 552149);   -- Rezeptur - Verbesserter Zweifl?gellangbogen
  db:priv_AddDB("RecipesCarpenter", 552151);   -- Rezeptur - Verbesserter Zweihandstab des Ruhms
  db:priv_AddDB("RecipesCarpenter", 552152);   -- Rezeptur - Verbesserte Glanzvolle Repetierballiste
  db:priv_AddDB("RecipesCarpenter", 552153);   -- Rezeptur - Verbesserter Sternenstab
  db:priv_AddDB("RecipesCarpenter", 552167);   -- Rezeptur - Seltener Geisterbeschw?rungsstein
  db:priv_AddDB("RecipesCarpenter", 552175);   -- Rezeptur - Seltener Zweifl?gellangbogen
  db:priv_AddDB("RecipesCarpenter", 552177);   -- Rezeptur - Seltener Zweihandstab des Ruhms
  db:priv_AddDB("RecipesCarpenter", 552178);   -- Rezeptur - Seltene glanzvolle Repetierballiste
  db:priv_AddDB("RecipesCarpenter", 552179);   -- Rezeptur - Seltener Sternenstab
  db:priv_AddDB("RecipesCarpenter", 552183);   -- Rezeptur - Hornbogen
  db:priv_AddDB("RecipesCarpenter", 552185);   -- Rezeptur - Grauer Fl?gelstab
  db:priv_AddDB("RecipesCarpenter", 552186);   -- Rezeptur - Zweihandstab des Leuchtens
  db:priv_AddDB("RecipesCarpenter", 552206);   -- Rezeptur - Verbesserter Hornbogen
  db:priv_AddDB("RecipesCarpenter", 552208);   -- Rezeptur - Verbesserter Grauer Fl?gelstab
  db:priv_AddDB("RecipesCarpenter", 552209);   -- Rezeptur - Verbesserter Zweihandstab des Leuchtens
  db:priv_AddDB("RecipesCarpenter", 552229);   -- Rezeptur - Seltener Hornbogen
  db:priv_AddDB("RecipesCarpenter", 552231);   -- Rezeptur - Seltener Grauer Fl?gelstab
  db:priv_AddDB("RecipesCarpenter", 552232);   -- Rezeptur - Seltener Zweihandstab des Leuchtens
  db:priv_AddDB("RecipesCarpenter", 552252);   -- Rezeptur - Transformierter stummer Heuler
  db:priv_AddDB("RecipesCarpenter", 552254);   -- Rezeptur - Transformierte Eisenblume des Alten K?nigreichs
  db:priv_AddDB("RecipesCarpenter", 552255);   -- Rezeptur - Stachel des Transformierten Hoson
  db:priv_AddDB("RecipesCarpenter", 552290);   -- Rezeptur - Holzkiste des Rätsels
  db:priv_AddDB("RecipesCarpenter", 552424);   -- Rezeptur - Armbrust der blutigen Zunge
  db:priv_AddDB("RecipesCarpenter", 552425);   -- Rezeptur - Stab der tr?gen Schwingen
  db:priv_AddDB("RecipesCarpenter", 552426);   -- Rezeptur - Zweihandstab des heiligen Sonnenaufgangs
  db:priv_AddDB("RecipesCarpenter", 552430);   -- Rezeptur - Verbesserte Armbrust der blutigen Zunge
  db:priv_AddDB("RecipesCarpenter", 552431);   -- Rezeptur - Verbesserter Stab der tr?gen Schwingen
  db:priv_AddDB("RecipesCarpenter", 552432);   -- Rezeptur - Verbesserter Zweihandstab des heiligen Sonnenaufgangs
  db:priv_AddDB("RecipesCarpenter", 552436);   -- Rezeptur - Seltene Armbrust der blutigen Zunge
  db:priv_AddDB("RecipesCarpenter", 552437);   -- Rezeptur - Seltener Stab der tr?gen Schwingen
  db:priv_AddDB("RecipesCarpenter", 552438);   -- Rezeptur - Seltener Zweihandstab des heiligen Sonnenaufgangs
  db:priv_AddDB("RecipesCarpenter", 552442);   -- Rezeptur - Transformierte Armbrust des Schreckens des D?monenkaisers
  db:priv_AddDB("RecipesCarpenter", 552443);   -- Rezeptur - Transformierte zersplitterte Knochen der K?nigin
  db:priv_AddDB("RecipesCarpenter", 552444);   -- Rezeptur - Transformierter Zweihandstab des k?niglichen Erbes
  db:priv_AddDB("RecipesCarpenter", 552462);   -- Rezeptur - Stab des magischen Strudels
  db:priv_AddDB("RecipesCarpenter", 552480);   -- Rezeptur - Verbesserter Stab des magischen Strudels
  db:priv_AddDB("RecipesCarpenter", 552498);   -- Rezeptur - Seltener Stab des magischen Strudels
  db:priv_AddDB("RecipesCarpenter", 552525);   -- Rezeptur - Transformiertes Buch des W?chters
  db:priv_AddDB("RecipesCarpenter", 552527);   -- Rezeptur - Runenholztruhe
  db:priv_AddDB("RecipesCarpenter", 552563);   -- Rezeptur - Langbogen von Arum
  db:priv_AddDB("RecipesCarpenter", 552565);   -- Rezeptur - Zweihandstab des Noktusseewassers
  db:priv_AddDB("RecipesCarpenter", 552566);   -- Rezeptur - Stab des Nantischiffsarztes
  db:priv_AddDB("RecipesCarpenter", 552570);   -- Rezeptur - Verbesserter Langbogen von Arum
  db:priv_AddDB("RecipesCarpenter", 552572);   -- Rezeptur - Verbesserter Zweihandstab des Noktusseewassers
  db:priv_AddDB("RecipesCarpenter", 552573);   -- Rezeptur - Verbesserter Stab des Nantischiffsarztes
  db:priv_AddDB("RecipesCarpenter", 552577);   -- Rezeptur - Seltener Langbogen von Arum
  db:priv_AddDB("RecipesCarpenter", 552579);   -- Rezeptur - Seltener Zweihandstab des Noktusseewassers
  db:priv_AddDB("RecipesCarpenter", 552580);   -- Rezeptur - Seltener Stab des Nantischiffsarztes
  db:priv_AddDB("RecipesCarpenter", 552584);   -- Rezeptur - Transformierter Bogen des Passw?chters
  db:priv_AddDB("RecipesCarpenter", 552586);   -- Rezeptur - Transformierter Zweihandstab der Meeresbestie
  db:priv_AddDB("RecipesCarpenter", 552587);   -- Rezeptur - Transformierte Vernichtung
  db:priv_AddDB("RecipesCarpenter", 552661);   -- Rezeptur - Geheimnisvolle Holztruhe
  db:priv_AddDB("RecipesCarpenter", 552683);   -- Rezeptur - Bogen der Mirakelworte
  db:priv_AddDB("RecipesCarpenter", 552684);   -- Rezeptur - Stab der Steinwarnung
  db:priv_AddDB("RecipesCarpenter", 552685);   -- Rezeptur - Zweihandstab des Ruinengefl?sters
  db:priv_AddDB("RecipesCarpenter", 552689);   -- Rezeptur - Verbesserter Bogen der Mirakelworte
  db:priv_AddDB("RecipesCarpenter", 552690);   -- Rezeptur - Verbesserter Stab der Steinwarnung
  db:priv_AddDB("RecipesCarpenter", 552691);   -- Rezeptur - Verbesserter Zweihandstab des Ruinengefl?sters
  db:priv_AddDB("RecipesCarpenter", 552695);   -- Rezeptur - Seltener Bogen der Mirakelworte
  db:priv_AddDB("RecipesCarpenter", 552696);   -- Rezeptur - Seltener Stab der Steinwarnung
  db:priv_AddDB("RecipesCarpenter", 552697);   -- Rezeptur - Seltener Zweihandstab des Ruinengefl?sters
  db:priv_AddDB("RecipesCarpenter", 552701);   -- Rezeptur - Transformierte schwere Armbrust der Klangleere
  db:priv_AddDB("RecipesCarpenter", 552702);   -- Rezeptur - Transformierter Stab des Genies
  db:priv_AddDB("RecipesCarpenter", 552703);   -- Rezeptur - Transformierter Stab der Aktivierung
  db:priv_AddDB("RecipesCarpenter", 552721);   -- Rezeptur - Heiliges Buch von Kaskada
  db:priv_AddDB("RecipesCarpenter", 552739);   -- Rezeptur - Verbessertes Heiliges Buch von Kaskada
  db:priv_AddDB("RecipesCarpenter", 552757);   -- Rezeptur - Seltenes Heiliges Buch von Kaskada
  db:priv_AddDB("RecipesCarpenter", 552784);   -- Rezeptur - Transformierte Magische Fackel der Energie
  db:priv_AddDB("RecipesCarpenter", 552801);   -- Rezeptur - Geh?rtete Holztruhe
  db:priv_AddDB("RecipesCarpenter", 552805);   -- Rezeptur - Meisterhafte Holztruhe
  db:priv_AddDB("RecipesCarpenter", 552819);   -- Rezeptur - Legend?re Holztruhe
  db:priv_AddDB("RecipesCarpenter", 552823);   -- Rezeptur - Ultimative Holztruhe
  db:priv_AddDB("RecipesCarpenter", 552837);   -- Rezeptur - Himmlische Holztruhe
  db:priv_AddDB("RecipesCarpenter", 552841);   -- Rezeptur - G?ttliche Holztruhe
  db:priv_AddDB("RecipesCarpenter", 552902);   -- Rezeptur - Gemmenkluftbogen
  db:priv_AddDB("RecipesCarpenter", 552904);   -- Rezeptur - Magierstab des Jadekanals
  db:priv_AddDB("RecipesCarpenter", 552905);   -- Rezeptur - Stab der Krypta der Ewigkeit
  db:priv_AddDB("RecipesCarpenter", 552909);   -- Rezeptur - Verbesserter Gemmenkluftbogen
  db:priv_AddDB("RecipesCarpenter", 552911);   -- Rezeptur - Verbesserter Magierstab des Jadekanals
  db:priv_AddDB("RecipesCarpenter", 552912);   -- Rezeptur - Verbesserter Stab der Krypta der Ewigkeit
  db:priv_AddDB("RecipesCarpenter", 552916);   -- Rezeptur - Seltener Gemmenkluftbogen
  db:priv_AddDB("RecipesCarpenter", 552918);   -- Rezeptur - Seltener Magierstab des Jadekanals
  db:priv_AddDB("RecipesCarpenter", 552923);   -- Rezeptur - Transformierter Mechanismusbogen
  db:priv_AddDB("RecipesCarpenter", 552925);   -- Rezeptur - Transformierter Kampfstab
  db:priv_AddDB("RecipesCarpenter", 552926);   -- Rezeptur - Transformiertes Zepter der Genesung
  db:priv_AddDB("RecipesCarpenter", 552944);   -- Rezeptur - Piratenhorn
  db:priv_AddDB("RecipesCarpenter", 552962);   -- Rezeptur - Verbessertes Piratenhorn
  db:priv_AddDB("RecipesCarpenter", 552980);   -- Rezeptur - Seltenes Piratenhorn
  db:priv_AddDB("RecipesCarpenter", 553007);   -- Rezeptur - Transformierte Hexerkralle
  
  db:priv_AddDB("RecipesCarpenter", 553010);   -- Rezeptur - 
  db:priv_AddDB("RecipesCarpenter", 553012);   -- Rezeptur - 
  db:priv_AddDB("RecipesCarpenter", 553013);   -- Rezeptur - 
  
  
  
  
  db:priv_AddDB("RecipesCarpenter", 553017);   -- Rezeptur - Flammenge?tzte Armbrust
  db:priv_AddDB("RecipesCarpenter", 553018);   -- Rezeptur - Einge?scherter Stab
  db:priv_AddDB("RecipesCarpenter", 553019);   -- Rezeptur - Stab des Abwehrfluches
  db:priv_AddDB("RecipesCarpenter", 553023);   -- Rezeptur - Verbesserte flammenge?tzte Armbrust
  db:priv_AddDB("RecipesCarpenter", 553024);   -- Rezeptur - Verbesserter einge?scherter Stab
  db:priv_AddDB("RecipesCarpenter", 553025);   -- Rezeptur - Verbesserter Stab des Abwehrfluches
  db:priv_AddDB("RecipesCarpenter", 553029);   -- Rezeptur - Seltene flammenge?tzte Armbrust
  db:priv_AddDB("RecipesCarpenter", 553030);   -- Rezeptur - Seltener einge?scherter Stab
  db:priv_AddDB("RecipesCarpenter", 553031);   -- Rezeptur - Seltener Stab des Abwehrfluches
  db:priv_AddDB("RecipesCarpenter", 553035);   -- Rezeptur - Transformierte Armbrust des Hinterhalts
  db:priv_AddDB("RecipesCarpenter", 553036);   -- Rezeptur - Transformierter unb?ndiger Stab
  db:priv_AddDB("RecipesCarpenter", 553037);   -- Rezeptur - Transformierter Stab der Wiedergeburt
  db:priv_AddDB("RecipesCarpenter", 553055);   -- Rezeptur - Siegelhorn
  db:priv_AddDB("RecipesCarpenter", 553073);   -- Rezeptur - Verstärktes Siegelhorn
  db:priv_AddDB("RecipesCarpenter", 553091);   -- Rezeptur - Seltenes Siegelhorn
  db:priv_AddDB("RecipesCarpenter", 553118);   -- Rezeptur - Transformierte Kralle des B?sen
  db:priv_AddDB("RecipesCarpenter", 553122);   -- Rezeptur - Spitzdornenbogen vom Kap der Schleiernebel
  db:priv_AddDB("RecipesCarpenter", 553124);   -- Rezeptur - Stab des Missionars
  db:priv_AddDB("RecipesCarpenter", 553125);   -- Rezeptur - Stab vom Nordweidenhof
  db:priv_AddDB("RecipesCarpenter", 553131);   -- Rezeptur - Verbesserter Stab des Missionars
  db:priv_AddDB("RecipesCarpenter", 553132);   -- Rezeptur - Verbesserter Stab vom Nordweidenhof
  db:priv_AddDB("RecipesCarpenter", 553136);   -- Rezeptur - Seltener Spitzdornenbogen vom Kap der Schleiernebel
  db:priv_AddDB("RecipesCarpenter", 553138);   -- Rezeptur - Seltener Stab des Missionars
  db:priv_AddDB("RecipesCarpenter", 553139);   -- Rezeptur - Seltener Stab vom Nordweidenhof
  db:priv_AddDB("RecipesCarpenter", 553143);   -- Rezeptur - Slogars transformierter Bogen
  db:priv_AddDB("RecipesCarpenter", 553145);   -- Rezeptur - Shabdoos transformiertes Ruder
  db:priv_AddDB("RecipesCarpenter", 553146);   -- Rezeptur - Transformierter Korallenfelsstab
  db:priv_AddDB("RecipesCarpenter", 553164);   -- Rezeptur - Magischer Ring des Kreidesumpfes
  db:priv_AddDB("RecipesCarpenter", 553182);   -- Rezeptur - Verbesserter magischer Ring des Kreidesumpfes
  db:priv_AddDB("RecipesCarpenter", 553200);   -- Rezeptur - Seltener magischer Ring des Kreidesumpfes
  db:priv_AddDB("RecipesCarpenter", 553227);   -- Rezeptur - Transformierter Weinbecher des alten Dan
  db:priv_AddDB("RecipesCarpenter", 553232);   -- Rezeptur - Stab von Akson
  db:priv_AddDB("RecipesCarpenter", 553233);   -- Rezeptur - Verlorener Stab
  db:priv_AddDB("RecipesCarpenter", 553237);   -- Rezeptur - Verbesserte Armbrust der Frontlinie
  db:priv_AddDB("RecipesCarpenter", 553238);   -- Rezeptur - Verbesserter Stab von Akson
  db:priv_AddDB("RecipesCarpenter", 553239);   -- Rezeptur - Verbesserter verlorener Stab
  db:priv_AddDB("RecipesCarpenter", 553243);   -- Rezeptur - Seltene Armbrust der Frontlinie
  db:priv_AddDB("RecipesCarpenter", 553244);   -- Rezeptur - Seltener Stab von Akson
  db:priv_AddDB("RecipesCarpenter", 553245);   -- Rezeptur - Seltener verlorener Stab
  db:priv_AddDB("RecipesCarpenter", 553249);   -- Rezeptur - Transformierte Jagdarmbrust des F?rsten der H?me
  db:priv_AddDB("RecipesCarpenter", 553250);   -- Rezeptur - Transformierter Seelenf?ngerstab des Gro?meisters der Toten
  db:priv_AddDB("RecipesCarpenter", 553251);   -- Rezeptur - Transformierter Wiederbelebungsstab des Gro?schamanen
  db:priv_AddDB("RecipesCarpenter", 553269);   -- Rezeptur - Verlorenes D?monenauge
  db:priv_AddDB("RecipesCarpenter", 553287);   -- Rezeptur - Verbessertes verlorenes D?monenauge
  db:priv_AddDB("RecipesCarpenter", 553305);   -- Rezeptur - Seltenes verlorenes D?monenauge
  db:priv_AddDB("RecipesCarpenter", 553332);   -- Rezeptur - Transformierter Sch?del des F?rsten der H?me
  db:priv_AddDB("RecipesCarpenter", 553336);   -- Rezeptur - Langbogen der Sandstrandgrenze
  db:priv_AddDB("RecipesCarpenter", 553338);   -- Rezeptur - Stab des Magieforschers
  db:priv_AddDB("RecipesCarpenter", 553339);   -- Rezeptur - Stab des Raumzeitchaos
  db:priv_AddDB("RecipesCarpenter", 553343);   -- Rezeptur - Verbesserter Langbogen der Sandstrandgrenze
  db:priv_AddDB("RecipesCarpenter", 553345);   -- Rezeptur - Verbesserter Stab des Magieforschers
  db:priv_AddDB("RecipesCarpenter", 553346);   -- Rezeptur - Verbesserter Stab des Raumzeitchaos
  db:priv_AddDB("RecipesCarpenter", 553350);   -- Rezeptur - Seltener Langbogen der Sandstrandgrenze
  db:priv_AddDB("RecipesCarpenter", 553352);   -- Rezeptur - Seltener Stab des Magieforschers
  db:priv_AddDB("RecipesCarpenter", 553353);   -- Rezeptur - Seltener Stab des Raumzeitchaos
  db:priv_AddDB("RecipesCarpenter", 553357);   -- Rezeptur - Mazzrens transformierte Gliedma?e
  db:priv_AddDB("RecipesCarpenter", 553359);   -- Rezeptur - Transformierter Zauberstab des Illusionskristallschubs
  db:priv_AddDB("RecipesCarpenter", 553360);   -- Rezeptur - Marisshas transformierter b?ser Stab
  db:priv_AddDB("RecipesCarpenter", 553378);   -- Rezeptur - Talisman des Schattenlagers
  db:priv_AddDB("RecipesCarpenter", 553396);   -- Rezeptur - Verbesserter Talisman des Schattenlagers
  db:priv_AddDB("RecipesCarpenter", 553414);   -- Rezeptur - Seltener Talisman des Schattenlagers
  db:priv_AddDB("RecipesCarpenter", 553441);   -- Rezeptur - Marisshas transformierter Talisman der dunklen Energie
  db:priv_AddDB("RecipesCarpenter", 553445);   -- Rezeptur - Cibels transformierte Armbrust
  db:priv_AddDB("RecipesCarpenter", 553446);   -- Rezeptur - Transformierter Stab des Nex von Korris
  db:priv_AddDB("RecipesCarpenter", 553447);   -- Rezeptur - Nasqtas' transformierter Wiederbelebungsstab
  db:priv_AddDB("RecipesCarpenter", 553469);   -- Rezeptur - Transformierte Kralle des D?monenauges
  db:priv_AddDB("RecipesCarpenter", 553491);   -- Rezeptur - Transformiertes Auge des Seelenverf?hrers
  db:priv_AddDB("RecipesCarpenter", 553495);   -- Rezeptur - 215082
  db:priv_AddDB("RecipesCarpenter", 553497);   -- Rezeptur - 215084
  db:priv_AddDB("RecipesCarpenter", 553498);   -- Rezeptur - 215085
  
  db:priv_AddDB("RecipesCarpenter", 553520);   -- Rezeptur - 236176

end

local function priv_AddRecipesArmorsmith(db)   -- Rezepte Rüstungsschmied

  db:priv_AddDB("RecipesArmorsmith", 550577);   -- Rezeptur - Beinschützer der wilden Bestie
  db:priv_AddDB("RecipesArmorsmith", 550578);   -- Rezeptur - Verbesserte LederBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550579);   -- Rezeptur - LederBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550580);   -- Rezeptur - Verbesserte Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550581);   -- Rezeptur - Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550582);   -- Rezeptur - Dekorative Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550583);   -- Rezeptur - Verbessertes Barbarenleder
  db:priv_AddDB("RecipesArmorsmith", 550584);   -- Rezeptur - Barbarenleder
  db:priv_AddDB("RecipesArmorsmith", 550585);   -- Rezeptur - BarbarenBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550586);   -- Rezeptur - Verbessertes heroisches Leder
  db:priv_AddDB("RecipesArmorsmith", 550587);   -- Rezeptur - Heroisches Leder
  db:priv_AddDB("RecipesArmorsmith", 550588);   -- Rezeptur - TigerfellBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550589);   -- Rezeptur - Verbesserte Bestien-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550590);   -- Rezeptur - Bestien-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550591);   -- Rezeptur - Fellr?stung
  db:priv_AddDB("RecipesArmorsmith", 550592);   -- Rezeptur - Phyllin-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550593);   -- Rezeptur - Leder der Vitalit?t
  db:priv_AddDB("RecipesArmorsmith", 550594);   -- Rezeptur - Verbessertes Starkleder
  db:priv_AddDB("RecipesArmorsmith", 550595);   -- Rezeptur - Starkleder
  db:priv_AddDB("RecipesArmorsmith", 550596);   -- Rezeptur - Verbesserte gefiederte Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550597);   -- Rezeptur - DaunenBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550598);   -- Rezeptur - Federleichte purpurrote Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550599);   -- Rezeptur - Verbesserte gefiederte Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550600);   -- Rezeptur - Daunenlederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550601);   -- Rezeptur - Junior-Hauptmannshut
  db:priv_AddDB("RecipesArmorsmith", 550602);   -- Rezeptur - Verbesserte Hoek-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550603);   -- Rezeptur - Hoek-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550604);   -- Rezeptur - Lederr?stung der Mondber?hrung
  db:priv_AddDB("RecipesArmorsmith", 550605);   -- Rezeptur - Beinschützer der Mondber?hrung
  db:priv_AddDB("RecipesArmorsmith", 550606);   -- Rezeptur - Lederkappe der Einsamkeit
  db:priv_AddDB("RecipesArmorsmith", 550607);   -- Rezeptur - Verbesserte alte Kappe
  db:priv_AddDB("RecipesArmorsmith", 550608);   -- Rezeptur - Alte Lederkappe
  db:priv_AddDB("RecipesArmorsmith", 550609);   -- Rezeptur - Sturmj?gerBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550610);   -- Rezeptur - Verbesserte Sturmj?gerlederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550611);   -- Rezeptur - Sturmj?gerlederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550613);   -- Rezeptur - Sturmwogen-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550614);   -- Rezeptur - Verbesserte Sturmwogen-Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550615);   -- Rezeptur - Sturmwogen-Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550616);   -- Rezeptur - Windwurfledermaske
  db:priv_AddDB("RecipesArmorsmith", 550617);   -- Rezeptur - Verbesserter staubiger Lederhelm
  db:priv_AddDB("RecipesArmorsmith", 550618);   -- Rezeptur - Staubiger Lederhelm
  db:priv_AddDB("RecipesArmorsmith", 550619);   -- Rezeptur - Starke gefiederte Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550620);   -- Rezeptur - Leichter Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 550621);   -- Rezeptur - Erlesene kupferne Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550622);   -- Rezeptur - Verbesserte derbe kupferne Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550623);   -- Rezeptur - Derbe kupferne Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550624);   -- Rezeptur - Verbesserte derbe kupferne Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550625);   -- Rezeptur - Derbe kupferne Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550626);   -- Rezeptur - RingkettenBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550627);   -- Rezeptur - Verbesserte ordentliche KettenBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550628);   -- Rezeptur - Ordentliche KettenBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550629);   -- Rezeptur - Ordentliche Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550630);   -- Rezeptur - Loyale Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550631);   -- Rezeptur - Sayes gekn?pfte Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550632);   -- Rezeptur - Verbesserte schwere Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550633);   -- Rezeptur - Schwere Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550634);   -- Rezeptur - Verbesserte Silberketten-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550635);   -- Rezeptur - Silberschloss-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550636);   -- Rezeptur - Frostkettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550637);   -- Rezeptur - Verbesserte silberne Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550638);   -- Rezeptur - Silberne Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550639);   -- Rezeptur - Mikrokristall-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550640);   -- Rezeptur - Verbesserte Mikrokristall-Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550641);   -- Rezeptur - Mikrokristall-Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550642);   -- Rezeptur - Beinschützer der Winteressenz
  db:priv_AddDB("RecipesArmorsmith", 550643);   -- Rezeptur - Kettenr?stung der Winteressenz
  db:priv_AddDB("RecipesArmorsmith", 550644);   -- Rezeptur - St?hlerner Reif
  db:priv_AddDB("RecipesArmorsmith", 550645);   -- Rezeptur - Verbesserter geschmiedeter Helm
  db:priv_AddDB("RecipesArmorsmith", 550646);   -- Rezeptur - Geh?rteter Reif
  db:priv_AddDB("RecipesArmorsmith", 550647);   -- Rezeptur - Kahlfeld-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550648);   -- Rezeptur - Verbesserte geriffelte Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550649);   -- Rezeptur - Geriffelte Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550650);   -- Rezeptur - Verbesserte Einklang-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550651);   -- Rezeptur - Beinschützer des Odems der Natur
  db:priv_AddDB("RecipesArmorsmith", 550652);   -- Rezeptur - Panzer des Sturms
  db:priv_AddDB("RecipesArmorsmith", 550653);   -- Rezeptur - Verbesserte Kettenr?stung des nat?rlichen Einklangs
  db:priv_AddDB("RecipesArmorsmith", 550654);   -- Rezeptur - Kettenr?stung des nat?rlichen Einklangs
  db:priv_AddDB("RecipesArmorsmith", 550655);   -- Rezeptur - Sturmbeinpanzer
  db:priv_AddDB("RecipesArmorsmith", 550656);   -- Rezeptur - Dunkler Helm
  db:priv_AddDB("RecipesArmorsmith", 550657);   -- Rezeptur - Verbesserte Beinschützer des Sturms
  db:priv_AddDB("RecipesArmorsmith", 550658);   -- Rezeptur - Verbesserter Helm der Gewalt
  db:priv_AddDB("RecipesArmorsmith", 550659);   -- Rezeptur - Helm des Zorns
  db:priv_AddDB("RecipesArmorsmith", 550660);   -- Rezeptur - Beinschützer des Sturms
  db:priv_AddDB("RecipesArmorsmith", 550661);   -- Rezeptur - W?chterBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550662);   -- Rezeptur - Verbesserte W?chterkettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550664);   -- Rezeptur - Verbesserte Fischschuppen-Beinpanzer
  db:priv_AddDB("RecipesArmorsmith", 550665);   -- Rezeptur - Fischschuppen-Beinpanzer
  db:priv_AddDB("RecipesArmorsmith", 550666);   -- Rezeptur - Verbesserter Schuppenpanzer
  db:priv_AddDB("RecipesArmorsmith", 550667);   -- Rezeptur - Schuppenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550668);   -- Rezeptur - Helm des Murmelns
  db:priv_AddDB("RecipesArmorsmith", 550669);   -- Rezeptur - Verbesserter wei?er Eisenhelm
  db:priv_AddDB("RecipesArmorsmith", 550670);   -- Rezeptur - Wei?er Eisenhelm
  db:priv_AddDB("RecipesArmorsmith", 550671);   -- Rezeptur - Sonnenspeer-Beinpanzer
  db:priv_AddDB("RecipesArmorsmith", 550672);   -- Rezeptur - Sonnenspeer-R?stung
  db:priv_AddDB("RecipesArmorsmith", 550673);   -- Rezeptur - Azraels Helm
  db:priv_AddDB("RecipesArmorsmith", 550674);   -- Rezeptur - Verbesserter Helm des Schreckens
  db:priv_AddDB("RecipesArmorsmith", 550675);   -- Rezeptur - Helm des Schreckens
  db:priv_AddDB("RecipesArmorsmith", 550731);   -- Rezeptur - Dunkler Beinpanzer
  db:priv_AddDB("RecipesArmorsmith", 550732);   -- Rezeptur - Verbesserte Dunkle Beinpanzer
  db:priv_AddDB("RecipesArmorsmith", 550733);   -- Rezeptur - Teufelsbann-Beinpanzer
  db:priv_AddDB("RecipesArmorsmith", 550734);   -- Rezeptur - R?stung der Dunkelheit
  db:priv_AddDB("RecipesArmorsmith", 550735);   -- Rezeptur - Verbesserte dunkle Plattenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550736);   -- Rezeptur - Teufelssiegel-R?stung
  db:priv_AddDB("RecipesArmorsmith", 550737);   -- Rezeptur - Himmlischer Helm
  db:priv_AddDB("RecipesArmorsmith", 550738);   -- Rezeptur - Verbesserter himmlischer Helm
  db:priv_AddDB("RecipesArmorsmith", 550739);   -- Rezeptur - Helm des himmlischen Ansehens
  db:priv_AddDB("RecipesArmorsmith", 550906);   -- Rezeptur - Barbaren-Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550907);   -- Rezeptur - Verbesserte Barbaren-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550908);   -- Rezeptur - BarbarenBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550909);   -- Rezeptur - Gepolsterte Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550910);   -- Rezeptur - Verbesserter Junior-Hauptmannslederhut
  db:priv_AddDB("RecipesArmorsmith", 550911);   -- Rezeptur - Lederner Hauptmannshut
  db:priv_AddDB("RecipesArmorsmith", 550912);   -- Rezeptur - Huloks Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550913);   -- Rezeptur - Verbesserte Lederr?stung der Mondber?hrung
  db:priv_AddDB("RecipesArmorsmith", 550914);   -- Rezeptur - Regenbogen-Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550915);   -- Rezeptur - Wirbelwind-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550916);   -- Rezeptur - Tornado-Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550917);   -- Rezeptur - Donner-SchienBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550918);   -- Rezeptur - Donner-Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550919);   -- Rezeptur - Goni-Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550920);   -- Rezeptur - Verbesserte loyale Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550921);   -- Rezeptur - Tarkba-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550922);   -- Rezeptur - Riesige KettenBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550923);   -- Rezeptur - Verbesserte Mikrokristall-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550924);   -- Rezeptur - Blaue KristallBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550925);   -- Rezeptur - Kristallisierte Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550926);   -- Rezeptur - Verbesserte Kettenr?stung der Winteressenz
  db:priv_AddDB("RecipesArmorsmith", 550927);   -- Rezeptur - Schneekristall-Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550928);   -- Rezeptur - Verbesserte Kahlfeld-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550929);   -- Rezeptur - ?dsumpf-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550930);   -- Rezeptur - Geriffelte Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550931);   -- Rezeptur - Silberne Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550933);   -- Rezeptur - Silberne Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550934);   -- Rezeptur - Br?llende Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550935);   -- Rezeptur - Br?llende Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550936);   -- Rezeptur - Verbesserte WachmannBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550937);   -- Rezeptur - Beinschützer des Aufsehers
  db:priv_AddDB("RecipesArmorsmith", 550938);   -- Rezeptur - Sch?tzende Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550939);   -- Rezeptur - Mehrlagige Fischschuppen-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550940);   -- Rezeptur - Mehrlagige Schuppenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550941);   -- Rezeptur - Dunkelkristall-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550942);   -- Rezeptur - Verbesserte Dunkelkristall-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 550943);   -- Rezeptur - Dunkle SchienBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550944);   -- Rezeptur - Silberne Plattenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550945);   -- Rezeptur - Verbesserte silberne Plattenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550946);   -- Rezeptur - Mondsilber-Plattenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550947);   -- Rezeptur - Verbesserte Sonnenspeer-Beinpanzer
  db:priv_AddDB("RecipesArmorsmith", 550948);   -- Rezeptur - Sonnenlicht-SchienBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 550949);   -- Rezeptur - Verbesserte Sonnenspeer-R?stung
  db:priv_AddDB("RecipesArmorsmith", 550950);   -- Rezeptur - Sonnenlichtpanzer
  db:priv_AddDB("RecipesArmorsmith", 550972);   -- Rezeptur - Yolta-Hut
  db:priv_AddDB("RecipesArmorsmith", 550973);   -- Rezeptur - Yolta-Jagdhut
  db:priv_AddDB("RecipesArmorsmith", 550974);   -- Rezeptur - Yolta-Federhut
  db:priv_AddDB("RecipesArmorsmith", 550975);   -- Rezeptur - Hochim-Soldatenhelm
  db:priv_AddDB("RecipesArmorsmith", 550976);   -- Rezeptur - Hochim-Soldatenkampfhelm
  db:priv_AddDB("RecipesArmorsmith", 550977);   -- Rezeptur - Hochim-Soldatenkriegshelm
  db:priv_AddDB("RecipesArmorsmith", 550981);   -- Rezeptur - Yolta-Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550982);   -- Rezeptur - Yolta-Jagdlederr?stung
  db:priv_AddDB("RecipesArmorsmith", 550984);   -- Rezeptur - Hochim-Soldatenkettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550985);   -- Rezeptur - Hochim-Soldatenkampfkettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 550986);   -- Rezeptur - Hochim-Soldatenkriegsr?stung
  db:priv_AddDB("RecipesArmorsmith", 550990);   -- Rezeptur - Yolta-Überhose
  db:priv_AddDB("RecipesArmorsmith", 550991);   -- Rezeptur - Yolta-FederlederÜberhose
  db:priv_AddDB("RecipesArmorsmith", 550992);   -- Rezeptur - Yolta-FederÜberhose
  db:priv_AddDB("RecipesArmorsmith", 550993);   -- Rezeptur - Hochim-SoldatenÜberhose
  db:priv_AddDB("RecipesArmorsmith", 550994);   -- Rezeptur - Hochim-Soldatenkampf-Überhose
  db:priv_AddDB("RecipesArmorsmith", 550995);   -- Rezeptur - Hochim-SoldatenkriegsÜberhose
  db:priv_AddDB("RecipesArmorsmith", 550999);   -- Rezeptur - Yolta-Langstiefel
  db:priv_AddDB("RecipesArmorsmith", 551000);   -- Rezeptur - Yolta-Jagdlangstiefel
  db:priv_AddDB("RecipesArmorsmith", 551001);   -- Rezeptur - Yolta-Federlangstiefel
  db:priv_AddDB("RecipesArmorsmith", 551002);   -- Rezeptur - Hochim-Soldatenstiefel
  db:priv_AddDB("RecipesArmorsmith", 551003);   -- Rezeptur - Hochim-Soldatenkampfstiefel
  db:priv_AddDB("RecipesArmorsmith", 551004);   -- Rezeptur - Hochim-Soldatenkriegsstiefel
  db:priv_AddDB("RecipesArmorsmith", 551014);   -- Rezeptur - Raltes Purpurzahnbrustschutz
  db:priv_AddDB("RecipesArmorsmith", 551015);   -- Rezeptur - Raltes Purpurzahnstiefel
  db:priv_AddDB("RecipesArmorsmith", 551016);   -- Rezeptur - Raltes PurpurzahnBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 551017);   -- Rezeptur - Raltes Purpurzahnhandschuhe
  db:priv_AddDB("RecipesArmorsmith", 551018);   -- Rezeptur - Raltes Gr?nschuppenkettenhemd
  db:priv_AddDB("RecipesArmorsmith", 551019);   -- Rezeptur - Raltes Gr?nschuppenkettenstiefel
  db:priv_AddDB("RecipesArmorsmith", 551020);   -- Rezeptur - Raltes Gr?nschuppenBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 551021);   -- Rezeptur - Raltes Gr?nschuppenhandsch?tzer
  db:priv_AddDB("RecipesArmorsmith", 551022);   -- Rezeptur - Raltes Drachenschuppenkampfpanzer
  db:priv_AddDB("RecipesArmorsmith", 551023);   -- Rezeptur - Raltes Drachenschuppenstulpenstiefel
  db:priv_AddDB("RecipesArmorsmith", 551024);   -- Rezeptur - Raltes Drachenschuppenbeinpanzer
  db:priv_AddDB("RecipesArmorsmith", 551025);   -- Rezeptur - Raltes Drachenschuppenhandsch?tzer
  db:priv_AddDB("RecipesArmorsmith", 551038);   -- Rezeptur - Verbesserte Windf?nger-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 551138);   -- Rezeptur - Einfache R?stungstruhe des Anf?ngersch?lers
  db:priv_AddDB("RecipesArmorsmith", 551139);   -- Rezeptur - Einfache R?stungstruhe des Nachwuchssch?lers
  db:priv_AddDB("RecipesArmorsmith", 551140);   -- Rezeptur - Einfache R?stungstruhe des erfahrenen Sch?lers
  db:priv_AddDB("RecipesArmorsmith", 551141);   -- Rezeptur - Einfache R?stungstruhe des Anf?ngerhandwerkers
  db:priv_AddDB("RecipesArmorsmith", 551142);   -- Rezeptur - Einfache R?stungstruhe des Nachwuchshandwerkers
  db:priv_AddDB("RecipesArmorsmith", 551143);   -- Rezeptur - Einfache R?stungstruhe des erfahrenen Handwerkers
  db:priv_AddDB("RecipesArmorsmith", 551144);   -- Rezeptur - Einfache R?stungstruhe des fachkundigen Handwerkers
  db:priv_AddDB("RecipesArmorsmith", 551145);   -- Rezeptur - Einfache R?stungstruhe des Experten
  db:priv_AddDB("RecipesArmorsmith", 551146);   -- Rezeptur - Einfache R?stungstruhe des erfahrenen Experten
  db:priv_AddDB("RecipesArmorsmith", 551147);   -- Rezeptur - Einfache R?stungstruhe des gebildeten Experten
  db:priv_AddDB("RecipesArmorsmith", 551148);   -- Rezeptur - Funktionale R?stungstruhe des Anf?ngersch?lers
  db:priv_AddDB("RecipesArmorsmith", 551149);   -- Rezeptur - Funktionale R?stungstruhe des Nachwuchssch?lers
  db:priv_AddDB("RecipesArmorsmith", 551150);   -- Rezeptur - Funktionale R?stungstruhe des erfahrenen Sch?lers
  db:priv_AddDB("RecipesArmorsmith", 551151);   -- Rezeptur - Funktionale R?stungstruhe des Anf?ngerhandwerkers
  db:priv_AddDB("RecipesArmorsmith", 551152);   -- Rezeptur - Funktionale R?stungstruhe des Nachwuchshandwerkers
  db:priv_AddDB("RecipesArmorsmith", 551153);   -- Rezeptur - Funktionale R?stungstruhe des erfahrenen Handwerkers
  db:priv_AddDB("RecipesArmorsmith", 551154);   -- Rezeptur - Funktionale R?stungstruhe des fachkundigen Handwerkers
  db:priv_AddDB("RecipesArmorsmith", 551155);   -- Rezeptur - Funktionale R?stungstruhe des Experten
  db:priv_AddDB("RecipesArmorsmith", 551156);   -- Rezeptur - Funktionale R?stungstruhe des erfahrenen Experten
  db:priv_AddDB("RecipesArmorsmith", 551157);   -- Rezeptur - Funktionale R?stungstruhe des gebildeten Experten
  db:priv_AddDB("RecipesArmorsmith", 551158);   -- Rezeptur - Exquisite R?stungstruhe des Anf?ngersch?lers
  db:priv_AddDB("RecipesArmorsmith", 551159);   -- Rezeptur - Exquisite R?stungstruhe des Nachwuchssch?lers
  db:priv_AddDB("RecipesArmorsmith", 551160);   -- Rezeptur - Exquisite R?stungstruhe des erfahrenen Sch?lers
  db:priv_AddDB("RecipesArmorsmith", 551161);   -- Rezeptur - Exquisite R?stungstruhe des Anf?ngerhandwerkers
  db:priv_AddDB("RecipesArmorsmith", 551162);   -- Rezeptur - Exquisite R?stungstruhe des Nachwuchshandwerkers
  db:priv_AddDB("RecipesArmorsmith", 551163);   -- Rezeptur - Exquisite R?stungstruhe des erfahrenen Handwerkers
  db:priv_AddDB("RecipesArmorsmith", 551164);   -- Rezeptur - Exquisite R?stungstruhe des fachkundigen Handwerkers
  db:priv_AddDB("RecipesArmorsmith", 551165);   -- Rezeptur - Exquisite R?stungstruhe des Experten
  db:priv_AddDB("RecipesArmorsmith", 551166);   -- Rezeptur - Exquisite R?stungstruhe des erfahrenen Experten
  db:priv_AddDB("RecipesArmorsmith", 551167);   -- Rezeptur - Exquisite R?stungstruhe des gebildeten Experten
  db:priv_AddDB("RecipesArmorsmith", 551193);   -- Rezeptur - Lederkappe des einsamen K?nigs
  db:priv_AddDB("RecipesArmorsmith", 551196);   -- Rezeptur - Helm des Siegesgesangs
  db:priv_AddDB("RecipesArmorsmith", 551202);   -- Rezeptur - Kibenstys Stiefel der Loyalit?t
  db:priv_AddDB("RecipesArmorsmith", 551206);   -- Rezeptur - Aguars Befehlskrone
  db:priv_AddDB("RecipesArmorsmith", 551207);   -- Rezeptur - Tadors brillante R?stung
  db:priv_AddDB("RecipesArmorsmith", 551217);   -- Rezeptur - Einfache Forscher-R?stungstruhe
  db:priv_AddDB("RecipesArmorsmith", 551218);   -- Rezeptur - Funktionale Forscher-R?stungstruhe
  db:priv_AddDB("RecipesArmorsmith", 551219);   -- Rezeptur - Exquisite Forscher-R?stungstruhe
  db:priv_AddDB("RecipesArmorsmith", 551220);   -- Rezeptur - Einfache R?stungstruhe des Rätselexperten
  db:priv_AddDB("RecipesArmorsmith", 551221);   -- Rezeptur - Funktionale R?stungstruhe des Rätselexperten
  db:priv_AddDB("RecipesArmorsmith", 551222);   -- Rezeptur - Exquisite R?stungstruhe des Rätselexperten
  db:priv_AddDB("RecipesArmorsmith", 551265);   -- Rezeptur - Fegefeuerhelm
  db:priv_AddDB("RecipesArmorsmith", 551266);   -- Rezeptur - Irdener Helm
  db:priv_AddDB("RecipesArmorsmith", 551267);   -- Rezeptur - Kristallmond-Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 551268);   -- Rezeptur - Kristallmond-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 551269);   -- Rezeptur - Beinschützer des leuchtenden Sterns
  db:priv_AddDB("RecipesArmorsmith", 551274);   -- Rezeptur - Verbesserter Helm des Fegefeuers
  db:priv_AddDB("RecipesArmorsmith", 551278);   -- Rezeptur - Lederr?stung des leuchtenden Sterns
  db:priv_AddDB("RecipesArmorsmith", 551279);   -- Rezeptur - Verbesserte Lederr?stung des leuchtenden Sterns
  db:priv_AddDB("RecipesArmorsmith", 551280);   -- Rezeptur - Gl?nzende Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 551281);   -- Rezeptur - Verbesserte Kristallmond-Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 551282);   -- Rezeptur - Kettenr?stung des leuchtenden Mondes
  db:priv_AddDB("RecipesArmorsmith", 551283);   -- Rezeptur - Wirbelwind-Plattenr?stung
  db:priv_AddDB("RecipesArmorsmith", 551284);   -- Rezeptur - Verbesserte Wirbelwind-Plattenr?stung
  db:priv_AddDB("RecipesArmorsmith", 551285);   -- Rezeptur - Orkan-Plattenr?stung
  db:priv_AddDB("RecipesArmorsmith", 551288);   -- Rezeptur - Verbesserte Beinschützer des leuchtenden Sterns
  db:priv_AddDB("RecipesArmorsmith", 551289);   -- Rezeptur - Gl?nzende Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 551290);   -- Rezeptur - Verbesserte Kristallmond-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 551291);   -- Rezeptur - Beinschützer des leuchtenden Mondes
  db:priv_AddDB("RecipesArmorsmith", 551292);   -- Rezeptur - Wirbelwind-PlattenBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 551293);   -- Rezeptur - Verbesserte Wirbelwind-PlattenBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 551295);   -- Rezeptur - Verbesserter Farbiger Kristallumhang
  db:priv_AddDB("RecipesArmorsmith", 551297);   -- Rezeptur - Lederhelm des leuchtenden Sterns
  db:priv_AddDB("RecipesArmorsmith", 551298);   -- Rezeptur - Verbesserter Lederhelm des leuchtenden Sterns
  db:priv_AddDB("RecipesArmorsmith", 551299);   -- Rezeptur - Gl?nzender Lederhelm
  db:priv_AddDB("RecipesArmorsmith", 551300);   -- Rezeptur - Wirbelwind-Plattenhelm
  db:priv_AddDB("RecipesArmorsmith", 551301);   -- Rezeptur - Verbesserter Wirbelwind-Plattenhelm
  db:priv_AddDB("RecipesArmorsmith", 551302);   -- Rezeptur - Orkan-Plattenhelm
  db:priv_AddDB("RecipesArmorsmith", 551351);   -- Rezeptur - Einfache R?stungstruhe des Arkanen Experten
  db:priv_AddDB("RecipesArmorsmith", 551352);   -- Rezeptur - Funktionale R?stungstruhe des Arkanen Experten
  db:priv_AddDB("RecipesArmorsmith", 551353);   -- Rezeptur - Schöne R?stungstruhe des Arkanen Experten
  db:priv_AddDB("RecipesArmorsmith", 551365);   -- Rezeptur - Helm des Waldritters
  db:priv_AddDB("RecipesArmorsmith", 551366);   -- Rezeptur - Plattenr?stung des Waldritters
  db:priv_AddDB("RecipesArmorsmith", 551367);   -- Rezeptur - Beinschützer des Waldritters
  db:priv_AddDB("RecipesArmorsmith", 551368);   -- Rezeptur - Helm des Waldkriegers
  db:priv_AddDB("RecipesArmorsmith", 551369);   -- Rezeptur - Kettenr?stung des Waldkriegers
  db:priv_AddDB("RecipesArmorsmith", 551370);   -- Rezeptur - Beinschützer des Waldkriegers
  db:priv_AddDB("RecipesArmorsmith", 551371);   -- Rezeptur - Waldhelm der Geschicklichkeit
  db:priv_AddDB("RecipesArmorsmith", 551372);   -- Rezeptur - Waldlederr?stung der Geschicklichkeit
  db:priv_AddDB("RecipesArmorsmith", 551373);   -- Rezeptur - WaldBeinschützer der Geschicklichkeit
  db:priv_AddDB("RecipesArmorsmith", 551391);   -- Rezeptur - Verbesserter Helm des Waldritters
  db:priv_AddDB("RecipesArmorsmith", 551392);   -- Rezeptur - Verbesserte Plattenr?stung des Waldritters
  db:priv_AddDB("RecipesArmorsmith", 551393);   -- Rezeptur - Verbesserte Beinschützer des Waldritters
  db:priv_AddDB("RecipesArmorsmith", 551394);   -- Rezeptur - Verbesserter Helm des Waldkriegers
  db:priv_AddDB("RecipesArmorsmith", 551395);   -- Rezeptur - Verbesserte Kettenr?stung des Waldkriegers
  db:priv_AddDB("RecipesArmorsmith", 551448);   -- Rezeptur - Beinschützer des Bestrafers
  db:priv_AddDB("RecipesArmorsmith", 551449);   -- Rezeptur - Helm des Richters
  db:priv_AddDB("RecipesArmorsmith", 551450);   -- Rezeptur - R?stung des Richters
  db:priv_AddDB("RecipesArmorsmith", 551451);   -- Rezeptur - Beinschützer des Richters
  db:priv_AddDB("RecipesArmorsmith", 551470);   -- Rezeptur - Helm der Burg
  db:priv_AddDB("RecipesArmorsmith", 551471);   -- Rezeptur - Plattenr?stung der Burg
  db:priv_AddDB("RecipesArmorsmith", 551472);   -- Rezeptur - Überhose der Burg
  db:priv_AddDB("RecipesArmorsmith", 551473);   -- Rezeptur - Leichter Helm der Seuche
  db:priv_AddDB("RecipesArmorsmith", 551474);   -- Rezeptur - Leichte R?stung der Seuche
  db:priv_AddDB("RecipesArmorsmith", 551475);   -- Rezeptur - Leichte Überhose der Seuche
  db:priv_AddDB("RecipesArmorsmith", 551476);   -- Rezeptur - Lederkappe des Grabsteins
  db:priv_AddDB("RecipesArmorsmith", 551477);   -- Rezeptur - Lederumhang des Grabsteins
  db:priv_AddDB("RecipesArmorsmith", 551478);   -- Rezeptur - LederÜberhose des Grabsteins
  db:priv_AddDB("RecipesArmorsmith", 551496);   -- Rezeptur - Verstärkter Helm der Burg
  db:priv_AddDB("RecipesArmorsmith", 551497);   -- Rezeptur - Verstärkte Plattenr?stung der Burg
  db:priv_AddDB("RecipesArmorsmith", 551499);   -- Rezeptur - Verstärkter leichter Helm der Seuche
  db:priv_AddDB("RecipesArmorsmith", 551500);   -- Rezeptur - Verstärkte leichte R?stung der Seuche
  db:priv_AddDB("RecipesArmorsmith", 551501);   -- Rezeptur - Verstärkte leichte Überhose der Seuche
  db:priv_AddDB("RecipesArmorsmith", 551502);   -- Rezeptur - Verstärkte Lederkappe des Grabsteins
  db:priv_AddDB("RecipesArmorsmith", 551503);   -- Rezeptur - Verstärkter Ledermantel des Grabsteins
  db:priv_AddDB("RecipesArmorsmith", 551504);   -- Rezeptur - Verstärkte LederÜberhose des Grabsteins
  db:priv_AddDB("RecipesArmorsmith", 551522);   -- Rezeptur - Seltener Helm der Burg
  db:priv_AddDB("RecipesArmorsmith", 551523);   -- Rezeptur - Seltene Plattenr?stung der Burg
  db:priv_AddDB("RecipesArmorsmith", 551524);   -- Rezeptur - Seltene Überhose der Burg
  db:priv_AddDB("RecipesArmorsmith", 551525);   -- Rezeptur - Seltener leichter Helm der Seuche
  db:priv_AddDB("RecipesArmorsmith", 551526);   -- Rezeptur - Seltene leichte R?stung der Seuche
  db:priv_AddDB("RecipesArmorsmith", 551527);   -- Rezeptur - Seltene leichte Überhose der Seuche
  db:priv_AddDB("RecipesArmorsmith", 551528);   -- Rezeptur - Seltene Lederkappe des Grabsteins
  db:priv_AddDB("RecipesArmorsmith", 551529);   -- Rezeptur - Seltener Ledermantel des Grabsteins
  db:priv_AddDB("RecipesArmorsmith", 551530);   -- Rezeptur - Seltene LederÜberhose des Grabsteins
  db:priv_AddDB("RecipesArmorsmith", 551543);   -- Rezeptur - 
  db:priv_AddDB("RecipesArmorsmith", 551544);   -- Rezeptur - 
  db:priv_AddDB("RecipesArmorsmith", 551545);   -- Rezeptur - 
  db:priv_AddDB("RecipesArmorsmith", 551546);   -- Rezeptur -  
  db:priv_AddDB("RecipesArmorsmith", 551547);   -- Rezeptur -  
  db:priv_AddDB("RecipesArmorsmith", 551554);   -- Rezeptur - Helm der verlassenen Festung
  db:priv_AddDB("RecipesArmorsmith", 551556);   -- Rezeptur - Überhose der verlassenen Festung
  db:priv_AddDB("RecipesArmorsmith", 551557);   -- Rezeptur - Leichter Helm der giftigen Seuche
  db:priv_AddDB("RecipesArmorsmith", 551558);   -- Rezeptur - Leichte R?stung der giftigen Seuche
  db:priv_AddDB("RecipesArmorsmith", 551559);   -- Rezeptur - Leichte Überhose der giftigen Seuche
  db:priv_AddDB("RecipesArmorsmith", 551560);   -- Rezeptur - Lederkappe der mysteri?sen Tafel
  db:priv_AddDB("RecipesArmorsmith", 551561);   -- Rezeptur - Ledermantel der mysteri?sen Tafel
  db:priv_AddDB("RecipesArmorsmith", 551562);   -- Rezeptur - LederÜberhose der mysteri?sen Tafel

  db:priv_AddDB("RecipesArmorsmith", 551583);   -- Rezeptur -  
  db:priv_AddDB("RecipesArmorsmith", 551584);   -- Rezeptur -  
  db:priv_AddDB("RecipesArmorsmith", 551585);   -- Rezeptur -  
  db:priv_AddDB("RecipesArmorsmith", 551586);   -- Rezeptur -  
  db:priv_AddDB("RecipesArmorsmith", 551587);   -- Rezeptur -  
  db:priv_AddDB("RecipesArmorsmith", 551588);   -- Rezeptur -   
  db:priv_AddDB("RecipesArmorsmith", 551589);   -- Rezeptur -  

  db:priv_AddDB("RecipesArmorsmith", 551650);   -- Rezeptur - Leichte Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 551651);   -- Rezeptur - Magische Kettenr?stung
  db:priv_AddDB("RecipesArmorsmith", 551705);   -- Rezeptur - Blaugr?nes Herz
  db:priv_AddDB("RecipesArmorsmith", 551706);   -- Rezeptur - Leichte gravierte R?stung
  db:priv_AddDB("RecipesArmorsmith", 551707);   -- Rezeptur - Gr?ne Botenkleidung
  db:priv_AddDB("RecipesArmorsmith", 551708);   -- Rezeptur - Gr?ner Jadeschutz
  db:priv_AddDB("RecipesArmorsmith", 551709);   -- Rezeptur - Gr?nschwingenschutz
  db:priv_AddDB("RecipesArmorsmith", 551710);   -- Rezeptur - Handwerker-Nietenr?stung
  db:priv_AddDB("RecipesArmorsmith", 551711);   -- Rezeptur - Purpurbrustpanzer
  db:priv_AddDB("RecipesArmorsmith", 551712);   -- Rezeptur - Enganliegende Duellr?stung
  db:priv_AddDB("RecipesArmorsmith", 551713);   -- Rezeptur - Schurkenset des Gr?nen Waldes
  db:priv_AddDB("RecipesArmorsmith", 551714);   -- Rezeptur - Stahlseelen-Handwerksausr?stung
  db:priv_AddDB("RecipesArmorsmith", 551715);   -- Rezeptur - R?stung der Kaiserlichen Wache
  db:priv_AddDB("RecipesArmorsmith", 551716);   -- Rezeptur - K?nigliche dekorative R?stung
  db:priv_AddDB("RecipesArmorsmith", 551754);   -- Rezeptur - Vollkommene einfache R?stungstruhe des Experten
  db:priv_AddDB("RecipesArmorsmith", 551755);   -- Rezeptur - Vollkommene funktionale R?stungstruhe des Experten
  db:priv_AddDB("RecipesArmorsmith", 551756);   -- Rezeptur - Vollkommene exquisite R?stungstruhe des Experten
  db:priv_AddDB("RecipesArmorsmith", 551772);   -- Rezeptur - Einfache R?stungstruhe des fachkundigen Handwerks
  db:priv_AddDB("RecipesArmorsmith", 551773);   -- Rezeptur - Helm der H?gel
  db:priv_AddDB("RecipesArmorsmith", 551774);   -- Rezeptur - Plattenr?stung der H?gel
  db:priv_AddDB("RecipesArmorsmith", 551775);   -- Rezeptur - Beinschützer der H?gel
  db:priv_AddDB("RecipesArmorsmith", 551776);   -- Rezeptur - Helm der Kalon
  db:priv_AddDB("RecipesArmorsmith", 551777);   -- Rezeptur - Kampfr?stung der Kalon
  db:priv_AddDB("RecipesArmorsmith", 551778);   -- Rezeptur - Überhose der Kalon
  db:priv_AddDB("RecipesArmorsmith", 551779);   -- Rezeptur - Bergbauhut
  db:priv_AddDB("RecipesArmorsmith", 551780);   -- Rezeptur - Bergbaumantel
  db:priv_AddDB("RecipesArmorsmith", 551782);   -- Rezeptur - Höhlenkopfbedeckung
  db:priv_AddDB("RecipesArmorsmith", 551799);   -- Rezeptur - Verstärkter Helm der H?gel
  db:priv_AddDB("RecipesArmorsmith", 551800);   -- Rezeptur - Verstärkte Plattenr?stung der H?gel
  db:priv_AddDB("RecipesArmorsmith", 551801);   -- Rezeptur - Verstärkte Beinschützer der H?gel
  db:priv_AddDB("RecipesArmorsmith", 551802);   -- Rezeptur - Verstärkter Helm der Kalon
  db:priv_AddDB("RecipesArmorsmith", 551803);   -- Rezeptur - Verstärkte Kampfr?stung der Kalon
  db:priv_AddDB("RecipesArmorsmith", 551804);   -- Rezeptur - Verstärkte Überhose der Kalon
  db:priv_AddDB("RecipesArmorsmith", 551805);   -- Rezeptur - Verstärkter Bergbauhut
  db:priv_AddDB("RecipesArmorsmith", 551806);   -- Rezeptur - Verstärkter Bergbaumantel
  db:priv_AddDB("RecipesArmorsmith", 551807);   -- Rezeptur - Verstärkte BergbauÜberhose
  db:priv_AddDB("RecipesArmorsmith", 551825);   -- Rezeptur - Seltener Helm der H?gel
  db:priv_AddDB("RecipesArmorsmith", 551826);   -- Rezeptur - Seltene Plattenr?stung der H?gel
  db:priv_AddDB("RecipesArmorsmith", 551827);   -- Rezeptur - Seltene Beinschützer der H?gel
  db:priv_AddDB("RecipesArmorsmith", 551828);   -- Rezeptur - Seltener Helm der Kalon
  db:priv_AddDB("RecipesArmorsmith", 551829);   -- Rezeptur - Seltene Kampfr?stung der Kalon
  db:priv_AddDB("RecipesArmorsmith", 551830);   -- Rezeptur - Seltene Überhose der Kalon
  db:priv_AddDB("RecipesArmorsmith", 551831);   -- Rezeptur - Seltener Bergbauhut
  db:priv_AddDB("RecipesArmorsmith", 551833);   -- Rezeptur - Seltene BergbauÜberhose
  db:priv_AddDB("RecipesArmorsmith", 551851);   -- Rezeptur - Kriegshelm
  db:priv_AddDB("RecipesArmorsmith", 551852);   -- Rezeptur - Kriegsr?stung
  db:priv_AddDB("RecipesArmorsmith", 551853);   -- Rezeptur - KriegsBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 551854);   -- Rezeptur - Helm des Widerstands
  db:priv_AddDB("RecipesArmorsmith", 551855);   -- Rezeptur - Kettenr?stung des Widerstands
  db:priv_AddDB("RecipesArmorsmith", 551856);   -- Rezeptur - Überhose des Widerstands
  db:priv_AddDB("RecipesArmorsmith", 551857);   -- Rezeptur - Mangelhafter Lederhut
  db:priv_AddDB("RecipesArmorsmith", 551858);   -- Rezeptur - Mangelhafte Lederr?stung
  db:priv_AddDB("RecipesArmorsmith", 551859);   -- Rezeptur - Mangelhafte LederÜberhose
  db:priv_AddDB("RecipesArmorsmith", 551878);   -- Rezeptur -   
  db:priv_AddDB("RecipesArmorsmith", 551880);   -- Rezeptur - Funktionale R?stungstruhe des fachkundigen Handwerks
  db:priv_AddDB("RecipesArmorsmith", 551881);   -- Rezeptur - Exquisite R?stungstruhe des fachkundigen Handwerks
  db:priv_AddDB("RecipesArmorsmith", 551912);   -- Rezeptur - Plattenhelm des Schicksals
  db:priv_AddDB("RecipesArmorsmith", 551913);   -- Rezeptur - Plattenr?stung des Schicksals
  db:priv_AddDB("RecipesArmorsmith", 551914);   -- Rezeptur - Beinschützer des Schicksals
  db:priv_AddDB("RecipesArmorsmith", 551915);   -- Rezeptur - Helm der Versorgung
  db:priv_AddDB("RecipesArmorsmith", 551916);   -- Rezeptur - Kettenr?stung der Versorgung
  db:priv_AddDB("RecipesArmorsmith", 551917);   -- Rezeptur - Hose der Versorgung
  db:priv_AddDB("RecipesArmorsmith", 551918);   -- Rezeptur - Lederkappe des Gesandten
  db:priv_AddDB("RecipesArmorsmith", 551919);   -- Rezeptur - Ledermantel des Gesandten
  db:priv_AddDB("RecipesArmorsmith", 551920);   -- Rezeptur - Lederhose des Gesandten
  db:priv_AddDB("RecipesArmorsmith", 551938);   -- Rezeptur - Verbesserter Plattenhelm des Schicksals
  db:priv_AddDB("RecipesArmorsmith", 551939);   -- Rezeptur - Verbesserte Plattenr?stung des Schicksals
  db:priv_AddDB("RecipesArmorsmith", 551940);   -- Rezeptur - Verbesserter Beinschützer des Schicksals
  db:priv_AddDB("RecipesArmorsmith", 551941);   -- Rezeptur - Verbesserter Helm der Versorgung
  db:priv_AddDB("RecipesArmorsmith", 551942);   -- Rezeptur - Verbesserter Kettenpanzer der Versorgung
  db:priv_AddDB("RecipesArmorsmith", 551943);   -- Rezeptur - Verbesserte Hose der Versorgung
  db:priv_AddDB("RecipesArmorsmith", 551944);   -- Rezeptur - Verbesserte Lederkappe des Gesandten
  db:priv_AddDB("RecipesArmorsmith", 551945);   -- Rezeptur - Verbesserter Ledermantel des Gesandten
  db:priv_AddDB("RecipesArmorsmith", 551946);   -- Rezeptur - Verbesserte Lederhose des Gesandten
  db:priv_AddDB("RecipesArmorsmith", 551979);   -- Rezeptur - Seltener Plattenhelm des Schicksals
  db:priv_AddDB("RecipesArmorsmith", 551980);   -- Rezeptur - Seltene Plattenr?stung des Schicksals
  db:priv_AddDB("RecipesArmorsmith", 551981);   -- Rezeptur - Seltener Beinschützer des Schicksals
  db:priv_AddDB("RecipesArmorsmith", 551982);   -- Rezeptur - Seltener Helm der Versorgung
  db:priv_AddDB("RecipesArmorsmith", 551983);   -- Rezeptur - Seltene Kettenr?stung der Versorgung
  db:priv_AddDB("RecipesArmorsmith", 551984);   -- Rezeptur - Seltene Hose der Versorgung
  db:priv_AddDB("RecipesArmorsmith", 551985);   -- Rezeptur - Seltene Lederkappe des Gesandten
  db:priv_AddDB("RecipesArmorsmith", 551986);   -- Rezeptur - Seltener Ledermantel des Gesandten
  db:priv_AddDB("RecipesArmorsmith", 551987);   -- Rezeptur - Seltene Lederhose des Gesandten
  db:priv_AddDB("RecipesArmorsmith", 552005);   -- Rezeptur - Plattenhelm des wahren Drachen
  db:priv_AddDB("RecipesArmorsmith", 552006);   -- Rezeptur - Plattenr?stung des wahren Drachen
  db:priv_AddDB("RecipesArmorsmith", 552007);   -- Rezeptur - Beinschützer des wahren Drachen
  db:priv_AddDB("RecipesArmorsmith", 552008);   -- Rezeptur - Helm der Elfe
  db:priv_AddDB("RecipesArmorsmith", 552009);   -- Rezeptur - Kettenr?stung der Elfe
  db:priv_AddDB("RecipesArmorsmith", 552010);   -- Rezeptur - Hose der Elfe
  db:priv_AddDB("RecipesArmorsmith", 552011);   -- Rezeptur - Lederkappe der Heimlichkeit
  db:priv_AddDB("RecipesArmorsmith", 552012);   -- Rezeptur - Lederr?stung der Heimlichkeit
  db:priv_AddDB("RecipesArmorsmith", 552013);   -- Rezeptur - Lederhose der Heimlichkeit
  db:priv_AddDB("RecipesArmorsmith", 552070);   -- Rezeptur - Große einfache R?stungstruhe des Novizen
  db:priv_AddDB("RecipesArmorsmith", 552071);   -- Rezeptur - Große funktionale R?stungstruhe des Novizen
  db:priv_AddDB("RecipesArmorsmith", 552072);   -- Rezeptur - Große exquisite R?stungstruhe des Novizen
  db:priv_AddDB("RecipesArmorsmith", 552073);   -- Rezeptur - Große einfache R?stungstruhe des Fortgeschrittenen
  db:priv_AddDB("RecipesArmorsmith", 552074);   -- Rezeptur - Große funktionale R?stungstruhe des Fortgeschrittenen
  db:priv_AddDB("RecipesArmorsmith", 552075);   -- Rezeptur - Große exquisite R?stungstruhe des Fortgeschrittenen
  db:priv_AddDB("RecipesArmorsmith", 552076);   -- Rezeptur - Große einfache R?stungstruhe des Erhabenen
  db:priv_AddDB("RecipesArmorsmith", 552077);   -- Rezeptur - Große funktionale R?stungstruhe des Erhabenen
  db:priv_AddDB("RecipesArmorsmith", 552078);   -- Rezeptur - Große exquisite R?stungstruhe des Erhabenen
  db:priv_AddDB("RecipesArmorsmith", 552102);   -- Rezeptur - Frosthelm
  db:priv_AddDB("RecipesArmorsmith", 552103);   -- Rezeptur - Frostplattenr?stung
  db:priv_AddDB("RecipesArmorsmith", 552104);   -- Rezeptur - FrostBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 552105);   -- Rezeptur - Nachthelm
  db:priv_AddDB("RecipesArmorsmith", 552106);   -- Rezeptur - Leichte Nachtr?stung
  db:priv_AddDB("RecipesArmorsmith", 552107);   -- Rezeptur - Beinpanzer der Nacht
  db:priv_AddDB("RecipesArmorsmith", 552108);   -- Rezeptur - Fl?stermaske
  db:priv_AddDB("RecipesArmorsmith", 552109);   -- Rezeptur - Fl?sterlederr?stung
  db:priv_AddDB("RecipesArmorsmith", 552110);   -- Rezeptur - Fl?sterBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 552128);   -- Rezeptur - Verbesserter Frosthelm
  db:priv_AddDB("RecipesArmorsmith", 552129);   -- Rezeptur - Verbesserte Frostplattenr?stung
  db:priv_AddDB("RecipesArmorsmith", 552130);   -- Rezeptur - Verbesserte FrostBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 552131);   -- Rezeptur - Verbesserter Nachthelm
  db:priv_AddDB("RecipesArmorsmith", 552132);   -- Rezeptur - Verbesserte leichte Nachtr?stung
  db:priv_AddDB("RecipesArmorsmith", 552133);   -- Rezeptur - Verbesserte Beinpanzer der Nacht
  db:priv_AddDB("RecipesArmorsmith", 552134);   -- Rezeptur - Verbesserte Fl?stermaske
  db:priv_AddDB("RecipesArmorsmith", 552135);   -- Rezeptur - Verbesserte Fl?sterlederr?stung
  db:priv_AddDB("RecipesArmorsmith", 552136);   -- Rezeptur - Verbesserte Fl?sterBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 552154);   -- Rezeptur - Seltener Frosthelm
  db:priv_AddDB("RecipesArmorsmith", 552155);   -- Rezeptur - Seltene Frostplattenr?stung
  db:priv_AddDB("RecipesArmorsmith", 552156);   -- Rezeptur - Seltene FrostBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 552157);   -- Rezeptur - Seltener Nachthelm
  db:priv_AddDB("RecipesArmorsmith", 552158);   -- Rezeptur - Seltene leichte Nachtr?stung
  db:priv_AddDB("RecipesArmorsmith", 552159);   -- Rezeptur - Seltene Beinpanzer der Nacht
  db:priv_AddDB("RecipesArmorsmith", 552160);   -- Rezeptur - Seltene Fl?stermaske
  db:priv_AddDB("RecipesArmorsmith", 552161);   -- Rezeptur - Seltene Fl?sterlederr?stung
  db:priv_AddDB("RecipesArmorsmith", 552162);   -- Rezeptur - Seltene Fl?sterBeinschützer
  db:priv_AddDB("RecipesArmorsmith", 552187);   -- Rezeptur - Goldene Plattenhandschuhe
  db:priv_AddDB("RecipesArmorsmith", 552188);   -- Rezeptur - Goldene Plattenhose
  db:priv_AddDB("RecipesArmorsmith", 552189);   -- Rezeptur - Goldener PlattenGürtel
  db:priv_AddDB("RecipesArmorsmith", 552191);   -- Rezeptur - Purpurrote Dornenhandschuhe
  db:priv_AddDB("RecipesArmorsmith", 552192);   -- Rezeptur - Purpurrote Dornenhose
  db:priv_AddDB("RecipesArmorsmith", 552194);   -- Rezeptur - Purpurroter Dornenumhang
  db:priv_AddDB("RecipesArmorsmith", 552195);   -- Rezeptur - Dschungelhandschuhe der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552196);   -- Rezeptur - Dschungelhose der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552197);   -- Rezeptur - DschungelGürtel der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552210);   -- Rezeptur - Verbesserte Goldene Plattenhandschuhe
  db:priv_AddDB("RecipesArmorsmith", 552211);   -- Rezeptur - Verbesserte Goldene Plattenhose
  db:priv_AddDB("RecipesArmorsmith", 552212);   -- Rezeptur - Verbesserter Goldener PlattenGürtel
  db:priv_AddDB("RecipesArmorsmith", 552214);   -- Rezeptur - Verbesserte Purpurrote Dornenhandschuhe
  db:priv_AddDB("RecipesArmorsmith", 552215);   -- Rezeptur - Verbesserte Purpurrote Dornenhose
  db:priv_AddDB("RecipesArmorsmith", 552216);   -- Rezeptur - Verbesserter Purpurroter DornenGürtel
  db:priv_AddDB("RecipesArmorsmith", 552218);   -- Rezeptur - Verbesserte Dschungelhandschuhe der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552219);   -- Rezeptur - Verbesserte Dschungelhose der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552220);   -- Rezeptur - Verbesserter DschungelGürtel der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552233);   -- Rezeptur - Seltene Goldene Plattenhandschuhe
  db:priv_AddDB("RecipesArmorsmith", 552234);   -- Rezeptur - Seltene Goldene Plattenhose
  db:priv_AddDB("RecipesArmorsmith", 552235);   -- Rezeptur - Seltener Goldener PlattenGürtel
  db:priv_AddDB("RecipesArmorsmith", 552237);   -- Rezeptur - Seltene Purpurrote Dornenhandschuhe
  db:priv_AddDB("RecipesArmorsmith", 552238);   -- Rezeptur - Seltene Purpurrote Dornenhose
  db:priv_AddDB("RecipesArmorsmith", 552239);   -- Rezeptur - Seltener Purpurroter DornenGürtel
  db:priv_AddDB("RecipesArmorsmith", 552241);   -- Rezeptur - Seltene Dschungelhandschuhe der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552242);   -- Rezeptur - Seltene Dschungelhose der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552243);   -- Rezeptur - Seltener DschungelGürtel der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552256);   -- Rezeptur - Transformierte Eisenlicht-Panzerhandschuhe
  db:priv_AddDB("RecipesArmorsmith", 552257);   -- Rezeptur - Transformierte Eisenlicht-Hose
  db:priv_AddDB("RecipesArmorsmith", 552258);   -- Rezeptur - Transformierter Eisenlicht-Gürtel
  db:priv_AddDB("RecipesArmorsmith", 552260);   -- Rezeptur - Handschuhe der Transformierten Geisterbestie
  db:priv_AddDB("RecipesArmorsmith", 552261);   -- Rezeptur - Hose der Transformierten Geisterbestie
  db:priv_AddDB("RecipesArmorsmith", 552262);   -- Rezeptur - Gürtel der Transformierten Geisterbestie
  db:priv_AddDB("RecipesArmorsmith", 552264);   -- Rezeptur - Handschuhe der Transformierten Giftigkeit
  db:priv_AddDB("RecipesArmorsmith", 552265);   -- Rezeptur - Hose der Transformierten Giftigkeit
  db:priv_AddDB("RecipesArmorsmith", 552266);   -- Rezeptur - Gürtel der Transformierten Giftigkeit
  db:priv_AddDB("RecipesArmorsmith", 552268);   -- Rezeptur - Handschuhe des Transformierten Lindwurms
  db:priv_AddDB("RecipesArmorsmith", 552269);   -- Rezeptur - Hose des Transformierten Lindwurms
  db:priv_AddDB("RecipesArmorsmith", 552270);   -- Rezeptur - Gürtel des Transformierten Lindwurms
  db:priv_AddDB("RecipesArmorsmith", 552272);   -- Rezeptur - Handschuhe des Transformierten Heulers
  db:priv_AddDB("RecipesArmorsmith", 552273);   -- Rezeptur - Hose des Transformierten Heulers
  db:priv_AddDB("RecipesArmorsmith", 552274);   -- Rezeptur - Gürtel des Transformierten Heulers
  db:priv_AddDB("RecipesArmorsmith", 552291);   -- Rezeptur - R?stungstruhe des Rätsels
  db:priv_AddDB("RecipesArmorsmith", 552445);   -- Rezeptur - Goldener Plattenhelm
  db:priv_AddDB("RecipesArmorsmith", 552446);   -- Rezeptur - Goldene Plattenstiefel
  db:priv_AddDB("RecipesArmorsmith", 552447);   -- Rezeptur - Goldenes Plattenbrustst?ck
  db:priv_AddDB("RecipesArmorsmith", 552448);   -- Rezeptur - Goldenes Plattenschultersch?tzer
  db:priv_AddDB("RecipesArmorsmith", 552450);   -- Rezeptur - Purpurrote Dornenstiefel
  db:priv_AddDB("RecipesArmorsmith", 552451);   -- Rezeptur - Purpurrotes Dornenbrustst?ck
  db:priv_AddDB("RecipesArmorsmith", 552452);   -- Rezeptur - Purpurrote Dornenschultersch?tzer
  db:priv_AddDB("RecipesArmorsmith", 552453);   -- Rezeptur - Dschungelstirnband der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552454);   -- Rezeptur - Dschungelstiefel der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552455);   -- Rezeptur - Dschungelmantel der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552456);   -- Rezeptur - Dschungelschultersch?tzer der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552463);   -- Rezeptur - Verbesserter goldener Plattenhelm
  db:priv_AddDB("RecipesArmorsmith", 552464);   -- Rezeptur - Verbesserte goldene Plattenstiefel
  db:priv_AddDB("RecipesArmorsmith", 552465);   -- Rezeptur - Verbessertes goldenes Plattenbrustst?ck
  db:priv_AddDB("RecipesArmorsmith", 552466);   -- Rezeptur - Verbesserte goldene Plattenschultersch?tzer
  db:priv_AddDB("RecipesArmorsmith", 552467);   -- Rezeptur - Verbesserter purpurroter Dornenhelm
  db:priv_AddDB("RecipesArmorsmith", 552468);   -- Rezeptur - Verbesserte purpurrote Dornenstiefel
  db:priv_AddDB("RecipesArmorsmith", 552469);   -- Rezeptur - Verbessertes purpurrotes Dornenbrustst?ck
  db:priv_AddDB("RecipesArmorsmith", 552470);   -- Rezeptur - Verbesserte purpurrote Dornenschultersch?tzer
  db:priv_AddDB("RecipesArmorsmith", 552471);   -- Rezeptur - Verbessertes Dschungelstirnband der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552472);   -- Rezeptur - Verbesserte Dschungelstiefel der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552473);   -- Rezeptur - Verbesserter Dschungelmantel der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552474);   -- Rezeptur - Verbesserte Dschungelschultersch?tzer der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552481);   -- Rezeptur - Seltener goldener Plattenhelm
  db:priv_AddDB("RecipesArmorsmith", 552482);   -- Rezeptur - Seltene goldene Plattenstiefel
  db:priv_AddDB("RecipesArmorsmith", 552483);   -- Rezeptur - Seltenes goldenes Plattenbrustst?ck
  db:priv_AddDB("RecipesArmorsmith", 552484);   -- Rezeptur - Seltene goldene Plattenschultersch?tzer
  db:priv_AddDB("RecipesArmorsmith", 552485);   -- Rezeptur - Seltener purpurroter Dornenhelm
  db:priv_AddDB("RecipesArmorsmith", 552486);   -- Rezeptur - Seltene purpurrote Dornenstiefel
  db:priv_AddDB("RecipesArmorsmith", 552487);   -- Rezeptur - Seltenes purpurroter Dornenbrustst?ck
  db:priv_AddDB("RecipesArmorsmith", 552488);   -- Rezeptur - Seltene purpurrote Dornenschultersch?tzer
  db:priv_AddDB("RecipesArmorsmith", 552489);   -- Rezeptur - Seltenes Dschungelstirnband der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552490);   -- Rezeptur - Seltene Dschungelstiefel der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552491);   -- Rezeptur - Seltener Dschungelmantel der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552492);   -- Rezeptur - Seltene Dschungelschultersch?tzer der Entdeckung
  db:priv_AddDB("RecipesArmorsmith", 552499);   -- Rezeptur - Schwerer Helm des transformierten W?chters
  db:priv_AddDB("RecipesArmorsmith", 552501);   -- Rezeptur - Kettenr?stung des transformierten W?chters
  db:priv_AddDB("RecipesArmorsmith", 552502);   -- Rezeptur - Schulterpanzer des transformierten W?chters
  db:priv_AddDB("RecipesArmorsmith", 552503);   -- Rezeptur - Helm des transformierten Riesenauges
  db:priv_AddDB("RecipesArmorsmith", 552504);   -- Rezeptur - Stiefel des transformierten Riesenauges
  db:priv_AddDB("RecipesArmorsmith", 552505);   -- Rezeptur - Kettenr?stung des transformierten Riesenauges
  db:priv_AddDB("RecipesArmorsmith", 552506);   -- Rezeptur - Schultersch?tzer des transformierten Riesenauges
  db:priv_AddDB("RecipesArmorsmith", 552507);   -- Rezeptur - Traumlandsch?del des transformierten dunklen Drachen
  db:priv_AddDB("RecipesArmorsmith", 552508);   -- Rezeptur - Traumlandfu? des transformierten dunklen Drachen
  db:priv_AddDB("RecipesArmorsmith", 552509);   -- Rezeptur - Traumlandlederr?stung des transformierten dunklen Drachen
  db:priv_AddDB("RecipesArmorsmith", 552510);   -- Rezeptur - Traumlandschultersch?tzer des transformierten dunklen Drachen
  db:priv_AddDB("RecipesArmorsmith", 552511);   -- Rezeptur - Weicher Ledersch?del der transformierten K?nigin
  db:priv_AddDB("RecipesArmorsmith", 552512);   -- Rezeptur - Weicher Lederfu? der transformierten K?nigin
  db:priv_AddDB("RecipesArmorsmith", 552513);   -- Rezeptur - Weiche Lederr?stung der transformierten K?nigin
  db:priv_AddDB("RecipesArmorsmith", 552514);   -- Rezeptur - Weiche Lederschultersch?tzer der transformierten K?nigin
  db:priv_AddDB("RecipesArmorsmith", 552528);   -- Rezeptur - Runenr?stungstruhe
  db:priv_AddDB("RecipesArmorsmith", 552588);   -- Rezeptur - Handsch?tzer der Shotakpiraten
  db:priv_AddDB("RecipesArmorsmith", 552589);   -- Rezeptur - Gürtel der Shotakpiraten
  db:priv_AddDB("RecipesArmorsmith", 552590);   -- Rezeptur - Beinschützer der Shotakpiraten
  db:priv_AddDB("RecipesArmorsmith", 552592);   -- Rezeptur - Handsch?tzer der Frankopiraten
  db:priv_AddDB("RecipesArmorsmith", 552593);   -- Rezeptur - Gürtel der Frankopiraten
  db:priv_AddDB("RecipesArmorsmith", 552594);   -- Rezeptur - Beinschützer der Frankopiraten
  db:priv_AddDB("RecipesArmorsmith", 552596);   -- Rezeptur - Lederhandschuhe des Schwarzzahn-Schn?blers
  db:priv_AddDB("RecipesArmorsmith", 552597);   -- Rezeptur - Gürtel des Schwarzzahn-Schn?blers
  db:priv_AddDB("RecipesArmorsmith", 552598);   -- Rezeptur - Lederhose des Schwarzzahn-Schn?blers
  db:priv_AddDB("RecipesArmorsmith", 552604);   -- Rezeptur - Verbesserter Handsch?tzer der Shotakpiraten
  db:priv_AddDB("RecipesArmorsmith", 552605);   -- Rezeptur - Verbesserter Gürtel der Shotakpiraten
  db:priv_AddDB("RecipesArmorsmith", 552606);   -- Rezeptur - Verbesserter Beinschützer der Shotakpiraten
  db:priv_AddDB("RecipesArmorsmith", 552608);   -- Rezeptur - Verbesserter Handsch?tzer der Frankopiraten
  db:priv_AddDB("RecipesArmorsmith", 552609);   -- Rezeptur - Verbesserter Gürtel der Frankopiraten
  db:priv_AddDB("RecipesArmorsmith", 552610);   -- Rezeptur - Verbesserter Beinschützer der Frankopiraten
  db:priv_AddDB("RecipesArmorsmith", 552612);   -- Rezeptur - Verbesserter Lederhandschuh des Schwarzzahn-Schn?blers
  db:priv_AddDB("RecipesArmorsmith", 552613);   -- Rezeptur - Verbesserter Gürtel des Schwarzzahn-Schn?blers
  db:priv_AddDB("RecipesArmorsmith", 552614);   -- Rezeptur - Verbesserte Lederhose des Schwarzzahn-Schn?blers
  db:priv_AddDB("RecipesArmorsmith", 552620);   -- Rezeptur - Seltener Handsch?tzer der Shotakpiraten
  db:priv_AddDB("RecipesArmorsmith", 552621);   -- Rezeptur - Seltener Gürtel der Shotakpiraten
  db:priv_AddDB("RecipesArmorsmith", 552622);   -- Rezeptur - Seltener Beinschützer der Shotakpiraten
  db:priv_AddDB("RecipesArmorsmith", 552624);   -- Rezeptur - Seltener Handsch?tzer der Frankopiraten
  db:priv_AddDB("RecipesArmorsmith", 552625);   -- Rezeptur - Seltener Gürtel der Frankopiraten
  db:priv_AddDB("RecipesArmorsmith", 552626);   -- Rezeptur - Seltener Beinschützer der Frankopiraten
  db:priv_AddDB("RecipesArmorsmith", 552628);   -- Rezeptur - Seltener Lederhandschuh des Schwarzzahn-Schn?blers
  db:priv_AddDB("RecipesArmorsmith", 552629);   -- Rezeptur - Seltener Gürtel des Schwarzzahn-Schn?blers
  db:priv_AddDB("RecipesArmorsmith", 552630);   -- Rezeptur - Seltene Lederhose des Schwarzzahn-Schn?blers
  db:priv_AddDB("RecipesArmorsmith", 552636);   -- Rezeptur - Transformierter Handgelenksch?tzer der Stahlspinne
  db:priv_AddDB("RecipesArmorsmith", 552637);   -- Rezeptur - Transformierter Gürtel der Stahlspinne
  db:priv_AddDB("RecipesArmorsmith", 552638);   -- Rezeptur - Transformierter Beinschützer der Stahlspinne
  db:priv_AddDB("RecipesArmorsmith", 552640);   -- Rezeptur - Transformierter Metallhandgelenksch?tzer der Leere
  db:priv_AddDB("RecipesArmorsmith", 552641);   -- Rezeptur - Transformierter MetallGürtel der Leere
  db:priv_AddDB("RecipesArmorsmith", 552642);   -- Rezeptur - Transformierter MetallBeinschützer der Leere
  db:priv_AddDB("RecipesArmorsmith", 552644);   -- Rezeptur - Transformierter Handschuh der verbotenen Runen
  db:priv_AddDB("RecipesArmorsmith", 552645);   -- Rezeptur - Transformierter Gürtel der verbotenen Runen
  db:priv_AddDB("RecipesArmorsmith", 552646);   -- Rezeptur - Transformierte Lederhose der verbotenen Runen
  db:priv_AddDB("RecipesArmorsmith", 552648);   -- Rezeptur - Transformierter Handschuh des Meer- Elementars
  db:priv_AddDB("RecipesArmorsmith", 552649);   -- Rezeptur - Transformierter Gürtel des Meer-Elementars
  db:priv_AddDB("RecipesArmorsmith", 552650);   -- Rezeptur - Transformierte Lederhose des Meer-Elementars
  db:priv_AddDB("RecipesArmorsmith", 552662);   -- Rezeptur - Geheimnisvolle R?stungstruhe
  db:priv_AddDB("RecipesArmorsmith", 552704);   -- Rezeptur - Sahen-Helm
  db:priv_AddDB("RecipesArmorsmith", 552705);   -- Rezeptur - Sahen-Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 552706);   -- Rezeptur - Sahen-Schultersch?tzer
  db:priv_AddDB("RecipesArmorsmith", 552707);   -- Rezeptur - Sahen-Kampfstiefel
  db:priv_AddDB("RecipesArmorsmith", 552708);   -- Rezeptur - Bodo-Helm
  db:priv_AddDB("RecipesArmorsmith", 552709);   -- Rezeptur - Bodo-Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 552711);   -- Rezeptur - Bodo-Stiefel
  db:priv_AddDB("RecipesArmorsmith", 552712);   -- Rezeptur - Helm der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552713);   -- Rezeptur - Brustpanzer der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552714);   -- Rezeptur - Schultersch?tzer der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552715);   -- Rezeptur - Stiefel der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552722);   -- Rezeptur - Verbesserter Sahen-Helm
  db:priv_AddDB("RecipesArmorsmith", 552723);   -- Rezeptur - Verbesserter Sahen-Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 552724);   -- Rezeptur - Verbesserter Sahen-Schultersch?tzer
  db:priv_AddDB("RecipesArmorsmith", 552725);   -- Rezeptur - Verbesserte Sahen-Kampfstiefel
  db:priv_AddDB("RecipesArmorsmith", 552726);   -- Rezeptur - Verbesserter Bodo-Helm
  db:priv_AddDB("RecipesArmorsmith", 552727);   -- Rezeptur - Verbesserter Bodo-Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 552728);   -- Rezeptur - Verbesserte Bodo-Schultersch?tzer
  db:priv_AddDB("RecipesArmorsmith", 552729);   -- Rezeptur - Verbesserte Bodo-Stiefel
  db:priv_AddDB("RecipesArmorsmith", 552730);   -- Rezeptur - Verbesserter Helm der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552731);   -- Rezeptur - Verbesserter Brustpanzer der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552732);   -- Rezeptur - Verbesserte Schultersch?tzer der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552733);   -- Rezeptur - Verbesserte Stiefel der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552740);   -- Rezeptur - Seltener Sahen-Helm
  db:priv_AddDB("RecipesArmorsmith", 552741);   -- Rezeptur - Seltener Sahen-Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 552742);   -- Rezeptur - Seltene Sahen-Schultersch?tzer
  db:priv_AddDB("RecipesArmorsmith", 552743);   -- Rezeptur - Seltene Sahen-Stiefel
  db:priv_AddDB("RecipesArmorsmith", 552744);   -- Rezeptur - Seltener Bodo-Helm
  db:priv_AddDB("RecipesArmorsmith", 552745);   -- Rezeptur - Seltener Bodo-Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 552746);   -- Rezeptur - Seltene Bodo-Schultersch?tzer
  db:priv_AddDB("RecipesArmorsmith", 552747);   -- Rezeptur - Seltene Bodo-Stiefel
  db:priv_AddDB("RecipesArmorsmith", 552748);   -- Rezeptur - Seltener Helm der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552749);   -- Rezeptur - Seltener Brustpanzer der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552750);   -- Rezeptur - Seltene Schultersch?tzer der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552751);   -- Rezeptur - Seltene Stiefel der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552758);   -- Rezeptur - Transformierter Helm des Donners
  db:priv_AddDB("RecipesArmorsmith", 552759);   -- Rezeptur - Transformierter Brustpanzer des Donners
  db:priv_AddDB("RecipesArmorsmith", 552760);   -- Rezeptur - Transformierte Schultersch?tzer des Donners
  db:priv_AddDB("RecipesArmorsmith", 552762);   -- Rezeptur - Transformierter Helm der Inspiration
  db:priv_AddDB("RecipesArmorsmith", 552763);   -- Rezeptur - Transformierter Brustpanzer der Inspiration
  db:priv_AddDB("RecipesArmorsmith", 552764);   -- Rezeptur - Transformierte Schultersch?tzer der Inspiration
  db:priv_AddDB("RecipesArmorsmith", 552765);   -- Rezeptur - Transformierte Stiefel der Inspiration
  db:priv_AddDB("RecipesArmorsmith", 552766);   -- Rezeptur - Transformierte Maske der Heiligen Klangschale
  db:priv_AddDB("RecipesArmorsmith", 552767);   -- Rezeptur - Transformierter Mantel der Heiligen Klangschale
  db:priv_AddDB("RecipesArmorsmith", 552768);   -- Rezeptur - Transformierte Schultersch?tzer der Heiligen Klangschale
  db:priv_AddDB("RecipesArmorsmith", 552769);   -- Rezeptur - Transformierte Stiefel der Heiligen Klangschale
  db:priv_AddDB("RecipesArmorsmith", 552770);   -- Rezeptur - Transformierter Helm des Antischalls
  db:priv_AddDB("RecipesArmorsmith", 552771);   -- Rezeptur - Transformierter Mantel des Antischalls
  db:priv_AddDB("RecipesArmorsmith", 552772);   -- Rezeptur - Transformierte Schultersch?tzer des Antischalls
  db:priv_AddDB("RecipesArmorsmith", 552773);   -- Rezeptur - Transformierte Stiefel des Antischalls
  db:priv_AddDB("RecipesArmorsmith", 552802);   -- Rezeptur - Geh?rtete R?stungstruhe
  db:priv_AddDB("RecipesArmorsmith", 552806);   -- Rezeptur - Meisterhafte R?stungstruhe
  db:priv_AddDB("RecipesArmorsmith", 552820);   -- Rezeptur - Legend?re R?stungstruhe
  db:priv_AddDB("RecipesArmorsmith", 552824);   -- Rezeptur - Ultimative R?stungstruhe
  db:priv_AddDB("RecipesArmorsmith", 552838);   -- Rezeptur - Himmlische R?stungstruhe
  db:priv_AddDB("RecipesArmorsmith", 552842);   -- Rezeptur - G?ttliche R?stungstruhe
  db:priv_AddDB("RecipesArmorsmith", 552927);   -- Rezeptur - Kulang-Handschuhe
  db:priv_AddDB("RecipesArmorsmith", 552928);   -- Rezeptur - Kulang-Gürtel
  db:priv_AddDB("RecipesArmorsmith", 552929);   -- Rezeptur - Kulang-Hose
  db:priv_AddDB("RecipesArmorsmith", 552931);   -- Rezeptur - Walu-Handschuhe
  db:priv_AddDB("RecipesArmorsmith", 552932);   -- Rezeptur - Walu-Gürtel
  db:priv_AddDB("RecipesArmorsmith", 552933);   -- Rezeptur - Walu-Hose
  db:priv_AddDB("RecipesArmorsmith", 552935);   -- Rezeptur - Handschuhe von Alaine
  db:priv_AddDB("RecipesArmorsmith", 552936);   -- Rezeptur - Gürtel von Alaine
  db:priv_AddDB("RecipesArmorsmith", 552937);   -- Rezeptur - Hose von Alaine
  db:priv_AddDB("RecipesArmorsmith", 552945);   -- Rezeptur - Verbesserte Kulang-Handschuhe
  db:priv_AddDB("RecipesArmorsmith", 552946);   -- Rezeptur - Verbesserter Kulang-Gürtel
  db:priv_AddDB("RecipesArmorsmith", 552947);   -- Rezeptur - Verbesserte Kulang-Hose
  db:priv_AddDB("RecipesArmorsmith", 552949);   -- Rezeptur - Verbesserte Walu-Handschuhe
  db:priv_AddDB("RecipesArmorsmith", 552950);   -- Rezeptur - Verbesserter Walu-Gürtel
  db:priv_AddDB("RecipesArmorsmith", 552951);   -- Rezeptur - Verbesserte Walu-Hose
  db:priv_AddDB("RecipesArmorsmith", 552953);   -- Rezeptur - Verbesserte Handschuhe von Alaine
  db:priv_AddDB("RecipesArmorsmith", 552954);   -- Rezeptur - Verbesserter Gürtel von Alaine
  db:priv_AddDB("RecipesArmorsmith", 552955);   -- Rezeptur - Verbesserte Hose von Alaine
  db:priv_AddDB("RecipesArmorsmith", 552963);   -- Rezeptur - Seltene Kulang-Handschuhe
  db:priv_AddDB("RecipesArmorsmith", 552964);   -- Rezeptur - Seltener Kulang-Gürtel
  db:priv_AddDB("RecipesArmorsmith", 552965);   -- Rezeptur - Seltene Kulang-Hose
  db:priv_AddDB("RecipesArmorsmith", 552967);   -- Rezeptur - Seltene Walu-Handschuhe
  db:priv_AddDB("RecipesArmorsmith", 552968);   -- Rezeptur - Seltener Walu-Gürtel
  db:priv_AddDB("RecipesArmorsmith", 552969);   -- Rezeptur - Seltene Walu-Hose
  db:priv_AddDB("RecipesArmorsmith", 552971);   -- Rezeptur - Seltene Handschuhe von Alaine
  db:priv_AddDB("RecipesArmorsmith", 552972);   -- Rezeptur - Seltener Gürtel von Alaine
  db:priv_AddDB("RecipesArmorsmith", 552973);   -- Rezeptur - Seltene Hose von Alaine
  db:priv_AddDB("RecipesArmorsmith", 552981);   -- Rezeptur - Transformierte Handschuhe des Wolfshammers
  db:priv_AddDB("RecipesArmorsmith", 552982);   -- Rezeptur - Transformierter Gürtel des Wolfshammers
  db:priv_AddDB("RecipesArmorsmith", 552983);   -- Rezeptur - Transformierte Hose des Wolfshammers
  db:priv_AddDB("RecipesArmorsmith", 552985);   -- Rezeptur - Transformierte Handschuhe der Bleiche
  db:priv_AddDB("RecipesArmorsmith", 552986);   -- Rezeptur - Transformierter Gürtel der Bleiche
  db:priv_AddDB("RecipesArmorsmith", 552987);   -- Rezeptur - Transformierte Hose der Bleiche
  db:priv_AddDB("RecipesArmorsmith", 552989);   -- Rezeptur - Transformierte Handschuhe der Blutranken
  db:priv_AddDB("RecipesArmorsmith", 552990);   -- Rezeptur - Transformierter Gürtel der Blutranken
  db:priv_AddDB("RecipesArmorsmith", 552991);   -- Rezeptur - Transformierte Hose der Blutranken
  db:priv_AddDB("RecipesArmorsmith", 552993);   -- Rezeptur - Transformierte Handschuhe der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552994);   -- Rezeptur - Transformierter Gürtel der Bestie
  db:priv_AddDB("RecipesArmorsmith", 552995);   -- Rezeptur - Transformierte Hose der Bestie
  db:priv_AddDB("RecipesArmorsmith", 553038);   -- Rezeptur - Verfluchter Helm
  db:priv_AddDB("RecipesArmorsmith", 553039);   -- Rezeptur - Verfluchter Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 553040);   -- Rezeptur - Verfluchter Schulterpanzer
  db:priv_AddDB("RecipesArmorsmith", 553041);   -- Rezeptur - Verfluchte Kriegsstiefel
  db:priv_AddDB("RecipesArmorsmith", 553042);   -- Rezeptur - Flammenge?tzter Helm
  db:priv_AddDB("RecipesArmorsmith", 553043);   -- Rezeptur - Flammenge?tzter Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 553044);   -- Rezeptur - Flammenge?tzter Schulterpanzer
  db:priv_AddDB("RecipesArmorsmith", 553045);   -- Rezeptur - Flammenge?tzte Stiefel
  db:priv_AddDB("RecipesArmorsmith", 553046);   -- Rezeptur - Einge?scherter Helm
  db:priv_AddDB("RecipesArmorsmith", 553047);   -- Rezeptur - Einge?scherter Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 553048);   -- Rezeptur - Einge?scherter Schulterpanzer
  db:priv_AddDB("RecipesArmorsmith", 553049);   -- Rezeptur - Einge?scherte Stiefel
  db:priv_AddDB("RecipesArmorsmith", 553056);   -- Rezeptur - Verstärkter verfluchter Helm
  db:priv_AddDB("RecipesArmorsmith", 553057);   -- Rezeptur - Verstärkter verfluchter Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 553058);   -- Rezeptur - Verstärkter verfluchter Schulterpanzer
  db:priv_AddDB("RecipesArmorsmith", 553059);   -- Rezeptur - Verstärkte verfluchte Kriegsstiefel
  db:priv_AddDB("RecipesArmorsmith", 553060);   -- Rezeptur - Verstärkter flammenge?tzter Helm
  db:priv_AddDB("RecipesArmorsmith", 553061);   -- Rezeptur - Verstärkter flammenge?tzter Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 553062);   -- Rezeptur - Verstärkter flammenge?tzter Schulterpanzer
  db:priv_AddDB("RecipesArmorsmith", 553063);   -- Rezeptur - Verstärkte flammenge?tzte Stiefel
  db:priv_AddDB("RecipesArmorsmith", 553064);   -- Rezeptur - Verstärkter einge?scherter Helm
  db:priv_AddDB("RecipesArmorsmith", 553065);   -- Rezeptur - Verstärkter einge?scherter Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 553066);   -- Rezeptur - Verstärkter einge?scherter Schulterpanzer
  db:priv_AddDB("RecipesArmorsmith", 553067);   -- Rezeptur - Verstärkte einge?scherte Stiefel
  db:priv_AddDB("RecipesArmorsmith", 553074);   -- Rezeptur - Seltener verfluchter Helm
  db:priv_AddDB("RecipesArmorsmith", 553075);   -- Rezeptur - Seltener verfluchter Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 553076);   -- Rezeptur - Seltener verfluchter Schulterpanzer
  db:priv_AddDB("RecipesArmorsmith", 553077);   -- Rezeptur - Seltene verfluchte Kriegsstiefel
  db:priv_AddDB("RecipesArmorsmith", 553079);   -- Rezeptur - Seltener flammenge?tzter Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 553080);   -- Rezeptur - Seltener flammenge?tzter Schulterpanzer
  db:priv_AddDB("RecipesArmorsmith", 553081);   -- Rezeptur - Seltene flammenge?tzte Stiefel
  db:priv_AddDB("RecipesArmorsmith", 553082);   -- Rezeptur - Seltener einge?scherter Helm
  db:priv_AddDB("RecipesArmorsmith", 553083);   -- Rezeptur - Seltener einge?scherter Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 553084);   -- Rezeptur - Seltener einge?scherter Schulterpanzer
  db:priv_AddDB("RecipesArmorsmith", 553085);   -- Rezeptur - Seltene einge?scherte Stiefel
  db:priv_AddDB("RecipesArmorsmith", 553092);   -- Rezeptur - Transformierter Helm der Wache
  db:priv_AddDB("RecipesArmorsmith", 553093);   -- Rezeptur - Transformierter Brustpanzer der Wache
  db:priv_AddDB("RecipesArmorsmith", 553094);   -- Rezeptur - Transformierter Schulterpanzer der Wache
  db:priv_AddDB("RecipesArmorsmith", 553095);   -- Rezeptur - Transformierte Kriegsstiefel der Wache
  db:priv_AddDB("RecipesArmorsmith", 553096);   -- Rezeptur - Transformierter Helm der Befallenen
  db:priv_AddDB("RecipesArmorsmith", 553097);   -- Rezeptur - Transformierter Brustpanzer der Befallenen
  db:priv_AddDB("RecipesArmorsmith", 553098);   -- Rezeptur - Transformierter Schulterpanzer der Befallenen
  db:priv_AddDB("RecipesArmorsmith", 553099);   -- Rezeptur - Transformierte Stiefel der Befallenen
  db:priv_AddDB("RecipesArmorsmith", 553100);   -- Rezeptur - Transformierte Maske der Unruhe
  db:priv_AddDB("RecipesArmorsmith", 553101);   -- Rezeptur - Transformierter Mantel der Unruhe
  db:priv_AddDB("RecipesArmorsmith", 553102);   -- Rezeptur - Transformierter Schulterpanzer der Unruhe
  db:priv_AddDB("RecipesArmorsmith", 553103);   -- Rezeptur - Transformierte Stiefel der Unruhe
  db:priv_AddDB("RecipesArmorsmith", 553104);   -- Rezeptur - Transformierter Helm des Energieschubs
  db:priv_AddDB("RecipesArmorsmith", 553105);   -- Rezeptur - Transformierter Mantel des Energieschubs
  db:priv_AddDB("RecipesArmorsmith", 553106);   -- Rezeptur - Transformierter Schulterpanzer des Energieschubs
  db:priv_AddDB("RecipesArmorsmith", 553107);   -- Rezeptur - Transformierte Stiefel des Energieschubs
  db:priv_AddDB("RecipesArmorsmith", 553147);   -- Rezeptur - Handschutz der Eisenschwinge
  db:priv_AddDB("RecipesArmorsmith", 553148);   -- Rezeptur - Gürtel der Eisenschwinge
  db:priv_AddDB("RecipesArmorsmith", 553149);   -- Rezeptur - Beinschützer der Eisenschwinge
  db:priv_AddDB("RecipesArmorsmith", 553151);   -- Rezeptur - Silberzimt-Handschutz
  db:priv_AddDB("RecipesArmorsmith", 553152);   -- Rezeptur - Silberzimt-Gürtel
  db:priv_AddDB("RecipesArmorsmith", 553153);   -- Rezeptur - Silberzimt-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 553155);   -- Rezeptur - Bartashandschuhe
  db:priv_AddDB("RecipesArmorsmith", 553156);   -- Rezeptur - BartasGürtel
  db:priv_AddDB("RecipesArmorsmith", 553157);   -- Rezeptur - Bartashose
  db:priv_AddDB("RecipesArmorsmith", 553165);   -- Rezeptur - Verbesserter Handschutz der Eisenschwinge
  db:priv_AddDB("RecipesArmorsmith", 553166);   -- Rezeptur - Verbesserter Gürtel der Eisenschwinge
  db:priv_AddDB("RecipesArmorsmith", 553167);   -- Rezeptur - Verbesserte Beinschützer der Eisenschwinge
  db:priv_AddDB("RecipesArmorsmith", 553169);   -- Rezeptur - Verbesserter Silberzimt-Handschutz
  db:priv_AddDB("RecipesArmorsmith", 553170);   -- Rezeptur - Verbesserter Silberzimt-Gürtel
  db:priv_AddDB("RecipesArmorsmith", 553171);   -- Rezeptur - Verbesserte Silberzimt-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 553173);   -- Rezeptur - Verbesserte Bartashandschuhe
  db:priv_AddDB("RecipesArmorsmith", 553174);   -- Rezeptur - Verbesserter BartasGürtel
  db:priv_AddDB("RecipesArmorsmith", 553175);   -- Rezeptur - Verbesserte Bartashose
  db:priv_AddDB("RecipesArmorsmith", 553183);   -- Rezeptur - Seltener Handschutz der Eisenschwinge
  db:priv_AddDB("RecipesArmorsmith", 553184);   -- Rezeptur - Seltener Gürtel der Eisenschwinge
  db:priv_AddDB("RecipesArmorsmith", 553185);   -- Rezeptur - Seltene Beinschützer der Eisenschwinge
  db:priv_AddDB("RecipesArmorsmith", 553187);   -- Rezeptur - Seltener Silberzimt-Handschutz
  db:priv_AddDB("RecipesArmorsmith", 553188);   -- Rezeptur - Seltener Silberzimt-Gürtel
  db:priv_AddDB("RecipesArmorsmith", 553189);   -- Rezeptur - Seltene Silberzimt-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 553191);   -- Rezeptur - Seltene Bartashandschuhe
  db:priv_AddDB("RecipesArmorsmith", 553192);   -- Rezeptur - Seltener BartasGürtel
  db:priv_AddDB("RecipesArmorsmith", 553193);   -- Rezeptur - Seltene Bartashose
  db:priv_AddDB("RecipesArmorsmith", 553201);   -- Rezeptur - Transformierte Handschuhe der Sirenenk?nigin
  db:priv_AddDB("RecipesArmorsmith", 553202);   -- Rezeptur - Transformierter Gürtel der Sirenenk?nigin
  db:priv_AddDB("RecipesArmorsmith", 553203);   -- Rezeptur - Transformierte Hose der Sirenenk?nigin
  db:priv_AddDB("RecipesArmorsmith", 553205);   -- Rezeptur - Transformierte Handschuhe des Großen Koboldh?uptlings
  db:priv_AddDB("RecipesArmorsmith", 553206);   -- Rezeptur - Transformierter Gürtel des Großen Koboldh?uptlings
  db:priv_AddDB("RecipesArmorsmith", 553207);   -- Rezeptur - Transformierte Hose des Großen Koboldh?uptlings
  db:priv_AddDB("RecipesArmorsmith", 553209);   -- Rezeptur - Transformierte Handschuhe des Splitterstromschurken
  db:priv_AddDB("RecipesArmorsmith", 553210);   -- Rezeptur - Transformierter Gürtel des Splitterstromschurken
  db:priv_AddDB("RecipesArmorsmith", 553211);   -- Rezeptur - Transformierte Hose des Splitterstromschurken
  db:priv_AddDB("RecipesArmorsmith", 553213);   -- Rezeptur - Transformierte Handschuhe des Tiktaalikgenerals
  db:priv_AddDB("RecipesArmorsmith", 553214);   -- Rezeptur - Transformierter Gürtel des Tiktaalikgenerals
  db:priv_AddDB("RecipesArmorsmith", 553215);   -- Rezeptur - Transformierte Hose des Tiktaalikgenerals
  db:priv_AddDB("RecipesArmorsmith", 553252);   -- Rezeptur - Lorsens Helm
  db:priv_AddDB("RecipesArmorsmith", 553253);   -- Rezeptur - Lorsens Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 553254);   -- Rezeptur - Lorsens Schulterpanzer
  db:priv_AddDB("RecipesArmorsmith", 553255);   -- Rezeptur - Lorsens Kampfstiefel
  db:priv_AddDB("RecipesArmorsmith", 553256);   -- Rezeptur - Helm von Sandhor
  db:priv_AddDB("RecipesArmorsmith", 553257);   -- Rezeptur - Brustpanzer von Sandhor
  db:priv_AddDB("RecipesArmorsmith", 553258);   -- Rezeptur - Schulterpanzer von Sandhor
  db:priv_AddDB("RecipesArmorsmith", 553259);   -- Rezeptur - Kampfstiefel von Sandhor
  db:priv_AddDB("RecipesArmorsmith", 553260);   -- Rezeptur - Helm von Akson
  db:priv_AddDB("RecipesArmorsmith", 553261);   -- Rezeptur - Brustpanzer von Akson
  db:priv_AddDB("RecipesArmorsmith", 553262);   -- Rezeptur - Schultersch?tzer von Akson
  db:priv_AddDB("RecipesArmorsmith", 553263);   -- Rezeptur - Lederstiefel von Akson
  db:priv_AddDB("RecipesArmorsmith", 553270);   -- Rezeptur - Lorsens verbesserter Helm
  db:priv_AddDB("RecipesArmorsmith", 553271);   -- Rezeptur - Lorsens verbesserter Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 553272);   -- Rezeptur - Lorsens verbesserter Schulterpanzer
  db:priv_AddDB("RecipesArmorsmith", 553273);   -- Rezeptur - Lorsens verbesserte Kampfstiefel
  db:priv_AddDB("RecipesArmorsmith", 553274);   -- Rezeptur - Verbesserter Helm von Sandhor
  db:priv_AddDB("RecipesArmorsmith", 553275);   -- Rezeptur - Verbesserter Brustpanzer von Sandhor
  db:priv_AddDB("RecipesArmorsmith", 553276);   -- Rezeptur - Verbesserte Schulterpanzer von Sandhor
  db:priv_AddDB("RecipesArmorsmith", 553277);   -- Rezeptur - Verbesserte Kampfstiefel von Sandhor
  db:priv_AddDB("RecipesArmorsmith", 553278);   -- Rezeptur - Verbesserter Helm von Akson
  db:priv_AddDB("RecipesArmorsmith", 553279);   -- Rezeptur - Verbesserter Brustpanzer von Akson
  db:priv_AddDB("RecipesArmorsmith", 553280);   -- Rezeptur - Verbesserte Schultersch?tzer von Akson
  db:priv_AddDB("RecipesArmorsmith", 553281);   -- Rezeptur - Verbesserte Lederstiefel von Akson
  db:priv_AddDB("RecipesArmorsmith", 553288);   -- Rezeptur - Lorsens seltener Helm
  db:priv_AddDB("RecipesArmorsmith", 553289);   -- Rezeptur - Lorsens seltener Brustpanzer
  db:priv_AddDB("RecipesArmorsmith", 553290);   -- Rezeptur - Lorsens seltener Schulterpanzer
  db:priv_AddDB("RecipesArmorsmith", 553291);   -- Rezeptur - Lorsens seltene Kampfstiefel
  db:priv_AddDB("RecipesArmorsmith", 553292);   -- Rezeptur - Seltener Helm von Sandhor
  db:priv_AddDB("RecipesArmorsmith", 553293);   -- Rezeptur - Seltener Brustpanzer von Sandhor
  db:priv_AddDB("RecipesArmorsmith", 553294);   -- Rezeptur - Seltene Schulterpanzer von Sandhor
  db:priv_AddDB("RecipesArmorsmith", 553295);   -- Rezeptur - Seltene Kampfstiefel von Sandhor
  db:priv_AddDB("RecipesArmorsmith", 553296);   -- Rezeptur - Seltener Helm von Akson
  db:priv_AddDB("RecipesArmorsmith", 553297);   -- Rezeptur - Seltener Brustpanzer von Akson
  db:priv_AddDB("RecipesArmorsmith", 553298);   -- Rezeptur - Seltene Schultersch?tzer von Akson
  db:priv_AddDB("RecipesArmorsmith", 553299);   -- Rezeptur - Seltene Lederstiefel von Akson
  db:priv_AddDB("RecipesArmorsmith", 553306);   -- Rezeptur - Transformierter Helm des Eisenblut-Generals
  db:priv_AddDB("RecipesArmorsmith", 553307);   -- Rezeptur - Transformierter Brustpanzer des Eisenblut-Generals
  db:priv_AddDB("RecipesArmorsmith", 553308);   -- Rezeptur - Transformierte Schulterpanzer des Eisenblut-Generals
  db:priv_AddDB("RecipesArmorsmith", 553309);   -- Rezeptur - Transformierte Kampfstiefel des Eisenblut-Generals
  db:priv_AddDB("RecipesArmorsmith", 553310);   -- Rezeptur - Transformierter Helm des Eisenkiefertyrannen
  db:priv_AddDB("RecipesArmorsmith", 553311);   -- Rezeptur - Transformierter Brustpanzer des Eisenkiefertyrannen
  db:priv_AddDB("RecipesArmorsmith", 553312);   -- Rezeptur - Transformierte Schulterpanzer des Eisenkiefertyrannen
  db:priv_AddDB("RecipesArmorsmith", 553313);   -- Rezeptur - Transformierte Kampfstiefel des Eisenkiefertyrannen
  db:priv_AddDB("RecipesArmorsmith", 553314);   -- Rezeptur - Transformierte Maske des doppelk?pfigen Propheten
  db:priv_AddDB("RecipesArmorsmith", 553315);   -- Rezeptur - Transformierter Mantel des doppelk?pfigen Propheten
  db:priv_AddDB("RecipesArmorsmith", 553316);   -- Rezeptur - Transformierte Schulterpanzer des doppelk?pfigen Propheten
  db:priv_AddDB("RecipesArmorsmith", 553317);   -- Rezeptur - Transformierte Lederstiefel des doppelk?pfigen Propheten
  db:priv_AddDB("RecipesArmorsmith", 553318);   -- Rezeptur - Transformierter Helm des Gro?schamanen
  db:priv_AddDB("RecipesArmorsmith", 553319);   -- Rezeptur - Transformierter Mantel des Gro?schamanen
  db:priv_AddDB("RecipesArmorsmith", 553320);   -- Rezeptur - Transformierte Schulterpanzer des Gro?schamanen
  db:priv_AddDB("RecipesArmorsmith", 553321);   -- Rezeptur - Transformierte Lederstiefel des Gro?schamanen
  db:priv_AddDB("RecipesArmorsmith", 553361);   -- Rezeptur - Handschuhe der Silberspuren
  db:priv_AddDB("RecipesArmorsmith", 553362);   -- Rezeptur - Gürtel der Silberspuren
  db:priv_AddDB("RecipesArmorsmith", 553363);   -- Rezeptur - Beinschützer der Silberspuren
  db:priv_AddDB("RecipesArmorsmith", 553365);   -- Rezeptur - Handschuhe des Tals ohne Wiederkehr
  db:priv_AddDB("RecipesArmorsmith", 553366);   -- Rezeptur - Gürtel des Tals ohne Wiederkehr
  db:priv_AddDB("RecipesArmorsmith", 553367);   -- Rezeptur - Langhose des Tals ohne Wiederkehr
  db:priv_AddDB("RecipesArmorsmith", 553369);   -- Rezeptur - Staubkesselhandschuhe
  db:priv_AddDB("RecipesArmorsmith", 553370);   -- Rezeptur - StaubkesselGürtel
  db:priv_AddDB("RecipesArmorsmith", 553371);   -- Rezeptur - Staubkessellanghose
  db:priv_AddDB("RecipesArmorsmith", 553379);   -- Rezeptur - Verbesserte Handschuhe der Silberspuren
  db:priv_AddDB("RecipesArmorsmith", 553380);   -- Rezeptur - Verbesserter Gürtel der Silberspuren
  db:priv_AddDB("RecipesArmorsmith", 553381);   -- Rezeptur - Verbesserte Beinschützer der Silberspuren
  db:priv_AddDB("RecipesArmorsmith", 553383);   -- Rezeptur - Verbesserte Handschuhe des Tals ohne Wiederkehr
  db:priv_AddDB("RecipesArmorsmith", 553384);   -- Rezeptur - Verbesserter Gürtel des Tals ohne Wiederkehr
  db:priv_AddDB("RecipesArmorsmith", 553385);   -- Rezeptur - Verbesserte Langhose des Tals ohne Wiederkehr
  db:priv_AddDB("RecipesArmorsmith", 553387);   -- Rezeptur - Verbesserte Staubkesselhandschuhe
  db:priv_AddDB("RecipesArmorsmith", 553388);   -- Rezeptur - Verbesserter StaubkesselGürtel
  db:priv_AddDB("RecipesArmorsmith", 553389);   -- Rezeptur - Verbesserte Staubkessellanghose
  db:priv_AddDB("RecipesArmorsmith", 553397);   -- Rezeptur - Seltene Handschuhe der Silberspuren
  db:priv_AddDB("RecipesArmorsmith", 553398);   -- Rezeptur - Seltene Gürtel der Silberspuren
  db:priv_AddDB("RecipesArmorsmith", 553399);   -- Rezeptur - Seltene Beinschützer der Silberspuren
  db:priv_AddDB("RecipesArmorsmith", 553401);   -- Rezeptur - Seltene Handschuhe des Tals ohne Wiederkehr
  db:priv_AddDB("RecipesArmorsmith", 553402);   -- Rezeptur - Seltener Gürtel des Tals ohne Wiederkehr
  db:priv_AddDB("RecipesArmorsmith", 553403);   -- Rezeptur - Seltene Langhose des Tals ohne Wiederkehr
  db:priv_AddDB("RecipesArmorsmith", 553405);   -- Rezeptur - Seltene Staubkesselhandschuhe
  db:priv_AddDB("RecipesArmorsmith", 553406);   -- Rezeptur - Seltener StaubkesselGürtel
  db:priv_AddDB("RecipesArmorsmith", 553407);   -- Rezeptur - Seltene Staubkessellanghose
  db:priv_AddDB("RecipesArmorsmith", 553415);   -- Rezeptur - Transformierte Handsch?tzer der Klingen
  db:priv_AddDB("RecipesArmorsmith", 553416);   -- Rezeptur - Transformierter Gürtel der Klingen
  db:priv_AddDB("RecipesArmorsmith", 553417);   -- Rezeptur - Transformierte Beinschützer der Klingen
  db:priv_AddDB("RecipesArmorsmith", 553419);   -- Rezeptur - Transformierte Handsch?tzer der Passage der Pr?fungen
  db:priv_AddDB("RecipesArmorsmith", 553420);   -- Rezeptur - Transformierter Gürtel der Passage der Pr?fungen
  db:priv_AddDB("RecipesArmorsmith", 553421);   -- Rezeptur - Transformierte Beinschützer der Passage der Pr?fungen
  db:priv_AddDB("RecipesArmorsmith", 553423);   -- Rezeptur - Transformierte Handsch?tzer der Energiestr?me
  db:priv_AddDB("RecipesArmorsmith", 553424);   -- Rezeptur - Transformierter Gürtel der Energiestr?me
  db:priv_AddDB("RecipesArmorsmith", 553425);   -- Rezeptur - Transformierte Beinschützer der Energiestr?me
  db:priv_AddDB("RecipesArmorsmith", 553427);   -- Rezeptur - Transformierte Hirntentakel-Handsch?tzer
  db:priv_AddDB("RecipesArmorsmith", 553428);   -- Rezeptur - Transformierter Hirntentakel-Gürtel
  db:priv_AddDB("RecipesArmorsmith", 553429);   -- Rezeptur - Transformierte Hirntentakel-Beinschützer
  db:priv_AddDB("RecipesArmorsmith", 553448);   -- Rezeptur - Transformierter Helm des Hohepriesters
  db:priv_AddDB("RecipesArmorsmith", 553449);   -- Rezeptur - Transformierter Brustpanzer des Hohepriesters
  db:priv_AddDB("RecipesArmorsmith", 553450);   -- Rezeptur - Transformierter Schulterpanzer des Hohepriesters
  db:priv_AddDB("RecipesArmorsmith", 553451);   -- Rezeptur - Transformierte Kampfstiefel des Hohepriesters
  db:priv_AddDB("RecipesArmorsmith", 553452);   -- Rezeptur - Transformierter Stirnschutz des Eishauchs
  db:priv_AddDB("RecipesArmorsmith", 553453);   -- Rezeptur - Transformierte Kettenr?stung des Eishauchs
  db:priv_AddDB("RecipesArmorsmith", 553454);   -- Rezeptur - Transformierte Schulterpanzer des Eishauchs
  db:priv_AddDB("RecipesArmorsmith", 553455);   -- Rezeptur - Transformierte Kampfstiefel des Eishauchs
  db:priv_AddDB("RecipesArmorsmith", 553456);   -- Rezeptur - Transformierte Maske der Mediatorin
  db:priv_AddDB("RecipesArmorsmith", 553457);   -- Rezeptur - Transformierter Mantel der Mediatorin
  db:priv_AddDB("RecipesArmorsmith", 553458);   -- Rezeptur - Transformierte Schulterpanzer der Mediatorin
  db:priv_AddDB("RecipesArmorsmith", 553459);   -- Rezeptur - Transformierte Lederstiefel der Mediatorin
  db:priv_AddDB("RecipesArmorsmith", 553470);   -- Rezeptur - Transformierter Handschutz des Tempelw?chters
  db:priv_AddDB("RecipesArmorsmith", 553471);   -- Rezeptur - Transformierter Gürtel des Tempelw?chters
  db:priv_AddDB("RecipesArmorsmith", 553472);   -- Rezeptur - Transformierte Beinschützer des Tempelw?chters
  db:priv_AddDB("RecipesArmorsmith", 553474);   -- Rezeptur - Transformierter Handschutz der S?enden
  db:priv_AddDB("RecipesArmorsmith", 553475);   -- Rezeptur - Transformierter Gürtel der S?enden
  db:priv_AddDB("RecipesArmorsmith", 553476);   -- Rezeptur - Transformierter Beinschutz der S?enden

  db:priv_AddDB("RecipesArmorsmith", 553478);   -- Rezeptur - Transformierter Handschutz des Meisterj?gers
  db:priv_AddDB("RecipesArmorsmith", 553479);   -- Rezeptur - Transformierter Gürtel des Meisterj?gers
  db:priv_AddDB("RecipesArmorsmith", 553480);   -- Rezeptur - Transformierter Beinschutz des Meisterj?gers  
  db:priv_AddDB("RecipesArmorsmith", 553499);   -- Rezeptur - 236155
  db:priv_AddDB("RecipesArmorsmith", 553500);   -- Rezeptur - 236156
  db:priv_AddDB("RecipesArmorsmith", 553501);   -- Rezeptur - 236157
  db:priv_AddDB("RecipesArmorsmith", 553503);   -- Rezeptur - 236159
  db:priv_AddDB("RecipesArmorsmith", 553504);   -- Rezeptur - 
  db:priv_AddDB("RecipesArmorsmith", 553505);   -- Rezeptur - 
  db:priv_AddDB("RecipesArmorsmith", 553507);   -- Rezeptur - 
  db:priv_AddDB("RecipesArmorsmith", 553508);   -- Rezeptur - 
  db:priv_AddDB("RecipesArmorsmith", 553509);   -- Rezeptur - 


end

local function priv_AddRecipesWeaponsmith(db)   -- Rezepte Waffenschmied

  db:priv_AddDB("RecipesWeaponsmith", 550344);   -- Rezeptur - Kurzes Verteidigungsschwert
  db:priv_AddDB("RecipesWeaponsmith", 550345);   -- Rezeptur - Verbessertes Kurzschwert
  db:priv_AddDB("RecipesWeaponsmith", 550346);   -- Rezeptur - Kurzschwert
  db:priv_AddDB("RecipesWeaponsmith", 550347);   -- Rezeptur - Verbesserter Dolch der Dornenranke
  db:priv_AddDB("RecipesWeaponsmith", 550348);   -- Rezeptur - Dolch der Dornenranke
  db:priv_AddDB("RecipesWeaponsmith", 550349);   -- Rezeptur - Blauer Nagel
  db:priv_AddDB("RecipesWeaponsmith", 550350);   -- Rezeptur - Verbesserter verborgener Dolch
  db:priv_AddDB("RecipesWeaponsmith", 550351);   -- Rezeptur - Verborgener Dolch
  db:priv_AddDB("RecipesWeaponsmith", 550352);   -- Rezeptur - Schlaufengriff-Dolch
  db:priv_AddDB("RecipesWeaponsmith", 550353);   -- Rezeptur - Drachenklauen-Dolch
  db:priv_AddDB("RecipesWeaponsmith", 550354);   -- Rezeptur - Skorpionstachel-Dolch
  db:priv_AddDB("RecipesWeaponsmith", 550355);   -- Rezeptur - Verbesserter Hakendolch
  db:priv_AddDB("RecipesWeaponsmith", 550356);   -- Rezeptur - Hakendolch
  db:priv_AddDB("RecipesWeaponsmith", 550358);   -- Rezeptur - Fledermaus-Flachaxt
  db:priv_AddDB("RecipesWeaponsmith", 550359);   -- Rezeptur - Verbesserte scharfe Axt
  db:priv_AddDB("RecipesWeaponsmith", 550360);   -- Rezeptur - Scharfe Axt
  db:priv_AddDB("RecipesWeaponsmith", 550361);   -- Rezeptur - Verbesserte durchdringende Axt
  db:priv_AddDB("RecipesWeaponsmith", 550362);   -- Rezeptur - Durchdringende Axt
  db:priv_AddDB("RecipesWeaponsmith", 550363);   -- Rezeptur - Gortheanische Streitaxt
  db:priv_AddDB("RecipesWeaponsmith", 550364);   -- Rezeptur - Kettenaxt
  db:priv_AddDB("RecipesWeaponsmith", 550365);   -- Rezeptur - Axt des boshaften Ritters
  db:priv_AddDB("RecipesWeaponsmith", 550366);   -- Rezeptur - Verbesserter runder Holzschild
  db:priv_AddDB("RecipesWeaponsmith", 550367);   -- Rezeptur - Runder Holzschild
  db:priv_AddDB("RecipesWeaponsmith", 550368);   -- Rezeptur - Harter Lederschild
  db:priv_AddDB("RecipesWeaponsmith", 550369);   -- Rezeptur - Verbesserter drachenf?rmiger Schild
  db:priv_AddDB("RecipesWeaponsmith", 550370);   -- Rezeptur - Drachenf?rmiger Schild
  db:priv_AddDB("RecipesWeaponsmith", 550371);   -- Rezeptur - Bestienhornschild
  db:priv_AddDB("RecipesWeaponsmith", 550372);   -- Rezeptur - Schild der blauen Flamme
  db:priv_AddDB("RecipesWeaponsmith", 550373);   -- Rezeptur - Verbesserter Flammenschild
  db:priv_AddDB("RecipesWeaponsmith", 550374);   -- Rezeptur - Flammenschild
  db:priv_AddDB("RecipesWeaponsmith", 550375);   -- Rezeptur - Verbesserte leichte Klinge
  db:priv_AddDB("RecipesWeaponsmith", 550376);   -- Rezeptur - Leichte Klinge
  db:priv_AddDB("RecipesWeaponsmith", 550377);   -- Rezeptur - Schuppenlicht-Schwert
  db:priv_AddDB("RecipesWeaponsmith", 550378);   -- Rezeptur - Kapuliton
  db:priv_AddDB("RecipesWeaponsmith", 550379);   -- Rezeptur - Pr?zise Schneideklinge
  db:priv_AddDB("RecipesWeaponsmith", 550380);   -- Rezeptur - Silberschwert
  db:priv_AddDB("RecipesWeaponsmith", 550381);   -- Rezeptur - Verbesserte Seidenklinge
  db:priv_AddDB("RecipesWeaponsmith", 550382);   -- Rezeptur - Seidenklinge
  db:priv_AddDB("RecipesWeaponsmith", 550383);   -- Rezeptur - Verbesserte Flammenklinge
  db:priv_AddDB("RecipesWeaponsmith", 550384);   -- Rezeptur - Flammenklinge
  db:priv_AddDB("RecipesWeaponsmith", 550385);   -- Rezeptur - Klinge des Federrandes
  db:priv_AddDB("RecipesWeaponsmith", 550386);   -- Rezeptur - Schwert des fliegenden Schnees
  db:priv_AddDB("RecipesWeaponsmith", 550387);   -- Rezeptur - Verbesserte Klinge des wei?en Schnees
  db:priv_AddDB("RecipesWeaponsmith", 550388);   -- Rezeptur - Klinge des wei?en Schnees
  db:priv_AddDB("RecipesWeaponsmith", 550389);   -- Rezeptur - Nieten-Holzkn?ppel
  db:priv_AddDB("RecipesWeaponsmith", 550390);   -- Rezeptur - Großer Hartholzhammer
  db:priv_AddDB("RecipesWeaponsmith", 550391);   -- Rezeptur - Verbesserter Sch?delbrecher-Kn?ppel
  db:priv_AddDB("RecipesWeaponsmith", 550392);   -- Rezeptur - Sch?delbrecher-Kn?ppel
  db:priv_AddDB("RecipesWeaponsmith", 550393);   -- Rezeptur - Steinbrecher-Hammer
  db:priv_AddDB("RecipesWeaponsmith", 550394);   -- Rezeptur - Seelent?ter-Hammer
  db:priv_AddDB("RecipesWeaponsmith", 550395);   -- Rezeptur - Verbesserter Hammer des Hüters
  db:priv_AddDB("RecipesWeaponsmith", 550396);   -- Rezeptur - Hammer des Hüters
  db:priv_AddDB("RecipesWeaponsmith", 550397);   -- Rezeptur - Geistt?ter-Hammer
  db:priv_AddDB("RecipesWeaponsmith", 550398);   -- Rezeptur - Riesige Kristall-Silberaxt
  db:priv_AddDB("RecipesWeaponsmith", 550399);   -- Rezeptur - Verbesserte Doppelklingenaxt
  db:priv_AddDB("RecipesWeaponsmith", 550400);   -- Rezeptur - Doppelklingenaxt
  db:priv_AddDB("RecipesWeaponsmith", 550401);   -- Rezeptur - Holzf?ller-Axt
  db:priv_AddDB("RecipesWeaponsmith", 550402);   -- Rezeptur - Axt des wilden Kriegers
  db:priv_AddDB("RecipesWeaponsmith", 550403);   -- Rezeptur - Verbesserte Faltzahn-Axt
  db:priv_AddDB("RecipesWeaponsmith", 550404);   -- Rezeptur - Faltzahn-Axt
  db:priv_AddDB("RecipesWeaponsmith", 550405);   -- Rezeptur - Axt des magischen Siegels
  db:priv_AddDB("RecipesWeaponsmith", 550406);   -- Rezeptur - Schmetterlingsaxt
  db:priv_AddDB("RecipesWeaponsmith", 550407);   -- Rezeptur - Verbesserte Gleve des S?ldners
  db:priv_AddDB("RecipesWeaponsmith", 550409);   -- Rezeptur - Verbessertes zweischneidiges Schwert
  db:priv_AddDB("RecipesWeaponsmith", 550410);   -- Rezeptur - Zweischneidiges Schwert
  db:priv_AddDB("RecipesWeaponsmith", 550411);   -- Rezeptur - Kerimi
  db:priv_AddDB("RecipesWeaponsmith", 550412);   -- Rezeptur - Verbessertes Schwert des Reichsritters
  db:priv_AddDB("RecipesWeaponsmith", 550413);   -- Rezeptur - Schwert des Reichsritters
  db:priv_AddDB("RecipesWeaponsmith", 550414);   -- Rezeptur - Schweres Schwert mit Axtklinge
  db:priv_AddDB("RecipesWeaponsmith", 550415);   -- Rezeptur - Verbessertes schweres Schwert des Ritters
  db:priv_AddDB("RecipesWeaponsmith", 550416);   -- Rezeptur - Schweres Schwert des Ritters
  db:priv_AddDB("RecipesWeaponsmith", 550417);   -- Rezeptur - Verbesserte Gleve des fremden Klans
  db:priv_AddDB("RecipesWeaponsmith", 550418);   -- Rezeptur - Gleve des fremden Klans
  db:priv_AddDB("RecipesWeaponsmith", 550419);   -- Rezeptur - Schwert des Blitzes
  db:priv_AddDB("RecipesWeaponsmith", 550420);   -- Rezeptur - Verbessertes Schwert des Donners
  db:priv_AddDB("RecipesWeaponsmith", 550421);   -- Rezeptur - Schwert des Donners
  db:priv_AddDB("RecipesWeaponsmith", 550422);   -- Rezeptur - Riesiger Bronzehammer
  db:priv_AddDB("RecipesWeaponsmith", 550423);   -- Rezeptur - Kriegshammer
  db:priv_AddDB("RecipesWeaponsmith", 550424);   -- Rezeptur - Verbesserter riesiger Schlachthammer
  db:priv_AddDB("RecipesWeaponsmith", 550425);   -- Rezeptur - Riesiger Schlachthammer
  db:priv_AddDB("RecipesWeaponsmith", 550426);   -- Rezeptur - Verbesserter Feld-Schlachthammer
  db:priv_AddDB("RecipesWeaponsmith", 550427);   -- Rezeptur - Feld-Schlachthammer
  db:priv_AddDB("RecipesWeaponsmith", 550428);   -- Rezeptur - Seelenverschlinger
  db:priv_AddDB("RecipesWeaponsmith", 550429);   -- Rezeptur - Verbesserter Seelenzerst?rer
  db:priv_AddDB("RecipesWeaponsmith", 550430);   -- Rezeptur - Seelenzerst?rer
  db:priv_AddDB("RecipesWeaponsmith", 550790);   -- Rezeptur - Poltings Dolch
  db:priv_AddDB("RecipesWeaponsmith", 550791);   -- Rezeptur - Verbesserter Schlaufengriff-Dolch
  db:priv_AddDB("RecipesWeaponsmith", 550792);   -- Rezeptur - D?nner Dolch
  db:priv_AddDB("RecipesWeaponsmith", 550793);   -- Rezeptur - Drachenstich
  db:priv_AddDB("RecipesWeaponsmith", 550794);   -- Rezeptur - Dolch des roten Drachen
  db:priv_AddDB("RecipesWeaponsmith", 550795);   -- Rezeptur - Verbessertes Kurzschwert des Regens
  db:priv_AddDB("RecipesWeaponsmith", 550796);   -- Rezeptur - Wolkenbruch-Dolch
  db:priv_AddDB("RecipesWeaponsmith", 550797);   -- Rezeptur - Hartmetalldolch
  db:priv_AddDB("RecipesWeaponsmith", 550798);   -- Rezeptur - Verbesserter Hartmetalldolch
  db:priv_AddDB("RecipesWeaponsmith", 550799);   -- Rezeptur - D?monen-Metalldolch
  db:priv_AddDB("RecipesWeaponsmith", 550800);   -- Rezeptur - Wei?e Eisenaxt
  db:priv_AddDB("RecipesWeaponsmith", 550801);   -- Rezeptur - Verbesserte wei?e Eisenaxt
  db:priv_AddDB("RecipesWeaponsmith", 550802);   -- Rezeptur - Pr?chtige Eisenaxt
  db:priv_AddDB("RecipesWeaponsmith", 550803);   -- Rezeptur - Sturmaxt
  db:priv_AddDB("RecipesWeaponsmith", 550804);   -- Rezeptur - Verbesserte Sturmaxt
  db:priv_AddDB("RecipesWeaponsmith", 550805);   -- Rezeptur - Belagerungsaxt
  db:priv_AddDB("RecipesWeaponsmith", 550806);   -- Rezeptur - Angriffsaxt
  db:priv_AddDB("RecipesWeaponsmith", 550807);   -- Rezeptur - Verbesserte gortheanische Streitaxt
  db:priv_AddDB("RecipesWeaponsmith", 550808);   -- Rezeptur - Gortheanische Krieger-Streitaxt
  db:priv_AddDB("RecipesWeaponsmith", 550809);   -- Rezeptur - Verbesserte Kettenaxt
  db:priv_AddDB("RecipesWeaponsmith", 550810);   -- Rezeptur - Sturmkettenaxt
  db:priv_AddDB("RecipesWeaponsmith", 550811);   -- Rezeptur - Breitaxt
  db:priv_AddDB("RecipesWeaponsmith", 550812);   -- Rezeptur - Verbesserte Wut-Breitaxt
  db:priv_AddDB("RecipesWeaponsmith", 550813);   -- Rezeptur - Flugschlag-Streitaxt
  db:priv_AddDB("RecipesWeaponsmith", 550814);   -- Rezeptur - Verbesserte Axt des gefallenen Ritters
  db:priv_AddDB("RecipesWeaponsmith", 550815);   -- Rezeptur - Ritteraxt der dunklen Glorie
  db:priv_AddDB("RecipesWeaponsmith", 550816);   -- Rezeptur - Hartholzschild
  db:priv_AddDB("RecipesWeaponsmith", 550817);   -- Rezeptur - Verbesserter Hartholzschild
  db:priv_AddDB("RecipesWeaponsmith", 550818);   -- Rezeptur - Solider Holzschild
  db:priv_AddDB("RecipesWeaponsmith", 550819);   -- Rezeptur - Verbesserter harter Lederschild
  db:priv_AddDB("RecipesWeaponsmith", 550820);   -- Rezeptur - Solider Lederschild
  db:priv_AddDB("RecipesWeaponsmith", 550821);   -- Rezeptur - Schild aus Mischmaterial
  db:priv_AddDB("RecipesWeaponsmith", 550822);   -- Rezeptur - Verbesserter Schild aus Mischmaterial
  db:priv_AddDB("RecipesWeaponsmith", 550823);   -- Rezeptur - Schild mit Kupferlegierung
  db:priv_AddDB("RecipesWeaponsmith", 550824);   -- Rezeptur - Drachenlederschild
  db:priv_AddDB("RecipesWeaponsmith", 550825);   -- Rezeptur - Silberschild
  db:priv_AddDB("RecipesWeaponsmith", 550826);   -- Rezeptur - Verbesserter Silberschild
  db:priv_AddDB("RecipesWeaponsmith", 550827);   -- Rezeptur - Mondsilberschild
  db:priv_AddDB("RecipesWeaponsmith", 550828);   -- Rezeptur - Verbesserter Bestienhornschild
  db:priv_AddDB("RecipesWeaponsmith", 550829);   -- Rezeptur - Tatens Schild
  db:priv_AddDB("RecipesWeaponsmith", 550831);   -- Rezeptur - Verbesserter Schild der dunklen Glorie
  db:priv_AddDB("RecipesWeaponsmith", 550832);   -- Rezeptur - "Ritter der dunklen Glorie"-Schild
  db:priv_AddDB("RecipesWeaponsmith", 550833);   -- Rezeptur - Verbessertes Schuppenlicht-Schwert
  db:priv_AddDB("RecipesWeaponsmith", 550834);   -- Rezeptur - Aiketas Schwert
  db:priv_AddDB("RecipesWeaponsmith", 550835);   -- Rezeptur - Verbessertes Kapulitonschwert
  db:priv_AddDB("RecipesWeaponsmith", 550836);   -- Rezeptur - Kapuliton-Ritterschwert
  db:priv_AddDB("RecipesWeaponsmith", 550837);   -- Rezeptur - Wellenschwert
  db:priv_AddDB("RecipesWeaponsmith", 550838);   -- Rezeptur - Verbessertes Wellenschwert
  db:priv_AddDB("RecipesWeaponsmith", 550839);   -- Rezeptur - Karols Wellenschwert
  db:priv_AddDB("RecipesWeaponsmith", 550840);   -- Rezeptur - Flammenklinge
  db:priv_AddDB("RecipesWeaponsmith", 550841);   -- Rezeptur - Breitschwert
  db:priv_AddDB("RecipesWeaponsmith", 550842);   -- Rezeptur - Verbessertes Breitschwert
  db:priv_AddDB("RecipesWeaponsmith", 550843);   -- Rezeptur - Darrifs Breitschwert
  db:priv_AddDB("RecipesWeaponsmith", 550844);   -- Rezeptur - Verbesserter Großer Hammer
  db:priv_AddDB("RecipesWeaponsmith", 550845);   -- Rezeptur - Dereks Großer Hammer
  db:priv_AddDB("RecipesWeaponsmith", 550846);   -- Rezeptur - Stahlhammer
  db:priv_AddDB("RecipesWeaponsmith", 550847);   -- Rezeptur - Verbesserter Stahlhammer
  db:priv_AddDB("RecipesWeaponsmith", 550848);   -- Rezeptur - Granathammer
  db:priv_AddDB("RecipesWeaponsmith", 550849);   -- Rezeptur - Knochenfragmentkn?ppel
  db:priv_AddDB("RecipesWeaponsmith", 550850);   -- Rezeptur - Panzerbrecher
  db:priv_AddDB("RecipesWeaponsmith", 550851);   -- Rezeptur - Verbesserter Panzerbrecher
  db:priv_AddDB("RecipesWeaponsmith", 550852);   -- Rezeptur - Panzerbrecher-Keule
  db:priv_AddDB("RecipesWeaponsmith", 550853);   -- Rezeptur - Erdgeisthammer
  db:priv_AddDB("RecipesWeaponsmith", 550854);   -- Rezeptur - Verbesserter Erdgeisthammer
  db:priv_AddDB("RecipesWeaponsmith", 550855);   -- Rezeptur - D?monischer Schlachthammer
  db:priv_AddDB("RecipesWeaponsmith", 550856);   -- Rezeptur - Hammer des wilden Kriegers
  db:priv_AddDB("RecipesWeaponsmith", 550857);   -- Rezeptur - Verbesserter Hammer des wilden Kriegers
  db:priv_AddDB("RecipesWeaponsmith", 550858);   -- Rezeptur - Kems Hammer
  db:priv_AddDB("RecipesWeaponsmith", 550859);   -- Rezeptur - Ochsenknochenkn?ppel
  db:priv_AddDB("RecipesWeaponsmith", 550860);   -- Rezeptur - Verbesserter Ochsenknochenkn?ppel
  db:priv_AddDB("RecipesWeaponsmith", 550861);   -- Rezeptur - Hammer des Minos
  db:priv_AddDB("RecipesWeaponsmith", 550862);   -- Rezeptur - Axt des wilden Mondes
  db:priv_AddDB("RecipesWeaponsmith", 550863);   -- Rezeptur - Verbesserte Holzf?ller-Axt
  db:priv_AddDB("RecipesWeaponsmith", 550864);   -- Rezeptur - Axt des Holzf?llermeisters
  db:priv_AddDB("RecipesWeaponsmith", 550865);   -- Rezeptur - Verbesserte Axt des wilden Kriegers
  db:priv_AddDB("RecipesWeaponsmith", 550866);   -- Rezeptur - Larkis Wurfaxt
  db:priv_AddDB("RecipesWeaponsmith", 550867);   -- Rezeptur - Dornen-Kampfaxt
  db:priv_AddDB("RecipesWeaponsmith", 550868);   -- Rezeptur - Verbesserte Axt des magischen Siegels
  db:priv_AddDB("RecipesWeaponsmith", 550869);   -- Rezeptur - Seelenaxt
  db:priv_AddDB("RecipesWeaponsmith", 550870);   -- Rezeptur - Verbesserte Schmetterlingsaxt
  db:priv_AddDB("RecipesWeaponsmith", 550871);   -- Rezeptur - Tansidya
  db:priv_AddDB("RecipesWeaponsmith", 550872);   -- Rezeptur - Gro?axt
  db:priv_AddDB("RecipesWeaponsmith", 550873);   -- Rezeptur - Verbesserte Gro?axt
  db:priv_AddDB("RecipesWeaponsmith", 550874);   -- Rezeptur - Elite-Gro?axt
  db:priv_AddDB("RecipesWeaponsmith", 550875);   -- Rezeptur - Riesen-Breitschwert
  db:priv_AddDB("RecipesWeaponsmith", 550876);   -- Rezeptur - Schweres Hackmesser
  db:priv_AddDB("RecipesWeaponsmith", 550877);   -- Rezeptur - Verbessertes schweres Hackmesser
  db:priv_AddDB("RecipesWeaponsmith", 550878);   -- Rezeptur - Zweihand-Panzerbrecher
  db:priv_AddDB("RecipesWeaponsmith", 550879);   -- Rezeptur - Riesiges Hexeneisenschwert
  db:priv_AddDB("RecipesWeaponsmith", 550880);   -- Rezeptur - Verbessertes Riesenzauberer-Eisenschwert
  db:priv_AddDB("RecipesWeaponsmith", 550882);   -- Rezeptur - Palten
  db:priv_AddDB("RecipesWeaponsmith", 550883);   -- Rezeptur - Weltenspalter-Schwert
  db:priv_AddDB("RecipesWeaponsmith", 550884);   -- Rezeptur - Verbessertes Weltenspalter-Schwert
  db:priv_AddDB("RecipesWeaponsmith", 550885);   -- Rezeptur - Yalatas Weltenspalter-Schwert
  db:priv_AddDB("RecipesWeaponsmith", 550886);   -- Rezeptur - Verbesserter riesiger Bronzehammer
  db:priv_AddDB("RecipesWeaponsmith", 550887);   -- Rezeptur - Darens wirbelnder Hammer
  db:priv_AddDB("RecipesWeaponsmith", 550888);   -- Rezeptur - Weidenhammer
  db:priv_AddDB("RecipesWeaponsmith", 550889);   -- Rezeptur - Verbesserter Weidenhammer
  db:priv_AddDB("RecipesWeaponsmith", 550890);   -- Rezeptur - Geh?rteter Weidenhammer
  db:priv_AddDB("RecipesWeaponsmith", 550891);   -- Rezeptur - Sarahs Hammer
  db:priv_AddDB("RecipesWeaponsmith", 550892);   -- Rezeptur - Sarahs verbesserter Hammer
  db:priv_AddDB("RecipesWeaponsmith", 550893);   -- Rezeptur - Saradiks Hammer
  db:priv_AddDB("RecipesWeaponsmith", 550894);   -- Rezeptur - Dunkelkristallhammer
  db:priv_AddDB("RecipesWeaponsmith", 550895);   -- Rezeptur - Verbesserter Dunkelkristallhammer
  db:priv_AddDB("RecipesWeaponsmith", 550896);   -- Rezeptur - Dunkelkristall-Ritterhammer
  db:priv_AddDB("RecipesWeaponsmith", 550897);   -- Rezeptur - Titanenhammer
  db:priv_AddDB("RecipesWeaponsmith", 550898);   -- Rezeptur - Barbaren-Schlachthammer
  db:priv_AddDB("RecipesWeaponsmith", 550899);   -- Rezeptur - Silberner Schlachthammer
  db:priv_AddDB("RecipesWeaponsmith", 550900);   -- Rezeptur - Verbesserter silberner Schlachthammer
  db:priv_AddDB("RecipesWeaponsmith", 550901);   -- Rezeptur - Mondsilber-Schlachthammer
  db:priv_AddDB("RecipesWeaponsmith", 550961);   -- Rezeptur - S?bel von Carlow
  db:priv_AddDB("RecipesWeaponsmith", 550962);   -- Rezeptur - Carlows Elites?bel
  db:priv_AddDB("RecipesWeaponsmith", 550963);   -- Rezeptur - Schneidezahn von Kayla
  db:priv_AddDB("RecipesWeaponsmith", 550964);   -- Rezeptur - Blutig-wilder Zahn von Kayla
  db:priv_AddDB("RecipesWeaponsmith", 551026);   -- Rezeptur - Schwarzschwingen-Zahn des Flammendrachen
  db:priv_AddDB("RecipesWeaponsmith", 551027);   -- Rezeptur - Langschwert des Zorns des Flammendrachen
  db:priv_AddDB("RecipesWeaponsmith", 551028);   -- Rezeptur - Verdorbene D?monenklinge des Flammendrachen
  db:priv_AddDB("RecipesWeaponsmith", 551029);   -- Rezeptur - Riesenaxt der Zerst?rung des Flammendrachen
  db:priv_AddDB("RecipesWeaponsmith", 551078);   -- Rezeptur - Einfache Eisentruhe des Anf?ngersch?lers
  db:priv_AddDB("RecipesWeaponsmith", 551079);   -- Rezeptur - Einfache Eisentruhe des Nachwuchssch?lers
  db:priv_AddDB("RecipesWeaponsmith", 551080);   -- Rezeptur - Einfache Eisentruhe des erfahrenen Sch?lers
  db:priv_AddDB("RecipesWeaponsmith", 551081);   -- Rezeptur - Einfache Eisentruhe des Anf?ngerhandwerkers
  db:priv_AddDB("RecipesWeaponsmith", 551082);   -- Rezeptur - Einfache Eisentruhe des Nachwuchshandwerkers
  db:priv_AddDB("RecipesWeaponsmith", 551083);   -- Rezeptur - Einfache Eisentruhe des erfahrenen Handwerkers
  db:priv_AddDB("RecipesWeaponsmith", 551084);   -- Rezeptur - Einfache Eisentruhe des fachkundigen Handwerkers
  db:priv_AddDB("RecipesWeaponsmith", 551086);   -- Rezeptur - Einfache Eisentruhe des erfahrenen Experten
  db:priv_AddDB("RecipesWeaponsmith", 551087);   -- Rezeptur - Einfache Eisentruhe des gebildeten Experten
  db:priv_AddDB("RecipesWeaponsmith", 551088);   -- Rezeptur - Funktionale Eisentruhe des Anf?ngersch?lers
  db:priv_AddDB("RecipesWeaponsmith", 551089);   -- Rezeptur - Funktionale Eisentruhe des Nachwuchssch?lers
  db:priv_AddDB("RecipesWeaponsmith", 551090);   -- Rezeptur - Funktionale Eisentruhe des erfahrenen Sch?lers
  db:priv_AddDB("RecipesWeaponsmith", 551091);   -- Rezeptur - Funktionale Eisentruhe des Anf?ngerhandwerkers
  db:priv_AddDB("RecipesWeaponsmith", 551092);   -- Rezeptur - Funktionale Eisentruhe des Nachwuchshandwerkers
  db:priv_AddDB("RecipesWeaponsmith", 551093);   -- Rezeptur - Funktionale Eisentruhe des erfahrenen Handwerkers
  db:priv_AddDB("RecipesWeaponsmith", 551094);   -- Rezeptur - Funktionale Eisentruhe des fachkundigen Handwerkers
  db:priv_AddDB("RecipesWeaponsmith", 551095);   -- Rezeptur - Funktionale Eisentruhe des Experten
  db:priv_AddDB("RecipesWeaponsmith", 551096);   -- Rezeptur - Funktionale Eisentruhe des erfahrenen Experten
  db:priv_AddDB("RecipesWeaponsmith", 551097);   -- Rezeptur - Funktionale Eisentruhe des gebildeten Experten
  db:priv_AddDB("RecipesWeaponsmith", 551098);   -- Rezeptur - Exquisite Eisentruhe des Anf?ngersch?lers
  db:priv_AddDB("RecipesWeaponsmith", 551099);   -- Rezeptur - Exquisite Eisentruhe des Nachwuchssch?lers
  db:priv_AddDB("RecipesWeaponsmith", 551100);   -- Rezeptur - Exquisite Eisentruhe des erfahrenen Sch?lers
  db:priv_AddDB("RecipesWeaponsmith", 551101);   -- Rezeptur - Exquisite Eisentruhe des Anf?ngerhandwerkers
  db:priv_AddDB("RecipesWeaponsmith", 551102);   -- Rezeptur - Exquisite Eisentruhe des Nachwuchshandwerkers
  db:priv_AddDB("RecipesWeaponsmith", 551103);   -- Rezeptur - Exquisite Eisentruhe des erfahrenen Handwerkers
  db:priv_AddDB("RecipesWeaponsmith", 551104);   -- Rezeptur - Exquisite Eisentruhe des fachkundigen Handwerkers
  db:priv_AddDB("RecipesWeaponsmith", 551105);   -- Rezeptur - Exquisite Eisentruhe des Experten
  db:priv_AddDB("RecipesWeaponsmith", 551106);   -- Rezeptur - Exquisite Eisentruhe des erfahrenen Experten
  db:priv_AddDB("RecipesWeaponsmith", 551107);   -- Rezeptur - Exquisite Eisentruhe des gebildeten Experten
  db:priv_AddDB("RecipesWeaponsmith", 551170);   -- Rezeptur - 
  db:priv_AddDB("RecipesWeaponsmith", 551171);   -- Rezeptur -  
  db:priv_AddDB("RecipesWeaponsmith", 551187);   -- Rezeptur - 

  db:priv_AddDB("RecipesWeaponsmith", 551194);   -- Rezeptur - Dolch des Skorpionk?nigs
  db:priv_AddDB("RecipesWeaponsmith", 551198);   -- Rezeptur - Kibenstys Klinge des Zwangs
  db:priv_AddDB("RecipesWeaponsmith", 551203);   -- Rezeptur - Tadors g?tiger Schild
  db:priv_AddDB("RecipesWeaponsmith", 551205);   -- Rezeptur - Aguars Schwert der Eroberung
  db:priv_AddDB("RecipesWeaponsmith", 551211);   -- Rezeptur - Einfache Forscher-Eisentruhe
  db:priv_AddDB("RecipesWeaponsmith", 551212);   -- Rezeptur - Funktionale Forscher-Eisentruhe
  db:priv_AddDB("RecipesWeaponsmith", 551213);   -- Rezeptur - Exquisite Forscher-Eisentruhe
  db:priv_AddDB("RecipesWeaponsmith", 551229);   -- Rezeptur - Durchdringende Axt
  db:priv_AddDB("RecipesWeaponsmith", 551230);   -- Rezeptur - Keule des trauernden Herzens
  db:priv_AddDB("RecipesWeaponsmith", 551233);   -- Rezeptur - Breitaxt aus geschmiedetem Silber
  db:priv_AddDB("RecipesWeaponsmith", 551234);   -- Rezeptur - Verbesserte durchdringende Axt
  db:priv_AddDB("RecipesWeaponsmith", 551235);   -- Rezeptur - Verbesserte Breitaxt aus geschmiedetem Silber
  db:priv_AddDB("RecipesWeaponsmith", 551239);   -- Rezeptur - Dolch der ziehenden Wolken
  db:priv_AddDB("RecipesWeaponsmith", 551240);   -- Rezeptur - Verbesserter Dolch der ziehenden Wolken
  db:priv_AddDB("RecipesWeaponsmith", 551241);   -- Rezeptur - Dolch der farbigen Wolke
  db:priv_AddDB("RecipesWeaponsmith", 551244);   -- Rezeptur - Sch?delspalter-Axt
  db:priv_AddDB("RecipesWeaponsmith", 551245);   -- Rezeptur - Langschwert der Pracht
  db:priv_AddDB("RecipesWeaponsmith", 551246);   -- Rezeptur - Verbessertes Langschwert der Pracht
  db:priv_AddDB("RecipesWeaponsmith", 551247);   -- Rezeptur - Langschwert der heiligen Glorie
  db:priv_AddDB("RecipesWeaponsmith", 551251);   -- Rezeptur - Spalter des b?sen Geistes
  db:priv_AddDB("RecipesWeaponsmith", 551252);   -- Rezeptur - Verbesserter Spalter des b?sen Geistes
  db:priv_AddDB("RecipesWeaponsmith", 551253);   -- Rezeptur - D?monen-Spalter
  db:priv_AddDB("RecipesWeaponsmith", 551254);   -- Rezeptur - Geschmiedeter Riesenhammer
  db:priv_AddDB("RecipesWeaponsmith", 551255);   -- Rezeptur - Verbesserter geschmiedeter Riesenhammer
  db:priv_AddDB("RecipesWeaponsmith", 551256);   -- Rezeptur - Geschmiedeter Stahl-Riesenhammer
  db:priv_AddDB("RecipesWeaponsmith", 551257);   -- Rezeptur - Verbesserte Keule des trauernden Herzens
  db:priv_AddDB("RecipesWeaponsmith", 551258);   -- Rezeptur - Keule des wahnsinnigen Herzens
  db:priv_AddDB("RecipesWeaponsmith", 551303);   -- Rezeptur - Schild der Pracht
  db:priv_AddDB("RecipesWeaponsmith", 551304);   -- Rezeptur - Verbesserter Schild der Pracht
  db:priv_AddDB("RecipesWeaponsmith", 551305);   -- Rezeptur - Schild der heiligen Glorie
  db:priv_AddDB("RecipesWeaponsmith", 551346);   -- Rezeptur - Funktionale Eisentruhe des Arkanen Experten
  db:priv_AddDB("RecipesWeaponsmith", 551347);   -- Rezeptur - Schöne Eisentruhe des Arkanen Experten
  db:priv_AddDB("RecipesWeaponsmith", 551354);   -- Rezeptur - Hiebaxt
  db:priv_AddDB("RecipesWeaponsmith", 551355);   -- Rezeptur - Hammer des Bestrafers
  db:priv_AddDB("RecipesWeaponsmith", 551358);   -- Rezeptur - St?hlerne Hiebaxt
  db:priv_AddDB("RecipesWeaponsmith", 551360);   -- Rezeptur - Klingenbrecher-Dolch
  db:priv_AddDB("RecipesWeaponsmith", 551361);   -- Rezeptur - Leichte Eisklinge
  db:priv_AddDB("RecipesWeaponsmith", 551363);   -- Rezeptur - Bruchzahn-Breitschwert
  db:priv_AddDB("RecipesWeaponsmith", 551364);   -- Rezeptur - Klobiger Hammer
  db:priv_AddDB("RecipesWeaponsmith", 551379);   -- Rezeptur - Zinnoberschild
  db:priv_AddDB("RecipesWeaponsmith", 551380);   -- Rezeptur - Verbesserte Hiebaxt
  db:priv_AddDB("RecipesWeaponsmith", 551381);   -- Rezeptur - Verbesserter Hammer des Bestrafers
  db:priv_AddDB("RecipesWeaponsmith", 551384);   -- Rezeptur - Verbesserte st?hlerne Hiebaxt
  db:priv_AddDB("RecipesWeaponsmith", 551386);   -- Rezeptur - Verbesserter Klingenbrecher-Dolch
  db:priv_AddDB("RecipesWeaponsmith", 551387);   -- Rezeptur - Verbesserte leichte Eisklinge
  db:priv_AddDB("RecipesWeaponsmith", 551389);   -- Rezeptur - Verbessertes Bruchzahn-Breitschwert
  db:priv_AddDB("RecipesWeaponsmith", 551390);   -- Rezeptur - Verbesserter klobiger Hammer
  db:priv_AddDB("RecipesWeaponsmith", 551457);   -- Rezeptur - Blutbarriere
  db:priv_AddDB("RecipesWeaponsmith", 551483);   -- Rezeptur - Umhang der Freude
  db:priv_AddDB("RecipesWeaponsmith", 551484);   -- Rezeptur - Breitschwert der Burg
  db:priv_AddDB("RecipesWeaponsmith", 551485);   -- Rezeptur - Schwert der Burg
  db:priv_AddDB("RecipesWeaponsmith", 551486);   -- Rezeptur - Gro?axt der Seuche
  db:priv_AddDB("RecipesWeaponsmith", 551487);   -- Rezeptur - Handaxt der Seuche
  db:priv_AddDB("RecipesWeaponsmith", 551488);   -- Rezeptur - Schwerer Hammer des Grabsteins
  db:priv_AddDB("RecipesWeaponsmith", 551489);   -- Rezeptur - Hammer des Grabsteins
  db:priv_AddDB("RecipesWeaponsmith", 551490);   -- Rezeptur - Zirkusmesser
  db:priv_AddDB("RecipesWeaponsmith", 551509);   -- Rezeptur - Verstärkter Schild der Roten Frucht
  db:priv_AddDB("RecipesWeaponsmith", 551510);   -- Rezeptur - Verstärktes Breitschwert der Burg
  db:priv_AddDB("RecipesWeaponsmith", 551511);   -- Rezeptur - Verstärktes Schwert der Burg
  db:priv_AddDB("RecipesWeaponsmith", 551512);   -- Rezeptur - Verstärkte Gro?axt der Seuche
  db:priv_AddDB("RecipesWeaponsmith", 551513);   -- Rezeptur - Verstärkte Handaxt der Seuche
  db:priv_AddDB("RecipesWeaponsmith", 551514);   -- Rezeptur - Verstärkter schwerer Hammer des Grabsteins
  db:priv_AddDB("RecipesWeaponsmith", 551515);   -- Rezeptur - Verstärkter Hammer des Grabsteins
  db:priv_AddDB("RecipesWeaponsmith", 551516);   -- Rezeptur - Verstärktes Zirkusmesser
  db:priv_AddDB("RecipesWeaponsmith", 551535);   -- Rezeptur - Seltener Schild der Roten Frucht
  db:priv_AddDB("RecipesWeaponsmith", 551536);   -- Rezeptur - Seltenes Breitschwert der Burg
  db:priv_AddDB("RecipesWeaponsmith", 551537);   -- Rezeptur - Seltenes Schwert der Burg
  db:priv_AddDB("RecipesWeaponsmith", 551538);   -- Rezeptur - Seltene Gro?axt der Seuche
  db:priv_AddDB("RecipesWeaponsmith", 551539);   -- Rezeptur - Seltene Handaxt der Seuche
  db:priv_AddDB("RecipesWeaponsmith", 551540);   -- Rezeptur - Seltener schwerer Hammer des Grabsteins
  db:priv_AddDB("RecipesWeaponsmith", 551541);   -- Rezeptur - Seltener Hammer des Grabsteins
  db:priv_AddDB("RecipesWeaponsmith", 551548);   -- Rezeptur - Seltenes Zirkusmesser
  db:priv_AddDB("RecipesWeaponsmith", 551567);   -- Rezeptur - Schild des Mysteriums
  db:priv_AddDB("RecipesWeaponsmith", 551568);   -- Rezeptur - Zur?ckgelassenes Breitschwert
  db:priv_AddDB("RecipesWeaponsmith", 551569);   -- Rezeptur - Schwert der Festung
  db:priv_AddDB("RecipesWeaponsmith", 551570);   -- Rezeptur - Gro?axt der giftigen Seuche
  db:priv_AddDB("RecipesWeaponsmith", 551571);   -- Rezeptur - Handaxt der giftigen Seuche
  db:priv_AddDB("RecipesWeaponsmith", 551572);   -- Rezeptur - schwerer Hammer der mysteri?sen Tafel
  db:priv_AddDB("RecipesWeaponsmith", 551573);   -- Rezeptur - Hammer der mysteri?sen Tafel
  db:priv_AddDB("RecipesWeaponsmith", 551574);   -- Rezeptur - Schwarzsumpf-Klinge
  db:priv_AddDB("RecipesWeaponsmith", 551590);   -- Rezeptur - Einfache Eisentruhe des Rätselexperten
  db:priv_AddDB("RecipesWeaponsmith", 551591);   -- Rezeptur - Funktionale Eisentruhe des Rätselexperten
  db:priv_AddDB("RecipesWeaponsmith", 551592);   -- Rezeptur - Exquisite Eisentruhe des Rätselexperten
  db:priv_AddDB("RecipesWeaponsmith", 551652);   -- Rezeptur - M?chtiger epischer Schild
  db:priv_AddDB("RecipesWeaponsmith", 551661);   -- Rezeptur - Aquamarin-Arbeitsschwert
  db:priv_AddDB("RecipesWeaponsmith", 551662);   -- Rezeptur - Orangefarbene Schnitzklinge
  db:priv_AddDB("RecipesWeaponsmith", 551663);   -- Rezeptur - Redda-Messer
  db:priv_AddDB("RecipesWeaponsmith", 551664);   -- Rezeptur - Gewellte Purpuraxt
  db:priv_AddDB("RecipesWeaponsmith", 551665);   -- Rezeptur - Schmetterlingskupferaxt
  db:priv_AddDB("RecipesWeaponsmith", 551666);   -- Rezeptur - Werkzeughammer
  db:priv_AddDB("RecipesWeaponsmith", 551667);   -- Rezeptur - Gr?ner Eissteinhammer
  db:priv_AddDB("RecipesWeaponsmith", 551668);   -- Rezeptur - Blutzahnschwert
  db:priv_AddDB("RecipesWeaponsmith", 551669);   -- Rezeptur - Wellen-Stilett
  db:priv_AddDB("RecipesWeaponsmith", 551670);   -- Rezeptur - Spinnaker-Messer
  db:priv_AddDB("RecipesWeaponsmith", 551671);   -- Rezeptur - Elfenbein-Handaxt
  db:priv_AddDB("RecipesWeaponsmith", 551672);   -- Rezeptur - H?llengewebe-Breitaxt
  db:priv_AddDB("RecipesWeaponsmith", 551673);   -- Rezeptur - Goldfass-Hammer
  db:priv_AddDB("RecipesWeaponsmith", 551674);   -- Rezeptur - Hammer der Atome
  db:priv_AddDB("RecipesWeaponsmith", 551675);   -- Rezeptur - Handwerker-Zahnschwert
  db:priv_AddDB("RecipesWeaponsmith", 551676);   -- Rezeptur - Hemming-Schwert
  db:priv_AddDB("RecipesWeaponsmith", 551677);   -- Rezeptur - Mantz-Messer
  db:priv_AddDB("RecipesWeaponsmith", 551679);   -- Rezeptur - Handwerks-Streitaxt
  db:priv_AddDB("RecipesWeaponsmith", 551680);   -- Rezeptur - Asja-Hammer
  db:priv_AddDB("RecipesWeaponsmith", 551681);   -- Rezeptur - Jade-Streithammer
  db:priv_AddDB("RecipesWeaponsmith", 551682);   -- Rezeptur - Purpurnes Seelenw?chterschwert
  db:priv_AddDB("RecipesWeaponsmith", 551683);   -- Rezeptur - Sternenstaub-Multiklinge
  db:priv_AddDB("RecipesWeaponsmith", 551684);   -- Rezeptur - Dur-Handwerkerdolch
  db:priv_AddDB("RecipesWeaponsmith", 551685);   -- Rezeptur - Geometrische Rosenaxt
  db:priv_AddDB("RecipesWeaponsmith", 551686);   -- Rezeptur - Fertigungshandwerks-Schlachtenaxt
  db:priv_AddDB("RecipesWeaponsmith", 551687);   -- Rezeptur - Originaler Felsbrockenhammer
  db:priv_AddDB("RecipesWeaponsmith", 551688);   -- Rezeptur - Ornament-Rosenhammer
  db:priv_AddDB("RecipesWeaponsmith", 551731);   -- Rezeptur - Einfache Eisentruhe des fachkundigen Handwerks
  db:priv_AddDB("RecipesWeaponsmith", 551732);   -- Rezeptur - Funktionale Eisentruhe des fachkundigen Handwerks
  db:priv_AddDB("RecipesWeaponsmith", 551733);   -- Rezeptur - Exquisite Eisentruhe des fachkundigen Handwerks
  db:priv_AddDB("RecipesWeaponsmith", 551748);   -- Rezeptur - Vollkommene einfache Eisentruhe des Experten
  db:priv_AddDB("RecipesWeaponsmith", 551749);   -- Rezeptur - Vollkommene funktionale Eisentruhe des Experten
  db:priv_AddDB("RecipesWeaponsmith", 551750);   -- Rezeptur - Vollkommene exquisite Eisentruhe des Experten
  db:priv_AddDB("RecipesWeaponsmith", 551786);   -- Rezeptur - Schild der Kalon
  db:priv_AddDB("RecipesWeaponsmith", 551787);   -- Rezeptur - Breitschwert des Streits
  db:priv_AddDB("RecipesWeaponsmith", 551788);   -- Rezeptur - Schwert des Verbrechens
  db:priv_AddDB("RecipesWeaponsmith", 551789);   -- Rezeptur - Riesige Axt des Verbrechens
  db:priv_AddDB("RecipesWeaponsmith", 551790);   -- Rezeptur - Handaxt des Streits
  db:priv_AddDB("RecipesWeaponsmith", 551791);   -- Rezeptur - Schwerer Hammer der Rebellion
  db:priv_AddDB("RecipesWeaponsmith", 551792);   -- Rezeptur - Hammer der R?ckkehr
  db:priv_AddDB("RecipesWeaponsmith", 551793);   -- Rezeptur - Finsterer Dolch
  db:priv_AddDB("RecipesWeaponsmith", 551812);   -- Rezeptur - Verstärkter Schild der Kalon
  db:priv_AddDB("RecipesWeaponsmith", 551813);   -- Rezeptur - Verstärktes Breitschwert des Streits
  db:priv_AddDB("RecipesWeaponsmith", 551814);   -- Rezeptur - Verstärktes Schwert des Verbrechens
  db:priv_AddDB("RecipesWeaponsmith", 551815);   -- Rezeptur - Verstärkte riesige Axt des Verbrechens
  db:priv_AddDB("RecipesWeaponsmith", 551816);   -- Rezeptur - Verstärkte Handaxt des Streits
  db:priv_AddDB("RecipesWeaponsmith", 551817);   -- Rezeptur - Verstärkter schwerer Hammer der Rebellion
  db:priv_AddDB("RecipesWeaponsmith", 551818);   -- Rezeptur - Verstärkter Hammer der R?ckkehr
  db:priv_AddDB("RecipesWeaponsmith", 551819);   -- Rezeptur - Verstärkter finsterer Dolch
  db:priv_AddDB("RecipesWeaponsmith", 551838);   -- Rezeptur - Seltener Schild der Kalon
  db:priv_AddDB("RecipesWeaponsmith", 551839);   -- Rezeptur - Seltenes Breitschwert des Streits
  db:priv_AddDB("RecipesWeaponsmith", 551840);   -- Rezeptur - Seltenes Schwert des Verbrechens
  db:priv_AddDB("RecipesWeaponsmith", 551841);   -- Rezeptur - Seltene riesige Axt des Verbrechens
  db:priv_AddDB("RecipesWeaponsmith", 551842);   -- Rezeptur - Seltene Handaxt des Streits
  db:priv_AddDB("RecipesWeaponsmith", 551843);   -- Rezeptur - Seltener schwerer Hammer der Rebellion
  db:priv_AddDB("RecipesWeaponsmith", 551844);   -- Rezeptur - Seltener Hammer der R?ckkehr
  db:priv_AddDB("RecipesWeaponsmith", 551845);   -- Rezeptur - Seltener finsterer Dolch
  db:priv_AddDB("RecipesWeaponsmith", 551864);   -- Rezeptur - Großer bewahrender Schild
  db:priv_AddDB("RecipesWeaponsmith", 551865);   -- Rezeptur - Breitschwert der Invasion
  db:priv_AddDB("RecipesWeaponsmith", 551866);   -- Rezeptur - Kurzschwert des Trotzes
  db:priv_AddDB("RecipesWeaponsmith", 551867);   -- Rezeptur - Riesige Axt der Invasion
  db:priv_AddDB("RecipesWeaponsmith", 551868);   -- Rezeptur - Axt des Trotzes
  db:priv_AddDB("RecipesWeaponsmith", 551869);   -- Rezeptur - Hammer der Zerst?rung
  db:priv_AddDB("RecipesWeaponsmith", 551870);   -- Rezeptur - Kleiner Hammer der List
  db:priv_AddDB("RecipesWeaponsmith", 551871);   -- Rezeptur - Dolch der Invasion
  db:priv_AddDB("RecipesWeaponsmith", 551877);   -- Rezeptur - 
 
  db:priv_AddDB("RecipesWeaponsmith", 551879);   -- Rezeptur - Transformiertes Langschwert des Nex von Enoch
  db:priv_AddDB("RecipesWeaponsmith", 551925);   -- Rezeptur - Gro?schild des Schicksals
  db:priv_AddDB("RecipesWeaponsmith", 551926);   -- Rezeptur - Riesiges Schwert des Schicksals
  db:priv_AddDB("RecipesWeaponsmith", 551927);   -- Rezeptur - Schwert der Versorgung
  db:priv_AddDB("RecipesWeaponsmith", 551928);   -- Rezeptur - Große Axt der Versorgung
  db:priv_AddDB("RecipesWeaponsmith", 551929);   -- Rezeptur - Handaxt des Schicksals
  db:priv_AddDB("RecipesWeaponsmith", 551930);   -- Rezeptur - Schwerer Hammer der Zuflucht
  db:priv_AddDB("RecipesWeaponsmith", 551931);   -- Rezeptur - Hammer des Gesandten
  db:priv_AddDB("RecipesWeaponsmith", 551932);   -- Rezeptur - Dolch des Gesandten
  db:priv_AddDB("RecipesWeaponsmith", 551951);   -- Rezeptur - Verbesserter Gro?schild des Schicksals
  db:priv_AddDB("RecipesWeaponsmith", 551952);   -- Rezeptur - Verbessertes Breitschwert des Schicksals
  db:priv_AddDB("RecipesWeaponsmith", 551953);   -- Rezeptur - Verbessertes Schwert der Versorgung
  db:priv_AddDB("RecipesWeaponsmith", 551954);   -- Rezeptur - Verbesserte Große Axt der Versorgung
  db:priv_AddDB("RecipesWeaponsmith", 551955);   -- Rezeptur - Verbesserte Handaxt des Schicksals
  db:priv_AddDB("RecipesWeaponsmith", 551956);   -- Rezeptur - Verbesserter Schwerer Hammer der Zuflucht
  db:priv_AddDB("RecipesWeaponsmith", 551957);   -- Rezeptur - Verbesserter Hammer des Gesandten
  db:priv_AddDB("RecipesWeaponsmith", 551958);   -- Rezeptur - Verbesserter Dolch des Gesandten
  db:priv_AddDB("RecipesWeaponsmith", 551992);   -- Rezeptur - Seltener Gro?schild des Schicksals
  db:priv_AddDB("RecipesWeaponsmith", 551993);   -- Rezeptur - Seltenes Riesiges Schwert des Schicksals
  db:priv_AddDB("RecipesWeaponsmith", 551994);   -- Rezeptur - Seltenes Schwert der Versorgung
  db:priv_AddDB("RecipesWeaponsmith", 551995);   -- Rezeptur - Seltene Große Axt der Versorgung
  db:priv_AddDB("RecipesWeaponsmith", 551996);   -- Rezeptur - Seltene Handaxt des Schicksals
  db:priv_AddDB("RecipesWeaponsmith", 551997);   -- Rezeptur - Seltener Schwerer Hammer der Zuflucht
  db:priv_AddDB("RecipesWeaponsmith", 551998);   -- Rezeptur - Seltener Hammer des Gesandten
  db:priv_AddDB("RecipesWeaponsmith", 551999);   -- Rezeptur - Seltener Dolch des Gesandten
  db:priv_AddDB("RecipesWeaponsmith", 552018);   -- Rezeptur - Gro?schild des wahren Drachen
  db:priv_AddDB("RecipesWeaponsmith", 552019);   -- Rezeptur - Breitschwert des wahren Drachen
  db:priv_AddDB("RecipesWeaponsmith", 552020);   -- Rezeptur - Kurzschwert der Heimlichkeit
  db:priv_AddDB("RecipesWeaponsmith", 552021);   -- Rezeptur - Große Axt der Hemmnis
  db:priv_AddDB("RecipesWeaponsmith", 552022);   -- Rezeptur - Axt der Heimlichkeit
  db:priv_AddDB("RecipesWeaponsmith", 552023);   -- Rezeptur - Hammer der Hemmnis
  db:priv_AddDB("RecipesWeaponsmith", 552024);   -- Rezeptur - Kleiner Hammer der Elfe
  db:priv_AddDB("RecipesWeaponsmith", 552025);   -- Rezeptur - Dolch der Hemmnis
  db:priv_AddDB("RecipesWeaponsmith", 552043);   -- Rezeptur - Große einfache Eisentruhe des Novizen
  db:priv_AddDB("RecipesWeaponsmith", 552044);   -- Rezeptur - Große funktionale Eisentruhe des Novizen
  db:priv_AddDB("RecipesWeaponsmith", 552045);   -- Rezeptur - Große exquisite Eisentruhe des Novizen
  db:priv_AddDB("RecipesWeaponsmith", 552046);   -- Rezeptur - Große einfache Eisentruhe des Fortgeschrittenen
  db:priv_AddDB("RecipesWeaponsmith", 552047);   -- Rezeptur - Große funktionale Eisentruhe des Fortgeschrittenen
  db:priv_AddDB("RecipesWeaponsmith", 552048);   -- Rezeptur - Große exquisite Eisentruhe des Fortgeschrittenen
  db:priv_AddDB("RecipesWeaponsmith", 552049);   -- Rezeptur - Große einfache Eisentruhe des Erhabenen
  db:priv_AddDB("RecipesWeaponsmith", 552050);   -- Rezeptur - Große funktionale Eisentruhe des Erhabenen
  db:priv_AddDB("RecipesWeaponsmith", 552051);   -- Rezeptur - Große exquisite Eisentruhe des Erhabenen
  db:priv_AddDB("RecipesWeaponsmith", 552114);   -- Rezeptur - Großer Windklippenschild
  db:priv_AddDB("RecipesWeaponsmith", 552117);   -- Rezeptur - Riesenschwert des Gemetzels
  db:priv_AddDB("RecipesWeaponsmith", 552118);   -- Rezeptur - Schwert der Legende
  db:priv_AddDB("RecipesWeaponsmith", 552119);   -- Rezeptur - Gr?ne Narbenaxt
  db:priv_AddDB("RecipesWeaponsmith", 552120);   -- Rezeptur - Streitaxt des Todesschwurs
  db:priv_AddDB("RecipesWeaponsmith", 552121);   -- Rezeptur - Gro?hammer des heftigen Angriffs
  db:priv_AddDB("RecipesWeaponsmith", 552122);   -- Rezeptur - Knochenbrecherhammer
  db:priv_AddDB("RecipesWeaponsmith", 552124);   -- Rezeptur - Wellendolch
  db:priv_AddDB("RecipesWeaponsmith", 552140);   -- Rezeptur - Verbesserter Großer Windklippenschild
  db:priv_AddDB("RecipesWeaponsmith", 552143);   -- Rezeptur - Verbessertes Riesenschwert des Gemetzels
  db:priv_AddDB("RecipesWeaponsmith", 552144);   -- Rezeptur - Verbessertes Schwert der Legende
  db:priv_AddDB("RecipesWeaponsmith", 552145);   -- Rezeptur - Verbesserte gr?ne Narbenaxt
  db:priv_AddDB("RecipesWeaponsmith", 552146);   -- Rezeptur - Verbesserte Streitaxt des Todesschwurs
  db:priv_AddDB("RecipesWeaponsmith", 552147);   -- Rezeptur - Verbesserter Gro?hammer des heftigen Angriffs
  db:priv_AddDB("RecipesWeaponsmith", 552148);   -- Rezeptur - Verbesserter Knochenbrecherhammer
  db:priv_AddDB("RecipesWeaponsmith", 552150);   -- Rezeptur - Verbesserter Wellendolch
  db:priv_AddDB("RecipesWeaponsmith", 552166);   -- Rezeptur - Seltener Großer Windklippenschild
  db:priv_AddDB("RecipesWeaponsmith", 552169);   -- Rezeptur - Seltenes Riesenschwert des Gemetzels
  db:priv_AddDB("RecipesWeaponsmith", 552170);   -- Rezeptur - Seltenes Schwert der Legende
  db:priv_AddDB("RecipesWeaponsmith", 552171);   -- Rezeptur - Seltene gr?ne Narbenaxt
  db:priv_AddDB("RecipesWeaponsmith", 552172);   -- Rezeptur - Seltene Streitaxt des Todesschwurs
  db:priv_AddDB("RecipesWeaponsmith", 552173);   -- Rezeptur - Seltener Gro?hammer des heftigen Angriffs
  db:priv_AddDB("RecipesWeaponsmith", 552174);   -- Rezeptur - Seltener Knochenbrecherhammer
  db:priv_AddDB("RecipesWeaponsmith", 552176);   -- Rezeptur - Seltener Wellendolch
  db:priv_AddDB("RecipesWeaponsmith", 552180);   -- Rezeptur - Heiliges Kreuzschwert
  db:priv_AddDB("RecipesWeaponsmith", 552181);   -- Rezeptur - Schwere Goldaxt
  db:priv_AddDB("RecipesWeaponsmith", 552182);   -- Rezeptur - Riesiger Sch?delhammer
  db:priv_AddDB("RecipesWeaponsmith", 552184);   -- Rezeptur - Kupferdornendolch
  db:priv_AddDB("RecipesWeaponsmith", 552203);   -- Rezeptur - Verbessertes heiliges Kreuzschwert
  db:priv_AddDB("RecipesWeaponsmith", 552204);   -- Rezeptur - Verbesserte schwere Goldaxt
  db:priv_AddDB("RecipesWeaponsmith", 552205);   -- Rezeptur - Verbesserter riesiger Sch?delhammer
  db:priv_AddDB("RecipesWeaponsmith", 552207);   -- Rezeptur - Verbesserter Kupferdornendolch
  db:priv_AddDB("RecipesWeaponsmith", 552226);   -- Rezeptur - Seltenes heiliges Kreuzschwert
  db:priv_AddDB("RecipesWeaponsmith", 552227);   -- Rezeptur - Seltene schwere Goldaxt
  db:priv_AddDB("RecipesWeaponsmith", 552228);   -- Rezeptur - Seltener riesiger Sch?delhammer
  db:priv_AddDB("RecipesWeaponsmith", 552230);   -- Rezeptur - Seltener Kupferdornendolch
  db:priv_AddDB("RecipesWeaponsmith", 552249);   -- Rezeptur - Magieknochen des Transformierten Lindwurms
  db:priv_AddDB("RecipesWeaponsmith", 552250);   -- Rezeptur - Riesenaxt des Transformierten Fayleod
  db:priv_AddDB("RecipesWeaponsmith", 552251);   -- Rezeptur - Eisenlicht des Transformierten Tatha
  db:priv_AddDB("RecipesWeaponsmith", 552253);   -- Rezeptur - Klaue des Transformierten Sandos
  db:priv_AddDB("RecipesWeaponsmith", 552289);   -- Rezeptur - Eisentruhe des Rätsels
  db:priv_AddDB("RecipesWeaponsmith", 552421);   -- Rezeptur - Saatchis Riesenschwert
  db:priv_AddDB("RecipesWeaponsmith", 552422);   -- Rezeptur - Handaxt des heiligen Siegels
  db:priv_AddDB("RecipesWeaponsmith", 552423);   -- Rezeptur - Quadratischer Siegelhammer
  db:priv_AddDB("RecipesWeaponsmith", 552427);   -- Rezeptur - Saatchis verbessertes Riesenschwert
  db:priv_AddDB("RecipesWeaponsmith", 552428);   -- Rezeptur - Verbesserte Handaxt des heiligen Siegels
  db:priv_AddDB("RecipesWeaponsmith", 552429);   -- Rezeptur - Verbesserter quadratischer Siegelhammer
  db:priv_AddDB("RecipesWeaponsmith", 552433);   -- Rezeptur - Saatchis seltenes Riesenschwert
  db:priv_AddDB("RecipesWeaponsmith", 552434);   -- Rezeptur - Seltene Handaxt des heiligen Siegels
  db:priv_AddDB("RecipesWeaponsmith", 552435);   -- Rezeptur - Seltener quadratischer Siegelhammer
  db:priv_AddDB("RecipesWeaponsmith", 552439);   -- Rezeptur - Transformiertes schweres Obeliskenschwert
  db:priv_AddDB("RecipesWeaponsmith", 552440);   -- Rezeptur - Transformierte K?nigliche Bestrafung
  db:priv_AddDB("RecipesWeaponsmith", 552441);   -- Rezeptur - Transformierter riesiger TraumlandSchl?ssel
  db:priv_AddDB("RecipesWeaponsmith", 552461);   -- Rezeptur - Schild des b?sen Fledermausfl?gels
  db:priv_AddDB("RecipesWeaponsmith", 552479);   -- Rezeptur - Verbesserter Schild des b?sen Fledermausfl?gels
  db:priv_AddDB("RecipesWeaponsmith", 552497);   -- Rezeptur - Seltener Schild des b?sen Fledermausfl?gels
  db:priv_AddDB("RecipesWeaponsmith", 552523);   -- Rezeptur - Schild des transformierten W?chters
  db:priv_AddDB("RecipesWeaponsmith", 552524);   -- Rezeptur - Schild des transformierten starken Throns
  db:priv_AddDB("RecipesWeaponsmith", 552526);   -- Rezeptur - Runeneisentruhe
  db:priv_AddDB("RecipesWeaponsmith", 552560);   -- Rezeptur - Schwert der tausend Steinaugen
  db:priv_AddDB("RecipesWeaponsmith", 552561);   -- Rezeptur - Handaxt des Feynawaldes
  db:priv_AddDB("RecipesWeaponsmith", 552562);   -- Rezeptur - Riesenhammer von Zindkar
  db:priv_AddDB("RecipesWeaponsmith", 552564);   -- Rezeptur - M?rderdolch von Modersturm
  db:priv_AddDB("RecipesWeaponsmith", 552567);   -- Rezeptur - Verbessertes Schwert der tausend Steinaugen
  db:priv_AddDB("RecipesWeaponsmith", 552568);   -- Rezeptur - Verbesserte Handaxt des Feynawaldes
  db:priv_AddDB("RecipesWeaponsmith", 552569);   -- Rezeptur - Verbesserter Riesenhammer von Zindkar
  db:priv_AddDB("RecipesWeaponsmith", 552571);   -- Rezeptur - Verbesserter M?rderdolch von Modersturm
  db:priv_AddDB("RecipesWeaponsmith", 552574);   -- Rezeptur - Seltenes Schwert der tausend Steinaugen
  db:priv_AddDB("RecipesWeaponsmith", 552575);   -- Rezeptur - Seltene Handaxt des Feynawaldes
  db:priv_AddDB("RecipesWeaponsmith", 552576);   -- Rezeptur - Seltener Riesenhammer von Zindkar
  db:priv_AddDB("RecipesWeaponsmith", 552578);   -- Rezeptur - Seltener M?rderdolch von Modersturm
  db:priv_AddDB("RecipesWeaponsmith", 552581);   -- Rezeptur - Transformiertes Schwert der Verzweiflung
  db:priv_AddDB("RecipesWeaponsmith", 552582);   -- Rezeptur - Transformierte Riesenstahlaxt der Leere
  db:priv_AddDB("RecipesWeaponsmith", 552583);   -- Rezeptur - Transformierter Riesenhammer von Poseidon
  db:priv_AddDB("RecipesWeaponsmith", 552585);   -- Rezeptur - Transformierte Folterklinge
  db:priv_AddDB("RecipesWeaponsmith", 552660);   -- Rezeptur - Geheimnisvolle Eisentruhe
  db:priv_AddDB("RecipesWeaponsmith", 552680);   -- Rezeptur - Riesenschwert des Schiffsfriedhofs der Riesenmasten
  db:priv_AddDB("RecipesWeaponsmith", 552681);   -- Rezeptur - Handaxt des gierigen Sumpfs
  db:priv_AddDB("RecipesWeaponsmith", 552682);   -- Rezeptur - Leichter Kriegerhammer der Behemothspitze
  db:priv_AddDB("RecipesWeaponsmith", 552686);   -- Rezeptur - Verbessertes Riesenschwert des Schiffsfriedhofs der Riesenmasten
  db:priv_AddDB("RecipesWeaponsmith", 552687);   -- Rezeptur - Verbesserte Handaxt des gierigen Sumpfs
  db:priv_AddDB("RecipesWeaponsmith", 552688);   -- Rezeptur - Verbesserter leichter Kriegerhammer der Behemothspitze
  db:priv_AddDB("RecipesWeaponsmith", 552692);   -- Rezeptur - Seltenes Riesenschwert des Schiffsfriedhofs der Riesenmasten
  db:priv_AddDB("RecipesWeaponsmith", 552693);   -- Rezeptur - Seltene Handaxt des gierigen Sumpfs
  db:priv_AddDB("RecipesWeaponsmith", 552694);   -- Rezeptur - Seltener leichter Kriegerhammer der Behemothspitze
  db:priv_AddDB("RecipesWeaponsmith", 552698);   -- Rezeptur - Transformierte Riesenklinge der Resonanz
  db:priv_AddDB("RecipesWeaponsmith", 552699);   -- Rezeptur - Transformierte Handaxt des Tornados
  db:priv_AddDB("RecipesWeaponsmith", 552700);   -- Rezeptur - Transformierter leichter Angriffshammer
  db:priv_AddDB("RecipesWeaponsmith", 552720);   -- Rezeptur - Tapatapa-Schild
  db:priv_AddDB("RecipesWeaponsmith", 552738);   -- Rezeptur - Verbesserter Tapatapa-Schild
  db:priv_AddDB("RecipesWeaponsmith", 552756);   -- Rezeptur - Seltener Tapatapa-Schild
  db:priv_AddDB("RecipesWeaponsmith", 552782);   -- Rezeptur - Transformierter Schild der Heiligen Klangschale
  db:priv_AddDB("RecipesWeaponsmith", 552783);   -- Rezeptur - Transformierter Schild der Heilung
  db:priv_AddDB("RecipesWeaponsmith", 552800);   -- Rezeptur - Geh?rtete Eisentruhe
  db:priv_AddDB("RecipesWeaponsmith", 552804);   -- Rezeptur - Meisterhafte Eisentruhe
  db:priv_AddDB("RecipesWeaponsmith", 552818);   -- Rezeptur - Legend?re Eisentruhe
  db:priv_AddDB("RecipesWeaponsmith", 552822);   -- Rezeptur - Ultimative Eisentruhe
  db:priv_AddDB("RecipesWeaponsmith", 552836);   -- Rezeptur - Himmlische Eisentruhe
  db:priv_AddDB("RecipesWeaponsmith", 552840);   -- Rezeptur - G?ttliche Eisentruhe
  db:priv_AddDB("RecipesWeaponsmith", 552899);   -- Rezeptur - Magieschwert des Schiffs des Urpsrungs
  db:priv_AddDB("RecipesWeaponsmith", 552900);   -- Rezeptur - Riesenaxt der Nebelschwaden
  db:priv_AddDB("RecipesWeaponsmith", 552901);   -- Rezeptur - Schwerer Hammer der Schwarznestebene
  db:priv_AddDB("RecipesWeaponsmith", 552903);   -- Rezeptur - Klinge der Obhut des Wassers
  db:priv_AddDB("RecipesWeaponsmith", 552906);   -- Rezeptur - Verbessertes Magieschwert des Schiffs des Urpsrungs
  db:priv_AddDB("RecipesWeaponsmith", 552907);   -- Rezeptur - Verbesserte Riesenaxt der Nebelschwaden
  db:priv_AddDB("RecipesWeaponsmith", 552908);   -- Rezeptur - Verbesserter Schwerer Hammer der Schwarznestebene
  db:priv_AddDB("RecipesWeaponsmith", 552910);   -- Rezeptur - Verbesserte Klinge der Obhut des Wassers
  db:priv_AddDB("RecipesWeaponsmith", 552913);   -- Rezeptur - Seltenes Magieschwert des Schiffs des Urpsrungs
  db:priv_AddDB("RecipesWeaponsmith", 552914);   -- Rezeptur - Seltene Riesenaxt der Nebelschwaden
  db:priv_AddDB("RecipesWeaponsmith", 552915);   -- Rezeptur - Seltener Schwerer Hammer der Schwarznestebene
  db:priv_AddDB("RecipesWeaponsmith", 552917);   -- Rezeptur - Seltene Klinge der Obhut des Wassers
  db:priv_AddDB("RecipesWeaponsmith", 552920);   -- Rezeptur - Transformierte Runenklinge
  db:priv_AddDB("RecipesWeaponsmith", 552921);   -- Rezeptur - Transformierte Riesenstahlaxt
  db:priv_AddDB("RecipesWeaponsmith", 552922);   -- Rezeptur - Transformierter Mystischer Massivhammer
  db:priv_AddDB("RecipesWeaponsmith", 552924);   -- Rezeptur - Transformierte Dornenklinge
  db:priv_AddDB("RecipesWeaponsmith", 552943);   -- Rezeptur - Jadeschild
  db:priv_AddDB("RecipesWeaponsmith", 552961);   -- Rezeptur - Verbessertes Jadeschild
  db:priv_AddDB("RecipesWeaponsmith", 552979);   -- Rezeptur - Seltenes Jadeschild
  db:priv_AddDB("RecipesWeaponsmith", 553005);   -- Rezeptur - Transformierter Sturmschild
  db:priv_AddDB("RecipesWeaponsmith", 553006);   -- Rezeptur - Transformierter Windschild
  db:priv_AddDB("RecipesWeaponsmith", 553008);   -- Rezeptur - 
  db:priv_AddDB("RecipesWeaponsmith", 553009);   -- Rezeptur - 

  
  db:priv_AddDB("RecipesWeaponsmith", 553011);   -- Rezeptur - 
  
  db:priv_AddDB("RecipesWeaponsmith", 553014);   -- Rezeptur - Verfluchtes Riesenschwert
  db:priv_AddDB("RecipesWeaponsmith", 553015);   -- Rezeptur - Verfluchte Handaxt
  db:priv_AddDB("RecipesWeaponsmith", 553016);   -- Rezeptur - Leichter flammenge?tzter Hammer
  db:priv_AddDB("RecipesWeaponsmith", 553020);   -- Rezeptur - Verbessertes verfluchtes Riesenschwert
  db:priv_AddDB("RecipesWeaponsmith", 553021);   -- Rezeptur - Verbesserte verfluchte Handaxt
  db:priv_AddDB("RecipesWeaponsmith", 553022);   -- Rezeptur - Verbesserter leichter flammenge?tzter Hammer
  db:priv_AddDB("RecipesWeaponsmith", 553026);   -- Rezeptur - Seltenes verfluchtes Riesenschwert
  db:priv_AddDB("RecipesWeaponsmith", 553028);   -- Rezeptur - Seltener leichter flammenge?tzter Hammer
  db:priv_AddDB("RecipesWeaponsmith", 553032);   -- Rezeptur - Transformierte Klinge der Unbesiegbarkeit
  db:priv_AddDB("RecipesWeaponsmith", 553033);   -- Rezeptur - Transformierte Elitehandaxt
  db:priv_AddDB("RecipesWeaponsmith", 553034);   -- Rezeptur - Transformierter leichter Hammer des Wutkampfs
  db:priv_AddDB("RecipesWeaponsmith", 553054);   -- Rezeptur - Schild der Sehnsucht
  db:priv_AddDB("RecipesWeaponsmith", 553072);   -- Rezeptur - Verstärkter Schild der Sehnsucht
  db:priv_AddDB("RecipesWeaponsmith", 553090);   -- Rezeptur - Seltener Schild der Sehnsucht
  db:priv_AddDB("RecipesWeaponsmith", 553116);   -- Rezeptur - Transformierter Stahlschild
  db:priv_AddDB("RecipesWeaponsmith", 553117);   -- Rezeptur - Transformierter Schild der Verst?rkung
  db:priv_AddDB("RecipesWeaponsmith", 553119);   -- Rezeptur - Armeeklinge des Eisenschwingenpostens
  db:priv_AddDB("RecipesWeaponsmith", 553120);   -- Rezeptur - Pferdekopfbeil der Zwielichtigen Grotte
  db:priv_AddDB("RecipesWeaponsmith", 553121);   -- Rezeptur - Goldhammer des Crohnhofes
  db:priv_AddDB("RecipesWeaponsmith", 553123);   -- Rezeptur - Runddolch vom S?dweidenhof
  db:priv_AddDB("RecipesWeaponsmith", 553126);   -- Rezeptur - Verbesserte Armeeklinge des Eisenschwingenpostens
  db:priv_AddDB("RecipesWeaponsmith", 553127);   -- Rezeptur - Verbessertes Pferdekopfbeil der Zwielichtigen Grotte
  db:priv_AddDB("RecipesWeaponsmith", 553128);   -- Rezeptur - Verbesserter Goldhammer des Crohnhofes
  db:priv_AddDB("RecipesWeaponsmith", 553130);   -- Rezeptur - Verbesserter Runddolch vom S?dweidenhof
  db:priv_AddDB("RecipesWeaponsmith", 553133);   -- Rezeptur - Seltene Armeeklinge des Eisenschwingenpostens
  db:priv_AddDB("RecipesWeaponsmith", 553134);   -- Rezeptur - Seltenes Pferdekopfbeil der Zwielichtigen Grotte
  db:priv_AddDB("RecipesWeaponsmith", 553135);   -- Rezeptur - Seltener Goldhammer des Crohnhofes
  db:priv_AddDB("RecipesWeaponsmith", 553137);   -- Rezeptur - Seltener Runddolch vom S?dweidenhof
  db:priv_AddDB("RecipesWeaponsmith", 553140);   -- Rezeptur - Shabdoos transformierter Knochenschneider
  db:priv_AddDB("RecipesWeaponsmith", 553141);   -- Rezeptur - Slogars transformiertes riesiges Fallbeil
  db:priv_AddDB("RecipesWeaponsmith", 553142);   -- Rezeptur - Transformierter Knochenhammer des Allseelensargs
  db:priv_AddDB("RecipesWeaponsmith", 553144);   -- Rezeptur - Lorls transformierte peitschende Klinge
  db:priv_AddDB("RecipesWeaponsmith", 553163);   -- Rezeptur - Schild des Kreidesumpfes
  db:priv_AddDB("RecipesWeaponsmith", 553181);   -- Rezeptur - Verbesserter Schild des Kreidesumpfes
  db:priv_AddDB("RecipesWeaponsmith", 553199);   -- Rezeptur - Seltener Schild des Kreidesumpfes
  db:priv_AddDB("RecipesWeaponsmith", 553225);   -- Rezeptur - Transformierter Schild der Allseelen
  db:priv_AddDB("RecipesWeaponsmith", 553226);   -- Rezeptur - Transformierter heiliger Schild von Slogar
  db:priv_AddDB("RecipesWeaponsmith", 553228);   -- Rezeptur - Lorsens Riesenschwert
  db:priv_AddDB("RecipesWeaponsmith", 553229);   -- Rezeptur - Handaxt von Shadis
  db:priv_AddDB("RecipesWeaponsmith", 553230);   -- Rezeptur - Leichthammer von Sandalor
  db:priv_AddDB("RecipesWeaponsmith", 553234);   -- Rezeptur - Lorsens verbessertes Riesenschwert
  db:priv_AddDB("RecipesWeaponsmith", 553235);   -- Rezeptur - Verbesserte Handaxt von Shadis
  db:priv_AddDB("RecipesWeaponsmith", 553236);   -- Rezeptur - Verbesserter Leichthammer von Sandalor
  db:priv_AddDB("RecipesWeaponsmith", 553240);   -- Rezeptur - Lorsens seltenes Riesenschwert
  db:priv_AddDB("RecipesWeaponsmith", 553241);   -- Rezeptur - Seltene Handaxt von Shadis
  db:priv_AddDB("RecipesWeaponsmith", 553242);   -- Rezeptur - Seltener Leichthammer von Sandalor
  db:priv_AddDB("RecipesWeaponsmith", 553246);   -- Rezeptur - Transformiertes Guillotineschwert des Eisenblut-Generals
  db:priv_AddDB("RecipesWeaponsmith", 553247);   -- Rezeptur - Transformierte Streitaxt der verlorenen Gerinnung
  db:priv_AddDB("RecipesWeaponsmith", 553248);   -- Rezeptur - Transformierter Leichthammer des Lehrmeisters der Wiederkehr
  db:priv_AddDB("RecipesWeaponsmith", 553268);   -- Rezeptur - Schild der Frontlinie
  db:priv_AddDB("RecipesWeaponsmith", 553286);   -- Rezeptur - Verbesserter Schild der Frontlinie
  db:priv_AddDB("RecipesWeaponsmith", 553304);   -- Rezeptur - Seltener Schild der Frontlinie
  db:priv_AddDB("RecipesWeaponsmith", 553330);   -- Rezeptur - Transformierter Schild des Kaltherzigen Prinzen
  db:priv_AddDB("RecipesWeaponsmith", 553331);   -- Rezeptur - Transformierter Schild der K?nigin der Tr?nen
  db:priv_AddDB("RecipesWeaponsmith", 553333);   -- Rezeptur - Langschwert des Archipelabenteurers
  db:priv_AddDB("RecipesWeaponsmith", 553334);   -- Rezeptur - Langstielaxt der w?tenden Bestie
  db:priv_AddDB("RecipesWeaponsmith", 553335);   -- Rezeptur - Schwerer Hammer des Raumexperiments
  db:priv_AddDB("RecipesWeaponsmith", 553337);   -- Rezeptur - Ringklinge des Seeinsellagers
  db:priv_AddDB("RecipesWeaponsmith", 553340);   -- Rezeptur - Verbessertes Langschwert des Archipelabenteurers
  db:priv_AddDB("RecipesWeaponsmith", 553341);   -- Rezeptur - Verbesserte Langstielaxt der w?tenden Bestie
  db:priv_AddDB("RecipesWeaponsmith", 553342);   -- Rezeptur - Verbesserter Schwerer Hammer des Raumexperiments
  db:priv_AddDB("RecipesWeaponsmith", 553344);   -- Rezeptur - Verbesserte Ringklinge des Seeinsellagers
  db:priv_AddDB("RecipesWeaponsmith", 553347);   -- Rezeptur - Seltenes Langschwert des Archipelabenteurers
  db:priv_AddDB("RecipesWeaponsmith", 553348);   -- Rezeptur - Seltene Langstielaxt der w?tenden Bestie
  db:priv_AddDB("RecipesWeaponsmith", 553349);   -- Rezeptur - Seltener Schwerer Hammer des Raumexperiments
  db:priv_AddDB("RecipesWeaponsmith", 553351);   -- Rezeptur - Seltene Ringklinge des Seeinsellagers
  db:priv_AddDB("RecipesWeaponsmith", 553354);   -- Rezeptur - Kreyens transformiertes Stahlschwert
  db:priv_AddDB("RecipesWeaponsmith", 553355);   -- Rezeptur - Transformierte Hirtentakel-Riesenaxt 
  db:priv_AddDB("RecipesWeaponsmith", 553356);   -- Rezeptur - Transformierter Langstielhammer der Passage der Pr?fungen
  db:priv_AddDB("RecipesWeaponsmith", 553358);   -- Rezeptur - Transformierte Scharfe Klinge des Rei?ers
  db:priv_AddDB("RecipesWeaponsmith", 553377);   -- Rezeptur - Schild des Staublagers
  db:priv_AddDB("RecipesWeaponsmith", 553395);   -- Rezeptur - Verbesserter Schild des Staublagers
  db:priv_AddDB("RecipesWeaponsmith", 553413);   -- Rezeptur - Seltener Schild des Staublagers
  db:priv_AddDB("RecipesWeaponsmith", 553439);   -- Rezeptur - Kreyens transformierter Schild der Stabilit?t
  db:priv_AddDB("RecipesWeaponsmith", 553440);   -- Rezeptur - Kreyens transformierter Schild des Schutzes
  db:priv_AddDB("RecipesWeaponsmith", 553442);   -- Rezeptur - Transformiertes Riesenschwert von Zeyj
  db:priv_AddDB("RecipesWeaponsmith", 553443);   -- Rezeptur - Fursthors transformierte Streitaxt
  db:priv_AddDB("RecipesWeaponsmith", 553444);   -- Rezeptur - Transformierter Schlachthammer des Nex von Korris
  db:priv_AddDB("RecipesWeaponsmith", 553468);   -- Rezeptur - Transformierter Schutzschild des Hohepriesters
  db:priv_AddDB("RecipesWeaponsmith", 553490);   -- Rezeptur - Transformierter Schild des Skarabb?us
  db:priv_AddDB("RecipesWeaponsmith", 553492);   -- Rezeptur - 215079
  db:priv_AddDB("RecipesWeaponsmith", 553493);   -- Rezeptur - 215080
  db:priv_AddDB("RecipesWeaponsmith", 553494);   -- Rezeptur - 215081
  db:priv_AddDB("RecipesWeaponsmith", 553496);   -- Rezeptur - 215083
  db:priv_AddDB("RecipesWeaponsmith", 553519);   -- Rezeptur -   

end


local function priv_AddRecipesOther(db)   -- Rezepte M?bel, Schmuck, Allgemein

  db:priv_AddDB("RecipesOther", 550952);   -- Rezeptur - Elementarkristall
  db:priv_AddDB("RecipesOther", 550953);   -- Rezeptur - Winziges magisches ?berbleibsel
  db:priv_AddDB("RecipesOther", 550954);   -- Rezeptur - Kleines magisches ?berbleibsel
  db:priv_AddDB("RecipesOther", 550955);   -- Rezeptur - Mittleres magisches ?berbleibsel
  db:priv_AddDB("RecipesOther", 550956);   -- Rezeptur - Winziges Runen?berbleibsel
  db:priv_AddDB("RecipesOther", 550957);   -- Rezeptur - Kleines Runen?berbleibsel
  db:priv_AddDB("RecipesOther", 550958);   -- Rezeptur - Mittleres Runen?berbleibsel
  db:priv_AddDB("RecipesOther", 551005);   -- Rezeptur - Carlyres Ring
  db:priv_AddDB("RecipesOther", 551006);   -- Rezeptur - Carlyres Diamantring
  db:priv_AddDB("RecipesOther", 551007);   -- Rezeptur - Carlyres Schwurring
  db:priv_AddDB("RecipesOther", 551008);   -- Rezeptur - Aufgewertetes Wasseressenzfragment
  db:priv_AddDB("RecipesOther", 551009);   -- Rezeptur - Geh?rtetes Wasseressenzfragment
  db:priv_AddDB("RecipesOther", 551040);   -- Rezeptur - Versiegelte Laute (3 Tage)
  db:priv_AddDB("RecipesOther", 551041);   -- Rezeptur - Versiegelte Gitarre (3 Tage)
  db:priv_AddDB("RecipesOther", 551042);   -- Rezeptur - Versiegeltes Saxophon (3 Tage)
  db:priv_AddDB("RecipesOther", 551043);   -- Rezeptur - Versiegelte Rassel (3 Tage)
  db:priv_AddDB("RecipesOther", 551044);   -- Rezeptur - Versiegeltes Tamburin (3 Tage)
  db:priv_AddDB("RecipesOther", 551168);   -- Rezeptur - Amulett des Lichts
  db:priv_AddDB("RecipesOther", 551169);   -- Rezeptur - Mondlichtpampelmusensaft
  db:priv_AddDB("RecipesOther", 551172);   -- Rezeptur - Totemflagge des Versieglers
  db:priv_AddDB("RecipesOther", 551173);   -- Rezeptur - Troph?e des Eisw?chters
  db:priv_AddDB("RecipesOther", 551174);   -- Rezeptur - Fellfu?' Kochm?tze
  db:priv_AddDB("RecipesOther", 551175);   -- Rezeptur - Troph?e von Taylin Fischgr?te
  db:priv_AddDB("RecipesOther", 551176);   -- Rezeptur - Probe von Perodia
  db:priv_AddDB("RecipesOther", 551177);   -- Rezeptur - Probe eines Eisw?stenmammuts
  db:priv_AddDB("RecipesOther", 551178);   -- Rezeptur - Schwarzhorn-Fl?gelornament
  db:priv_AddDB("RecipesOther", 551179);   -- Rezeptur - Oktopusarmornament
  db:priv_AddDB("RecipesOther", 551180);   -- Rezeptur - Elegantes Harfenornament
  db:priv_AddDB("RecipesOther", 551181);   -- Rezeptur - Yusaliens Panzerornament
  db:priv_AddDB("RecipesOther", 551182);   -- Rezeptur - Ugudas Hammerballornament
  db:priv_AddDB("RecipesOther", 551183);   -- Rezeptur - Androliers Kopfornament
  db:priv_AddDB("RecipesOther", 551184);   -- Rezeptur - Ornament der Blutr?nstigen Klaue
  db:priv_AddDB("RecipesOther", 551185);   -- Rezeptur - Aishas Kristallornament
  db:priv_AddDB("RecipesOther", 551186);   -- Rezeptur - Neeps Skorpionbeinornament
  db:priv_AddDB("RecipesOther", 551306);   -- Rezeptur - Zuckerball der S??beere
  db:priv_AddDB("RecipesOther", 551307);   -- Rezeptur - Kirschtoffee
  db:priv_AddDB("RecipesOther", 551308);   -- Rezeptur - Weintraubenlutscher
  db:priv_AddDB("RecipesOther", 551309);   -- Rezeptur - Gebet der Ruhe
  db:priv_AddDB("RecipesOther", 551310);   -- Rezeptur - Gebet der F?lle
  db:priv_AddDB("RecipesOther", 551311);   -- Rezeptur - Gebet des Lebens
  db:priv_AddDB("RecipesOther", 551312);   -- Rezeptur - Gebet des Webens
  db:priv_AddDB("RecipesOther", 551313);   -- Rezeptur - Gebet des Kampfes
  db:priv_AddDB("RecipesOther", 551314);   -- Rezeptur - Gebet des Schutzes
  db:priv_AddDB("RecipesOther", 551315);   -- Rezeptur - Feyenloths Gelassenheit
  db:priv_AddDB("RecipesOther", 551316);   -- Rezeptur - Feyenloths Ruhe
  db:priv_AddDB("RecipesOther", 551317);   -- Rezeptur - Feyenloths Wachstum
  db:priv_AddDB("RecipesOther", 551318);   -- Rezeptur - Feyenloths R?ckkehr
  db:priv_AddDB("RecipesOther", 551319);   -- Rezeptur - Feyenloths Kampfeswille
  db:priv_AddDB("RecipesOther", 551320);   -- Rezeptur - Feyenloths Einverst?ndnis
  db:priv_AddDB("RecipesOther", 551332);   -- Rezeptur - Flammendrachenherz-Kette der Macht
  db:priv_AddDB("RecipesOther", 551333);   -- Rezeptur - Flammendrachenschuppen-Ohrring der Macht
  db:priv_AddDB("RecipesOther", 551334);   -- Rezeptur - Flammendrachenfl?gel-Ohrring der Macht
  db:priv_AddDB("RecipesOther", 551335);   -- Rezeptur - Flammendrachenzahn-Ring der Macht
  db:priv_AddDB("RecipesOther", 551336);   -- Rezeptur - Flammendrachenklauen-Ring der Macht
  db:priv_AddDB("RecipesOther", 551337);   -- Rezeptur - Flammendrachenherz-Kette der Intelligenz
  db:priv_AddDB("RecipesOther", 551338);   -- Rezeptur - Flammendrachenschuppen-Ohrring der Intelligenz
  db:priv_AddDB("RecipesOther", 551339);   -- Rezeptur - Flammendrachenfl?gel-Ohrring der Intelligenz
  db:priv_AddDB("RecipesOther", 551340);   -- Rezeptur - Flammendrachenklauen-Ring der Intelligenz
  db:priv_AddDB("RecipesOther", 551341);   -- Rezeptur - Flammendrachenzahn-Ring der Intelligenz
  db:priv_AddDB("RecipesOther", 551633);   -- Rezeptur - Einfache Kiste: Holzhandwerk
  db:priv_AddDB("RecipesOther", 551634);   -- Rezeptur - Magische Kiste: Holzhandwerk
  db:priv_AddDB("RecipesOther", 551635);   -- Rezeptur - Exquisiter Musterbogen
  db:priv_AddDB("RecipesOther", 551636);   -- Rezeptur - M?chtiger epischer Bogen
  db:priv_AddDB("RecipesOther", 551637);   -- Rezeptur - Eiserne Puppe
  db:priv_AddDB("RecipesOther", 551638);   -- Rezeptur - Empfindlicher wei?er Eisenkessel
  db:priv_AddDB("RecipesOther", 551639);   -- Rezeptur - Unbekannter Eisenrunenw?rfel
  db:priv_AddDB("RecipesOther", 551640);   -- Rezeptur - M?chtiges episches Schwert
  db:priv_AddDB("RecipesOther", 551641);   -- Rezeptur - Hosenanzug von DIIOR
  db:priv_AddDB("RecipesOther", 551642);   -- Rezeptur - Hosenanzug von Cucci
  db:priv_AddDB("RecipesOther", 551643);   -- Rezeptur - Hosenanzug von LY
  db:priv_AddDB("RecipesOther", 551644);   -- Rezeptur - Hosenanzug von SHANEL
  db:priv_AddDB("RecipesOther", 551645);   -- Rezeptur - Geschmolzene Legierung
  db:priv_AddDB("RecipesOther", 551646);   -- Rezeptur - Superl?sungsmittel
  db:priv_AddDB("RecipesOther", 551647);   -- Rezeptur - Stein des Philosophen
  db:priv_AddDB("RecipesOther", 551648);   -- Rezeptur - Stein der Weisheit aus Massenproduktion
  db:priv_AddDB("RecipesOther", 551649);   -- Rezeptur - Einfacher Arbeitshelm
  db:priv_AddDB("RecipesOther", 551653);   -- Rezeptur - Gereinigter Kristall
  db:priv_AddDB("RecipesOther", 551654);   -- Rezeptur - Gereinigter Kristall
  db:priv_AddDB("RecipesOther", 551655);   -- Rezeptur - Gereinigter Kristall
  db:priv_AddDB("RecipesOther", 551656);   -- Rezeptur - Bausatz-Ausr?stung
  db:priv_AddDB("RecipesOther", 551657);   -- Rezeptur - Bewegliche Miniaturr?stung
  db:priv_AddDB("RecipesOther", 551658);   -- Rezeptur - Handgefertigter Tisch mit Sheenas Geschirr
  db:priv_AddDB("RecipesOther", 551659);   -- Rezeptur - Tanz-Parf?m
  db:priv_AddDB("RecipesOther", 551660);   -- Rezeptur - Exquisite handgefertigte Kleidung
  db:priv_AddDB("RecipesOther", 551964);   -- Rezeptur - Besondere Eiskohle
  db:priv_AddDB("RecipesOther", 551965);   -- Rezeptur - Stab der flinken Hand
  db:priv_AddDB("RecipesOther", 551966);   -- Rezeptur - Thermosflasche
  db:priv_AddDB("RecipesOther", 551967);   -- Rezeptur - Gew?rzkessel
  db:priv_AddDB("RecipesOther", 551968);   -- Rezeptur - ZERA-Robe
  db:priv_AddDB("RecipesOther", 551969);   -- Rezeptur - POSS-Hemd
  db:priv_AddDB("RecipesOther", 551970);   -- Rezeptur - Magischer Energiekristall
  db:priv_AddDB("RecipesOther", 551971);   -- Rezeptur - Modifizierter Stein der Weisheit
  db:priv_AddDB("RecipesOther", 551972);   -- Rezeptur - Helm der Allsicht
  db:priv_AddDB("RecipesOther", 551973);   -- Rezeptur - M?chtiger Plattenschutz vom Typus 800
  db:priv_AddDB("RecipesOther", 551974);   -- Rezeptur - Essenzkristall
  db:priv_AddDB("RecipesOther", 551975);   -- Rezeptur - Essenzkristall
  db:priv_AddDB("RecipesOther", 551976);   -- Rezeptur - Essenzkristall
  db:priv_AddDB("RecipesOther", 552039);   -- Rezeptur - Beweis des Handwerkergeistes
  db:priv_AddDB("RecipesOther", 552041);   -- Rezeptur - Griff der Pr?zision
  db:priv_AddDB("RecipesOther", 552042);   -- Rezeptur - Erfindungsgeist
  db:priv_AddDB("RecipesOther", 552079);   -- Rezeptur - Modell eines Arenak?mpfers
  db:priv_AddDB("RecipesOther", 552080);   -- Rezeptur - Modell eines W?chters der Erde
  db:priv_AddDB("RecipesOther", 552081);   -- Rezeptur - Modell einer Hüterin des Dschungels
  db:priv_AddDB("RecipesOther", 552082);   -- Rezeptur - Modell eines W?stenrunenmechanismus
  db:priv_AddDB("RecipesOther", 552083);   -- Rezeptur - Dekoration der Burgjongleure
  db:priv_AddDB("RecipesOther", 552084);   -- Rezeptur - Braunb?rpuppe
  db:priv_AddDB("RecipesOther", 552085);   -- Rezeptur - Ornament des Eisenw?chters zu Lande
  db:priv_AddDB("RecipesOther", 552086);   -- Rezeptur - Ornament des Eisenw?chters zur Luft
  db:priv_AddDB("RecipesOther", 552087);   -- Rezeptur - Ornament des Aslansch?tzers
  db:priv_AddDB("RecipesOther", 552088);   -- Rezeptur - Ornament des Bestrafers des Lichts			xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx wird nicht ausgew?hlt
  db:priv_AddDB("RecipesOther", 552089);   -- Rezeptur - Troph?e der Gladiatorstreitaxt
  db:priv_AddDB("RecipesOther", 552090);   -- Rezeptur - "Macht des Hüters der Erde"-Dekoration
  db:priv_AddDB("RecipesOther", 552091);   -- Rezeptur - "Grabkäferkönig-Dekoration"  
  db:priv_AddDB("RecipesOther", 552092);   -- Rezeptur - Stuhl der Puppenspielerin
  db:priv_AddDB("RecipesOther", 552093);   -- Rezeptur - Minibraunb?rpuppe
  db:priv_AddDB("RecipesOther", 552094);   -- Rezeptur - Siegertroph?e Nr. 203
  db:priv_AddDB("RecipesOther", 552095);   -- Rezeptur - Giftalchemist-Dekoration
  db:priv_AddDB("RecipesOther", 552096);   -- Rezeptur - "Scheibe des Bestrafers der Finsternis"-Ornament
  db:priv_AddDB("RecipesOther", 552097);   -- Rezeptur - "Kopf des Lichtbestrafers"-Ornament
  db:priv_AddDB("RecipesOther", 552098);   -- Rezeptur - D?monenspinnenornament
  db:priv_AddDB("RecipesOther", 552099);   -- Rezeptur - Stehlampe des Donnerd?mons
  db:priv_AddDB("RecipesOther", 552100);   -- Rezeptur - Stehlampe des w?tenden Geistes
  db:priv_AddDB("RecipesOther", 552101);   -- Rezeptur - "Fragment des Schattenbestrafers"-Ornament


end



-- Materials
local function priv_AddOres(db)   -- Erz

  db:priv_AddDB("Ores", 200230); -- Zinc Ore
  db:priv_AddDB("Ores", 200232); -- Tin Ore
  db:priv_AddDB("Ores", 200234); -- Iron Ore
  db:priv_AddDB("Ores", 200236); -- Copper Ore
  db:priv_AddDB("Ores", 200238); -- Dark Crystal
  db:priv_AddDB("Ores", 200239); -- Silver Ore
  db:priv_AddDB("Ores", 200242); -- Wizard-Iron Ore
  db:priv_AddDB("Ores", 200244); -- Moon Silver Ore
  db:priv_AddDB("Ores", 200249); -- Rock Crystal
  db:priv_AddDB("Ores", 200264); -- Abyss-Mercury
  db:priv_AddDB("Ores", 200265); -- Mithril
  db:priv_AddDB("Ores", 200268); -- Rune Obsidian Ore - 56
  db:priv_AddDB("Ores", 200269); -- Mysticite
  db:priv_AddDB("Ores", 200506); -- Cyanide
  db:priv_AddDB("Ores", 200507); -- Flame Dust
  db:priv_AddDB("Ores", 201710); -- Zinc Sand
  db:priv_AddDB("Ores", 201711); -- Tin Sand
  db:priv_AddDB("Ores", 201713); -- Iron Sand
  db:priv_AddDB("Ores", 201714); -- Copper Sand
  db:priv_AddDB("Ores", 201715); -- Dark Crystal Sand
  db:priv_AddDB("Ores", 201716); -- Silver Sand
  db:priv_AddDB("Ores", 201717); -- Wizard-Iron Sand
  db:priv_AddDB("Ores", 201718); -- Moon Silver Sand
  db:priv_AddDB("Ores", 201720); -- Abyss-Mercury Sand
  db:priv_AddDB("Ores", 201721); -- Rune Obsidian Sand - 56
  db:priv_AddDB("Ores", 201723); -- Zinc Nugget
  db:priv_AddDB("Ores", 201724); -- Tin Nugget
  db:priv_AddDB("Ores", 201725); -- Iron Nugget
  db:priv_AddDB("Ores", 201726); -- Copper Nugget
  db:priv_AddDB("Ores", 201727); -- Dark Crystal Nugget
  db:priv_AddDB("Ores", 201728); -- Silver Nugget
  db:priv_AddDB("Ores", 201729); -- Wizard-Iron Nugget
  db:priv_AddDB("Ores", 201730); -- Moon Silver Nugget
  db:priv_AddDB("Ores", 201731); -- Abyss-Mercury Nugget
  db:priv_AddDB("Ores", 201732); -- Rune Obsidian Nugget - 56
  db:priv_AddDB("Ores", 201736); -- Zinc Ingot
  db:priv_AddDB("Ores", 201737); -- Tin Ingot
  db:priv_AddDB("Ores", 201738); -- Iron Ingot
  db:priv_AddDB("Ores", 201739); -- Copper Ingot
  db:priv_AddDB("Ores", 201740); -- Dark Crystal Ingot
  db:priv_AddDB("Ores", 201741); -- Silver Ingot
  db:priv_AddDB("Ores", 201742); -- Wizard-Iron Ingot
  db:priv_AddDB("Ores", 201743); -- Moon Silver Ingot
  db:priv_AddDB("Ores", 201744); -- Abyss-Mercury Ingot
  db:priv_AddDB("Ores", 201745); -- Rune Obsidian Ingot - 56
  db:priv_AddDB("Ores", 202315); -- Frost Crystal
  db:priv_AddDB("Ores", 202316); -- Mica - 61
  db:priv_AddDB("Ores", 202561); -- Flame Dust Sand
  db:priv_AddDB("Ores", 202562); -- Cyanide Sand
  db:priv_AddDB("Ores", 202563); -- Rock Crystal Sand
  db:priv_AddDB("Ores", 202564); -- Mysticite Sand
  db:priv_AddDB("Ores", 202565); -- Mithrial Sand
  db:priv_AddDB("Ores", 202566); -- Frost Crystal Sand
  db:priv_AddDB("Ores", 202567); -- Mica Sand - 61
  db:priv_AddDB("Ores", 202568); -- Flame Dust Nugget
  db:priv_AddDB("Ores", 202569); -- Cyanide Nugget
  db:priv_AddDB("Ores", 202570); -- Rock Crystal Nugget
  db:priv_AddDB("Ores", 202571); -- Mysticite Nugget
  db:priv_AddDB("Ores", 202572); -- Mithril Nugget
  db:priv_AddDB("Ores", 202573); -- Frost Crystal Nugget
  db:priv_AddDB("Ores", 202574); -- Mica Nugget - 61
  db:priv_AddDB("Ores", 202575); -- Flame Dust Ingot
  db:priv_AddDB("Ores", 202576); -- Cyanide Ingot
  db:priv_AddDB("Ores", 202577); -- Rock Crystal Ingot
  db:priv_AddDB("Ores", 202578); -- Mysticite Ingot
  db:priv_AddDB("Ores", 202579); -- Mithril Ingot
  db:priv_AddDB("Ores", 202580); -- Frost Crystal Ingot
  db:priv_AddDB("Ores", 202581); -- Mica Ingot - 61
  db:priv_AddDB("Ores", 208234); -- Olivine - 61
  db:priv_AddDB("Ores", 208235); -- Olivine Sand - 61
  db:priv_AddDB("Ores", 208236); -- Olivine Stone - 61
  db:priv_AddDB("Ores", 208237); -- Olivine Ingot - 61
  db:priv_AddDB("Ores", 240314); -- Purpurroter Achatkristall - 66
  db:priv_AddDB("Ores", 240315); -- Purpurroter Achatkristallsand - 66
  db:priv_AddDB("Ores", 240316); -- Purpurroter Achatkristallklumpen - 66-- credit Ultak
  db:priv_AddDB("Ores", 240317); -- Purple Agate Crystal Ingot - 66
  db:priv_AddDB("Ores", 241432); -- Olegan Stone - 69
  db:priv_AddDB("Ores", 241433); -- Olegan Stone Sand - 69
  db:priv_AddDB("Ores", 241434); -- Olegan Stone Nugget - 69-- credit Ultak
  db:priv_AddDB("Ores", 241435); -- Olegansteinbarren - 69
  db:priv_AddDB("Ores", 241438); -- Rein Crystal - 69
  db:priv_AddDB("Ores", 241439); -- Rein Crystal Sand - 69
  db:priv_AddDB("Ores", 241440); -- Rein Crystal Nugget - 69-- credit Ultak
  db:priv_AddDB("Ores", 241441); -- Rein Crystal Ingot - 69
  db:priv_AddDB("Ores", 242246); -- Silver Star Stone - 81-- credit Ultak
  db:priv_AddDB("Ores", 242247); -- Silver Star Stone Sand - 81-- credit Ultak
  db:priv_AddDB("Ores", 242248); -- Silver Star Stone Nugget - 81-- credit Ultak
  db:priv_AddDB("Ores", 242249); -- Silver Star Stone Ingot - 81-- credit Ultak
  db:priv_AddDB("Ores", 242258); -- Mutation Dust - 86-- credit Ultak
  db:priv_AddDB("Ores", 242259); -- Mutation Dust Sand - 86-- credit Ultak
  db:priv_AddDB("Ores", 242260); -- Mutation Dust Nugget - 86-- credit Ultak
  db:priv_AddDB("Ores", 242261); -- Mutation Dust Ingot - 86-- credit Ultak
  db:priv_AddDB("Ores", 242270); -- Rainbow Stone - 91-- credit Ultak
  db:priv_AddDB("Ores", 242271); -- Rainbow Stone Sand - 91-- credit Ultak
  db:priv_AddDB("Ores", 242272); -- Rainbow Stone Nugget - 91-- credit Ultak
  db:priv_AddDB("Ores", 242273); -- Rainbow Stone Ingot - 91-- credit Ultak
  db:priv_AddDB("Ores", 242282); -- Argentit
  db:priv_AddDB("Ores", 242283); -- Argentitsand
  db:priv_AddDB("Ores", 242284); -- Argentitklumpen
  db:priv_AddDB("Ores", 242285); -- Argentitbarren
  db:priv_AddDB("Ores", 242294); -- Ironaxe Stone - 81-- credit Ultak
  db:priv_AddDB("Ores", 242295); -- Ironaxe Stone Sand - 81-- credit Ultak
  db:priv_AddDB("Ores", 242296); -- Ironaxe Stone Nugget - 81-- credit Ultak
  db:priv_AddDB("Ores", 242297); -- Ironaxe Stone Ingot - 81-- credit Ultak
  db:priv_AddDB("Ores", 242305); -- Sea Crystal Sand - 91-- credit Ultak
  db:priv_AddDB("Ores", 242306); -- Meereskristall
  db:priv_AddDB("Ores", 242307); -- Meereskristallsand
  db:priv_AddDB("Ores", 242308); -- Meereskristallklumpen
  db:priv_AddDB("Ores", 242309); -- Meereskristallbarren 
  
end

local function priv_AddWood(db)   -- Holz

  db:priv_AddDB("Wood", 200293); -- Ash Wood - 1
  db:priv_AddDB("Wood", 200295); -- Willow Wood - 8
  db:priv_AddDB("Wood", 200297); -- Maple Wood - 14
  db:priv_AddDB("Wood", 200298); -- Holly Wood - 32
  db:priv_AddDB("Wood", 200300); -- Oak Wood - 20
  db:priv_AddDB("Wood", 200304); -- Pine Wood - 26
  db:priv_AddDB("Wood", 200306); -- Yew Wood - 38
  db:priv_AddDB("Wood", 200307); -- Tarslin Demon Wood - 44
  db:priv_AddDB("Wood", 200310); -- Dragonlair Wood - 51
  db:priv_AddDB("Wood", 200312); -- Ancient Spirit Oak Wood - 56
  db:priv_AddDB("Wood", 200326); -- Redwood - 21
  db:priv_AddDB("Wood", 200331); -- Sagewood - 41
  db:priv_AddDB("Wood", 200332); -- Dragon Beard Root Wood - 31
  db:priv_AddDB("Wood", 200508); -- Chime Wood - 1
  db:priv_AddDB("Wood", 200509); -- Stone Rotan Wood - 11
  db:priv_AddDB("Wood", 201749); -- Ash Timber - 1
  db:priv_AddDB("Wood", 201750); -- Willow Timber - 8
  db:priv_AddDB("Wood", 201751); -- Maple Timber - 14
  db:priv_AddDB("Wood", 201752); -- Oak Timber - 20
  db:priv_AddDB("Wood", 201753); -- Holly Timber - 32
  db:priv_AddDB("Wood", 201754); -- Pine Timber - 26
  db:priv_AddDB("Wood", 201757); -- Yew Timber - 38
  db:priv_AddDB("Wood", 201758); -- Tarslin Demon Wood Timber - 44
  db:priv_AddDB("Wood", 201759); -- Dragonlair Wood Timber - 51
  db:priv_AddDB("Wood", 201760); -- Ancient Spirit Oak Timber - 56
  db:priv_AddDB("Wood", 201761); -- Ash Lumber
  db:priv_AddDB("Wood", 201762); -- Willow Lumber
  db:priv_AddDB("Wood", 201763); -- Maple Lumber
  db:priv_AddDB("Wood", 201764); -- Oak Lumber
  db:priv_AddDB("Wood", 201765); -- Pine Lumber
  db:priv_AddDB("Wood", 201766); -- Holly Lumber
  db:priv_AddDB("Wood", 201767); -- Yew Lumber
  db:priv_AddDB("Wood", 201768); -- Tarslin Demon Wood Lumber
  db:priv_AddDB("Wood", 201769); -- Dragonlair Wood Lumber
  db:priv_AddDB("Wood", 201770); -- Ancient Spirit Oak Lumber
  db:priv_AddDB("Wood", 201773); -- Ash Plank
  db:priv_AddDB("Wood", 201774); -- Willow Plank
  db:priv_AddDB("Wood", 201775); -- Maple Plank
  db:priv_AddDB("Wood", 201776); -- Oak Plank
  db:priv_AddDB("Wood", 201777); -- Pine Plank
  db:priv_AddDB("Wood", 201778); -- Holly Plank
  db:priv_AddDB("Wood", 201779); -- Yew Plank
  db:priv_AddDB("Wood", 201780); -- Tarslin Demon Wood Plank
  db:priv_AddDB("Wood", 201781); -- Dragonlair Wood Plank
  db:priv_AddDB("Wood", 201782); -- Ancient Spirit Oak Plank
  db:priv_AddDB("Wood", 202317); -- Fairywood - 51
  db:priv_AddDB("Wood", 202318); -- Aeontree Wood - 61
  db:priv_AddDB("Wood", 202596); -- Chime Wood Timber - 1
  db:priv_AddDB("Wood", 202597); -- Stone Rotan Timber - 11
  db:priv_AddDB("Wood", 202598); -- Redwood Timber - 21
  db:priv_AddDB("Wood", 202599); -- Dragon Beard Root Timber - 31
  db:priv_AddDB("Wood", 202600); -- Sagewood Timber - 41
  db:priv_AddDB("Wood", 202601); -- Fairywood Timber - 51
  db:priv_AddDB("Wood", 202602); -- Aeontree Timber - 61
  db:priv_AddDB("Wood", 202603); -- Chime Wood Lumber
  db:priv_AddDB("Wood", 202604); -- Stone Rotan Lumber
  db:priv_AddDB("Wood", 202605); -- Redwood Lumber
  db:priv_AddDB("Wood", 202606); -- Dragon Beard Root Lumber
  db:priv_AddDB("Wood", 202607); -- Sagewood Lumber
  db:priv_AddDB("Wood", 202608); -- Fairywood Lumber
  db:priv_AddDB("Wood", 202609); -- Aeontree Lumber - 61
  db:priv_AddDB("Wood", 202610); -- Chime Wood Plank
  db:priv_AddDB("Wood", 202611); -- Stone Rotan Plank
  db:priv_AddDB("Wood", 202612); -- Redwood Plank
  db:priv_AddDB("Wood", 202613); -- Dragon Beard Root Plank
  db:priv_AddDB("Wood", 202614); -- Sagewood Plank
  db:priv_AddDB("Wood", 202615); -- Fairywood Plank
  db:priv_AddDB("Wood", 202616); -- Aeontree Plank - 61
  db:priv_AddDB("Wood", 208240); -- Fastan Banyan - 63
  db:priv_AddDB("Wood", 208241); -- Fastan Banyan Timber - 63
  db:priv_AddDB("Wood", 208242); -- Fastan Banyan Lumber - 63
  db:priv_AddDB("Wood", 208243); -- Fastan Banyan Plank - 63
  db:priv_AddDB("Wood", 240323); -- Janost-Cypress Wood - 66
  db:priv_AddDB("Wood", 240324); -- Janost-Cypress Timber - 66
  db:priv_AddDB("Wood", 240325); -- Janost-Cypress Lumber - 66
  db:priv_AddDB("Wood", 240326); -- Janost-Zypressenbrett - 66-- credit Ultak
  db:priv_AddDB("Wood", 241420); -- Todo Ginkgo Tree - 66?
  db:priv_AddDB("Wood", 241421); -- Todo Ginkgo Timber
  db:priv_AddDB("Wood", 241422); -- Todo Ginkgo Lumber
  db:priv_AddDB("Wood", 241423); -- Todo Ginkgo Plank?
  db:priv_AddDB("Wood", 241426); -- Stone Pine Wood - 71-- credit Ultak
  db:priv_AddDB("Wood", 241427); -- Stone Pine Timber - 71-- credit Ultak
  db:priv_AddDB("Wood", 241428); -- Stone Pine Lumber - 71-- credit Ultak
  db:priv_AddDB("Wood", 241429); -- Pinienholzbrett - 69-- credit Ultak
  db:priv_AddDB("Wood", 242242); -- Nadal Wisteria Wood - 81-- credit Ultak
  db:priv_AddDB("Wood", 242243); -- Nadal Wisteria Timber - 81-- credit Ultak
  db:priv_AddDB("Wood", 242244); -- Nadal Wisteria Lumber - 81-- credit Ultak
  db:priv_AddDB("Wood", 242245); -- Nadal Wisteria Plank - 81-- credit Ultak
  db:priv_AddDB("Wood", 242254); -- Summer Oak Wood - 86-- credit Ultak
  db:priv_AddDB("Wood", 242255); -- Summer Oak Timber - 86-- credit Ultak
  db:priv_AddDB("Wood", 242256); -- Summer Oak Lumber - 86-- credit Ultak
  db:priv_AddDB("Wood", 242257); -- Summer Oak Plank - 86-- credit Ultak
  db:priv_AddDB("Wood", 242266); -- Fire Mountain Tree Wood - 91-- credit Ultak
  db:priv_AddDB("Wood", 242267); -- Fire Mountain Tree Timber - 91-- credit Ultak
  db:priv_AddDB("Wood", 242268); -- Fire Mountain Tree Lumber - 91-- credit Ultak
  db:priv_AddDB("Wood", 242269); -- Fire Mountain Tree Plank - 91-- credit Ultak
  db:priv_AddDB("Wood", 242278); -- Kandibaum 
  db:priv_AddDB("Wood", 242279); -- Kandibaumrohholz
  db:priv_AddDB("Wood", 242280); -- Kandibaumkantholz
  db:priv_AddDB("Wood", 242281); -- Kandibaumbrett 
  db:priv_AddDB("Wood", 242290); -- Blood Palm Wood - 81-- credit Ultak
  db:priv_AddDB("Wood", 242291); -- Blood Palm Timber - 81-- credit Ultak
  db:priv_AddDB("Wood", 242292); -- Blood Palm Lumber - 81-- credit Ultak
  db:priv_AddDB("Wood", 242293); -- Blood Palm Plank - 81-- credit Ultak
  db:priv_AddDB("Wood", 242302); -- Bleak Fir Wood - 91-- credit Ultak
  db:priv_AddDB("Wood", 242303); -- Bleak Fir Timber - 91-- credit Ultak
  db:priv_AddDB("Wood", 242304); -- Bleak Fir Lumber - 91-- credit Ultak
  db:priv_AddDB("Wood", 242305); -- Bleak Fir Plank - 91-- credit Ultak
  
end

local function priv_AddHerbs(db)   -- Kraut

  db:priv_AddDB("Herbs", 200333); -- Bitterleaf
  db:priv_AddDB("Herbs", 200334); -- Beetroot
  db:priv_AddDB("Herbs", 200335); -- Mountain Demon Grass
  db:priv_AddDB("Herbs", 200338); -- Moxa
  db:priv_AddDB("Herbs", 200342); -- Barsleaf
  db:priv_AddDB("Herbs", 200343); -- Dusk Orchid
  db:priv_AddDB("Herbs", 200345); -- Moon Orchid
  db:priv_AddDB("Herbs", 200346); -- Sinners Palm - 44
  db:priv_AddDB("Herbs", 200349); -- Dragon Mallow
  db:priv_AddDB("Herbs", 200350); -- Thorn Apple - 56
  db:priv_AddDB("Herbs", 201785); -- Mountain Demon Grass Bundle
  db:priv_AddDB("Herbs", 201786); -- Beetroot Bundle
  db:priv_AddDB("Herbs", 201788); -- Moxa Bundle
  db:priv_AddDB("Herbs", 201789); -- Bitterleaf Bundle
  db:priv_AddDB("Herbs", 201791); -- Dusk Orchid Bundle
  db:priv_AddDB("Herbs", 201792); -- Barsleaf Bundle
  db:priv_AddDB("Herbs", 201794); -- Moon Orchid Bundle
  db:priv_AddDB("Herbs", 201796); -- Sinners Palm Bundle - 44
  db:priv_AddDB("Herbs", 201797); -- Dragon Mallow Bundle
  db:priv_AddDB("Herbs", 201798); -- Thorn Apple Bundle - 56
  db:priv_AddDB("Herbs", 201799); -- Mountain Demon Grass Sap
  db:priv_AddDB("Herbs", 201800); -- Beetroot Sap
  db:priv_AddDB("Herbs", 201801); -- Bitterleaf Sap
  db:priv_AddDB("Herbs", 201802); -- Moxa Sap
  db:priv_AddDB("Herbs", 201803); -- Dusk Orchid Sap
  db:priv_AddDB("Herbs", 201804); -- Barsleaf Sap
  db:priv_AddDB("Herbs", 201805); -- Moon Orchid Sap
  db:priv_AddDB("Herbs", 201806); -- Sinners Palm Sap - 44
  db:priv_AddDB("Herbs", 201807); -- Dragon Mallow Sap
  db:priv_AddDB("Herbs", 201808); -- Thorn Apple Juice - 56
  db:priv_AddDB("Herbs", 201813); -- Mountain Demon Grass Extract
  db:priv_AddDB("Herbs", 201814); -- Beetroot Extract
  db:priv_AddDB("Herbs", 201815); -- Bitterleaf Extract
  db:priv_AddDB("Herbs", 201816); -- Moxa Extract
  db:priv_AddDB("Herbs", 201817); -- Dusk Orchid Extract
  db:priv_AddDB("Herbs", 201818); -- Barsleaf Extract
  db:priv_AddDB("Herbs", 201819); -- Moon Orchid Extract
  db:priv_AddDB("Herbs", 201820); -- Sinners Palm Extract - 44
  db:priv_AddDB("Herbs", 201821); -- Dragon Mallow Extract
  db:priv_AddDB("Herbs", 201822); -- Thorn Apple Extract - 56
  db:priv_AddDB("Herbs", 202552); -- Rosemary
  db:priv_AddDB("Herbs", 202553); -- Bison Grass
  db:priv_AddDB("Herbs", 202554); -- Foloin Nut
  db:priv_AddDB("Herbs", 202555); -- Green Thistle
  db:priv_AddDB("Herbs", 202556); -- Straw Mushroom - 41
  db:priv_AddDB("Herbs", 202557); -- Mirror Sedge - 51
  db:priv_AddDB("Herbs", 202558); -- Goblin Grass - 61
  db:priv_AddDB("Herbs", 202631); -- Rosemary Bundle
  db:priv_AddDB("Herbs", 202632); -- Bison Grass Bundle
  db:priv_AddDB("Herbs", 202633); -- Foloin Nut Bundle
  db:priv_AddDB("Herbs", 202634); -- Green Thistle Bundle
  db:priv_AddDB("Herbs", 202635); -- Straw Mushroom Bundle - 41
  db:priv_AddDB("Herbs", 202636); -- Mirror Sedge Bundle - 51
  db:priv_AddDB("Herbs", 202637); -- Goblin Grass Bundle - 61
  db:priv_AddDB("Herbs", 202638); -- Rosemary Sap
  db:priv_AddDB("Herbs", 202639); -- Bison Grass Sap
  db:priv_AddDB("Herbs", 202640); -- Foloin Nut Sap
  db:priv_AddDB("Herbs", 202641); -- Green Thistle Sap
  db:priv_AddDB("Herbs", 202642); -- Straw Mushroom Sap - 41
  db:priv_AddDB("Herbs", 202643); -- Mirror Sedge Sap - 51
  db:priv_AddDB("Herbs", 202644); -- Goblin Grass Sap - 61
  db:priv_AddDB("Herbs", 202645); -- Rosemary Extract
  db:priv_AddDB("Herbs", 202646); -- Bison Grass Extract
  db:priv_AddDB("Herbs", 202647); -- Foloin Nut Extract
  db:priv_AddDB("Herbs", 202648); -- Green Thistle Extract
  db:priv_AddDB("Herbs", 202649); -- Straw Mushroom Extract - 41
  db:priv_AddDB("Herbs", 202650); -- Mirror Sedge Extract - 51
  db:priv_AddDB("Herbs", 202651); -- Goblin Grass Extract - 61
  db:priv_AddDB("Herbs", 208246); -- Verbena - 63
  db:priv_AddDB("Herbs", 208247); -- Bouquet of Verbena - 63
  db:priv_AddDB("Herbs", 208248); -- Verbena Juice - 63
  db:priv_AddDB("Herbs", 208249); -- Verbena Extract - 63
  db:priv_AddDB("Herbs", 240329); -- Nocturnal Lantern Grass - 66
  db:priv_AddDB("Herbs", 240330); -- Nocturnal Lantern Grass Bundle - 66
  db:priv_AddDB("Herbs", 240331); -- Nocturnal Lantern Grass Sap - 66
  db:priv_AddDB("Herbs", 240332); -- Nocturnal Lantern Grass Extract - 66
  db:priv_AddDB("Herbs", 241408); -- Thunderhoof Grass - 75-- credit Ultak
  db:priv_AddDB("Herbs", 241409); -- Thunderhoof Grass Bundle - 75-- credit Ultak
  db:priv_AddDB("Herbs", 241410); -- Thunderhoof Sap - 75-- credit Ultak
  db:priv_AddDB("Herbs", 241411); -- Tuhnderhoof Grass Extract - 75-- credit Ultak
  db:priv_AddDB("Herbs", 241414); -- Dovetail Flower - 71-- credit Ultak
  db:priv_AddDB("Herbs", 241415); -- Dovetail Flower Bundle - 71
  db:priv_AddDB("Herbs", 241416); -- Dovetail Flower Sap - 71
  db:priv_AddDB("Herbs", 241417); -- Dovetail Flower Extract - 71
  db:priv_AddDB("Herbs", 242250); -- Isyeh Grass - 81-- credit Ultak
  db:priv_AddDB("Herbs", 242251); -- Isyeh Grass Bundle - 81-- credit Ultak
  db:priv_AddDB("Herbs", 242252); -- Isyeh Grass Sap - 81-- credit Ultak
  db:priv_AddDB("Herbs", 242253); -- Isyeh Grass Extract - 81-- credit Ultak
  db:priv_AddDB("Herbs", 242262); -- Cold Psilotum - 86-- credit Ultak
  db:priv_AddDB("Herbs", 242263); -- Cold Psilotum Bundle - 86-- credit Ultak
  db:priv_AddDB("Herbs", 242264); -- Cold Psilotum Sap - 86-- credit Ultak
  db:priv_AddDB("Herbs", 242265); -- Cold Psilotum Extract - 86-- credit Ultak
  db:priv_AddDB("Herbs", 242274); -- Snow Grass - 91-- credit Ultak
  db:priv_AddDB("Herbs", 242275); -- Snow Grass Bundle - 91-- credit Ultak
  db:priv_AddDB("Herbs", 242276); -- Snow Grass Sap - 91-- credit Ultak
  db:priv_AddDB("Herbs", 242277); -- Snow Grass Extract - 91-- credit Ultak
  db:priv_AddDB("Herbs", 242286); -- Muschelblume
  db:priv_AddDB("Herbs", 242287); -- Muschelblumenb?ndel  
  db:priv_AddDB("Herbs", 242288); -- Muschelblumensaft
  db:priv_AddDB("Herbs", 242289); -- Muschelblumenextrakt
  db:priv_AddDB("Herbs", 242298); -- Dragonsprout Grass - 81-- credit Ultak 
  db:priv_AddDB("Herbs", 242299); -- Dragonsprout Grass Bundle - 81-- credit Ultak
  db:priv_AddDB("Herbs", 242300); -- Dragonsprout Grass Sap - 81-- credit Ultak
  db:priv_AddDB("Herbs", 242301); -- Dragonsprout Grass Extract - 81-- credit Ultak
  db:priv_AddDB("Herbs", 242310); -- Mondgras
  db:priv_AddDB("Herbs", 242311); -- Mondgrasb?ndel
  db:priv_AddDB("Herbs", 242312); -- Mondgras-Saft
  db:priv_AddDB("Herbs", 242313); -- Mondgrasextrakt
  
end

local function priv_AddCards(db)	-- Karte

  db:priv_AddDB("Cards", 770000);  -- Karte - Fungus
  db:priv_AddDB("Cards", 770001);  -- Karte - Fungus-Wache
  db:priv_AddDB("Cards", 770002);  -- Karte - Fungus-Hauptmann
  db:priv_AddDB("Cards", 770003);  -- Karte - Hillarzu der Erste
  db:priv_AddDB("Cards", 770004);  -- Karte - Jungwolf
  db:priv_AddDB("Cards", 770005);  -- Karte - Jungb?r
  db:priv_AddDB("Cards", 770006);  -- Karte - K?fer
  db:priv_AddDB("Cards", 770007);  -- Karte - Welkblatt-Fledermaus
  db:priv_AddDB("Cards", 770008);  -- Karte - Wildspinne
  db:priv_AddDB("Cards", 770009);  -- Karte - B?r
  db:priv_AddDB("Cards", 770010);  -- Karte - Keiler
  db:priv_AddDB("Cards", 770011);  -- Karte - Wolf
  db:priv_AddDB("Cards", 770012);  -- Karte - Rotaugen-Nachtb?r
  db:priv_AddDB("Cards", 770013);  -- Karte - D?monenspinne vom Toten Baum
  db:priv_AddDB("Cards", 770014);  -- Karte - Dunkelfledermaus
  db:priv_AddDB("Cards", 770015);  -- Karte - Minen-Kobold
  db:priv_AddDB("Cards", 770016);  -- Karte - Raub-Kobold
  db:priv_AddDB("Cards", 770017);  -- Karte - Anglie
  db:priv_AddDB("Cards", 770018);  -- Karte - Kobold-Kundschafter
  db:priv_AddDB("Cards", 770019);  -- Karte - Schattenmolch
  db:priv_AddDB("Cards", 770020);  -- Karte - Molch
  db:priv_AddDB("Cards", 770021);  -- Karte - Höhlenkrebs
  db:priv_AddDB("Cards", 770022);  -- Karte - Rotscheren-Höhlenkrebs
  db:priv_AddDB("Cards", 770023);  -- Karte - Minen-Goblin
  db:priv_AddDB("Cards", 770024);  -- Karte - Goblin-Patrouille
  db:priv_AddDB("Cards", 770025);  -- Karte - H?ndler der blutroten Karawane
  db:priv_AddDB("Cards", 770026);  -- Karte - Kuhk?fer
  db:priv_AddDB("Cards", 770027);  -- Karte - Graslandhy?ne
  db:priv_AddDB("Cards", 770028);  -- Karte - Schwarzer Keiler
  db:priv_AddDB("Cards", 770029);  -- Karte - Yuri
  db:priv_AddDB("Cards", 770030);  -- Karte - Kobold-Pl?nderer
  db:priv_AddDB("Cards", 770031);  -- Karte - Stechfl?gel-Libelle
  db:priv_AddDB("Cards", 770032);  -- Karte - Blutsauger-Fledermaus
  db:priv_AddDB("Cards", 770033);  -- Karte - Bandit
  db:priv_AddDB("Cards", 770034);  -- Karte - Silberm?hnenhund
  db:priv_AddDB("Cards", 770035);  -- Karte - Dornenspinne
  db:priv_AddDB("Cards", 770036);  -- Karte - Rattenohren-Fledermaus
  db:priv_AddDB("Cards", 770037);  -- Karte - Aasspinne
  db:priv_AddDB("Cards", 770038);  -- Karte - Zwanghafter Schatten
  db:priv_AddDB("Cards", 770039);  -- Karte - Taren
  db:priv_AddDB("Cards", 770040);  -- Karte - Zurhidon-T?ter
  db:priv_AddDB("Cards", 770041);  -- Karte - B?ser Landarbeiter von Maidges Hof
  db:priv_AddDB("Cards", 770042);  -- Karte - B?ser Arbeiter von Maidges Hof
  db:priv_AddDB("Cards", 770043);  -- Karte - Morrison
  db:priv_AddDB("Cards", 770044);  -- Karte - R?udiges Schwein
  db:priv_AddDB("Cards", 770045);  -- Karte - Mutierter Wolf
  db:priv_AddDB("Cards", 770046);  -- Karte - Tagena-Patrouille
  db:priv_AddDB("Cards", 770047);  -- Karte - Tagena-Wanderer
  db:priv_AddDB("Cards", 770048);  -- Karte - Zurhidon-Anh?nger
  db:priv_AddDB("Cards", 770049);  -- Karte - Amias
  db:priv_AddDB("Cards", 770050);  -- 
  db:priv_AddDB("Cards", 770051);  -- Karte - Traumland-D?mon
  db:priv_AddDB("Cards", 770052);  -- Karte - Buntstrau?
  db:priv_AddDB("Cards", 770053);  -- Karte - Kupferpanzer-K?fer
  db:priv_AddDB("Cards", 770054);  -- Karte - Jungstrau?
  db:priv_AddDB("Cards", 770055);  -- Karte - Tal-Aasfresser
  db:priv_AddDB("Cards", 770056);  -- Karte - Talpl?nderer
  db:priv_AddDB("Cards", 770057);  -- Karte - Gr?npunkt-Fungus
  db:priv_AddDB("Cards", 770058);  -- Karte - Schuppen-Ameisenb?r
  db:priv_AddDB("Cards", 770059);  -- Karte - Eisenklauen-Ameisenb?r
  db:priv_AddDB("Cards", 770060);  -- Karte - Peitschenschwanz-Ameisenb?r
  db:priv_AddDB("Cards", 770061);  -- Karte - Hauer-Schwein
  db:priv_AddDB("Cards", 770062);  -- Karte - D?monenm?hnen-Schwein
  db:priv_AddDB("Cards", 770063);  -- Karte - Zurhidon-Nachforscher
  db:priv_AddDB("Cards", 770064);  -- Karte - Todesleguan
  db:priv_AddDB("Cards", 770065);  -- Karte - Aslan-Pelzfrosch
  db:priv_AddDB("Cards", 770066);  -- Karte - Panzer-Kasumille
  db:priv_AddDB("Cards", 770067);  -- Karte - W?tender Goblin
  db:priv_AddDB("Cards", 770068);  -- Karte - Hammerzahn-Rabauke
  db:priv_AddDB("Cards", 770069);  -- Karte - Hammerzahn-Krachmacher
  db:priv_AddDB("Cards", 770070);  -- Karte - Hammerzahn-Arbeiter
  db:priv_AddDB("Cards", 770071);  -- Karte - Hammerzahn-Raubein
  db:priv_AddDB("Cards", 770072);  -- Karte - Hammerzahn-Weiser
  db:priv_AddDB("Cards", 770073);  -- Karte - Hammerzahn-Wache
  db:priv_AddDB("Cards", 770074);  -- Karte - Kyrm Hammerzahn
  db:priv_AddDB("Cards", 770075);  -- Karte - Bubsitan
  db:priv_AddDB("Cards", 770076);  -- Karte - Wildnis-Otyuch
  db:priv_AddDB("Cards", 770077);  -- Karte - Beruda Lize
  db:priv_AddDB("Cards", 770078);  -- Karte - Morkusbestie
  db:priv_AddDB("Cards", 770079);  -- Karte - Ausgewachsener Ent
  db:priv_AddDB("Cards", 770080);  -- Karte - Neumond-Ent
  db:priv_AddDB("Cards", 770081);  -- Karte - Wander-Ent
  db:priv_AddDB("Cards", 770082);  -- Karte - Zottelb?r
  db:priv_AddDB("Cards", 770083);  -- Karte - Scharfkrallenb?r
  db:priv_AddDB("Cards", 770084);  -- Karte - Borrofar
  db:priv_AddDB("Cards", 770085);  -- Karte - D?monendornenranke
  db:priv_AddDB("Cards", 770086);  -- Karte - Blutd?rstige D?monenranke
  db:priv_AddDB("Cards", 770087);  -- Karte - Gebundener Forscher
  db:priv_AddDB("Cards", 770088);  -- Karte - Riesengeweih-Rentier
  db:priv_AddDB("Cards", 770089);  -- Karte - Nekromant
  db:priv_AddDB("Cards", 770090);  -- Karte - Zombie
  db:priv_AddDB("Cards", 770091);  -- Karte - Ghul
  db:priv_AddDB("Cards", 770092);  -- Karte - Ghul Duke
  db:priv_AddDB("Cards", 770093);  -- Karte - D?monenhexe Ancalon
  db:priv_AddDB("Cards", 770094);  -- Karte - Modder
  db:priv_AddDB("Cards", 770095);  -- Karte - Dunkle Nachtruf-Fledermaus
  db:priv_AddDB("Cards", 770096);  -- Karte - Flie?endes Chaos
  db:priv_AddDB("Cards", 770097);  -- Karte - Gr?uelfresser
  db:priv_AddDB("Cards", 770098);  -- Karte - Leere H?lle
  db:priv_AddDB("Cards", 770099);  -- Karte - Ystra-Frettchenjunges
  db:priv_AddDB("Cards", 770100);  -- Karte - Frostholztal-Zyklop
  db:priv_AddDB("Cards", 770101);  -- 
  db:priv_AddDB("Cards", 770102);  -- Karte - Minotauren-Patrouille
  db:priv_AddDB("Cards", 770103);  -- Karte - Altes Rentier
  db:priv_AddDB("Cards", 770104);  -- Karte - Wild-Berhu
  db:priv_AddDB("Cards", 770105);  -- Karte - Carfcamoi
  db:priv_AddDB("Cards", 770106);  -- Karte - Ystra-Schneefrettchen
  db:priv_AddDB("Cards", 770107);  -- Karte - Schatten des Berhu-K?nigs
  db:priv_AddDB("Cards", 770108);  -- Karte - Ystra-Winterspinne
  db:priv_AddDB("Cards", 770109);  -- Karte - Feueraugen-Schneefrettchen
  db:priv_AddDB("Cards", 770110);  -- Karte - Ystra-Schneefrosch
  db:priv_AddDB("Cards", 770111);  -- Karte - Zottelschneeb?r
  db:priv_AddDB("Cards", 770112);  -- Karte - Ystra-Eiskrebs
  db:priv_AddDB("Cards", 770113);  -- Karte - Schwarzm?hnenfuchs
  db:priv_AddDB("Cards", 770114);  -- Karte - Winternacht-Eisfee
  db:priv_AddDB("Cards", 770115);  -- Karte - Winternacht-Eishexe
  db:priv_AddDB("Cards", 770116);  -- Karte - Enoch-Blaufalter
  db:priv_AddDB("Cards", 770117);  -- Karte - Hochland-D?monenkraut
  db:priv_AddDB("Cards", 770118);  -- Karte - Quirlag, Sohn des Erddrachen
  db:priv_AddDB("Cards", 770119);  -- Karte - Steinkrallendrache
  db:priv_AddDB("Cards", 770120);  -- Karte - Schreiender Gargoyle
  db:priv_AddDB("Cards", 770121);  -- Karte - Boshafter Gargoyle
  db:priv_AddDB("Cards", 770122);  -- Karte - Eisechse
  db:priv_AddDB("Cards", 770123);  -- Karte - Minotauren-Kommandant
  db:priv_AddDB("Cards", 770124);  -- Karte - Minotauren-Wache
  db:priv_AddDB("Cards", 770125);  -- Karte - Minotauren-Priester
  db:priv_AddDB("Cards", 770126);  -- Karte - Ralpher Dunkelmond
  db:priv_AddDB("Cards", 770127);  -- Karte - Prinktar Sandhuf
  db:priv_AddDB("Cards", 770128);  -- Karte - Sheren Scharfaxt
  db:priv_AddDB("Cards", 770129);  -- Karte - Aucloy Riesenhorn
  db:priv_AddDB("Cards", 770130);  -- Karte - Ghul-Minotaurus
  db:priv_AddDB("Cards", 770131);  -- Karte - Enoch-Giftlibelle
  db:priv_AddDB("Cards", 770132);  -- Karte - J?nger
  db:priv_AddDB("Cards", 770133);  -- Karte - Flitzeschatten
  db:priv_AddDB("Cards", 770134);  -- Karte - Androliers St?rke
  db:priv_AddDB("Cards", 770135);  -- Karte - Kampfpanzer
  db:priv_AddDB("Cards", 770136);  -- Karte - Verw?nschte Robe
  db:priv_AddDB("Cards", 770137);  -- Karte - Kummerkristall
  db:priv_AddDB("Cards", 770138);  -- Karte - Hasskristall
  db:priv_AddDB("Cards", 770139);  -- Karte - Androliers Schatten
  db:priv_AddDB("Cards", 770140);  -- Karte - Schatten des Verlangens
  db:priv_AddDB("Cards", 770141);  -- Karte - Androliers Gefangener
  db:priv_AddDB("Cards", 770142);  -- Karte - Krodamon
  db:priv_AddDB("Cards", 770143);  -- Karte - Krodamar
  db:priv_AddDB("Cards", 770144);  -- Karte - Magister Gumas
  db:priv_AddDB("Cards", 770145);  -- Karte - Schreckenskristall
  db:priv_AddDB("Cards", 770146);  -- Karte - Riesen-Nadelkaktus
  db:priv_AddDB("Cards", 770147);  -- Karte - Riesen-Bl?tenkaktus
  db:priv_AddDB("Cards", 770148);  -- Karte - Verw?nschter Eisengolem
  db:priv_AddDB("Cards", 770149);  -- Karte - Razeela
  db:priv_AddDB("Cards", 770150);  -- Karte - Dorlos
  db:priv_AddDB("Cards", 770151);  -- Karte - Flammender Albtraum
  db:priv_AddDB("Cards", 770152);  -- 
  db:priv_AddDB("Cards", 770153);  -- Karte - Mana-Fledermaus
  db:priv_AddDB("Cards", 770154);  -- Karte - Panzerknackerskorpion
  db:priv_AddDB("Cards", 770155);  -- Karte - Zurhidon-Wache
  db:priv_AddDB("Cards", 770156);  -- Karte - Dunkelk?fer
  db:priv_AddDB("Cards", 770157);  -- Karte - Zurhidon-Soldat
  db:priv_AddDB("Cards", 770158);  -- Karte - Zurhidon-R?uber
  db:priv_AddDB("Cards", 770159);  -- Karte - Unterwelt-Morkusbestie
  db:priv_AddDB("Cards", 770160);  -- Karte - Traumfresser
  db:priv_AddDB("Cards", 770161);  -- Karte - Riesen-Fruchtkaktus
  db:priv_AddDB("Cards", 770162);  -- Karte - Bl?tenkaktus
  db:priv_AddDB("Cards", 770163);  -- Karte - Fruchtkaktus
  db:priv_AddDB("Cards", 770164);  -- Karte - Nadelkaktus
  db:priv_AddDB("Cards", 770165);  -- Karte - F?ulnis-Libelle
  db:priv_AddDB("Cards", 770166);  -- Karte - Schwarzfelsskorpion
  db:priv_AddDB("Cards", 770167);  -- Karte - Stachelschwanzskorpion
  db:priv_AddDB("Cards", 770168);  -- Karte - Hochlandleguan
  db:priv_AddDB("Cards", 770169);  -- Karte - Schimmerschuppenleguan
  db:priv_AddDB("Cards", 770170);  -- Karte - Sturmh?he-J?gerin
  db:priv_AddDB("Cards", 770171);  -- Karte - Sturmh?he-Schamane
  db:priv_AddDB("Cards", 770172);  -- Karte - Sturmh?he-Krieger
  db:priv_AddDB("Cards", 770173);  -- Karte - Hy?ne aus dem Roten Tal
  db:priv_AddDB("Cards", 770174);  -- Karte - Enoch-Scharlach-Scharfzahn
  db:priv_AddDB("Cards", 770175);  -- Karte - Nebelwaldk?fer
  db:priv_AddDB("Cards", 770176);  -- Karte - Sturmh?he-Tierausbilder
  db:priv_AddDB("Cards", 770177);  -- Karte - Sturmh?he-Adlerk?mpferin
  db:priv_AddDB("Cards", 770178);  -- Karte - Boedem
  db:priv_AddDB("Cards", 770179);  -- Karte - Tal-Fels-Skorpion
  db:priv_AddDB("Cards", 770180);  -- Karte - Feuerechse
  db:priv_AddDB("Cards", 770181);  -- Karte - Moosbedeckter Sharpro
  db:priv_AddDB("Cards", 770182);  -- Karte - Myrmex-K?nigin von Kal-Turok
  db:priv_AddDB("Cards", 770183);  -- Karte - Kal-Turok-Myrmex
  db:priv_AddDB("Cards", 770184);  -- Karte - Arbeiter-Myrmex von Kal-Turok
  db:priv_AddDB("Cards", 770185);  -- Karte - Myrmex-Soldat von Kal-Turok
  db:priv_AddDB("Cards", 770186);  -- Karte - Myrmex-K?nig von Kal-Turok
  db:priv_AddDB("Cards", 770187);  -- Karte - Mutierter Knospenwurm
  db:priv_AddDB("Cards", 770188);  -- Karte - Kal'Turstan
  db:priv_AddDB("Cards", 770189);  -- Karte - Kal'Turssi
  db:priv_AddDB("Cards", 770190);  -- Karte - Mumifizierter Mann
  db:priv_AddDB("Cards", 770191);  -- Karte - Weibliche ausgezehrte Seele
  db:priv_AddDB("Cards", 770192);  -- Karte - Schamane Yeda
  db:priv_AddDB("Cards", 770193);  -- Karte - Kr?he
  db:priv_AddDB("Cards", 770194);  -- Karte - Enoch-Baumk?fer
  db:priv_AddDB("Cards", 770195);  -- Karte - Mineralskorpion
  db:priv_AddDB("Cards", 770196);  -- Karte - Kristallechse
  db:priv_AddDB("Cards", 770197);  -- Karte - Nebelwaldkeiler
  db:priv_AddDB("Cards", 770198);  -- Karte - Sturmharpyie
  db:priv_AddDB("Cards", 770199);  -- Karte - Eisenklauenharpyie
  db:priv_AddDB("Cards", 770200);  -- Karte - Rotfl?gelharpyie
  db:priv_AddDB("Cards", 770201);  -- Karte - Ayelo
  db:priv_AddDB("Cards", 770202);  -- Karte - Vogel der Schwermut
  db:priv_AddDB("Cards", 770203);  -- 
  db:priv_AddDB("Cards", 770204);  -- Karte - M?nnliche ausgezehrte Seele
  db:priv_AddDB("Cards", 770205);  -- Karte - H?gelschleicher
  db:priv_AddDB("Cards", 770206);  -- Karte - Totholz-J?ger
  db:priv_AddDB("Cards", 770207);  -- Karte - Flammenfl?gel
  db:priv_AddDB("Cards", 770208);  -- Karte - Roter Panzerwolf
  db:priv_AddDB("Cards", 770209);  -- Karte - Nebelwald-D?monenkraut
  db:priv_AddDB("Cards", 770210);  -- Karte - Knochenbrecher
  db:priv_AddDB("Cards", 770211);  -- Karte - Runenschneegeist
  db:priv_AddDB("Cards", 770212);  -- Karte - Blutd?rstige Welkblatt-Fledermaus
  db:priv_AddDB("Cards", 770213);  -- Karte - Dunkelgr?ne Fledermaus
  db:priv_AddDB("Cards", 770214);  -- Karte - Boshafte Nachtschatten-Fledermaus
  db:priv_AddDB("Cards", 770215);  -- Karte - Finstere Magie-Fledermaus
  db:priv_AddDB("Cards", 770216);  -- Karte - Graf Hibara
  db:priv_AddDB("Cards", 770217);  -- Karte - Graf Hibara
  db:priv_AddDB("Cards", 770218);  -- Karte - Taylin Fischgr?te
  db:priv_AddDB("Cards", 770219);  -- Karte - Bronzepanzer-Scooray
  db:priv_AddDB("Cards", 770220);  -- Karte - Kratzklaue Hammerzahn
  db:priv_AddDB("Cards", 770221);  -- Karte - Chester Eisenpanzer
  db:priv_AddDB("Cards", 770222);  -- Karte - Roter Kroon-Skorpion
  db:priv_AddDB("Cards", 770223);  -- Karte - Akeli der Weise
  db:priv_AddDB("Cards", 770224);  -- Karte - Perodia
  db:priv_AddDB("Cards", 770225);  -- Karte - Sauropus
  db:priv_AddDB("Cards", 770226);  -- Karte - Ambas
  db:priv_AddDB("Cards", 770227);  -- Karte - Rachegeist
  db:priv_AddDB("Cards", 770228);  -- Karte - Anf?hrer der Kobold-Pl?nderer
  db:priv_AddDB("Cards", 770229);  -- Karte - Kobold-Schamane
  db:priv_AddDB("Cards", 770230);  -- Karte - Kipos
  db:priv_AddDB("Cards", 770231);  -- Karte - Kobold-Nachschuboffizier
  db:priv_AddDB("Cards", 770232);  -- Karte - Wirbelwind-K?fer
  db:priv_AddDB("Cards", 770233);  -- Karte - Pirlanok-Diener
  db:priv_AddDB("Cards", 770234);  -- Karte - Gefr??iger Kalod
  db:priv_AddDB("Cards", 770235);  -- Karte - Verlorene Seele von Tifka
  db:priv_AddDB("Cards", 770236);  -- Karte - Grasland-Heulwolf
  db:priv_AddDB("Cards", 770237);  -- Karte - Sturmkeiler
  db:priv_AddDB("Cards", 770238);  -- Karte - Giftlibelle
  db:priv_AddDB("Cards", 770239);  -- Karte - Tal-T?lpel
  db:priv_AddDB("Cards", 770240);  -- Karte - Tal-Stinker
  db:priv_AddDB("Cards", 770241);  -- Karte - Panzer-Ameisenb?r
  db:priv_AddDB("Cards", 770242);  -- Karte - Scharfkrallen-Ameisenb?r
  db:priv_AddDB("Cards", 770243);  -- Karte - Eisenschwanz-Ameisenb?r
  db:priv_AddDB("Cards", 770244);  -- Karte - Scharfzahn-Schwein
  db:priv_AddDB("Cards", 770245);  -- Karte - Feuerm?hnen-Schwein
  db:priv_AddDB("Cards", 770246);  -- Karte - Khazor-Rentier
  db:priv_AddDB("Cards", 770247);  -- Karte - Schneemeer-Zyklop
  db:priv_AddDB("Cards", 770248);  -- Karte - Schneemeer-Berhu
  db:priv_AddDB("Cards", 770249);  -- Karte - Schwarzwindskorpion
  db:priv_AddDB("Cards", 770250);  -- Karte - Alter Leguan
  db:priv_AddDB("Cards", 770251);  -- Karte - Giftiger Höhlenskorpion
  db:priv_AddDB("Cards", 770252);  -- Karte - Schl?ger der blutroten Karawane
  db:priv_AddDB("Cards", 770253);  -- Karte - Höhlensandk?fer
  db:priv_AddDB("Cards", 770254);  -- 
  db:priv_AddDB("Cards", 770255);  -- Karte - Koboldw?chter
  db:priv_AddDB("Cards", 770256);  -- Karte - Kobold-Expertengr?ber
  db:priv_AddDB("Cards", 770257);  -- Karte - Kobold-Genie
  db:priv_AddDB("Cards", 770258);  -- Karte - Kobold-Schattenschreiter
  db:priv_AddDB("Cards", 770259);  -- Karte - Anglo
  db:priv_AddDB("Cards", 770260);  -- Karte - Angstelement
  db:priv_AddDB("Cards", 770261);  -- Karte - Kalter Schatten
  db:priv_AddDB("Cards", 770262);  -- Karte - Schatten des Gefangenen
  db:priv_AddDB("Cards", 770263);  -- Karte - B?ser Schatten
  db:priv_AddDB("Cards", 770264);  -- Karte - Bluttrinker-Schatten
  db:priv_AddDB("Cards", 770265);  -- Karte - Kopfloser Krieger
  db:priv_AddDB("Cards", 770266);  -- Karte - Untoter Sucher
  db:priv_AddDB("Cards", 770267);  -- Karte - Leiche des Schatzsuchers
  db:priv_AddDB("Cards", 770268);  -- Karte - Schwarzkern-W?chter
  db:priv_AddDB("Cards", 770269);  -- Karte - Sturmenergie-W?chter
  db:priv_AddDB("Cards", 770270);  -- Karte - Frostenergie-W?chter
  db:priv_AddDB("Cards", 770271);  -- Karte - Priester der heiligen Rune
  db:priv_AddDB("Cards", 770272);  -- Karte - Flammenrunenschwertk?mpfer
  db:priv_AddDB("Cards", 770273);  -- Karte - Frostrunen-W?chter
  db:priv_AddDB("Cards", 770274);  -- Karte - Brennender Giftkristall
  db:priv_AddDB("Cards", 770275);  -- Karte - T?dlicher Giftkristall
  db:priv_AddDB("Cards", 770276);  -- Karte - Imitator
  db:priv_AddDB("Cards", 770277);  -- Karte - FelsenHüter
  db:priv_AddDB("Cards", 770278);  -- Karte - Kalter Stahlw?chter
  db:priv_AddDB("Cards", 770279);  -- Karte - Geh?rnter W?chter
  db:priv_AddDB("Cards", 770280);  -- Karte - Chaosbringer
  db:priv_AddDB("Cards", 770281);  -- Karte - Sch?pfer der Geisterwache
  db:priv_AddDB("Cards", 770282);  -- Karte - Runenw?chter-Anf?hrer
  db:priv_AddDB("Cards", 770283);  -- Karte - Raichika der Zerst?rer
  db:priv_AddDB("Cards", 770284);  -- Karte - Leichenw?chter
  db:priv_AddDB("Cards", 770285);  -- Karte - B?ser Knochenw?chter
  db:priv_AddDB("Cards", 770286);  -- Karte - Ousul-Salamander
  db:priv_AddDB("Cards", 770287);  -- Karte - Ousul-Giftfrosch
  db:priv_AddDB("Cards", 770288);  -- Karte - Bezaubernde Jungfrau der Musen
  db:priv_AddDB("Cards", 770289);  -- Karte - Wahnsinnige Jungfrau der Musen
  db:priv_AddDB("Cards", 770290);  -- Karte - Traurige Jungfrau der Musen
  db:priv_AddDB("Cards", 770291);  -- Karte - Runenw?chter
  db:priv_AddDB("Cards", 770292);  -- Karte - RunenHüter
  db:priv_AddDB("Cards", 770293);  -- Karte - Runenvernichter
  db:priv_AddDB("Cards", 770294);  -- Karte - Runenpatrouille
  db:priv_AddDB("Cards", 770295);  -- Karte - Enoch-Pukari
  db:priv_AddDB("Cards", 770296);  -- Karte - Eiserner Runenkrieger
  db:priv_AddDB("Cards", 770297);  -- Karte - Yusalien
  db:priv_AddDB("Cards", 770298);  -- Karte - Locatha
  db:priv_AddDB("Cards", 770299);  -- Karte - Adept der G?ttin der K?nste
  db:priv_AddDB("Cards", 770300);  -- Karte - Ensia
  db:priv_AddDB("Cards", 770301);  -- Karte - Regin
  db:priv_AddDB("Cards", 770302);  -- Karte - Agriza-Krieger
  db:priv_AddDB("Cards", 770303);  -- Karte - Agriza-General
  db:priv_AddDB("Cards", 770304);  -- Karte - Unbezwingbarer Barbarensoldat
  db:priv_AddDB("Cards", 770305);  -- 
  db:priv_AddDB("Cards", 770306);  -- Karte - Agriza-Belagerungssoldat
  db:priv_AddDB("Cards", 770307);  -- Karte - Agriza-Schl?ger
  db:priv_AddDB("Cards", 770308);  -- Karte - Agriza-Angreifer
  db:priv_AddDB("Cards", 770309);  -- Karte - Agriza-Wolfsreiter
  db:priv_AddDB("Cards", 770310);  -- Karte - Rasender Riesenwolf
  db:priv_AddDB("Cards", 770311);  -- Karte - Sturmbeschw?rer
  db:priv_AddDB("Cards", 770312);  -- Karte - Agriza-Verteidiger
  db:priv_AddDB("Cards", 770313);  -- Karte - Agriza-Heiler
  db:priv_AddDB("Cards", 770314);  -- 
  db:priv_AddDB("Cards", 770315);  -- Karte - Zurhidon-Medium
  db:priv_AddDB("Cards", 770316);  -- Karte - Zurhidon-Unterst?tzer
  db:priv_AddDB("Cards", 770317);  -- Karte - Zurhidon-Unterh?ndler
  db:priv_AddDB("Cards", 770318);  -- Karte - Podag
  db:priv_AddDB("Cards", 770319);  -- Karte - Masso
  db:priv_AddDB("Cards", 770320);  -- Karte - Gaia
  db:priv_AddDB("Cards", 770321);  -- Karte - Ortiga
  db:priv_AddDB("Cards", 770322);  -- Karte - Uguda
  db:priv_AddDB("Cards", 770323);  -- Karte - Wills Fluch
  db:priv_AddDB("Cards", 770324);  -- Karte - Treuer Talomo
  db:priv_AddDB("Cards", 770325);  -- Karte - Fels-Sidaar
  db:priv_AddDB("Cards", 770326);  -- Karte - Dreiaugen-Luke
  db:priv_AddDB("Cards", 770327);  -- Karte - Snow Blake
  db:priv_AddDB("Cards", 770328);  -- Karte - Schwarzsegel-Matrose
  db:priv_AddDB("Cards", 770329);  -- Karte - Schwarzsegel-Steuermann
  db:priv_AddDB("Cards", 770330);  -- Karte - Schwarzsegel-Bluttrinker
  db:priv_AddDB("Cards", 770331);  -- Karte - Snows Ergebener
  db:priv_AddDB("Cards", 770332);  -- Karte - Schwarzsegel-Wellenbrecher
  db:priv_AddDB("Cards", 770333);  -- Karte - Blakes Geheimagentin
  db:priv_AddDB("Cards", 770334);  -- Karte - Schwarzsegel-Angreifer
  db:priv_AddDB("Cards", 770335);  -- Karte - Blake-M?rderin
  db:priv_AddDB("Cards", 770336);  -- Karte - Tiefseefluch
  db:priv_AddDB("Cards", 770337);  -- Karte - Tiefseealbtraum
  db:priv_AddDB("Cards", 770338);  -- Karte - Verfluchter Schwarzsegel-Matrose
  db:priv_AddDB("Cards", 770339);  -- Karte - Verfluchter Schwarzsegel-Pirat
  db:priv_AddDB("Cards", 770340);  -- Karte - Kleiner W?stenfuchs
  db:priv_AddDB("Cards", 770341);  -- Karte - Falke
  db:priv_AddDB("Cards", 770342);  -- Karte - Egar-Lebenskraftvogel
  db:priv_AddDB("Cards", 770343);  -- Karte - Riesenmoosnashorn
  db:priv_AddDB("Cards", 770344);  -- Karte - Sturmnashornm?nnchen
  db:priv_AddDB("Cards", 770345);  -- Karte - Runenstein-KlingenHüter
  db:priv_AddDB("Cards", 770346);  -- Karte - Kriegerische Reliquienwache
  db:priv_AddDB("Cards", 770347);  -- Karte - Runensteinsch?tzer
  db:priv_AddDB("Cards", 770348);  -- Karte - Kriegerischer Reliquiensch?tzer
  db:priv_AddDB("Cards", 770349);  -- Karte - Runenstein-Felsenwache
  db:priv_AddDB("Cards", 770350);  -- Karte - Riesen-Talmilan
  db:priv_AddDB("Cards", 770351);  -- Karte - Riesiger Gr?nschwingen-Schwarzmilan
  db:priv_AddDB("Cards", 770352);  -- Karte - Riesiger Klippen-Regenbogenmilan
  db:priv_AddDB("Cards", 770353);  -- Karte - Lauernder Scalok
  db:priv_AddDB("Cards", 770354);  -- Karte - Glanzschuppen-Molch
  db:priv_AddDB("Cards", 770355);  -- Karte - Treibender Alga-Krebs
  db:priv_AddDB("Cards", 770356);  -- Karte - Knurrender Jagdhund
  db:priv_AddDB("Cards", 770357);  -- 
  db:priv_AddDB("Cards", 770358);  -- Karte - Grasland-Pl?nderer
  db:priv_AddDB("Cards", 770359);  -- Karte - Blaine
  db:priv_AddDB("Cards", 770360);  -- Karte - Neblund-Sucher
  db:priv_AddDB("Cards", 770361);  -- Karte - Neblund-Aufschneider
  db:priv_AddDB("Cards", 770362);  -- Karte - Neblund-Schleicher
  db:priv_AddDB("Cards", 770363);  -- Karte - Wilde Klinge - Ardise
  db:priv_AddDB("Cards", 770364);  -- Karte - Schwarzhorn-Patrouille
  db:priv_AddDB("Cards", 770365);  -- Karte - Schwarzhorn-Hüter
  db:priv_AddDB("Cards", 770366);  -- Karte - Schwarzhorn-Pl?nkler
  db:priv_AddDB("Cards", 770367);  -- Karte - Schwarzhorn-Anf?hrer
  db:priv_AddDB("Cards", 770368);  -- Karte - Elite-Schwarzhorn-Hüter
  db:priv_AddDB("Cards", 770369);  -- Karte - Sturzflut-Riesenkrebs
  db:priv_AddDB("Cards", 770370);  -- Karte - Fellschwein
  db:priv_AddDB("Cards", 770371);  -- Karte - W?tender Scalok
  db:priv_AddDB("Cards", 770372);  -- Karte - Purpurlibelle
  db:priv_AddDB("Cards", 770373);  -- Karte - Rotfederstrau?
  db:priv_AddDB("Cards", 770374);  -- Karte - Zyklopen-Milit?ringenieur
  db:priv_AddDB("Cards", 770375);  -- Karte - Zurhidon-Assistent
  db:priv_AddDB("Cards", 770376);  -- Karte - Zurhidon-Vollstrecker
  db:priv_AddDB("Cards", 770377);  -- Karte - Zurhidon-Transporteur
  db:priv_AddDB("Cards", 770378);  -- Karte - Felsenbestie
  db:priv_AddDB("Cards", 770379);  -- Karte - Zyklopen-Berserker
  db:priv_AddDB("Cards", 770380);  -- Karte - Zyklopen-Offizier
  db:priv_AddDB("Cards", 770381);  -- Karte - Enoch-Mosto
  db:priv_AddDB("Cards", 770382);  -- Karte - Renngazelle
  db:priv_AddDB("Cards", 770383);  -- Karte - Wilder Riesenwolf
  db:priv_AddDB("Cards", 770384);  -- Karte - Wildes Rhinozeros
  db:priv_AddDB("Cards", 770385);  -- Karte - Talmilan
  db:priv_AddDB("Cards", 770386);  -- Karte - Gr?nschwingen-Schwarzmilan
  db:priv_AddDB("Cards", 770387);  -- Karte - Klippen-Regenbogenmilan
  db:priv_AddDB("Cards", 770388);  -- Karte - Blauer Egar-Vogel
  db:priv_AddDB("Cards", 770389);  -- Karte - B?ses Kugelmonster
  db:priv_AddDB("Cards", 770390);  -- Karte - Dunkler Baumwollwurm
  db:priv_AddDB("Cards", 770391);  -- Karte - Wilde M?hne
  db:priv_AddDB("Cards", 770392);  -- Karte - Geheimnisvoller Riesenwolf
  db:priv_AddDB("Cards", 770393);  -- Karte - Phant
  db:priv_AddDB("Cards", 770394);  -- Karte - Kobold-Sammler
  db:priv_AddDB("Cards", 770395);  -- Karte - Kobold-Arzt
  db:priv_AddDB("Cards", 770396);  -- Karte - Kobold-Sp?her
  db:priv_AddDB("Cards", 770397);  -- Karte - Sumpfland-Giftfrosch
  db:priv_AddDB("Cards", 770398);  -- Karte - Schlammmolch
  db:priv_AddDB("Cards", 770399);  -- Karte - Wilder Scalok
  db:priv_AddDB("Cards", 770400);  -- Karte - Rotschwanzfrosch
  db:priv_AddDB("Cards", 770401);  -- Karte - Dreistreifenschwein
  db:priv_AddDB("Cards", 770402);  -- Karte - Schwebendes Kugelmonster
  db:priv_AddDB("Cards", 770403);  -- Karte - Gestreifte Gazelle
  db:priv_AddDB("Cards", 770404);  -- Karte - Springgras
  db:priv_AddDB("Cards", 770405);  -- Karte - Junger Springbock
  db:priv_AddDB("Cards", 770406);  -- Karte - Gro?horn-St?rmer
  db:priv_AddDB("Cards", 770407);  -- Karte - Langhorn-Springer
  db:priv_AddDB("Cards", 770408);  -- 
  db:priv_AddDB("Cards", 770409);  -- Karte - Kristallkugel-Korn
  db:priv_AddDB("Cards", 770410);  -- Karte - Hochlandechse
  db:priv_AddDB("Cards", 770411);  -- Karte - Riesenhuf-Rentier
  db:priv_AddDB("Cards", 770412);  -- Karte - Riesen-Frostwolf
  db:priv_AddDB("Cards", 770413);  -- Karte - Eisw?sten-S?belzahntiger
  db:priv_AddDB("Cards", 770414);  -- Karte - Nebelwald-Gulo
  db:priv_AddDB("Cards", 770415);  -- Karte - Mammut-Mutter
  db:priv_AddDB("Cards", 770416);  -- Karte - Mammutkalb
  db:priv_AddDB("Cards", 770417);  -- Karte - Sto?zahnmammut der Eisw?ste
  db:priv_AddDB("Cards", 770418);  -- Karte - Wildmammut der Eisw?ste
  db:priv_AddDB("Cards", 770419);  -- Karte - Ayson
  db:priv_AddDB("Cards", 770420);  -- Karte - Eiszwerg-Soldat
  db:priv_AddDB("Cards", 770421);  -- Karte - Anf?hrer der Eiszwerg-Wache
  db:priv_AddDB("Cards", 770422);  -- Karte - Eiszwerg-Priester
  db:priv_AddDB("Cards", 770423);  -- Karte - Eiszwerg-Gladiator
  db:priv_AddDB("Cards", 770424);  -- Karte - Eiszwerg-Arbeiter
  db:priv_AddDB("Cards", 770425);  -- Karte - Nebelwaldfrontgauner
  db:priv_AddDB("Cards", 770426);  -- Karte - Nebelwaldfrontmagier
  db:priv_AddDB("Cards", 770427);  -- Karte - Riesen-Eisw?sten-B?r
  db:priv_AddDB("Cards", 770428);  -- Karte - Riesen-Eisb?r
  db:priv_AddDB("Cards", 770429);  -- Karte - Gefl?gelter Knochendrachen
  db:priv_AddDB("Cards", 770430);  -- Karte - Gefl?gelter Eisdrachen
  db:priv_AddDB("Cards", 770431);  -- Karte - Gefl?gelter K?ltedrachen
  db:priv_AddDB("Cards", 770432);  -- Karte - Rentier
  db:priv_AddDB("Cards", 770433);  -- Karte - Junger Schneefuchs
  db:priv_AddDB("Cards", 770434);  -- Karte - Nebelwaldfront-Magierwache
  db:priv_AddDB("Cards", 770435);  -- Karte - Drachenzahn-Wildschwein
  db:priv_AddDB("Cards", 770436);  -- Karte - Drachenzahn-Wolf
  db:priv_AddDB("Cards", 770437);  -- Karte - Drachenzahn-Grizzly
  db:priv_AddDB("Cards", 770438);  -- Karte - Zadarha
  db:priv_AddDB("Cards", 770439);  -- Karte - Zurhidon-Anh?nger
  db:priv_AddDB("Cards", 770440);  -- Karte - Zurhidon-Anh?nger
  db:priv_AddDB("Cards", 770441);  -- Karte - Riesengrimmwolf
  db:priv_AddDB("Cards", 770442);  -- Karte - Kampfschwein
  db:priv_AddDB("Cards", 770443);  -- Karte - Nebelwaldfrontpriester
  db:priv_AddDB("Cards", 770444);  -- Karte - Agriza-Aufseher
  db:priv_AddDB("Cards", 770445);  -- Karte - Agriza-Patrouille
  db:priv_AddDB("Cards", 770446);  -- Karte - Agriza-Sucher
  db:priv_AddDB("Cards", 770447);  -- Karte - Agriza-Schildtr?ger
  db:priv_AddDB("Cards", 770448);  -- Karte - Agriza-Koch
  db:priv_AddDB("Cards", 770449);  -- Karte - Agriza-Hoplit
  db:priv_AddDB("Cards", 770450);  -- Karte - Agriza-Infanterist
  db:priv_AddDB("Cards", 770451);  -- Karte - Agriza-Raufbold
  db:priv_AddDB("Cards", 770452);  -- Karte - Saerzhate Kayen
  db:priv_AddDB("Cards", 770453);  -- Karte - Seris Kodun
  db:priv_AddDB("Cards", 770454);  -- Karte - Tak Modun
  db:priv_AddDB("Cards", 770455);  -- Karte - Blutklaue
  db:priv_AddDB("Cards", 770456);  -- Karte - Schwein
  db:priv_AddDB("Cards", 770457);  -- Karte - Aris Dori
  db:priv_AddDB("Cards", 770458);  -- Karte - Sethet Balen
  db:priv_AddDB("Cards", 770459);  -- 
  db:priv_AddDB("Cards", 770460);  -- Karte - Hochland-S?belzahntiger
  db:priv_AddDB("Cards", 770461);  -- Karte - Drachenzahn-Eisbestie
  db:priv_AddDB("Cards", 770462);  -- Karte - Pl?nderer der wilden Bande
  db:priv_AddDB("Cards", 770463);  -- Karte - R?uber der wilden Bande
  db:priv_AddDB("Cards", 770464);  -- Karte - Patrouille der wilden Bande
  db:priv_AddDB("Cards", 770465);  -- Karte - Besetzer der wilden Bande
  db:priv_AddDB("Cards", 770466);  -- Karte - Assassine der Schneeklauen
  db:priv_AddDB("Cards", 770467);  -- Karte - Schneeklauen-Sp?her
  db:priv_AddDB("Cards", 770468);  -- Karte - Schneeklauen-Giftmischer
  db:priv_AddDB("Cards", 770469);  -- Karte - Schneeklauen-Sucher
  db:priv_AddDB("Cards", 770470);  -- Karte - Schneeklauen-Speertr?ger
  db:priv_AddDB("Cards", 770471);  -- Karte - Schneeklauen-Verteidiger
  db:priv_AddDB("Cards", 770472);  -- Karte - Colin der Schneeklauen-Anf?hrer
  db:priv_AddDB("Cards", 770473);  -- Karte - Gutch der Schneeklauen-Anf?hrer
  db:priv_AddDB("Cards", 770474);  -- Karte - Bogensch?tze der wilden Bande
  db:priv_AddDB("Cards", 770475);  -- Karte - Hammerwerfer der wilden Bande
  db:priv_AddDB("Cards", 770476);  -- Karte - Axtk?mpfer der wilden Bande
  db:priv_AddDB("Cards", 770477);  -- Karte - Schwarzm?hnen-Verteidiger
  db:priv_AddDB("Cards", 770478);  -- Karte - Schwarzm?hnen-W?chter
  db:priv_AddDB("Cards", 770479);  -- Karte - Schwarzm?hnen-Patrouille
  db:priv_AddDB("Cards", 770480);  -- Karte - Schwarzm?hnen-Anf?hrer
  db:priv_AddDB("Cards", 770481);  -- Karte - Schwarzm?hnen-Bogensch?tze
  db:priv_AddDB("Cards", 770482);  -- Karte - Schwarzm?hnen-Gefangener
  db:priv_AddDB("Cards", 770483);  -- Karte - Schwarzm?hnen-Angreifer
  db:priv_AddDB("Cards", 770484);  -- Karte - Schwarzm?hnen-Anf?hrer Porker
  db:priv_AddDB("Cards", 770485);  -- Karte - Schnee-Rentier
  db:priv_AddDB("Cards", 770486);  -- Karte - W?lfe jagender S?belzahntiger
  db:priv_AddDB("Cards", 770487);  -- Karte - Wei?m?hne-Riesenwolf
  db:priv_AddDB("Cards", 770488);  -- Karte - Buriz
  db:priv_AddDB("Cards", 770489);  -- Karte - Vierfl?gel-Geier
  db:priv_AddDB("Cards", 770490);  -- Karte - Trockenes D?monenkraut
  db:priv_AddDB("Cards", 770491);  -- Karte - Schwarzfl?gelrabe
  db:priv_AddDB("Cards", 770492);  -- Karte - ?dlandhy?ne
  db:priv_AddDB("Cards", 770493);  -- Karte - ?dland-Fl?gelfalter
  db:priv_AddDB("Cards", 770494);  -- Karte - Wind-Elementar
  db:priv_AddDB("Cards", 770495);  -- Karte - Rotgefleckter Krebs
  db:priv_AddDB("Cards", 770496);  -- Karte - Seefahrergeist
  db:priv_AddDB("Cards", 770497);  -- Karte - St?rmender Scealok
  db:priv_AddDB("Cards", 770498);  -- Karte - Tsunami-Scealok
  db:priv_AddDB("Cards", 770499);  -- Karte - Erdpanzer-Krebs
  db:priv_AddDB("Cards", 770500);  -- Karte - Ochsenfrosch
  db:priv_AddDB("Cards", 770501);  -- Karte - Schwarzpanzer-Krebs
  db:priv_AddDB("Cards", 770502);  -- Karte - Lamud
  db:priv_AddDB("Cards", 770503);  -- Karte - Hafenr?uber
  db:priv_AddDB("Cards", 770504);  -- Karte - Hafenschurke
  db:priv_AddDB("Cards", 770505);  -- Karte - Grausamer Schattenmond-Seefahrer
  db:priv_AddDB("Cards", 770506);  -- Karte - Elender Schattenmond-Seefahrer
  db:priv_AddDB("Cards", 770507);  -- Karte - Schattenmond-Wanderer
  db:priv_AddDB("Cards", 770508);  -- Karte - Huck
  db:priv_AddDB("Cards", 770509);  -- Karte - Nasenf?ule-Porgy
  db:priv_AddDB("Cards", 770510);  -- 
  db:priv_AddDB("Cards", 770511);  -- Karte - Todesland-Sandskorpion
  db:priv_AddDB("Cards", 770512);  -- Karte - Mutierter Sandskorpion
  db:priv_AddDB("Cards", 770513);  -- Karte - Todesland-Echse
  db:priv_AddDB("Cards", 770514);  -- Karte - Neep
  db:priv_AddDB("Cards", 770515);  -- Karte - Puppe des Todesland-Sandskorpions
  db:priv_AddDB("Cards", 770516);  -- Karte - Weibliche Sandskorpionlarve
  db:priv_AddDB("Cards", 770517);  -- Karte - M?nnliche Sandskorpionlarve
  db:priv_AddDB("Cards", 770518);  -- Karte - Nestw?chter
  db:priv_AddDB("Cards", 770519);  -- Karte - Sandbank-Chelone
  db:priv_AddDB("Cards", 770520);  -- Karte - Sandbankw?chter
  db:priv_AddDB("Cards", 770521);  -- Karte - Vagabundierender Schwarzsegel-Pirat
  db:priv_AddDB("Cards", 770522);  -- Karte - Lungernder Schwarzsegel-Steuermann
  db:priv_AddDB("Cards", 770523);  -- Karte - Geisterstadt-Wiederg?nger
  db:priv_AddDB("Cards", 770524);  -- Karte - Wilder Piratenwiederg?nger
  db:priv_AddDB("Cards", 770525);  -- Karte - Hafenbanditin
  db:priv_AddDB("Cards", 770526);  -- Karte - Hafendieb
  db:priv_AddDB("Cards", 770527);  -- Karte - Hafenvagabund
  db:priv_AddDB("Cards", 770528);  -- Karte - Agriza-Sturmtruppsoldat
  db:priv_AddDB("Cards", 770529);  -- Karte - Agriza-Sturmkampfwolf
  db:priv_AddDB("Cards", 770530);  -- Karte - Axis, Anf?hrer der Kampfw?lfe
  db:priv_AddDB("Cards", 770531);  -- Karte - Eisw?chter
  db:priv_AddDB("Cards", 770532);  -- Karte - Mula Kupfernagel
  db:priv_AddDB("Cards", 770533);  -- Karte - Crasset Fellfu?
  db:priv_AddDB("Cards", 770534);  -- Karte - W?chter des Magischen Eispanzers
  db:priv_AddDB("Cards", 770535);  -- Karte - Maulwurfk?nig
  db:priv_AddDB("Cards", 770536);  -- Karte - Wasserkristall-Cavia
  db:priv_AddDB("Cards", 770537);  -- Karte - Federkristall-Cavia
  db:priv_AddDB("Cards", 770538);  -- Karte - Erdriesen-Soldat
  db:priv_AddDB("Cards", 770539);  -- Karte - Kampf-Foger
  db:priv_AddDB("Cards", 770540);  -- Karte - Panzer-Foger
  db:priv_AddDB("Cards", 770541);  -- Karte - Eiszwerg-Stampfer
  db:priv_AddDB("Cards", 770542);  -- Karte - Eiszwerg-T?ter
  db:priv_AddDB("Cards", 770543);  -- Karte - Eiszwerg-Zerst?rer
  db:priv_AddDB("Cards", 770544);  -- Karte - Eiszwerg-Bote der Seelen
  db:priv_AddDB("Cards", 770545);  -- Karte - Eiszwerg-Bote der Elemente
  db:priv_AddDB("Cards", 770546);  -- Karte - Furchtloser Eiszwerg
  db:priv_AddDB("Cards", 770547);  -- Karte - Brutaler Eiszwerg
  db:priv_AddDB("Cards", 770548);  -- Karte - Kampf-Foger-Bestienz?hmer
  db:priv_AddDB("Cards", 770549);  -- Karte - Panzer-Foger-Bestienz?hmer
  db:priv_AddDB("Cards", 770550);  -- Karte - Eiszwerg-Rekrut
  db:priv_AddDB("Cards", 770551);  -- Karte - Eis-Arbeiter
  db:priv_AddDB("Cards", 770552);  -- Karte - Eiszwerg-Tr?ger
  db:priv_AddDB("Cards", 770553);  -- Karte - Regenbogenfalke
  db:priv_AddDB("Cards", 770554);  -- Karte - Rosafarbener Fl?gelfalter
  db:priv_AddDB("Cards", 770555);  -- Karte - Gr?nes Moosmonster
  db:priv_AddDB("Cards", 770556);  -- Karte - Suhlender Keucher
  db:priv_AddDB("Cards", 770557);  -- Karte - Schlammiger Keucher
  db:priv_AddDB("Cards", 770558);  -- Karte - Gr?ner Lakoso
  db:priv_AddDB("Cards", 770559);  -- Karte - Schlammiges Moosmonster
  db:priv_AddDB("Cards", 770560);  -- Karte - Doppelstachel-Hornisse
  db:priv_AddDB("Cards", 770561);  -- 
  db:priv_AddDB("Cards", 770562);  -- Karte - Wilder Pirat
  db:priv_AddDB("Cards", 770563);  -- Karte - Piratenveteran
  db:priv_AddDB("Cards", 770564);  -- Karte - Beh?nde Schwertk?mpferin
  db:priv_AddDB("Cards", 770565);  -- Karte - Piratenmatrose
  db:priv_AddDB("Cards", 770566);  -- Karte - Heimt?ckischer Matrose
  db:priv_AddDB("Cards", 770567);  -- Karte - Ayal-Krieger
  db:priv_AddDB("Cards", 770568);  -- Karte - Ayal-Priester
  db:priv_AddDB("Cards", 770569);  -- Karte - Ayal-H?uptling
  db:priv_AddDB("Cards", 770570);  -- Karte - Ayak-Fl?chtling
  db:priv_AddDB("Cards", 770571);  -- Karte - Ayat-Priester
  db:priv_AddDB("Cards", 770572);  -- Karte - Ayat-Zivilist
  db:priv_AddDB("Cards", 770573);  -- Karte - Ayat-H?uptling
  db:priv_AddDB("Cards", 770574);  -- Karte - Ayat-J?ger
  db:priv_AddDB("Cards", 770575);  -- Karte - Ayam-Zivilist
  db:priv_AddDB("Cards", 770576);  -- Karte - Ayam-J?ger
  db:priv_AddDB("Cards", 770577);  -- Karte - Ayam-Priester
  db:priv_AddDB("Cards", 770578);  -- Karte - Ayam-H?uptling
  db:priv_AddDB("Cards", 770579);  -- Karte - Fischmaul-Felskrebs
  db:priv_AddDB("Cards", 770580);  -- Karte - Wildrochen der K?ste der Wehklagen
  db:priv_AddDB("Cards", 770581);  -- Karte - Pfeilschwanzkrebs der K?ste der Wehklagen
  db:priv_AddDB("Cards", 770582);  -- Karte - Lakoso der K?ste der Wehklagen
  db:priv_AddDB("Cards", 770583);  -- Karte - Ayak-?berlebender
  db:priv_AddDB("Cards", 770584);  -- Karte - Seltsamer Besucher
  db:priv_AddDB("Cards", 770585);  -- Karte - Wasser-Elementar
  db:priv_AddDB("Cards", 770586);  -- Karte - Wasserriese
  db:priv_AddDB("Cards", 770587);  -- Karte - Waldfuchs
  db:priv_AddDB("Cards", 770588);  -- Karte - Totholzspinne
  db:priv_AddDB("Cards", 770589);  -- Karte - Waldleopard
  db:priv_AddDB("Cards", 770590);  -- Karte - Wandertroll
  db:priv_AddDB("Cards", 770591);  -- Karte - Gestreiftes S?gemaul
  db:priv_AddDB("Cards", 770592);  -- Karte - Roter Fl?gelfalter
  db:priv_AddDB("Cards", 770593);  -- Karte - Hartschuppen-S?gemaul
  db:priv_AddDB("Cards", 770594);  -- Karte - Bungajunges
  db:priv_AddDB("Cards", 770595);  -- Karte - Weibliche Bungabestie
  db:priv_AddDB("Cards", 770596);  -- Karte - Bungabestie
  db:priv_AddDB("Cards", 770597);  -- Karte - Verfallener Erdelementar
  db:priv_AddDB("Cards", 770598);  -- Karte - Riesensumpfwolf
  db:priv_AddDB("Cards", 770599);  -- Karte - Sumpf-Moosmonster
  db:priv_AddDB("Cards", 770600);  -- Karte - Hartsch?del-Gepard
  db:priv_AddDB("Cards", 770601);  -- Karte - Hartsch?del-J?ger
  db:priv_AddDB("Cards", 770602);  -- Karte - Hartsch?del-Krieger
  db:priv_AddDB("Cards", 770603);  -- Karte - Hartsch?del-Schamane
  db:priv_AddDB("Cards", 770604);  -- Karte - Cowadunga
  db:priv_AddDB("Cards", 770605);  -- Karte - Blutzahn-Rennwolf
  db:priv_AddDB("Cards", 770606);  -- Karte - Blutzahn-J?ger
  db:priv_AddDB("Cards", 770607);  -- Karte - Blutzahn-Krieger
  db:priv_AddDB("Cards", 770608);  -- Karte - Blutzahn-Schamane
  db:priv_AddDB("Cards", 770609);  -- Karte - Artmenlud
  db:priv_AddDB("Cards", 770610);  -- Karte - Scharlachrote Spinne
  db:priv_AddDB("Cards", 770611);  -- Karte - Kaa-Agent
  db:priv_AddDB("Cards", 770612);  -- 
  db:priv_AddDB("Cards", 770613);  -- Karte - Kaa-Hauptmann
  db:priv_AddDB("Cards", 770614);  -- Karte - Moriargy
  db:priv_AddDB("Cards", 770615);  -- Karte - Verfallener Angren
  db:priv_AddDB("Cards", 770616);  -- Karte - Zurhidon-Forscher
  db:priv_AddDB("Cards", 770617);  -- Karte - Reum?tiger Ayak
  db:priv_AddDB("Cards", 770618);  -- Karte - Blutbestie
  db:priv_AddDB("Cards", 770619);  -- Karte - Zinnoberroter Molch
  db:priv_AddDB("Cards", 770620);  -- Karte - Ayal-Zeremonienpriester
  db:priv_AddDB("Cards", 770621);  -- Karte - Ayal-Agent
  db:priv_AddDB("Cards", 770622);  -- Karte - Jungmolch
  db:priv_AddDB("Cards", 770623);  -- Karte - Gefr??ige Schnecke
  db:priv_AddDB("Cards", 770624);  -- Karte - Verfallener Jyr'na-Elf
  db:priv_AddDB("Cards", 770625);  -- Karte - Sto?zahnspinne
  db:priv_AddDB("Cards", 770626);  -- Karte - Dschungelschleicher
  db:priv_AddDB("Cards", 770627);  -- Karte - Kranker Ent
  db:priv_AddDB("Cards", 770628);  -- Karte - Regenbogenfl?gelfalter
  db:priv_AddDB("Cards", 770629);  -- Karte - Wei?es Höhlenkaninchen
  db:priv_AddDB("Cards", 770630);  -- Karte - Gefleckter K?fer
  db:priv_AddDB("Cards", 770631);  -- Karte - Heller Vogel
  db:priv_AddDB("Cards", 770632);  -- Karte - Lebhafter Ent
  db:priv_AddDB("Cards", 770633);  -- Karte - Gesunder Ent
  db:priv_AddDB("Cards", 770634);  -- Karte - Flachwasser-Lakoso
  db:priv_AddDB("Cards", 770635);  -- Karte - Ebenenwolf
  db:priv_AddDB("Cards", 770636);  -- Karte - Sporenwache
  db:priv_AddDB("Cards", 770637);  -- Karte - Sporenmeister
  db:priv_AddDB("Cards", 770638);  -- Karte - Bolida-Holz
  db:priv_AddDB("Cards", 770639);  -- Karte - Pfeifensee-?lfrosch
  db:priv_AddDB("Cards", 770640);  -- Karte - Pfeifensee-Krebs
  db:priv_AddDB("Cards", 770641);  -- Karte - Schwacher Ent
  db:priv_AddDB("Cards", 770642);  -- Karte - Staubstrau?
  db:priv_AddDB("Cards", 770643);  -- Karte - H?gelb?renjunges
  db:priv_AddDB("Cards", 770644);  -- Karte - Kajiazan
  db:priv_AddDB("Cards", 770645);  -- Karte - Sabineaner-Krieger
  db:priv_AddDB("Cards", 770646);  -- Karte - Sabineaner-Schamane
  db:priv_AddDB("Cards", 770647);  -- Karte - Erd-Cavia
  db:priv_AddDB("Cards", 770648);  -- Karte - Pangkor
  db:priv_AddDB("Cards", 770649);  -- Karte - Thynos
  db:priv_AddDB("Cards", 770650);  -- Karte - Bunter Fl?gelfalter
  db:priv_AddDB("Cards", 770651);  -- Karte - Goldengr?nes Kugelmonster
  db:priv_AddDB("Cards", 770652);  -- Karte - Wilder Riesenmilan
  db:priv_AddDB("Cards", 770653);  -- Karte - Wilde Riesenpython
  db:priv_AddDB("Cards", 770654);  -- Karte - Wilder Riesenb?r
  db:priv_AddDB("Cards", 770655);  -- Karte - Versteckter Panther
  db:priv_AddDB("Cards", 770656);  -- Karte - Gr?nwaldhirsch
  db:priv_AddDB("Cards", 770657);  -- Karte - Regenwaldj?ger
  db:priv_AddDB("Cards", 770658);  -- Karte - Wachsamer Affenmensch
  db:priv_AddDB("Cards", 770659);  -- Karte - Entstellter Affenmensch
  db:priv_AddDB("Cards", 770660);  -- Karte - Starker Affenmensch
  db:priv_AddDB("Cards", 770661);  -- Karte - Riesenaffenk?nig
  db:priv_AddDB("Cards", 770662);  -- Karte - Blauhimmel-Fischadler
  db:priv_AddDB("Cards", 770663);  -- 
  db:priv_AddDB("Cards", 770664);  -- Karte - Biber-Sp?her
  db:priv_AddDB("Cards", 770665);  -- Karte - Holzbrecher Jillap
  db:priv_AddDB("Cards", 770666);  -- Karte - Goldener seltsamer Stiel
  db:priv_AddDB("Cards", 770667);  -- Karte - R?cksichtsloser Fungus
  db:priv_AddDB("Cards", 770668);  -- Karte - Illusion?res Opfer
  db:priv_AddDB("Cards", 770669);  -- Karte - Fungus-Hüter
  db:priv_AddDB("Cards", 770670);  -- Karte - Pasayshoji
  db:priv_AddDB("Cards", 770671);  -- Karte - Großer Kuman
  db:priv_AddDB("Cards", 770672);  -- Karte - Wilde Alligatorschildkr?te
  db:priv_AddDB("Cards", 770673);  -- Karte - Schlammf?rst
  db:priv_AddDB("Cards", 770674);  -- Karte - Flussfischmonster
  db:priv_AddDB("Cards", 770675);  -- Karte - Hartschalenkriecher
  db:priv_AddDB("Cards", 770676);  -- Karte - Wilder Lakoso
  db:priv_AddDB("Cards", 770677);  -- Karte - Eduth-Gemeiner
  db:priv_AddDB("Cards", 770678);  -- Karte - Eduth-K?mpfer
  db:priv_AddDB("Cards", 770679);  -- Karte - Eduth-Schamane
  db:priv_AddDB("Cards", 770680);  -- Karte - Eduth-J?ger
  db:priv_AddDB("Cards", 770681);  -- Karte - Eduth-H?uptling
  db:priv_AddDB("Cards", 770682);  -- Karte - Rasender Affenmensch
  db:priv_AddDB("Cards", 770683);  -- Karte - Grausamer Fungus
  db:priv_AddDB("Cards", 770684);  -- Karte - Gef?ngnis-Flammenteufel
  db:priv_AddDB("Cards", 770685);  -- Karte - Naga-Vertreiber
  db:priv_AddDB("Cards", 770686);  -- Karte - Naga-Brenner
  db:priv_AddDB("Cards", 770687);  -- Karte - Rei?zahn-Ankylosaurier
  db:priv_AddDB("Cards", 770688);  -- Karte - Rufa-Gemeiner
  db:priv_AddDB("Cards", 770689);  -- Karte - Rufa-K?mpfer
  db:priv_AddDB("Cards", 770690);  -- Karte - Rufa-Schamane
  db:priv_AddDB("Cards", 770691);  -- Karte - Rufa-J?ger
  db:priv_AddDB("Cards", 770692);  -- Karte - Rufa-H?uptling
  db:priv_AddDB("Cards", 770693);  -- Karte - Luzan-Gemeiner
  db:priv_AddDB("Cards", 770694);  -- Karte - Luzan-K?mpfer
  db:priv_AddDB("Cards", 770695);  -- Karte - Luzan-Schamane
  db:priv_AddDB("Cards", 770696);  -- Karte - Luzan-J?ger
  db:priv_AddDB("Cards", 770697);  -- Karte - Luzan-H?uptling
  db:priv_AddDB("Cards", 770698);  -- Karte - Lavasammler
  db:priv_AddDB("Cards", 770699);  -- Karte - Lavaarbeiter
  db:priv_AddDB("Cards", 770700);  -- Karte - Lavaoberaufseher
  db:priv_AddDB("Cards", 770701);  -- Karte - Lavasch?tzer
  db:priv_AddDB("Cards", 770702);  -- Karte - Chefoberaufseher Schamane Chia
  db:priv_AddDB("Cards", 770703);  -- Karte - Kaa-Marschierer
  db:priv_AddDB("Cards", 770704);  -- Karte - Naga-Sieger
  db:priv_AddDB("Cards", 770705);  -- Karte - Naga-Unterdr?cker
  db:priv_AddDB("Cards", 770706);  -- Karte - D?mmersumpfalligator
  db:priv_AddDB("Cards", 770707);  -- Karte - Kaa-Wache
  db:priv_AddDB("Cards", 770708);  -- Karte - Naga-Verteidiger
  db:priv_AddDB("Cards", 770709);  -- Karte - Reinrassiger Naga
  db:priv_AddDB("Cards", 770710);  -- Karte - Versorgungshauptmann
  db:priv_AddDB("Cards", 770711);  -- Karte - Dreckiger Teufel
  db:priv_AddDB("Cards", 770712);  -- Karte - Blutgetr?nkter Wiederg?nger
  db:priv_AddDB("Cards", 770713);  -- Karte - W?tender Toter
  db:priv_AddDB("Cards", 770714);  -- 
  db:priv_AddDB("Cards", 770715);  -- Karte - W?tender Rudd
  db:priv_AddDB("Cards", 770716);  -- Karte - W?tender Hanz
  db:priv_AddDB("Cards", 770717);  -- Karte - W?tender dreckiger Teufel
  db:priv_AddDB("Cards", 770718);  -- Karte - Verbotener Besch?tzer
  db:priv_AddDB("Cards", 770719);  -- Karte - Verbotener Bewahrer
  db:priv_AddDB("Cards", 770720);  -- Karte - Verbotene Patrouille
  db:priv_AddDB("Cards", 770721);  -- Karte - Scharfschneidiger Vernichter
  db:priv_AddDB("Cards", 770722);  -- Karte - StahlHüter
  db:priv_AddDB("Cards", 770723);  -- Karte - Energieumwandler
  db:priv_AddDB("Cards", 770724);  -- Karte - Nachtmahr Androlier
  db:priv_AddDB("Cards", 770725);  -- Karte - Leichen-Albtraum
  db:priv_AddDB("Cards", 770726);  -- Karte - K?lte-Albtraum
  db:priv_AddDB("Cards", 770727);  -- Karte - Sturm-Albtraum
  db:priv_AddDB("Cards", 770728);  -- Karte - Kriegsillusion
  db:priv_AddDB("Cards", 770729);  -- Karte - Tr?gerische Illusion
  db:priv_AddDB("Cards", 770730);  -- Karte - Untergangsillusion
  db:priv_AddDB("Cards", 770731);  -- Karte - Unreifer D?monensoldat
  db:priv_AddDB("Cards", 770732);  -- Karte - Verr?ckte Kaa-Wache
  db:priv_AddDB("Cards", 770733);  -- Karte - Naga-Berserker
  db:priv_AddDB("Cards", 770734);  -- Karte - Irrer Naga
  db:priv_AddDB("Cards", 770735);  -- Karte - Schwarzschlangen-Leutnant
  db:priv_AddDB("Cards", 770736);  -- Karte - Schwarzschlangen-General Mafrur
  db:priv_AddDB("Cards", 770737);  -- Karte - Blutsaugende D?mmerfledermaus
  db:priv_AddDB("Cards", 770738);  -- Karte - Unkontrollierter D?monensoldat
  db:priv_AddDB("Cards", 770739);  -- Karte - Versklavter Flammenteufel
  db:priv_AddDB("Cards", 770740);  -- Karte - Naga-Schmied
  db:priv_AddDB("Cards", 770741);  -- Karte - Naga-Weber
  db:priv_AddDB("Cards", 770742);  -- Karte - Naga-Brandstifter
  db:priv_AddDB("Cards", 770743);  -- Karte - Naga-Wache
  db:priv_AddDB("Cards", 770744);  -- Karte - Feuerschlangen-Hauptmann Fenkani
  db:priv_AddDB("Cards", 770745);  -- Karte - Lava-Gr?ber
  db:priv_AddDB("Cards", 770746);  -- Karte - Lava-Schmied
  db:priv_AddDB("Cards", 770747);  -- Karte - Lava-Arbeiter
  db:priv_AddDB("Cards", 770748);  -- Karte - Fehlerhafter D?monensoldat
  db:priv_AddDB("Cards", 770749);  -- Karte - Kaa-Eisenwache
  db:priv_AddDB("Cards", 770750);  -- Karte - Naga-?berwacher
  db:priv_AddDB("Cards", 770751);  -- Karte - Naga-Aufsp?rer
  db:priv_AddDB("Cards", 770752);  -- Karte - Scharlachschlangen-Leutnant
  db:priv_AddDB("Cards", 770753);  -- Karte - Scharlachschlangen-General Kurawang
  db:priv_AddDB("Cards", 770754);  -- Karte - D?mmer-Cylotok
  db:priv_AddDB("Cards", 770755);  -- Karte - D?mmer-Kulang
  db:priv_AddDB("Cards", 770756);  -- Karte - Naga-Transportwache
  db:priv_AddDB("Cards", 770757);  -- Karte - Naga-Scharm?tzler
  db:priv_AddDB("Cards", 770758);  -- Karte - Naga-Versorgungsbeamter
  db:priv_AddDB("Cards", 770759);  -- Karte - Fl?gelschlangen-General Lireda
  db:priv_AddDB("Cards", 770760);  -- Karte - Junger Mantikor
  db:priv_AddDB("Cards", 770761);  -- Karte - Weiblicher Mantikor
  db:priv_AddDB("Cards", 770762);  -- Karte - Grausamer Mantikor
  db:priv_AddDB("Cards", 770763);  -- Karte - Grausamer Windreiter
  db:priv_AddDB("Cards", 770764);  -- Karte - Dressierter Ankylosaurier
  db:priv_AddDB("Cards", 770765);  -- 
  db:priv_AddDB("Cards", 770766);  -- Karte - Naga-B?ndiger
  db:priv_AddDB("Cards", 770767);  -- Karte - Naga-F?tterer
  db:priv_AddDB("Cards", 770768);  -- Karte - Scharfrichter-Puppe
  db:priv_AddDB("Cards", 770769);  -- Karte - Verschlinger-Kriecher
  db:priv_AddDB("Cards", 770770);  -- Karte - D?mmergiftfrosch
  db:priv_AddDB("Cards", 770771);  -- Karte - Pack-Ankylosaurier
  db:priv_AddDB("Cards", 770772);  -- Karte - Lava-Transporter
  db:priv_AddDB("Cards", 770773);  -- Karte - Freier Pango
  db:priv_AddDB("Cards", 770774);  -- Karte - Verwirrter Hirsch
  db:priv_AddDB("Cards", 770775);  -- Karte - Wildes Gulo
  db:priv_AddDB("Cards", 770776);  -- Karte - Ruinenvagabund
  db:priv_AddDB("Cards", 770777);  -- Karte - Ruinenbandit
  db:priv_AddDB("Cards", 770778);  -- Karte - Unterstadtgauner
  db:priv_AddDB("Cards", 770779);  -- Karte - Unterstadtverbrecher
  db:priv_AddDB("Cards", 770780);  -- Karte - Grausamer Pl?nderer
  db:priv_AddDB("Cards", 770781);  -- Karte - Abscheulicher Vagabund
  db:priv_AddDB("Cards", 770782);  -- Karte - Wilde Chupura
  db:priv_AddDB("Cards", 770783);  -- 
  db:priv_AddDB("Cards", 770784);  -- Karte - Gigantische Kanalspinne
  db:priv_AddDB("Cards", 770785);  -- Karte - Gigantische Kanalkakerlake
  db:priv_AddDB("Cards", 770786);  -- Karte - Gigantische Kanalratte
  db:priv_AddDB("Cards", 770787);  -- Karte - Kanalschlammmonster
  db:priv_AddDB("Cards", 770788);  -- Karte - Wildes Pango
  db:priv_AddDB("Cards", 770789);  -- Karte - Korrumpierter Ritter von Avano
  db:priv_AddDB("Cards", 770790);  -- Karte - Unverbesserliche Banditin
  db:priv_AddDB("Cards", 770791);  -- Karte - Ehrloser Ritter
  db:priv_AddDB("Cards", 770792);  -- Karte - Rick Mallen
  db:priv_AddDB("Cards", 770793);  -- Karte - Woody Mallen
  db:priv_AddDB("Cards", 770794);  -- Karte - Mitglied der Mallen-Bande
  db:priv_AddDB("Cards", 770795);  -- Karte - Grausamer Mallen-Bandit
  db:priv_AddDB("Cards", 770796);  -- Karte - Starke Chupura
  db:priv_AddDB("Cards", 770797);  -- Karte - Aufmerksames Boshi
  db:priv_AddDB("Cards", 770798);  -- Karte - Wilder Tatani
  db:priv_AddDB("Cards", 770799);  -- Karte - Wilder Hippogryph
  db:priv_AddDB("Cards", 770800);  -- Karte - Milasso-Gulo
  db:priv_AddDB("Cards", 770801);  -- Karte - Behemoth
  db:priv_AddDB("Cards", 770802);  -- Karte - Menschenfressende Pflanze
  db:priv_AddDB("Cards", 770803);  -- Karte - Wanderranke
  db:priv_AddDB("Cards", 770804);  -- Karte - Sigg-Schleicher
  db:priv_AddDB("Cards", 770805);  -- Karte - Warnorken-Elitewache
  db:priv_AddDB("Cards", 770806);  -- Karte - Warnorken-Sicherheitsoffizier
  db:priv_AddDB("Cards", 770807);  -- Karte - Warnorken-Patrouillenchupura
  db:priv_AddDB("Cards", 770808);  -- Karte - Warnorken-Soldat
  db:priv_AddDB("Cards", 770809);  -- Karte - Rh'anka-Nebelsoldat
  db:priv_AddDB("Cards", 770810);  -- Karte - Nebel-Rh'anka Shamane
  db:priv_AddDB("Cards", 770811);  -- Karte - Bambam Lom
  db:priv_AddDB("Cards", 770812);  -- Karte - Sch?delk?fer
  db:priv_AddDB("Cards", 770813);  -- Karte - Grinsek?fer
  db:priv_AddDB("Cards", 770814);  -- Karte - Nebelmoderwurm
  db:priv_AddDB("Cards", 770815);  -- Karte - Rh'anka-Nebelj?ger
  db:priv_AddDB("Cards", 770816);  -- Karte - Rh'anka-Nebelkundschafter
  db:priv_AddDB("Cards", 770817);  -- 
  db:priv_AddDB("Cards", 770818);  -- Karte - Grabr?uber
  db:priv_AddDB("Cards", 770819);  -- Karte - Blinder Hackman
  db:priv_AddDB("Cards", 770820);  -- Karte - Javias
  db:priv_AddDB("Cards", 770821);  -- Karte - Giftiger Moderwurm
  db:priv_AddDB("Cards", 770822);  -- Karte - S?gezahn-Chupura
  db:priv_AddDB("Cards", 770823);  -- Karte - Blutklauen-Chupura
  db:priv_AddDB("Cards", 770824);  -- Karte - ?ngstliches Gulo
  db:priv_AddDB("Cards", 770825);  -- Karte - Alte Chupura
  db:priv_AddDB("Cards", 770826);  -- Karte - Verirrtes Boshi
  db:priv_AddDB("Cards", 770827);  -- Karte - Janost-Echse
  db:priv_AddDB("Cards", 770828);  -- Karte - Janost-Scharfzahn
  db:priv_AddDB("Cards", 770829);  -- Karte - Verirrter Moderwurm
  db:priv_AddDB("Cards", 770830);  -- Karte - Geh?rnter Hirsch
  db:priv_AddDB("Cards", 770831);  -- Karte - Steinpanzer-Rhino
  db:priv_AddDB("Cards", 770832);  -- Karte - Hippogryphenk?nig Wodjin
  db:priv_AddDB("Cards", 770833);  -- Karte - Angren Bolmu
  db:priv_AddDB("Cards", 770834);  -- Karte - Versteckter Pukari
  db:priv_AddDB("Cards", 770835);  -- Karte - Sibwok
  db:priv_AddDB("Cards", 770836);  -- Karte - Tarnk?fer
  db:priv_AddDB("Cards", 770837);  -- Karte - Croso-Sharpro
  db:priv_AddDB("Cards", 770838);  -- Karte - Faulholzk?fer
  db:priv_AddDB("Cards", 770839);  -- Karte - Giftstecher
  db:priv_AddDB("Cards", 770840);  -- Karte - Jyr'na-Kulang
  db:priv_AddDB("Cards", 770841);  -- Karte - Faulender Entling
  db:priv_AddDB("Cards", 770842);  -- Karte - Jyr'na-Elfen-Magier
  db:priv_AddDB("Cards", 770843);  -- Karte - Jyr'na-Elfen-Krieger
  db:priv_AddDB("Cards", 770844);  -- Karte - Jyr'na-Elfen-Bewahrer
  db:priv_AddDB("Cards", 770845);  -- Karte - D?mmerstern-Bolmu
  db:priv_AddDB("Cards", 770846);  -- Karte - Sumpf-Kulang
  db:priv_AddDB("Cards", 770847);  -- Karte - Roter Giftfrosch
  db:priv_AddDB("Cards", 770848);  -- Karte - Blauer Schmetterling
  db:priv_AddDB("Cards", 770849);  -- Karte - Zahmer Bergkrebs
  db:priv_AddDB("Cards", 770850);  -- Karte - Blutschwingen-Fruchtfledermaus
  db:priv_AddDB("Cards", 770851);  -- Karte - Scharlach-Scharfzahn
  db:priv_AddDB("Cards", 770852);  -- Karte - Steppengrasschnecke
  db:priv_AddDB("Cards", 770853);  -- Karte - Welker Javias
  db:priv_AddDB("Cards", 770854);  -- Karte - Croso-Lakoso
  db:priv_AddDB("Cards", 770855);  -- Karte - Aasmolch
  db:priv_AddDB("Cards", 770856);  -- Karte - Gefallene Zentauren-Waldpatrouille
  db:priv_AddDB("Cards", 770857);  -- Karte - Gefallener Zentauren-Krieger
  db:priv_AddDB("Cards", 770858);  -- Karte - Soldat von Zaramonde
  db:priv_AddDB("Cards", 770859);  -- Karte - Zaramonde-Patrouille
  db:priv_AddDB("Cards", 770860);  -- Karte - Wache von Zaramonde
  db:priv_AddDB("Cards", 770861);  -- Karte - Strauch der rasenden Feuersbrunst
  db:priv_AddDB("Cards", 770862);  -- Karte - Croso-Keiler
  db:priv_AddDB("Cards", 770863);  -- Karte - Jyr'na-Elfen-Druidin
  db:priv_AddDB("Cards", 770864);  -- Karte - Wache des Heiligtums von Jyr'na
  db:priv_AddDB("Cards", 770865);  -- Karte - D?mmermolch
  db:priv_AddDB("Cards", 770866);  -- Karte - Angren Mosto
  db:priv_AddDB("Cards", 770867);  -- Karte - Cylotok
  db:priv_AddDB("Cards", 770868);  -- 
  db:priv_AddDB("Cards", 770869);  -- Karte - Babel
  db:priv_AddDB("Cards", 770870);  -- Karte - Windadler
  db:priv_AddDB("Cards", 770871);  -- Karte - Riesiger Sturmwolf
  db:priv_AddDB("Cards", 770872);  -- Karte - Ruinenforscher
  db:priv_AddDB("Cards", 770873);  -- Karte - Griffith Dunkelstern der korrupte Zentaur
  db:priv_AddDB("Cards", 770874);  -- Karte - Jyr'na-Elfen-Magd
  db:priv_AddDB("Cards", 770875);  -- Karte - Jyr'na-Druiden-Assistentin
  db:priv_AddDB("Cards", 770876);  -- Karte - Jyn'na-Elfen-Bogensch?tze
  db:priv_AddDB("Cards", 770877);  -- Karte - Rh'anka-Wanderer
  db:priv_AddDB("Cards", 770878);  -- Karte - Stachelige Sandviper
  db:priv_AddDB("Cards", 770879);  -- Karte - Ausgewachsenes Yasheedee
  db:priv_AddDB("Cards", 770880);  -- Karte - Riesenschlund
  db:priv_AddDB("Cards", 770881);  -- Karte - Scharfhorn-Gulo
  db:priv_AddDB("Cards", 770882);  -- Karte - Donnerwindgeier
  db:priv_AddDB("Cards", 770883);  -- Karte - Windreiter Sammis
  db:priv_AddDB("Cards", 770884);  -- Karte - Donnerwindskorpion
  db:priv_AddDB("Cards", 770885);  -- 
  db:priv_AddDB("Cards", 770886);  -- Karte - W?stenscharfzahn
  db:priv_AddDB("Cards", 770887);  -- Karte - W?sten-Boshi
  db:priv_AddDB("Cards", 770888);  -- Karte - Steinsalz-Mosto
  db:priv_AddDB("Cards", 770889);  -- Karte - Rh'anka-Steinsalzr?uber
  db:priv_AddDB("Cards", 770890);  -- Karte - Panzilla
  db:priv_AddDB("Cards", 770891);  -- Karte - Zanka-Hy?ne
  db:priv_AddDB("Cards", 770892);  -- Karte - Zanka-Skorpion
  db:priv_AddDB("Cards", 770893);  -- Karte - Zanka-Sandviper
  db:priv_AddDB("Cards", 770894);  -- Karte - Sandsteinfledermaus
  db:priv_AddDB("Cards", 770895);  -- Karte - Sandsteinschlange
  db:priv_AddDB("Cards", 770896);  -- 
  db:priv_AddDB("Cards", 770897);  -- Karte - Sturmgeier
  db:priv_AddDB("Cards", 770898);  -- Karte - Oasenskorpion
  db:priv_AddDB("Cards", 770899);  -- Karte - Sandspurschildkr?te
  db:priv_AddDB("Cards", 770900);  -- Karte - Verfallener Entling
  db:priv_AddDB("Cards", 770901);  -- Karte - Junges Yasheedee
  db:priv_AddDB("Cards", 770902);  -- Karte - Forscher der Hand der Wahrheit
  db:priv_AddDB("Cards", 770903);  -- 
  db:priv_AddDB("Cards", 770904);  -- Karte - Langlokee-G?rtner
  db:priv_AddDB("Cards", 770905);  -- Karte - Langlokee-W?chter
  db:priv_AddDB("Cards", 770906);  -- 
  db:priv_AddDB("Cards", 770907);  -- 
  db:priv_AddDB("Cards", 770908);  -- Karte - Himmelszornkrieger
  db:priv_AddDB("Cards", 770909);  -- Karte - Himmelszornvollstrecker
  db:priv_AddDB("Cards", 770910);  -- Karte - Oasenboshi
  db:priv_AddDB("Cards", 770911);  -- Karte - Sandsturm-Yasheedee
  db:priv_AddDB("Cards", 770912);  -- Karte - Hei?quellenschildkr?te
  db:priv_AddDB("Cards", 770913);  -- Karte - W?stenkaktus
  db:priv_AddDB("Cards", 770914);  -- Karte - Eisenzahnwachposten
  db:priv_AddDB("Cards", 770915);  -- 
  db:priv_AddDB("Cards", 770916);  -- Karte - Eisenzahnbogensch?tze
  db:priv_AddDB("Cards", 770917);  -- Karte - Marionettensoldat
  db:priv_AddDB("Cards", 770918);  -- Karte - Marionettenschamane
  db:priv_AddDB("Cards", 770919);  -- Karte - Ackersch?dling
  db:priv_AddDB("Cards", 770920);  -- Karte - Riesenb?r des Unheils
  db:priv_AddDB("Cards", 770921);  -- Karte - Mondschatten-Pukari
  db:priv_AddDB("Cards", 770922);  -- Karte - Mondschatten-Boshi
  db:priv_AddDB("Cards", 770923);  -- Karte - Dunkelsternmagier
  db:priv_AddDB("Cards", 770924);  -- Karte - Schwarzsumpf-Krokodil
  db:priv_AddDB("Cards", 770925);  -- 
  db:priv_AddDB("Cards", 770926);  -- Karte - Dunkelsternkrieger
  db:priv_AddDB("Cards", 770927);  -- Karte - Geistermutterspinne
  db:priv_AddDB("Cards", 770928);  -- Karte - Spinnenpriesterin Mandara
  db:priv_AddDB("Cards", 770929);  -- 
  db:priv_AddDB("Cards", 770930);  -- Karte - Verr?ckter Schmetterling
  db:priv_AddDB("Cards", 770931);  -- Karte - Dunkelsternbewahrer
  db:priv_AddDB("Cards", 770932);  -- Karte - Mondschatten-Gulo
  db:priv_AddDB("Cards", 770933);  -- Karte - Fuchs des Unheils
  db:priv_AddDB("Cards", 770934);  -- Karte - Wespe des Unheils
  db:priv_AddDB("Cards", 770935);  -- Karte - Grinsender Clown
  db:priv_AddDB("Cards", 770936);  -- Karte - Schlangenbeschw?rer
  db:priv_AddDB("Cards", 770937);  -- Karte - Tierb?ndiger
  db:priv_AddDB("Cards", 770938);  -- Karte - Merkw?rdige Clownin
  db:priv_AddDB("Cards", 770939);  -- Karte - Zirkusgehilfe
  db:priv_AddDB("Cards", 770940);  -- Karte - Unmoralischer Schattenmagier der Hand der Wahrheit
  db:priv_AddDB("Cards", 770941);  -- Karte - Seelent?terwache der Hand der Wahrheit
  db:priv_AddDB("Cards", 770942);  -- Karte - Bewaffnete Wache der Hand der Wahrheit
  db:priv_AddDB("Cards", 770943);  -- Karte - Laborprofessor der Hand der Wahrheit
  db:priv_AddDB("Cards", 770944);  -- Karte - Irrfuchs
  db:priv_AddDB("Cards", 770945);  -- Karte - Grafu-Wachposten
  db:priv_AddDB("Cards", 770946);  -- Karte - Mondschatten-Sib
  db:priv_AddDB("Cards", 770947);  -- Karte - Geistergeheul-Schreckenswolf
  db:priv_AddDB("Cards", 770948);  -- Karte - ?chzkondor
  db:priv_AddDB("Cards", 770949);  -- Karte - Giftiges Blutgespenst
  db:priv_AddDB("Cards", 770950);  -- Karte - Heulende Seele
  db:priv_AddDB("Cards", 770951);  -- Karte - Klagegeist
  db:priv_AddDB("Cards", 770952);  -- Karte - Leidender Marionettensoldat
  db:priv_AddDB("Cards", 770953);  -- Karte - Dunkelseelenmarionettenmagier
  db:priv_AddDB("Cards", 770954);  -- Karte - Transformierter Draken
  db:priv_AddDB("Cards", 770955);  -- Karte - Grafu-Peitscher
  db:priv_AddDB("Cards", 770956);  -- Karte - Grafu-Unterdr?cker
  db:priv_AddDB("Cards", 770957);  -- Karte - Transformierter D?monendraken
  db:priv_AddDB("Cards", 770958);  -- Karte - Gr?nfeld-Panzilla
  db:priv_AddDB("Cards", 770959);  -- Karte - Transformierter Dorfbewohner
  db:priv_AddDB("Cards", 770960);  -- Karte - Aasfressender Wolf
  db:priv_AddDB("Cards", 770961);  -- Karte - Flicker
  db:priv_AddDB("Cards", 770962);  -- Karte - Zugvogel
  db:priv_AddDB("Cards", 770963);  -- Karte - Grafu-Soldat
  db:priv_AddDB("Cards", 770964);  -- Karte - Transformierte zusammengeflickte Menschenst?cke
  db:priv_AddDB("Cards", 770965);  -- Karte - Riesenskorpion des Unheils
  db:priv_AddDB("Cards", 770966);  -- Karte - Hending-Tigerrochen
  db:priv_AddDB("Cards", 770967);  -- Karte - Hending-Kulang
  db:priv_AddDB("Cards", 770968);  -- Karte - Nordpl?nderer
  db:priv_AddDB("Cards", 770969);  -- Karte - Nordschleicher
  db:priv_AddDB("Cards", 770970);  -- Karte - Nordsklavenh?ndler
  db:priv_AddDB("Cards", 770971);  -- Karte - Gezeitenadler des Piraten
  db:priv_AddDB("Cards", 770972);  -- Karte - B?sartiger Nordpirat
  db:priv_AddDB("Cards", 770973);  -- Karte - Kaltbl?tiger Nordpirat
  db:priv_AddDB("Cards", 770974);  -- Karte - Zapa-Schwertalligator
  db:priv_AddDB("Cards", 770975);  -- Karte - Junger Schwertalligator
  db:priv_AddDB("Cards", 770976);  -- Karte - Zapa-Pango
  db:priv_AddDB("Cards", 770977);  -- 
  db:priv_AddDB("Cards", 770978);  -- Karte - Zapa-Chupura
  db:priv_AddDB("Cards", 770979);  -- Karte - Zapa-Strau?
  db:priv_AddDB("Cards", 770980);  -- Karte - Shuma-Schildkr?te
  db:priv_AddDB("Cards", 770981);  -- Karte - Shuma-Gazelle
  db:priv_AddDB("Cards", 770982);  -- Karte - Shuma-Riesenrhinozeros
  db:priv_AddDB("Cards", 770983);  -- Karte - Buntpython
  db:priv_AddDB("Cards", 770984);  -- Karte - Mestro-Braunb?r
  db:priv_AddDB("Cards", 770985);  -- Karte - Mestro-S?belzahntiger
  db:priv_AddDB("Cards", 770986);  -- Karte - Mestro-Waldwolf
  db:priv_AddDB("Cards", 770987);  -- Karte - Mestro-Hippogryph
  db:priv_AddDB("Cards", 770988);  -- Karte - Sumpf-Python
  db:priv_AddDB("Cards", 770989);  -- Karte - Basiliskenboa
  db:priv_AddDB("Cards", 770990);  -- Karte - Riesenbasiliskenmoskito
  db:priv_AddDB("Cards", 770991);  -- Karte - Tiefschlamm-Cylotok
  db:priv_AddDB("Cards", 770992);  -- Karte - Riesenstirn-Basilisken-Rhinozeros
  db:priv_AddDB("Cards", 770993);  -- Karte - Kaskadenmolch
  db:priv_AddDB("Cards", 770994);  -- Karte - Kaskadenlibelle
  db:priv_AddDB("Cards", 770995);  -- Karte - Boshafter Gulo
  db:priv_AddDB("Cards", 770996);  -- Karte - Schwacher Bestrafer
  db:priv_AddDB("Cards", 770997);  -- Karte - Instabiler Energiefluss
  db:priv_AddDB("Cards", 770998);  -- Karte - Erdgruben-Scharfzahn
  db:priv_AddDB("Cards", 770999);  -- Karte - Blutroter Erdgruben-Skorpion
  db:priv_AddDB("Cards", 771000);  -- Karte - Erdgruben-Hy?ne
  db:priv_AddDB("Cards", 771001);  -- Karte - Erdgruben-Gr?ber
  db:priv_AddDB("Cards", 771002);  -- Karte - Erdgruben-Nahrungspl?nderer
  db:priv_AddDB("Cards", 771003);  -- Karte - Erdgruben-Kaktus
  db:priv_AddDB("Cards", 771004);  -- Karte - Alter Naga-Rebell
  db:priv_AddDB("Cards", 771005);  -- Karte - Alter Limon-Bandit
  db:priv_AddDB("Cards", 771006);  -- Karte - Altes Ayax-Klansmitglied
  db:priv_AddDB("Cards", 771007);  -- Karte - Alter verbitterter Adept
  db:priv_AddDB("Cards", 771008);  -- Karte - Quodate-Ankylosaurier
  db:priv_AddDB("Cards", 771009);  -- Karte - Todesblume
  db:priv_AddDB("Cards", 771010);  -- Karte - Skrupellose Eishexe
  db:priv_AddDB("Cards", 771011);  -- Karte - Quodate-Sigg
  db:priv_AddDB("Cards", 771012);  -- Karte - Mutierter Schwindler
  db:priv_AddDB("Cards", 771013);  -- Karte - Schlingblume
  db:priv_AddDB("Cards", 771014);  -- Karte - Alter Eiskrieger
  db:priv_AddDB("Cards", 771015);  -- Karte - Pr?chtiger Foger
  db:priv_AddDB("Cards", 771016);  -- Karte - Hervorgew?rgtes Skelett
  db:priv_AddDB("Cards", 771017);  -- Karte - Flachwasser-Scealok
  db:priv_AddDB("Cards", 771018);  -- Karte - Hending-Einsiedlerkrebs
  db:priv_AddDB("Cards", 771019);  -- Karte - Lauernder Pirat
  db:priv_AddDB("Cards", 771020);  -- Karte - Listiger Pirat
  db:priv_AddDB("Cards", 771021);  -- Karte - Wanderschlange
  db:priv_AddDB("Cards", 771022);  -- Karte - Bedrohlicher S?belzahntiger
  db:priv_AddDB("Cards", 771023);  -- Karte - Ruhelose Pflanze
  db:priv_AddDB("Cards", 771024);  -- Karte - Steinalte Riesenbasiliskenpython
  db:priv_AddDB("Cards", 771025);  -- Karte - Mutierte Mestro-Wanderschlange
  db:priv_AddDB("Cards", 771026);  -- Karte - Furchterregender steinalter Humanoid
  db:priv_AddDB("Cards", 771027);  -- Karte - Skrupelloser steinalter Humanoid
  db:priv_AddDB("Cards", 771028);  -- 
  db:priv_AddDB("Cards", 771029);  -- Karte - Sumpf-Riesenpython
  db:priv_AddDB("Cards", 771030);  -- Karte - Mestro-Riesenschlange
  db:priv_AddDB("Cards", 771031);  -- Karte - Hydra
  db:priv_AddDB("Cards", 771032);  -- Karte - Erdgruben-Nahrungsaasfresser
  db:priv_AddDB("Cards", 771033);  -- Karte - Erdgruben-Arachneskor
  db:priv_AddDB("Cards", 771034);  -- Karte - Steinalter Limon-Bandit
  db:priv_AddDB("Cards", 771035);  -- Karte - Alter Ayax-Krieger
  db:priv_AddDB("Cards", 771036);  -- Karte - Steinalter Naga-Verschw?rer
  db:priv_AddDB("Cards", 771037);  -- Karte - Uralter Wander-Naga
  db:priv_AddDB("Cards", 771038);  -- Karte - Uralter Wander-Adept
  db:priv_AddDB("Cards", 771039);  -- Karte - Alter Wander-Tiktaalik
  db:priv_AddDB("Cards", 771040);  -- Karte - Hending-Riesenscherenkrebs
  db:priv_AddDB("Cards", 771041);  -- Karte - Dunkelriten-Akolyth
  db:priv_AddDB("Cards", 771042);  -- Karte - Dunkelritenmagier
  db:priv_AddDB("Cards", 771043);  -- Karte - Dunkelritenausbilder
  db:priv_AddDB("Cards", 771044);  -- Karte - Dunkelritenhexenmeister
  db:priv_AddDB("Cards", 771045);  -- Karte - Kupferg?rtner
  db:priv_AddDB("Cards", 771046);  -- Karte - Heftiger Sturm
  db:priv_AddDB("Cards", 771047);  -- Karte - Uralte D?monenblume
  db:priv_AddDB("Cards", 771048);  -- Karte - Wiedererweckter Zombie
  db:priv_AddDB("Cards", 771049);  -- Karte - Verst?mmelter Zombie
  db:priv_AddDB("Cards", 771050);  -- Karte - Stinkender Zombie
  db:priv_AddDB("Cards", 771051);  -- Karte - Verzauberter Zombie
  db:priv_AddDB("Cards", 771052);  -- Karte - Dunkler Nachtgargoyle
  db:priv_AddDB("Cards", 771053);  -- Karte - H?llenwachhund
  db:priv_AddDB("Cards", 771054);  -- Karte - H?llenmaschine
  db:priv_AddDB("Cards", 771055);  -- Karte - Heulender Mosto
  db:priv_AddDB("Cards", 771056);  -- Karte - Knochenmahlblume
  db:priv_AddDB("Cards", 771057);  -- Karte - H?llenschmetterling
  db:priv_AddDB("Cards", 771058);  -- Karte - Wanderskelett
  db:priv_AddDB("Cards", 771059);  -- Karte - Schatten des Abgrunds
  db:priv_AddDB("Cards", 771060);  -- Karte - Ansilox-Nachtfalter
  db:priv_AddDB("Cards", 771061);  -- Karte - Arcurion-Vampirfledermaus
  db:priv_AddDB("Cards", 771062);  -- Karte - Psyloban
  db:priv_AddDB("Cards", 771063);  -- Karte - Arcurion-Granatratte
  db:priv_AddDB("Cards", 771064);  -- Karte - Arcurion-Spinne
  db:priv_AddDB("Cards", 771065);  -- Karte - Abenteurer-Gesindel
  db:priv_AddDB("Cards", 771066);  -- Karte - Skelettsoldat
  db:priv_AddDB("Cards", 771067);  -- Karte - Skelettmagier
  db:priv_AddDB("Cards", 771068);  -- Karte - Blutiges Skelett
  db:priv_AddDB("Cards", 771069);  -- Karte - Totenbeschw?rer
  db:priv_AddDB("Cards", 771070);  -- Karte - Blaufederharse
  db:priv_AddDB("Cards", 771071);  -- Karte - Riesiger Ruinenwolf
  db:priv_AddDB("Cards", 771072);  -- Karte - Geheimnisvolle Blutspinne
  db:priv_AddDB("Cards", 771073);  -- Karte - Ruinens?uberer
  db:priv_AddDB("Cards", 771074);  -- Karte - Granatgepanzerte Bestie
  db:priv_AddDB("Cards", 771075);  -- Karte - Ruinenfungus
  db:priv_AddDB("Cards", 771076);  -- Karte - Steinsch?tzer
  db:priv_AddDB("Cards", 771077);  -- Karte - Ruinen-Blitzschuppenechse
  db:priv_AddDB("Cards", 771078);  -- Karte - Agiler Schattennerz
  db:priv_AddDB("Cards", 771079);  -- 
  db:priv_AddDB("Cards", 771080);  -- Karte - Purpur-Pukari
  db:priv_AddDB("Cards", 771081);  -- Karte - Roter Aasfresserb?r
  db:priv_AddDB("Cards", 771082);  -- Karte - Harpyienschreierin
  db:priv_AddDB("Cards", 771083);  -- Karte - Harpyienheulerin
  db:priv_AddDB("Cards", 771084);  -- Karte - Chaotischer Entling
  db:priv_AddDB("Cards", 771085);  -- Karte - Verrotteter Entling
  db:priv_AddDB("Cards", 771086);  -- Karte - Heulender Wurm
  db:priv_AddDB("Cards", 771087);  -- Karte - Riesengeweih-Schattenhirsch
  db:priv_AddDB("Cards", 771088);  -- Karte - Heulender Scharfzahn
  db:priv_AddDB("Cards", 771089);  -- Karte - Robest-Spinne
  db:priv_AddDB("Cards", 771090);  -- Karte - Wanderleiche
  db:priv_AddDB("Cards", 771091);  -- Karte - Moderholzfungus
  db:priv_AddDB("Cards", 771092);  -- Karte - Hungerwolf
  db:priv_AddDB("Cards", 771093);  -- Karte - Faulmade
  db:priv_AddDB("Cards", 771094);  -- Karte - Silbermondsee-Frosch
  db:priv_AddDB("Cards", 771095);  -- Karte - Harpyienbeschw?rerin
  db:priv_AddDB("Cards", 771096);  -- Karte - Harpyienpl?ndererin
  db:priv_AddDB("Cards", 771097);  -- Karte - Harpyienschamane
  db:priv_AddDB("Cards", 771098);  -- Karte - Silbermondlibelle
  db:priv_AddDB("Cards", 771099);  -- Karte - Junger Silbermondfrosch
  db:priv_AddDB("Cards", 771100);  -- Karte - Layod-Wildschwein
  db:priv_AddDB("Cards", 771101);  -- Karte - Layod-Wolf
  db:priv_AddDB("Cards", 771102);  -- Karte - Umherstreifender Pango
  db:priv_AddDB("Cards", 771103);  -- Karte - Umherstreifender Javia
  db:priv_AddDB("Cards", 771104);  -- Karte - Rotblatt-Gulo
  db:priv_AddDB("Cards", 771105);  -- Karte - Boshi des Geheimen Haines
  db:priv_AddDB("Cards", 771106);  -- Karte - Waldschabe des Geheimen Haines
  db:priv_AddDB("Cards", 771107);  -- Karte - Rotfl?gel-Kulang
  db:priv_AddDB("Cards", 771108);  -- Karte - Felsgalidun
  db:priv_AddDB("Cards", 771109);  -- Karte - M?nnlicher Knochenmalmer
  db:priv_AddDB("Cards", 771110);  -- Karte - Unheilk?nder
  db:priv_AddDB("Cards", 771111);  -- Karte - Seltsamer Schlachtfeldbandit
  db:priv_AddDB("Cards", 771112);  -- Karte - Hoffnungsloser Schlachtfeldbandit
  db:priv_AddDB("Cards", 771113);  -- Karte - Weiblicher Knochenmalmer
  db:priv_AddDB("Cards", 771114);  -- Karte - Knochenmalmer-Jungtier
  db:priv_AddDB("Cards", 771115);  -- Karte - Ferdhuf-Gebirgsskorpion
  db:priv_AddDB("Cards", 771116);  -- Karte - Schlachtfeldphantom
  db:priv_AddDB("Cards", 771117);  -- Karte - M?nnliche Ferdhufgazelle
  db:priv_AddDB("Cards", 771118);  -- Karte - Weibliche Ferdhufgazelle
  db:priv_AddDB("Cards", 771119);  -- Karte - Halbverwester Chupura
  db:priv_AddDB("Cards", 771120);  -- Karte - Verseuchter Molch
  db:priv_AddDB("Cards", 771121);  -- Karte - Pfefferpilz
  db:priv_AddDB("Cards", 771122);  -- Karte - Chupura der Ebenen von Kagasi
  db:priv_AddDB("Cards", 771123);  -- Karte - Blutd?rstige Made
  db:priv_AddDB("Cards", 771124);  -- Karte - Blattgottesanbeterin
  db:priv_AddDB("Cards", 771125);  -- Karte - Blutschwingen-Schmetterling
  db:priv_AddDB("Cards", 771126);  -- Karte - Blutd?rstige Stachelschwanzlibelle
  db:priv_AddDB("Cards", 771127);  -- Karte - Blutgl?nzender K?fer
  db:priv_AddDB("Cards", 771128);  -- Karte - Menschenfressender Mosto
  db:priv_AddDB("Cards", 771129);  -- Karte - Steinpanzerrhino der Ebenen von Kagasi
  db:priv_AddDB("Cards", 771130);  -- 
  db:priv_AddDB("Cards", 771131);  -- Karte - Verbesserter umgeformter Soldat
  db:priv_AddDB("Cards", 771132);  -- Karte - Umgeformter Elitesoldat
  db:priv_AddDB("Cards", 771133);  -- Karte - Brutale umgeformte Bestie
  db:priv_AddDB("Cards", 771134);  -- Karte - Verbesserter Sp?hsoldat
  db:priv_AddDB("Cards", 771135);  -- Karte - Ausgehungertes Versuchsobjekt
  db:priv_AddDB("Cards", 771136);  -- Karte - Undiszipliniertes Versuchsobjekt
  db:priv_AddDB("Cards", 771137);  -- Karte - Wahnsinniges Versuchsobjekt
  db:priv_AddDB("Cards", 771138);  -- Karte - Wutm?hnenschamane
  db:priv_AddDB("Cards", 771139);  -- Karte - Wutm?hnenkrieger
  db:priv_AddDB("Cards", 771140);  -- Karte - Wutm?hnensch?tze
  db:priv_AddDB("Cards", 771141);  -- Karte - Wutm?hnenh?uptling
  db:priv_AddDB("Cards", 771142);  -- Karte - M?nnliche Tergothen-Hornbestie
  db:priv_AddDB("Cards", 771143);  -- Karte - Weibliche Tergothen-Hornbestie
  db:priv_AddDB("Cards", 771144);  -- Karte - Mutierter Tergothen-Baumfrosch
  db:priv_AddDB("Cards", 771145);  -- Karte - Riesiger mutierter Tergothen-Baumfrosch
  db:priv_AddDB("Cards", 771146);  -- Karte - Sumpfrei?zahn
  db:priv_AddDB("Cards", 771147);  -- Karte - Dornnasen-Sandkrabbe
  db:priv_AddDB("Cards", 771148);  -- Karte - Dornnasen-Seem?we
  db:priv_AddDB("Cards", 771149);  -- Karte - Strandholzwurm
  db:priv_AddDB("Cards", 771150);  -- Karte - Umherstreifender Ruinenalbtraum
  db:priv_AddDB("Cards", 771151);  -- Karte - Kaltwasser-Seeschlange
  db:priv_AddDB("Cards", 771152);  -- Karte - Umherstreifende Chupura
  db:priv_AddDB("Cards", 771153);  -- Karte - Tergothenh?gel-Echse
  db:priv_AddDB("Cards", 771154);  -- Karte - Doppelbeutelwespe
  db:priv_AddDB("Cards", 771155);  -- Karte - M?nnliches Tergothen-Panzilla
  db:priv_AddDB("Cards", 771156);  -- Karte - Weibliches Tergothen-Panzilla
  db:priv_AddDB("Cards", 771157);  -- Karte - Roter Tergothen-Schmetterling
  db:priv_AddDB("Cards", 771158);  -- Karte - Zur?ckgelassene Probe
  db:priv_AddDB("Cards", 771159);  -- Karte - Diebischer Ronin
  db:priv_AddDB("Cards", 771160);  -- Karte - Diebischer Spion
  db:priv_AddDB("Cards", 771161);  -- Karte - Diebischer Strolch
  db:priv_AddDB("Cards", 771162);  -- Karte - Diebischer Handlanger
  db:priv_AddDB("Cards", 771163);  -- Karte - Lechif-Agent
  db:priv_AddDB("Cards", 771164);  -- Karte - Ebenenmosto
  db:priv_AddDB("Cards", 771165);  -- Karte - Ebenengalidun
  db:priv_AddDB("Cards", 771166);  -- Karte - Ebenentatani
  db:priv_AddDB("Cards", 771167);  -- Karte - Wilder Sigg
  db:priv_AddDB("Cards", 771168);  -- Karte - Riesige menschenfressende Weinpflanze
  db:priv_AddDB("Cards", 771169);  -- Karte - Tergothen-Sandspurschildkr?te
  db:priv_AddDB("Cards", 771170);  -- Karte - Mutierter Gro?muschelkrebs
  db:priv_AddDB("Cards", 771171);  -- Karte - Mutierter Algenschlamm
  db:priv_AddDB("Cards", 771172);  -- Karte - Lechif-Krieger
  db:priv_AddDB("Cards", 771173);  -- Karte - Lechif-Wachmann
  db:priv_AddDB("Cards", 771174);  -- Karte - Lechif-Patrouille
  db:priv_AddDB("Cards", 771175);  -- Karte - Ankes-Krieger
  db:priv_AddDB("Cards", 771176);  -- Karte - Ankes-Bomber
  db:priv_AddDB("Cards", 771177);  -- Karte - Ankes-Heiler
  db:priv_AddDB("Cards", 771178);  -- Karte - Ankes-Agent
  db:priv_AddDB("Cards", 771179);  -- Karte - Werftratte
  db:priv_AddDB("Cards", 771180);  -- Karte - Bandit vom Stillen Pass
  db:priv_AddDB("Cards", 771181);  -- 
  db:priv_AddDB("Cards", 771182);  -- Karte - Hund der Diebe
  db:priv_AddDB("Cards", 771183);  -- Karte - Stille Schwalbe
  db:priv_AddDB("Cards", 771184);  -- Karte - Gulo vom Stillen Pass
  db:priv_AddDB("Cards", 771185);  -- Karte - Fledermaus vom Stillen Pass
  db:priv_AddDB("Cards", 771186);  -- Karte - Sismonds W?chter
  db:priv_AddDB("Cards", 771187);  -- Karte - Targonharl
  db:priv_AddDB("Cards", 771188);  -- Karte - Lagusen
  db:priv_AddDB("Cards", 771189);  -- Karte - Spezifischer Aggregatskristall
  db:priv_AddDB("Cards", 771190);  -- Karte - Kristall-Gamiter
  db:priv_AddDB("Cards", 771191);  -- Karte - Heulschilf
  db:priv_AddDB("Cards", 771192);  -- Karte - Energieblume
  db:priv_AddDB("Cards", 771193);  -- Karte - Umherstreifendes Funkenhuhn
  db:priv_AddDB("Cards", 771194);  -- Karte - Laphraag-Bef?ller
  db:priv_AddDB("Cards", 771195);  -- Karte - Laphraag-Patrouille
  db:priv_AddDB("Cards", 771196);  -- Karte - Laphraag-Wache
  db:priv_AddDB("Cards", 771197);  -- Karte - Kristallkollektor
  db:priv_AddDB("Cards", 771198);  -- Karte - Komponentenbauer
  db:priv_AddDB("Cards", 771199);  -- Karte - Waldregenbogenadler
  db:priv_AddDB("Cards", 771200);  -- Karte - Einhorn-Waldschlange
  db:priv_AddDB("Cards", 771201);  -- Karte - Waldhirsch
  db:priv_AddDB("Cards", 771202);  -- Karte - Baumgrenze-Leopard
  db:priv_AddDB("Cards", 771203);  -- Karte - Baumgrenze-Keiler
  db:priv_AddDB("Cards", 771204);  -- Karte - Ver?ngstigter Strau?
  db:priv_AddDB("Cards", 771205);  -- Karte - Ver?ngstigtes Gulo
  db:priv_AddDB("Cards", 771206);  -- Karte - Waldr?uber
  db:priv_AddDB("Cards", 771207);  -- Karte - W?tender Elementar des Kochenden Wassers
  db:priv_AddDB("Cards", 771208);  -- Karte - ?ffner des Großen Tors
  db:priv_AddDB("Cards", 771209);  -- Karte - W?chter des Großen Tors
  db:priv_AddDB("Cards", 771210);  -- Karte - Energiekollektor des Großen Tors
  db:priv_AddDB("Cards", 771211);  -- Karte - Waldflammenwolf
  db:priv_AddDB("Cards", 771212);  -- Karte - Waldflammenhirsch
  db:priv_AddDB("Cards", 771213);  -- Karte - Waldpanzerbestie
  db:priv_AddDB("Cards", 771214);  -- Karte - Waldgro?schnabel
  db:priv_AddDB("Cards", 771215);  -- Karte - Energie-Aggregatskristall
  db:priv_AddDB("Cards", 771216);  -- Karte - Energie-Aggregatsbestie
  db:priv_AddDB("Cards", 771217);  -- Karte - Spaltflammen-Panzerbestie "Riesenschwanz"
  db:priv_AddDB("Cards", 771218);  -- Karte - Flammenruferwolf "Zornklaue"
  db:priv_AddDB("Cards", 771219);  -- Karte - W?tender Leopardengeist
  db:priv_AddDB("Cards", 771220);  -- Karte - Kristallpelz-Mutantenmaus
  db:priv_AddDB("Cards", 771221);  -- Karte - Mutantenbestie
  db:priv_AddDB("Cards", 771222);  -- Karte - W?tender R?ubergeist
  db:priv_AddDB("Cards", 771223);  -- Karte - W?tender Keilergeist
  db:priv_AddDB("Cards", 771224);  -- Karte - Laphraag-Transporteur
  db:priv_AddDB("Cards", 771225);  -- Karte - Balanzasar-Baumfrosch
  db:priv_AddDB("Cards", 771226);  -- Karte - Dicker Hase
  db:priv_AddDB("Cards", 771227);  -- Karte - Giftspinnenskorpion
  db:priv_AddDB("Cards", 771228);  -- Karte - Wilder Brauntiger
  db:priv_AddDB("Cards", 771229);  -- Karte - Neuer Feuer-Elementar
  db:priv_AddDB("Cards", 771230);  -- Karte - Streitbarer Feuer-Elementar
  db:priv_AddDB("Cards", 771231);  -- Karte - Uralter Entling
  db:priv_AddDB("Cards", 771232);  -- 
  db:priv_AddDB("Cards", 771233);  -- Karte - Krolin
  db:priv_AddDB("Cards", 771234);  -- Karte - Dunkelsternbogensch?tze
  db:priv_AddDB("Cards", 771235);  -- Karte - W?chter des Dunkelsternheiligtums
  db:priv_AddDB("Cards", 771236);  -- Karte - Mondzahnk?mpfer
  db:priv_AddDB("Cards", 771237);  -- Karte - Mondzahnr?uberin
  db:priv_AddDB("Cards", 771238);  -- Karte - Mondzahnpriester
  db:priv_AddDB("Cards", 771239);  -- Karte - Mondzahnmagierin
  db:priv_AddDB("Cards", 771240);  -- Karte - Mondzahnj?gerin
  db:priv_AddDB("Cards", 771241);  -- Karte - Azursee-Pango
  db:priv_AddDB("Cards", 771242);  -- Karte - Mutierte fleischfressende Pflanze
  db:priv_AddDB("Cards", 771243);  -- Karte - Mutierte Riesenmantis
  db:priv_AddDB("Cards", 771244);  -- Karte - Mutierter Baumk?fer
  db:priv_AddDB("Cards", 771245);  -- Karte - Mutierter Riesenwolf
  db:priv_AddDB("Cards", 771246);  -- Karte - Blinde Tiefenspinne
  db:priv_AddDB("Cards", 771247);  -- Karte - Schmutzige Höhlenratte
  db:priv_AddDB("Cards", 771248);  -- Karte - Kristall-Rattenschlange
  db:priv_AddDB("Cards", 771249);  -- Karte - Kabbas-K?fer
  db:priv_AddDB("Cards", 771250);  -- Karte - Magiefels-Gamiter
  db:priv_AddDB("Cards", 771251);  -- Karte - Auflauerer-Phantom
  db:priv_AddDB("Cards", 771252);  -- Karte - Gellis-K?fer
  db:priv_AddDB("Cards", 771253);  -- Karte - Phantomj?ger
  db:priv_AddDB("Cards", 771254);  -- Karte - Dunkelenergie-Marionette
  db:priv_AddDB("Cards", 771255);  -- Karte - Widerliche Fledermaus
  db:priv_AddDB("Cards", 771256);  -- Karte - Dunkelenergiek?fer
  db:priv_AddDB("Cards", 771257);  -- Karte - Dunkelenergie-W?chter
  db:priv_AddDB("Cards", 771258);  -- Karte - Blutr?nstige umgeformte Bestie
  db:priv_AddDB("Cards", 771259);  -- Karte - Naghur Seelenschinder
  db:priv_AddDB("Cards", 771260);  -- Karte - Großer Giftdrachen
  db:priv_AddDB("Cards", 771261);  -- Karte - Heiliger Erdelementar
  db:priv_AddDB("Cards", 771262);  -- Karte - Heiliger Feuerelementar
  db:priv_AddDB("Cards", 771263);  -- Karte - Kleiner Giftdrache
  db:priv_AddDB("Cards", 771264);  -- Karte - Blattwurm
  db:priv_AddDB("Cards", 771265);  -- Karte - Gelbblattwurm
  db:priv_AddDB("Cards", 771266);  -- Karte - Kristallk?fer
  db:priv_AddDB("Cards", 771267);  -- Karte - Sagthorne-Echse
  db:priv_AddDB("Cards", 771268);  -- Karte - Heiliger Wasserelementar
  db:priv_AddDB("Cards", 771269);  -- Karte - Fleischfressendes Yasheedee
  db:priv_AddDB("Cards", 771270);  -- Karte - Nestkugelmonster
  db:priv_AddDB("Cards", 771271);  -- Karte - Finsteres Mutantengras
  db:priv_AddDB("Cards", 771272);  -- Karte - Skelettskorpion
  db:priv_AddDB("Cards", 771273);  -- Karte - Kulech-Vorhut
  db:priv_AddDB("Cards", 771274);  -- Karte - Kulech-Bluttrinker
  db:priv_AddDB("Cards", 771275);  -- Karte - Junge Fleischmade
  db:priv_AddDB("Cards", 771276);  -- Karte - Erdaufseher-Myrmex
  db:priv_AddDB("Cards", 771277);  -- Karte - Kulech-Schlitzer
  db:priv_AddDB("Cards", 771278);  -- Karte - Finsterbaron
  db:priv_AddDB("Cards", 771279);  -- Karte - Finsterer Gelehrter
  db:priv_AddDB("Cards", 771280);  -- Karte - Kulech-Sucher
  db:priv_AddDB("Cards", 771281);  -- Karte - Nestw?chtermyrmex
  db:priv_AddDB("Cards", 771282);  -- Karte - Kulech-Tr?ger
  db:priv_AddDB("Cards", 771283);  -- 
  db:priv_AddDB("Cards", 771284);  -- Karte - Bestrafer Nr. 74
  db:priv_AddDB("Cards", 771285);  -- Karte - Bestrafer Nr. 72
  db:priv_AddDB("Cards", 771286);  -- Karte - Schwarzfl?gel des verwaisten Tals
  db:priv_AddDB("Cards", 771287);  -- Karte - Salvond-Rotwolf
  db:priv_AddDB("Cards", 771288);  -- Karte - Salvond-Springbock
  db:priv_AddDB("Cards", 771289);  -- Karte - Hüter-Bestrafer
  db:priv_AddDB("Cards", 771290);  -- Karte - Blockender Bestrafer
  db:priv_AddDB("Cards", 771291);  -- Karte - Transport-Bestrafer
  db:priv_AddDB("Cards", 771292);  -- Karte - Rasende Form
  db:priv_AddDB("Cards", 771293);  -- Karte - Scheues Gutai-Kugelmonster
  db:priv_AddDB("Cards", 771294);  -- Karte - Gutais Zorn
  db:priv_AddDB("Cards", 771295);  -- Karte - Gutais Zweifel
  db:priv_AddDB("Cards", 771296);  -- Karte - Gutais Schrecken
  db:priv_AddDB("Cards", 771297);  -- Karte - Klagender verwirrter Vogel
  db:priv_AddDB("Cards", 771298);  -- Karte - Rasender B?r
  db:priv_AddDB("Cards", 771299);  -- Karte - Korum-St?rmer
  db:priv_AddDB("Cards", 771300);  -- Karte - Korum-Schamane
  db:priv_AddDB("Cards", 771301);  -- Karte - Korum-W?chter
  db:priv_AddDB("Cards", 771302);  -- Karte - Korum-Krieger
  db:priv_AddDB("Cards", 771303);  -- Karte - Korum-Handwerker
  db:priv_AddDB("Cards", 771304);  -- Karte - Korum-J?ger
  db:priv_AddDB("Cards", 771305);  -- Karte - Korum-Bergarbeiter
  db:priv_AddDB("Cards", 771306);  -- Karte - Tundra-Tatani
  db:priv_AddDB("Cards", 771307);  -- Karte - Tundra-Berhu
  db:priv_AddDB("Cards", 771308);  -- Karte - Haus-Berhu
  db:priv_AddDB("Cards", 771309);  -- Karte - Sto?zahnmammut der Tundra
  db:priv_AddDB("Cards", 771310);  -- Karte - Tundramammut-Pfleger
  db:priv_AddDB("Cards", 771311);  -- Karte - Kladoren-Sucher
  db:priv_AddDB("Cards", 771312);  -- Karte - Kladoren-Entdecker
  db:priv_AddDB("Cards", 771313);  -- Karte - Kladoren-Schwimmer
  db:priv_AddDB("Cards", 771314);  -- Karte - Sugon-Hochlandrentier
  db:priv_AddDB("Cards", 771315);  -- Karte - Sugon-Panzerbestie
  db:priv_AddDB("Cards", 771316);  -- Karte - Bestrafer Nr. 74 EX
  db:priv_AddDB("Cards", 771317);  -- Karte - Bestrafer Nr. 72 EX
  db:priv_AddDB("Cards", 771318);  -- Karte - Elementarbestrafer Nr. 731
  db:priv_AddDB("Cards", 771319);  -- Karte - Elementarbestrafer Nr. 7 
  db:priv_AddDB("Cards", 771320);  -- Karte - Zur?ckkehrende alte Seele
  db:priv_AddDB("Cards", 771321);  -- Karte - Zur?ckkehrender alter Krieger
  db:priv_AddDB("Cards", 771322);  -- Karte - Zur?ckkehrender alter Magier
  db:priv_AddDB("Cards", 771323);  -- Karte - Kommandant der zur?ckkehrenden Armee
  db:priv_AddDB("Cards", 771324);  -- Karte - Kaluga-Blauadler
  db:priv_AddDB("Cards", 771325);  -- Karte - Kaluga-Braunb?r
  db:priv_AddDB("Cards", 771326);  -- Karte - Salvond-Schneeb?r
  db:priv_AddDB("Cards", 771327);  -- Karte - Salvond-Boshi
  db:priv_AddDB("Cards", 771328);  -- Karte - Grauer K?nig Sheluud
  db:priv_AddDB("Cards", 771329);  -- Karte - Zalkenrys
  db:priv_AddDB("Cards", 771330);  -- Karte - Riesiger Gr?nwaldmoskito
  db:priv_AddDB("Cards", 771331);  -- Karte - Gr?nwald-Mimengottesanbeterin
  db:priv_AddDB("Cards", 771332);  -- Karte - Schwirrklingenk?fer
  db:priv_AddDB("Cards", 771333);  -- Karte - Riesiger Rockden-Fl?gelfalter
  db:priv_AddDB("Cards", 771334);  -- 
  db:priv_AddDB("Cards", 771335);  -- Karte - Rockden-Eisspinne
  db:priv_AddDB("Cards", 771336);  -- Karte - Rockden-Panzerraupe
  db:priv_AddDB("Cards", 771337);  -- Karte - Rasendes Yasheedee
  db:priv_AddDB("Cards", 771338);  -- Karte - Schattenrei?er
  db:priv_AddDB("Cards", 771339);  -- Karte - Ruinenpirscher
  db:priv_AddDB("Cards", 771340);  -- Karte - ?ngstlicher Gauner
  db:priv_AddDB("Cards", 771341);  -- Karte - Ruinenschatten
  db:priv_AddDB("Cards", 771342);  -- Karte - Okkulter Spinner
  db:priv_AddDB("Cards", 771343);  -- Karte - Schattenwache
  db:priv_AddDB("Cards", 771344);  -- Karte - Waldpl?ndernder Draken
  db:priv_AddDB("Cards", 771345);  -- Karte - M?nnlicher Sturzwasserdraken
  db:priv_AddDB("Cards", 771346);  -- Karte - Zinnoberhornschildkr?te
  db:priv_AddDB("Cards", 771347);  -- Karte - Blutsaugender WasserHöhlenk?fer
  db:priv_AddDB("Cards", 771348);  -- Karte - Junger Sturzwasserdraken
  db:priv_AddDB("Cards", 771349);  -- Karte - Weiblicher Sturzwasserdraken
  db:priv_AddDB("Cards", 771350);  -- Karte - Draken Yapherian
  db:priv_AddDB("Cards", 771351);  -- Karte - Purpurm?hnen-Panzilla
  db:priv_AddDB("Cards", 771352);  -- Karte - Lavabergkrebs
  db:priv_AddDB("Cards", 771353);  -- Karte - Aufgescheuchte Kreatur
  db:priv_AddDB("Cards", 771354);  -- Karte - Zurhidon-Anh?nger
  db:priv_AddDB("Cards", 771355);  -- Karte - Zurhidon-Beschw?rerin
  db:priv_AddDB("Cards", 771356);  -- Karte - Zurhidon-Marionettenspieler
  db:priv_AddDB("Cards", 771357);  -- Karte - Kulech-Brutpfleger
  db:priv_AddDB("Cards", 771358);  -- Karte - Flammenfl?gel-Gargoyle
  db:priv_AddDB("Cards", 771359);  -- Karte - Zurhidon-Bomber
  db:priv_AddDB("Cards", 771360);  -- Karte - Lossogby
  db:priv_AddDB("Cards", 771361);  -- Karte - Investigationsbestrafer EX
  db:priv_AddDB("Cards", 771362);  -- Karte - Wutm?hnen-Chupura
  db:priv_AddDB("Cards", 771363);  -- Karte - Geschw?chtes Chupura
  db:priv_AddDB("Cards", 771364);  -- Karte - Feuer-Yasheedee
  db:priv_AddDB("Cards", 771365);  -- Karte - Farentel
  db:priv_AddDB("Cards", 771366);  -- Karte - Sengendes Zaubergas
  db:priv_AddDB("Cards", 771367);  -- Karte - Sengender Erd-Elementar
  db:priv_AddDB("Cards", 771368);  -- Karte - W?tender Schmelzd?mon
  db:priv_AddDB("Cards", 771369);  -- Karte - Zurhidon-Okkultist
  db:priv_AddDB("Cards", 771370);  -- Karte - Hammerfaust-Bestrafer
  db:priv_AddDB("Cards", 771371);  -- Karte - Baubestrafer
  db:priv_AddDB("Cards", 771372);  -- Karte - Auge von Vicky
  db:priv_AddDB("Cards", 771373);  -- Karte - Investigationsbestrafer
  db:priv_AddDB("Cards", 771374);  -- Karte - W?tender Baumgeist
  db:priv_AddDB("Cards", 771375);  -- Karte - Zurhidon-Pyromantiker
  db:priv_AddDB("Cards", 771376);  -- Karte - Zurhidon-Assassine
  db:priv_AddDB("Cards", 771377);  -- Karte - Unkontrollierter Erdelementar
  db:priv_AddDB("Cards", 771378);  -- Karte - Sarlo-Urwolfjunges
  db:priv_AddDB("Cards", 771379);  -- Karte - Ayven Lyndbo
  db:priv_AddDB("Cards", 771380);  -- Karte - WaldHüter
  db:priv_AddDB("Cards", 771381);  -- Karte - Verzauberter Hüter
  db:priv_AddDB("Cards", 771382);  -- Karte - Sarlo-Urw?lfin
  db:priv_AddDB("Cards", 771383);  -- Karte - Sarlo-Urwolf
  db:priv_AddDB("Cards", 771384);  -- Karte - Sarlo-Harthorn
  db:priv_AddDB("Cards", 771385);  -- 
  db:priv_AddDB("Cards", 771386);  -- Karte - Aufgehetzter Feuerelementar
  db:priv_AddDB("Cards", 771387);  -- Karte - Elementarbestrafer Nr. 733
  db:priv_AddDB("Cards", 771388);  -- Karte - Zurhidon-Drachenj?ger
  db:priv_AddDB("Cards", 771389);  -- Karte - Zurhidon-Wache
  db:priv_AddDB("Cards", 771390);  -- Karte - Versklavter Schmelzd?mon
  db:priv_AddDB("Cards", 771391);  -- Karte - Gez?hmter Urwolf
  db:priv_AddDB("Cards", 771392);  -- Karte - Umherstreifender Riesenbestrafer
  db:priv_AddDB("Cards", 771393);  -- Karte - Zurhidon-R?uber
  db:priv_AddDB("Cards", 771394);  -- Karte - Zurhidon-Auflauerer
  db:priv_AddDB("Cards", 771395);  -- Karte - Flammenspore
  db:priv_AddDB("Cards", 771396);  -- Karte - Feuriger Ameisenb?r
  db:priv_AddDB("Cards", 771397);  -- Karte - Flammenzungenbinder
  db:priv_AddDB("Cards", 771398);  -- Karte - Schattenassassine
  db:priv_AddDB("Cards", 771399);  -- Karte - Bestrafer Nr. 89-X
  db:priv_AddDB("Cards", 771400);  -- Karte - Zurhidon-Pirscher
  db:priv_AddDB("Cards", 771401);  -- Karte - Zurhidon-W?chter
  db:priv_AddDB("Cards", 771402);  -- Karte - ?berladener Bestrafer Nr. 89
  db:priv_AddDB("Cards", 771403);  -- Karte - ?berladene Bestrafer Nr. 103
  db:priv_AddDB("Cards", 771404);  -- Karte - Zurhidon-Champion
  db:priv_AddDB("Cards", 771405);  -- Karte - Zurhidon-Aggressor
  db:priv_AddDB("Cards", 771406);  -- Karte - Grabungsbestrafer Nr. 89
  db:priv_AddDB("Cards", 771407);  -- Karte - Kochender Wasserskorpion
  db:priv_AddDB("Cards", 771408);  -- Karte - Flammenfeder-Hippogryph
  db:priv_AddDB("Cards", 771409);  -- Karte - Verteidigungslinienbestrafer
  db:priv_AddDB("Cards", 771410);  -- Karte - Patrouillierender Verteidigungslinienbestrafer
  db:priv_AddDB("Cards", 771411);  -- Karte - Duplizierte Junge Kulech
  db:priv_AddDB("Cards", 771412);  -- Karte - Duplizierter Kulechpl?nderer
  db:priv_AddDB("Cards", 771413);  -- Karte - Duplizierter Kulech-Soldat
  db:priv_AddDB("Cards", 771414);  -- Karte - ?berwachungsbestrafer
  db:priv_AddDB("Cards", 771415);  -- Karte - Transmutierte Made
  db:priv_AddDB("Cards", 771416);  -- Karte - Patrouillierender Bestrafer
  db:priv_AddDB("Cards", 771417);  -- Karte - Besch?tzter Bestrafer
  db:priv_AddDB("Cards", 771418);  -- Karte - Korum-Sklave
  db:priv_AddDB("Cards", 771419);  -- Karte - Zurhidon-Experimentator
  db:priv_AddDB("Cards", 771420);  -- Karte - Erkundungskapit?n der Zurhidon
  db:priv_AddDB("Cards", 771421);  -- Karte - Zurhidon-Patrouille
  db:priv_AddDB("Cards", 771422);  -- Karte - Zurhidon-Patrouillenhauptmann
  db:priv_AddDB("Cards", 771423);  -- Karte - Unt?tiger Zurhidon
  db:priv_AddDB("Cards", 771424);  -- Karte - Jungzahnk?nig
  db:priv_AddDB("Cards", 771425);  -- Karte - Teufelskieselwurm
  db:priv_AddDB("Cards", 771426);  -- Karte - Jungzahn-Strandkrabbe
  db:priv_AddDB("Cards", 771427);  -- Karte - Jungzahn-Fischmonster
  db:priv_AddDB("Cards", 771428);  -- Karte - Jungzahn-Sammler
  db:priv_AddDB("Cards", 771429);  -- Karte - Scharlachglut-K?mpfer
  db:priv_AddDB("Cards", 771430);  -- Karte - Scharlachglut-K?mpferin
  db:priv_AddDB("Cards", 771431);  -- Karte - Schwarzzahn-Schn?bler
  db:priv_AddDB("Cards", 771432);  -- Karte - Steinkralle
  db:priv_AddDB("Cards", 771433);  -- Karte - Noktusechse
  db:priv_AddDB("Cards", 771434);  -- Karte - Scharfzahnbandit
  db:priv_AddDB("Cards", 771435);  -- Karte - Scharfzahnpl?nderer
  db:priv_AddDB("Cards", 771436);  -- 
  db:priv_AddDB("Cards", 771437);  -- Karte - Ellenpein Kuloka
  db:priv_AddDB("Cards", 771438);  -- Karte - Arum-Sandr?uber
  db:priv_AddDB("Cards", 771439);  -- Karte - Arum-Sandschurkin
  db:priv_AddDB("Cards", 771440);  -- Karte - Urmensch von Arum
  db:priv_AddDB("Cards", 771441);  -- Karte - Frevelbiene
  db:priv_AddDB("Cards", 771442);  -- Karte - Arum-Gulo
  db:priv_AddDB("Cards", 771443);  -- Karte - Jammer-M?hnenwolf
  db:priv_AddDB("Cards", 771444);  -- Karte - Salojungwiesel
  db:priv_AddDB("Cards", 771445);  -- Karte - Salowieselm?nnchen
  db:priv_AddDB("Cards", 771446);  -- Karte - Salowieselweibchen
  db:priv_AddDB("Cards", 771447);  -- Karte - Knochenkopf das Alphawiesel
  db:priv_AddDB("Cards", 771448);  -- Karte - Gez?hmtes Gulo
  db:priv_AddDB("Cards", 771449);  -- Karte - Zindkar-Piratentyrann
  db:priv_AddDB("Cards", 771450);  -- Karte - Zindkar-Diebin
  db:priv_AddDB("Cards", 771451);  -- Karte - Zindkar-Piratenpl?nderer
  db:priv_AddDB("Cards", 771452);  -- Karte - Zindkar-Wilderin
  db:priv_AddDB("Cards", 771453);  -- Karte - Zindkar-Tentakel
  db:priv_AddDB("Cards", 771454);  -- Karte - Höhlenhufkrabbe
  db:priv_AddDB("Cards", 771455);  -- Karte - Zindkar-Strandschnecke
  db:priv_AddDB("Cards", 771456);  -- Karte - Gr?ne Teufelsblume
  db:priv_AddDB("Cards", 771457);  -- Karte - Feyna-Riesenb?r
  db:priv_AddDB("Cards", 771458);  -- Karte - Jammerweide
  db:priv_AddDB("Cards", 771459);  -- Karte - Feyna-Schmetterling
  db:priv_AddDB("Cards", 771460);  -- Karte - Lenka
  db:priv_AddDB("Cards", 771461);  -- Karte - Hulu-J?ger
  db:priv_AddDB("Cards", 771462);  -- Karte - Hulu-Krieger
  db:priv_AddDB("Cards", 771463);  -- Karte - Hulu-Sturmkrieger
  db:priv_AddDB("Cards", 771464);  -- Karte - Scharfzahn-Pionierin
  db:priv_AddDB("Cards", 771465);  -- Karte - Blutr?nstiger Riesenwolf
  db:priv_AddDB("Cards", 771466);  -- Karte - Felsfeuerechse
  db:priv_AddDB("Cards", 771467);  -- Karte - Baby-Lenka
  db:priv_AddDB("Cards", 771468);  -- Karte - Blutr?nstiges Lenka
  db:priv_AddDB("Cards", 771469);  -- Karte - Blutr?nstiger Riesenwolfwelpe
  db:priv_AddDB("Cards", 771470);  -- Karte - W?tender Blutr?nstiger Riesenwolf
  db:priv_AddDB("Cards", 771471);  -- Karte - Zahme Felsfeuerechse
  db:priv_AddDB("Cards", 771472);  -- Karte - Zischotter
  db:priv_AddDB("Cards", 771473);  -- Karte - Hulu-Dorfbewohner
  db:priv_AddDB("Cards", 771474);  -- Karte - Kolanda
  db:priv_AddDB("Cards", 771475);  -- Karte - Sumpfschlangenmensch
  db:priv_AddDB("Cards", 771476);  -- Karte - Instabiler Wassergeist
  db:priv_AddDB("Cards", 771477);  -- Karte - Sumpf-Erdgeist
  db:priv_AddDB("Cards", 771478);  -- Karte - Baumgewordener Pirat
  db:priv_AddDB("Cards", 771479);  -- Karte - Baumgewordene Piratin
  db:priv_AddDB("Cards", 771480);  -- Karte - B?ser Matrosengeist
  db:priv_AddDB("Cards", 771481);  -- Karte - T?ckischer Matrosinnengeist
  db:priv_AddDB("Cards", 771482);  -- Karte - Großer Geist
  db:priv_AddDB("Cards", 771483);  -- Karte - J?ger der Sumpfschlangenmenschen
  db:priv_AddDB("Cards", 771484);  -- Karte - Knabbernder Schwarm
  db:priv_AddDB("Cards", 771485);  -- Karte - Welkender Entling
  db:priv_AddDB("Cards", 771486);  -- Karte - Lagon der T?uscher
  db:priv_AddDB("Cards", 771487);  -- 
  db:priv_AddDB("Cards", 771488);  -- Karte - Scharlachglut-W?chter
  db:priv_AddDB("Cards", 771489);  -- Karte - Scharlachglut-Kopfj?ger-Patrouille
  db:priv_AddDB("Cards", 771490);  -- Karte - Scharlachglut-Assassinenj?ger
  db:priv_AddDB("Cards", 771491);  -- Karte - Scharlachglut-Windrufer
  db:priv_AddDB("Cards", 771492);  -- Karte - Scharlachglut-Opferbringer
  db:priv_AddDB("Cards", 771493);  -- Karte - Eiserner Wachmechanismus
  db:priv_AddDB("Cards", 771494);  -- Karte - Stahlaxtwache
  db:priv_AddDB("Cards", 771495);  -- Karte - Stahlklingenwache
  db:priv_AddDB("Cards", 771496);  -- Karte - Stahlstabwache
  db:priv_AddDB("Cards", 771497);  -- Karte - Jalor-Agent
  db:priv_AddDB("Cards", 771498);  -- Karte - Jalor-W?chter
  db:priv_AddDB("Cards", 771499);  -- Karte - Jalor-Rekrut
  db:priv_AddDB("Cards", 771500);  -- Karte - Jalor-Schallschmiedrekrut
  db:priv_AddDB("Cards", 771501);  -- Karte - Wilde Klippenechse
  db:priv_AddDB("Cards", 771502);  -- Karte - Tapatapa-Klippenechse
  db:priv_AddDB("Cards", 771503);  -- Karte - Felsenschnecke
  db:priv_AddDB("Cards", 771504);  -- Karte - Verr?ckter Papowaka
  db:priv_AddDB("Cards", 771505);  -- Karte - Xabu-Dorfbewohner
  db:priv_AddDB("Cards", 771506);  -- Karte - Xabu-Verteidiger
  db:priv_AddDB("Cards", 771507);  -- Karte - Xabu-J?ger
  db:priv_AddDB("Cards", 771508);  -- Karte - Xabu-L?ufer
  db:priv_AddDB("Cards", 771509);  -- Karte - Wei?hornbestie
  db:priv_AddDB("Cards", 771510);  -- Karte - Schwarzhornbestie
  db:priv_AddDB("Cards", 771511);  -- Karte - Sumpfwegelagerer
  db:priv_AddDB("Cards", 771512);  -- Karte - Sumpf-Guerilla
  db:priv_AddDB("Cards", 771513);  -- Karte - Sumpfj?ger
  db:priv_AddDB("Cards", 771514);  -- Karte - Rotflecken-Monstrum
  db:priv_AddDB("Cards", 771515);  -- Karte - Mutierter Pukari
  db:priv_AddDB("Cards", 771516);  -- Karte - Mutiertes D?monenkraut
  db:priv_AddDB("Cards", 771517);  -- Karte - Frankopiraten-Heimlichtuer
  db:priv_AddDB("Cards", 771518);  -- Karte - Sumpf-Guerilla
  db:priv_AddDB("Cards", 771519);  -- Karte - Junge Wei?hornbestie
  db:priv_AddDB("Cards", 771520);  -- Karte - Wache der Frankopiraten
  db:priv_AddDB("Cards", 771521);  -- Karte - Sammler der Frankopiraten
  db:priv_AddDB("Cards", 771522);  -- Karte - Sammler-Aufseher der Frankopiraten
  db:priv_AddDB("Cards", 771523);  -- Karte - Eisenfaust Baul
  db:priv_AddDB("Cards", 771524);  -- Karte - Lagerpatrouille der Frankopiraten
  db:priv_AddDB("Cards", 771525);  -- Karte - Pl?nderer der Frankopiraten
  db:priv_AddDB("Cards", 771526);  -- Karte - Schwarznest-Riesenaffe
  db:priv_AddDB("Cards", 771527);  -- Karte - Fegefeuer-Spinne
  db:priv_AddDB("Cards", 771528);  -- Karte - Tigermolch
  db:priv_AddDB("Cards", 771529);  -- Karte - Blutbiene
  db:priv_AddDB("Cards", 771530);  -- Karte - Schwarznest-Gazelle
  db:priv_AddDB("Cards", 771531);  -- Karte - Aasfressender Wildhund
  db:priv_AddDB("Cards", 771532);  -- Karte - Fegefeuer-Geier
  db:priv_AddDB("Cards", 771533);  -- Karte - Fegefeuer-Blutpanther
  db:priv_AddDB("Cards", 771534);  -- Karte - Blutbienen-K?nigin
  db:priv_AddDB("Cards", 771535);  -- Karte - Jadekraut
  db:priv_AddDB("Cards", 771536);  -- Karte - Hungergeist
  db:priv_AddDB("Cards", 771537);  -- Karte - Schwarzaugen-Kulang
  db:priv_AddDB("Cards", 771538);  -- 
  db:priv_AddDB("Cards", 771539);  -- Karte - Nebelhexe
  db:priv_AddDB("Cards", 771540);  -- Karte - Schattenmantikor
  db:priv_AddDB("Cards", 771541);  -- Karte - Nicht infiziertes Gulo
  db:priv_AddDB("Cards", 771542);  -- Karte - Irunia-Adler
  db:priv_AddDB("Cards", 771543);  -- Karte - Große Dornenblutranke
  db:priv_AddDB("Cards", 771544);  -- Karte - Kleine Dornenblutranke
  db:priv_AddDB("Cards", 771545);  -- Karte - Infiziertes Gulo
  db:priv_AddDB("Cards", 771546);  -- Karte - Infiziertes Wildschwein
  db:priv_AddDB("Cards", 771547);  -- Karte - Infizierter Riesenb?r
  db:priv_AddDB("Cards", 771548);  -- Karte - Schatten des Dschungels
  db:priv_AddDB("Cards", 771549);  -- Karte - Salioca-Elefant
  db:priv_AddDB("Cards", 771550);  -- Karte - Nebel-Harpyie
  db:priv_AddDB("Cards", 771551);  -- Karte - Dschungelj?ger
  db:priv_AddDB("Cards", 771552);  -- Karte - Joja-Pango
  db:priv_AddDB("Cards", 771553);  -- Karte - Felsen-Scharfzahn
  db:priv_AddDB("Cards", 771554);  -- Karte - Fegefeuer-Schlange
  db:priv_AddDB("Cards", 771555);  -- Karte - Krieger der Walu
  db:priv_AddDB("Cards", 771556);  -- Karte - H?uptling der Walu
  db:priv_AddDB("Cards", 771557);  -- Karte - Walu-Schamane
  db:priv_AddDB("Cards", 771558);  -- Karte - Walu-Dorfbewohner
  db:priv_AddDB("Cards", 771559);  -- Karte - Wasserl?ufer
  db:priv_AddDB("Cards", 771560);  -- Karte - Wassertal-Entling
  db:priv_AddDB("Cards", 771561);  -- Karte - Regenbogenmilan der Schlucht
  db:priv_AddDB("Cards", 771562);  -- Karte - Waldleguan
  db:priv_AddDB("Cards", 771563);  -- Karte - Salioca-Honigmarder
  db:priv_AddDB("Cards", 771564);  -- Karte - Jade-Foger
  db:priv_AddDB("Cards", 771565);  -- Karte - Jademaus
  db:priv_AddDB("Cards", 771566);  -- Karte - Silberzimt-Nagek?fer
  db:priv_AddDB("Cards", 771567);  -- Karte - Wolf der Splitterstromk?ste
  db:priv_AddDB("Cards", 771568);  -- Karte - Zornzahn
  db:priv_AddDB("Cards", 771569);  -- Karte - Panzerschildkr?te der Splitterstromk?ste
  db:priv_AddDB("Cards", 771570);  -- Karte - Haarkrebs der Splitterstromk?ste
  db:priv_AddDB("Cards", 771571);  -- Karte - Feuerholz-Agent
  db:priv_AddDB("Cards", 771572);  -- Karte - Splitterstromdetektiv
  db:priv_AddDB("Cards", 771573);  -- Karte - Splitterstrom-Taugenichts
  db:priv_AddDB("Cards", 771574);  -- Karte - Splitterstrommagier
  db:priv_AddDB("Cards", 771575);  -- Karte - Karschid Krankwolf
  db:priv_AddDB("Cards", 771576);  -- Karte - Splitterstrom-Matrose
  db:priv_AddDB("Cards", 771577);  -- Karte - Piratensaufbold
  db:priv_AddDB("Cards", 771578);  -- Karte - Menschenfressendes Sumpfgras
  db:priv_AddDB("Cards", 771579);  -- Karte - Mutierter Sumpfschlamm
  db:priv_AddDB("Cards", 771580);  -- Karte - Sumpfsalamander
  db:priv_AddDB("Cards", 771581);  -- Karte - Sumpflenka
  db:priv_AddDB("Cards", 771582);  -- Karte - Stinkender Wassergigant
  db:priv_AddDB("Cards", 771583);  -- Karte - Stinkender Wasserelementar
  db:priv_AddDB("Cards", 771584);  -- Karte - Purpurlibelle
  db:priv_AddDB("Cards", 771585);  -- Karte - Sturzflut-Riesenkrebs
  db:priv_AddDB("Cards", 771586);  -- Karte - J?hzorniger S?gezahnfisch
  db:priv_AddDB("Cards", 771587);  -- Karte - Runen-Himmelsfeuer
  db:priv_AddDB("Cards", 771588);  -- Karte - Boshafter Fischk?nig
  db:priv_AddDB("Cards", 771589);  -- 
  db:priv_AddDB("Cards", 771590);  -- Karte - Sumpf-Duftb?r
  db:priv_AddDB("Cards", 771591);  -- Karte - T?towiertes Wildschwein
  db:priv_AddDB("Cards", 771592);  -- Karte - W?tendes Mammut
  db:priv_AddDB("Cards", 771593);  -- Karte - Panischer Strau?
  db:priv_AddDB("Cards", 771594);  -- Karte - Rasender Riesenwolf
  db:priv_AddDB("Cards", 771595);  -- Karte - Leichter Banka
  db:priv_AddDB("Cards", 771596);  -- Karte - Kashay-Patrouille
  db:priv_AddDB("Cards", 771597);  -- Karte - Kashay-Gelegenheitsarbeiter
  db:priv_AddDB("Cards", 771598);  -- Karte - Fahrer eines leichten Bankas
  db:priv_AddDB("Cards", 771599);  -- Karte - Felsenadlerk?nig
  db:priv_AddDB("Cards", 771600);  -- Karte - W?tendes Kleinmammut
  db:priv_AddDB("Cards", 771601);  -- Karte - Hluthar Gl?hfeder
  db:priv_AddDB("Cards", 771602);  -- Karte - Sandsteinskorpion des Flammenwindes
  db:priv_AddDB("Cards", 771603);  -- Karte - Blutsaugender Floh
  db:priv_AddDB("Cards", 771604);  -- Karte - Harpyien-Assassine
  db:priv_AddDB("Cards", 771605);  -- Karte - Harpyienbeschw?rerin
  db:priv_AddDB("Cards", 771606);  -- Karte - Eingeschleppter Floh
  db:priv_AddDB("Cards", 771607);  -- Karte - Rotes W?stengespenst
  db:priv_AddDB("Cards", 771608);  -- Karte - Trockenlaubschluchtk?fer
  db:priv_AddDB("Cards", 771609);  -- Karte - Schluchtstachelbeerm?nnchen
  db:priv_AddDB("Cards", 771610);  -- Karte - W?chter der Befallenen
  db:priv_AddDB("Cards", 771611);  -- Karte - Kashay-Krieger
  db:priv_AddDB("Cards", 771612);  -- Karte - Schattenschwinge
  db:priv_AddDB("Cards", 771613);  -- Karte - Balu-St?rmer
  db:priv_AddDB("Cards", 771614);  -- Karte - Balu-Dorfbewohner
  db:priv_AddDB("Cards", 771615);  -- Karte - Balu-Krieger
  db:priv_AddDB("Cards", 771616);  -- Karte - Gieriger Sandk?fer
  db:priv_AddDB("Cards", 771617);  -- Karte - Kashay-St?rmer
  db:priv_AddDB("Cards", 771618);  -- Karte - Kashay-Angreifer
  db:priv_AddDB("Cards", 771619);  -- Karte - Kashay-Wache
  db:priv_AddDB("Cards", 771620);  -- Karte - Mantikor-Kriegsbestie
  db:priv_AddDB("Cards", 771621);  -- Karte - Wildes Mantikorm?nnchen
  db:priv_AddDB("Cards", 771622);  -- Karte - Wildes Mantikorweibchen
  db:priv_AddDB("Cards", 771623);  -- Karte - Skelettsoldat
  db:priv_AddDB("Cards", 771624);  -- Karte - Schattenmagier
  db:priv_AddDB("Cards", 771625);  -- Karte - Grabfledermaus
  db:priv_AddDB("Cards", 771626);  -- Karte - Splitterstromkanonier
  db:priv_AddDB("Cards", 771627);  -- Karte - Splitterstromnavigator
  db:priv_AddDB("Cards", 771628);  -- Karte - Splitterstrom-Schiffsarzt
  db:priv_AddDB("Cards", 771629);  -- Karte - Schleierhafenbewohner
  db:priv_AddDB("Cards", 771630);  -- Karte - Schleierhafenbewohner
  db:priv_AddDB("Cards", 771631);  -- Karte - Riesenfeldmaus
  db:priv_AddDB("Cards", 771632);  -- Karte - B?r der Splitterstromk?ste
  db:priv_AddDB("Cards", 771633);  -- Karte - Ger?chteverbreitender Pachtbauer
  db:priv_AddDB("Cards", 771634);  -- Karte - Schlammflossen-Patrouille
  db:priv_AddDB("Cards", 771635);  -- Karte - Schlammflossen-Wasserbeschw?rer
  db:priv_AddDB("Cards", 771636);  -- Karte - Gazelle der Splitterstromk?ste
  db:priv_AddDB("Cards", 771637);  -- Karte - Schlammflossen-Wanderj?ger
  db:priv_AddDB("Cards", 771638);  -- Karte - Zahmer Schlammflossen-Scealok
  db:priv_AddDB("Cards", 771639);  -- Karte - Schlammflossen-K?mpfer
  db:priv_AddDB("Cards", 771640);  -- 
  db:priv_AddDB("Cards", 771641);  -- Karte - Mysteri?ser Ausbilder
  db:priv_AddDB("Cards", 771642);  -- Karte - Mysteri?ser Hexenmeister
  db:priv_AddDB("Cards", 771643);  -- Karte - Scealokkeimling
  db:priv_AddDB("Cards", 771644);  -- Karte - Sumpfland-Schwertalligator
  db:priv_AddDB("Cards", 771645);  -- Karte - Junge Gazelle der Splitterstromk?ste
  db:priv_AddDB("Cards", 771646);  -- Karte - W?tender Dscharbas
  db:priv_AddDB("Cards", 771647);  -- Karte - Wilder Scealok
  db:priv_AddDB("Cards", 771648);  -- Karte - Feuerholzkuli
  db:priv_AddDB("Cards", 771649);  -- Karte - Feuerholz-Berserker
  db:priv_AddDB("Cards", 771650);  -- Karte - Feuerholz-J?ger
  db:priv_AddDB("Cards", 771651);  -- Karte - Feuerholz-Panzerwache
  db:priv_AddDB("Cards", 771652);  -- Karte - Feuerholz-Vorarbeiter
  db:priv_AddDB("Cards", 771653);  -- Karte - "Der Große Aufseher" Tirkt?rk
  db:priv_AddDB("Cards", 771654);  -- Karte - Feuerholz-Kampfkeiler
  db:priv_AddDB("Cards", 771655);  -- Karte - Schwarzer Keiler mit roten Borsten
  db:priv_AddDB("Cards", 771656);  -- Karte - Feuerholz-Schamane
  db:priv_AddDB("Cards", 771657);  -- Karte - Hochlandbuddelwurm
  db:priv_AddDB("Cards", 771658);  -- Karte - Hofs?ldner
  db:priv_AddDB("Cards", 771659);  -- Karte - Assassine der Rabengarde
  db:priv_AddDB("Cards", 771660);  -- Karte - Totenbeschw?rer der Rabengarde
  db:priv_AddDB("Cards", 771661);  -- Karte - Wildes Boshi der Splitterstromk?ste
  db:priv_AddDB("Cards", 771662);  -- Karte - Splitterstrom-Klingenf??ler
  db:priv_AddDB("Cards", 771663);  -- Karte - H?geltr?ffelschwein
  db:priv_AddDB("Cards", 771664);  -- Karte - H?gelgulo
  db:priv_AddDB("Cards", 771665);  -- Karte - Verlorener Skelettsoldat
  db:priv_AddDB("Cards", 771666);  -- Karte - Verlorener Skeletthauptmann
  db:priv_AddDB("Cards", 771667);  -- Karte - Verlorener H?llenhund
  db:priv_AddDB("Cards", 771668);  -- Karte - Gliederloser Kriecher
  db:priv_AddDB("Cards", 771669);  -- Karte - Blutsaugende Sumpffledermaus
  db:priv_AddDB("Cards", 771670);  -- Karte - Sumpfzombie
  db:priv_AddDB("Cards", 771671);  -- Karte - Rastlose Seele der Bosheit
  db:priv_AddDB("Cards", 771672);  -- Karte - Goldene Grabschlange
  db:priv_AddDB("Cards", 771673);  -- Karte - Langbeinige Faulfleischspinne
  db:priv_AddDB("Cards", 771674);  -- Karte - Skelettgeneral
  db:priv_AddDB("Cards", 771675);  -- Karte - Rote H?gelechse
  db:priv_AddDB("Cards", 771676);  -- Karte - H?gelbreitmaulrhino
  db:priv_AddDB("Cards", 771677);  -- Karte - D?monisches Tr?ffelschwein
  db:priv_AddDB("Cards", 771678);  -- Karte - Flickenmonster
  db:priv_AddDB("Cards", 771679);  -- Karte - Kleines Breitmaulrhino
  db:priv_AddDB("Cards", 771680);  -- Karte - H?gelfelsmonster
  db:priv_AddDB("Cards", 771681);  -- Karte - Kleine schwarze Vampirfledermaus
  db:priv_AddDB("Cards", 771682);  -- Karte - Vogelgef?hrte
  db:priv_AddDB("Cards", 771683);  -- Karte - Azurolibelle von Farsitan
  db:priv_AddDB("Cards", 771684);  -- Karte - Eisenkiefer-Berserker
  db:priv_AddDB("Cards", 771685);  -- Karte - Pachakon
  db:priv_AddDB("Cards", 771686);  -- Karte - Eisenkiefer-General
  db:priv_AddDB("Cards", 771687);  -- Karte - Eisenkiefer-Graphitschamane
  db:priv_AddDB("Cards", 771688);  -- Karte - Eisenkiefer-Patrouillenbestie
  db:priv_AddDB("Cards", 771689);  -- Karte - Eisenkiefer-Hortw?chter
  db:priv_AddDB("Cards", 771690);  -- Karte - Wahnsinniger Minenarbeiter
  db:priv_AddDB("Cards", 771691);  -- 
  db:priv_AddDB("Cards", 771692);  -- Karte - Eisenkiefer-Geistschamane
  db:priv_AddDB("Cards", 771693);  -- Karte - Verd?chtiger Gl?ubiger
  db:priv_AddDB("Cards", 771694);  -- Karte - Feindselige Wache
  db:priv_AddDB("Cards", 771695);  -- Karte - Schattenmagier der Schattenbanditen
  db:priv_AddDB("Cards", 771696);  -- Karte - Tempelwachhund
  db:priv_AddDB("Cards", 771697);  -- Karte - Verd?chtiger Priester
  db:priv_AddDB("Cards", 771698);  -- Karte - Tempeldiener
  db:priv_AddDB("Cards", 771699);  -- Karte - Entstellter Rei?er
  db:priv_AddDB("Cards", 771700);  -- Karte - D?monensoldat der Vorhut
  db:priv_AddDB("Cards", 771701);  -- Karte - Fansar
  db:priv_AddDB("Cards", 771702);  -- Karte - Stachelschlange von Farsitan
  db:priv_AddDB("Cards", 771703);  -- Karte - Strau? von Farsitan
  db:priv_AddDB("Cards", 771704);  -- Karte - Verlorener Skelettmagier
  db:priv_AddDB("Cards", 771705);  -- Karte - Ruinenschatten
  db:priv_AddDB("Cards", 771706);  -- Karte - Geheimvollstrecker
  db:priv_AddDB("Cards", 771707);  -- Karte - Koboldkundschafter
  db:priv_AddDB("Cards", 771708);  -- Karte - Sismond
  db:priv_AddDB("Cards", 771709);  -- Karte - Tasuq-Strandkrebs
  db:priv_AddDB("Cards", 771710);  -- Karte - Tasuq-Scealok
  db:priv_AddDB("Cards", 771711);  -- Karte - Tasuq-Einsiedlerkrebs
  db:priv_AddDB("Cards", 771712);  -- Karte - Tasuq-Piratenwiederg?nger
  db:priv_AddDB("Cards", 771713);  -- Karte - Tasuq-Sch?tzenwiederg?nger
  db:priv_AddDB("Cards", 771714);  -- Karte - Tasuq-Schwertk?mpferwiederg?ngerin
  db:priv_AddDB("Cards", 771715);  -- Karte - Verstohlener Gauner
  db:priv_AddDB("Cards", 771716);  -- Karte - Verstohlene Wache
  db:priv_AddDB("Cards", 771717);  -- Karte - Verstohlener Kampfmagier
  db:priv_AddDB("Cards", 771718);  -- Karte - Verstohlener Lagerhauptmann
  db:priv_AddDB("Cards", 771719);  -- Karte - Verstohlener Forscher
  db:priv_AddDB("Cards", 771720);  -- Karte - Kontrollierte Kriegerleiche
  db:priv_AddDB("Cards", 771721);  -- Karte - Kontrollierte Piratenleiche
  db:priv_AddDB("Cards", 771722);  -- Karte - Verwirrter Fruchtkaktus
  db:priv_AddDB("Cards", 771723);  -- Karte - Verwirrter Blutenkaktus
  db:priv_AddDB("Cards", 771724);  -- Karte - Verwirrter Nadelkaktus
  db:priv_AddDB("Cards", 771725);  -- Karte - Launischer Riesenzangenskorpion
  db:priv_AddDB("Cards", 771726);  -- Karte - Staublager-Gauner
  db:priv_AddDB("Cards", 771727);  -- Karte - Dunkler Magier des Staublagers
  db:priv_AddDB("Cards", 771728);  -- Karte - Staublager-Hauptmann
  db:priv_AddDB("Cards", 771729);  -- Karte - Staublager-Forscher
  db:priv_AddDB("Cards", 771730);  -- Karte - Tasuq-Panther
  db:priv_AddDB("Cards", 771731);  -- Karte - Gestreiftes Tasuq-Gulo
  db:priv_AddDB("Cards", 771732);  -- Karte - Tasuq-Wildschwein
  db:priv_AddDB("Cards", 771733);  -- Karte - Tasuq-Libelle
  db:priv_AddDB("Cards", 771734);  -- Karte - Tasuq-Dorngras
  db:priv_AddDB("Cards", 771735);  -- Karte - Tasuq-Tukan
  db:priv_AddDB("Cards", 771736);  -- Karte - Schattenlager-Gauner
  db:priv_AddDB("Cards", 771737);  -- Karte - Dunkler Magier des Schattenlagers
  db:priv_AddDB("Cards", 771738);  -- Karte - Schattenlager-Hauptmann
  db:priv_AddDB("Cards", 771739);  -- Karte - Schattenlager-Forscher
  db:priv_AddDB("Cards", 771740);  -- Karte - Tasuq-Rotfedervogel
  db:priv_AddDB("Cards", 771741);  -- Karte - Tasuq-Blaufedervogel
  db:priv_AddDB("Cards", 771742);  -- 
  db:priv_AddDB("Cards", 771743);  -- Karte - Tasuq-Giftschlange
  db:priv_AddDB("Cards", 771744);  -- Karte - Honigwei?es Tasuq-Frettchen
  db:priv_AddDB("Cards", 771745);  -- Karte - Brauner Tasuqwolf
  db:priv_AddDB("Cards", 771746);  -- Karte - Verfallene Harpyie
  db:priv_AddDB("Cards", 771747);  -- Karte - Verfallener Felsskorpion
  db:priv_AddDB("Cards", 771748);  -- Karte - Assassine des Tals ohne Wiederkehr
  db:priv_AddDB("Cards", 771749);  -- Karte - B?ser Formgeber des Tals ohne Wiederkehr
  db:priv_AddDB("Cards", 771750);  -- Karte - Wache des Tals ohne Wiederkehr
  db:priv_AddDB("Cards", 771751);  -- Karte - Schatten des Tals ohne Wiederkehr
  db:priv_AddDB("Cards", 771752);  -- Karte - Chaotische dunkle Energie
  db:priv_AddDB("Cards", 771753);  -- Karte - Verschlingersoldat des Rei?ers
  db:priv_AddDB("Cards", 771754);  -- Karte - Assassine des Rei?ers
  db:priv_AddDB("Cards", 771755);  -- Karte - B?ser Formgeber des Rei?ers
  db:priv_AddDB("Cards", 771756);  -- Karte - Magierwache des Rei?ers
  db:priv_AddDB("Cards", 771757);  -- Karte - Forscher des Rei?ers
  db:priv_AddDB("Cards", 771758);  -- Karte - Schatten des Rei?ers
  db:priv_AddDB("Cards", 771759);  -- Karte - Dunkle Energie des Rei?ers
  db:priv_AddDB("Cards", 771760);  -- Karte - Geist des Piratenkapit?ns Sjubold
  db:priv_AddDB("Cards", 771761);  -- Karte - Lageroffizier Dawith
  db:priv_AddDB("Cards", 771762);  -- Karte - Offizierin Abley
  db:priv_AddDB("Cards", 771763);  -- Karte - Elite-D?monenschwertk?mpfer
  db:priv_AddDB("Cards", 771764);  -- Karte - Mutiertes Gulo
  db:priv_AddDB("Cards", 771765);  -- Karte - Kundschafter des Zirkels des Unverw?stlichen
  db:priv_AddDB("Cards", 771766);  -- Karte - Tieflandpanther
  db:priv_AddDB("Cards", 771767);  -- Karte - Tieflandkeiler
  db:priv_AddDB("Cards", 771768);  -- Karte - Tieflandgiftbiene
  db:priv_AddDB("Cards", 771769);  -- Karte - Tieflandhonigmarder
  db:priv_AddDB("Cards", 771770);  -- Karte - Fleischfressende Pflanze des Tieflands
  db:priv_AddDB("Cards", 771771);  -- Karte - Tieflandwaldwolf
  db:priv_AddDB("Cards", 771772);  -- Karte - Schattenwache
  db:priv_AddDB("Cards", 771773);  -- Karte - Schattenkraftwandler
  db:priv_AddDB("Cards", 771774);  -- Karte - Schatten-Magierwache
  db:priv_AddDB("Cards", 771775);  -- Karte - Schattenpriester
  db:priv_AddDB("Cards", 771776);  -- Karte - Schattenaggregat
  db:priv_AddDB("Cards", 771777);  -- Karte - Schattengerippe
  db:priv_AddDB("Cards", 771778);  -- Karte - Scealok der siechenden See
  db:priv_AddDB("Cards", 771779);  -- Karte - Wache der siechenden See
  db:priv_AddDB("Cards", 771780);  -- Karte - Kraftwandler der siechenden See
  db:priv_AddDB("Cards", 771781);  -- Karte - Magierwache der siechenden See
  db:priv_AddDB("Cards", 771782);  -- Karte - Priester der siechenden See
  db:priv_AddDB("Cards", 771783);  -- Karte - Aggregat der siechenden See
  db:priv_AddDB("Cards", 771784);  -- Karte - Gerippe der siechenden See
  db:priv_AddDB("Cards", 771785);  -- Karte - Finsterbergschatten
  db:priv_AddDB("Cards", 771786);  -- Karte - Finsterbergwache
  db:priv_AddDB("Cards", 771787);  -- Karte - Finsterbergkraftwandler
  db:priv_AddDB("Cards", 771788);  -- Karte - Finsterbergmagierwache
  db:priv_AddDB("Cards", 771789);  -- Karte - Finsterbergpriester
  db:priv_AddDB("Cards", 771790);  -- Karte - Finsterberg-Zyklopen-Berserker
  db:priv_AddDB("Cards", 771791);  -- Karte - Finsterberg-Minotaurenschamane
  db:priv_AddDB("Cards", 771792);  -- Karte - Bergpfad-Kundschafter
  db:priv_AddDB("Cards", 771793);  -- 
  db:priv_AddDB("Cards", 771794);  -- Karte - Bergpilger-Gulo
  db:priv_AddDB("Cards", 771795);  -- Karte - Bergpilger-Falke
  db:priv_AddDB("Cards", 771796);  -- Karte - Hochlandschneefrettchen
  db:priv_AddDB("Cards", 771797);  -- Karte - Hochlandreh
  db:priv_AddDB("Cards", 771798);  -- Karte - Hochland-Schneeschwein
  db:priv_AddDB("Cards", 771799);  -- Karte - Hochland-Berhu
  db:priv_AddDB("Cards", 771800);  -- Karte - Hochlandechse
  db:priv_AddDB("Cards", 771801);  -- Karte - Hochlandeisfee
  db:priv_AddDB("Cards", 771802);  -- Karte - Hochland-M?hnenfuchs
  db:priv_AddDB("Cards", 771803);  -- Karte - Frostlagerwache
  db:priv_AddDB("Cards", 771804);  -- Karte - Frostlager-Kraftwandler
  db:priv_AddDB("Cards", 771805);  -- Karte - Frostlager-Magierwache
  db:priv_AddDB("Cards", 771806);  -- Karte - Frostlager-Verschlingersoldat
  db:priv_AddDB("Cards", 771807);  -- Karte - Frostlager-Eishexe
  db:priv_AddDB("Cards", 771808);  -- Karte - Frostauge-Berserker
  db:priv_AddDB("Cards", 771809);  -- Karte - Frostauge-Magier
  db:priv_AddDB("Cards", 771810);  -- Karte - Frostauge-Kampfkommandant
  db:priv_AddDB("Cards", 771811);  -- Karte - Frostauge-Kampfpriester
  db:priv_AddDB("Cards", 771812);  -- Karte - Frostauge-Kampfschwein
  db:priv_AddDB("Cards", 771813);  -- Karte - Schamane der eisigen Bastion
  db:priv_AddDB("Cards", 771814);  -- Karte - Krieger der eisigen Bastion
  db:priv_AddDB("Cards", 771815);  -- Karte - Segenschamane der eisigen Bastion
  db:priv_AddDB("Cards", 771816);  -- Karte - Eisenwache der eisigen Bastion
  db:priv_AddDB("Cards", 771817);  -- Karte - Frostkristall der eisigen Bastion
  db:priv_AddDB("Cards", 771818);  -- Karte - Berhu der eisigen Bastion
  db:priv_AddDB("Cards", 771819);  -- Karte - Frostlager-Sympathisantin
  db:priv_AddDB("Cards", 771820);  -- Karte - Cador
  db:priv_AddDB("Cards", 771821);  -- Karte - Herfniak
  db:priv_AddDB("Cards", 771822);  -- Karte - Mutierter Mosto
  db:priv_AddDB("Cards", 771823);  -- Karte - D?monen-Verschlingersoldat
  db:priv_AddDB("Cards", 771824);  -- Karte - D?monengauner
  db:priv_AddDB("Cards", 771825);  -- Karte - D?monenkampfmagier
  db:priv_AddDB("Cards", 771826);  -- Karte - D?monenmagierwache
  db:priv_AddDB("Cards", 771827);  -- Karte - D?monenforscher
  db:priv_AddDB("Cards", 771828);  -- Karte - Faulatemschatten
  db:priv_AddDB("Cards", 771829);  -- Karte - Faule Schattenenergie
  db:priv_AddDB("Cards", 771830);  -- Karte - Yorza
  db:priv_AddDB("Cards", 771831);  -- Karte - Sorlen
  db:priv_AddDB("Cards", 771832);  -- Karte - Kurda
  db:priv_AddDB("Cards", 771833);  -- Karte - Moderfressende Giftpflanze
  db:priv_AddDB("Cards", 771834);  -- Karte - Junger Kreios-Draco
  db:priv_AddDB("Cards", 771835);  -- Karte - Erwachsener Kreios-Draco
  db:priv_AddDB("Cards", 771836);  -- Karte - Legend?rer Kreios-Draco
  db:priv_AddDB("Cards", 771837);  -- Karte - Junge Tethys-Draco
  db:priv_AddDB("Cards", 771838);  -- Karte - Erwachsene Tethys-Draco
  db:priv_AddDB("Cards", 771839);  -- Karte - Legend?re Tethys-Draco
  db:priv_AddDB("Cards", 771840);  -- Karte - Junger Okeanos-Draco
  db:priv_AddDB("Cards", 771841);  -- Karte - Erwachsener Okeanos-Draco
  db:priv_AddDB("Cards", 771842);  -- Karte - Legend?rer Okeanos-Draco
  db:priv_AddDB("Cards", 771843);  -- Karte - Junger Koios-Draco
  db:priv_AddDB("Cards", 771844);  -- 
  db:priv_AddDB("Cards", 771845);  -- Karte - Legend?rer Koios-Draco
  db:priv_AddDB("Cards", 771846);  -- Karte - Junger Kronos-Draco
  db:priv_AddDB("Cards", 771847);  -- Karte - Erwachsener Kronos-Draco
  db:priv_AddDB("Cards", 771848);  -- Karte - Legend?rer Kronos-Draco
  db:priv_AddDB("Cards", 771849);  -- Karte - Junge Rhea-Draco
  db:priv_AddDB("Cards", 771850);  -- Karte - Erwachsene Rhea-Draco
  db:priv_AddDB("Cards", 771851);  -- Karte - Legend?re Rhea-Draco
  db:priv_AddDB("Cards", 771852);  -- Karte - Junge Mnemosyne-Draco
  db:priv_AddDB("Cards", 771853);  -- Karte - Erwachsene Mnemosyne-Draco
  db:priv_AddDB("Cards", 771854);  -- Karte - Legend?re Mnemosyne-Draco
  db:priv_AddDB("Cards", 771855);  -- Karte - Junger Hyperion-Draco
  db:priv_AddDB("Cards", 771856);  -- Karte - Erwachsener Hyperion-Draco
  db:priv_AddDB("Cards", 771857);  -- Karte - Legend?rer Hyperion-Draco
  db:priv_AddDB("Cards", 771858);  -- Karte - Junger Iapetos-Draco
  db:priv_AddDB("Cards", 771859);  -- Karte - Erwachsener Iapetos-Draco
  db:priv_AddDB("Cards", 771860);  -- Karte - Legend?rer Iapetos-Draco
  db:priv_AddDB("Cards", 771861);  -- Karte - Junge Theia-Draco
  db:priv_AddDB("Cards", 771862);  -- Karte - Erwachsene Theia-Draco
  db:priv_AddDB("Cards", 771863);  -- Karte - Legend?re Theia-Draco
  db:priv_AddDB("Cards", 771864);  -- Karte - Junge Themis-Draco
  db:priv_AddDB("Cards", 771865);  -- Karte - Erwachsene Themis-Draco
  db:priv_AddDB("Cards", 771866);  -- Karte - Legend?re Themis-Draco
  db:priv_AddDB("Cards", 771867);  -- Karte - Junge Phoibe-Draco
  db:priv_AddDB("Cards", 771868);  -- Karte - Erwachsene Phoibe-Draco
  db:priv_AddDB("Cards", 771869);  -- Karte - Legend?re Phoibe-Draco
  db:priv_AddDB("Cards", 771870);  -- 
  db:priv_AddDB("Cards", 771871);  -- 
  db:priv_AddDB("Cards", 771872);  -- 
  db:priv_AddDB("Cards", 771873);  -- 
  db:priv_AddDB("Cards", 771874);  -- 
  db:priv_AddDB("Cards", 771875);  -- 
  db:priv_AddDB("Cards", 771876);  -- 
  db:priv_AddDB("Cards", 771877);  -- 
  db:priv_AddDB("Cards", 771878);  -- 
  db:priv_AddDB("Cards", 771879);  -- 
  db:priv_AddDB("Cards", 771880);  -- 
  db:priv_AddDB("Cards", 771881);  -- 
  db:priv_AddDB("Cards", 771882);  -- 
  db:priv_AddDB("Cards", 771883);  -- 
  db:priv_AddDB("Cards", 771884);  -- 
  db:priv_AddDB("Cards", 771885);  -- 
  db:priv_AddDB("Cards", 771886);  -- 
  db:priv_AddDB("Cards", 771887);  -- 
  db:priv_AddDB("Cards", 771888);  -- 
  db:priv_AddDB("Cards", 771889);  -- 
  db:priv_AddDB("Cards", 771890);  -- 
  db:priv_AddDB("Cards", 771891);  -- 
  db:priv_AddDB("Cards", 771892);  -- 
  db:priv_AddDB("Cards", 771893);  -- 
  db:priv_AddDB("Cards", 771894);  -- 
  db:priv_AddDB("Cards", 771895);  -- 
  db:priv_AddDB("Cards", 771896);  -- 
  db:priv_AddDB("Cards", 771897);  -- 
  db:priv_AddDB("Cards", 771898);  -- 
  db:priv_AddDB("Cards", 771899);  -- 
  db:priv_AddDB("Cards", 771900);  -- 
  db:priv_AddDB("Cards", 771901);  -- 
  db:priv_AddDB("Cards", 771902);  -- 
  db:priv_AddDB("Cards", 771903);  -- 
  db:priv_AddDB("Cards", 771904);  -- 
  db:priv_AddDB("Cards", 771905);  -- 
  db:priv_AddDB("Cards", 771906);  -- 
  db:priv_AddDB("Cards", 771907);  -- 
  db:priv_AddDB("Cards", 771908);  -- 
  db:priv_AddDB("Cards", 771909);  -- 
  db:priv_AddDB("Cards", 771910);  -- 
  db:priv_AddDB("Cards", 771911);  -- 
  db:priv_AddDB("Cards", 771912);  -- 
  db:priv_AddDB("Cards", 771913);  -- 
  db:priv_AddDB("Cards", 771914);  -- 
  db:priv_AddDB("Cards", 771915);  -- 
  db:priv_AddDB("Cards", 771916);  -- 
  db:priv_AddDB("Cards", 771917);  -- 
  db:priv_AddDB("Cards", 771918);  -- 
  db:priv_AddDB("Cards", 771919);  -- 
  db:priv_AddDB("Cards", 771920);  -- 
  db:priv_AddDB("Cards", 771921);  -- 
  db:priv_AddDB("Cards", 771922);  -- 
  db:priv_AddDB("Cards", 771923);  -- 
  db:priv_AddDB("Cards", 771924);  -- 
  db:priv_AddDB("Cards", 771925);  -- 
  db:priv_AddDB("Cards", 771926);  -- 
  db:priv_AddDB("Cards", 771927);  -- 
  db:priv_AddDB("Cards", 771928);  -- 
  db:priv_AddDB("Cards", 771929);  -- 
  db:priv_AddDB("Cards", 771930);  -- 
  db:priv_AddDB("Cards", 771931);  -- 
  db:priv_AddDB("Cards", 771932);  -- 
  db:priv_AddDB("Cards", 771933);  -- 
  db:priv_AddDB("Cards", 771934);  -- 
  db:priv_AddDB("Cards", 771935);  -- 
  db:priv_AddDB("Cards", 771936);  -- 
  db:priv_AddDB("Cards", 771937);  -- 
  db:priv_AddDB("Cards", 771938);  -- 
  db:priv_AddDB("Cards", 771939);  -- 
  db:priv_AddDB("Cards", 771940);  -- 
  db:priv_AddDB("Cards", 771941);  -- 
  db:priv_AddDB("Cards", 771942);  -- 
  db:priv_AddDB("Cards", 771943);  -- 
  db:priv_AddDB("Cards", 771944);  -- 
  db:priv_AddDB("Cards", 771945);  -- 
  db:priv_AddDB("Cards", 771946);  -- 
  db:priv_AddDB("Cards", 771947);  -- 
  db:priv_AddDB("Cards", 771948);  -- 
  db:priv_AddDB("Cards", 771949);  -- 
  db:priv_AddDB("Cards", 771950);  -- 
  db:priv_AddDB("Cards", 771951);  -- 
  db:priv_AddDB("Cards", 771952);  -- 
  db:priv_AddDB("Cards", 771953);  -- 
  db:priv_AddDB("Cards", 771954);  -- 
  db:priv_AddDB("Cards", 771955);  -- 
  db:priv_AddDB("Cards", 771956);  -- 
  db:priv_AddDB("Cards", 771957);  -- 
  db:priv_AddDB("Cards", 771958);  -- 
  db:priv_AddDB("Cards", 771959);  -- 
  db:priv_AddDB("Cards", 771960);  -- 
  db:priv_AddDB("Cards", 771961);  -- 
  db:priv_AddDB("Cards", 771962);  -- 
  db:priv_AddDB("Cards", 771963);  -- 
  db:priv_AddDB("Cards", 771964);  -- 
  db:priv_AddDB("Cards", 771965);  -- 
  db:priv_AddDB("Cards", 771966);  -- 
  db:priv_AddDB("Cards", 771967);  -- 
  db:priv_AddDB("Cards", 771968);  -- 
  db:priv_AddDB("Cards", 771969);  -- 
  db:priv_AddDB("Cards", 771970);  -- 
  db:priv_AddDB("Cards", 771971);  -- 
  db:priv_AddDB("Cards", 771972);  -- 
  db:priv_AddDB("Cards", 771973);  -- 
  db:priv_AddDB("Cards", 771974);  -- 
  db:priv_AddDB("Cards", 771975);  -- 
  db:priv_AddDB("Cards", 771976);  -- 
  db:priv_AddDB("Cards", 771977);  -- 
  db:priv_AddDB("Cards", 771978);  -- 
  db:priv_AddDB("Cards", 771979);  -- 
  db:priv_AddDB("Cards", 771980);  -- Karte - Mutierte Giftlibelle
  db:priv_AddDB("Cards", 771981);  -- 
  db:priv_AddDB("Cards", 771982);  -- 
  db:priv_AddDB("Cards", 771983);  -- 
  db:priv_AddDB("Cards", 771984);  -- 
  db:priv_AddDB("Cards", 771985);  -- 
  db:priv_AddDB("Cards", 771986);  --   
  


end

local function priv_AddRunePetEggs(db) -- Rune
  db:priv_AddDB("RunePetEgg", 204506); --Blue Rune Egg 6.4.1.2758
  db:priv_AddDB("RunePetEgg", 204507); --Purple Rune Egg 6.4.1.2758
  db:priv_AddDB("RunePetEgg", 204508); --orange Rune Egg 6.4.1.2758
  db:priv_AddDB("RunePetEgg", 204509); --white Rune Egg 6.4.1.2758
end;

local function priv_AddEarthPetEggs(db) -- Erde
  db:priv_AddDB("EarthPetEgg", 204476); --white 6.4.1.2758
  db:priv_AddDB("EarthPetEgg", 204482); --Green 6.4.1.2758
  db:priv_AddDB("EarthPetEgg", 204488); --Blue 6.4.1.2758
  db:priv_AddDB("EarthPetEgg", 204494); --Purple 6.4.1.2758
  db:priv_AddDB("EarthPetEgg", 204500); --orange 6.4.1.2758
end;

local function priv_AddWaterPetEggs(db) -- Wasser
  db:priv_AddDB("WaterPetEgg", 204477); --white 6.4.1.2758
  db:priv_AddDB("WaterPetEgg", 204483); --Green 6.4.1.2758
  db:priv_AddDB("WaterPetEgg", 204489); --Blue 6.4.1.2758
  db:priv_AddDB("WaterPetEgg", 204495); --Purple 6.4.1.2758
  db:priv_AddDB("WaterPetEgg", 204501); --orange 6.4.1.2758
end;

local function priv_AddFirePetEggs(db) -- Feuer
  db:priv_AddDB("FirePetEgg", 204478); --white 6.4.1.2758
  db:priv_AddDB("FirePetEgg", 204484); --Green 6.4.1.2758
  db:priv_AddDB("FirePetEgg", 204490); --Blue 6.4.1.2758
  db:priv_AddDB("FirePetEgg", 204496); --Purple 6.4.1.2758
  db:priv_AddDB("FirePetEgg", 204502); --orange 6.4.1.2758
end;

local function priv_AddWindPetEggs(db) -- Wind
  db:priv_AddDB("WindPetEgg", 204479); --white 6.4.1.2758
  db:priv_AddDB("WindPetEgg", 204485); --Green 6.4.1.2758
  db:priv_AddDB("WindPetEgg", 204491); --Blue 6.4.1.2758
  db:priv_AddDB("WindPetEgg", 204497); --Purple 6.4.1.2758
  db:priv_AddDB("WindPetEgg", 204503); --orange 6.4.1.2758
end;

local function priv_AddLightPetEggs(db) -- Licht
  db:priv_AddDB("LightPetEgg", 204480); --white 6.4.1.2758
  db:priv_AddDB("LightPetEgg", 204486); --green 6.4.1.2758
  db:priv_AddDB("LightPetEgg", 204492); --Blue 6.4.1.2758
  db:priv_AddDB("LightPetEgg", 204498); --Purple 6.4.1.2758
  db:priv_AddDB("LightPetEgg", 204504); --orange 6.4.1.2758
end;

local function priv_AddDarkPetEggs(db) -- Dunkelheit
  db:priv_AddDB("DarkPetEgg", 204481); --white 6.4.1.2758
  db:priv_AddDB("DarkPetEgg", 204487); --Green 6.4.1.2758
  db:priv_AddDB("DarkPetEgg", 204493); --Blue 6.4.1.2758
  db:priv_AddDB("DarkPetEgg", 204499); --Purple 6.4.1.2758
  db:priv_AddDB("DarkPetEgg", 204505); --orange 6.4.1.2758
end;

-- Cenedril --
local function priv_DynamicCenedril(db) -- Dynamischer Cenedril
  db:priv_AddDB("DynamicCenedril", 209873); -- white mirror fragment
  db:priv_AddDB("DynamicCenedril", 209876); -- white cenedril image piece
  db:priv_AddDB("DynamicCenedril", 209879); -- white mirror ink
  db:priv_AddDB("DynamicCenedril", 209882); -- white immage restoration scroll
  db:priv_AddDB("DynamicCenedril", 209885); -- Green mirror fragment
  db:priv_AddDB("DynamicCenedril", 209888); -- Green cenedril image piece
  db:priv_AddDB("DynamicCenedril", 209891); -- Green mirror ink
  db:priv_AddDB("DynamicCenedril", 209894); -- Green immage restoration scroll
  db:priv_AddDB("DynamicCenedril", 209897); -- Blue mirror fragment
  db:priv_AddDB("DynamicCenedril", 209900); -- Blue cenedril image piece
  db:priv_AddDB("DynamicCenedril", 209903); -- Blue mirror ink
  db:priv_AddDB("DynamicCenedril", 209906); -- Blue immage restoration scroll
  db:priv_AddDB("DynamicCenedril", 209909); -- Purple mirror fragment
  db:priv_AddDB("DynamicCenedril", 209912); -- Purple cenedril image piece
  db:priv_AddDB("DynamicCenedril", 209915); -- Purple mirror ink
  db:priv_AddDB("DynamicCenedril", 209918); -- Purple immage restoration scroll
  db:priv_AddDB("DynamicCenedril", 209921); -- Orange mirror fragment
  db:priv_AddDB("DynamicCenedril", 209924); -- Orange cenedril image piece
  db:priv_AddDB("DynamicCenedril", 209927); -- Orange mirror ink
  db:priv_AddDB("DynamicCenedril", 209930); -- Orange immage restoration scroll
  db:priv_AddDB("DynamicCenedril", 209933); -- Brown mirror fragment
  db:priv_AddDB("DynamicCenedril", 209936); -- Brown cenedril image piece
  db:priv_AddDB("DynamicCenedril", 209939); -- Brown mirror ink
  db:priv_AddDB("DynamicCenedril", 209942); -- Brown immage restoration scroll
end;

local function priv_MysticalCenedril(db) --  Mystischer Cenedril
  db:priv_AddDB("MysticalCenedril", 209875); -- white mirror fragment
  db:priv_AddDB("MysticalCenedril", 209878); -- white cenedril image piece
  db:priv_AddDB("MysticalCenedril", 209881); -- white mirror ink
  db:priv_AddDB("MysticalCenedril", 209884); -- white immage restoration scroll
  db:priv_AddDB("MysticalCenedril", 209887); -- Green mirror fragment
  db:priv_AddDB("MysticalCenedril", 209890); -- Green cenedril image piece
  db:priv_AddDB("MysticalCenedril", 209893); -- Green mirror ink
  db:priv_AddDB("MysticalCenedril", 209896); -- Green immage restoration scroll
  db:priv_AddDB("MysticalCenedril", 209899); -- Blue mirror fragment
  db:priv_AddDB("MysticalCenedril", 209902); -- Blue cenedril image piece
  db:priv_AddDB("MysticalCenedril", 209905); -- Blue mirror ink
  db:priv_AddDB("MysticalCenedril", 209908); -- Blue immage restoration scroll
  db:priv_AddDB("MysticalCenedril", 209911); -- Purple mirror fragment
  db:priv_AddDB("MysticalCenedril", 209914); -- Purple cenedril image piece
  db:priv_AddDB("MysticalCenedril", 209917); -- Purple mirror ink
  db:priv_AddDB("MysticalCenedril", 209920); -- Purple immage restoration scroll
  db:priv_AddDB("MysticalCenedril", 209923); -- Orange mirror fragment
  db:priv_AddDB("MysticalCenedril", 209926); -- Orange cenedril image piece
  db:priv_AddDB("MysticalCenedril", 209929); -- Orange mirror ink
  db:priv_AddDB("MysticalCenedril", 209932); -- Orange immage restoration scroll
  db:priv_AddDB("MysticalCenedril", 209935); -- Brown mirror fragment
  db:priv_AddDB("MysticalCenedril", 209938); -- Brown cenedril image piece
  db:priv_AddDB("MysticalCenedril", 209941); -- Brown mirror ink
  db:priv_AddDB("MysticalCenedril", 209944); -- Brown immage restoration scroll
end;

local function priv_SteadfastCenedril(db) -- Wehrhafter Cenedril
  db:priv_AddDB("SteadfastCenedril", 209874); -- white mirror fragment
  db:priv_AddDB("SteadfastCenedril", 209877); -- white cenedril image piece
  db:priv_AddDB("SteadfastCenedril", 209880); -- white mirror ink
  db:priv_AddDB("SteadfastCenedril", 209883); -- white immage restoration scroll
  db:priv_AddDB("SteadfastCenedril", 209886); -- Green mirror fragment
  db:priv_AddDB("SteadfastCenedril", 209889); -- Green cenedril image piece
  db:priv_AddDB("SteadfastCenedril", 209892); -- Green mirror ink
  db:priv_AddDB("SteadfastCenedril", 209895); -- Green immage restoration scroll
  db:priv_AddDB("SteadfastCenedril", 209898); -- Blue mirror fragment
  db:priv_AddDB("SteadfastCenedril", 209901); -- Blue cenedril image piece
  db:priv_AddDB("SteadfastCenedril", 209904); -- Blue mirror ink
  db:priv_AddDB("SteadfastCenedril", 209907); -- Blue immage restoration scroll
  db:priv_AddDB("SteadfastCenedril", 209910); -- Purple mirror fragment
  db:priv_AddDB("SteadfastCenedril", 209913); -- Purple cenedril image piece
  db:priv_AddDB("SteadfastCenedril", 209916); -- Purple mirror ink
  db:priv_AddDB("SteadfastCenedril", 209919); -- Purple immage restoration scroll
  db:priv_AddDB("SteadfastCenedril", 209922); -- Orange mirror fragment
  db:priv_AddDB("SteadfastCenedril", 209925); -- Orange cenedril image piece
  db:priv_AddDB("SteadfastCenedril", 209928); -- Orange mirror ink
  db:priv_AddDB("SteadfastCenedril", 209931); -- Orange immage restoration scroll
  db:priv_AddDB("SteadfastCenedril", 209934); -- Brown mirror fragment
  db:priv_AddDB("SteadfastCenedril", 209937); -- Brown cenedril image piece
  db:priv_AddDB("SteadfastCenedril", 209940); -- Brown mirror ink
  db:priv_AddDB("SteadfastCenedril", 209943); -- Brown immage restoration scroll
end;

-- Guild Contribution
local function priv_AddGuildContribution(db) -- 5.0.0.2545
  db:priv_AddDB("Guild", 202916); -- Guild Rune
  db:priv_AddDB("Guild", 202917); -- Guild Stone

  db:priv_AddDB("Guild", 203450); -- Ruby Stone
  
  db:priv_AddDB("Guild", 206590); -- Magic Fortune Grass - 100 Guild Herb
  db:priv_AddDB("Guild", 206591); -- Sunset Ear of Grain - 100 Guild Wood
  db:priv_AddDB("Guild", 206592); -- Moonlight Pearl - 100 Guild Ore
  db:priv_AddDB("Guild", 206593); --  
  
  db:priv_AddDB("Guild", 206695); -- Ore Essence
  db:priv_AddDB("Guild", 206696); -- Wood Essence
  db:priv_AddDB("Guild", 206697); -- Herb Essence
  
  --Andor Materials-- credit Ultak


  db:priv_AddDB("Guild", 207319); --
  db:priv_AddDB("Guild", 207320); --
  db:priv_AddDB("Guild", 207321); --
  db:priv_AddDB("Guild", 207322); --
  db:priv_AddDB("Guild", 207323); --
  db:priv_AddDB("Guild", 207324); --
  db:priv_AddDB("Guild", 207325); --
  db:priv_AddDB("Guild", 207326); -- Nightmare Essence - 100 Guild Runes
  db:priv_AddDB("Guild", 207327); --
  db:priv_AddDB("Guild", 207328); --
  db:priv_AddDB("Guild", 207329); -- Furchtloser Kern
  db:priv_AddDB("Guild", 207330); -- Wisdom Core - 100 Guild Stones
  db:priv_AddDB("Guild", 207331); --
  db:priv_AddDB("Guild", 207332); --

  db:priv_AddDB("Guild", 207930); -- Teardrop Ruby - 100 Guild Rubies

  
  
  
  
end;

--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


UMMItemDB = ResourceItemFilter;
UMMItemDB:Init();



priv_AddProductionRunes(UMMItemDB);	-- P. Runen

priv_AddRunes(UMMItemDB);	-- Runen

-- Accuracy
priv_AddFusionStones(UMMItemDB);	-- F. Steine
priv_AddManaStones(UMMItemDB);	-- Mana-Steine
priv_AddJuwels(UMMItemDB);
priv_AddGeneralMaterials(UMMItemDB);   -- Allgemeines Material
priv_AddRawMaterials(UMMItemDB);  -- RohMaterial, Verarbeitete Güter
priv_AddTQMaterials(UMMItemDB);  -- 




-- Supplies
priv_AddFoodsDesserts(UMMItemDB);   -- Essen
priv_AddPotions(UMMItemDB);   -- Tränke
priv_AddBagStats(UMMItemDB); -- Beutel Item
priv_AddT6clean(UMMItemDB);  -- T6 clean
priv_AddT698er(UMMItemDB);  -- T6 98er grün     clean oder Fähigkeiten
priv_AddT6(UMMItemDB);		-- T6
priv_AddRecipesAlchemist(UMMItemDB);   -- Rezepte Allchemist
priv_AddRecipesCook(UMMItemDB);   -- Rezepte Koch
priv_AddRecipesCutter(UMMItemDB);   -- Rezepte Schneider
priv_AddRecipesCarpenter(UMMItemDB);   -- Rezepte Schreiner
priv_AddRecipesArmorsmith(UMMItemDB);   -- Rezepte Rüstungsschmied
priv_AddRecipesWeaponsmith(UMMItemDB);   -- Rezepte Waffenschmied
priv_AddRecipesOther(UMMItemDB);   -- Rezepte M?bel, Schmuck, Allgemein

-- Materials
priv_AddOres(UMMItemDB);   -- Erz
priv_AddWood(UMMItemDB);   -- Holz
priv_AddHerbs(UMMItemDB);   -- Kraut
priv_AddCards(UMMItemDB);	-- Karte
priv_AddRunePetEggs(UMMItemDB); -- 6.4.1.2758
priv_AddEarthPetEggs(UMMItemDB); -- 6.4.1.2758
priv_AddWaterPetEggs(UMMItemDB); -- 6.4.1.2758
priv_AddFirePetEggs(UMMItemDB); -- 6.4.1.2758
priv_AddWindPetEggs(UMMItemDB); -- 6.4.1.2758
priv_AddLightPetEggs(UMMItemDB); -- 6.4.1.2758
priv_AddDarkPetEggs(UMMItemDB); -- 6.4.1.2758

-- Cenedril --
priv_DynamicCenedril(UMMItemDB); -- Dynamischer Cenedril
priv_MysticalCenedril(UMMItemDB); --  Mystischer Cenedril
priv_SteadfastCenedril(UMMItemDB); -- Wehrhafter Cenedril

-- Guild Contribution
priv_AddGuildContribution(UMMItemDB); -- 5.0.0.2545













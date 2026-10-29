function zBagConfig_Load()
			zBagRowSlider:SetValue(ZBAG_ROW_ITEMS);
			zBagScaleSlider:SetValue(ZBAG_SCALE);
			if (zBag_VAR["bag3"]==1) then
				zBagConfigFrameBagP3:SetChecked(true);
			else
				zBagConfigFrameBagP3:SetChecked(false);
			end
			if (zBag_VAR["bag4"]==1) then
				zBagConfigFrameBagP4:SetChecked(true);
			else
				zBagConfigFrameBagP4:SetChecked(false);
			end
			if (zBag_VAR["bag5"]==1) then
				zBagConfigFrameBagP5:SetChecked(true);
			else
				zBagConfigFrameBagP5:SetChecked(false);
			end
			if (zBag_VAR["bag6"]==1) then
				zBagConfigFrameBagP6:SetChecked(true);
			else
				zBagConfigFrameBagP6:SetChecked(false);
			end
			if (zBag_VAR["alwaysshow"]==1) then
				zBagConfigFramealwaysshow:SetChecked(true);
			else
				zBagConfigFramealwaysshow:SetChecked(false);
			end
			if (zBag_VAR["showeq"]==1) then
				zBagConfigFrameshoweq:SetChecked(true);
			else
				zBagConfigFrameshoweq:SetChecked(false);
			end
			if (zBag_VAR["showback"]==1) then
				zBagConfigFrameshowback:SetChecked(true);
			else
				zBagConfigFrameshowback:SetChecked(false);
			end
			if (zBag_VAR["highlighteven"]==1) then
				zBagConfigFramehighlighteven:SetChecked(true);
			else
				zBagConfigFramehighlighteven:SetChecked(false);
			end
			if (zBag_VAR["highlightitemquality"]==1) then
				zBagConfigFramehighlightitemquality:SetChecked(true);
			else
				zBagConfigFramehighlightitemquality:SetChecked(false);
			end			
			if (zBag_VAR["showitemshop"]==1) then
				zBagConfigFrameshowitemshop:SetChecked(true);
			else
				zBagConfigFrameshowitemshop:SetChecked(false);
			end
			zBagConfigTitleText:SetText(zBLocale.zBagConfigFrame.zBagConfigTitleText);
			zBagConfigFrameTxt1:SetText(zBLocale.zBagConfigFrame.zBagConfigFrameTxt1);
			zBagConfigFrameTxt2:SetText(zBLocale.zBagConfigFrame.zBagConfigFrameTxt2);
			zBagConfigFrameBagP3Txt1:SetText(zBLocale.zBagConfigFrame.Three);
			zBagConfigFrameBagP4Txt1:SetText(zBLocale.zBagConfigFrame.Four);
			zBagConfigFrameBagP5Txt1:SetText(zBLocale.zBagConfigFrame.Five);
			zBagConfigFrameBagP6Txt1:SetText(zBLocale.zBagConfigFrame.Six);
			zBagConfigFramealwaysshowTxt1:SetText(zBLocale.zBagConfigFrame.AlwaysShowContent);
			zBagConfigFrameshoweqTxt1:SetText(zBLocale.zBagConfigFrame.ShowEquipmentSlots);
			zBagConfigFrameshowbackTxt1:SetText(zBLocale.zBagConfigFrame.ShowBackground);
			zBagConfigFramehighlightevenTxt1:SetText(zBLocale.zBagConfigFrame.HighlightEvenTabs);
			zBagConfigFrameshowitemshopTxt1:SetText(zBLocale.zBagConfigFrame.ShowItemShopButtons);
			zBagRowSliderTxt1:SetText(zBLocale.zBagConfigFrame.NumberOfItemsOnARow);
			zBagRowSliderTxt2:SetText(zBLocale.zBagConfigFrame.Two);
			zBagRowSliderTxt3:SetText(zBLocale.zBagConfigFrame.Twenty);

			zBagScaleSliderTxt1:SetText(zBLocale.zBagConfigFrame.BagItemsScale);
			zBagScaleSliderTxt2:SetText(zBLocale.zBagConfigFrame.ZeroPointFive);
			zBagScaleSliderTxt3:SetText(zBLocale.zBagConfigFrame.OnePointFive);
			zBagConfigFrameBankP2Txt1:SetText(zBLocale.zBagConfigFrame.Two);
			zBagConfigFrameBankP3Txt1:SetText(zBLocale.zBagConfigFrame.Three);
			zBagConfigFrameBankP4Txt1:SetText(zBLocale.zBagConfigFrame.Four);
			zBagConfigFrameBankP5Txt1:SetText(zBLocale.zBagConfigFrame.Five);
			zBagConfigFrameBankP6Txt1:SetText(zBLocale.zBagConfigFrame.Six);
			
			zBagConfigFramebankshowbackTxt1:SetText(zBLocale.zBagConfigFrame.ShowBackground);
			zBagConfigFramebankhighlightevenTxt1:SetText(zBLocale.zBagConfigFrame.HighlightEvenTabs);
			zBagConfigFramebankhighlightinspectingTxt1:SetText(zBLocale.zBagConfigFrame.ShowPreviewHighlight);
			zBagConfigFramebankopenwithbagTxt1:SetText(zBLocale.zBagConfigFrame.OpenWithBackpack);
			zBagConfigFramehighlightitemqualityTxt1:SetText(zBLocale.zBagConfigFrame.HighlightItemQuality);
			zBagConfigFrameallowaltrightclickdeleteTxt1:SetText(zBLocale.zBagConfigFrame.AllowAltRightClickDelete);
			zBagConfigFrameusebagsearchTxt1:SetText(zBLocale.zBagConfigFrame.UseBagSearchAddon);			
			
			zBagBRowSliderTxt1:SetText(zBLocale.zBagConfigFrame.NumberOfItemsOnARow);
			zBagBRowSliderTxt2:SetText(zBLocale.zBagConfigFrame.Two);
			zBagBRowSliderTxt3:SetText(zBLocale.zBagConfigFrame.Twenty);
			
			zBagBScaleSliderTxt1:SetText(zBLocale.zBagConfigFrame.BankItemsScale);
			zBagBScaleSliderTxt2:SetText(zBLocale.zBagConfigFrame.ZeroPointFive);
			zBagBScaleSliderTxt3:SetText(zBLocale.zBagConfigFrame.OnePointFive);
			
end

function zBagConfig_Save()
			if (zBagConfigFrameBagP3:IsChecked()) then 
				zBag_VAR["bag3"]=1; 
			else 
				zBag_VAR["bag3"]=0; 
			end
			if (zBagConfigFrameBagP4:IsChecked()) then 
				zBag_VAR["bag4"]=1; 
			else 
				zBag_VAR["bag4"]=0; 
			end
			if (zBagConfigFrameBagP5:IsChecked()) then 
				zBag_VAR["bag5"]=1; 
			else 
				zBag_VAR["bag5"]=0; 
			end
			if (zBagConfigFrameBagP6:IsChecked()) then 
				zBag_VAR["bag6"]=1; 
			else 
				zBag_VAR["bag6"]=0; 
			end
			if (zBagConfigFramealwaysshow:IsChecked()) then 
				zBag_VAR["alwaysshow"]=1; 
			else 
				zBag_VAR["alwaysshow"]=0; 
			end
			if (zBagConfigFrameshoweq:IsChecked()) then 
				zBag_VAR["showeq"]=1; 
			else 
				zBag_VAR["showeq"]=0; 
			end
			if (zBagConfigFrameshowback:IsChecked()) then 
				zBag_VAR["showback"]=1; 
			else 
				zBag_VAR["showback"]=0; 
			end
			if (zBagConfigFramehighlighteven:IsChecked()) then 
				zBag_VAR["highlighteven"]=1; 
			else 
				zBag_VAR["highlighteven"]=0; 
			end
			if (zBagConfigFramehighlightitemquality:IsChecked()) then 
				zBag_VAR["highlightitemquality"]=1; 
			else 
				zBag_VAR["highlightitemquality"]=0; 
			end
			if (zBagConfigFrameshowitemshop:IsChecked()) then 
				zBag_VAR["showitemshop"]=1; 
			else 
				zBag_VAR["showitemshop"]=0; 
			end
			zBag_SetItemShop();
			zBagB_SetItemShop();
			ZBAG_SHOWEQ=zBag_VAR["showeq"];
			ZBAG_ROW_ITEMS=zBagRowSlider:GetValue();
			zBag_VAR["rowitems"]=ZBAG_ROW_ITEMS;
			ZBAG_SCALE=zBagScaleSlider:GetValue();
			zBag_VAR["scale"]=ZBAG_SCALE;
			local x,y = zBag:GetPos();
			zBag_VAR["x"] = x;
			zBag_VAR["y"] = y;
			x,y = zBagBBackground:GetPos();
			zBag_VAR["bankx"] = x;
			zBag_VAR["banky"] = y;
			zBagKit.SaveSettings();
			zBag_Resize(this);
			zBag_Update();
end

function zBankConfig_Load()
			if (zBag_VAR["bank2"]==1) then
				zBagConfigFrameBankP2:SetChecked(true);
			else
				zBagConfigFrameBankP2:SetChecked(false);
			end
			if (zBag_VAR["bank3"]==1) then
				zBagConfigFrameBankP3:SetChecked(true);
			else
				zBagConfigFrameBankP3:SetChecked(false);
			end
			if (zBag_VAR["bank4"]==1) then
				zBagConfigFrameBankP4:SetChecked(true);
			else
				zBagConfigFrameBankP4:SetChecked(false);
			end
			if (zBag_VAR["bank5"]==1) then
				zBagConfigFrameBankP5:SetChecked(true);
			else
				zBagConfigFrameBankP5:SetChecked(false);
			end
			if (zBag_VAR["bank6"]==1) then
				zBagConfigFrameBankP6:SetChecked(true);
			else
				zBagConfigFrameBankP6:SetChecked(false);
			end			
			if (zBag_VAR["bankshowback"]==1) then
				zBagConfigFramebankshowback:SetChecked(true);
			else
				zBagConfigFramebankshowback:SetChecked(false);
			end
			if (zBag_VAR["bankhighlighteven"]==1) then
				zBagConfigFramebankhighlighteven:SetChecked(true);
			else
				zBagConfigFramebankhighlighteven:SetChecked(false);
			end
			if (zBag_VAR["bankhighlightinspecting"]==1) then
				zBagConfigFramebankhighlightinspecting:SetChecked(true);
			else
				zBagConfigFramebankhighlightinspecting:SetChecked(false);
			end
			if (zBag_VAR["bankopenwithbag"]==1) then
				zBagConfigFramebankopenwithbag:SetChecked(true);
			else
				zBagConfigFramebankopenwithbag:SetChecked(false);
			end
			if (zBag_VAR["allowaltrightclickdelete"]==1) then
				zBagConfigFrameallowaltrightclickdelete:SetChecked(true);
			else
				zBagConfigFrameallowaltrightclickdelete:SetChecked(false);
			end
			if (zBag_VAR["usebagsearch"]==1) then
				zBagConfigFrameusebagsearch:SetChecked(true);
			else
				zBagConfigFrameusebagsearch:SetChecked(false);
			end			
end

function zBankConfig_Save()
			if (zBagConfigFrameBankP2:IsChecked()) then 
				zBag_VAR["bank2"]=1; 
			else 
				zBag_VAR["bank2"]=0; 
			end
			if (zBagConfigFrameBankP3:IsChecked()) then 
				zBag_VAR["bank3"]=1; 
			else 
				zBag_VAR["bank3"]=0; 
			end
			if (zBagConfigFrameBankP4:IsChecked()) then 
				zBag_VAR["bank4"]=1; 
			else 
				zBag_VAR["bank4"]=0; 
			end
			if (zBagConfigFrameBankP5:IsChecked()) then 
				zBag_VAR["bank5"]=1; 
			else 
				zBag_VAR["bank5"]=0; 
			end
			if (zBagConfigFrameBankP6:IsChecked()) then 
				zBag_VAR["bank6"]=1; 
			else 
				zBag_VAR["bank6"]=0; 
			end			
			if (zBagConfigFramebankshowback:IsChecked()) then 
				zBag_VAR["bankshowback"]=1; 
			else 
				zBag_VAR["bankshowback"]=0; 
			end
			if (zBagConfigFramebankhighlighteven:IsChecked()) then 
				zBag_VAR["bankhighlighteven"]=1; 
			else 
				zBag_VAR["bankhighlighteven"]=0; 
			end
			if (zBagConfigFramebankhighlightinspecting:IsChecked()) then
				zBag_VAR["bankhighlightinspecting"]=1; 
			else 
				zBag_VAR["bankhighlightinspecting"]=0; 
			end
			if (zBagConfigFramebankopenwithbag:IsChecked()) then 
				zBag_VAR["bankopenwithbag"]=1; 
			else 
				zBag_VAR["bankopenwithbag"]=0; 
			end
			if (zBagConfigFrameallowaltrightclickdelete:IsChecked()) then 
				zBag_VAR["allowaltrightclickdelete"]=1; 
			else 
				zBag_VAR["allowaltrightclickdelete"]=0; 
			end
			if (zBagConfigFrameusebagsearch:IsChecked()) then 
				zBag_VAR["usebagsearch"]=1; 
			else 
				zBag_VAR["usebagsearch"]=0; 
			end
			zBagKit.PlaceSearchBoxes();
			local x,y = zBagBBackground:GetPos();
			zBag_VAR["bankx"] = x;
			zBag_VAR["banky"] = y;
			zBagKit.SaveSettings();
			zBagB_Resize(this);
			zBagB_Update();
end


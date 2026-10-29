zBagDeveloperConfigVariablesLoaded = 0;
function zBagDeveloperConfig_Load()
			--yecho("in dcl");
			if (zBag_VAR["displayWackyBagIndex"]==1) then
				zBagDeveloperConfigFrameDisplayWackyBagIndex:SetChecked(true);
			else 
				zBagDeveloperConfigFrameDisplayWackyBagIndex:SetChecked(false);
			end	
			if (zBag_VAR["displayDebugMessages"]==1) then
				zBagDeveloperConfigFrameDisplayDebugMessages:SetChecked(true);
			else 
				zBagDeveloperConfigFrameDisplayDebugMessages:SetChecked(false);
			end		
			zBagDeveloperConfigVariablesLoaded = 1;
end

function zBagDeveloperConfig_Save()
			if (zBagDeveloperConfigVariablesLoaded == 1) then
				--yecho("in dcs");	
				if (zBagDeveloperConfigFrameDisplayWackyBagIndex:IsChecked()) then 
					zBag_VAR["displayWackyBagIndex"]=1; 
					--yecho("zbV1dwbi" .. zBag_VAR["displayWackyBagIndex"]);
				else 
					zBag_VAR["displayWackyBagIndex"]=0; 
					--yecho("zbV2dwbi" .. zBag_VAR["displayWackyBagIndex"]);
				end
				if (zBagDeveloperConfigFrameDisplayDebugMessages:IsChecked()) then 
					zBag_VAR["displayDebugMessages"]=1; 
					--yecho("zbV1dwbi" .. zBag_VAR["displayWackyBagIndex"]);
				else 
					zBag_VAR["displayDebugMessages"]=0; 
					--yecho("zbV2dwbi" .. zBag_VAR["displayWackyBagIndex"]);
				end				
				zBagKit.SaveSettings();
				zBag_Update();
			end
end
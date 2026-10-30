LSF_PageTab = {};

function LSF_Tab_OnClick(this)
	LSF_PageTab[LoginSettingsFrame.oldPage]:Hide();
	LSF_PageTab[this:GetID()]:Show();
	getglobal( this:GetParent():GetName() .. "Pagebut" .. LoginSettingsFrame.oldPage ):UnlockHighlight();
	this:LockHighlight();
	LoginSettingsFrame.oldPage = this:GetID();
end

function LSF_ValueSlider_OnValueChanged(this)
	if ( this.OnValueChanged ) then
		this:OnValueChanged();
	end

	local value = this:GetValue();
	if ( this:GetValueStepMode() == "FLOAT" ) then
		value = string.format("%.2f", value);
	end
	getglobal(this:GetName().."Value"):SetText(value);
end

function LSF_ResolutionDropDown_OnLoad(this)
	LoginDropDownList_SetWidth(this, 120);
	LoginDropDownList_Initialize(this, LSF_ResolutionDropDown_Show);
	LoginDropDownList_SetSelectedID(this, 1);
end

function LSF_ResolutionDropDown_Show()
	local info;

	local displayModeCount = SYS_DispSet_GetNumDispModes();
	for i = 1, displayModeCount, 1 do
		local width = SYS_DispSet_GetDispWidth(i - 1);
		local height = SYS_DispSet_GetDispHeight(i - 1);

		info = {};
		info.text = width.."x"..height;
		info.func = LSF_ResolutionDropDown_Click;
		LoginDropDownList_AddButton(info);
	end
end

function LSF_ResolutionDropDown_Click(button)
	LoginDropDownList_SetSelectedID(LSF_ResolutionDropDown, button:GetID());
	SYS_DispSet_SetResolutionNeedChange(true);
end

function LSF_WorstRadioButton_OnClick(this)
	local DisplayGroup = this:GetParent();
	local LeftGroup = getglobal( DisplayGroup:GetName() .. "LeftGroup" );

	getglobal( LeftGroup:GetName() .. "RTLightMapCheckBox" ):SetChecked(false);
	getglobal( LeftGroup:GetName() .. "TerrainShaderDetailSlider" ):SetValue(0);
	getglobal( LeftGroup:GetName() .. "LightMapResSlider" ):SetValue(0);
	getglobal( LeftGroup:GetName() .. "ShadowDetailSlider" ):SetValue(0);

	getglobal( LeftGroup:GetName() .. "WaterReflectionCheckButton" ):SetChecked(false);
	getglobal( LeftGroup:GetName() .. "WaterRefractionCheckButton" ):SetChecked(false);
	getglobal( LeftGroup:GetName() .. "WaterQualitySlider" ):SetValue(1);

	getglobal( LeftGroup:GetName() .. "BloomCheckButton" ):SetChecked(false);
	getglobal( LeftGroup:GetName() .. "GlowCheckButton" ):SetChecked(false);
	getglobal( LeftGroup:GetName() .. "BloomQualitySlider" ):SetValue(1);

	local RightGroup = getglobal( DisplayGroup:GetName() .. "RightGroup" );

	getglobal( RightGroup:GetName() .. "PaperdollDetailSlider" ):SetValue(1);
	getglobal( RightGroup:GetName() .. "ViewDistanceSlider" ):SetValue(600);
	getglobal( RightGroup:GetName() .. "WorldDetailSlider" ):SetValue(0);
	getglobal( RightGroup:GetName() .. "SkyDetailSlider" ):SetValue(0);
	getglobal( RightGroup:GetName() .. "TextureDetailSlider" ):SetValue(0);
	getglobal( RightGroup:GetName() .. "TerrainTextureDetailSlider" ):SetValue(0);

	getglobal( RightGroup:GetName() .. "SpecularHighlightCheckButton" ):SetChecked(false);
	getglobal( RightGroup:GetName() .. "DistortFXCheckButton" ):SetChecked(false);
	getglobal( RightGroup:GetName() .. "DebaseTextureCheckButton" ):SetChecked(true);
	getglobal( RightGroup:GetName() .. "SmoothBlendCheckButton" ):SetChecked(false);

	LSF_Display_WorstRadioButton:SetChecked(true);
end

function LSF_GeneralRadioButton_OnClick(this)
	local DisplayGroup = this:GetParent();
	local LeftGroup = getglobal( DisplayGroup:GetName() .. "LeftGroup" );

	getglobal( LeftGroup:GetName() .. "RTLightMapCheckBox" ):SetChecked(false);
	getglobal( LeftGroup:GetName() .. "TerrainShaderDetailSlider" ):SetValue(2);
	getglobal( LeftGroup:GetName() .. "LightMapResSlider" ):SetValue(1);
	getglobal( LeftGroup:GetName() .. "ShadowDetailSlider" ):SetValue(3);

	getglobal( LeftGroup:GetName() .. "WaterReflectionCheckButton" ):SetChecked(true);
	getglobal( LeftGroup:GetName() .. "WaterRefractionCheckButton" ):SetChecked(true);
	getglobal( LeftGroup:GetName() .. "WaterQualitySlider" ):SetValue(2);

	getglobal( LeftGroup:GetName() .. "BloomCheckButton" ):SetChecked(true);
	getglobal( LeftGroup:GetName() .. "GlowCheckButton" ):SetChecked(false);
	getglobal( LeftGroup:GetName() .. "BloomQualitySlider" ):SetValue(2);

	local RightGroup = getglobal( DisplayGroup:GetName() .. "RightGroup" );

	getglobal( RightGroup:GetName() .. "PaperdollDetailSlider" ):SetValue(4);
	getglobal( RightGroup:GetName() .. "ViewDistanceSlider" ):SetValue(2000);
	getglobal( RightGroup:GetName() .. "WorldDetailSlider" ):SetValue(3);
	getglobal( RightGroup:GetName() .. "SkyDetailSlider" ):SetValue(1);
	getglobal( RightGroup:GetName() .. "TextureDetailSlider" ):SetValue(4);
	getglobal( RightGroup:GetName() .. "TerrainTextureDetailSlider" ):SetValue(3);

	getglobal( RightGroup:GetName() .. "SpecularHighlightCheckButton" ):SetChecked(false);
	getglobal( RightGroup:GetName() .. "DistortFXCheckButton" ):SetChecked(true);
	getglobal( RightGroup:GetName() .. "DebaseTextureCheckButton" ):SetChecked(false);
	getglobal( RightGroup:GetName() .. "SmoothBlendCheckButton" ):SetChecked(false);

	LSF_Display_GeneralRadioButton:SetChecked(true);
end

function LSF_BestRadioButton_OnClick(this)
	local DisplayGroup = this:GetParent();
	local LeftGroup = getglobal( DisplayGroup:GetName() .. "LeftGroup" );

	getglobal( LeftGroup:GetName() .. "RTLightMapCheckBox" ):SetChecked(true);
	getglobal( LeftGroup:GetName() .. "TerrainShaderDetailSlider" ):SetValue(2);
	getglobal( LeftGroup:GetName() .. "LightMapResSlider" ):SetValue(1);
	getglobal( LeftGroup:GetName() .. "ShadowDetailSlider" ):SetValue(3);

	getglobal( LeftGroup:GetName() .. "WaterReflectionCheckButton" ):SetChecked(true);
	getglobal( LeftGroup:GetName() .. "WaterRefractionCheckButton" ):SetChecked(true);
	getglobal( LeftGroup:GetName() .. "WaterQualitySlider" ):SetValue(3);

	getglobal( LeftGroup:GetName() .. "BloomCheckButton" ):SetChecked(true);
	getglobal( LeftGroup:GetName() .. "GlowCheckButton" ):SetChecked(true);
	getglobal( LeftGroup:GetName() .. "BloomQualitySlider" ):SetValue(3);

	local RightGroup = getglobal( DisplayGroup:GetName() .. "RightGroup" );

	getglobal( RightGroup:GetName() .. "PaperdollDetailSlider" ):SetValue(6);
	getglobal( RightGroup:GetName() .. "ViewDistanceSlider" ):SetValue(3500);
	getglobal( RightGroup:GetName() .. "WorldDetailSlider" ):SetValue(3);
	getglobal( RightGroup:GetName() .. "SkyDetailSlider" ):SetValue(1);
	getglobal( RightGroup:GetName() .. "TextureDetailSlider" ):SetValue(4);
	getglobal( RightGroup:GetName() .. "TerrainTextureDetailSlider" ):SetValue(3);

	getglobal( RightGroup:GetName() .. "SpecularHighlightCheckButton" ):SetChecked(true);
	getglobal( RightGroup:GetName() .. "DistortFXCheckButton" ):SetChecked(true);
	getglobal( RightGroup:GetName() .. "DebaseTextureCheckButton" ):SetChecked(false);
	getglobal( RightGroup:GetName() .. "SmoothBlendCheckButton" ):SetChecked(true);

	LSF_Display_BestRadioButton:SetChecked(true);
end

function LSF_UIScaleSliderUpdate()
	if ( LSF_DisplayGroupLeftGroupUIScaleCheckButton:IsChecked() ) then
		LSF_DisplayGroupLeftGroupUIScaleSlider:Enable();
		LSF_DisplayGroupLeftGroupUIScaleSliderNormalLeft:Show();
		LSF_DisplayGroupLeftGroupUIScaleSliderNormalRight:Show();
		LSF_DisplayGroupLeftGroupUIScaleSliderNormalMiddle:Show();
		LSF_DisplayGroupLeftGroupUIScaleSliderDisableLeft:Hide();
		LSF_DisplayGroupLeftGroupUIScaleSliderDisableRight:Hide();
		LSF_DisplayGroupLeftGroupUIScaleSliderDisableMiddle:Hide();
		LSF_DisplayGroupLeftGroupUIScaleSliderThumb:SetFile( "Interface\\ChatFrame\\ChatFrame-ScrollBar-Knob" );
	else
		LSF_DisplayGroupLeftGroupUIScaleSlider:Disable();
		LSF_DisplayGroupLeftGroupUIScaleSliderNormalLeft:Hide();
		LSF_DisplayGroupLeftGroupUIScaleSliderNormalRight:Hide();
		LSF_DisplayGroupLeftGroupUIScaleSliderNormalMiddle:Hide();
		LSF_DisplayGroupLeftGroupUIScaleSliderDisableLeft:Show();
		LSF_DisplayGroupLeftGroupUIScaleSliderDisableRight:Show();
		LSF_DisplayGroupLeftGroupUIScaleSliderDisableMiddle:Show();
		LSF_DisplayGroupLeftGroupUIScaleSliderThumb:SetFile( "Interface\\ChatFrame\\ChatFrame-ScrollBar-Disable-Knob" );
	end
end

-----------------------------------------------------------------------
function LSF_DisplaySettings_Initialize()
	LSF_PageTab[1] = LSF_DisplaySettingsFrame;

	LSF_Display_GeneralRadioButton:SetChecked(true);

	------------------------------ LeftGroupBox
	LSF_UIScaleSliderUpdate();
	LSF_DisplayGroupLeftGroupUIScaleCheckButtonDesc:SetText(OPTUI_DISP_USE_UI_SCALE);

	LSF_DisplayGroupLeftGroupUIScaleSliderDesc:SetText(OPTUI_DISP_UI_SCALE);
	LSF_DisplayGroupLeftGroupUIScaleSliderLow:SetText(0.5);
	LSF_DisplayGroupLeftGroupUIScaleSliderHigh:SetText(1);
	LSF_DisplayGroupLeftGroupUIScaleSlider:SetValueStepMode("FLOAT");
	LSF_DisplayGroupLeftGroupUIScaleSlider:SetMinMaxValues(0.5, 1);
	LSF_DisplayGroupLeftGroupUIScaleSlider:SetValue(1.0);
	LSF_DisplayGroupLeftGroupUIScaleSlider:Disable();

	LSF_DisplayGroupLeftGroupRTLightMapCheckBoxDesc:SetText(OPTUI_DISP_ENABLE_RTLIGHTMAP);

	LSF_DisplayGroupLeftGroupTerrainShaderDetailSliderDesc:SetText(OPTUI_DISP_TERRAIN_SHADER);
	LSF_DisplayGroupLeftGroupTerrainShaderDetailSlider:SetValueStepMode("INT");
	LSF_DisplayGroupLeftGroupTerrainShaderDetailSlider:SetMinMaxValues(0, 2);
	LSF_DisplayGroupLeftGroupTerrainShaderDetailSlider:SetValue(2);

	LSF_DisplayGroupLeftGroupLightMapResSliderDesc:SetText(OPTUI_DISP_RTLIGHTMAP_RES);
	LSF_DisplayGroupLeftGroupLightMapResSlider:SetValueStepMode("INT");
	LSF_DisplayGroupLeftGroupLightMapResSlider:SetMinMaxValues(0, 1);
	LSF_DisplayGroupLeftGroupLightMapResSlider:SetValue(1);

	LSF_DisplayGroupLeftGroupShadowDetailSliderDesc:SetText(OPTUI_DISP_SHADOW_DETAIL);
	LSF_DisplayGroupLeftGroupShadowDetailSlider:SetValueStepMode("INT");
	LSF_DisplayGroupLeftGroupShadowDetailSlider:SetMinMaxValues(0, 3);
	LSF_DisplayGroupLeftGroupShadowDetailSlider:SetValue(3);

	LSF_DisplayGroupLeftGroupWaterReflectionCheckButton:SetChecked(true);
	LSF_DisplayGroupLeftGroupWaterReflectionCheckButtonDesc:SetText(OPTUI_DISP_WATER_REFLECTIONS);

	LSF_DisplayGroupLeftGroupWaterRefractionCheckButton:SetChecked(true);
	LSF_DisplayGroupLeftGroupWaterRefractionCheckButtonDesc:SetText(OPTUI_DISP_WATER_REFRACTIONS);

	LSF_DisplayGroupLeftGroupWaterQualitySliderDesc:SetText(OPTUI_DISP_WATER_EFFECTS_QUALITY);
	LSF_DisplayGroupLeftGroupWaterQualitySlider:SetValueStepMode("INT");
	LSF_DisplayGroupLeftGroupWaterQualitySlider:SetMinMaxValues(1, 3);
	LSF_DisplayGroupLeftGroupWaterQualitySlider:SetValue(2);	

	LSF_DisplayGroupLeftGroupBloomCheckButton:SetChecked(true);
	LSF_DisplayGroupLeftGroupBloomCheckButtonDesc:SetText(OPTUI_DISP_FULL_SCREEN_BLOOM);

	LSF_DisplayGroupLeftGroupGlowCheckButtonDesc:SetText(OPTUI_DISP_GLOW_EFFECT);

	LSF_DisplayGroupLeftGroupBloomQualitySliderDesc:SetText(OPTUI_DISP_BLOOM_EFFECTS_QUALITY);
	LSF_DisplayGroupLeftGroupBloomQualitySlider:SetValueStepMode("INT");
	LSF_DisplayGroupLeftGroupBloomQualitySlider:SetMinMaxValues(1, 3);
	LSF_DisplayGroupLeftGroupBloomQualitySlider:SetValue(2);

	------------------------------ RightGroupBox
	LSF_DisplayGroupRightGroupPaperdollDetailSliderTooltipDesc:SetText(OPTUI_DISP_PAPERDOLL_DETAIL);
	LSF_DisplayGroupRightGroupPaperdollDetailSlider:SetValueStepMode("INT");
	LSF_DisplayGroupRightGroupPaperdollDetailSlider:SetMinMaxValues(1, 6);
	LSF_DisplayGroupRightGroupPaperdollDetailSlider:SetValue(4);

	LSF_DisplayGroupRightGroupViewDistanceSliderDesc:SetText(OPTUI_DISP_VIEW_DISTANCE);
	LSF_DisplayGroupRightGroupViewDistanceSliderLow:SetText(OPTUI_COM_NEAR);
	LSF_DisplayGroupRightGroupViewDistanceSliderHigh:SetText(OPTUI_COM_FAR);
	LSF_DisplayGroupRightGroupViewDistanceSlider:SetValueStepMode("FLOAT");
	LSF_DisplayGroupRightGroupViewDistanceSlider:SetMinMaxValues(400, 3500);
	LSF_DisplayGroupRightGroupViewDistanceSlider:SetValue(2000);

	LSF_DisplayGroupRightGroupWorldDetailSliderDesc:SetText(OPTUI_DISP_WORLD_DETAIL);
	LSF_DisplayGroupRightGroupWorldDetailSlider:SetValueStepMode("INT");
	LSF_DisplayGroupRightGroupWorldDetailSlider:SetMinMaxValues(0, 3);
	LSF_DisplayGroupRightGroupWorldDetailSlider:SetValue(3);

	LSF_DisplayGroupRightGroupSkyDetailSliderDesc:SetText(OPTUI_DISP_SKY_DETAIL);
	LSF_DisplayGroupRightGroupSkyDetailSlider:SetValueStepMode("INT");
	LSF_DisplayGroupRightGroupSkyDetailSlider:SetMinMaxValues(0, 1);
	LSF_DisplayGroupRightGroupSkyDetailSlider:SetValue(1);

	LSF_DisplayGroupRightGroupTextureDetailSliderTooltipDesc:SetText(OPTUI_DISP_TEXTURE_DETAIL);
	LSF_DisplayGroupRightGroupTextureDetailSlider:SetValueStepMode("INT");
	LSF_DisplayGroupRightGroupTextureDetailSlider:SetMinMaxValues(0, 4);
	LSF_DisplayGroupRightGroupTextureDetailSlider:SetValue(4);

	LSF_DisplayGroupRightGroupTerrainTextureDetailSliderDesc:SetText(OPTUI_DISP_TERRAIN_TEXTURE);
	LSF_DisplayGroupRightGroupTerrainTextureDetailSlider:SetValueStepMode("INT");
	LSF_DisplayGroupRightGroupTerrainTextureDetailSlider:SetMinMaxValues(0, 3);
	LSF_DisplayGroupRightGroupTerrainTextureDetailSlider:SetValue(3);

	LSF_DisplayGroupRightGroupSpecularHighlightCheckButtonDesc:SetText(OPTUI_DISP_SPECULAR_HIGHLIGHT);

	LSF_DisplayGroupRightGroupDistortFXCheckButton:SetChecked(true);
	LSF_DisplayGroupRightGroupDistortFXCheckButtonDesc:SetText(OPTUI_DISP_DISTORT_FX);

	LSF_DisplayGroupRightGroupDebaseTextureCheckButton:SetChecked(false);
	LSF_DisplayGroupRightGroupDebaseTextureCheckButtonDesc:SetText(OPTUI_DISP_DEBASE_TEXTURE);

	LSF_DisplayGroupRightGroupSmoothBlendCheckButtonDesc:SetText(OPTUI_DISP_SMOOTH_BLENDING);
end
-----------------------------------------------------------------------

-----------------------------------------------------------------------
function LSF_AudioSettings_Initialize()
	LSF_PageTab[2] = LSF_AudioSettingsFrame;

	------------------------------ VolumeGroupBox
	LSF_VolumeGroupMasterVolumeSliderDesc:SetText(OPTUI_AUDIO_MASTER);
	LSF_VolumeGroupMasterVolumeSliderLow:SetText(0);
	LSF_VolumeGroupMasterVolumeSliderHigh:SetText(100);
	LSF_VolumeGroupMasterVolumeSlider:SetValueStepMode("INT");
	LSF_VolumeGroupMasterVolumeSlider:SetMinMaxValues(0, 100);
	LSF_VolumeGroupMasterVolumeSlider:SetValue(100);

	LSF_VolumeGroupMusicVolumeSliderDesc:SetText(OPTUI_AUDIO_MUSIC);
    LSF_VolumeGroupMusicVolumeSliderLow:SetText(0);
    LSF_VolumeGroupMusicVolumeSliderHigh:SetText(100);
	LSF_VolumeGroupMusicVolumeSlider:SetValueStepMode("INT");
	LSF_VolumeGroupMusicVolumeSlider:SetMinMaxValues(0, 100);
	LSF_VolumeGroupMusicVolumeSlider:SetValue(50);

	LSF_VolumeGroupAmbienceVolumeSliderDesc:SetText(OPTUI_AUDIO_AMBIENCE);
	LSF_VolumeGroupAmbienceVolumeSliderLow:SetText(0);
	LSF_VolumeGroupAmbienceVolumeSliderHigh:SetText(100);
	LSF_VolumeGroupAmbienceVolumeSlider:SetValueStepMode("INT");
	LSF_VolumeGroupAmbienceVolumeSlider:SetMinMaxValues(0, 100);
	LSF_VolumeGroupAmbienceVolumeSlider:SetValue(50);

	LSF_VolumeGroupSoundFXVolumeSliderDesc:SetText(OPTUI_AUDIO_SOUND_FX);
	LSF_VolumeGroupSoundFXVolumeSliderLow:SetText(0);
	LSF_VolumeGroupSoundFXVolumeSliderHigh:SetText(100);
	LSF_VolumeGroupSoundFXVolumeSlider:SetValueStepMode("INT");
	LSF_VolumeGroupSoundFXVolumeSlider:SetMinMaxValues(0, 100);
	LSF_VolumeGroupSoundFXVolumeSlider:SetValue(100);

	LSF_VolumeGroupInterfaceSFXVolumeSliderDesc:SetText(OPTUI_AUDIO_INTERFACE_SFX);
	LSF_VolumeGroupInterfaceSFXVolumeSliderLow:SetText(0);
	LSF_VolumeGroupInterfaceSFXVolumeSliderHigh:SetText(100);
	LSF_VolumeGroupInterfaceSFXVolumeSlider:SetValueStepMode("INT");
	LSF_VolumeGroupInterfaceSFXVolumeSlider:SetMinMaxValues(0, 100);
	LSF_VolumeGroupInterfaceSFXVolumeSlider:SetValue(100);

	------------------------------ OptionsGroupBox
	LSF_OptionsGroupMusicFrequencySliderDesc:SetText(OPTUI_AUDIO_MUSICFREQ);
	LSF_OptionsGroupMusicFrequencySlider:SetValueStepMode("FLOAT");
	LSF_OptionsGroupMusicFrequencySlider:SetMinMaxValues(1.0, 100.0);
	LSF_OptionsGroupMusicFrequencySlider:SetValue(50.0);
end
-----------------------------------------------------------------------

function LSF_OnLoad(this)
	LoginSettingsFrame.oldPage=1;
	
	LSF_DisplaySettings_Initialize();
	LSF_AudioSettings_Initialize();
end

function LSF_DisplaySettings_OnApply()
	UIScaleCheckButton_SetChecked( LSF_DisplayGroupLeftGroupUIScaleCheckButton:IsChecked() );
	UIScaleSlider_SetValue( LSF_DisplayGroupLeftGroupUIScaleSlider:GetValue() );

	RTLightMapCheckBox_SetChecked( LSF_DisplayGroupLeftGroupRTLightMapCheckBox:IsChecked() );
	TerrainShaderDetailSlider_SetValue( LSF_DisplayGroupLeftGroupTerrainShaderDetailSlider:GetValue() );
	LightMapResSlider_SetValue( LSF_DisplayGroupLeftGroupLightMapResSlider:GetValue() );
	ShadowDetailSlider_SetValue( LSF_DisplayGroupLeftGroupShadowDetailSlider:GetValue() );

	WaterReflectionCheckButton_SetChecked( LSF_DisplayGroupLeftGroupWaterReflectionCheckButton:IsChecked() );
	WaterRefractionCheckButton_SetChecked( LSF_DisplayGroupLeftGroupWaterRefractionCheckButton:IsChecked() );
	WaterQualitySlider_SetValue( LSF_DisplayGroupLeftGroupWaterQualitySlider:GetValue() );	

	BloomCheckButton_SetChecked( LSF_DisplayGroupLeftGroupBloomCheckButton:IsChecked() );
	GlowCheckButton_SetChecked( LSF_DisplayGroupLeftGroupGlowCheckButton:IsChecked() );
	BloomQualitySlider_SetValue( LSF_DisplayGroupLeftGroupBloomQualitySlider:GetValue() );

	PaperdollDetailSlider_SetValue( LSF_DisplayGroupRightGroupPaperdollDetailSlider:GetValue() );
	ViewDistanceSlider_SetValue( LSF_DisplayGroupRightGroupViewDistanceSlider:GetValue() );
	WorldDetailSlider_SetValue( LSF_DisplayGroupRightGroupWorldDetailSlider:GetValue() );
	SkyDetailSlider_SetValue( LSF_DisplayGroupRightGroupSkyDetailSlider:GetValue() );
	TextureDetailSlider_SetValue( LSF_DisplayGroupRightGroupTextureDetailSlider:GetValue() );
	TerrainTextureDetailSlider_SetValue( LSF_DisplayGroupRightGroupTerrainTextureDetailSlider:GetValue() );

	SpecularHighlightCheckButton_SetChecked( LSF_DisplayGroupRightGroupSpecularHighlightCheckButton:IsChecked() );
	DistortFXCheckButton_SetChecked( LSF_DisplayGroupRightGroupDistortFXCheckButton:IsChecked() );
	DebaseTextureCheckButton_SetChecked( LSF_DisplayGroupRightGroupDebaseTextureCheckButton:IsChecked() );
	SmoothBlendCheckButton_SetChecked( LSF_DisplayGroupRightGroupSmoothBlendCheckButton:IsChecked() );

	local quality = 0;

	if ( LSF_Display_WorstRadioButton:IsChecked() ) then
		quality = 1;
	elseif ( LSF_Display_GeneralRadioButton:IsChecked() ) then
		quality = 2;
	elseif ( LSF_Display_BestRadioButton:IsChecked() ) then
		quality = 3;
	end

	SetDisplayQuality( quality );
end

function LSF_AudioSettings_OnApply()
	MasterVolumeSlider_SetValue( LSF_VolumeGroupMasterVolumeSlider:GetValue() );
	MusicVolumeSlider_SetValue( LSF_VolumeGroupMusicVolumeSlider:GetValue() );
	AmbienceVolumeSlider_SetValue( LSF_VolumeGroupAmbienceVolumeSlider:GetValue() );
	SoundFXVolumeSlider_SetValue( LSF_VolumeGroupSoundFXVolumeSlider:GetValue() );
	InterfaceSFXVolumeSlider_SetValue( LSF_VolumeGroupInterfaceSFXVolumeSlider:GetValue() );
	MusicFrequencySlider_SetValue( LSF_OptionsGroupMusicFrequencySlider:GetValue() );
end

function LSF_OnShow()
	LSF_Tab_OnClick(LoginSettingsFramePagebut1);

	if ( IsFullscreen() ) then
		LSF_FullScreenRadioButton:SetChecked(true);
	else
		LSF_WindowModeRadioButton:SetChecked(true);
	end

	if ( UIScaleCheckButton_IsChecked() ) then
		LSF_DisplayGroupLeftGroupUIScaleCheckButton:SetChecked( true );
		LSF_DisplayGroupLeftGroupUIScaleSlider:Enable();
	else
		LSF_DisplayGroupLeftGroupUIScaleCheckButton:SetChecked( false );
		LSF_DisplayGroupLeftGroupUIScaleSlider:Disable();
	end

	LSF_UIScaleSliderUpdate();

	LSF_DisplayGroupLeftGroupUIScaleSlider:SetValue( UIScaleSlider_GetValue() );

	LSF_DisplayGroupLeftGroupRTLightMapCheckBox:SetChecked( RTLightMapCheckBox_IsChecked() );
	LSF_DisplayGroupLeftGroupTerrainShaderDetailSlider:SetValue( TerrainShaderDetailSlider_GetValue() );
	LSF_DisplayGroupLeftGroupLightMapResSlider:SetValue( LightMapResSlider_GetValue() );
	LSF_DisplayGroupLeftGroupShadowDetailSlider:SetValue( ShadowDetailSlider_GetValue() );

	LSF_DisplayGroupLeftGroupWaterReflectionCheckButton:SetChecked( WaterReflectionCheckButton_IsChecked() );
	LSF_DisplayGroupLeftGroupWaterRefractionCheckButton:SetChecked( WaterRefractionCheckButton_IsChecked() );
	LSF_DisplayGroupLeftGroupWaterQualitySlider:SetValue( WaterQualitySlider_GetValue() );	

	LSF_DisplayGroupLeftGroupBloomCheckButton:SetChecked( BloomCheckButton_IsChecked() );
	LSF_DisplayGroupLeftGroupGlowCheckButton:SetChecked( GlowCheckButton_IsChecked() );
	LSF_DisplayGroupLeftGroupBloomQualitySlider:SetValue( BloomQualitySlider_GetValue() );

	LSF_DisplayGroupRightGroupPaperdollDetailSlider:SetValue( PaperdollDetailSlider_GetValue() );
	LSF_DisplayGroupRightGroupViewDistanceSlider:SetValue( ViewDistanceSlider_GetValue() );
	LSF_DisplayGroupRightGroupWorldDetailSlider:SetValue( WorldDetailSlider_GetValue() );
	LSF_DisplayGroupRightGroupSkyDetailSlider:SetValue( SkyDetailSlider_GetValue() );
	LSF_DisplayGroupRightGroupTextureDetailSlider:SetValue( TextureDetailSlider_GetValue() );
	LSF_DisplayGroupRightGroupTerrainTextureDetailSlider:SetValue( TerrainTextureDetailSlider_GetValue() );

	LSF_DisplayGroupRightGroupSpecularHighlightCheckButton:SetChecked( SpecularHighlightCheckButton_IsChecked() );
	LSF_DisplayGroupRightGroupDistortFXCheckButton:SetChecked( DistortFXCheckButton_IsChecked() );
	LSF_DisplayGroupRightGroupDebaseTextureCheckButton:SetChecked( DebaseTextureCheckButton_IsChecked() );
	LSF_DisplayGroupRightGroupSmoothBlendCheckButton:SetChecked( SmoothBlendCheckButton_IsChecked() );

	local quality = GetDisplayQuality();

	if ( quality == 0 ) then
		LSF_Display_WorstRadioButton:SetChecked(false);
		LSF_Display_GeneralRadioButton:SetChecked(false);
		LSF_Display_BestRadioButton:SetChecked(false);
	elseif ( quality == 1 ) then
		LSF_Display_WorstRadioButton:SetChecked(true);
	elseif ( quality == 2 ) then
		LSF_Display_GeneralRadioButton:SetChecked(true);
	elseif ( quality == 3 ) then
		LSF_Display_BestRadioButton:SetChecked(true);
	end

	LSF_VolumeGroupMasterVolumeSlider:SetValue( MasterVolumeSlider_GetValue() );
	LSF_VolumeGroupMusicVolumeSlider:SetValue( MusicVolumeSlider_GetValue() );
	LSF_VolumeGroupAmbienceVolumeSlider:SetValue( AmbienceVolumeSlider_GetValue() );
	LSF_VolumeGroupSoundFXVolumeSlider:SetValue( SoundFXVolumeSlider_GetValue() );
	LSF_VolumeGroupInterfaceSFXVolumeSlider:SetValue( InterfaceSFXVolumeSlider_GetValue() );
	LSF_OptionsGroupMusicFrequencySlider:SetValue( MusicFrequencySlider_GetValue() );
end

function LSF_OnApply()
	if ( LSF_FullScreenRadioButton:IsChecked() ~= IsFullscreen() ) then		
		SYS_DispSet_SetResolutionNeedChange(true);
	end

	if( LSF_WindowModeRadioButton:IsChecked() ) then
		SYS_DispSet_SetNeedToBeWindowed(true);
	else
		SYS_DispSet_SetNeedToBeWindowed(false);
	end
	
	LSF_DisplaySettings_OnApply();
	LSF_AudioSettings_OnApply();
	SYS_DisplaySettings_OnApply();
end
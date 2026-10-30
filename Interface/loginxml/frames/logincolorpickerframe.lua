g_LoginColorPickerColors = 
{
	[1] = { r = 1, g = 0, b = 0 , angle = math.pi         },
	[2] = { r = 1, g = 1, b = 0 , angle = math.pi * 2 / 3 },
	[3] = { r = 0, g = 1, b = 0 , angle = math.pi * 1 / 3 },
	[4] = { r = 0, g = 1, b = 1 , angle = 0               },
	[5] = { r = 0, g = 0, b = 1 , angle = math.pi * 5 / 3 },
	[6] = { r = 1, g = 0, b = 1 , angle = math.pi * 4 / 3 },
}

--[[
List of ColorPickerFrame attributes
=================================================
info.parent    = [FRAME]   -- 
info.titleText = [STRING]  -- title , default UI_COLORPICKER_DEFAULT_TITLE
info.alphaMode = [nil, 1]  -- 有沒有 alpha Slider , default nil
info.r         = [0 - 1]   -- default 1
info.g         = [0 - 1]   -- default 1
info.b         = [0 - 1]   -- default 1
info.a         = [0 - 1]   -- default 1
info.brightnessUp   = [0 - 1] -- 亮度上限 , default 1
info.brightnessDown = [0 - 1] -- 亮度下限 , default 0
info.callbackFuncOkay   = [function] --按下Okay時的callback
info.callbackFuncUpdate = [function] --顏色改變時的callback
info.callbackFuncCancel = [function] --按下Cancel時的callback
--]]

function OpenLoginColorPickerFrame( info )
	LoginColorPickerFrame.callbackFuncOkay   = info.callbackFuncOkay  ;
	LoginColorPickerFrame.callbackFuncUpdate = info.callbackFuncUpdate;
	LoginColorPickerFrame.callbackFuncCancel = info.callbackFuncCancel;

	LoginColorPickerFrame.parent = info.parent;

	if( info.alphaMode )then
		LoginSelectAlphaSlider:Show();
	else
		LoginSelectAlphaSlider:Hide();
	end

	LoginColorPickerFrame.r = info.r or 1;
	LoginColorPickerFrame.g = info.g or 1;
	LoginColorPickerFrame.b = info.b or 1;
	LoginColorPickerFrame.a = info.a or 1;

	LoginColorPickerFrame.old_r = LoginColorPickerFrame.r ;
	LoginColorPickerFrame.old_g = LoginColorPickerFrame.g ;
	LoginColorPickerFrame.old_b = LoginColorPickerFrame.b ;
	LoginColorPickerFrame.old_a = LoginColorPickerFrame.a ;

	LoginColorPickerFrame.update_r = LoginColorPickerFrame.r ;
	LoginColorPickerFrame.update_g = LoginColorPickerFrame.g ;
	LoginColorPickerFrame.update_b = LoginColorPickerFrame.b ;
	LoginColorPickerFrame.update_a = LoginColorPickerFrame.a ;

	LoginColorPickerFrame.brightnessUp   = info.brightnessUp   or 1;
	LoginColorPickerFrame.brightnessDown = info.brightnessDown or 0;

	--亮度
	LoginSelectValueSlider:SetMinMaxValues( LoginColorPickerFrame.brightnessDown, LoginColorPickerFrame.brightnessUp );

	if( LoginColorPickerFrame:IsVisible() )then
		LoginColorPickerFrame_OnShow();
	else
		LoginColorPickerFrame:Show();
	end
end

--------------------------------------------------------------------------
function LoginColorPickerFrame_OnLoad()

	LoginSelectValueSlider:SetValueStepMode( "FLOAT" );
	LoginSelectValueSlider:SetMinMaxValues( 0, 1 );
	LoginSelectValueSlider:SetValue( 1 );

	LoginSelectAlphaSlider:SetValueStepMode( "FLOAT" );
	LoginSelectAlphaSlider:SetMinMaxValues( 0, 1 );
	LoginSelectAlphaSlider:SetValue( 1 );

end

--------------------------------------------------------------------------
function LoginColorPickerFrame_OnShow()
	LoginColorTextureFrame_SetColor( LoginColorPickerFrame.r , LoginColorPickerFrame.g , LoginColorPickerFrame.b  );
	LoginSelectAlphaSlider:SetValue( LoginColorPickerFrame.a );

	LoginColorPickerFrame:ResetFrameOrder();
end

--------------------------------------------------------------------------
function LoginColorPickerFrame_OnUpdate()
	if ( LoginColorPickerFrame.parent and (not LoginColorPickerFrame.parent:IsVisible()) ) then
		LoginColorPickerFrame:Hide();
	end
end

--------------------------------------------------------------------------
function LoginColorTextureFrame_SetColor( r , g , b  )
	if( r > 1 )then r = 1; end
	if( g > 1 )then g = 1; end
	if( b > 1 )then b = 1; end

	if( r < 0 )then r = 0; end
	if( g < 0 )then g = 0; end
	if( b < 0 )then b = 0; end

	LoginColorPickerFrame.r = r;
	LoginColorPickerFrame.g = g;
	LoginColorPickerFrame.b = b;

	local value;
	local radius;
	local angle;

	local _color = 0;

	if( r > _color )then _color = r; end
	if( g > _color )then _color = g; end
	if( b > _color )then _color = b; end

	if( _color == 0 )then
		value = 0;
		r = 1;
		g = 1;
		b = 1;
	else
		value = _color;
		
		r = r / value;
		g = g / value;
		b = b / value;

		if( r > 1 )then r = 1; end
		if( g > 1 )then g = 1; end
		if( b > 1 )then b = 1; end

		if( r < 0 )then r = 0; end
		if( g < 0 )then g = 0; end
		if( b < 0 )then b = 0; end
	end

	if( r == 1 and g == 1 and b == 1 )then
		LoginSelectValueSlider:SetValue( value );
		LoginSelectValueSliderValueTexture:SetColor( 1, 1, 1 );
		LoginColorPickerFrame.r = 1;
		LoginColorPickerFrame.g = 1;
		LoginColorPickerFrame.b = 1;

		LoginSelectAlphaSlider:SetValue( 1 );
		LoginColorPickerFrame.a = 1;

		LoginSelectColorFrame:ClearAllAnchors();
		LoginSelectColorFrame:SetAnchor( "CENTER", "CENTER", LoginColorTextureFrame, 0, 0 );

		LoginSelectColorTexture:SetColor( 1, 1, 1 );
		return;
	end

	--去除最小的顏色
	local find = nil;
	local least = 1;

	if( r < least )then least = r; end
	if( g < least )then least = g; end
	if( b < least )then least = b; end

	_r = ( r == least ) and 0 or r;
	_g = ( g == least ) and 0 or g;
	_b = ( b == least ) and 0 or b;

	--判斷顏色落在哪

	local index1, index2; 
	local check,find;

	find = 0;
	for i = 1 , 6 , 1 do
		check = 0;
		if( g_LoginColorPickerColors[i].r == _r )then check = check + 1; end
		if( g_LoginColorPickerColors[i].g == _g )then check = check + 1; end
		if( g_LoginColorPickerColors[i].b == _b )then check = check + 1; end

		if( check == 3 )then
			index1 = i;
			index2 = i;
			break;
		elseif( check == 2 )then
			if( find == 0 )then
				index1 = i;
				find = 1;
			elseif( find == 1 )then
				index2 = i;
				find = 2;
			end
		end
	end

	index1 = index1 or 0;
	index2 = index2 or 0;

	local _color,_color1, _color2;
	local _angle1, _angle2;

	angle = nil;

	if( index1 == 1 and index2 == 1 )then

		angle  = g_LoginColorPickerColors[1].angle ;
		radius = 1 - b;

	elseif( index1 == 2 and index2 == 2 )then

		angle  = g_LoginColorPickerColors[2].angle ;
		radius = 1 - b;

	elseif( index1 == 3 and index2 == 3 )then

		angle  = g_LoginColorPickerColors[3].angle ;
		radius = 1 - r;

	elseif( index1 == 4 and index2 == 4 )then

		angle  = g_LoginColorPickerColors[4].angle ;
		radius = 1 - r;

	elseif( index1 == 5 and index2 == 5 )then

		angle  = g_LoginColorPickerColors[5].angle ;
		radius = 1 - g;

	elseif( index1 == 6 and index2 == 6 )then

		angle  = g_LoginColorPickerColors[6].angle ;
		radius = 1 - g;

	elseif( index1 == 1 and index2 == 2 )then

		_color   = _g;

		_color1 = g_LoginColorPickerColors[2].g ;
		_color2 = g_LoginColorPickerColors[1].g ;
		_angle1 = g_LoginColorPickerColors[2].angle ;
		_angle2 = g_LoginColorPickerColors[1].angle ;

		radius = 1 - b;

	elseif( index1 == 2 and index2 == 3 )then
		_color  = _r;
		_color1 = g_LoginColorPickerColors[3].r ;
		_color2 = g_LoginColorPickerColors[2].r ;
		_angle1 = g_LoginColorPickerColors[3].angle ;
		_angle2 = g_LoginColorPickerColors[2].angle ;

		radius = 1 - b;

	elseif( index1 == 3 and index2 == 4 )then
		_color  = _b;
		_color1 = g_LoginColorPickerColors[4].b ;
		_color2 = g_LoginColorPickerColors[3].b ;
		_angle1 = g_LoginColorPickerColors[4].angle ;
		_angle2 = g_LoginColorPickerColors[3].angle ;

		radius = 1 - r;

	elseif( index1 == 4 and index2 == 5 )then
		_color  = _g;
		_color1 = g_LoginColorPickerColors[5].g ;
		_color2 = g_LoginColorPickerColors[4].g ;
		_angle1 = g_LoginColorPickerColors[5].angle ;
		_angle2 = g_LoginColorPickerColors[4].angle ;

		radius = 1 - r;

	elseif( index1 == 5 and index2 == 6 )then
		_color  = _r;
		_color1 = g_LoginColorPickerColors[6].r ;
		_color2 = g_LoginColorPickerColors[5].r ;
		_angle1 = g_LoginColorPickerColors[6].angle ;
		_angle2 = g_LoginColorPickerColors[5].angle ;

		radius = 1 - g;

	elseif( index1 == 1 and index2 == 6 )then
		_color  = _b;
		_color1 = g_LoginColorPickerColors[1].b ;
		_color2 = g_LoginColorPickerColors[6].b ;
		_angle1 = g_LoginColorPickerColors[1].angle ;
		_angle2 = g_LoginColorPickerColors[6].angle ;

		radius = 1 - g;
	else

	
	end

	if( not angle )then

		if( _angle1 > _angle2 )then 
			_angle2 = _angle2 + ( math.pi * 2 ) ; 
		end

		--r = 1 * ( 1 - percentage ) + r * percentage; <<==算出原本的顏色
		_color = ( _color - 1 ) / radius + 1 ;

		angle = ( (_color - _color1) / (_color2 - _color1) ) * ( _angle2 - _angle1 ) + _angle1;
	end

	--_a = angle * 180 / math.pi;

	--
	vecX = math.sin( angle );
	vecY = -math.cos( angle );

	_w,_h = LoginColorTextureFrame:GetSize();

	x = vecX * radius * ( _w / 2 );
	y = vecY * radius * ( _h / 2 );

	LoginSelectColorFrame:ClearAllAnchors();
	LoginSelectColorFrame:SetAnchor("CENTER", "CENTER", LoginColorTextureFrame, x, y );

	LoginSelectValueSlider:SetValue( value );
	LoginSelectValueSliderValueTexture:SetColor( r , g , b );

	LoginColorPickerFrame.r = r;
	LoginColorPickerFrame.g = g;
	LoginColorPickerFrame.b = b;

	--讓pick小圈圈變亮一點
	percentage = 0.7;
	r = r * ( 1 - percentage ) + 1 * percentage;
	g = g * ( 1 - percentage ) + 1 * percentage;
	b = b * ( 1 - percentage ) + 1 * percentage;
	
	LoginSelectColorTexture:SetColor( r, g, b );
end

--------------------------------------------------------------------------
function LoginColorTextureFrame_Pick(this)
	local x,y = GetCursorPos();
	local _x,_y = LoginColorTextureFrame:GetPos();
	local _w,_h = LoginColorTextureFrame:GetRealSize();

	x = ( x - _x ) / _w - 0.5;
	y = ( y - _y ) / _h - 0.5;

	x = x * 2;
	y = y * 2;

	local val = math.sqrt( x * x + y * y );

	if( val == 0 )then
		val = 0.0001; 
	end

	local vecX = x / val;
	local vecY = y / val;

	local angle = math.asin( vecX );
	if( vecY < 0 )then
		angle = math.pi - angle;
	end

	if( angle < 0 )then
		angle = math.pi * 2 + angle;
	end

	local colorIndex1 = angle * 3 / math.pi; --angle / ( math.pi / 3 );
	
	local percentage = colorIndex1 - math.floor( colorIndex1 );

	colorIndex1 = math.floor( colorIndex1 ) + 1;

	if( colorIndex1 > 6 or colorIndex1 < 1 )then
		colorIndex1 = 1;
	end

	local colorIndex2 = colorIndex1 + 1;
	if( colorIndex2 > 6 )then
		colorIndex2 = 1;
	end

	local r,g,b;
	r = g_LoginColorPickerColors[colorIndex1].r * ( 1 - percentage ) + g_LoginColorPickerColors[colorIndex2].r * percentage;
	g = g_LoginColorPickerColors[colorIndex1].g * ( 1 - percentage ) + g_LoginColorPickerColors[colorIndex2].g * percentage;
	b = g_LoginColorPickerColors[colorIndex1].b * ( 1 - percentage ) + g_LoginColorPickerColors[colorIndex2].b * percentage;
	
	percentage = val;
	if( percentage > 1 )then
		percentage = 1;	
	end
	r = 1 * ( 1 - percentage ) + r * percentage;
	g = 1 * ( 1 - percentage ) + g * percentage;
	b = 1 * ( 1 - percentage ) + b * percentage;

	LoginSelectValueSliderValueTexture:SetColor( r, g, b );

	_w,_h = LoginColorTextureFrame:GetSize();

	x = vecX * percentage * ( _w / 2 );
	y = vecY * percentage * ( _h / 2 );

	LoginSelectColorFrame:ClearAllAnchors();
	LoginSelectColorFrame:SetAnchor("CENTER", "CENTER", LoginColorTextureFrame, x, y );

	--val = SelectValueSlider:GetValue();
	--ColorPickerFrame.r = r * val;
	--ColorPickerFrame.g = g * val;
	--ColorPickerFrame.b = b * val;

	LoginColorPickerFrame.r = r;
	LoginColorPickerFrame.g = g;
	LoginColorPickerFrame.b = b;


	--r = 1-r;
	--g = 1-g;
	--b = 1-b;

	--讓pick小圈圈變亮一點
	percentage = 0.7;
	r = r * ( 1 - percentage ) + 1 * percentage;
	g = g * ( 1 - percentage ) + 1 * percentage;
	b = b * ( 1 - percentage ) + 1 * percentage;
	LoginSelectColorTexture:SetColor( r, g, b );
end

--------------------------------------------------------------------------
function LoginColorTextureFrame_OnMouseDown(this)
	LoginColorTextureFrame.picking = 1;
end

--------------------------------------------------------------------------
function LoginColorTextureFrame_OnMouseUp(this)
	LoginColorTextureFrame.picking = nil;
end

--------------------------------------------------------------------------
function LoginColorTextureFrame_OnUpdate(this)
	if( LoginColorTextureFrame.picking )then
		LoginColorTextureFrame_Pick(this);
	end

	local val = LoginSelectValueSlider:GetValue();
	local r,g,b;
	r = LoginColorPickerFrame.r * val;
	g = LoginColorPickerFrame.g * val;
	b = LoginColorPickerFrame.b * val;
	--SelectValueSliderThumbTexture:SetColor( r, g, b );

	LoginSelectValueSliderText:SetColor( r, g, b );

	local a = LoginSelectAlphaSlider:GetValue();
	LoginSelectValueSliderText:SetAlpha( a );


	if( LoginColorPickerFrame.callbackFuncUpdate )then

		r = LoginColorPickerFrame.r ;
		g = LoginColorPickerFrame.g ;
		b = LoginColorPickerFrame.b ;
		a = LoginColorPickerFrame.a ;

		local val = LoginSelectValueSlider:GetValue();
		LoginColorPickerFrame.r = LoginColorPickerFrame.r * val;
		LoginColorPickerFrame.g = LoginColorPickerFrame.g * val;
		LoginColorPickerFrame.b = LoginColorPickerFrame.b * val;
		LoginColorPickerFrame.a = LoginSelectAlphaSlider:GetValue();

		if( LoginColorPickerFrame.update_r ~= LoginColorPickerFrame.r or
			LoginColorPickerFrame.update_g ~= LoginColorPickerFrame.g or
			LoginColorPickerFrame.update_b ~= LoginColorPickerFrame.b or
			LoginColorPickerFrame.update_a ~= LoginColorPickerFrame.a )then

			LoginColorPickerFrame.update_r = LoginColorPickerFrame.r ;
			LoginColorPickerFrame.update_g = LoginColorPickerFrame.g ;
			LoginColorPickerFrame.update_b = LoginColorPickerFrame.b ;
			LoginColorPickerFrame.update_a = LoginColorPickerFrame.a ;

		LoginColorPickerFrame.isUpdate = 1;
		LoginColorPickerFrame.isOkay   = nil;
		LoginColorPickerFrame.isCancel = nil;

			LoginColorPickerFrame.callbackFuncUpdate();
		end

		LoginColorPickerFrame.r = r;
		LoginColorPickerFrame.g = g;
		LoginColorPickerFrame.b = b;
		LoginColorPickerFrame.a = a;

	end


end

--------------------------------------------------------------------------
function LoginColorPickerOkayButton_OnClick()

	if( LoginColorPickerFrame.callbackFuncOkay )then
		local val = LoginSelectValueSlider:GetValue();
		LoginColorPickerFrame.r = LoginColorPickerFrame.r * val;
		LoginColorPickerFrame.g = LoginColorPickerFrame.g * val;
		LoginColorPickerFrame.b = LoginColorPickerFrame.b * val;

		LoginColorPickerFrame.a = LoginSelectAlphaSlider:GetValue();

		LoginColorPickerFrame.isUpdate = nil;
		LoginColorPickerFrame.isOkay   = 1;
		LoginColorPickerFrame.isCancel = nil;

		LoginColorPickerFrame.callbackFuncOkay();
	end

	LoginColorPickerFrame:Hide();

end

--------------------------------------------------------------------------
function LoginColorPickerCancelButton_OnClick()

	if( LoginColorPickerFrame.callbackFuncCancel )then

		LoginColorPickerFrame.r = LoginColorPickerFrame.old_r ;
		LoginColorPickerFrame.g = LoginColorPickerFrame.old_g ;
		LoginColorPickerFrame.b = LoginColorPickerFrame.old_b ;
		LoginColorPickerFrame.a = LoginColorPickerFrame.old_a ;

		LoginColorPickerFrame.isUpdate = nil;
		LoginColorPickerFrame.isOkay   = nil;
		LoginColorPickerFrame.isCancel = 1;

		LoginColorPickerFrame.callbackFuncCancel();
	end

	LoginColorPickerFrame:Hide();
end



-- Cherry's Kit: resizable Advanced AuctionHouse window.
--
-- Drag the corner grip (bottom right) to make the window wider and taller; the size is saved in
-- AAH_SavedSettings.Width / Height. The old up/down arrows still work and change the height by one
-- list row. "/aah size reset" goes back to the default size.
--
-- Wider: the Item Name and Stats columns grow, the filter boxes get longer, the Bids and Auctions
-- lists get a wider name column. Taller: more rows in every list.
--
-- RoM units (measured in game for Cherry's Chat): GetCursorPos and GetLeft/GetTop are screen
-- pixels with +y down, sizes are UI units, and screen pixels = UI units * GetUIScale().

local Layout = {
	BASE_W = 846, BASE_H = 489,   -- the original window
	DEFAULT_W = 1150, DEFAULT_H = 509,  -- 20 taller than 6.0.2: the taller search panel (AAH.Browse.HEADER_EXTRA)
	MIN_W = 1150, MIN_H = 509,  -- 1150: two filter columns, and a Stats column that shows all 6 slots (2 a line, full values)
	MAX_W = 1800, MAX_H = 509 + 44 * 9, -- 16 Browse rows; the XML has rows for that
	VERSION = 2,
	ROW = 44,
	errors = {},
}
AAH.Layout = Layout

local function scale()
	local s = GetUIScale and GetUIScale()
	return (type(s) == "number" and s > 0) and s or 1
end

local function try(obj, method, ...)
	if obj and obj[method] then
		return pcall(obj[method], obj, ...)
	end
	return false
end
Layout.Try = try

-- Runs one resize step; an error is remembered for /aah probe instead of breaking the window.
local function safe(name, fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then
		Layout.errors[name] = tostring(err)
	end
	return ok
end

function Layout.Clamp(w, h)
	w = math.floor(tonumber(w) or Layout.DEFAULT_W)
	h = math.floor(tonumber(h) or Layout.DEFAULT_H)
	w = math.max(Layout.MIN_W, math.min(Layout.MAX_W, w))
	h = math.max(Layout.MIN_H, math.min(Layout.MAX_H, h))
	return w, h
end

function Layout.Init()
	local s = AAH_SavedSettings
	-- 6.0.2 saved a step count (0-5) for the arrow buttons; turn it into a height once.
	if (s.Resize or 0) > 0 then
		s.Height = Layout.MIN_H + Layout.ROW * s.Resize
		s.Resize = 0
	end
	-- kit 0.11.8: the search panel got 20 taller; keep the number of Browse rows the same
	if (tonumber(s.LayoutVersion) or 0) < Layout.VERSION then
		if (tonumber(s.LayoutVersion) or 0) < 2 and s.Height then
			s.Height = s.Height + 20
		end
		s.LayoutVersion = Layout.VERSION
	end
	try(AAH_AuctionResizeGripTexture, "SetFile", AAH.Manifest.Root .. "/Textures/resize_grip")
	Layout.Apply(s.Width, s.Height)
end

function Layout.Size()
	local s = AAH_SavedSettings or {}
	return Layout.Clamp(s.Width, s.Height)
end

function Layout.Apply(w, h)
	w, h = Layout.Clamp(w, h)
	if AAH_SavedSettings then
		AAH_SavedSettings.Width, AAH_SavedSettings.Height = w, h
	end
	local dW, dH = w - Layout.BASE_W, h - Layout.BASE_H
	local num = math.floor(dH / Layout.ROW)

	safe("frame", function()
		AAH_AuctionFrame:SetSize(w, h)
		AAH_AuctionFrameTopCenter:SetSize(334 + dW, 256)
		AAH_AuctionFrameBottomLeft:SetSize(256, 233 + dH)
		AAH_AuctionFrameBottomCenter:SetSize(334 + dW, 233 + dH)
		AAH_AuctionFrameBottomRight:SetSize(256, 233 + dH)
	end)
	safe("arrows", function()
		if h <= Layout.MIN_H then AAH_AuctionReduceButton:Disable() else AAH_AuctionReduceButton:Enable() end
		if h >= Layout.MAX_H then AAH_AuctionEnlargeButton:Disable() else AAH_AuctionEnlargeButton:Enable() end
	end)
	safe("browse", AAH.Browse.Resize, num, dH, dW)
	safe("bid", AAH.Bid.Resize, num, dH, dW)
	safe("sell", AAH.Sell.Resize, num, dH, dW)
	return w, h
end

-- The up/down arrows: one list row taller or shorter.
function Layout.Step(step)
	local w, h = Layout.Size()
	Layout.Apply(w, h + Layout.ROW * (step or 0))
end

function Layout.Reset()
	Layout.Apply(Layout.DEFAULT_W, Layout.DEFAULT_H)
end

---------------------------------------------------------------------------
-- Corner grip
---------------------------------------------------------------------------

-- Pins the window's top-left corner where it is now, so dragging the grip moves only the
-- bottom-right corner (the game may have anchored it by its centre).
function Layout.PinTopLeft()
	local f = AAH_AuctionFrame
	local ok1, left = try(f, "GetLeft")
	local ok2, top = try(f, "GetTop")
	if not (ok1 and ok2 and left and top) then
		return false
	end
	local s = scale()
	try(f, "ClearAllAnchors")
	try(f, "SetAnchor", "TOPLEFT", "TOPLEFT", "UIParent", left / s, top / s)
	local _, left2 = try(f, "GetLeft")
	local _, top2 = try(f, "GetTop")
	Layout.pin = { left = left, top = top, left2 = left2, top2 = top2, scale = s }
	-- If GetLeft turned out to be UI units rather than pixels, the frame jumped: use them as they are.
	if left2 and top2 and (math.abs(left2 - left) > 3 or math.abs(top2 - top) > 3) then
		try(f, "ClearAllAnchors")
		try(f, "SetAnchor", "TOPLEFT", "TOPLEFT", "UIParent", left, top)
		Layout.pin.fallback = true
	end
	return true
end

function Layout.GripDown(this)
	if not GetCursorPos then
		return
	end
	local x, y = GetCursorPos()
	local w, h = Layout.Size()
	Layout.PinTopLeft()
	Layout.drag = { x = x, y = y, w = w, h = h, scale = scale() }
end

function Layout.GripUp(this)
	if Layout.drag then
		Layout.drag = nil
		local w, h = Layout.Size()
		Layout.Apply(w, h)
	end
end

local lastW, lastH
function Layout.GripUpdate(this)
	local d = Layout.drag
	if not d then
		return
	end
	local x, y = GetCursorPos()
	-- right makes it wider, down makes it taller
	local w, h = Layout.Clamp(d.w + (x - d.x) / d.scale, d.h + (y - d.y) / d.scale)
	if w ~= lastW or h ~= lastH then
		lastW, lastH = w, h
		Layout.Apply(w, h)
	end
end

function Layout.GripEnter(this)
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	GameTooltip:SetText("Resize", 1, 1, 1)
	GameTooltip:AddLine("Drag to make the window wider or taller.", 0, 0.75, 0.95)
	GameTooltip:AddLine("/aah size reset puts it back.", 0, 0.75, 0.95)
	GameTooltip:Show()
end

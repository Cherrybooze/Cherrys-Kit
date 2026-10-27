-- ClassIcons.lua: the class-combo icon for a primary/secondary class (used by the Class trigger).
-- The icons ship with Cherry's KittyCombo 1.5.0+ (Kitty.ClassIcon, gfx/class); without it there is no icon.

local RWA = RWA

function RWA.ClassIcon(main, sub)
  if Kitty and type(Kitty.ClassIcon) == "function" then
    local ok, path = pcall(Kitty.ClassIcon, main, sub)
    if ok and path then
      return path
    end
  end
  return nil
end

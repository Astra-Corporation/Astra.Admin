--[[
	Clone and drop the loader so it can hide in nil.
--]]

local loader = script.Parent.Loader:Clone()
loader.Parent = script.Parent
loader.Name = "\0NoStealing."
loader.Archivable = false
loader.Disabled = false

-- Disable the Dropper so Adonis doesn't try to load on BindToClose()
script.Disabled = true
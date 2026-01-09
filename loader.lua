-- ======================================================
-- 🔮 Ko0 Hub Loader
-- ======================================================

getgenv().Ko0Hub = getgenv().Ko0Hub or {}

if getgenv().Ko0Hub.Unload then
    pcall(getgenv().Ko0Hub.Unload)
end

-- ========= Services =========
local MarketplaceService = game:GetService("MarketplaceService")

-- ========= Library =========
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

Library.ForceCheckbox = false

getgenv().Ko0Hub.Library = Library
getgenv().Ko0Hub.Unload = function()
    Library:Unload()
end

-- ========= Window =========
local info = MarketplaceService:GetProductInfo(game.PlaceId)

local Window = Library:CreateWindow({
    Title = "🔮 Ko0 Hub 🔮",
    Footer = info.Name,
    Center = true,
    Resizable = false,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

-- ========= Settings tab (ONLY global tab) =========
local SettingsTab = Window:AddTab("Settings", "settings")
local MenuGroup = SettingsTab:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(v)
        Library.KeybindFrame.Visible = v
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(v)
        Library.ShowCustomCursor = v
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(v)
        Library:SetNotifySide(v)
    end,
})

MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(v)
        Library:SetDPIScale(tonumber(v:gsub("%%","")))
    end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "Insert", NoUI = true })

MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Library.Options.MenuKeybind

-- ========= Managers =========
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("Ko0-Hub")
SaveManager:SetFolder("Ko0-Hub/" .. game.GameId)

SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:LoadAutoloadConfig()

-- ========= GAME LOADER =========
-- local BASE = "https://raw.githubusercontent.com/YOU/Ko0-Hub/main/games/"

-- local function loadGame()
--     local ok, src = pcall(function()
--         return game:HttpGet(BASE .. game.PlaceId .. ".lua")
--     end)

--     if ok and src then
--         local fn = loadstring(src)
--         if fn then
--             fn(Window, Library)
--             return
--         end
--     end

--     loadstring(game:HttpGet(BASE .. "default.lua"))()(Window, Library)
-- end
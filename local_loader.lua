-- ======================================================
-- 🔮 Ko0 Hub Loader (Local Version)
-- ======================================================

-- Local script folder
local SCRIPTS_DIR = "Ko0Script/scripts/"

-- Use timestamp as cache buster (optional for local, mostly ignored)
local CACHE_BUSTER = tostring(os.time())

-- Versioning (optional, can keep "local" for now)
local HUB_VERSION = "local"

getgenv().Ko0Hub = getgenv().Ko0Hub or {}
local Hub = getgenv().Ko0Hub

-- Unload previous instance
if Hub.Unload then
    pcall(Hub.Unload)
end

-- Prevent duplicate window
if Hub.Window and Hub.Window.Open then
    warn("Ko0 Hub already loaded!")
    return
end

-- ========= Services =========
local MarketplaceService = game:GetService("MarketplaceService")

-- ========= Library (Obsidian, unchanged) =========
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
Library.ForceCheckbox = false

Hub.Library = Library
Hub.Unload = function()
    if Hub.Library then
        Hub.Library:Unload()
    end
    Hub.Window = nil
end

-- ========= Window =========
local info = MarketplaceService:GetProductInfo(game.PlaceId)
Hub.Window = Library:CreateWindow({
    Title = "🔮 Ko0 Hub 🔮",
    Footer = info.Name,
    Center = true,
    Resizable = false,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

-- ========= GAME LOADER (LOCAL) =========
local function loadGame()
    local localPath = SCRIPTS_DIR .. game.GameId .. ".lua"
    local success, chunk = pcall(function()
        return loadfile(localPath)
    end)

    if success and chunk then
        local ok, innerFn = pcall(chunk)
        if ok and type(innerFn) == "function" then
            print("Loaded local script for:", info.Name, "HUB VERSION:", HUB_VERSION)
            innerFn(Hub.Window, Hub.Library)
            return
        else
            warn("Error running local script for:", game.GameId, innerFn)
        end
    else
        warn("Cannot find local script for:", game.GameId, "Path:", localPath)
    end

    -- Fallback: load test.lua locally
    local testPath = SCRIPTS_DIR .. "test.lua"
    local testChunk = loadfile(testPath)
    if testChunk then
        local ok, innerFn = pcall(testChunk)
        if ok and type(innerFn) == "function" then
            print("Loaded local test.lua as fallback")
            innerFn(Hub.Window, Hub.Library)
        end
    end
end

loadGame()

-- ========= Settings Tab =========
local SettingsTab = Hub.Window:AddTab("Settings", "settings")
local MenuGroup = SettingsTab:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Hub.Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(v)
        Hub.Library.KeybindFrame.Visible = v
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(v)
        Hub.Library.ShowCustomCursor = v
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(v)
        Hub.Library:SetNotifySide(v)
    end,
})

MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(v)
        Hub.Library:SetDPIScale(tonumber(v:gsub("%%","")))
    end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "Insert", NoUI = true })

MenuGroup:AddButton("Unload", function()
    Hub.Unload()
end)
MenuGroup:AddDivider()
MenuGroup:AddLabel("Hub Version:\t" .. HUB_VERSION)

Library.ToggleKeybind = Hub.Library.Options.MenuKeybind

-- ========= Managers =========
ThemeManager:SetLibrary(Hub.Library)
SaveManager:SetLibrary(Hub.Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("Ko0-Hub")
SaveManager:SetFolder("Ko0-Hub/" .. game.GameId)

SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:LoadAutoloadConfig()

-- ========= Queue on teleport =========
getgenv().Ko0TP = getgenv().Ko0TP or false
if not getgenv().Ko0TP then
    getgenv().Ko0TP = true
    queue_on_teleport([[
        getgenv().Ko0TP = false
        -- Load local version on teleport
        loadfile("Ko0Script/local_loader.lua")()
    ]])
end

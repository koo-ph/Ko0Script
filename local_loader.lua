-- ======================================================
-- 🔮 Local Ko0 Hub Loader (with logging)
-- ======================================================

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

local info = MarketplaceService:GetProductInfo(game.PlaceId)
print("[Ko0 Hub] Game:", info.Name, "PlaceId:", game.PlaceId)

-- ========= Library =========
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library, ThemeManager, SaveManager

local function SafeLoad(url)
    local ok, res = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not ok then
        warn("[Ko0 Hub] Failed to load:", url, "Error:", res)
        return nil
    end
    return res
end

Library = SafeLoad(repo .. "Library.lua")
ThemeManager = SafeLoad(repo .. "addons/ThemeManager.lua")
SaveManager = SafeLoad(repo .. "addons/SaveManager.lua")

if not Library then
    error("[Ko0 Hub] Cannot continue without Library!")
end

-- ========= Hub globals =========
getgenv().Ko0Hub = getgenv().Ko0Hub or {}
local Hub = getgenv().Ko0Hub

-- Prevent duplicate window creation
if Hub.Window and Hub.Window.Open then
    warn("[Ko0 Hub] Window already loaded!")
    return
end

Hub.Library = Library
Hub.Unload = function()
    if Hub.Library then
        Hub.Library:Unload()
    end
    Hub.Window = nil
end

-- ========= Window =========
Hub.Window = Library:CreateWindow({
    Title = "🔮 Ko0 Hub 🔮",
    Footer = info.Name,
    Center = true,
    Resizable = false,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

-- ========= Local script loader =========
local SCRIPT_DIR = "C:\\Users\\Vivo\\Desktop\\Ko0Script"  -- relative folder
local gameScriptPath = SCRIPT_DIR .. game.GameId .. ".lua"
local fallbackPath = SCRIPT_DIR .. "test.lua"

local function Log(msg, ...)
    print("[Ko0 Hub]", string.format(msg, ...))
end

local function loadGame()
    Log("Attempting to load local script for PlaceId %d: %s", game.PlaceId, gameScriptPath)

    local chunk, err = loadfile(gameScriptPath)
    if chunk then
        local ok, fn = pcall(chunk)
        if ok and type(fn) == "function" then
            Log("Successfully loaded local script: %s", gameScriptPath)
            fn(Hub.Window, Hub.Library)
            return
        else
            warn("[Ko0 Hub] Error running script:", fn)
        end
    else
        warn("[Ko0 Hub] Failed to compile script:", err)
    end

    -- Fallback
    Log("Loading fallback script: %s", fallbackPath)
    local fallbackChunk, fallbackErr = loadfile(fallbackPath)
    if fallbackChunk then
        local ok, fn = pcall(fallbackChunk)
        if ok and type(fn) == "function" then
            Log("Successfully loaded fallback script")
            fn(Hub.Window, Hub.Library)
        else
            warn("[Ko0 Hub] Failed to run fallback script:", fn)
        end
    else
        warn("[Ko0 Hub] Fallback script not found or failed to compile:", fallbackErr)
    end
end

loadGame()

-- ========= Settings tab =========
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

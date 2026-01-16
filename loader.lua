-- ======================================================
-- 🔮 Ko0 Hub Loader
-- ======================================================
local COMMIT_API =
    "https://api.github.com/repos/koo-ph/Ko0Script/commits/main"

local CACHE_BUSTER = tostring(os.time())

local function GetVersion()
    local ok, res = pcall(function()
        return game:HttpGet(COMMIT_API .. "?v=" .. CACHE_BUSTER)
    end)

    if not ok or not res then return nil end

    -- Extract full SHA, then trim to 7 chars
    local sha = res:match('"sha"%s*:%s*"([a-f0-9]+)"')
    if sha then
        return sha:sub(1, 7)
    end
end
local HUB_VERSION = GetVersion() or "unknown"

getgenv().Ko0Hub = getgenv().Ko0Hub or {}
local Hub = getgenv().Ko0Hub

if Hub.Unload then
    pcall(Hub.Unload)
end

-- Prevent duplicate window creation
if Hub.Window and Hub.Window.Open then
    warn("Ko0 Hub already loaded!")
    return
end

-- ========= Services =========
local MarketplaceService = game:GetService("MarketplaceService")

-- ========= Library =========
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

-- ========= GAME LOADER =========
local BASE = "https://raw.githubusercontent.com/koo-ph/Ko0Script/main/"
local SCRIPTS = BASE .. "/scripts/"
local function loadGame()
    local ok, src = pcall(function()
        return game:HttpGet(SCRIPTS .. game.GameId .. ".lua")
    end)

    if ok and src then
        local fn, err = loadstring(src)
        if not fn then
            warn("Failed to load GAME:", game.GameId, "Error:", err)
            setclipboard("Failed to load GAME: " .. tostring(game.GameId) .. " | Error: " .. tostring(err))
            return
        end

        local success, innerFn = pcall(fn)  -- call the chunk first
        if success and type(innerFn) == "function" then
            innerFn(Hub.Window, Hub.Library)  -- now call the returned function
            return
        end
    end
     -- Fallback to test.lua if the game-specific script failed
    warn("Cannot find script for: " .. game.GameId)
    warn("Now loading test.lua")

    local testOk, testSrc = pcall(function()
        return game:HttpGet(SCRIPTS .. "test.lua")
    end)

    if testOk and testSrc then
        local testFn, testErr = loadstring(testSrc)
        if testFn then
            local success, innerFn = pcall(testFn)
            if success and type(innerFn) == "function" then
                innerFn(Hub.Window, Hub.Library)
                return
            else
                warn("Failed to execute test.lua:", innerFn)
            end
        else
            warn("Failed to load test.lua:", testErr)
        end
    else
        warn("Failed to fetch test.lua")
    end
end
loadGame()
-- ========= Settings tab (ONLY global tab) =========
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
MenuGroup:AddLabel("Hub Version:")
    :AddLabel(HUB_VERSION)

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

getgenv().Ko0TP = getgenv().Ko0TP or false
if not getgenv().Ko0TP then
    getgenv().Ko0TP = true
    queue_on_teleport([[
        getgenv().Ko0TP = false
        loadstring(game:HttpGet("https://raw.githubusercontent.com/koo-ph/Ko0Script/main/loader.lua"))()
    ]])
end
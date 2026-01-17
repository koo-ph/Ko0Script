local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Remotes = ReplicatedStorage:WaitForChild("remotes")

-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- =================================================================== KILL AURA =================================================================== --
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
nearest = nil
targets = {}
local function GetNear(tagName, enemies)
    local character = LocalPlayer.Character
    if not character then
        nearest = nil
        return nil
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        nearest = nil
        return nil
    end

    local nearestTarget = nil
    local nearestDistSq = math.huge

    for enemy in pairs(enemies) do
        local primary = enemy.PrimaryPart
        if primary then
            local diff = primary.Position - hrp.Position
            local distSq = diff.X*diff.X + diff.Y*diff.Y + diff.Z*diff.Z

            if distSq < nearestDistSq then
                nearestDistSq = distSq
                nearestTarget = enemy
            end
        end
    end

    nearest = nearestTarget
end
for _, inst in ipairs(CollectionService:GetTagged("enemy")) do
    targets[inst] = true
end
local function StartSwing()
    local swing = Remotes:FindFirstChild("swing")
    if not swing then return end

    swing:FireServer()
end
local function StartBlock()
    local block = Remotes:FindFirstChild("block")
    if not block then return end

    block:FireServer(true)
end
local TargetHandlers = {}
TargetHandlers["BookHand"] = function(target)
    -- Find Korth in the targets table
    local korth
    for t in pairs(targets) do
        if t.Name == "Korth" then
            korth = t
            break
        end
    end

    if not korth then return end

    local hadEntrance = korth:GetAttribute("hadEntrance")
    local health = korth:FindFirstChild("Health")
    if hadEntrance and health and health.Value > 0 then
        Damage(target)
    end
end

local function Damage(target)
    local onHit = Remotes:FindFirstChild("onHit")
    if not onHit or not target:FindFirstChild("Humanoid") then return end

    onHit:FireServer(
        target.Humanoid,
        9999,
        {},
        0
    )
end
local function KillAura(target)
    if not target or not target.Parent then return end

    -- Always skip LocalKorth (the player)
    if target.Name == "LocalKorth" then
        return
    end

    local handler = TargetHandlers[target.Name] or Damage
    handler(target)
end

-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- =================================================================== INTERFACE =================================================================== --
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
return function(Window, Library)
    local Toggles = Library.Toggles
    local Options = Library.Options
    local HeartbeatConn

    local Main = Window:AddTab("Main", "house")
    local Main_Combat = Main:AddLeftGroupbox("Combat", "swords")
    local Main_Movement = Main:AddLeftGroupbox("Movement", "footprints")
    local Main_Visual = Main:AddRightGroupbox("Visual", "eye")
    local Main_Utility = Main:AddRightGroupbox("Utility", "target")
-- ================================================================== Main_Combat =================================================================== --
    local KA_Toggle_G = 0
    Main_Combat:AddToggle("KA_Toggle", {
    Text = "Kill Aura",
    Tooltip = "Use Skill to Damage All",
    DisabledTooltip = "I am disabled!",

    Default = false,
    Disabled = false,
    Visible = true,
    Risky = true,

    Callback = function(Value)
        KA_Toggle_G += 1
        local myG = KA_Toggle_G
        if not Value then return end
        task.spawn(function()
            while Toggles.KA_Toggle.Value and KA_Toggle_G == myG do
                for target in pairs(targets) do
                    KillAura(target)
                end

                task.wait(Options.KA_Speed.Value)
            end
        end)
    end,
    })
    Main_Combat:AddSlider("KA_Speed", {
        Text = "KillAura Speed",
        Default = 0.3,
        Min = 0.01,
        Max = 2,
        Rounding = 2,
        Compact = true,

        Callback = function(Value)
        end,

        Tooltip = "Kill Aura Speed", -- Information shown when you hover over the slider
        DisabledTooltip = "I am disabled!", -- Information shown when you hover over the slider while it's disabled

        Disabled = false, -- Will disable the slider (true / false)
        Visible = true, -- Will make the slider invisible (true / false)
    })
-- ================================================================= Main_Movement ================================================================== --
    Main_Movement:AddToggle("WS_Toggle", {
        Text = "Walk Speed",
        Tooltip = "Change your character's walk speed",
        DisabledTooltip = "I am disabled!",

        Default = false,
        Disabled = false,
        Visible = true,
        Risky = false,

        Callback = function(Value)
            Options.WS_Speed:SetDisabled(not Value)
        end,
    })
    Main_Movement:AddSlider("WS_Speed", {
        Text = "",
        Default = 45,
        Min = 16,
        Max = 200,
        Rounding = 0,
        Suffix = " stud/s",
        Compact = false,

        Callback = function(Value)

        end,

        Tooltip = "Walk Speed Value", -- Information shown when you hover over the slider
        DisabledTooltip = "Enable Walk Speed!", -- Information shown when you hover over the slider while it's disabled

        Disabled = not Toggles.WS_Toggle.Value, -- Will disable the slider (true / false)
        Visible = true, -- Will make the slider invisible (true / false)
        HideMax = true,
    })
-- ================================================================== Main_Visual =================================================================== --
    Main_Visual:AddToggle("HT_Toggle", {
        Text = "Highlight Target",
        Tooltip = "Highlight the target",
        DisabledTooltip = "I am disabled!",

        Default = false,
        Disabled = false,
        Visible = true,
        Risky = false,

        Callback = function(Value)
            
        end,
    })
-- ================================================================= Main_Utility =================================================================== --
    Main_Utility:AddToggle("ASA_Toggle", {
        Text = "Auto Select Abilities",
        Tooltip = "Automatically select abilities",
        DisabledTooltip = "I am disabled!",

        Default = false,
        Disabled = false,
        Visible = true,
        Risky = false,

        Callback = function(Value)
            
        end,
    })
-- =================================================================== CONNECTIONS ==================================================================== --
    local Worker = {}
    Worker.__index = Worker
    function Worker.new()
        return setmetatable({ _tasks = {} }, Worker)
    end
    function Worker:Start(task)
        table.insert(self._tasks, task)
        return task
    end
    function Worker:StopAll()
        for i = #self._tasks, 1, -1 do
            local task = self._tasks[i]

            local t = typeof(task)
            if t == "RBXScriptConnection" then
                if task.Connected then
                    task:Disconnect()
                end
            elseif t == "function" then
                task()
            elseif t == "Instance" then
                task:Destroy()
            end

            self._tasks[i] = nil
        end
    end
    local worker = Worker.new()
    worker:Start(RunService.Heartbeat:Connect(function(delta_time)
        if Toggles.KA_Toggle.Value then
            -- Do KillAura
            StartSwing()
            StartBlock()
        end
        if Toggles.WS_Toggle.Value then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = Options.WS_Speed.Value
            end
        end
    end))
    worker:Start(CollectionService:GetInstanceAddedSignal("enemy"):Connect(function(instance)
        targets[instance] = true
    end))
    worker:Start(CollectionService:GetInstanceRemovedSignal("enemy"):Connect(function(instance)
        targets[instance] = nil
    end))
-- ===================================================================== UNLOAD ======================================================================= --
    Library:OnUnload(function()
        worker:StopAll()
        KA_Toggle_G = nil
    end)
end

--- THIS IS A FUNCTIONS
-- local args = {
-- 	1
-- }
-- game:GetService("ReplicatedStorage"):WaitForChild("remotes"):WaitForChild("plrUpgrade"):FireServer(unpack(args))


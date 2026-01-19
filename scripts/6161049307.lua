local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("remotes", 1)

-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- =================================================================== KILL AURA =================================================================== --
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
nearest = nil
targets = {}
local function GetNear(enemies)
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
        local health = enemy:FindFirstChild("Health")
        if not health or health.Value <= 0 then
            continue
        end
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

    return nearestTarget
end
for _, inst in ipairs(CollectionService:GetTagged("enemy")) do
    if inst.Name == "LocalKorth" or inst.Parent ~= Workspace then
        continue
    end
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

local TargetHandlers = {}
local BOOKHAND_INITIAL_DELAY = 2 -- seconds (first time)
local BOOKHAND_REVIVE_DELAY  = 0 -- seconds (after death)

local BookHandState = {
    seenAlive = false,
    wasDead = false,
    delayUntil = 0,
}
TargetHandlers["BookHand"] = function(target)
    local now = os.clock()

    -- Find Korth
    local korth
    for t in pairs(targets) do
        if t.Name == "Korth" or t.Name == "CorruptKorth" then
            korth = t
            break
        end
    end
    if not korth then return end

    local hadEntrance = korth:GetAttribute("hadEntrance")
    local health = korth:FindFirstChild("Health")
    local alive = korth:FindFirstChild("alive")

    local target_health = target:FindFirstChild("Health")
    if not target_health then return end

    -- FIRST TIME alive → initial delay (X)
    if target_health.Value > 0 and not BookHandState.seenAlive and hadEntrance then
        BookHandState.seenAlive = true
        BookHandState.delayUntil = now + BOOKHAND_INITIAL_DELAY
        BookHandState.wasDead = false
        return
    end

    -- REVIVE: dead -> alive → revive delay (Y)
    if target_health.Value > 0 then
        if BookHandState.wasDead then
            BookHandState.delayUntil = now + BOOKHAND_REVIVE_DELAY
            BookHandState.wasDead = false
            return
        end
    else
        -- Currently dead
        BookHandState.wasDead = true
        return
    end

    -- Still in delay window
    if now < BookHandState.delayUntil then
        return
    end

    if hadEntrance
        and health and health.Value > 0
        and alive and alive.Value
        and target_health.Value > 0 then

        Damage(target)
    end
end

local function KillAura(target)
    if not target or not target.Parent then return end    

    local handler = TargetHandlers[target.Name] or Damage
    handler(target)
end

-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- ================================================================== HIGHLIGHT ==================================================================== --
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- Create a Highlight
local highlight = Instance.new("Highlight")

-- Customize properties
highlight.FillColor = Color3.fromRGB(0, 0, 0)   -- Yellow fill
highlight.OutlineColor = Color3.fromRGB(123, 43, 90)    -- Black outline
highlight.FillTransparency = .95                    -- Semi-transparent fill
highlight.OutlineTransparency = 0                   -- Solid outline
highlight.DepthMode = "AlwaysOnTop"

local old_nearest = nil
local function UpdateHighlight()
    if not nearest then
        if highlight.Parent then
            highlight.Adornee = nil
            highlight.Parent = nil
        end
        old_nearest = nil
        return
    end

    -- Target changed
    if nearest ~= old_nearest then
        highlight.Adornee = nearest
        highlight.Parent = nearest  -- or Workspace
        highlight.Enabled = true
        old_nearest = nearest
    end
end

-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- ================================================================ HEALTH FRAME =================================================================== --
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- Instances:

local KooScreen = Instance.new("ScreenGui")
local HPFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local HPBar = Instance.new("Frame")
local UICorner_2 = Instance.new("UICorner")
local HPFill = Instance.new("Frame")
local UICorner_3 = Instance.new("UICorner")
local HPF_Target = Instance.new("TextLabel")
local HPF_Distance = Instance.new("TextLabel")
local HPF_Health = Instance.new("TextLabel")
local UIGradient = Instance.new("UIGradient")

--Properties:

KooScreen.Name = "KooScreen"
KooScreen.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
KooScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
KooScreen.Enabled = false

HPFrame.Name = "HPFrame"
HPFrame.Parent = KooScreen
HPFrame.AnchorPoint = Vector2.new(0.5, 0.5)
HPFrame.BackgroundColor3 = Color3.fromRGB(25, 0, 40)
HPFrame.BorderSizePixel = 0
HPFrame.Position = UDim2.new(0.5, 0, 0.150000006, 0)
HPFrame.Size = UDim2.new(0, 377, 0, 136)

UICorner.CornerRadius = UDim.new(0, 18)
UICorner.Parent = HPFrame

HPBar.Name = "HPBar"
HPBar.Parent = HPFrame
HPBar.BackgroundColor3 = Color3.fromRGB(26, 0, 0)
HPBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
HPBar.BorderSizePixel = 0
HPBar.Position = UDim2.new(0.0778368264, 0, 0.400334865, 0)
HPBar.Size = UDim2.new(0, 318, 0, 42)

UICorner_2.CornerRadius = UDim.new(0, 15)
UICorner_2.Parent = HPBar

HPFill.Name = "HPFill"
HPFill.Parent = HPFrame
HPFill.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
HPFill.BorderColor3 = Color3.fromRGB(0, 0, 0)
HPFill.BorderSizePixel = 0
HPFill.Position = UDim2.new(0.0778368264, 0, 0.400334865, 0)
HPFill.Size = UDim2.new(0, 153, 0, 42)

UICorner_3.CornerRadius = UDim.new(0, 15)
UICorner_3.Parent = HPFill

HPF_Target.Name = "HPF_Target"
HPF_Target.Parent = HPFrame
HPF_Target.BackgroundTransparency = 1.000
HPF_Target.Position = UDim2.new(0.157953322, 0, 0.335468858, 0)
HPF_Target.Size = UDim2.new(0.684350133, 0, -0.264705896, 0)
HPF_Target.FontFace = Font.new(
	"rbxasset://fonts/families/FredokaOne.json", -- built-in font path
	Enum.FontWeight.Bold                          -- weight
)
HPF_Target.Text = "Corrupted Korth"
HPF_Target.TextColor3 = Color3.fromRGB(255, 255, 255)
HPF_Target.TextSize = 24.000
HPF_Target.TextWrapped = true

HPF_Distance.Name = "HPF_Distance"
HPF_Distance.Parent = HPFrame
HPF_Distance.BackgroundTransparency = 1.000
HPF_Distance.Position = UDim2.new(0.0778368264, 0, 0.864880621, 0)
HPF_Distance.Size = UDim2.new(0.843501329, 0, -0.132352948, 0)
HPF_Distance.FontFace = Font.new(
	"rbxasset://fonts/families/FredokaOne.json", -- built-in font path
	Enum.FontWeight.Bold                          -- weight
)
HPF_Distance.Text = "Distance: 100m"
HPF_Distance.TextColor3 = Color3.fromRGB(255, 255, 255)
HPF_Distance.TextScaled = true
HPF_Distance.TextSize = 14.000
HPF_Distance.TextWrapped = true

HPF_Health.Name = "HPF_Health"
HPF_Health.Parent = HPFrame
HPF_Health.BackgroundTransparency = 1.000
HPF_Health.Position = UDim2.new(0.109667063, 0, 0.62223357, 0)
HPF_Health.Size = UDim2.new(0.787798405, 0, -0.132352948, 0)
HPF_Health.FontFace = Font.new(
	"rbxasset://fonts/families/FredokaOne.json", -- built-in font path
	Enum.FontWeight.Bold                          -- weight
)
HPF_Health.Text = "HP 1000/1000 (100%)"
HPF_Health.TextColor3 = Color3.fromRGB(255, 255, 255)
HPF_Health.TextScaled = true
HPF_Health.TextSize = 14.000
HPF_Health.TextWrapped = true
HPF_Health.TextXAlignment = Enum.TextXAlignment.Left

UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(40, 10, 70)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(20, 0, 35))}
UIGradient.Rotation = 135
UIGradient.Parent = HPFrame

local currentTween = nil
local function UpdateHealthFrame()
    if not nearest then
        KooScreen.Enabled = false
        return
    end

    KooScreen.Enabled = true
    -- Target Name
    HPF_Target.Text = nearest.Name

    -- Distance
    local character = LocalPlayer.Character
    if nearest.PrimaryPart and character and character:FindFirstChild("HumanoidRootPart") then
        local dist = (nearest.PrimaryPart.Position - character.HumanoidRootPart.Position).Magnitude
        HPF_Distance.Text = string.format("Distance: %.1f m", dist)
    else
        HPF_Distance.Text = "Distance: N/A"
    end

    -- Health
    local health = nearest:FindFirstChild("Health")
    local maxHealth = nearest:GetAttribute("MaxHealth")
    local maxHealth_child = nearest:FindFirstChild("MaxHealth")
    if health and maxHealth ~= nil then
        local hp = health.Value
        local percent = (maxHealth > 0) and (hp / maxHealth * 100) or 0
        HPF_Health.Text = string.format("HP %d/%d (%.1f%%)", hp, maxHealth, percent)

        -- Update HP Fill
        local fillScale = math.clamp(hp / maxHealth, 0, 1)
        local targetSize = UDim2.new(fillScale * 0.8435, 0, 0, 42)
        if currentTween then currentTween:Cancel() end
        currentTween = TweenService:Create(HPFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize})
        currentTween:Play()
    elseif health and maxHealth_child then
        local hp = health.Value
        local maxH = maxHealth_child.Value
        local percent = (maxH > 0) and (hp / maxH * 100) or 0
        HPF_Health.Text = string.format("HP %d/%d (%.1f%%)", hp, maxH, percent)

        -- Update HP Fill
        local fillScale = math.clamp(hp / maxH, 0, 1)
        local targetSize = UDim2.new(fillScale * 0.8435, 0, 0, 42)
        if currentTween then currentTween:Cancel() end
        currentTween = TweenService:Create(HPFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize})
        currentTween:Play()
    else
        HPF_Health.Text = "HP N/A"
        HPFill.Size = UDim2.new(0, 0, 0, 42)
    end
end
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- ================================================================= AUTO ABILITY ================================================================== --
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
local UpgradeUIEnv
local canUpgrade = false
local Abilities = {
    Crit = "Critical Boost",
    Flame = "Flame Element",
    Frost = "Frost Element",
    Poison = "Poison Element",
    Recovery = "Recovery",
    Health = "Health Boost",
    Stamina = "Stamina",
    Agility = "Agility",
    Element = "Element Circle",
    Life = "Life Steal",
    RSpirit = "Rage Spirits",
    CSpirit = "Spirit Capacity",
    Thorns = "Thorns",
}
local AbilitySliders = {}
local function ChooseUpgrade(num)
    if not UpgradeUIEnv then return end
    UpgradeUIEnv.chooseUpgrade(num)
end
local function GetPriorities()
    local priorities = {}
    for ability, slider in pairs(AbilitySliders) do
        priorities[ability] = slider.Value
    end
    return priorities
end

local function AutoSelectAbility()
    if not UpgradeUIEnv then
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end

        local gameUI = pg:FindFirstChild("gameUI")
        if not gameUI then return end

        local upgradeFrame = gameUI:FindFirstChild("upgradeFrame")
        if not upgradeFrame then return end

        local UpgradeUI = upgradeFrame:FindFirstChild("upgradeUI")
        if not UpgradeUI then return end

        UpgradeUIEnv = getsenv(UpgradeUI)
    end
    local canSelect = UpgradeUIEnv.canSelect
    if not canSelect then return end

    local banners = UpgradeUIEnv.banners
    if not banners then return end

    local priorities = GetPriorities() -- ability key -> slider value

    local bestIndex = nil
    local bestPriority = -math.huge

    for i, banner in ipairs(banners) do
        local title = banner.title
        if title and title.Text then
            for key, name in pairs(Abilities) do
                -- Check if the banner text contains the ability name
                if string.find(title.Text, name, 1, true) then
                    local priority = priorities[key] or 0
                    if priority > bestPriority then
                        bestPriority = priority
                        bestIndex = i
                    end
                    break -- stop checking other abilities for this banner
                end
            end
        end
    end

    if bestIndex then
        ChooseUpgrade(bestIndex)
    end
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
    local Main_Priority = Main:AddRightGroupbox("Priority", "circle-alert")
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
        if not Value then KooScreen.Enabled = false return end
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
            if not Value then
                if highlight.Parent then
                    highlight.Adornee = nil
                    highlight.Parent = nil
                end
                old_nearest = nil
                return
            end
        end,
    })
    :AddColorPicker("HTO_ColorPicker", {
		Default = Library.Scheme.AccentColor or Color3.fromRGB(125, 85, 255),
		Title = "Outline for highlight", -- Optional. Allows you to have a custom color picker title (when you open it)
		Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

		Callback = function(Value)
			highlight.OutlineColor = Value
            highlight.OutlineTransparency = Options.HTO_ColorPicker.Transparency
		end,
	})
    Options.HTO_ColorPicker:SetValueRGB(Options.HTO_ColorPicker.Value)
-- ================================================================= Main_Utility =================================================================== --
    local ASA_Toggle_G = 0
    Main_Utility:AddToggle("ASA_Toggle", {
        Text = "Auto Select Abilities",
        Tooltip = "Automatically select abilities",
        DisabledTooltip = "I am disabled!",
        Default = false,
        Disabled = false,
        Visible = true,
        Risky = false,

        Callback = function(Value)
            ASA_Toggle_G += 1
            local myG = ASA_Toggle_G
            if not Value then return end

            task.spawn(function()
                while Toggles.ASA_Toggle.Value and ASA_Toggle_G == myG do
                    AutoSelectAbility()
                    task.wait(0.3)
                end
            end)
        end,
    })
    Main_Utility:AddButton("Open All Chest", function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local gameUI = playerGui and playerGui:FindFirstChild("gameUI")
        local armory = gameUI and gameUI:FindFirstChild("armory")
        local inventory = armory and armory:FindFirstChild("inventory")
        local clip = inventory and inventory:FindFirstChild("clip")
        local loots = clip and clip:FindFirstChild("Loot")

        if not loots then return end
        for i=1, 100 do
            for _, loot in ipairs(loots:GetChildren()) do
                local args = {
                    loot.Name,
                    1
                }
                Remotes:WaitForChild("openLoot"):InvokeServer(unpack(args))
            end
        end
    end)
-- ================================================================ Main_Priority =================================================================== --
    for ability, name in pairs(Abilities) do
        AbilitySliders[ability] = Main_Priority:AddSlider(ability, {
            Text = name,
            Default = 1,
            Min = 1,
            Max = 20,
            Rounding = 0,
            Suffix = "",
            Compact = true,

            Callback = function(Value)

            end,

            Tooltip = name .. " Priority", -- Information shown when you hover over the slider
            DisabledTooltip = "I am disabled!", -- Information shown when you hover over the slider while it's disabled

            Disabled = false, -- Will disable the slider (true / false)
            Visible = true, -- Will make the slider invisible (true / false)
        })
    end
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
        nearest = GetNear(targets)
        if Toggles.KA_Toggle.Value then
            -- Do KillAura
            UpdateHealthFrame()
            StartSwing()
            StartBlock()
        end
        if Toggles.WS_Toggle.Value then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = Options.WS_Speed.Value
            end
        end
        if Toggles.HT_Toggle.Value then
            UpdateHighlight()
        end
    end))
    worker:Start(CollectionService:GetInstanceAddedSignal("enemy"):Connect(function(instance)
        if instance.Name == "LocalKorth" or instance.Parent ~= Workspace then
            return
        end
        targets[instance] = true
    end))
    worker:Start(CollectionService:GetInstanceRemovedSignal("enemy"):Connect(function(instance)
        targets[instance] = nil
    end))
-- ===================================================================== UNLOAD ======================================================================= --
    Library:OnUnload(function()
        worker:StopAll()
        highlight:Destroy()
        KooScreen:Destroy()
        KA_Toggle_G = nil
    end)
end
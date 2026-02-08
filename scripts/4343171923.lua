-- Studlands
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- #region ======================= WORKER =======================
local Worker = {}
Worker.__index = Worker
function Worker.New() return setmetatable({_tasks = {}}, Worker) end
function Worker:Start(task)
    table.insert(self._tasks, task)
    return task
end
function Worker:StopAll()
    for i = #self._tasks, 1, -1 do
        local task = self._tasks[i]
        local t = typeof(task)
        if t == "RBXScriptConnection" then
            if task.Connected then task:Disconnect() end
        elseif t == "function" then
            task()
        elseif t == "Instance" then
            task:Destroy()
        elseif t == "table" and task.Destroy then
            task:Destroy()
        end
        self._tasks[i] = nil
    end
end
function Worker:Stop(_task)
    for i = #self._tasks, 1, -1 do
        local task = self._tasks[i]

        if task == _task then
            local t = typeof(task)

            if t == "RBXScriptConnection" then
                if task.Connected then task:Disconnect() end

            elseif t == "function" then
                task()

            elseif t == "Instance" then
                task:Destroy()
            elseif t == "table" and task.Destroy then
                task:Destroy()
            end

            table.remove(self._tasks, i)
            return true
        end
    end

    return false
end
local worker = Worker.New()
-- #endregion

-- #region ======================= COMBAT =======================
local NearestMob
local function GetNearestEnemy(radius)
    local character = LocalPlayer.Character
    if not character then return end
    local p_part = character.PrimaryPart
    if not p_part then return end
    local position = p_part.Position
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Whitelist
    params.FilterDescendantsInstances = {
        workspace.Areas
    }

    local parts = workspace:GetPartBoundsInRadius(position, radius, params)

    local closestModel
    local closestDist = math.huge

    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model then
            local hrp = model:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - position).Magnitude
                if d < closestDist then
                    closestDist = d
                    closestModel = model
                end
            end
        end
    end

    return closestModel
end
local ATTACK_DELAY = 0
local function StartAttack(dt)
    if ATTACK_DELAY <= 0.1 then
        ATTACK_DELAY = ATTACK_DELAY + dt
        return
    end
    ATTACK_DELAY = 0
    local clientRemotes = ReplicatedStorage:FindFirstChild("ClientRemotes")
    if not clientRemotes then return end

    local character = clientRemotes:FindFirstChild("Character")
    if not character then return end
    local useItem = character:FindFirstChild("UseItem")
    if not useItem then return end
    local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if not tool then return end
    local hitbox = tool:FindFirstChild("HitBox")
    if not hitbox then return end
    useItem:FireServer(tool, false)
    if NearestMob then
        firetouchinterest(hitbox, NearestMob.HumanoidRootPart, 1)
	    firetouchinterest(hitbox, NearestMob.HumanoidRootPart, 0)
    end

end

local function AttackRadius(radius)
    local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if not tool then return end
    local hitbox = tool:FindFirstChild("HitBox")
    if not hitbox then return end
    hitbox.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
end

local function GetRadius()
    local character = LocalPlayer.Character

    -- Get bounding box size
    local size = character:GetExtentsSize()

    -- Compute radius (largest axis / 2)
    local diameter = math.max(size.X, size.Y, size.Z)
    local radius = diameter / 2

    -- Round to nearest decimal
    local roundedRadius = math.round(radius * 10) / 10

    return roundedRadius
end
-- #endregion

-- #region ======================= VISUALS =======================
local function CreateRadiusSphere()
    local self = {}

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local p = Instance.new("MeshPart")
    p.Name = "AttackSphere"
    p.MeshId = "rbxassetid://2936644507"
    p.DoubleSided = true
    p.Size = Vector3.new(2, 2, 2) -- will be updated by SetRadius
    p.Anchored = false
    p.Massless = true
    p.CanCollide = false
    p.CanTouch = true
    p.CanQuery = false
    p.CastShadow = false
    p.Material = Enum.Material.SmoothPlastic
    p.Transparency = 0.7
    p.Parent = workspace
    p.CFrame = hrp.CFrame

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = p
    weld.Part1 = hrp
    weld.Parent = p

    function self:SetRadius(r) p.Size = Vector3.new(r * 2, r * 2, r * 2) end

    function self:SetColor(c) p.Color = c end

    function self:SetTransparency(t) p.Transparency = t end

    function self:Destroy() p:Destroy() end

    return self
end
local AttackSphere

local original = {
    Ambient = Lighting.Ambient,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    ColorShift_Top = Lighting.ColorShift_Top
}

local function ApplyFullBright()
    Lighting.Ambient = Color3.new(1, 1, 1)
    Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
    Lighting.ColorShift_Top = Color3.new(1, 1, 1)
end

local function ToggleFullBright(state)
    -- Optional explicit state override
    if state ~= nil then
        fullbrightEnabled = state
    else
        fullbrightEnabled = not fullbrightEnabled
    end

    if fullbrightEnabled then
        ApplyFullBright()

        -- Prevent multiple connections
        if not lightingConnection then
            lightingConnection = Lighting.LightingChanged:Connect(
                                     ApplyFullBright)
        end
    else
        -- Disable
        if lightingConnection then
            lightingConnection:Disconnect()
            lightingConnection = nil
        end

        -- Restore original lighting
        Lighting.Ambient = original.Ambient
        Lighting.ColorShift_Bottom = original.ColorShift_Bottom
        Lighting.ColorShift_Top = original.ColorShift_Top
    end
end
-- #endregion

-- #region ======================= INTERFACE =======================
return function(Window, Library)
    local Toggles = Library.Toggles
    local Options = Library.Options
    local Main = Window:AddTab("Main", "house")
    local Main_Combat = Main:AddLeftGroupbox("Combat", "swords")
    local Main_Movement = Main:AddLeftGroupbox("Movement", "footprints")
    local Main_Utility = Main:AddLeftGroupbox("Utility", "target")
    local Main_Visual = Main:AddRightGroupbox("Visual", "eye")

    -- #region ======================= Main_Combat =======================
    Main_Combat:AddToggle("SA_Toggle",
                          {Text = "Auto Attack", Tooltip = "Like Kill Aura"})
    Main_Combat:AddSlider("CAD_Slider", {
        Text = "Attack Distance",
        Tooltip = "In a form of a radius",
        Default = GetRadius(),
        Min = 1,
        Max = 100,
        Rounding = 0,
        Suffix = "studs",
        Compact = true
    })
    -- #endregion

    -- #region ======================= Main_Visual =======================
    Main_Visual:AddToggle("SR_Toggle", {
        Text = "Show Radius",
        Callback = function(value)
            if value then
                AttackSphere = worker:Start(CreateRadiusSphere())
            else
                if AttackSphere then
                    worker:Stop(AttackSphere)
                    AttackSphere = nil
                end
            end
        end
    }):AddColorPicker("SR_ColorPicker", {
        Default = Library.Scheme.AccentColor or Color3.fromRGB(125, 85, 255),
        Title = "Outline for highlight", -- Optional. Allows you to have a custom color picker title (when you open it)
        Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

        Callback = function(Value)
            if not Toggles.SR_Toggle.Value then return end
            if not AttackSphere then return end
            AttackSphere:SetRadius(Options.CAD_Slider.Value)
            AttackSphere:SetColor(Options.SR_ColorPicker.Value)
            AttackSphere:SetTransparency(Options.SR_ColorPicker.Transparency)
        end
    })
    Main_Visual:AddToggle("FB_Toggle", {
        Text = "FullBright",
        Tooltip = "Let there be LIGHT!",
        Callback = function(value) ToggleFullBright(value) end
    })
    Options.SR_ColorPicker:SetValueRGB(Options.SR_ColorPicker.Value)
    Options.CAD_Slider:OnChanged(function(value)
        if not AttackSphere then return end
        if Toggles.SR_Toggle.Value then
            AttackSphere:SetRadius(Options.CAD_Slider.Value)
            AttackSphere:SetColor(Options.SR_ColorPicker.Value)
            AttackSphere:SetTransparency(Options.SR_ColorPicker.Transparency)
        end
    end)
    Toggles.SR_Toggle:OnChanged(function(value)
        if not AttackSphere then return end
        if value then
            AttackSphere:SetRadius(Options.CAD_Slider.Value)
            AttackSphere:SetColor(Options.SR_ColorPicker.Value)
            AttackSphere:SetTransparency(Options.SR_ColorPicker.Transparency)
        end
    end)
    -- #endregion

    -- #region ======================= MY WORKER =======================
    worker:Start(RunService.Heartbeat:Connect(function(dt)
        NearestMob = GetNearestEnemy(Options.CAD_Slider.Value)
        if Toggles.SA_Toggle.Value then
            StartAttack(dt)
            AttackRadius(Options.CAD_Slider.Value)
        end
        if Toggles.SR_Toggle.Value then
            if not AttackSphere then Toggles.SR_Toggle:SetValue(true) end
        end
    end))
    -- #endregion

    -- #region ======================= UNLOAD =======================
    Library:OnUnload(function() worker:StopAll() end)
    -- #endregion
end
-- #endregion

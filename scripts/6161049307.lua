local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("remotes", 1)
local PlayerData
task.spawn(function()
    while not PlayerData do
        local PlayerDataPath = ReplicatedStorage:FindFirstChild("plrData")
        if PlayerDataPath then
            local ok, result = pcall(require, PlayerDataPath)
            if ok then
                PlayerData = result
                break
            end
        end
        task.wait(1) -- retry every second
    end
end)
local function FireProximity(prompt, player)
    -- executor does not provide fireproximityprompt
    if type(fireproximityprompt) ~= "function" then
        warn("[FireProximity] fireproximityprompt is not available in this executor")
        setclipboard("fireproximityprompt is not available in this executor")
        return false
    end

    -- try calling it safely
    local ok, err = pcall(function()
        fireproximityprompt(prompt, player)
    end)

    if not ok then
        warn("[FireProximity] fireproximityprompt exists but probably broken!")
        warn("[FireProximity] Error:", err)
        setclipboard("fireproximityprompt exists but probably broken! Error: "..tostring(err))
        return false
    end

    return true
end

-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- ============================================================== TELEPORT CONTROLLER ============================================================== --
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- REGION
    local TeleportController = {
        owner = nil,
        priority = -math.huge
    }

    function TeleportController:Acquire(owner, priority)
        if priority >= self.priority then
            self.owner = owner
            self.priority = priority
            return true
        end
        return false
    end

    function TeleportController:Release(owner)
        if self.owner == owner then
            self.owner = nil
            self.priority = -math.huge
        end
    end

    function TeleportController:CanTeleport(owner)
        return self.owner == owner
    end

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
local function GetEnemies()
    for _, inst in ipairs(CollectionService:GetTagged("enemy")) do
        if inst.Name == "LocalKorth" then continue end
        if not inst:IsDescendantOf(workspace) then continue end
        local maxHealth = inst:GetAttribute("MaxHealth")
        local maxHealthChild = inst:FindFirstChild("MaxHealth")
            -- Skip if neither exists
        if maxHealth == nil and maxHealthChild == nil then
            continue
        end
        targets[inst] = true
    end
end
GetEnemies()
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

local function TPNearest(cf)
    local character = LocalPlayer.Character
    if not character then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if TeleportController:Acquire("TPNearest", 1) then
        hrp.CFrame = cf + Vector3.new(0, 5, 0)
        TeleportController:Release("TPNearest")
    end
end

-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- =================================================================== AUTO FARM =================================================================== --
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- REGION
    local CurrentFarmZone = nil
    local initFarmZone = false
    local FarmState = {
        CLEARING = 0,
        MOVING = 1,
    }
    local CurrentFarmState = FarmState.MOVING

    local function flatten(v)
        return Vector3.new(v.X, 0, v.Z)
    end

    local function getOrderedFightZones()
        local zones = {}
        for _, model in ipairs(workspace:GetChildren()) do
            local fz = model:FindFirstChild("fightZone")
            if fz then
                table.insert(zones, fz)
            end
        end

        -- detect dominant axis
        local minX, maxX = math.huge, -math.huge
        local minZ, maxZ = math.huge, -math.huge
        for _, z in ipairs(zones) do
            minX = math.min(minX, z.Position.X)
            maxX = math.max(maxX, z.Position.X)
            minZ = math.min(minZ, z.Position.Z)
            maxZ = math.max(maxZ, z.Position.Z)
        end
        local axis = (maxZ - minZ) > (maxX - minX) and "Z" or "X"

        table.sort(zones, function(a, b)
            return a.Position[axis] < b.Position[axis]
        end)

        return zones, axis
    end

    local function EnemiesInZone(zone)
        if not zone then return {} end

        local zoneCFrame = zone.CFrame
        local size = zone.Size
        local halfSize = size / 2

        local enemiesHere = {}

        for _, enemy in ipairs(CollectionService:GetTagged("enemy")) do
            if enemy.PrimaryPart and enemy.Parent then
                local relativePos = zoneCFrame:PointToObjectSpace(enemy.PrimaryPart.Position)

                if math.abs(relativePos.X) <= halfSize.X and
                math.abs(relativePos.Y) <= halfSize.Y and
                math.abs(relativePos.Z) <= halfSize.Z then
                    table.insert(enemiesHere, enemy)
                end
            end
        end

        return enemiesHere
    end

    local function IsEnemyInZone(enemy, zone)
        if not enemy or not zone then
            return false
        end

        -- use visual center of the whole model
        local cf = enemy:GetBoundingBox()
        if not cf then
            return false
        end

        local rel = zone.CFrame:PointToObjectSpace(cf.Position)
        local half = zone.Size * 0.5
        local EPS = 0.2 -- small tolerance for border jitter

        return math.abs(rel.X) <= half.X + EPS
        and math.abs(rel.Y) <= half.Y + EPS
        and math.abs(rel.Z) <= half.Z + EPS
    end


    local function GetNextZone(fromZone)
        local zones = getOrderedFightZones()
        for i, z in ipairs(zones) do
            if z == fromZone then
                return zones[i + 1]
            end
        end
        return nil
    end

    local function GetCurrentZone()
        local character = LocalPlayer.Character
        if not character then return nil end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end

        local zones = getOrderedFightZones()
        local best, dist = nil, math.huge

        for _, z in ipairs(zones) do
            local d = (z.Position - hrp.Position).Magnitude
            if d < dist then
                dist = d
                best = z
            end
        end

        return best
    end

    local ActiveTweenS = nil

    local function AutoFarmTween(speed)
        local character = LocalPlayer.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- If already tweening, don't start another (prevents re-entry)
        if ActiveTweenS then return end

        if not TeleportController:Acquire("FarmTP", 2) then return end

        -- Find all fightZones and order them
        local zones = getOrderedFightZones()

        -- Find current zone (nearest)
        local currentZone = CurrentFarmZone or GetCurrentZone()
        if not currentZone then
            TeleportController:Release("FarmTP")
            return
        end

        -- Find next zone in order
        local nextZone = nil
        for i, z in ipairs(zones) do
            if z == currentZone then
                nextZone = zones[i + 1]
                break
            end
        end

        if not nextZone and not initFarmZone then
            nextZone = currentZone
            initFarmZone = true
        end

        if not nextZone then
            TeleportController:Release("FarmTP")
            CurrentFarmState = FarmState.CLEARING
            return
        end

        -- Two targets (no disconnect between them)
        local targets = {}

        if nextZone.Parent:FindFirstChild("Entrance") then
            table.insert(targets,
                nextZone.Parent.Entrance.Position
            )
        end

                if nextZone.Parent:FindFirstChild("FLOOR") then
            table.insert(targets,
                nextZone.Parent.FLOOR.Position
            )
        end

        if nextZone.Parent:FindFirstChild("Exit") then
            table.insert(targets,
                nextZone.Parent.Exit.Position
            )
        end


        -- fallback: if neither exists, use Tp like before
        if #targets == 0 and nextZone.Parent:FindFirstChild("Tp") then
            table.insert(targets,
                nextZone.Parent.Tp.Position
            )
        end


        local stage = 1
        local startPos = hrp.Position
        local endPos = targets[stage]
        local distance = (endPos - startPos).Magnitude
        if distance < 0.05 then distance = 0.05 end
        local elapsed = 0

        local oldCanCollide = hrp.CanCollide
        hrp.CanCollide = false

        ActiveTweenS = RunService.Heartbeat:Connect(function(dt)
            if not hrp.Parent then
                ActiveTweenS:Disconnect()
                ActiveTweenS = nil
                TeleportController:Release("FarmTP")
                return
            end

            elapsed += dt
            local alpha = math.clamp((elapsed * speed) / distance, 0, 1)

            local newPos = startPos:Lerp(endPos, alpha)
            hrp.CFrame = CFrame.new(newPos)

            if alpha >= 1 then
                -- Snap to exact target
                hrp.CFrame = CFrame.new(endPos)

                -- Advance to next stage OR finish
                stage += 1

                if stage <= #targets then
                    -- Setup next stage WITHOUT disconnecting (no gap!)
                    startPos = endPos
                    endPos = targets[stage]
                    distance = (endPos - startPos).Magnitude
                    if distance < 0.05 then distance = 0.05 end
                    elapsed = 0
                    return
                end

                -- Finished BOTH stages (end exactly like your original)
                hrp.CanCollide = oldCanCollide
                CurrentFarmState = FarmState.CLEARING
                TeleportController:Release("FarmTP")
                CurrentFarmZone = nextZone

                ActiveTweenS:Disconnect()
                ActiveTweenS = nil
            end
        end)
    end


    local function CheckZoneClear()
        if not CurrentFarmZone then return end

        if #EnemiesInZone(CurrentFarmZone) == 0 then
            CurrentFarmState = FarmState.MOVING
            AutoFarmTween(120)
        end
    end

    local function AutoReplayWorld()
        local vote = workspace:FindFirstChild("voting")
        if not vote then return end
        local gameEndVote = Remotes.gameEndVote
        if not vote.Value or not gameEndVote then return end
        gameEndVote:FireServer("replay")
    end

    local function NearestWatchdog()
        local currentTarget = nil
        local currentHealthObj = nil
        local lastHealth = nil
        local lastChange = os.clock()

        local function killLocal()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = 0
            end
        end

        return function(nearest)
            local now = os.clock()

            -- New real target appeared
            if nearest and nearest ~= currentTarget then
                currentTarget = nearest
                currentHealthObj = nil
                lastHealth = nil
                lastChange = now
            end

            -- Try to bind health if we have a target
            if currentTarget then
                if not currentHealthObj or currentHealthObj.Parent ~= currentTarget then
                    local h = currentTarget:FindFirstChild("Health")
                    if h and h:IsA("ValueBase") then
                        currentHealthObj = h
                        lastHealth = h.Value
                        lastChange = now
                    end
                end
            end

            -- Track health changes
            if currentHealthObj then
                local v = currentHealthObj.Value
                if v ~= lastHealth then
                    lastHealth = v
                    lastChange = now
                end
            end

            -- Timeout if no progress for 15s (even if nearest is nil)
            if now - lastChange >= 15 then
                killLocal()
                lastChange = now -- prevent spam
            end
        end
    end
    local NWatchdog = NearestWatchdog()
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- ================================================================== HIGHLIGHT ==================================================================== --
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- REGION
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
-- REGION
    local KooScreen = Instance.new("ScreenGui")
    local PerfFrame = Instance.new("Frame")
    local PingFrame = Instance.new("Frame")
    local UICorner = Instance.new("UICorner")
    local UIGradient = Instance.new("UIGradient")
    local PingText = Instance.new("TextLabel")
    local FPSFrame = Instance.new("Frame")
    local UICorner_2 = Instance.new("UICorner")
    local UIGradient_2 = Instance.new("UIGradient")
    local FPSText = Instance.new("TextLabel")
    local UIListLayout = Instance.new("UIListLayout")
    local HPFrame = Instance.new("Frame")
    local UICorner_3 = Instance.new("UICorner")
    local UIGradient_3 = Instance.new("UIGradient")
    local HPBar = Instance.new("Frame")
    local UICorner_4 = Instance.new("UICorner")
    local HPFill = Instance.new("Frame")
    local UICorner_5 = Instance.new("UICorner")
    local UIGradient_4 = Instance.new("UIGradient")
    local HPF_Target = Instance.new("TextLabel")
    local HPF_Health = Instance.new("TextLabel")
    local HPF_Distance = Instance.new("TextLabel")

    KooScreen.Name = "KooScreen"
    KooScreen.Parent = LocalPlayer:WaitForChild("PlayerGui")
    KooScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KooScreen.ResetOnSpawn = false
    KooScreen.IgnoreGuiInset = true

    PerfFrame.Name = "PerfFrame"
    PerfFrame.Parent = KooScreen
    PerfFrame.AnchorPoint = Vector2.new(1, 0)
    PerfFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    PerfFrame.BackgroundTransparency = 1.000
    PerfFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    PerfFrame.BorderSizePixel = 0
    PerfFrame.Position = UDim2.new(0.800000012, 0, 0.0599999987, 0)
    PerfFrame.Size = UDim2.new(0.170000002, 0, 0.0299999993, 0)

    PingFrame.Name = "PingFrame"
    PingFrame.Parent = PerfFrame
    PingFrame.AnchorPoint = Vector2.new(1, 0)
    PingFrame.BackgroundColor3 = Color3.fromRGB(22, 20, 35)
    PingFrame.BackgroundTransparency = 0.050
    PingFrame.BorderSizePixel = 0
    PingFrame.LayoutOrder = 2
    PingFrame.Position = UDim2.new(0.904682577, 0, 0.0118811959, 0)
    PingFrame.Size = UDim2.new(0.449999988, 0, 1, 0)

    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = PingFrame

    UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(160, 90, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(35, 25, 60))}
    UIGradient.Rotation = 90
    UIGradient.Parent = PingFrame

    PingText.Name = "PingText"
    PingText.Parent = PingFrame
    PingText.AnchorPoint = Vector2.new(0.5, 0.5)
    PingText.BackgroundTransparency = 1.000
    PingText.Position = UDim2.new(0.5, 0, 0.5, 0)
    PingText.Size = UDim2.new(0.800000012, 0, 0.800000012, 0)
    PingText.FontFace = Font.new(
        "rbxasset://fonts/families/FredokaOne.json", -- built-in font path
        Enum.FontWeight.Bold                          -- weight
    )
    PingText.Text = "Ping: 232345ms"
    PingText.TextColor3 = Color3.fromRGB(235, 235, 255)
    PingText.TextScaled = true
    PingText.TextSize = 14.000
    PingText.TextWrapped = true

    FPSFrame.Name = "FPSFrame"
    FPSFrame.Parent = PerfFrame
    FPSFrame.AnchorPoint = Vector2.new(1, 0)
    FPSFrame.BackgroundColor3 = Color3.fromRGB(22, 20, 35)
    FPSFrame.BackgroundTransparency = 0.050
    FPSFrame.BorderSizePixel = 0
    FPSFrame.LayoutOrder = 1
    FPSFrame.Position = UDim2.new(0.775458097, 0, 0.0126732644, 0)
    FPSFrame.Size = UDim2.new(0.449999988, 0, 1, 0)

    UICorner_2.CornerRadius = UDim.new(0, 10)
    UICorner_2.Parent = FPSFrame

    UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(110, 80, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(30, 25, 55))}
    UIGradient_2.Rotation = 90
    UIGradient_2.Parent = FPSFrame

    FPSText.Name = "FPSText"
    FPSText.Parent = FPSFrame
    FPSText.AnchorPoint = Vector2.new(0.5, 0.5)
    FPSText.BackgroundTransparency = 1.000
    FPSText.Position = UDim2.new(0.5, 0, 0.5, 0)
    FPSText.Size = UDim2.new(0.800000012, 0, 0.800000012, 0)
    FPSText.FontFace = Font.new(
        "rbxasset://fonts/families/FredokaOne.json", -- built-in font path
        Enum.FontWeight.Bold                          -- weight
    )
    FPSText.Text = "FPS: 120"
    FPSText.TextColor3 = Color3.fromRGB(235, 235, 255)
    FPSText.TextScaled = true
    FPSText.TextSize = 14.000
    FPSText.TextWrapped = true

    UIListLayout.Parent = PerfFrame
    UIListLayout.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween

    HPFrame.Name = "HPFrame"
    HPFrame.Parent = KooScreen
    HPFrame.AnchorPoint = Vector2.new(0.5, 0)
    HPFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 35)
    HPFrame.BackgroundTransparency = 0.040
    HPFrame.BorderSizePixel = 0
    HPFrame.Position = UDim2.new(0.5, 0, 0.0299999993, 0)
    HPFrame.Size = UDim2.new(0.187999994, 0, 0.140000001, 0)
    HPFrame.Visible = false

    UICorner_3.CornerRadius = UDim.new(0, 18)
    UICorner_3.Parent = HPFrame

    UIGradient_3.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(90, 60, 200)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(25, 20, 45))}
    UIGradient_3.Rotation = 135
    UIGradient_3.Parent = HPFrame

    HPBar.Name = "HPBar"
    HPBar.Parent = HPFrame
    HPBar.AnchorPoint = Vector2.new(0, 0.5)
    HPBar.BackgroundColor3 = Color3.fromRGB(45, 30, 30)
    HPBar.BorderSizePixel = 0
    HPBar.Position = UDim2.new(0.0500000007, 0, 0.5, 0)
    HPBar.Size = UDim2.new(0.899999976, 0, 0.25999999, 0)

    UICorner_4.CornerRadius = UDim.new(0, 14)
    UICorner_4.Parent = HPBar

    HPFill.Name = "HPFill"
    HPFill.Parent = HPBar
    HPFill.AnchorPoint = Vector2.new(0, 0.5)
    HPFill.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    HPFill.BorderSizePixel = 0
    HPFill.Position = UDim2.new(0, 0, 0.5, 0)
    HPFill.Size = UDim2.new(0.45, 0, 1, 0)

    UICorner_5.CornerRadius = UDim.new(0, 14)
    UICorner_5.Parent = HPFill

    UIGradient_4.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 80, 80)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(150, 10, 10))}
    UIGradient_4.Parent = HPFill

    HPF_Target.Name = "HPF_Target"
    HPF_Target.Parent = HPFrame
    HPF_Target.AnchorPoint = Vector2.new(0.5, 0)
    HPF_Target.BackgroundTransparency = 1.000
    HPF_Target.Position = UDim2.new(0.5, 0, 0.0799999982, 0)
    HPF_Target.Size = UDim2.new(0.899999976, 0, 0.219999999, 0)
    HPF_Target.FontFace = Font.new(
        "rbxasset://fonts/families/FredokaOne.json", -- built-in font path
        Enum.FontWeight.Bold                          -- weight
    )
    HPF_Target.Text = "Korth"
    HPF_Target.TextColor3 = Color3.fromRGB(245, 245, 255)
    HPF_Target.TextScaled = true
    HPF_Target.TextSize = 22.000
    HPF_Target.TextWrapped = true

    HPF_Health.Name = "HPF_Health"
    HPF_Health.Parent = HPFrame
    HPF_Health.AnchorPoint = Vector2.new(0, 0.5)
    HPF_Health.BackgroundTransparency = 1.000
    HPF_Health.Position = UDim2.new(0.0928340703, 0, 0.5, 0)
    HPF_Health.Size = UDim2.new(0.839999974, 0, 0.180000007, 0)
    HPF_Health.Font = Enum.Font.GothamMedium
    HPF_Health.Text = "HP 100000 / 100000 (100%)"
    HPF_Health.TextColor3 = Color3.fromRGB(210, 210, 230)
    HPF_Health.TextScaled = true
    HPF_Health.TextSize = 14.000
    HPF_Health.TextWrapped = true
    HPF_Health.TextXAlignment = Enum.TextXAlignment.Left

    HPF_Distance.Name = "HPF_Distance"
    HPF_Distance.Parent = HPFrame
    HPF_Distance.AnchorPoint = Vector2.new(0.5, 1)
    HPF_Distance.BackgroundTransparency = 1.000
    HPF_Distance.Position = UDim2.new(0.5, 0, 0.899999976, 0)
    HPF_Distance.Size = UDim2.new(0.879999995, 0, 0.150000006, 0)
    HPF_Distance.Font = Enum.Font.GothamMedium
    HPF_Distance.Text = "Distance: 100m"
    HPF_Distance.TextColor3 = Color3.fromRGB(170, 170, 210)
    HPF_Distance.TextScaled = true
    HPF_Distance.TextSize = 14.000
    HPF_Distance.TextWrapped = true

    local currentTween = nil
    local function UpdateHealthFrame()
        if not nearest then
            HPFrame.Visible = false
            return
        end

        HPFrame.Visible = true
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
            local hp = math.max(health.Value, 0) -- never below 0
            local percent = (maxHealth > 0) and (hp / maxHealth * 100) or 0
            HPF_Health.Text = string.format("HP %d/%d (%.1f%%)", hp, maxHealth, percent)

            -- Update HP Fill
            local fillScale = math.clamp(hp / maxHealth, 0, 1)
            local targetSize = UDim2.fromScale(fillScale, 1) -- full height, scaled X

            if currentTween then currentTween:Cancel() end
            currentTween = TweenService:Create(HPFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize})
            currentTween:Play()
        elseif health and maxHealth_child then
            local hp = math.max(health.Value, 0) -- never below 0
            local maxH = maxHealth_child.Value
            local percent = (maxH > 0) and (hp / maxH * 100) or 0
            HPF_Health.Text = string.format("HP %d/%d (%.1f%%)", hp, maxH, percent)

            -- Update HP Fill
            local fillScale = math.clamp(hp / maxH, 0, 1)
            local targetSize = UDim2.fromScale(fillScale, 1) -- full height, scaled X

            if currentTween then currentTween:Cancel() end
            currentTween = TweenService:Create(HPFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize})
            currentTween:Play()
        else
            HPF_Health.Text = "HP N/A"
            HPFill.Size = UDim2.new(0, 0, 0, 100)
        end
    end
    local fpsSmooth = 60 -- initial guess
    local function UpdatePerformance(dt)
        -- Update Ping
        local ping = LocalPlayer:GetNetworkPing() * 1000 -- convert to ms
        PingText.Text = string.format("Ping: %d ms", ping)

        -- Update FPS
        local fps = 1 / dt
        fpsSmooth = fpsSmooth * 0.9 + fps * 0.1
        FPSText.Text = string.format("FPS: %d", math.floor(fpsSmooth))
    end
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- ================================================================= AUTO ABILITY ================================================================== --
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- REGION
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
    local function AutoSelectAbility_v2()
        if type(UpgradeUIEnv) == "table" and #UpgradeUIEnv > 0 then return end
        local plrUpgrade = Remotes:FindFirstChild("plrUpgrade")
        if not plrUpgrade then return end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end

        local gameUI = pg:FindFirstChild("gameUI")
        if not gameUI then return end

        local ui = gameUI:FindFirstChild("upgradeFrame")
        if not ui then return end
        ui.Visible = false
        local banners = {ui.LeftBanner.BannerCover.Banner, ui.MiddleBanner.BannerCover.Banner, ui.RightBanner.BannerCover.Banner}
        local priorities = GetPriorities() -- ability key -> slider value

        local bestIndex = nil
        local bestPriority = -math.huge
        Lighting.deathBlur.Enabled = true
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
            Lighting.deathBlur.Enabled = false
            plrUpgrade:FireServer(bestIndex)
        end
    end

-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- ================================================================= OMINOUS CHEST ================================================================= --
-- ================================================================================================================================================= --
-- ================================================================================================================================================= --
-- REGION
    local isOminousClaim = false
    local initvariant = false
    local function NoCooldownPrompt(prompt)
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = math.huge
        prompt.Enabled = true
    end

    local function AutoClaimOminous(tpf_toggle)
        local function cleanup()
            TeleportController:Release("Ominous")
        end
        if nearest and tpf_toggle then cleanup() return end
        local character = LocalPlayer.Character
        if not character then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- borrow teleport control ONLY
        if not TeleportController:Acquire("Ominous", 3) then
            return
        end

        local castle_entrance = workspace:FindFirstChild("CastleEntrance")
        if castle_entrance then
            local key = castle_entrance:FindFirstChild("GoldKey")
            if key and TeleportController:CanTeleport("Ominous") then
                hrp.CFrame = key.CFrame

                local g_clyde = castle_entrance:FindFirstChild("GhostClyde")
                local g_clyde_hrp = g_clyde and g_clyde:FindFirstChild("HumanoidRootPart")
                local proximity = g_clyde_hrp and g_clyde_hrp:FindFirstChildOfClass("ProximityPrompt")

                if not g_clyde or not g_clyde_hrp or not proximity then
                    cleanup()
                    return
                end
                NoCooldownPrompt(proximity)
                FireProximity(proximity, LocalPlayer)
                return
            end
        end

        local puzzle_variant = workspace:FindFirstChild("puzzleVariant")
        if not puzzle_variant then
            cleanup()
            return
        end

        local pzvStart = puzzle_variant:FindFirstChild("puzzleStart")
        local pzvZone  = puzzle_variant:FindFirstChild("StartPuzzleZone")
        local pvzChest = puzzle_variant:FindFirstChild("End") and puzzle_variant.End:FindFirstChild("Chest")

        if pzvStart and pzvZone and not initvariant then
            hrp.CFrame = pzvStart.CFrame + Vector3.new(0, 5, 0)
            task.wait(0.5)
            hrp.CFrame = pzvZone.CFrame + Vector3.new(0, 5, 0)
            task.wait(0.5)
            initvariant = true
            return
        end

        if pvzChest and initvariant then
            local cf = pvzChest:GetBoundingBox()

            -- position 5 studs in front of the chest
            local pos = (cf * CFrame.new(0, 0, -5)).Position

            -- make the player face the chest
            hrp.CFrame = CFrame.lookAt(pos, cf.Position)


            local prompt = pvzChest:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                NoCooldownPrompt(prompt)
                FireProximity(prompt, LocalPlayer)
            end
            return
        end

        if not pvzChest then
            local tp = puzzle_variant:FindFirstChild("Tp")
            if tp then
                hrp.CFrame = tp.CFrame
                isOminousClaim = true
                initvariant = false
                cleanup()
            end
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
    local Main_Utility = Main:AddLeftGroupbox("Utility", "target")
    local Main_Visual = Main:AddRightGroupbox("Visual", "eye")
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
        if not Value then
            if HPFrame then HPFrame.Visible = false end
            return
        end
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
    Main_Combat:AddDivider("Teleport")
    local TPF_Toggle_G = 0
    Main_Combat:AddToggle("TPF_Toggle", {
        Text = "TP Farm",
        Tooltip = "Auto Farm",
        DisabledTooltip = "I am disabled!",

        Default = false,
        Disabled = false,
        Visible = true,
        Risky = true,

        Callback = function(Value)
            TPF_Toggle_G += 1
            local myG = TPF_Toggle_G

            -- TURN OFF
            if not Value then
                if ActiveTweenS then
                    ActiveTweenS:Disconnect()
                    ActiveTweenS = nil
                end

                CurrentFarmZone = nil
                initFarmZone = false
                TeleportController:Release("FarmTP")
                return
            end

            task.spawn(function()
                while Toggles.TPF_Toggle.Value and myG == TPF_Toggle_G do
                    if not CurrentFarmZone and not initFarmZone then
                        CurrentFarmState = FarmState.MOVING
                        AutoFarmTween(120)
                    end
                    if CurrentFarmState ~= FarmState.MOVING then
                        task.wait(0.1)
                        continue
                    end
                    CheckZoneClear()
                    task.wait(1)
                end
            end)
        end,
    })
    Main_Combat:AddToggle("AR_Toggle", {
        Text = "Auto Replay World",
        Tooltip = "Auto Replay Current World",
        DisabledTooltip = "I am disabled!",

        Default = false,
        Disabled = false,
        Visible = true,
        Risky = false,

        Callback = function(Value)

        end,
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
                    AutoSelectAbility_v2()
                    task.wait(0.01)
                end
            end)
        end,
    })
    Main_Utility:AddDivider("Inventory")
    local OpenChest_G = false
    Main_Utility:AddButton("Open All Chest", function()
        -- guard: prevent multiple spawns
        if OpenChest_G then return end
        OpenChest_G = true

        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local gameUI = playerGui and playerGui:FindFirstChild("gameUI")
        local armory = gameUI and gameUI:FindFirstChild("armory")
        local inventory = armory and armory:FindFirstChild("inventory")
        local clip = inventory and inventory:FindFirstChild("clip")
        local loots = clip and clip:FindFirstChild("Loot")
        local openLoot = Remotes:FindFirstChild("openLoot")
        if not loots or not openLoot then
            OpenChest_G = false
            return
        end

        task.spawn(function()
            while true and OpenChest_G do
                local hasLoot = false
                for _, loot in ipairs(loots:GetChildren()) do
                    if loot:FindFirstChild("copies") then
                        hasLoot = true
                        local str_amount = loot.copies.Text
                        local amount = tonumber(str_amount) or 1
                        openLoot:InvokeServer(loot.Name, amount)
                    end
                end

                if not hasLoot then
                    OpenChest_G = false -- release guard when finished
                    break
                end

                task.wait(0.5) -- pacing
            end
        end)
    end)

    local OpenRings_G = false
    Main_Utility:AddButton("Open All Rings", function()
        -- 🔒 HARD LOCK
        if OpenRings_G then return end
        OpenRings_G = true

        if not PlayerData then
            OpenRings_G = false
            return
        end

        local unveilRing = Remotes:FindFirstChild("unveilRing")
        if not unveilRing then
            OpenRings_G = false
            return
        end

        task.spawn(function()
            -- Open normal rings
            while true and OpenRings_G do
                local normal = PlayerData:GetValue(LocalPlayer, "Rings")
                if not normal or normal <= 0 then
                    break
                end

                unveilRing:InvokeServer("Normal")
                task.wait(0.01)
            end

            -- Open super rings
            while true and OpenRings_G do
                local super = PlayerData:GetValue(LocalPlayer, "SuperRings")
                if not super or super <= 0 then
                    break
                end

                unveilRing:InvokeServer("Super")
                task.wait(0.01)
            end

            -- 🔓 UNLOCK ONLY AFTER EVERYTHING FINISHES
            OpenRings_G = false
        end)
    end)
    
    local ACO_Toggle_G = 0
    Main_Utility:AddToggle("ACO_Toggle", {
        Text = "Auto Claim Ominous Chest",
        Tooltip = "Automatically claim ominous chests",
        DisabledTooltip = "Chest Claimed!",

        Default = false,
        Disabled = false,
        Visible = true,
        Risky = false,

        Callback = function(Value)
            ACO_Toggle_G += 1
            local myG = ACO_Toggle_G
            if not Value then return end

            task.spawn(function()
                while Toggles.ACO_Toggle.Value and myG == ACO_Toggle_G do
                    AutoClaimOminous(Toggles.TPF_Toggle.Value)
                    task.wait(0.01)
                    if isOminousClaim then
                        Toggles.ACO_Toggle:SetValue(false)
                        Toggles.ACO_Toggle:SetDisabled(true)
                    end
                end
            end)
        end,
    })

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
        UpdatePerformance(delta_time)
        UpdateHealthFrame()
        GetEnemies()
        if Toggles.TPF_Toggle.Value then
            NWatchdog(nearest)
        end
        if Toggles.TPF_Toggle.Value and CurrentFarmZone then
            if nearest then
                if IsEnemyInZone(nearest, CurrentFarmZone) then
                    TPNearest(nearest:GetBoundingBox())
                else
                    CurrentFarmState = FarmState.MOVING
                end
            else
                CurrentFarmState = FarmState.MOVING
            end
        end

        if Toggles.KA_Toggle.Value then
            -- Do KillAura
            StartSwing()
            StartBlock()
        end
        if Toggles.AR_Toggle.Value then
            AutoReplayWorld()
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
        if instance.Name == "LocalKorth" then
            return
        end
        if not instance:IsDescendantOf(workspace) then
            return
        end
        local maxHealth = instance:GetAttribute("MaxHealth")
        local maxHealthChild = instance:FindFirstChild("MaxHealth")

        -- Skip if neither exists
        if maxHealth == nil and maxHealthChild == nil then
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
        if highlight then
            highlight:Destroy()
            highlight = nil
        end
        if ActiveTweenS then
            ActiveTweenS:Disconnect()
        end
        if KooScreen then
            KooScreen:Destroy()
            KooScreen = nil
        end
        OpenRings_G = false
        OpenChest_G = false
        KA_Toggle_G = nil
        ACO_Toggle_G = nil
        ASA_Toggle_G = nil
        TPF_Toggle_G = nil
    end)
end
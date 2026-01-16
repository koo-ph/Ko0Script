local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local function GetNear()
    local character = LocalPlayer.Character
    if not character then
        nearest = nil
        return {}
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        nearest = nil
        return {}
    end

    local targets = {}           -- store {Parent, distSq} temporarily
    local nearestDistSq = math.huge
    local nearestParent = nil

    -- Iterate over all descendants (supports nested models)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") then
            local parent = obj.Parent
            local health = parent and parent:FindFirstChild("Health")
            local primary = parent and parent.PrimaryPart
            if health and primary and health.Value > 0 then
                local diff = primary.Position - hrp.Position
                local distSq = diff.X*diff.X + diff.Y*diff.Y + diff.Z*diff.Z

                -- Keep track of nearest for quick access
                if distSq < nearestDistSq then
                    nearestDistSq = distSq
                    nearestParent = parent
                end

                -- Store for sorting later
                table.insert(targets, {Parent = parent, DistSq = distSq})
            end
        end
    end

    -- Sort targets by distance squared (ascending)
    table.sort(targets, function(a, b)
        return a.DistSq < b.DistSq
    end)

    -- Update global nearest
    nearest = nearestParent

    -- Return only parents, sorted
    local sortedParents = {}
    for i, entry in ipairs(targets) do
        sortedParents[i] = entry.Parent
    end

    return sortedParents
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
local function KillAura(target)
    local onHit = Remotes:FindFirstChild("onHit")
    if not onHit or not target:FindFirstChild("Humanoid") then return end

    onHit:FireServer(
        target.Humanoid,
        9999,
        {},
        0
    )
end
-- ================================================================== UI =================================================================== --
return function(Window, Library)
    version = "1.0.0"
    print("Ko0 Hub: " .. version)
    local Toggles = Library.Toggles
    local Options = Library.Options
    local HeartbeatConn

    local Main = Window:AddTab("Main", "house")
    local Main_Combat = Main:AddLeftGroupbox("Combat", "swords")

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
                    for _,target in pairs(GetNear()) do
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
        Min = 0.1,
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

-- ================================================================== HEARTBEAT =================================================================== --
    HeartbeatConn = RunService.Heartbeat:Connect(function(delta_time)
        if Toggles.KA_Toggle.Value then
            -- Do KillAura
            StartSwing()
            StartBlock()
        end
    end)

    Library:OnUnload(function()
        if HeartbeatConn then HeartbeatConn:Disconnect() HeartbeatConn = nil end
    end)
end

--- THIS IS A FUNCTIONS
-- local args = {
-- 	1
-- }
-- game:GetService("ReplicatedStorage"):WaitForChild("remotes"):WaitForChild("plrUpgrade"):FireServer(unpack(args))


local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Systems = ReplicatedStorage.Systems

-- ================================================================== KillAura =================================================================== --
local function GetNear(max_dist, max_count)
    local path1 = workspace:WaitForChild("Mobs")
    local candidates = {}
    for _, enemy in pairs (path1:GetChildren()) do
        if enemy.PrimaryPart then
            local distance = (enemy.PrimaryPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distance <= max_dist then
                table.insert(candidates, {enemy = enemy, distance = distance})
            end
        end
    end
    table.sort(candidates, function(a, b)
        return a.distance < b.distance
    end)

    local topTargets = {}
    for i = 1, math.min(max_count, #candidates) do
        table.insert(topTargets, candidates[i].enemy)
    end

    return topTargets
end

local function Damage(target)
    Systems.Combat.PlayerAttack:FireServer(target)
end

local function KillAura(max_dist, max_count)
    local character = LocalPlayer.Character
    if not character or not character.PrimaryPart then return end
    local pos = character.PrimaryPart.Position

    local targets = GetNear(max_dist, max_count)
    Damage(targets)
end
local function PlayerAura()
end

-- ================================================================== UI =================================================================== --
return function(Window, Library)
    local Toggles = Library.Toggles
    local Options = Library.Options
    local HeartbeatConn

    local Main = Window:AddTab("Main", "house")
    local Main_Combat = Main:AddLeftGroupbox("Combat", "swords")

    Main_Combat:AddToggle("KA_Toggle", {
        Text = "Kill Aura",
        Tooltip = "Toggle Kill Aura",
        DisabledTooltip = "I am disabled!",

        Default = false,
        Disabled = false,
        Visible = true,
        Risky = true,

        Callback = function(Value)
        end,
    })

    KillAuraTick = 0
    HeartbeatConn = RunService.Heartbeat:Connect(function(delta_time)
        if Toggles.KA_Toggle.Value then
            KillAuraTick += delta_time
            if KillAuraTick >= 0.25 then
                KillAuraTick = 0
                KillAura(10,5)
            end
        end
    end)

    Library:OnUnload(function()
        if HeartbeatConn then HeartbeatConn:Disconnect() HeartbeatConn = nil end
    end)
end
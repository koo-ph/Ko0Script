local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Systems = ReplicatedStorage.Systems

-- ================================================================== KillAura =================================================================== --
local path = workspace:WaitForChild("Mobs")
local function GetNearest(pos, count, list)
    local nearest = {}           -- stores {mob = ..., dist2 = ...}

    for _,mob in pairs(list:GetChildren()) do
        local root = mob.PrimaryPart
        if root then
            local d2 = (root.Position - pos).Magnitude^2

            if #nearest < count then
                table.insert(nearest, {mob = mob, dist2 = d2})
            else
                -- find the farthest in current nearest
                local worstIdx = 1
                for i = 2, #nearest do
                    if nearest[i].dist2 > nearest[worstIdx].dist2 then
                        worstIdx = i
                    end
                end
                if d2 < nearest[worstIdx].dist2 then
                    nearest[worstIdx] = {mob = mob, dist2 = d2}
                end
            end
        end
    end

    -- Extract only the mob objects
    local result = {}
    for _, v in ipairs(nearest) do
        table.insert(result, v.mob)
    end
    return result
end

local function Damage(target)
    Systems.Combat.PlayerAttack:FireServer(target)
end

local function KillAura(max_count)
    local character = LocalPlayer.Character
    if not character or not character.PrimaryPart then return end
    local pos = character.PrimaryPart.Position

    local targets = GetNearest(pos, max_count, path)
    for _,target in pairs(targets) do
        Damage(target)
    end
end
local function PlayerAura()
end

-- ================================================================== UI =================================================================== --
return function(Window, Library)
    print("loaded")
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
            if KillAuraTick >= 0.1 then
                KillAuraTick = 0
                KillAura(5)
            end
        end
    end)

    Library:OnUnload(function()
        if HeartbeatConn then HeartbeatConn:Disconnect() HeartbeatConn = nil end
    end)
end
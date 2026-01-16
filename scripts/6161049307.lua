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
local nearest
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

	local distanceTable = {}

	for _, humanoid in ipairs(workspace:GetDescendants()) do
		if humanoid:IsA("Humanoid") then
			local parent = humanoid.Parent
			if parent and parent:FindFirstChild("Health") then
				local primary = parent.PrimaryPart
				if primary then
					local distance = (primary.Position - hrp.Position).Magnitude

					table.insert(distanceTable, {
						Parent = parent,
						Distance = distance
					})
				end
			end
		end
	end

	table.sort(distanceTable, function(a, b)
		return a.Distance < b.Distance
	end)

	-- populate global nearest
	nearest = distanceTable[1] and distanceTable[1].Parent or nil

	-- return only parents, sorted
	local sortedParents = {}
	for i, entry in ipairs(distanceTable) do
		sortedParents[i] = entry.Parent
	end

	return sortedParents
end

local function StartSwing()
    local swing = Remotes:FindFirstChild("swing")
    if not swing then return end

    swing:FireServer()
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


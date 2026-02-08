-- Infinity RPG
-- Studlands
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local RemoteService

-- #region ======================= HELPER =======================
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
		setclipboard("fireproximityprompt exists but probably broken! Error: " .. tostring(err))
		return false
	end

	return true
end
-- #endregion

-- #region ======================= WORKER =======================
local Worker = {}
Worker.__index = Worker
function Worker.New()
	return setmetatable({ _tasks = {} }, Worker)
end
function Worker:Start(task)
	table.insert(self._tasks, task)
	return task
end
function Worker:StartThread(fn)
	local alive = true
	task.spawn(function()
		fn(function()
			return alive
		end)
	end)

	return self:Start(function()
		alive = false
	end)
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
				if task.Connected then
					task:Disconnect()
				end
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

-- #region ======================= SCRIPTS =======================
local ModuleManager = {}
ModuleManager._cache = {}
ModuleManager._pending = {}
function ModuleManager:Get(module)
	-- Reject invalid inputs
	if typeof(module) ~= "Instance" or not module:IsA("ModuleScript") then
		return nil
	end

	-- Already loaded
	local cached = self._cache[module]
	if cached ~= nil then
		return cached
	end

	-- Already loading
	if self._pending[module] then
		return nil
	end

	self._pending[module] = true

	task.spawn(function()
		local ok, result = pcall(require, module)
		if ok then
			self._cache[module] = result
		end
		self._pending[module] = nil
	end)

	return nil
end

function ModuleManager:IsReady(module)
	return self._cache[module] ~= nil
end
-- #endregion

-- #region ======================= COMBAT =======================
local NearestMob
local NearestMobByTag
local NearestMobs = {}
local NearestMobsByTag = {}
local function GetNearestEnemy(radius)
	local character = LocalPlayer.Character
	if not character then
		return
	end
	local p_part = character.PrimaryPart
	if not p_part then
		return
	end
	local position = p_part.Position
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Whitelist
	params.FilterDescendantsInstances = { workspace.Mobs }

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
local function GetNearestEnemies(radius)
	local character = LocalPlayer.Character
	if not character then
		return {}
	end

	local p_part = character.PrimaryPart
	if not p_part then
		return {}
	end

	local position = p_part.Position

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Whitelist
	params.FilterDescendantsInstances = { workspace.Mobs }

	local parts = workspace:GetPartBoundsInRadius(position, radius, params)

	local seen = {}
	local enemies = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not seen[model] then
			if model:FindFirstChild("HumanoidRootPart") then
				seen[model] = true
				table.insert(enemies, model)
			end
		end
	end

	return enemies
end
local function GetNearestsByTags(radius, tag)
	local root = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
	if not root then
		return {}
	end

	local pos = root.Position
	local r2 = radius * radius
	local out = {}

	for _, mob in ipairs(CollectionService:GetTagged(tag)) do
		local hrp = mob:FindFirstChild("HumanoidRootPart")
		if hrp then
			local diff = hrp.Position - pos
			local dist2 = diff:Dot(diff)

			if dist2 <= r2 then
				out[#out + 1] = { Model = mob, Dist = dist2 }
			end
		end
	end

	table.sort(out, function(a, b)
		return a.Dist < b.Dist -- nearest first
	end)

	-- strip distances, return only models
	for i = 1, #out do
		out[i] = out[i].Model
	end

	return out
end
local function GetAllByTagsSorted(tag)
	local root = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
	if not root then
		return {}
	end

	local pos = root.Position
	local out = {}

	for _, mob in ipairs(CollectionService:GetTagged(tag)) do
		local hrp = mob:FindFirstChild("HumanoidRootPart")
		if hrp then
			local diff = hrp.Position - pos
			out[#out + 1] = { Model = mob, Dist = diff:Dot(diff) }
		end
	end

	table.sort(out, function(a, b)
		return a.Dist < b.Dist
	end)

	-- Strip distance, return only models
	for i = 1, #out do
		out[i] = out[i].Model
	end

	return out
end

local function StartKillAura()
	local rs = ModuleManager:Get(ReplicatedStorage.Modules.Shared.RemoteService)
	if not rs then
		return -- skip this tick, script continues next frame
	end

	-- rs is now guaranteed to be loaded and cached
	rs:InvokeServer("Damage", NearestMobsByTag)
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
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Transparency = 0.7
	p.Parent = char
	p.CFrame = hrp.CFrame

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p
	weld.Part1 = hrp
	weld.Parent = p

	p.Destroying:Connect(function()
		p = nil
	end)

	function self:SetRadius(r)
		p.Size = Vector3.new(r * 2, r * 2, r * 2)
	end

	function self:SetColor(c)
		p.Color = c
	end

	function self:SetTransparency(t)
		p.Transparency = t
	end

	function self:GetInstance()
		return p
	end

	function self:Destroy()
		p:Destroy()
	end

	return self
end
local AttackSphere

local original = {
	Ambient = Lighting.Ambient,
	ColorShift_Bottom = Lighting.ColorShift_Bottom,
	ColorShift_Top = Lighting.ColorShift_Top,
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
			lightingConnection = Lighting.LightingChanged:Connect(ApplyFullBright)
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

-- #region ======================= UTILITY =======================
local ArtifactWorker
local function CollectArtifact()
	local Advanced = workspace:FindFirstChild("Advanced")
	if not Advanced then
		return
	end
	local Artifacts = Advanced:FindFirstChild("Artifacts")
	if not Artifacts then
		return
	end
	for i, v in ipairs(Artifacts:GetDescendants()) do
		if not v:IsA("ProximityPrompt") then
			continue
		end
		FireProximity(v, LocalPlayer)
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
	Main_Combat:AddToggle("KA_Toggle", { Text = "Kill Aura" })
	Main_Combat:AddSlider("CAD_Slider", {
		Text = "Aura Distance",
		Tooltip = "In a form of a radius",
		Default = 50,
		Min = 1,
		Max = 100,
		Rounding = 0,
		Suffix = "studs",
		Compact = true,
		DisabledTooltip = "Disable No Distance!",
	})
	Main_Combat:AddToggle("ND_Toggle", { Text = "No Distance" })
	-- #endregion

	-- #region ======================= Main_Visual =======================
	Main_Visual:AddToggle("SR_Toggle", {
		Text = "Show Radius",
		DisabledTooltip = "Disable No Distance!",
		Callback = function(value)
			if value then
				AttackSphere = worker:Start(CreateRadiusSphere())
			else
				if AttackSphere then
					worker:Stop(AttackSphere)
					AttackSphere = nil
				end
			end
		end,
	}):AddColorPicker("SR_ColorPicker", {
		Default = Library.Scheme.AccentColor or Color3.fromRGB(125, 85, 255),
		Title = "Outline for highlight", -- Optional. Allows you to have a custom color picker title (when you open it)
		Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

		Callback = function(Value)
			if not Toggles.SR_Toggle.Value then
				return
			end
			if not AttackSphere then
				return
			end
			AttackSphere:SetRadius(Options.CAD_Slider.Value)
			AttackSphere:SetColor(Options.SR_ColorPicker.Value)
			AttackSphere:SetTransparency(Options.SR_ColorPicker.Transparency)
		end,
	})
	Main_Visual:AddToggle("FB_Toggle", {
		Text = "FullBright",
		Tooltip = "Let there be LIGHT!",
		Callback = function(value)
			ToggleFullBright(value)
		end,
	})
	Options.SR_ColorPicker:SetValueRGB(Options.SR_ColorPicker.Value)
	Options.CAD_Slider:OnChanged(function(value)
		if not AttackSphere then
			return
		end
		if Toggles.SR_Toggle.Value then
			AttackSphere:SetRadius(Options.CAD_Slider.Value)
			AttackSphere:SetColor(Options.SR_ColorPicker.Value)
			AttackSphere:SetTransparency(Options.SR_ColorPicker.Transparency)
		end
	end)
	Toggles.SR_Toggle:OnChanged(function(value)
		if not AttackSphere then
			return
		end
		if value then
			AttackSphere:SetRadius(Options.CAD_Slider.Value)
			AttackSphere:SetColor(Options.SR_ColorPicker.Value)
			AttackSphere:SetTransparency(Options.SR_ColorPicker.Transparency)
		end
	end)
	-- #endregion
	Toggles.ND_Toggle:OnChanged(function(state)
		if state then
			Toggles.SR_Toggle:SetValue(false)
			Toggles.SR_Toggle:SetDisabled(true)
			Options.CAD_Slider:SetDisabled(true)
		else
			Toggles.SR_Toggle:SetDisabled(false)
			Options.CAD_Slider:SetDisabled(false)
		end
	end)

	-- #region ======================= Main_Utility =======================
	Main_Utility:AddToggle("ACA_Toggle", {
		Text = "Auto Claim Artifact",
		Callback = function(state)
			if state then
				ArtifactWorker = worker:StartThread(function(thread_state)
					while thread_state() do
						CollectArtifact()
						task.wait(0.1)
					end
				end)
			else
				if ArtifactWorker then
					worker:Stop(ArtifactWorker)
					ArtifactWorker = nil
				end
			end
		end,
	})
	-- #endregion

	-- #region ======================= MY WORKER =======================
	worker:Start(RunService.Heartbeat:Connect(function(dt)
		if Toggles.ND_Toggle.Value then
			NearestMobsByTag = GetAllByTagsSorted("Mob")
		else
			NearestMobsByTag = GetNearestsByTags(Options.CAD_Slider.Value, "Mob")
		end
		if Toggles.KA_Toggle.Value then
			StartKillAura()
		end
		if Toggles.SR_Toggle.Value then
			if not AttackSphere or not AttackSphere:GetInstance() then
				-- AttackSphere = worker:Start(CreateRadiusSphere())
				-- AttackSphere:SetRadius(Options.CAD_Slider.Value)
				-- AttackSphere:SetColor(Options.SR_ColorPicker.Value)
				-- AttackSphere:SetTransparency(Options.SR_ColorPicker.Transparency)
			end
		end
	end))
	-- #endregion

	-- #region ======================= UNLOAD =======================
	Library:OnUnload(function()
		worker:StopAll()
	end)
	-- #endregion
end
-- #endregion

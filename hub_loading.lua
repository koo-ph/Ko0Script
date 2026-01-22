local G2L = {};
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- StarterGui.Ko0Hub
G2L["1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"));
G2L["1"]["IgnoreGuiInset"] = true;
G2L["1"]["ScreenInsets"] = Enum.ScreenInsets.DeviceSafeInsets;
G2L["1"]["Name"] = [[Ko0Hub]];
G2L["1"]["ResetOnSpawn"] = false;


-- StarterGui.Ko0Hub.DimBackground
G2L["2"] = Instance.new("Frame", G2L["1"]);
G2L["2"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
G2L["2"]["Size"] = UDim2.new(1, 0, 1, 0);
G2L["2"]["Name"] = [[DimBackground]];
G2L["2"]["BackgroundTransparency"] = 0.35;


-- StarterGui.Ko0Hub.LauncherCard
G2L["3"] = Instance.new("Frame", G2L["1"]);
G2L["3"]["BackgroundColor3"] = Color3.fromRGB(16, 15, 23);
G2L["3"]["ClipsDescendants"] = true;
G2L["3"]["Size"] = UDim2.new(0.34, 0, 0.32, 0);
G2L["3"]["Position"] = UDim2.new(0.33, 0, 0.37, 0);
G2L["3"]["Name"] = [[LauncherCard]];
G2L["3"]["BackgroundTransparency"] = 0.04;


-- StarterGui.Ko0Hub.LauncherCard.UICorner
G2L["4"] = Instance.new("UICorner", G2L["3"]);
G2L["4"]["CornerRadius"] = UDim.new(0, 14);


-- StarterGui.Ko0Hub.LauncherCard.CardStroke
G2L["5"] = Instance.new("UIStroke", G2L["3"]);
G2L["5"]["Transparency"] = 0.46399;
G2L["5"]["Color"] = Color3.fromRGB(121, 81, 161);
G2L["5"]["Name"] = [[CardStroke]];


-- StarterGui.Ko0Hub.LauncherCard.NoiseOverlay
G2L["6"] = Instance.new("ImageLabel", G2L["3"]);
G2L["6"]["ImageTransparency"] = 0.9;
G2L["6"]["Image"] = [[rbxassetid://9968343281]];
G2L["6"]["Size"] = UDim2.new(1, 0, 1, 0);
G2L["6"]["BackgroundTransparency"] = 1;
G2L["6"]["Name"] = [[NoiseOverlay]];
G2L["6"]["Position"] = UDim2.new(0.00681, 0, -0.04254, 0);


-- StarterGui.Ko0Hub.LauncherCard.AccentBar
G2L["7"] = Instance.new("Frame", G2L["3"]);
G2L["7"]["BackgroundColor3"] = Color3.fromRGB(131, 91, 201);
G2L["7"]["Size"] = UDim2.new(0.01, 0, 1, 0);
G2L["7"]["Name"] = [[AccentBar]];
G2L["7"]["BackgroundTransparency"] = 0.2;


-- StarterGui.Ko0Hub.LauncherCard.HubLogo
G2L["8"] = Instance.new("ImageLabel", G2L["3"]);
G2L["8"]["ScaleType"] = Enum.ScaleType.Crop;
G2L["8"]["AutomaticSize"] = Enum.AutomaticSize.XY;
G2L["8"]["Image"] = [[rbxassetid://89625232178150]];
G2L["8"]["Size"] = UDim2.new(0.19148, 0, 0.36169, 0);
G2L["8"]["BackgroundTransparency"] = 1;
G2L["8"]["Name"] = [[HubLogo]];
G2L["8"]["Position"] = UDim2.new(0.05, 0, 0.05, 0);


-- StarterGui.Ko0Hub.LauncherCard.HubLogo.UICorner
G2L["9"] = Instance.new("UICorner", G2L["8"]);
G2L["9"]["CornerRadius"] = UDim.new(1, 0);


-- StarterGui.Ko0Hub.LauncherCard.HubLogo.UIStroke
G2L["a"] = Instance.new("UIStroke", G2L["8"]);
G2L["a"]["Thickness"] = 1.5;
G2L["a"]["Color"] = Color3.fromRGB(119, 89, 197);


-- StarterGui.Ko0Hub.LauncherCard.HubSubtitle
G2L["b"] = Instance.new("TextLabel", G2L["3"]);
G2L["b"]["TextWrapped"] = true;
G2L["b"]["TextScaled"] = true;
G2L["b"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["b"]["TextColor3"] = Color3.fromRGB(171, 161, 201);
G2L["b"]["BackgroundTransparency"] = 1;
G2L["b"]["AnchorPoint"] = Vector2.new(0.5, 0);
G2L["b"]["Size"] = UDim2.new(0.6, 0, 0.18, 0);
G2L["b"]["Text"] = [[Game Place]];
G2L["b"]["Name"] = [[HubSubtitle]];
G2L["b"]["Position"] = UDim2.new(0.6, 0, 0.2, 0);


-- StarterGui.Ko0Hub.LauncherCard.SignalRail
G2L["c"] = Instance.new("Frame", G2L["3"]);
G2L["c"]["Visible"] = false;
G2L["c"]["BackgroundColor3"] = Color3.fromRGB(41, 39, 56);
G2L["c"]["AnchorPoint"] = Vector2.new(0.5, 0);
G2L["c"]["Size"] = UDim2.new(0.6, 0, 0.006, 0);
G2L["c"]["Position"] = UDim2.new(0.5, 0, 0.55, 0);
G2L["c"]["Name"] = [[SignalRail]];
G2L["c"]["BackgroundTransparency"] = 0.2;


-- StarterGui.Ko0Hub.LauncherCard.SignalRail.UICorner
G2L["d"] = Instance.new("UICorner", G2L["c"]);
G2L["d"]["CornerRadius"] = UDim.new(1, 0);


-- StarterGui.Ko0Hub.LauncherCard.SignalRail.RailGlow
G2L["e"] = Instance.new("UIStroke", G2L["c"]);
G2L["e"]["Transparency"] = 0.85;
G2L["e"]["Color"] = Color3.fromRGB(91, 61, 151);
G2L["e"]["Name"] = [[RailGlow]];


-- StarterGui.Ko0Hub.LauncherCard.SignalRail.SignalFill
G2L["f"] = Instance.new("Frame", G2L["c"]);
G2L["f"]["BackgroundColor3"] = Color3.fromRGB(151, 111, 255);
G2L["f"]["Size"] = UDim2.new(0.25, 0, 1, 0);
G2L["f"]["Name"] = [[SignalFill]];


-- StarterGui.Ko0Hub.LauncherCard.SignalRail.SignalFill.UICorner
G2L["10"] = Instance.new("UICorner", G2L["f"]);
G2L["10"]["CornerRadius"] = UDim.new(1, 0);


-- StarterGui.Ko0Hub.LauncherCard.SignalRail.SignalFill.SignalGlow
G2L["11"] = Instance.new("UIStroke", G2L["f"]);
G2L["11"]["Transparency"] = 0.26544;
G2L["11"]["Color"] = Color3.fromRGB(171, 131, 255);
G2L["11"]["Name"] = [[SignalGlow]];


-- StarterGui.Ko0Hub.LauncherCard.KeyBox
G2L["12"] = Instance.new("TextBox", G2L["3"]);
G2L["12"]["CursorPosition"] = -1;
G2L["12"]["Name"] = [[KeyBox]];
G2L["12"]["TextWrapped"] = true;
G2L["12"]["TextColor3"] = Color3.fromRGB(241, 241, 255);
G2L["12"]["TextScaled"] = true;
G2L["12"]["BackgroundColor3"] = Color3.fromRGB(23, 23, 31);
G2L["12"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["12"]["AnchorPoint"] = Vector2.new(0.5, 0);
G2L["12"]["PlaceholderText"] = [[Enter Access Key]];
G2L["12"]["Size"] = UDim2.new(0.55, 0, 0.18, 0);
G2L["12"]["Position"] = UDim2.new(0.5, 0, 0.45, 0);
G2L["12"]["Text"] = [[]];


-- StarterGui.Ko0Hub.LauncherCard.KeyBox.UICorner
G2L["13"] = Instance.new("UICorner", G2L["12"]);
G2L["13"]["CornerRadius"] = UDim.new(0, 6);


-- StarterGui.Ko0Hub.LauncherCard.SubmitButton
G2L["14"] = Instance.new("TextButton", G2L["3"]);
G2L["14"]["TextWrapped"] = true;
G2L["14"]["TextScaled"] = true;
G2L["14"]["TextColor3"] = Color3.fromRGB(21, 11, 41);
G2L["14"]["BackgroundColor3"] = Color3.fromRGB(121, 91, 201);
G2L["14"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L["14"]["Size"] = UDim2.new(0.25, 0, 0.11, 0);
G2L["14"]["Text"] = [[Submit]];
G2L["14"]["Name"] = [[SubmitButton]];
G2L["14"]["Position"] = UDim2.new(0.63176, 0, 0.65955, 0);


-- StarterGui.Ko0Hub.LauncherCard.SubmitButton.UICorner
G2L["15"] = Instance.new("UICorner", G2L["14"]);
G2L["15"]["CornerRadius"] = UDim.new(0, 6);


-- StarterGui.Ko0Hub.LauncherCard.GetKeyButton
G2L["16"] = Instance.new("TextButton", G2L["3"]);
G2L["16"]["TextWrapped"] = true;
G2L["16"]["TextScaled"] = true;
G2L["16"]["TextColor3"] = Color3.fromRGB(201, 201, 221);
G2L["16"]["BackgroundColor3"] = Color3.fromRGB(36, 36, 51);
G2L["16"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["16"]["Size"] = UDim2.new(0.25, 0, 0.11, 0);
G2L["16"]["Text"] = [[Get Key]];
G2L["16"]["Name"] = [[GetKeyButton]];
G2L["16"]["Position"] = UDim2.new(0.10796, 0, 0.65955, 0);


-- StarterGui.Ko0Hub.LauncherCard.GetKeyButton.UICorner
G2L["17"] = Instance.new("UICorner", G2L["16"]);
G2L["17"]["CornerRadius"] = UDim.new(0, 6);


-- StarterGui.Ko0Hub.LauncherCard.GameFooter
G2L["18"] = Instance.new("TextLabel", G2L["3"]);
G2L["18"]["TextWrapped"] = true;
G2L["18"]["TextXAlignment"] = Enum.TextXAlignment.Right;
G2L["18"]["TextScaled"] = true;
G2L["18"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L["18"]["TextColor3"] = Color3.fromRGB(121, 121, 151);
G2L["18"]["BackgroundTransparency"] = 1;
G2L["18"]["AnchorPoint"] = Vector2.new(1, 1);
G2L["18"]["Size"] = UDim2.new(0.39319, 0, 0.06199, 0);
G2L["18"]["Text"] = [[Version: xxxxxxx]];
G2L["18"]["Name"] = [[GameFooter]];
G2L["18"]["Position"] = UDim2.new(0.96184, 0, 0.99868, 0);


-- StarterGui.Ko0Hub.LauncherCard.HubTitle
G2L["19"] = Instance.new("TextLabel", G2L["3"]);
G2L["19"]["TextWrapped"] = true;
G2L["19"]["TextScaled"] = true;
G2L["19"]["FontFace"] = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L["19"]["TextColor3"] = Color3.fromRGB(236, 236, 246);
G2L["19"]["BackgroundTransparency"] = 1;
G2L["19"]["AnchorPoint"] = Vector2.new(0.5, 0);
G2L["19"]["Size"] = UDim2.new(0.6, 0, 0.25, 0);
G2L["19"]["Text"] = [[🔮 Ko0 Hub 🔮]];
G2L["19"]["Name"] = [[HubTitle]];
G2L["19"]["Position"] = UDim2.new(0.6, 0, 0, 0);


-- StarterGui.Ko0Hub.GetDiscord
G2L["1a"] = Instance.new("ImageButton", G2L["1"]);
G2L["1a"]["BorderSizePixel"] = 0;
G2L["1a"]["ScaleType"] = Enum.ScaleType.Slice;
G2L["1a"]["BackgroundTransparency"] = 1;
G2L["1a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["1a"]["Image"] = [[rbxassetid://4559100966]];
G2L["1a"]["Size"] = UDim2.new(0.02762, 0, 0.03762, 5);
G2L["1a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["1a"]["Name"] = [[GetDiscord]];
G2L["1a"]["Position"] = UDim2.new(0.33951, 0, 0.63243, 0);

-- entrance
TweenService:Create(G2L["2"], TweenInfo.new(0.4), {
	BackgroundTransparency = 0.55
}):Play()

TweenService:Create(G2L["3"], TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
	Position = UDim2.fromScale(0.33, 0.37)
}):Play()

-- subtle breathing glow
task.spawn(function()
	while G2L["3"].Parent do
		TweenService:Create(G2L["5"], TweenInfo.new(2,Enum.EasingStyle.Sine), {
			Transparency = 0.25
		}):Play()
		task.wait(2)
		TweenService:Create(G2L["5"], TweenInfo.new(2,Enum.EasingStyle.Sine), {
			Transparency = 0.65
		}):Play()
		task.wait(2)
	end
end)

-- progress setter
local function setProgress(p)
	TweenService:Create(G2L["f"], TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(math.clamp(p, 0, 1), 1)
	}):Play()
end

-- glow pulse
task.spawn(function()
	while G2L["f"].Parent do
		TweenService:Create(G2L["11"], TweenInfo.new(1.5, Enum.EasingStyle.Sine), {
			Transparency = 0.2
		}):Play()
		task.wait(1.5)
		TweenService:Create(G2L["11"], TweenInfo.new(1.5, Enum.EasingStyle.Sine), {
			Transparency = 0.7
		}):Play()
		task.wait(1.5)
	end
end)

-- close hub
local function closeHub()
	TweenService:Create(G2L["3"], TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
		Position = UDim2.fromScale(1.2,0.37)
	}):Play()

	TweenService:Create(G2L["2"], TweenInfo.new(0.4), {
		BackgroundTransparency = 1
	}):Play()

	task.wait(0.4)
	G2L["1"]:Destroy()

	print("LOADING HUB...")
end

G2L["16"].MouseButton1Click:Connect(function()
	print("https://your-key-site.com")
end)

-- ================================== LOGIC ==================================
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

G2L["18"].Text = "Version: " .. HUB_VERSION

local hub = "https://raw.githubusercontent.com/koo-ph/Ko0Script/" .. HUB_VERSION .. "/loader.lua"
local function loadHub()
    G2L["14"].Visible = false
    G2L["12"].Visible = false
    G2L["16"].Visible = false
    G2L["c"].Visible = true
    setProgress(0.25) -- fetching

    setProgress(0.55) -- compiling

    local fn = loadstring(game:HttpGet(hub))
    setProgress(0.85) -- executing

    fn()
    setProgress(1)
    task.wait(0.1)
    closeHub()
end

local oldPlaceholder = G2L["12"].PlaceholderText
local oldPlaceholderColor = G2L["12"].PlaceholderColor3

-- KEY SECTION
G2L["14"].MouseButton1Click:Connect(function()
    local enteredKey = G2L["12"].Text
    if enteredKey == "key" then
        loadHub()
    else
        task.spawn(function()
            G2L["12"].Text = ""
            G2L["12"].PlaceholderText = "Invalid Key!"
            G2L["12"].PlaceholderColor3 = Color3.fromRGB(255, 100, 100)
            task.wait(1)
            G2L["12"].PlaceholderText = oldPlaceholder
            G2L["12"].PlaceholderColor3 = oldPlaceholderColor
        end)
    end
end)

local needKey = false
G2L["14"].Visible = needKey
G2L["12"].Visible = needKey
G2L["16"].Visible = needKey

if not needKey then
    G2L["c"].Visible = true
    loadHub()
else
    G2L["12"].FocusLost:Connect(function(enterPressed)
		if enterPressed and G2L["12"].Text == "key" then
			loadHub()
		end
        if G2L["12"].Text ~= "key" then
            task.spawn(function()
                G2L["12"].Text = ""
                G2L["12"].PlaceholderText = "Invalid Key!"
                G2L["12"].PlaceholderColor3 = Color3.fromRGB(255, 100, 100)
                task.wait(1)
                G2L["12"].PlaceholderText = oldPlaceholder
                G2L["12"].PlaceholderColor3 = oldPlaceholderColor
            end)
        end
	end)
end
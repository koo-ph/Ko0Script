-- ======================================================
-- 🔮 Ko0 Hub Demo Game Script
-- ======================================================

return function(Window, Library)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local LocalPlayer = Players.LocalPlayer
    local Toggles = Library.Toggles
    local Options = Library.Options

    -- ================= Tabs =================
    local DemoTab = Window:AddTab("Demo", "flask-conical")
    local PlayerTab = Window:AddTab("Player", "user")
    local FunTab = Window:AddTab("Fun", "sparkles")

    -- ================= Demo Tab =================
    local DemoBox = DemoTab:AddLeftGroupbox("Hub Test")

    DemoBox:AddLabel("If you see this, the hub works ✅")

    DemoBox:AddButton("Notify Test", function()
        Library:Notify("Ko0 Hub", "Notification system working!", 3)
    end)

    DemoBox:AddToggle("DemoToggle", {
        Text = "Demo Toggle",
        Default = false,
        Callback = function(v)
            print("[DEMO] Toggle:", Toggles.DemoToggle.Value)
            Toggles.HiddenToggle.Visible = v
        end
    })

    DemoBox:AddToggle("HiddenToggle", {
        Text = "Hidden Toggle",
        Default = false,
        Callback = function(v)
            print("[DEMO] Hidden Toggle:", v)
        end
    })

    DemoBox:AddSlider("DemoSlider", {
        Text = "Demo Slider",
        Min = 1,
        Max = 100,
        Default = 50,
        Callback = function(v)
            print("[DEMO] Slider:", v)
        end
    })

    -- ================= Player Tab =================
    local PlayerBox = PlayerTab:AddLeftGroupbox("Movement")

    PlayerBox:AddSlider("WalkSpeed", {
        Text = "WalkSpeed",
        Min = 16,
        Max = 100,
        Default = 16,
        Callback = function(v)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = v
            end
        end
    })

    PlayerBox:AddSlider("JumpPower", {
        Text = "JumpPower",
        Min = 50,
        Max = 150,
        Default = 50,
        Callback = function(v)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.JumpPower = v
            end
        end
    })

    -- ================= Fun Tab =================
    local FunBox = FunTab:AddLeftGroupbox("Fun Stuff")

    FunBox:AddButton("Print Player Info", function()
        print("Name:", LocalPlayer.Name)
        print("UserId:", LocalPlayer.UserId)
        print("PlaceId:", game.PlaceId)
    end)

    FunBox:AddToggle("RainbowSpam", {
        Text = "Rainbow Console Spam 🌈",
        Callback = function(v)
            print("Rainbow spam:", v)
        end
    })

    -- ================= Loop Example =================
    local heartbeatConn
    heartbeatConn = RunService.Heartbeat:Connect(function()
        if Toggles.RainbowSpam and Toggles.RainbowSpam.Value then
            print("🌈")
        end
    end)

    -- ================= Cleanup =================
    Library:OnUnload(function()
        if heartbeatConn then
            heartbeatConn:Disconnect()
        end

        print("[Ko0 Hub] Demo script unloaded cleanly")
    end)
end

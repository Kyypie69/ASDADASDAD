-- SpeedHub Merged Mega File
-- Put the entire Speedhub.UI.lua library inside the PASTE block below to make this file fully standalone (no HTTP/local reads required).
-- If you don't paste it, the script will try to load Speedhub.UI.lua from common local paths, then fall back to a remote HttpGet URL.

-- =========================
-- BEGIN: OPTIONAL INLINE LIBRARY
-- =========================
--[[ PASTE SPEEDHUB.UI.lua HERE
   -----------------------------------------------------------------
   Paste the full contents of your Speedhub.UI.lua file here (the
   entire library). If you paste it, the loader below will detect the
   global `Library` created by the inlined code and use it directly.
   -----------------------------------------------------------------
--]]
-- =========================
-- END: OPTIONAL INLINE LIBRARY
-- =========================

-- Loader: if Library isn't defined by the pasted code above, try local readfile(s), else HttpGet fallback
local Library
do
    if _G and _G.SpeedHubLibrary then
        Library = _G.SpeedHubLibrary
    end

    if not Library then
        -- First, try to find already loaded SpeedHub in the environment
        if type(getfenv) == "function" then
            -- nothing done here; typical exploit envs already set global Library when inlined
        end
    end

    if not Library then
        -- try local common file paths using readfile/isfile (some executors)
        local ok, lib
        local function try_local(path)
            if type(isfile) == "function" and isfile(path) then
                local contents = readfile(path)
                if contents and #contents > 10 then
                    local fn, err = loadstring(contents)
                    if fn then
                        local suc, res = pcall(fn)
                        if suc and res == nil then
                            -- assume inlined code sets a global Library; try to fetch it
                            if _G and _G.Library then return _G.Library end
                            if Library then return Library end
                        end
                    end
                end
            end
            return nil
        end

        -- Try a couple places
        pcall(function() lib = try_local("Speedhub.UI.lua") end)
        if not lib then pcall(function() lib = try_local("/mnt/data/Speedhub.UI.lua") end) end
        if lib then Library = lib end
    end

    if not Library then
        -- fallback remote (modify URL if desired)
        local success, result = pcall(function()
            local url = "https://raw.githubusercontent.com/Kyypie69/Library.UI/refs/heads/main/Speedhub.UI.lua"
            local s = game:HttpGet(url, true)
            if s and #s > 10 then
                local fn, err = loadstring(s)
                if fn then
                    fn()
                    -- assume inlined code sets Library global
                    if _G and _G.Library then return _G.Library end
                    if Library then return Library end
                end
            end
            return nil
        end)
        if success and result then
            Library = result
        end
    end

    if not Library then
        -- final attempt: if inlined code created a 'Library' global earlier, use it
        if _G and _G.Library then Library = _G.Library end
    end

    if not Library then
        warn("[SpeedHub Merged Mega] Could not locate SpeedHub library. Paste the library into the PASTE block at the top or ensure readfile/getfile is available, or allow HttpGet.")
        -- continue -- script will still attempt to use Creator/New if Library becomes available later
    end
end

-- If Library wasn't created by the inline paste but was present with different name, attempt to locate Creator in globals
local Creator
if Library and Library.Creator then
    Creator = Library.Creator
else
    -- fallback Creator that uses minimal UI functions if SpeedHub isn't loaded.
    Creator = {}
    function Creator.New(name, props, children)
        -- Very small fallback: create basic Roblox instances
        local inst = Instance.new(name)
        if props then
            for k,v in pairs(props) do
                if k ~= "ThemeTag" then
                    pcall(function() inst[k] = v end)
                end
            end
        end
        if children then
            for _,c in pairs(children) do
                pcall(function() c.Parent = inst end)
            end
        end
        return inst
    end
    function Creator.GetThemeProperty(key)
        local themes = {
            AcrylicMain = Color3.fromRGB(20,20,30),
            Text = Color3.new(1,1,1),
            Tab = Color3.fromRGB(0,100,220),
        }
        return themes[key] or Color3.new(1,1,1)
    end
    Library = Library or {}
    Library.Creator = Creator
    Library.GUI = Library.GUI or Instance.new("ScreenGui", game:GetService("CoreGui"))
end

local New = Creator.New
-- short services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

-- safe pcall helper
local function safeCall(f, ...)
    if not f then return end
    local ok, res = pcall(f, ...)
    if not ok then warn("[SpeedHub Merged] callback error:", res) end
    return ok, res
end

-- ----------------------------
-- Begin: Feature ported code
-- ----------------------------

-- Global toggles and state
getgenv()._AutoRepFarmEnabled = getgenv()._AutoRepFarmEnabled or false
getgenv()._AutoRepFarmLoop = getgenv()._AutoRepFarmLoop or false
getgenv().AutoFarming = getgenv().AutoFarming or false
getgenv().AntiAfkExecuted = getgenv().AntiAfkExecuted or false

-- constants
local PET_NAME = "Swift Samurai"
local ROCK_NAME = "Rock5M"
local PROTEIN_EGG_NAME = "ProteinEgg"
local PROTEIN_EGG_INTERVAL = 30 * 60
local BURST_SIZE = 15
local ROCK_INTERVAL = 1

local lastRockTime, lastProteinEggTime = 0, 0
local RockRef = Workspace:FindFirstChild(ROCK_NAME)
local HumanoidRootPart

local function getPing()
    local success, ping = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return success and ping or 999
end

local function getDelay()
    local ping = getPing()
    if ping < 100 then return 0.0003
    elseif ping < 300 then return 0.0006
    elseif ping < 600 then return 0.001
    else return 0.002 end
end

local function updateCharacterRefs()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
end

local function equipPetByName(name, maxEquip)
    maxEquip = maxEquip or 8
    local c = LocalPlayer
    local a = ReplicatedStorage
    local equipped = 0
    local petsFolder = c:FindFirstChild("petsFolder")
    if not petsFolder then return 0 end
    -- unequip all
    for _, folder in pairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                pcall(function() a.rEvents.equipPetEvent:FireServer("unequipPet", pet) end)
            end
        end
    end
    task.wait(0.1)
    for _, folder in pairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                if pet.Name:lower() == name:lower() then
                    pcall(function() a.rEvents.equipPetEvent:FireServer("equipPet", pet) end)
                    equipped = equipped + 1
                    if equipped >= maxEquip then return equipped end
                end
            end
        end
    end
    return equipped
end

local function eatProteinEgg()
    local player = LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end
    for _, item in pairs(backpack:GetChildren()) do
        if item.Name == PROTEIN_EGG_NAME or item.Name == "Protein Egg" then
            pcall(function()
                ReplicatedStorage.rEvents.eatEvent:FireServer("eat", item)
            end)
            return true
        end
    end
    return false
end

local function hitRock()
    if not RockRef or not RockRef.Parent then
        RockRef = Workspace:FindFirstChild(ROCK_NAME)
    end
    if RockRef and HumanoidRootPart then
        HumanoidRootPart.CFrame = RockRef.CFrame * CFrame.new(0, 0, -5)
        pcall(function() ReplicatedStorage.rEvents.hitEvent:FireServer("hit", RockRef) end)
    end
end

-- AutoRepFarm loop
if not getgenv()._AutoRepFarmLoop then
    getgenv()._AutoRepFarmLoop = true
    updateCharacterRefs()
    equipPetByName(PET_NAME, 1)
    lastProteinEggTime = tick()
    lastRockTime = tick()
    RunService.Heartbeat:Connect(function()
        if not getgenv()._AutoRepFarmEnabled then return end
        for i = 1, BURST_SIZE do
            task.spawn(function()
                pcall(function()
                    if LocalPlayer:FindFirstChild("muscleEvent") then
                        LocalPlayer.muscleEvent:FireServer("rep")
                    end
                end)
            end)
        end
        if tick() - lastProteinEggTime >= PROTEIN_EGG_INTERVAL then
            eatProteinEgg()
            lastProteinEggTime = tick()
        end
        if tick() - lastRockTime >= ROCK_INTERVAL then
            hitRock()
            lastRockTime = tick()
        end
        task.wait(getDelay())
    end)
end

-- AutoEat thread
local autoEatEnabled = false
task.spawn(function()
    while true do
        if autoEatEnabled then
            eatProteinEgg()
            task.wait(1800)
        else
            task.wait(1)
        end
    end
end)

-- Fast Rebirths helpers
local function getGoldenRebirthCount()
    local g = LocalPlayer:FindFirstChild("ultimatesFolder")
    if g and g:FindFirstChild("Golden Rebirth") then
        return g["Golden Rebirth"].Value
    end
    return 0
end

local function getStrengthRequiredForRebirth()
    local rebirths = 0
    pcall(function() rebirths = LocalPlayer.leaderstats.Rebirths.Value end)
    local baseStrength = 10000 + (5000 * rebirths)
    local golden = getGoldenRebirthCount()
    if golden >= 1 and golden <= 5 then
        baseStrength = baseStrength * (1 - golden * 0.01)
    end
    return math.floor(baseStrength)
end

local function startFastRebirths()
    if getgenv().AutoFarming then
        task.spawn(function()
            local a = ReplicatedStorage
            local c = LocalPlayer
            while getgenv().AutoFarming do
                local requiredStrength = getStrengthRequiredForRebirth()
                -- unequip all
                if c:FindFirstChild("petsFolder") then
                    for _, folder in pairs(c.petsFolder:GetChildren()) do
                        if folder:IsA("Folder") then
                            for _, pet in pairs(folder:GetChildren()) do
                                pcall(function() a.rEvents.equipPetEvent:FireServer("unequipPet", pet) end)
                            end
                        end
                    end
                end
                -- equip Swift Samurai
                equipPetByName("Swift Samurai", 1)
                -- pump reps
                while (c:FindFirstChild("leaderstats") and c.leaderstats.Strength and c.leaderstats.Strength.Value or 0) < requiredStrength and getgenv().AutoFarming do
                    for _ = 1, 10 do
                        pcall(function() if c:FindFirstChild("muscleEvent") then c.muscleEvent:FireServer("rep") end end)
                    end
                    task.wait()
                end
                if getgenv().AutoFarming then
                    pcall(function() equipPetByName("Tribal Overlord", 1) end)
                    local oldRebirths = (c:FindFirstChild("leaderstats") and c.leaderstats.Rebirths.Value) or 0
                    repeat
                        pcall(function() a.rEvents.rebirthRemote:InvokeServer("rebirthRequest") end)
                        task.wait(0.01)
                    until not getgenv().AutoFarming or ((c:FindFirstChild("leaderstats") and c.leaderstats.Rebirths.Value) or 0) > oldRebirths
                end
                task.wait()
            end
        end)
    end
end

-- Lock Position helper
local positionLockConn = nil
local function setLockPosition(enable)
    if enable then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local cf = LocalPlayer.Character.HumanoidRootPart.CFrame
            positionLockConn = RunService.Heartbeat:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = cf
                end
            end)
        end
    else
        if positionLockConn then pcall(function() positionLockConn:Disconnect() end) end
        positionLockConn = nil
    end
end

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
end)

local antiAfkGui = nil
local zamanbaslaticisi = false
local function toggleAntiAfk(state)
    if state then
        if getgenv().AntiAfkExecuted then return end
        getgenv().AntiAfkExecuted = true
        zamanbaslaticisi = true
        -- Build minimal anti-afk UI if library exists
        if Library and Library.GUI then
            antiAfkGui = New("Frame", {
                Name = "AntiAfkPanel",
                Size = UDim2.new(0,225,0,96),
                Position = UDim2.new(0.085,0,0.13,0),
                BackgroundColor3 = Color3.fromRGB(30,30,30),
                Parent = Library.GUI,
            }, { New("UICorner", { CornerRadius = UDim.new(0,6) }) })
            local timerLabel = New("TextLabel", {
                Text = "0:0:0",
                Size = UDim2.new(0,60,0,24),
                Position = UDim2.new(0.65,0,0.68,0),
                BackgroundTransparency = 1,
                Parent = antiAfkGui,
            })
            local pingLabel = New("TextLabel", {
                Text = "0",
                Size = UDim2.new(0,55,0,24),
                Position = UDim2.new(0.2,0,0.37,0),
                BackgroundTransparency = 1,
                Parent = antiAfkGui,
            })
            local fpsLabel = New("TextLabel", {
                Text = "0",
                Size = UDim2.new(0,55,0,24),
                Position = UDim2.new(0.72,0,0.35,0),
                BackgroundTransparency = 1,
                Parent = antiAfkGui,
            })
            -- FPS & ping loops
            local frames = {}
            local sec = tick()
            RunService.RenderStepped:Connect(function()
                local fr = tick()
                for i = #frames, 1, -1 do frames[i+1] = (frames[i] >= fr-1) and frames[i] or nil end
                frames[1] = fr
                local fps = math.floor((tick()-sec>=1 and #frames) or (#frames/(tick()-sec)))
                fpsLabel.Text = tostring(fps)
            end)
            spawn(function()
                while zamanbaslaticisi do
                    wait(1)
                    local ping = 0
                    pcall(function() ping = math.floor(tonumber(Stats:FindFirstChild("PerformanceStats").Ping:GetValue())) end)
                    pingLabel.Text = tostring(ping)
                end
            end)
            -- timer
            local secn, minu, hr = 0,0,0
            spawn(function()
                while zamanbaslaticisi do
                    wait(1)
                    secn = secn + 1
                    if secn >= 60 then secn = 0; minu = minu + 1 end
                    if minu >= 60 then minu = 0; hr = hr + 1 end
                    timerLabel.Text = string.format("%d:%d:%d", hr, minu, secn)
                end
            end)
        end
    else
        zamanbaslaticisi = false
        getgenv().AntiAfkExecuted = false
        if antiAfkGui and antiAfkGui.Parent then pcall(function() antiAfkGui:Destroy() end) end
    end
end

-- Anti Lag
local function applyAntiLag()
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
            pcall(function() v.Enabled = false end)
        end
    end
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 0
    pcall(function() settings().Rendering.QualityLevel = 1 end)
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("Decal") or v:IsA("Texture") then
            pcall(function() v.Transparency = 1 end)
        elseif v:IsA("BasePart") and not v:IsA("MeshPart") then
            pcall(function() v.Material = Enum.Material.SmoothPlastic end)
            pcall(function() v.Reflectance = 0 end)
        end
    end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Anti Lag",
            Text = "Full optimization applied!",
            Duration = 5
        })
    end)
end

-- Equip Swift Samurai x8
local function equipSwiftSamuraiBulk()
    equipPetByName("Swift Samurai", 8)
end

-- Jungle lift / squat
local function jungleLift()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(-8652.8672, 29.2667, 2089.2617)
    task.wait(0.2)
    pcall(function()
        local VirtualInputManager = game:GetService("VirtualInputManager")
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

local function jungleSquat()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char:SetPrimaryPartCFrame(CFrame.new(-8374.25586, 34.5933418, 2932.44995))
        local machine = workspace:FindFirstChild("machinesFolder")
        if machine and machine:FindFirstChild("Jungle Squat") then
            local seat = machine["Jungle Squat"]:FindFirstChild("interactSeat")
            if seat then
                pcall(function() ReplicatedStorage.rEvents.machineInteractRemote:InvokeServer("useMachine", seat) end)
            end
        end
    end
end

-- Auto Spin wheel
local autoSpin = false
task.spawn(function()
    while true do
        if autoSpin then
            pcall(function()
                ReplicatedStorage.rEvents.openFortuneWheelRemote:InvokeServer(
                    "openFortuneWheel",
                    ReplicatedStorage.fortuneWheelChances["Fortune Wheel"]
                )
            end)
            task.wait(0.1)
        else
            task.wait(0.5)
        end
    end
end)

-- ----------------------------
-- Build UI (SpeedHub style)
-- ----------------------------

-- Ensure GUI root
local GUIRoot = (Library and Library.GUI) or New("ScreenGui", { Name = "SpeedHub_Merged_UI", Parent = game:GetService("CoreGui") })

-- Create main window
local MainWindow = New("Frame", {
    Name = "MainWindow",
    Size = UDim2.new(0, 580, 0, 520),
    Position = UDim2.new(0.12, 0, 0.08, 0),
    BackgroundColor3 = Creator.GetThemeProperty and Creator.GetThemeProperty("AcrylicMain") or Color3.fromRGB(20,20,30),
    Parent = GUIRoot,
}, { New("UICorner", { CornerRadius = UDim.new(0,10) }) })

New("TextLabel", {
    Text = "SpeedHub - Merged (Mega)",
    Size = UDim2.new(1, -20, 0, 34),
    Position = UDim2.new(0, 10, 0, 8),
    BackgroundTransparency = 1,
    TextColor3 = Creator.GetThemeProperty and Creator.GetThemeProperty("Text") or Color3.new(1,1,1),
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    Parent = MainWindow,
})

local TabsHolder = New("Frame", {
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 48),
    BackgroundTransparency = 1,
    Parent = MainWindow,
})

local contentHolder = New("Frame", {
    Size = UDim2.new(1, -20, 1, -120),
    Position = UDim2.new(0, 10, 0, 84),
    BackgroundTransparency = 1,
    Parent = MainWindow,
})

local function createTabButton(name, x)
    local btn = New("TextButton", {
        Text = name,
        Size = UDim2.new(0, 140, 0, 28),
        Position = UDim2.new(0, x, 0, 0),
        BackgroundColor3 = Creator.GetThemeProperty and Creator.GetThemeProperty("Tab") or Color3.fromRGB(0,100,220),
        TextColor3 = Creator.GetThemeProperty and Creator.GetThemeProperty("Text") or Color3.new(1,1,1),
        Parent = TabsHolder,
    }, { New("UICorner", { CornerRadius = UDim.new(0, 6) }) })
    return btn
end

local mainTabBtn = createTabButton("Main", 0)
local rebirthTabBtn = createTabButton("Rebirth", 150)
local perfTabBtn = createTabButton("Performance", 300)

local mainPane = New("Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = true, Parent = contentHolder })
local rebirthPane = New("Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false, Parent = contentHolder })
local perfPane = New("Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false, Parent = contentHolder })

local function showPane(p)
    mainPane.Visible = (p == mainPane)
    rebirthPane.Visible = (p == rebirthPane)
    perfPane.Visible = (p == perfPane)
end

mainTabBtn.MouseButton1Click:Connect(function() showPane(mainPane) end)
rebirthTabBtn.MouseButton1Click:Connect(function() showPane(rebirthPane) end)
perfTabBtn.MouseButton1Click:Connect(function() showPane(perfPane) end)

-- helper: toggle
local function createToggle(parent, labelText, y, initial, callback)
    local label = New("TextLabel", {
        Text = labelText,
        Position = UDim2.new(0, 6, 0, y),
        Size = UDim2.new(0, 380, 0, 26),
        BackgroundTransparency = 1,
        TextColor3 = Creator.GetThemeProperty and Creator.GetThemeProperty("Text") or Color3.new(1,1,1),
        Parent = parent,
    })
    local btn = New("TextButton", {
        Text = initial and "ON" or "OFF",
        Position = UDim2.new(0, 410, 0, y),
        Size = UDim2.new(0, 120, 0, 26),
        Parent = parent,
    }, { New("UICorner", { CornerRadius = UDim.new(0, 6) }) })
    local state = initial
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        safeCall(callback, state)
    end)
    return label, btn
end

local function createButton(parent, text, y, cb)
    local b = New("TextButton", {
        Text = text,
        Position = UDim2.new(0, 6, 0, y),
        Size = UDim2.new(0, 520, 0, 34),
        Parent = parent,
    }, { New("UICorner", { CornerRadius = UDim.new(0, 6) }) })
    b.MouseButton1Click:Connect(function() safeCall(cb) end)
    return b
end

-- Fill Main pane
local y = 6
local _, autoStrengthBtn = createToggle(mainPane, "Auto Strength Farm (rep bursts)", y, getgenv()._AutoRepFarmEnabled, function(s)
    getgenv()._AutoRepFarmEnabled = s
end)
y = y + 40
local _, eatEggBtn = createToggle(mainPane, "Auto Eat Egg (30 min)", y, autoEatEnabled, function(s)
    autoEatEnabled = s
end)
y = y + 40
local _, spinBtn = createToggle(mainPane, "Auto Spin Wheel", y, autoSpin, function(s)
    autoSpin = s
end)
y = y + 40
createButton(mainPane, "Equip Swift Samurai x8", y, equipSwiftSamuraiBulk)
y = y + 44
createButton(mainPane, "Jungle Lift", y, jungleLift)
y = y + 44
createButton(mainPane, "Jungle Squat", y, jungleSquat)
y = y + 44
createButton(mainPane, "Hide All Frames (ReplicatedStorage frames)", y, function()
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj.Name:match("Frame$") and obj:IsA("GuiBase") then pcall(function() obj.Visible = false end) end
    end
end)
y = y + 44
createToggle(mainPane, "Lock Position", y, false, function(s) setLockPosition(s) end)

-- Rebirth pane
local ry = 6
createToggle(rebirthPane, "Fast Rebirths", ry, getgenv().AutoFarming, function(s)
    getgenv().AutoFarming = s
    if s then startFastRebirths() end
end)
ry = ry + 46

local timeLabel = New("TextLabel", { Text = "Session: 0d 0h 0m 0s", Position = UDim2.new(0,6,0,ry), Size = UDim2.new(0,520,0,24), BackgroundTransparency = 1, Parent = rebirthPane })
ry = ry + 28
local currentLabel = New("TextLabel", { Text = "Current Rebirths: 0", Position = UDim2.new(0,6,0,ry), Size = UDim2.new(0,520,0,24), BackgroundTransparency = 1, Parent = rebirthPane })
ry = ry + 28
local gainedLabel = New("TextLabel", { Text = "Gained: +0", Position = UDim2.new(0,6,0,ry), Size = UDim2.new(0,520,0,24), BackgroundTransparency = 1, Parent = rebirthPane })
ry = ry + 28
local rpmLabel = New("TextLabel", { Text = "Rebirths/Min: 0", Position = UDim2.new(0,6,0,ry), Size = UDim2.new(0,520,0,24), BackgroundTransparency = 1, Parent = rebirthPane })
ry = ry + 28
local rphLabel = New("TextLabel", { Text = "Rebirths/Hour: 0", Position = UDim2.new(0,6,0,ry), Size = UDim2.new(0,520,0,24), BackgroundTransparency = 1, Parent = rebirthPane })

-- Stats updater
local startTime = tick()
local sessionRebirths = (LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats.Rebirths.Value) or 0
task.spawn(function()
    while task.wait(1) do
        local elapsed = tick() - startTime
        local days = math.floor(elapsed / 86400)
        local hours = math.floor((elapsed % 86400) / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = math.floor(elapsed % 60)
        timeLabel.Text = string.format("Session: %dd %dh %dm %ds", days, hours, minutes, seconds)
        local currentRebirths = (LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats.Rebirths.Value) or 0
        local gained = currentRebirths - sessionRebirths
        currentLabel.Text = "Current Rebirths: " .. tostring(currentRebirths)
        gainedLabel.Text = "Gained: +" .. tostring(gained)
        local minutesElapsed = math.max( (elapsed/60), 1 )
        local hoursElapsed = math.max( (elapsed/3600), 1 )
        rpmLabel.Text = string.format("Rebirths/Min: %.2f", gained / minutesElapsed)
        rphLabel.Text = string.format("Rebirths/Hour: %.2f", gained / hoursElapsed)
    end
end)

-- Perf pane
local py = 6
createButton(perfPane, "Apply Anti Lag", py, applyAntiLag)
py = py + 46
createToggle(perfPane, "Anti AFK", py, getgenv().AntiAfkExecuted, function(s) toggleAntiAfk(s) end)
py = py + 46
createButton(perfPane, "Force GC & Clean Lighting", py, function()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            pcall(function() obj:Destroy() end)
        end
    end
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("Sky") then pcall(function() v:Destroy() end) end
    end
    collectgarbage()
end)

-- Draggable main window
do
    local dragging, dragStart, startPos = false, nil, nil
    MainWindow.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainWindow.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    MainWindow.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- protect gui if environment supports it
pcall(function()
    if protectgui then protectgui(GUIRoot) end
end)

print("[SpeedHub Merged Mega] Loaded. If you want zero-network usage: paste your entire Speedhub.UI.lua into the PASTE block at the top.")

-- End of mega file

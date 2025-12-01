--[[
    Elerium V2 Farming - Fixed Auto Rebirth Version
    This script has been corrected to include the complete rebirth functionality
    from the original SilenceV2Farming code
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local username = localPlayer.Name
local userId = localPlayer.UserId

local Player = Players.LocalPlayer
local player = game.Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local muscleEvent = player:WaitForChild("muscleEvent")
local leaderstats = player:WaitForChild("leaderstats")
local rebirthsStat = leaderstats:WaitForChild("Rebirths")

-- Load Elerium V2 library instead of Silence library
local EleriumV2_UI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Kyypie69/Library.UI/refs/heads/main/KYY.luau"))()

-- Create the main window with Elerium V2 configuration
local c2 = EleriumV2_UI.new({
    MainColor = Color3.fromRGB(0, 0, 139),  -- Same color as original
    ToggleKey = Enum.KeyCode.Insert,        -- Added required toggle key
    MinSize = Vector2.new(500, 500)         -- Same size as original
})

-- Create the main window (equivalent to library:AddWindow)
local aw = c2:CreateWindow("KYY HUB | Packs Farming", {})

-- Hide blocked frames (same functionality)
local replicatedStorage = game:GetService("ReplicatedStorage")
local blockedFrames = {
    "strengthFrame",
    "durabilityFrame", 
    "agilityFrame",
}

for _, name in ipairs(blockedFrames) do
    local frame = replicatedStorage:FindFirstChild(name)
    if frame and frame:IsA("GuiObject") then
        frame.Visible = false
    end
end

replicatedStorage.ChildAdded:Connect(function(child)
    if table.find(blockedFrames, child.Name) and child:IsA("GuiObject") then
        child.Visible = false
    end
end)

-- Create Fast Rebirth tab (equivalent to window:AddTab)
-- Create tabs
local FastRebTab = aw:CreateTab("Fast Rebirth", "Speed")
local FastStrTab = aw:CreateTab("Fast Strength", "Super Speed") 
local SettingsTab = aw:CreateTab("Settings", "Settings")
local MiscTab = aw:CreateTab("Misc", "Misc")

-- Format number function (same as original)
local function formatNumber(num)
    if num >= 1e15 then return string.format("%.2fQ", num/1e15) end
    if num >= 1e12 then return string.format("%.2fT", num/1e12) end
    if num >= 1e9 then return string.format("%.2fB", num/1e9) end
    if num >= 1e6 then return string.format("%.2fM", num/1e6) end
    if num >= 1e3 then return string.format("%.2fK", num/1e3) end
    return string.format("%.0f", num)
end

-- State variables (same as original)
local isRunning = false
local startTime = 0
local totalElapsed = 0
local initialRebirths = rebirthsStat.Value
local lastPaceUpdate = 0

-- Create UI elements using Elerium V2 methods
local serverLabel = FastRebTab:AddLabel("Time:")
serverLabel.TextSize = 20

local timeLabel = FastRebTab:AddLabel("0d 0h 0m 0s - Inactive")
local paceLabel = FastRebTab:AddLabel("Pace: 0 / Hour | 0 / Day | 0 / Week")
local averagePaceLabel = FastRebTab:AddLabel("Average Pace: 0 / Hour | 0 / Day | 0 / Week")

paceLabel.TextSize = 17
averagePaceLabel.TextSize = 17
timeLabel.TextSize = 17
timeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)

local rebirthsStatsLabel = FastRebTab:AddLabel("Rebirths: "..formatNumber(rebirthsStat.Value).." | Gained: 0")
rebirthsStatsLabel.TextSize = 17

-- State tracking variables (same as original)
local lastRebirthTime = tick()
local lastRebirthValue = rebirthsStat.Value

-- Update rebirths label function (same as original)
local function updateRebirthsLabel()
    local gained = rebirthsStat.Value - initialRebirths
    rebirthsStatsLabel.Text = string.format("Rebirths: %s | Gained: %s", 
                                           formatNumber(rebirthsStat.Value), 
                                           formatNumber(gained))
end

-- Update UI function (same as original)
local function updateUI(forceUpdate)
    local currentTime = tick()
    local elapsed = isRunning and (currentTime - startTime + totalElapsed) or totalElapsed
    
    local days = math.floor(elapsed / 86400)
    local hours = math.floor((elapsed % 86400) / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = math.floor(elapsed % 60)
    
    timeLabel.Text = string.format("%dd %dh %dm %ds - %s", days, hours, minutes, seconds,
                                 isRunning and "Rebirthing" or "Paused")
    
    if isRunning and (forceUpdate or currentTime - lastPaceUpdate >= 60) then
        local rebirthsGained = rebirthsStat.Value - lastRebirthValue
        local timeDiff = currentTime - lastRebirthTime
        
        if timeDiff > 0 then
            local perHour = (rebirthsGained / timeDiff) * 3600
            local perDay = perHour * 24
            local perWeek = perDay * 7
            
            paceLabel.Text = string.format("Pace: %s / Hour | %s / Day | %s / Week",
                                          formatNumber(perHour), formatNumber(perDay), formatNumber(perWeek))
            
            if totalElapsed > 0 then
                local avgPerHour = ((rebirthsStat.Value - initialRebirths) / totalElapsed) * 3600
                local avgPerDay = avgPerHour * 24
                local avgPerWeek = avgPerDay * 7
                
                averagePaceLabel.Text = string.format("Average Pace: %s / Hour | %s / Day | %s / Week",
                                                     formatNumber(avgPerHour), formatNumber(avgPerDay), formatNumber(avgPerWeek))
            end
        end
        
        lastPaceUpdate = currentTime
    end
    
    updateRebirthsLabel()
end

-- CORRECTED: Pet management function from original code
local function managePets(petName)
    for _, folder in pairs(player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                replicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
    
    for _, pet in pairs(player.petsFolder.Unique:GetChildren()) do
        if pet.Name == petName then
            replicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
        end
    end
end

-- CORRECTED: Complete rebirth function from original code
local function doRebirth()
    local rebirths = rebirthsStat.Value
    local strengthTarget = 5000 + (rebirths * 2550)
    
    while isRunning and player.leaderstats.Strength.Value < strengthTarget do
        local reps = player.MembershipType == Enum.MembershipType.Premium and 8 or 14
        for _ = 1, reps do
            muscleEvent:FireServer("rep")
        end
        task.wait(0.02)
    end
    
    if isRunning and player.leaderstats.Strength.Value >= strengthTarget then
        managePets("Tribal Overlord")
        task.wait(0.25)
        
        local before = rebirthsStat.Value
        repeat
            replicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
            task.wait(0.05)
        until rebirthsStat.Value > before or not isRunning
    end
end

-- CORRECTED: Fast rebirth loop from original code
local function fastRebirthLoop()
    while isRunning do
        managePets("Swift Samurai")
        doRebirth()
        task.wait(0.5)
    end
end

-- CORRECTED: Start/Stop functionality using proper toggle
local rebirthToggle = FastRebTab:AddToggle("Fast Rebirth", false, function(state)
    isRunning = state
    
    if state then
        startTime = tick()
        initialRebirths = rebirthsStat.Value
        lastRebirthTime = tick()
        lastRebirthValue = rebirthsStat.Value
        
        c2:Notify("Started", "Auto rebirth started!", "Success", 3)
        
        -- Start the rebirth loop in a separate thread
        task.spawn(fastRebirthLoop)
    else
        totalElapsed = totalElapsed + (tick() - startTime)
        c2:Notify("Stopped", "Auto rebirth stopped!", "Warning", 3)
        updateUI(true)
    end
end)

-- Reset stats button
local resetButton = FastRebTab:AddButton("Reset Stats", function()
    totalElapsed = 0
    startTime = isRunning and tick() or 0
    initialRebirths = rebirthsStat.Value
    lastRebirthTime = tick()
    lastRebirthValue = rebirthsStat.Value
    lastPaceUpdate = 0
    
    c2:Notify("Reset", "Statistics have been reset!", "Info", 3)
    updateUI(true)
end)

-- Auto-update UI (same as original)
spawn(function()
    while true do
        updateUI()
        wait(1)
    end
end)

-- Track rebirth changes (same as original)
rebirthsStat.Changed:Connect(function()
    updateRebirthsLabel()
end)

-- Initial UI update
updateUI(true)

-- Size optimization
local sizeRunning = false
local sizeThread = nil

FastRebTab:AddButton("Set Size 1", function(bool)
    sizeRunning = bool
    if sizeRunning then
        sizeThread = coroutine.create(function()
            while sizeRunning do
                ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", 1)
                wait(0.01)
            end
        end)
        coroutine.resume(sizeThread)
    end
end)

-- Fast Strength Variables
local fastRepRunning = false
local fastRepStartTime = 0
local fastRepPausedTime = 0
local fastRepTracking = false
local strengthHistory = {}
local durabilityHistory = {}
local calculationInterval = 10
local initialStrength = strengthStat.Value
local initialDurability = durabilityStat.Value
local repsPerTick = 1

-- Fast Strength UI Elements
FastStrengthTab:AddLabel("Time:")
local fastRepTimeLabel = FastStrengthTab:AddLabel("0d 0h 0m 0s - Fast Rep Inactive")
local projectedStrengthLabel = FastStrengthTab:AddLabel("Strength Pace: 0 /Hour | 0 /Day | 0 /Week")
local projectedDurabilityLabel = FastStrengthTab:AddLabel("Durability Pace: 0 /Hour | 0 /Day | 0 /Week")
local averageStrengthLabel = FastStrengthTab:AddLabel("Average Strength Pace: 0 /Hour | 0 /Day | 0 /Week")
local averageDurabilityLabel = FastStrengthTab:AddLabel("Average Durability Pace: 0 /Hour | 0 /Day | 0 /Week")
FastStrengthTab:AddLabel("")
FastStrengthTab:AddLabel("Stats:")
local strengthStatsLabel = FastStrengthTab:AddLabel("Strength: 0 | Gained: 0")
local durabilityStatsLabel = FastStrengthTab:AddLabel("Durability: 0 | Gained: 0")

-- Fast Strength Functions
local function fastRepLoop()
    while fastRepRunning do
        local startTick = tick()
        while tick() - startTick < 0.75 and fastRepRunning do
            for i = 1, repsPerTick do
                muscleEvent:FireServer("rep")
            end
            task.wait(0.02)
        end
        while fastRepRunning and getPing() >= 350 do
            task.wait(1)
        end
    end
end

FastStrTab:AddTextBox("Rep Speed", function(value)
    local num = tonumber(value)
    if num and num > 0 then
        repsPerTick = math.floor(num)
    end
end, {
    placeholder = "1",
})

FastStrTab:AddToggle("Fast Rep", function(state)
    if state and not fastRepRunning then
        fastRepRunning = true
        task.spawn(fastRepLoop)
    elseif not state and fastRepRunning then
        fastRepRunning = false
    end
end)

-- Statistics tracking loop
task.spawn(function()
    local lastCalcTime = tick()
    while true do
        local currentTime = tick()
        local currentStrength = strengthStat.Value
        local currentDurability = durabilityStat.Value

        strengthStatsLabel.Text = "Strength: " .. formatNumber(currentStrength) .. " | Gained: " .. formatNumber(currentStrength - initialStrength)
        durabilityStatsLabel.Text = "Durability: " .. formatNumber(currentDurability) .. " | Gained: " .. formatNumber(currentDurability - initialDurability)

        if fastRepRunning then
            if not fastRepTracking then
                fastRepTracking = true
                fastRepStartTime = currentTime
                strengthHistory = {}
                durabilityHistory = {}
            end
            local elapsedTime = fastRepPausedTime + (currentTime - fastRepStartTime)
            local days = math.floor(elapsedTime / (24 * 3600))
            local hours = math.floor((elapsedTime % (24 * 3600)) / 3600)
            local minutes = math.floor((elapsedTime % 3600) / 60)
            local seconds = math.floor(elapsedTime % 60)
            fastRepTimeLabel.Text = string.format("%dd %dh %dm %ds - Fast Rep Running", days, hours, minutes, seconds)
            fastRepTimeLabel.TextColor3 = Color3.fromRGB(50, 255, 50)

            table.insert(strengthHistory, {time = currentTime, value = currentStrength})
            table.insert(durabilityHistory, {time = currentTime, value = currentDurability})

            while #strengthHistory > 0 and currentTime - strengthHistory[1].time > calculationInterval do
                table.remove(strengthHistory, 1)
            end
            while #durabilityHistory > 0 and currentTime - durabilityHistory[1].time > calculationInterval do
                table.remove(durabilityHistory, 1)
            end

            if currentTime - lastCalcTime >= calculationInterval then
                lastCalcTime = currentTime

                if #strengthHistory >= 2 then
                    local strengthDelta = strengthHistory[#strengthHistory].value - strengthHistory[1].value
                    local strengthPerSecond = strengthDelta / calculationInterval
                    local strengthPerHour = strengthPerSecond * 3600
                    local strengthPerDay = strengthPerSecond * 86400
                    local strengthPerWeek = strengthPerSecond * 604800
                    projectedStrengthLabel.Text = "Strength Pace: " .. formatNumber(strengthPerHour) .. "/Hour | " .. formatNumber(strengthPerDay) .. "/Day | " .. formatNumber(strengthPerWeek) .. "/Week"
                end

                if #durabilityHistory >= 2 then
                    local durabilityDelta = durabilityHistory[#durabilityHistory].value - durabilityHistory[1].value
                    local durabilityPerSecond = durabilityDelta / calculationInterval
                    local durabilityPerHour = durabilityPerSecond * 3600
                    local durabilityPerDay = durabilityPerSecond * 86400
                    local durabilityPerWeek = durabilityPerSecond * 604800
                    projectedDurabilityLabel.Text = "Durability Pace: " .. formatNumber(durabilityPerWeek) .. "/Hour | " .. formatNumber(durabilityPerDay) .. "/Day | " .. formatNumber(durabilityPerWeek) .. "/Week"
                end

                local totalElapsed = fastRepPausedTime + (currentTime - fastRepStartTime)
                if totalElapsed > 0 then
                    local avgStrengthPerSecond = (currentStrength - initialStrength) / totalElapsed
                    local avgStrengthPerHour = avgStrengthPerSecond * 3600
                    local avgStrengthPerDay = avgStrengthPerSecond * 86400
                    local avgStrengthPerWeek = avgStrengthPerSecond * 604800
                    averageStrengthLabel.Text = "Average Strength Pace: " .. formatNumber(avgStrengthPerHour) .. "/Hour | " .. formatNumber(avgStrengthPerDay) .. "/Day | " .. formatNumber(avgStrengthPerWeek) .. "/Week"

                    local avgDurabilityPerSecond = (currentDurability - initialDurability) / totalElapsed
                    local avgDurabilityPerHour = avgDurabilityPerSecond * 3600
                    local avgDurabilityPerDay = avgDurabilityPerSecond * 86400
                    local avgDurabilityPerWeek = avgDurabilityPerSecond * 604800
                    averageDurabilityLabel.Text = "Average Durability Pace: " .. formatNumber(avgDurabilityPerHour) .. "/Hour | " .. formatNumber(avgDurabilityPerDay) .. "/Day | " .. formatNumber(avgDurabilityPerWeek) .. "/Week"
                end
            end
        else
            if fastRepTracking then
                fastRepTracking = false
                fastRepPausedTime = fastRepPausedTime + (currentTime - fastRepStartTime)
                fastRepTimeLabel.Text = string.format("%dd %dh %dm %ds - Fast Rep Stopped", math.floor(fastRepPausedTime / (24 * 3600)), math.floor((fastRepPausedTime % (24 * 3600)) / 3600), math.floor((fastRepPausedTime % 3600) / 60), math.floor(fastRepPausedTime % 60))
                fastRepTimeLabel.TextColor3 = Color3.fromRGB(255, 165, 0)

                projectedStrengthLabel.Text = "Strength Pace: 0 /Hour | 0 /Day | 0 /Week"
                projectedDurabilityLabel.Text = "Durability Pace: 0 /Hour | 0 /Day | 0 /Week"
                averageStrengthLabel.Text = "Average Strength Pace: 0 /Hour | 0 /Day | 0 /Week"
                averageDurabilityLabel.Text = "Average Durability Pace: 0 /Hour | 0 /Day | 0 /Week"

                strengthHistory = {}
                durabilityHistory = {}
            end
        end

        task.wait(0.05)
    end
end)

-- Anti-Lag Function
local function antiLag()
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Clear UI
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            gui:Destroy()
        end
    end
    
    -- Darken sky
    local function darkenSky()
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Sky") then
                v:Destroy()
            end
        end
        
        local darkSky = Instance.new("Sky")
        darkSky.Name = "DarkSky"
        darkSky.SkyboxBk = "rbxassetid://0"
        darkSky.SkyboxDn = "rbxassetid://0"
        darkSky.SkyboxFt = "rbxassetid://0"
        darkSky.SkyboxLf = "rbxassetid://0"
        darkSky.SkyboxRt = "rbxassetid://0"
        darkSky.SkyboxUp = "rbxassetid://0"
        darkSky.Parent = Lighting
        
        Lighting.Brightness = 0
        Lighting.ClockTime = 0
        Lighting.TimeOfDay = "00:00:00"
        Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
        Lighting.Ambient = Color3.new(0, 0, 0)
        Lighting.FogColor = Color3.new(0, 0, 0)
        Lighting.FogEnd = 100
    end
    
    -- Remove particles
    local function removeParticleEffects()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then
                obj:Destroy()
            end
        end
    end
    
    -- Remove lights
    local function removeLightSources()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj:Destroy()
            end
        end
    end
    
    removeParticleEffects()
    removeLightSources()
    darkenSky()
    
    -- Maintain dark environment
    task.spawn(function()
        while true do
            wait(5)
            if not Lighting:FindFirstChild("DarkSky") then
                darkenSky()
            end
            Lighting.Brightness = 0
            Lighting.ClockTime = 0
            Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
            Lighting.Ambient = Color3.new(0, 0, 0)
            Lighting.FogColor = Color3.new(0, 0, 0)
            Lighting.FogEnd = 100
        end
    end)
end

-- Anti-Lag Buttons
FastRebTab:AddButton("Anti Lag", antiLag)
FastStrTab:AddButton("Anti Lag", antiLag)

-- Position Lock Variables
local lockRunning = false
local lockThread = nil

-- Position Lock Function
MiscTab:AddToggle("Lock Position", function(state)
    lockRunning = state
    if lockRunning then
        local char = Player.Character or Player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local lockPosition = hrp.Position
        
        lockThread = coroutine.create(function()
            while lockRunning do
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.RotVelocity = Vector3.new(0, 0, 0)
                hrp.CFrame = CFrame.new(lockPosition)
                wait(0.05)
            end
        end)
        
        coroutine.resume(lockThread)
    end
end)

-- Auto Shake Functions
local function activateShake()
    local tool = Player.Character:FindFirstChild("Tropical Shake") or Player.Backpack:FindFirstChild("Tropical Shake")
    if tool then
        muscleEvent:FireServer("tropicalShake", tool)
    end
end

local shakeRunning = false
task.spawn(function()
    while true do
        if shakeRunning then
            activateShake()
            task.wait(450)
        else
            task.wait(1)
        end
    end
end)

MiscTab:AddToggle("Auto Shake", function(state)
    shakeRunning = state
    if state then
        activateShake()
    end
end)

-- Auto Protein Egg Functions
local function activateProteinEgg()
    local tool = Player.Character:FindFirstChild("Protein Egg") or Player.Backpack:FindFirstChild("Protein Egg")
    if tool then
        muscleEvent:FireServer("proteinEgg", tool)
    end
end

local eggRunning = false
task.spawn(function()
    while true do
        if eggRunning then
            activateProteinEgg()
            task.wait(1800)
        else
            task.wait(1)
        end
    end
end)

MiscTab:AddToggle("Auto Egg", function(state)
    eggRunning = state
    if state then
        activateProteinEgg()
    end
end)

-- Fortune Wheel Automation
MiscTab:AddToggle("Spin Fortune Wheel", function(bool)
    _G.AutoSpinWheel = bool
    
    if bool then
        spawn(function()
            while _G.AutoSpinWheel and wait(1) do
                ReplicatedStorage.rEvents.openFortuneWheelRemote:InvokeServer("openFortuneWheel", ReplicatedStorage.fortuneWheelChances["Fortune Wheel"])
            end
        end)
    end
end)

-- Teleport Functions
MiscTab:AddButton("Jungle Lift", function()
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(-8642.396484375, 6.7980651855, 2086.1030273)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end)

MiscTab:AddButton("Jungle Squat", function()
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(-8371.43359375, 6.79806327, 2858.88525390)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end)

-- Anti-AFK System
local antiAfkRunning = false
local antiAfkThread = nil

MiscTab:AddButton("Anti AFK", function(state)
    antiAfkRunning = state
    if antiAfkRunning then
        antiAfkThread = coroutine.create(function()
            while antiAfkRunning do
                -- Simulate small movement to prevent AFK
                local char = Player.Character or Player.CharacterAdded:Wait()
                local hrp = char:WaitForChild("HumanoidRootPart")
                local originalPos = hrp.Position
                
                -- Small random movement
                hrp.CFrame = hrp.CFrame + Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))
                wait(0.1)
                hrp.CFrame = CFrame.new(originalPos)
                
                wait(60) -- Check every minute
            end
        end)
        coroutine.resume(antiAfkThread)
    end
end)

-- Settings Tab
SettingsTab:AddLabel("Settings Panel")
SettingsTab:AddButton("Reset All", function()
    -- Reset all running functions
    rebirthRunning = false
    fastRepRunning = false
    sizeRunning = false
    lockRunning = false
    shakeRunning = false
    eggRunning = false
    antiAfkRunning = false
    
    MainUI:Notify("Reset", "All settings have been reset!", "Warning", 3)
end)

SettingsTab:AddToggle("Auto Save", true, function(bd)
    print("Auto save:", bd)
end)

-- Event connections
rebirthsStat:GetPropertyChangedSignal("Value"):Connect(function()
    calculateRebirthPace()
    updateRebirthsLabel()
    updateRebirthUI()
end)

-- Update UI loops
task.spawn(function()
    while true do
        updateRebirthUI()
        task.wait(0.1)
    end
end)

-- Block unwanted UI frames
local blockedFrames = {
    "strengthFrame",
    "durabilityFrame", 
    "agilityFrame",
}

for _, name in ipairs(blockedFrames) do
    local frame = ReplicatedStorage:FindFirstChild(name)
    if frame and frame:IsA("GuiObject") then
        frame.Visible = false
    end
end

ReplicatedStorage.ChildAdded:Connect(function(child)
    if table.find(blockedFrames, child.Name) and child:IsA("GuiObject") then
        child.Visible = false
    end
end)

-- Welcome notification
MainUI:Notify("Welcome!", "Elerium V2 x Silence Farming loaded successfully!", "Success", 5)

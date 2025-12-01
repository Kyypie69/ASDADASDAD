--[[
    Elerium V2: Farming Transfer from SilenceV2Farming
]] -- Create the main window

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local username = localPlayer.Name
local userId = localPlayer.UserId
local player = game.Players.LocalPlayer
local muscleEvent = player:WaitForChild("muscleEvent")
local leaderstats = player:WaitForChild("leaderstats")
local rebirthsStat = leaderstats:WaitForChild("Rebirths")

-- Load Elerium V2 UI Library
local EleriumV2_UI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Kyypie69/Library.UI/refs/heads/main/KYY.luau"))()

local c2 = EleriumV2_UI.new({
    MainColor = Color3.fromRGB(138, 43, 226),
    ToggleKey = Enum.KeyCode.Insert,
    MinSize = Vector2.new(600, 600)
})

local aw = c2:CreateWindow("Elerium V2 | Farming", {})

-- Create tabs
local farmingTab = aw:CreateTab("Farming", "Farming")
local settingsTab = aw:CreateTab("Settings", "Settings")
local statsTab = aw:CreateTab("Stats", "Stats")

-- Anti-lag functionality
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

-- Utility functions
local function formatNumber(num)
    if num >= 1e15 then return string.format("%.2fQ", num/1e15) end
    if num >= 1e12 then return string.format("%.2fT", num/1e12) end
    if num >= 1e9 then return string.format("%.2fB", num/1e9) end
    if num >= 1e6 then return string.format("%.2fM", num/1e6) end
    if num >= 1e3 then return string.format("%.2fK", num/1e3) end
    return string.format("%.0f", num)
end

-- Farming variables
local isRunning = false
local startTime = 0
local totalElapsed = 0
local initialRebirths = rebirthsStat.Value
local lastPaceUpdate = 0
local lastRebirthTime = tick()
local lastRebirthValue = rebirthsStat.Value

-- UI Elements
farmingTab:AddLabel("🏃‍♂️ Fast Rebirth Farming")

local timeLabel = farmingTab:AddLabel("Time: 0d 0h 0m 0s - Inactive")
local paceLabel = farmingTab:AddLabel("Pace: 0 / Hour | 0 / Day | 0 / Week")
local averagePaceLabel = farmingTab:AddLabel("Average Pace: 0 / Hour | 0 / Day | 0 / Week")
local rebirthsStatsLabel = farmingTab:AddLabel("Rebirths: "..formatNumber(rebirthsStat.Value).." | Gained: 0")

-- Auto eat egg functionality
local autoEatEggEnabled = false
local autoShakeEnabled = false
local antiAfkEnabled = true
local spawnJungleEnabled = false

-- Anti-AFK functionality
local function antiAfk()
    if antiAfkEnabled then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
        wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        wait(0.1)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.S, false, game)
        wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.S, false, game)
    end
end

-- Auto eat egg functionality  
local function autoEatEgg()
    if autoEatEggEnabled then
        local args = {
            [1] = "eat_egg",
            [2] = "regular_egg"
        }
        
        game:GetService("ReplicatedStorage").RemoteEvents.petEvent:FireServer(unpack(args))
    end
end

-- Auto shake functionality
local function autoShake()
    if autoShakeEnabled then
        local args = {
            [1] = "shake"
        }
        
        game:GetService("ReplicatedStorage").RemoteEvents.petEvent:FireServer(unpack(args))
    end
end

-- Spawn jungle lift and squat functionality
local function spawnJungle()
    if spawnJungleEnabled then
        -- Jungle lift
        local args1 = {
            [1] = "lift",
            [2] = "jungle"
        }
        
        -- Jungle squat
        local args2 = {
            [1] = "squat", 
            [2] = "jungle"
        }
        
        game:GetService("ReplicatedStorage").RemoteEvents.petEvent:FireServer(unpack(args1))
        wait(0.5)
        game:GetService("ReplicatedStorage").RemoteEvents.petEvent:FireServer(unpack(args2))
    end
end

-- Update functions
local function updateRebirthsLabel()
    local gained = rebirthsStat.Value - initialRebirths
    rebirthsStatsLabel.Text = string.format("Rebirths: %s | Gained: %s", 
                                           formatNumber(rebirthsStat.Value), 
                                           formatNumber(gained))
end

local function updateUI(forceUpdate)
    local currentTime = tick()
    local elapsed = isRunning and (currentTime - startTime + totalElapsed) or totalElapsed
    
    local days = math.floor(elapsed / 86400)
    local hours = math.floor((elapsed % 86400) / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = math.floor(elapsed % 60)
    
    timeLabel.Text = string.format("Time: %dd %dh %dm %ds - %s", days, hours, minutes, seconds,
                                 isRunning and "Rebirthing" or "Paused")
    
    if isRunning and (forceUpdate or currentTime - lastPaceUpdate >= 1) then
        local rebirthsGained = rebirthsStat.Value - lastRebirthValue
        local timeSinceLast = currentTime - lastRebirthTime
        
        if rebirthsGained > 0 then
            lastRebirthTime = currentTime
            lastRebirthValue = rebirthsStat.Value
        end
        
        if timeSinceLast > 0 then
            local perHour = (rebirthsGained / timeSinceLast) * 3600
            local perDay = perHour * 24
            local perWeek = perDay * 7
            
            paceLabel.Text = string.format("Pace: %s / Hour | %s / Day | %s / Week",
                                         formatNumber(perHour), formatNumber(perDay), formatNumber(perWeek))
            
            local totalRebirths = rebirthsStat.Value - initialRebirths
            local totalHours = elapsed / 3600
            if totalHours > 0 then
                local avgPerHour = totalRebirths / totalHours
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

-- Main farming function
local function startFarming()
    isRunning = true
    startTime = tick()
    initialRebirths = rebirthsStat.Value
    lastRebirthTime = tick()
    lastRebirthValue = rebirthsStat.Value
    
    c2:Notify("Farming Started!", "Auto rebirth farming has begun", "Success", 3)
    
    while isRunning do
        -- Anti-AFK
        antiAfk()
        
        -- Auto eat egg
        autoEatEgg()
        
        -- Auto shake
        autoShake()
        
        -- Spawn jungle
        spawnJungle()
        
        -- Rebirth functionality
        local args = {
            [1] = "rebirth"
        }
        
        game:GetService("ReplicatedStorage").RemoteEvents.statEvent:FireServer(unpack(args))
        
        -- Update UI
        updateUI()
        
        -- Small delay to prevent spam
        wait(0.1)
    end
end

local function stopFarming()
    isRunning = false
    totalElapsed = totalElapsed + (tick() - startTime)
    c2:Notify("Farming Stopped!", "Auto rebirth farming has been stopped", "Warning", 3)
end

-- UI Controls
farmingTab:AddButton("Start Farming", function()
    if not isRunning then
        startFarming()
    else
        c2:Notify("Already Running!", "Farming is already active", "Warning", 2)
    end
end)

farmingTab:AddButton("Stop Farming", function()
    if isRunning then
        stopFarming()
    else
        c2:Notify("Not Running!", "Farming is not active", "Warning", 2)
    end
end)

-- Settings
settingsTab:AddLabel("⚙️ Farming Settings")

settingsTab:AddToggle("Auto Eat Egg", false, function(value)
    autoEatEggEnabled = value
    c2:Notify("Auto Eat Egg", "Feature " .. (value and "enabled" or "disabled"), value and "Success" or "Warning", 2)
end)

settingsTab:AddToggle("Auto Shake", false, function(value)
    autoShakeEnabled = value
    c2:Notify("Auto Shake", "Feature " .. (value and "enabled" or "disabled"), value and "Success" or "Warning", 2)
end)

settingsTab:AddToggle("Anti-AFK", true, function(value)
    antiAfkEnabled = value
    c2:Notify("Anti-AFK", "Feature " .. (value and "enabled" or "disabled"), value and "Success" or "Warning", 2)
end)

settingsTab:AddToggle("Spawn Jungle", false, function(value)
    spawnJungleEnabled = value
    c2:Notify("Spawn Jungle", "Feature " .. (value and "enabled" or "disabled"), value and "Success" or "Warning", 2)
end)

-- Stats tracking
statsTab:AddLabel("📊 Farming Statistics")

local totalRebirthsLabel = statsTab:AddLabel("Total Rebirths: 0")
local sessionTimeLabel = statsTab:AddLabel("Session Time: 0h 0m 0s")
local rebirthsPerHourLabel = statsTab:AddLabel("Rebirths/Hour: 0")

-- Update stats periodically
spawn(function()
    while true do
        if isRunning then
            updateUI()
            
            -- Update additional stats
            local gained = rebirthsStat.Value - initialRebirths
            totalRebirthsLabel.Text = "Total Rebirths: " .. formatNumber(gained)
            
            local elapsed = isRunning and (tick() - startTime + totalElapsed) or totalElapsed
            local hours = math.floor(elapsed / 3600)
            local minutes = math.floor((elapsed % 3600) / 60)
            local seconds = math.floor(elapsed % 60)
            sessionTimeLabel.Text = string.format("Session Time: %dh %dm %ds", hours, minutes, seconds)
            
            if elapsed > 0 then
                local perHour = gained / (elapsed / 3600)
                rebirthsPerHourLabel.Text = "Rebirths/Hour: " .. formatNumber(perHour)
            end
        end
        wait(1)
    end
end)

-- Rebirth stat change listener
rebirthsStat.Changed:Connect(function()
    updateUI(true)
end)

-- Welcome notification
c2:Notify("Elerium V2 Farming Loaded!", "All features from SilenceV2Farming have been transferred successfully!", "Success", 5)

print("Elerium V2 Farming script loaded successfully!")

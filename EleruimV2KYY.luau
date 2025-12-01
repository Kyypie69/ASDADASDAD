--[[
    Elerium V2: Fixed Farming Script
    Fixed version with proper library integration
]]

-- Wait for game to load
repeat wait() until game:IsLoaded()
repeat wait() until game.Players.LocalPlayer

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local leaderstats = player:WaitForChild("leaderstats")
local rebirthsStat = leaderstats:WaitForChild("Rebirths")

-- Load Elerium V2 UI Library
local EleriumV2_UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kyypie69/Library.UI/refs/heads/main/KYY.luau"))()

-- Create main UI
local c2 = EleriumV2_UI.new({
    MainColor = Color3.fromRGB(138, 43, 226),
    ToggleKey = Enum.KeyCode.Insert,
    MinSize = Vector2.new(500, 450)
})

local aw = c2:CreateWindow("KYY HUB 0.6.9 | Packs Farming", {})

-- Create tabs
local farmingTab = aw:CreateTab("Farming", "Farming")
local settingsTab = aw:CreateTab("Settings", "Settings")
local statsTab = aw:CreateTab("Stats", "Stats")

-- Utility functions
local function formatNumber(num)
    if num >= 1e15 then return string.format("%.2fQ", num/1e15) end
    if num >= 1e12 then return string.format("%.2fT", num/1e12) end
    if num >= 1e9 then return string.format("%.2fB", num/1e9) end
    if num >= 1e6 then return string.format("%.2fM", num/1e6) end
    if num >= 1e3 then return string.format("%.2fK", num/1e3) end
    return string.format("%.0f", num)
end

-- Anti-lag functionality
local function setupAntiLag()
    local blockedFrames = {
        "strengthFrame",
        "durabilityFrame", 
        "agilityFrame",
    }

    -- Hide existing frames
    for _, name in ipairs(blockedFrames) do
        local frame = ReplicatedStorage:FindFirstChild(name)
        if frame and frame:IsA("GuiObject") then
            frame.Visible = false
        end
    end

    -- Hide new frames when added
    ReplicatedStorage.ChildAdded:Connect(function(child)
        if table.find(blockedFrames, child.Name) and child:IsA("GuiObject") then
            child.Visible = false
        end
    end)
end

-- Initialize anti-lag
setupAntiLag()

-- Farming variables
local isRunning = false
local startTime = 0
local totalElapsed = 0
local initialRebirths = rebirthsStat.Value
local lastPaceUpdate = 0

-- Feature toggles
local settings = {
    autoEatEgg = false,
    autoShake = false,
    antiAfk = true,
    spawnJungle = false,
    autoRebirth = false
}

-- UI Elements
farmingTab:AddLabel("🏃‍♂️ Fast Rebirth Farming")

local timeLabel = farmingTab:AddLabel("Time: 0d 0h 0m 0s - Inactive")
local paceLabel = farmingTab:AddLabel("Pace: 0 / Hour | 0 / Day | 0 / Week")
local averagePaceLabel = farmingTab:AddLabel("Average Pace: 0 / Hour | 0 / Day | 0 / Week")
local rebirthsStatsLabel = farmingTab:AddLabel("Rebirths: "..formatNumber(rebirthsStat.Value).." | Gained: 0")

-- Anti-AFK functionality
local function antiAfk()
    if settings.antiAfk and character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if rootPart then
            -- Simple movement to prevent AFK
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
            wait(0.2)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
            wait(0.1)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.S, false, game)
            wait(0.2)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.S, false, game)
        end
    end
end

-- Auto eat egg functionality  
local function autoEatEgg()
    if settings.autoEatEgg then
        local success, err = pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("petEvent") then
                local args = {
                    [1] = "eat_egg",
                    [2] = "regular_egg"
                }
                ReplicatedStorage.RemoteEvents.petEvent:FireServer(unpack(args))
            end
        end)
        if not success then
            print("Auto eat egg error:", err)
        end
    end
end

-- Auto shake functionality
local function autoShake()
    if settings.autoShake then
        local success, err = pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("petEvent") then
                local args = {
                    [1] = "shake"
                }
                ReplicatedStorage.RemoteEvents.petEvent:FireServer(unpack(args))
            end
        end)
        if not success then
            print("Auto shake error:", err)
        end
    end
end

-- Spawn jungle lift and squat functionality
local function spawnJungle()
    if settings.spawnJungle then
        local success, err = pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("petEvent") then
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
                
                ReplicatedStorage.RemoteEvents.petEvent:FireServer(unpack(args1))
                wait(0.5)
                ReplicatedStorage.RemoteEvents.petEvent:FireServer(unpack(args2))
            end
        end)
        if not success then
            print("Spawn jungle error:", err)
        end
    end
end

-- Rebirth functionality
local function doRebirth()
    if settings.autoRebirth then
        local success, err = pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("statEvent") then
                local args = {
                    [1] = "rebirth"
                }
                ReplicatedStorage.RemoteEvents.statEvent:FireServer(unpack(args))
            end
        end)
        if not success then
            print("Rebirth error:", err)
        end
    end
end

-- Update functions
local function updateRebirthsLabel()
    local gained = rebirthsStat.Value - initialRebirths
    rebirthsStatsLabel.Text = string.format("Rebirths: %s | Gained: %s", 
                                           formatNumber(rebirthsStat.Value), 
                                           formatNumber(gained))
end

local function updateUI()
    local currentTime = tick()
    local elapsed = isRunning and (currentTime - startTime + totalElapsed) or totalElapsed
    
    local days = math.floor(elapsed / 86400)
    local hours = math.floor((elapsed % 86400) / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = math.floor(elapsed % 60)
    
    timeLabel.Text = string.format("Time: %dd %dh %dm %ds - %s", days, hours, minutes, seconds,
                                 isRunning and "Active" or "Paused")
    
    if isRunning then
        local totalRebirths = rebirthsStat.Value - initialRebirths
        local totalHours = elapsed / 3600
        
        if totalHours > 0 then
            local avgPerHour = totalRebirths / totalHours
            local avgPerDay = avgPerHour * 24
            local avgPerWeek = avgPerDay * 7
            
            paceLabel.Text = string.format("Current: %s / Hour", formatNumber(avgPerHour))
            averagePaceLabel.Text = string.format("Average: %s / Day | %s / Week",
                                                formatNumber(avgPerDay), formatNumber(avgPerWeek))
        end
    end
    
    updateRebirthsLabel()
end

-- Main farming loop
local function startFarming()
    if isRunning then
        c2:Notify("Already Running!", "Farming is already active", "Warning", 2)
        return
    end
    
    isRunning = true
    startTime = tick()
    initialRebirths = rebirthsStat.Value
    settings.autoRebirth = true
    
    c2:Notify("Farming Started!", "Auto rebirth farming has begun", "Success", 3)
    
    spawn(function()
        while isRunning do
            -- Execute all enabled features
            antiAfk()
            autoEatEgg()
            autoShake()
            spawnJungle()
            doRebirth()
            
            -- Update UI
            updateUI()
            
            -- Small delay to prevent spam
            wait(0.5)
        end
    end)
end

local function stopFarming()
    if not isRunning then
        c2:Notify("Not Running!", "Farming is not active", "Warning", 2)
        return
    end
    
    isRunning = false
    settings.autoRebirth = false
    totalElapsed = totalElapsed + (tick() - startTime)
    c2:Notify("Farming Stopped!", "Auto rebirth farming has been stopped", "Warning", 3)
end

-- UI Controls
farmingTab:AddButton("Start Farming", startFarming)
farmingTab:AddButton("Stop Farming", stopFarming)

-- Settings
settingsTab:AddLabel("⚙️ Farming Settings")

settingsTab:AddToggle("Auto Eat Egg", false, function(value)
    settings.autoEatEgg = value
    c2:Notify("Auto Eat Egg", value and "Enabled" or "Disabled", value and "Success" or "Warning", 2)
end)

settingsTab:AddToggle("Auto Shake", false, function(value)
    settings.autoShake = value
    c2:Notify("Auto Shake", value and "Enabled" or "Disabled", value and "Success" or "Warning", 2)
end)

settingsTab:AddToggle("Anti-AFK", true, function(value)
    settings.antiAfk = value
    c2:Notify("Anti-AFK", value and "Enabled" or "Disabled", value and "Success" or "Warning", 2)
end)

settingsTab:AddToggle("Spawn Jungle", false, function(value)
    settings.spawnJungle = value
    c2:Notify("Spawn Jungle", value and "Enabled" or "Disabled", value and "Success" or "Warning", 2)
end)

-- Stats tracking
statsTab:AddLabel("📊 Farming Statistics")

local totalRebirthsLabel = statsTab:AddLabel("Total Rebirths: 0")
local sessionTimeLabel = statsTab:AddLabel("Session Time: 0h 0m 0s")
local rebirthsPerHourLabel = statsTab:AddLabel("Rebirths/Hour: 0")

-- Update stats periodically
spawn(function()
    while true do
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
        
        wait(1)
    end
end)

-- Rebirth stat change listener
rebirthsStat.Changed:Connect(function()
    updateUI()
end)

-- Character added listener
player.CharacterAdded:Connect(function(char)
    character = char
end)

-- Welcome notification
c2:Notify("Elerium V2 Farming Loaded!", "All features activated successfully!", "Success", 5)

print("Elerium V2 Farming script loaded successfully!")
print("Features: Anti-lag, Anti-AFK, Auto Eat Egg, Auto Shake, Spawn Jungle, Auto Rebirth")

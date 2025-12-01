--[[
    Elerium V2: Complete Fixed Farming Script
    Fixed auto farming + added fast strength
]]

-- Wait for game to load completely
repeat wait() until game:IsLoaded()
repeat wait() until game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Wait for leaderstats
local leaderstats = player:WaitForChild("leaderstats")
local rebirthsStat = leaderstats:WaitForChild("Rebirths")
local strengthStat = leaderstats:WaitForChild("Strength")

-- Load Elerium V2 UI Library
local success, EleriumV2_UI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Kyypie69/Library.UI/refs/heads/main/KYY.luau"))()
end)

if not success then
    print("Failed to load UI library:", EleriumV2_UI)
    return
end

-- Create main UI
local c2 = EleriumV2_UI.new({
    MainColor = Color3.fromRGB(138, 43, 226),
    ToggleKey = Enum.KeyCode.Insert,
    MinSize = Vector2.new(650, 600)
})

local aw = c2:CreateWindow("Elerium V2 x KYY HUB | Packs Farming", {})

-- Create tabs
local farmingTab = aw:CreateTab("Farming", "Farming")
local strengthTab = aw:CreateTab("Strength", "Strength")
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

-- Global settings
local settings = {
    autoFarming = {
        enabled = false,
        autoRebirth = false,
        autoEatEgg = false,
        autoShake = false,
        antiAfk = true,
        spawnJungle = false
    },
    fastStrength = {
        enabled = false,
        method = "click", -- click, auto, burst
        clickSpeed = 10,
        burstInterval = 5
    }
}

-- Farming variables
local farmingStartTime = 0
local totalFarmingTime = 0
local initialRebirths = rebirthsStat.Value
local lastRebirthTime = tick()

-- Strength variables
local strengthStartTime = 0
local initialStrength = strengthStat.Value

-- Anti-lag setup
local function setupAntiLag()
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
end

setupAntiLag()

-- ==================== FARMING FUNCTIONS ====================

-- Anti-AFK function
local function antiAfk()
    if settings.autoFarming.antiAfk and character and humanoid and rootPart then
        local directions = {
            Vector3.new(0, 0, -1),  -- Forward
            Vector3.new(0, 0, 1),   -- Backward
            Vector3.new(-1, 0, 0),  -- Left
            Vector3.new(1, 0, 0)    -- Right
        }
        
        local randomDirection = directions[math.random(1, #directions)]
        rootPart.CFrame = rootPart.CFrame + randomDirection * 2
        wait(0.1)
        rootPart.CFrame = rootPart.CFrame - randomDirection * 2
    end
end

-- Auto eat egg function
local function autoEatEgg()
    if settings.autoFarming.autoEatEgg then
        local success = pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") and 
               ReplicatedStorage.RemoteEvents:FindFirstChild("petEvent") then
                
                ReplicatedStorage.RemoteEvents.petEvent:FireServer("eat_egg", "regular_egg")
            end
        end)
        if not success then
            print("Auto eat egg failed")
        end
    end
end

-- Auto shake function
local function autoShake()
    if settings.autoFarming.autoShake then
        local success = pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") and 
               ReplicatedStorage.RemoteEvents:FindFirstChild("petEvent") then
                
                ReplicatedStorage.RemoteEvents.petEvent:FireServer("shake")
            end
        end)
        if not success then
            print("Auto shake failed")
        end
    end
end

-- Spawn jungle function
local function spawnJungle()
    if settings.autoFarming.spawnJungle then
        local success = pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") and 
               ReplicatedStorage.RemoteEvents:FindFirstChild("petEvent") then
                
                -- Jungle lift
                ReplicatedStorage.RemoteEvents.petEvent:FireServer("lift", "jungle")
                wait(0.3)
                -- Jungle squat
                ReplicatedStorage.RemoteEvents.petEvent:FireServer("squat", "jungle")
            end
        end)
        if not success then
            print("Spawn jungle failed")
        end
    end
end

-- Auto rebirth function
local function autoRebirth()
    if settings.autoFarming.autoRebirth then
        local success = pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") and 
               ReplicatedStorage.RemoteEvents:FindFirstChild("statEvent") then
                
                ReplicatedStorage.RemoteEvents.statEvent:FireServer("rebirth")
            end
        end)
        if not success then
            print("Auto rebirth failed")
        end
    end
end

-- ==================== STRENGTH FUNCTIONS ====================

-- Fast strength click function
local function fastStrengthClick()
    if settings.fastStrength.enabled and settings.fastStrength.method == "click" then
        local success = pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") and 
               ReplicatedStorage.RemoteEvents:FindFirstChild("statEvent") then
                
                ReplicatedStorage.RemoteEvents.statEvent:FireServer("strength")
            end
        end)
        if not success then
            print("Strength click failed")
        end
    end
end

-- Auto strength function
local function autoStrength()
    if settings.fastStrength.enabled and settings.fastStrength.method == "auto" then
        local success = pcall(function()
            if ReplicatedStorage:FindFirstChild("RemoteEvents") and 
               ReplicatedStorage.RemoteEvents:FindFirstChild("statEvent") then
                
                ReplicatedStorage.RemoteEvents.statEvent:FireServer("strength")
            end
        end)
        if not success then
            print("Auto strength failed")
        end
    end
end

-- ==================== MAIN FARMING LOOP ====================

local farmingConnection
local strengthConnection

local function startFarming()
    if settings.autoFarming.enabled then
        c2:Notify("Already Running!", "Farming is already active", "Warning", 2)
        return
    end
    
    settings.autoFarming.enabled = true
    farmingStartTime = tick()
    initialRebirths = rebirthsStat.Value
    
    c2:Notify("Farming Started!", "Auto farming has begun", "Success", 3)
    
    -- Main farming loop
    farmingConnection = RunService.Heartbeat:Connect(function()
        if not settings.autoFarming.enabled then return end
        
        -- Execute all enabled farming features
        antiAfk()
        autoEatEgg()
        autoShake()
        spawnJungle()
        autoRebirth()
        
        wait(0.5) -- Prevent spam
    end)
end

local function stopFarming()
    if not settings.autoFarming.enabled then
        c2:Notify("Not Running!", "Farming is not active", "Warning", 2)
        return
    end
    
    settings.autoFarming.enabled = false
    totalFarmingTime = totalFarmingTime + (tick() - farmingStartTime)
    
    if farmingConnection then
        farmingConnection:Disconnect()
        farmingConnection = nil
    end
    
    c2:Notify("Farming Stopped!", "Auto farming has been stopped", "Warning", 3)
end

-- ==================== STRENGTH LOOP ====================

local function startStrength()
    if settings.fastStrength.enabled then
        c2:Notify("Already Running!", "Strength training is active", "Warning", 2)
        return
    end
    
    settings.fastStrength.enabled = true
    strengthStartTime = tick()
    initialStrength = strengthStat.Value
    
    c2:Notify("Strength Started!", "Fast strength training begun", "Success", 3)
    
    if settings.fastStrength.method == "auto" then
        -- Auto strength loop
        strengthConnection = RunService.Heartbeat:Connect(function()
            if not settings.fastStrength.enabled then return end
            
            autoStrength()
            wait(1 / settings.fastStrength.clickSpeed)
        end)
    elseif settings.fastStrength.method == "burst" then
        -- Burst strength loop
        strengthConnection = RunService.Heartbeat:Connect(function()
            if not settings.fastStrength.enabled then return end
            
            -- Burst of clicks
            for i = 1, 10 do
                if not settings.fastStrength.enabled then break end
                fastStrengthClick()
                wait(0.1)
            end
            
            wait(settings.fastStrength.burstInterval)
        end)
    end
end

local function stopStrength()
    if not settings.fastStrength.enabled then
        c2:Notify("Not Running!", "Strength training not active", "Warning", 2)
        return
    end
    
    settings.fastStrength.enabled = false
    
    if strengthConnection then
        strengthConnection:Disconnect()
        strengthConnection = nil
    end
    
    c2:Notify("Strength Stopped!", "Strength training stopped", "Warning", 3)
end

-- ==================== UI CREATION ====================

-- Farming Tab
farmingTab:AddLabel("🏃‍♂️ Auto Farming Controls")

local farmingTimeLabel = farmingTab:AddLabel("Farming Time: 0d 0h 0m 0s")
local farmingStatusLabel = farmingTab:AddLabel("Status: Inactive")
local rebirthsGainedLabel = farmingTab:AddLabel("Rebirths Gained: 0")
local rebirthsPaceLabel = farmingTab:AddLabel("Rebirths/Hour: 0")

farmingTab:AddButton("Start Auto Farming", startFarming)
farmingTab:AddButton("Stop Auto Farming", stopFarming)

-- Strength Tab
strengthTab:AddLabel("💪 Fast Strength Training")

local strengthTimeLabel = strengthTab:AddLabel("Training Time: 0h 0m 0s")
local strengthStatusLabel = strengthTab:AddLabel("Status: Inactive")
local strengthGainedLabel = strengthTab:AddLabel("Strength Gained: 0")
local strengthPaceLabel = strengthTab:AddLabel("Strength/Hour: 0")

strengthTab:AddButton("Start Strength Training", startStrength)
strengthTab:AddButton("Stop Strength Training", stopStrength)

-- Strength method selection
local strengthMethods = {"click", "auto", "burst"}
strengthTab:AddDropdown("Strength Method", strengthMethods, function(method)
    settings.fastStrength.method = method
    c2:Notify("Method Changed", "Strength method: " .. method, "Info", 2)
end)

-- Settings Tab
settingsTab:AddLabel("⚙️ Auto Farming Settings")

settingsTab:AddToggle("Auto Rebirth", false, function(value)
    settings.autoFarming.autoRebirth = value
    c2:Notify("Auto Rebirth", value and "Enabled" or "Disabled", value and "Success" or "Warning", 2)
end)

settingsTab:AddToggle("Auto Eat Egg", false, function(value)
    settings.autoFarming.autoEatEgg = value
    c2:Notify("Auto Eat Egg", value and "Enabled" or "Disabled", value and "Success" or "Warning", 2)
end)

settingsTab:AddToggle("Auto Shake", false, function(value)
    settings.autoFarming.autoShake = value
    c2:Notify("Auto Shake", value and "Enabled" or "Disabled", value and "Success" or "Warning", 2)
end)

settingsTab:AddToggle("Anti-AFK", true, function(value)
    settings.autoFarming.antiAfk = value
    c2:Notify("Anti-AFK", value and "Enabled" or "Disabled", value and "Success" or "Warning", 2)
end)

settingsTab:AddToggle("Spawn Jungle", false, function(value)
    settings.autoFarming.spawnJungle = value
    c2:Notify("Spawn Jungle", value and "Enabled" or "Disabled", value and "Success" or "Warning", 2)
end)

-- Strength settings
settingsTab:AddLabel("⚙️ Strength Settings")

settingsTab:AddSlider("Click Speed", 1, 20, 10, function(value)
    settings.fastStrength.clickSpeed = value
    c2:Notify("Click Speed", "Set to: " .. value .. " clicks/sec", "Info", 2)
end)

settingsTab:AddSlider("Burst Interval", 1, 10, 5, function(value)
    settings.fastStrength.burstInterval = value
    c2:Notify("Burst Interval", "Set to: " .. value .. " seconds", "Info", 2)
end)

-- Stats Tab
statsTab:AddLabel("📊 Session Statistics")

local totalStatsLabel = statsTab:AddLabel("=== FARMING STATS ===")
local totalRebirthsStatLabel = statsTab:AddLabel("Total Rebirths: 0")
local sessionTimeStatLabel = statsTab:AddLabel("Session Time: 0h 0m 0s")
local avgRebirthsStatLabel = statsTab:AddLabel("Avg Rebirths/Hour: 0")

local strengthStatsLabel = statsTab:AddLabel("=== STRENGTH STATS ===")
local totalStrengthStatLabel = statsTab:AddLabel("Total Strength: 0")
local strengthSessionTimeStatLabel = statsTab:AddLabel("Training Time: 0h 0m 0s")
local avgStrengthStatLabel = statsTab:AddLabel("Avg Strength/Hour: 0")

-- ==================== UPDATE LOOPS ====================

-- Update farming UI
spawn(function()
    while true do
        if settings.autoFarming.enabled then
            local elapsed = tick() - farmingStartTime + totalFarmingTime
            local days = math.floor(elapsed / 86400)
            local hours = math.floor((elapsed % 86400) / 3600)
            local minutes = math.floor((elapsed % 3600) / 60)
            local seconds = math.floor(elapsed % 60)
            
            farmingTimeLabel.Text = string.format("Farming Time: %dd %dh %dm %ds", days, hours, minutes, seconds)
            farmingStatusLabel.Text = "Status: Active"
            
            local gained = rebirthsStat.Value - initialRebirths
            rebirthsGainedLabel.Text = "Rebirths Gained: " .. formatNumber(gained)
            
            if elapsed > 0 then
                local perHour = gained / (elapsed / 3600)
                rebirthsPaceLabel.Text = "Rebirths/Hour: " .. formatNumber(perHour)
            end
        else
            farmingStatusLabel.Text = "Status: Inactive"
        end
        
        wait(1)
    end
end)

-- Update strength UI
spawn(function()
    while true do
        if settings.fastStrength.enabled then
            local elapsed = tick() - strengthStartTime
            local hours = math.floor(elapsed / 3600)
            local minutes = math.floor((elapsed % 3600) / 60)
            local seconds = math.floor(elapsed % 60)
            
            strengthTimeLabel.Text = string.format("Training Time: %dh %dm %ds", hours, minutes, seconds)
            strengthStatusLabel.Text = "Status: Active (" .. settings.fastStrength.method .. ")"
            
            local gained = strengthStat.Value - initialStrength
            strengthGainedLabel.Text = "Strength Gained: " .. formatNumber(gained)
            
            if elapsed > 0 then
                local perHour = gained / (elapsed / 3600)
                strengthPaceLabel.Text = "Strength/Hour: " .. formatNumber(perHour)
            end
        else
            strengthStatusLabel.Text = "Status: Inactive"
        end
        
        wait(1)
    end
end)

-- Update statistics tab
spawn(function()
    while true do
        -- Farming stats
        local farmingGained = rebirthsStat.Value - initialRebirths
        totalRebirthsStatLabel.Text = "Total Rebirths: " .. formatNumber(farmingGained)
        
        local farmingElapsed = totalFarmingTime + (settings.autoFarming.enabled and (tick() - farmingStartTime) or 0)
        local hours = math.floor(farmingElapsed / 3600)
        local minutes = math.floor((farmingElapsed % 3600) / 60)
        local seconds = math.floor(farmingElapsed % 60)
        sessionTimeStatLabel.Text = string.format("Session Time: %dh %dm %ds", hours, minutes, seconds)
        
        if farmingElapsed > 0 then
            local perHour = farmingGained / (farmingElapsed / 3600)
            avgRebirthsStatLabel.Text = "Avg Rebirths/Hour: " .. formatNumber(perHour)
        end
        
        -- Strength stats
        local strengthGained = strengthStat.Value - initialStrength
        totalStrengthStatLabel.Text = "Total Strength: " .. formatNumber(strengthGained)
        
        local strengthElapsed = settings.fastStrength.enabled and (tick() - strengthStartTime) or 0
        hours = math.floor(strengthElapsed / 3600)
        minutes = math.floor((strengthElapsed % 3600) / 60)
        seconds = math.floor(strengthElapsed % 60)
        strengthSessionTimeStatLabel.Text = string.format("Training Time: %dh %dm %ds", hours, minutes, seconds)
        
        if strengthElapsed > 0 then
            local perHour = strengthGained / (strengthElapsed / 3600)
            avgStrengthStatLabel.Text = "Avg Strength/Hour: " .. formatNumber(perHour)
        end
        
        wait(2)
    end
end)

-- Manual strength click for "click" method
strengthTab:AddButton("Manual Strength Click", function()
    if settings.fastStrength.method == "click" then
        fastStrengthClick()
        c2:Notify("Strength Click", "Manual strength gained!", "Success", 1)
    else
        c2:Notify("Wrong Method", "Switch to 'click' method for manual clicking", "Warning", 2)
    end
end)

-- Character change detection
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
end)

-- Welcome notification
c2:Notify("Elerium V2 Complete Loaded!", "Auto farming + Fast strength ready!", "Success", 5)

print("Elerium V2 Complete script loaded successfully!")
print("Features: Auto farming, Fast strength, Anti-lag, Anti-AFK, Auto eat egg, Auto shake, Spawn jungle")

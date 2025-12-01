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
    MainColor = Color3.fromRGB(138, 0, 0),  -- Same color as original
    ToggleKey = Enum.KeyCode.Insert,        -- Added required toggle key
    MinSize = Vector2.new(600, 600)         -- Same size as original
})

-- Create the main window (equivalent to library:AddWindow)
local aw = c2:CreateWindow("Silence | Farming", {})

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
local FastRebTab = aw:CreateTab("Fast Rebirth", "Speed")

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

-- Welcome notification
c2:Notify("Welcome", "Silence Farming with working auto rebirth!", "Success", 4)

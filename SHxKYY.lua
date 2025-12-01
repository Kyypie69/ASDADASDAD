--[[
    Elerium V2xKYY Merged: Enhanced Farming Library
    Transferred from SilenceV2Farming with all features
]]

-- Create the main window
local EleriumV2_UI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Kyypie69/Library.UI/refs/heads/main/KYY.luau"))()

local c2 = EleriumV2_UI.new({
    MainColor = Color3.fromRGB(25, 25, 112),
    ToggleKey = Enum.KeyCode.Insert,
    MinSize   = Vector2.new(500, 350)
})

local aw = c2:CreateWindow("Elerium V2xKYY | Enhanced Farming", {})

-- Game Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Player Setup
local localPlayer = Players.LocalPlayer
local username = localPlayer.Name
local userId = localPlayer.UserId
local player = game.Players.LocalPlayer

-- Game Events and Stats
local muscleEvent = player:WaitForChild("muscleEvent")
local leaderstats = player:WaitForChild("leaderstats")
local rebirthsStat = leaderstats:WaitForChild("Rebirths")
local strengthStat = leaderstats:WaitForChild("Strength")

-- Utility Functions
local function formatNumber(num)
    if num >= 1e15 then return string.format("%.2fQ", num/1e15) end
    if num >= 1e12 then return string.format("%.2fT", num/1e12) end
    if num >= 1e9 then return string.format("%.2fB", num/1e9) end
    if num >= 1e6 then return string.format("%.2fM", num/1e6) end
    if num >= 1e3 then return string.format("%.2fK", num/1e3) end
    return string.format("%.0f", num)
end

local function formatNumberExtended(number)
    local isNegative = number < 0
    number = math.abs(number)
    if number >= 1e15 then
        return (isNegative and "-" or "") .. string.format("%.2fQa", number / 1e15)
    elseif number >= 1e12 then
        return (isNegative and "-" or "") .. string.format("%.2fT", number / 1e12)
    elseif number >= 1e9 then
        return (isNegative and "-" or "") .. string.format("%.2fB", number / 1e9)
    elseif number >= 1e6 then
        return (isNegative and "-" or "") .. string.format("%.2fM", number / 1e6)
    elseif number >= 1e3 then
        return (isNegative and "-" or "") .. string.format("%.2fK", number / 1e3)
    else
        return (isNegative and "-" or "") .. string.format("%.2f", number)
    end
end

-- Block unwanted UI elements
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

-- Fast Rebirth Tab
c3 = aw:CreateTab("Fast Rebirth", "Rebirth")

-- Fast Rebirth Variables
local isRunning = false
local startTime = 0
local totalElapsed = 0
local initialRebirths = rebirthsStat.Value
local lastPaceUpdate = 0

-- Fast Rebirth UI Elements
local serverLabel = c3:AddLabel("Time:")
serverLabel.TextSize = 20
local timeLabel = c3:AddLabel("0d 0h 0m 0s - Inactive")
local paceLabel = c3:AddLabel("Pace: 0 / Hour | 0 / Day | 0 / Week")
local averagePaceLabel = c3:AddLabel("Average Pace: 0 / Hour | 0 / Day | 0 / Week")

paceLabel.TextSize = 17
averagePaceLabel.TextSize = 17
timeLabel.TextSize = 17
timeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)

local rebirthsStatsLabel = c3:AddLabel("Rebirths: "..formatNumber(rebirthsStat.Value).." | Gained: 0")
rebirthsStatsLabel.TextSize = 17

-- Fast Rebirth Functions
local lastRebirthTime = tick()
local lastRebirthValue = rebirthsStat.Value
local paceHistoryHour = {}
local paceHistoryDay = {}
local paceHistoryWeek = {}
local maxHistoryLength = 20
local rebirthCount = 0

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
    
    timeLabel.Text = string.format("%dd %dh %dm %ds - %s", days, hours, minutes, seconds,
                                 isRunning and "Rebirthing" or "Paused")
    timeLabel.TextColor3 = isRunning and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
end

local function calculatePaceOnRebirth()
    rebirthCount = rebirthCount + 1
    
    if rebirthCount < 2 then
        lastRebirthTime = tick()
        lastRebirthValue = rebirthsStat.Value
        return
    end

    local now = tick()
    local gained = rebirthsStat.Value - lastRebirthValue

    if gained > 0 then
        local avgTimePerRebirth = (now - lastRebirthTime) / gained
        local paceHour = 3600 / avgTimePerRebirth
        local paceDay = 86400 / avgTimePerRebirth
        local paceWeek = 604800 / avgTimePerRebirth

        paceLabel.Text = string.format("Pace: %s / Hour | %s / Day | %s / Week",
            formatNumber(paceHour), formatNumber(paceDay), formatNumber(paceWeek))

        table.insert(paceHistoryHour, paceHour)
        table.insert(paceHistoryDay, paceDay)
        table.insert(paceHistoryWeek, paceWeek)

        if #paceHistoryHour > maxHistoryLength then
            table.remove(paceHistoryHour, 1)
            table.remove(paceHistoryDay, 1)
            table.remove(paceHistoryWeek, 1)
        end

        local function average(tbl)
            local sum = 0
            for _, v in ipairs(tbl) do
                sum = sum + v
            end
            return #tbl > 0 and (sum / #tbl) or 0
        end

        local avgHour = average(paceHistoryHour)
        local avgDay = average(paceHistoryDay)
        local avgWeek = average(paceHistoryWeek)

        averagePaceLabel.Text = string.format("Average Pace: %s / Hour | %s / Day | %s / Week",
            formatNumber(avgHour), formatNumber(avgDay), formatNumber(avgWeek))

        lastRebirthTime = now
        lastRebirthValue = rebirthsStat.Value
    end
end

-- Pet Management Functions
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

local function fastRebirthLoop()
    while isRunning do
        managePets("Swift Samurai")
        doRebirth()
        task.wait(0.5)
    end
end

-- Fast Rebirth UI Elements
c3:AddLabel("")

local RebirthLabel = c3:AddLabel("Rebirthing:")
RebirthLabel.TextSize = 20

c3:AddToggle("Fast Rebirth", false, function(state)
    isRunning = state
    
    if state then
        startTime = tick()
        task.spawn(fastRebirthLoop)
    else
        totalElapsed = totalElapsed + (tick() - startTime)
        updateUI(true)
    end
end)

-- Anti-AFK Feature
local lockRunning = false
local lockThread = nil

c3:AddToggle("Anti-AFK", false, function(state)
    lockRunning = state
    if lockRunning then
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
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

-- Auto spawn Jungle Lift
c3:AddButton("Auto Jungle Lift", function()
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(-8642.396484375, 6.7980651855, 2086.1030273)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end)

-- Auto eat protein egg
local proteinRunning = false

task.spawn(function()
    while true do
        if proteinRunning then
            local tool = player.Character:FindFirstChild("Protein Egg") or player.Backpack:FindFirstChild("Protein Egg")
            if tool then
                muscleEvent:FireServer("proteinEgg", tool)
            end
            task.wait(1800)
        else
            task.wait(1)
        end
    end
end)

c3:AddToggle("Auto Protein Egg", false, function(state)
    proteinRunning = state
    if state then
        local tool = player.Character:FindFirstChild("Protein Egg") or player.Backpack:FindFirstChild("Protein Egg")
        if tool then
            muscleEvent:FireServer("proteinEgg", tool)
        end
    end
end)

-- Anti Lag Function
local function antiLag()
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local lighting = game:GetService("Lighting")

    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            gui:Destroy()
        end
    end

    local function darkenSky()
        for _, v in pairs(lighting:GetChildren()) do
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
        darkSky.Parent = lighting

        lighting.Brightness = 0
        lighting.ClockTime = 0
        lighting.TimeOfDay = "00:00:00"
        lighting.OutdoorAmbient = Color3.new(0, 0, 0)
        lighting.Ambient = Color3.new(0, 0, 0)
        lighting.FogColor = Color3.new(0, 0, 0)
        lighting.FogEnd = 100

        task.spawn(function()
            while true do
                wait(5)
                if not lighting:FindFirstChild("DarkSky") then
                    darkSky:Clone().Parent = lighting
                end
                lighting.Brightness = 0
                lighting.ClockTime = 0
                lighting.OutdoorAmbient = Color3.new(0, 0, 0)
                lighting.Ambient = Color3.new(0, 0, 0)
                lighting.FogColor = Color3.new(0, 0, 0)
                lighting.FogEnd = 100
            end
        end)
    end

    local function removeParticleEffects()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then
                obj:Destroy()
            end
        end
    end

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
end

c3:AddButton("Anti Lag", function()
    antiLag()
end)

-- Equip 8 pets Swift Samurai
c3:AddButton("Equip Swift Samurai", function()
    for _, folder in pairs(player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                replicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
    
    local equippedCount = 0
    for _, pet in pairs(player.petsFolder.Unique:GetChildren()) do
        if pet.Name == "Swift Samurai" and equippedCount < 8 then
            replicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
            equippedCount = equippedCount + 1
        end
    end
end)

-- Fast Strength Tab
c4 = aw:CreateTab("Fast Strength", "Strength")

-- Fast Strength Variables
local runFastRep = false
local trackingStarted = false
local startTimeStrength = 0
local pausedElapsedTime = 0
local strengthHistory = {}
local durabilityHistory = {}
local calculationInterval = 10
local initialStrength = strengthStat.Value
local initialDurability = player:WaitForChild("Durability").Value

-- Fast Strength UI Elements
c4:AddLabel("Time:").TextSize = 20
local stopwatchLabel = c4:AddLabel("0d 0h 0m 0s - Fast Rep Inactive")
stopwatchLabel.TextSize = 17
stopwatchLabel.TextColor3 = Color3.fromRGB(255, 50, 50)

local projectedStrengthLabel = c4:AddLabel("Strength Pace: 0 /Hour | 0 /Day | 0 /Week")
projectedStrengthLabel.TextSize = 17
local projectedDurabilityLabel = c4:AddLabel("Durability Pace: 0 /Hour | 0 /Day | 0 /Week")
projectedDurabilityLabel.TextSize = 17
local averageStrengthLabel = c4:AddLabel("Average Strength Pace: 0 /Hour | 0 /Day | 0 /Week")
averageStrengthLabel.TextSize = 17
local averageDurabilityLabel = c4:AddLabel("Average Durability Pace: 0 /Hour | 0 /Day | 0 /Week")
averageDurabilityLabel.TextSize = 17

c4:AddLabel("").TextSize = 10
c4:AddLabel("Stats:").TextSize = 20
local strengthLabel = c4:AddLabel("Strength: 0 | Gained: 0")
strengthLabel.TextSize = 17
local durabilityLabel = c4:AddLabel("Durability: 0 | Gained: 0")
durabilityLabel.TextSize = 17

-- Fast Strength Functions
local function getPing()
    local stats = game:GetService("Stats")
    local pingStat = stats:FindFirstChild("PerformanceStats") and stats.PerformanceStats:FindFirstChild("Ping")
    return pingStat and pingStat:GetValue() or 0
end

local function fastRepLoop()
    local repsPerTick = 1
    while runFastRep do
        local startTick = tick()
        while tick() - startTick < 0.75 and runFastRep do
            for i = 1, repsPerTick do
                muscleEvent:FireServer("rep")
            end
            task.wait(0.02)
        end
        while runFastRep and getPing() >= 350 do
            task.wait(1)
        end
    end
end

-- Fast Strength Rep Speed Textbox
c4:AddTextBox("Rep Speed", function(value)
    local num = tonumber(value)
    if num and num > 0 then
        repsPerTick = math.floor(num)
    end
end, {
    placeholder = "1",
})

-- Fast Strength Toggle
c4:AddToggle("Fast Strength", false, function(state)
    if state and not runFastRep then
        runFastRep = true
        task.spawn(fastRepLoop)
    elseif not state and runFastRep then
        runFastRep = false
    end
end)

-- Auto spawn Jungle Squat
c4:AddButton("Auto Jungle Squat", function()
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(-8371.43359375, 6.79806327, 2858.88525390)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end)

-- Auto eat protein egg and shake for Fast Strength
local proteinStrengthRunning = false
local shakeStrengthRunning = false

task.spawn(function()
    while true do
        if proteinStrengthRunning then
            local tool = player.Character:FindFirstChild("Protein Egg") or player.Backpack:FindFirstChild("Protein Egg")
            if tool then
                muscleEvent:FireServer("proteinEgg", tool)
            end
            task.wait(1800)
        else
            task.wait(1)
        end
    end
end)

task.spawn(function()
    while true do
        if shakeStrengthRunning then
            local tool = player.Character:FindFirstChild("Tropical Shake") or player.Backpack:FindFirstChild("Tropical Shake")
            if tool then
                muscleEvent:FireServer("tropicalShake", tool)
            end
            task.wait(900)
        else
            task.wait(1)
        end
    end
end)

c4:AddToggle("Auto Protein Egg", false, function(state)
    proteinStrengthRunning = state
    if state then
        local tool = player.Character:FindFirstChild("Protein Egg") or player.Backpack:FindFirstChild("Protein Egg")
        if tool then
            muscleEvent:FireServer("proteinEgg", tool)
        end
    end
end)

c4:AddToggle("Auto Shake", false, function(state)
    shakeStrengthRunning = state
    if state then
        local tool = player.Character:FindFirstChild("Tropical Shake") or player.Backpack:FindFirstChild("Tropical Shake")
        if tool then
            muscleEvent:FireServer("tropicalShake", tool)
        end
    end
end)

-- Anti Lag for Fast Strength
c4:AddButton("Anti Lag", function()
    antiLag()
end)

-- Anti-AFK for Fast Strength
c4:AddToggle("Anti-AFK", false, function(state)
    lockRunning = state
    if lockRunning then
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
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

-- Equip 8 pets Swift Samurai for Fast Strength
c4:AddButton("Equip Swift Samurai", function()
    for _, folder in pairs(player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                replicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
    
    local equippedCount = 0
    for _, pet in pairs(player.petsFolder.Unique:GetChildren()) do
        if pet.Name == "Swift Samurai" and equippedCount < 8 then
            replicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
            equippedCount = equippedCount + 1
        end
    end
end)

-- Settings Tab (Previously Info Tab - Modified)
c5 = aw:CreateTab("Settings", "Settings")

c5:AddLabel("Elerium V2xKYY Enhanced")
c5:AddLabel("All features transferred from SilenceV2Farming")
c5:AddLabel("")
c5:AddButton("Reset All Settings", function()
    -- Reset all toggles and states
    isRunning = false
    runFastRep = false
    lockRunning = false
    proteinRunning = false
    proteinStrengthRunning = false
    shakeStrengthRunning = false
    
    c2:Notify("Settings Reset", "All settings have been reset to default!", "Warning", 3)
end)

-- Update loops for UI
task.spawn(function()
    while true do
        updateUI(false)
        task.wait(0.1)
    end
end)

rebirthsStat:GetPropertyChangedSignal("Value"):Connect(function()
    calculatePaceOnRebirth()
    updateRebirthsLabel()
end)

-- Fast Strength Update Loop
task.spawn(function()
    local lastCalcTime = tick()
    while true do
        local currentTime = tick()
        local currentStrength = strengthStat.Value
        local currentDurability = player:WaitForChild("Durability").Value

        strengthLabel.Text = "Strength: " .. formatNumberExtended(currentStrength) .. " | Gained: " .. formatNumberExtended(currentStrength - initialStrength)
        durabilityLabel.Text = "Durability: " .. formatNumberExtended(currentDurability) .. " | Gained: " .. formatNumberExtended(currentDurability - initialDurability)

        if runFastRep then
            if not trackingStarted then
                trackingStarted = true
                startTimeStrength = currentTime
                strengthHistory = {}
                durabilityHistory = {}
            end
            local elapsedTime = pausedElapsedTime + (currentTime - startTimeStrength)
            local days = math.floor(elapsedTime / (24 * 3600))
            local hours = math.floor((elapsedTime % (24 * 3600)) / 3600)
            local minutes = math.floor((elapsedTime % 3600) / 60)
            local seconds = math.floor(elapsedTime % 60)
            stopwatchLabel.Text = string.format("%dd %dh %dm %ds - Fast Rep Running", days, hours, minutes, seconds)
            stopwatchLabel.TextColor3 = Color3.fromRGB(50, 255, 50)

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
                    projectedStrengthLabel.Text = "Strength Pace: " .. formatNumberExtended(strengthPerHour) .. "/Hour | " .. formatNumberExtended(strengthPerDay) .. "/Day | " .. formatNumberExtended(strengthPerWeek) .. "/Week"
                end

                if #durabilityHistory >= 2 then
                    local durabilityDelta = durabilityHistory[#durabilityHistory].value - durabilityHistory[1].value
                    local durabilityPerSecond = durabilityDelta / calculationInterval
                    local durabilityPerHour = durabilityPerSecond * 3600
                    local durabilityPerDay = durabilityPerSecond * 86400
                    local durabilityPerWeek = durabilityPerSecond * 604800
                    projectedDurabilityLabel.Text = "Durability Pace: " .. formatNumberExtended(durabilityPerHour) .. "/Hour | " .. formatNumberExtended(durabilityPerDay) .. "/Day | " .. formatNumberExtended(durabilityPerWeek) .. "/Week"
                end

                local totalElapsed = pausedElapsedTime + (currentTime - startTimeStrength)
                if totalElapsed > 0 then
                    local avgStrengthPerSecond = (currentStrength - initialStrength) / totalElapsed
                    local avgStrengthPerHour = avgStrengthPerSecond * 3600
                    local avgStrengthPerDay = avgStrengthPerSecond * 86400
                    local avgStrengthPerWeek = avgStrengthPerSecond * 604800
                    averageStrengthLabel.Text = "Average Strength Pace: " .. formatNumberExtended(avgStrengthPerHour) .. "/Hour | " .. formatNumberExtended(avgStrengthPerDay) .. "/Day | " .. formatNumberExtended(avgStrengthPerWeek) .. "/Week"

                    local avgDurabilityPerSecond = (currentDurability - initialDurability) / totalElapsed
                    local avgDurabilityPerHour = avgDurabilityPerSecond * 3600
                    local avgDurabilityPerDay = avgDurabilityPerSecond * 86400
                    local avgDurabilityPerWeek = avgDurabilityPerSecond * 604800
                    averageDurabilityLabel.Text = "Average Durability Pace: " .. formatNumberExtended(avgDurabilityPerHour) .. "/Hour | " .. formatNumberExtended(avgDurabilityPerDay) .. "/Day | " .. formatNumberExtended(avgDurabilityPerWeek) .. "/Week"
                end
            end
        else
            if trackingStarted then
                trackingStarted = false
                pausedElapsedTime = pausedElapsedTime + (currentTime - startTimeStrength)
                stopwatchLabel.Text = string.format("%dd %dh %dm %ds - Fast Rep Stopped", math.floor(pausedElapsedTime / (24 * 3600)), math.floor((pausedElapsedTime % (24 * 3600)) / 3600), math.floor((pausedElapsedTime % 3600) / 60), math.floor(pausedElapsedTime % 60))
                stopwatchLabel.TextColor3 = Color3.fromRGB(255, 165, 0)

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

-- Initial notification
c2:Notify("Elerium V2xKYY Loaded", "All features from SilenceV2Farming have been transferred!", "Success", 5)

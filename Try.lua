-- =========  Elerium V2  (2025-12)  =========
local h = game:HttpGet("https://raw.githubusercontent.com/Kyypie69/Library.UI/main/KYY.luau")
local ok, lib = pcall(loadstring, h)
if not ok or not lib then
    game:GetService("StarterGui"):SetCore("SendNotification",{
        Title = "Elerium V2", Text = "Could not load library", Duration = 5
    })
    return
end
lib()                       -- runs the loader; creates global «Elerium»
local UI = Elerium          -- the library table we will use everywhere

-- create the window
local main = UI:new({
    Name        = "Silence | Farming (Elerium V2)",
    MainColor   = Color3.fromRGB(138,0,0),
    ToggleKey   = Enum.KeyCode.RightControl,
    MinSize     = Vector2.new(600,600)
})

-- tabs
local fastRebirthTab = main:CreateTab("Fast Rebirth","Fast Rebirth")
local fastFarmTab    = main:CreateTab("Fast Farm","Fast Farm")
local infoTab        = main:CreateTab("Info","Info")
-- ============================================

-- Game services and player variables
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local localPlayer = Players.LocalPlayer
local leaderstats = localPlayer:WaitForChild("leaderstats")
local rebirthsStat = leaderstats:WaitForChild("Rebirths")
local strengthStat = leaderstats:WaitForChild("Strength")
local muscleEvent = localPlayer:WaitForChild("muscleEvent")

-- Utility function to format large numbers
local function formatNumber(num)
    if num >= 1e15 then return string.format("%.2fQ", num/1e15) end
    if num >= 1e12 then return string.format("%.2fT", num/1e12) end
    if num >= 1e9 then return string.format("%.2fB", num/1e9) end
    if num >= 1e6 then return string.format("%.2fM", num/1e6) end
    if num >= 1e3 then return string.format("%.2fK", num/1e3) end
    return string.format("%.0f", num)
end

-- --- FAST REBIRTH TAB LOGIC ---
local isRunning = false
local startTime = 0
local totalElapsed = 0
local initialRebirths = rebirthsStat.Value
local rebirthCount = 0
local lastRebirthTime = tick()
local lastRebirthValue = rebirthsStat.Value

local paceHistoryHour = {}
local paceHistoryDay = {}
local paceHistoryWeek = {}
local maxHistoryLength = 20

-- UI Elements for Fast Rebirth
local timeLabel = fastRebirthTab:AddLabel("Time: 0d 0h 0m 0s - Inactive")
local paceLabel = fastRebirthTab:AddLabel("Pace: 0 / Hour | 0 / Day | 0 / Week")
local averagePaceLabel = fastRebirthTab:AddLabel("Average Pace: 0 / Hour | 0 / Day | 0 / Week")
local rebirthsStatsLabel = fastRebirthTab:AddLabel("Rebirths: "..formatNumber(rebirthsStat.Value).." | Gained: 0")

fastRebirthTab:AddLabel("--- Fast Rebirth Controls ---")

-- Update UI function for Fast Rebirth
local function updateUI(forceUpdate)
    local currentTime = tick()
    local elapsed = isRunning and (currentTime - startTime + totalElapsed) or totalElapsed
    
    local days = math.floor(elapsed / 86400)
    local hours = math.floor((elapsed % 86400) / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = math.floor(elapsed % 60)
    
    timeLabel.Text = string.format("Time: %dd %dh %dm %ds - %s", days, hours, minutes, seconds,
                                 isRunning and "Rebirthing" or "Paused")
end

-- Calculate pace function
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
            for _, v in ipairs(tbl) do sum = sum + v end
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

-- Rebirth logic functions
local function managePets(petName)
    for _, folder in pairs(localPlayer.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
    
    for _, pet in pairs(localPlayer.petsFolder.Unique:GetChildren()) do
        if pet.Name == petName then
            ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
        end
    end
end

local function doRebirth()
    local rebirths = rebirthsStat.Value
    local strengthTarget = 5000 + (rebirths * 2550)
    
    while isRunning and localPlayer.leaderstats.Strength.Value < strengthTarget do
        local reps = localPlayer.MembershipType == Enum.MembershipType.Premium and 8 or 14
        for _ = 1, reps do
            muscleEvent:FireServer("rep")
        end
        task.wait(0.02)
    end
    
    if isRunning and localPlayer.leaderstats.Strength.Value >= strengthTarget then
        managePets("Tribal Overlord")
        task.wait(0.25)
        
        local before = rebirthsStat.Value
        repeat
            ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
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

-- UI Controls for Fast Rebirth
fastRebirthTab:AddToggle("Fast Rebirth", false, function(state)
    isRunning = state
    
    if state then
        startTime = tick()
        task.spawn(fastRebirthLoop)
    else
        totalElapsed = totalElapsed + (tick() - startTime)
        updateUI(true)
    end
end)

-- Auto Shake for Fast Rebirth
local autoShakeRunning = false
local function activateShake()
    local tool = localPlayer.Character:FindFirstChild("Tropical Shake") or localPlayer.Backpack:FindFirstChild("Tropical Shake")
    if tool then
        muscleEvent:FireServer("tropicalShake", tool)
    end
end
fastRebirthTab:AddToggle("Auto Shake (Rebirth)", false, function(state)
    autoShakeRunning = state
    if state then activateShake() end
end)
task.spawn(function()
    while true do
        if autoShakeRunning then
            activateShake()
            task.wait(450)
        else
            task.wait(1)
        end
    end
end)

-- Spin Fortune Wheel for Fast Rebirth
fastRebirthTab:AddToggle("Spin Fortune Wheel (Rebirth)", false, function(state)
    _G.AutoSpinWheelRebirth = state
    if state then
        spawn(function()
            while _G.AutoSpinWheelRebirth do
                ReplicatedStorage.rEvents.openFortuneWheelRemote:InvokeServer("openFortuneWheel", ReplicatedStorage.fortuneWheelChances["Fortune Wheel"])
                wait(60) -- Wait longer to avoid spamming
            end
        end)
    end
end)

-- Set Size for Fast Rebirth
local sizeRunning = false
fastRebirthTab:AddToggle("Set Size 1", false, function(state)
    sizeRunning = state
    if sizeRunning then
        coroutine.wrap(function()
            while sizeRunning do
                ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", 1)
                wait(0.01)
            end
        end)()
    end
end)

-- Lock Position for Fast Rebirth
local lockRunning = false
fastRebirthTab:AddToggle("Lock Position", false, function(state)
    lockRunning = state
    if lockRunning then
        local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local lockPosition = hrp.Position

        coroutine.wrap(function()
            while lockRunning do
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.RotVelocity = Vector3.new(0, 0, 0)
                hrp.CFrame = CFrame.new(lockPosition)
                wait(0.05)
            end
        end)()
    end
end)

-- Anti-Lag Button for Fast Rebirth
fastRebirthTab:AddButton("Anti Lag", function()
    local playerGui = localPlayer:WaitForChild("PlayerGui")
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
    EleriumV2_UI:Notify("Anti-Lag", "Lag reduction measures activated!", "Success", 3)
end)

-- Jungle Lift Button for Fast Rebirth
fastRebirthTab:AddButton("Jungle Lift", function()
    local char = localPlayer.Character or localPlayer.CharacterAdded:wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(-8642.396484375, 6.7980651855, 2086.1030273)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    EleriumV2_UI:Notify("Jungle Lift", "Teleported to Jungle Lift!", "Info", 2)
end)

-- --- FAST FARM TAB LOGIC ---
local runFastRep = false
local trackingStarted = false
local startTimeFarm = 0
local pausedElapsedTimeFarm = 0

local initialStrength = strengthStat.Value
local initialDurability = localPlayer:WaitForChild("Durability").Value

local strengthHistory = {}
local durabilityHistory = {}
local calculationInterval = 10
local repsPerTick = 1

-- UI Elements for Fast Farm
local stopwatchLabel = fastFarmTab:AddLabel("Time: 0d 0h 0m 0s - Fast Rep Inactive")
local projectedStrengthLabel = fastFarmTab:AddLabel("Strength Pace: 0 /Hour | 0 /Day | 0 /Week")
local projectedDurabilityLabel = fastFarmTab:AddLabel("Durability Pace: 0 /Hour | 0 /Day | 0 /Week")
local averageStrengthLabel = fastFarmTab:AddLabel("Average Strength Pace: 0 /Hour | 0 /Day | 0 /Week")
local averageDurabilityLabel = fastFarmTab:AddLabel("Average Durability Pace: 0 /Hour | 0 /Day | 0 /Week")
fastFarmTab:AddLabel("--- Stats ---")
local strengthLabel = fastFarmTab:AddLabel("Strength: 0 | Gained: 0")
local durabilityLabel = fastFarmTab:AddLabel("Durability: 0 | Gained: 0")

fastFarmTab:AddLabel("--- Fast Farm Controls ---")
fastFarmTab:AddLabel("Recommended Speed: 20")

-- Get Ping function
local function getPing()
    local stats = game:GetService("Stats")
    local pingStat = stats:FindFirstChild("PerformanceStats") and stats.PerformanceStats:FindFirstChild("Ping")
    return pingStat and pingStat:GetValue() or 0
end

-- TextBox for Rep Speed
fastFarmTab:AddTextBox("Rep Speed", "1", function(value)
    local num = tonumber(value)
    if num and num > 0 then
        repsPerTick = math.floor(num)
    end
end)

-- Fast Rep Loop Logic
local function fastRepLoop()
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

-- Toggle for Fast Rep
fastFarmTab:AddToggle("Fast Rep", false, function(state)
    if state and not runFastRep then
        runFastRep = true
        task.spawn(fastRepLoop)
    elseif not state and runFastRep then
        runFastRep = false
    end
end)

-- Auto Shake for Fast Farm
local autoShakeFarmRunning = false
fastFarmTab:AddToggle("Auto Shake (Farm)", false, function(state)
    autoShakeFarmRunning = state
    if state then activateShake() end
end)
task.spawn(function()
    while true do
        if autoShakeFarmRunning then
            activateShake()
            task.wait(900)
        else
            task.wait(1)
        end
    end
end)

-- Auto Egg for Fast Farm
local autoEggRunning = false
local function activateProteinEgg()
    local tool = localPlayer.Character:FindFirstChild("Protein Egg") or localPlayer.Backpack:FindFirstChild("Protein Egg")
    if tool then
        muscleEvent:FireServer("proteinEgg", tool)
    end
end
fastFarmTab:AddToggle("Auto Egg", false, function(state)
    autoEggRunning = state
    if state then activateProteinEgg() end
end)
task.spawn(function()
    while true do
        if autoEggRunning then
            activateProteinEgg()
            task.wait(1800)
        else
            task.wait(1)
        end
    end
end)

-- Spin Fortune Wheel for Fast Farm
fastFarmTab:AddToggle("Spin Fortune Wheel (Farm)", false, function(state)
    _G.AutoSpinWheelFarm = state
    if state then
        spawn(function()
            while _G.AutoSpinWheelFarm do
                ReplicatedStorage.rEvents.openFortuneWheelRemote:InvokeServer("openFortuneWheel", ReplicatedStorage.fortuneWheelChances["Fortune Wheel"])
                wait(60)
            end
        end)
    end
end)

-- Equip Swift Samurai Button for Fast Farm
fastFarmTab:AddButton("Equip Swift Samurai", function()
    local function unequipPets()
        for _, folder in pairs(localPlayer.petsFolder:GetChildren()) do
            if folder:IsA("Folder") then
                for _, pet in pairs(folder:GetChildren()) do
                    ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
                end
            end
        end
        task.wait(0.1)
    end
    local function equipPetsByName(name)
        unequipPets()
        task.wait(0.01)
        for _, pet in pairs(localPlayer.petsFolder.Unique:GetChildren()) do
            if pet.Name == name then
                ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
            end
        end
    end
    equipPetsByName("Swift Samurai")
    EleriumV2_UI:Notify("Pets", "Equipped Swift Samurai!", "Info", 2)
end)

-- Jungle Squat Button for Fast Farm
fastFarmTab:AddButton("Jungle Squat", function()
    local char = localPlayer.Character or localPlayer.CharacterAdded:wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(-8371.43359375, 6.79806327, 2858.88525390)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    EleriumV2_UI:Notify("Jungle Squat", "Teleported to Jungle Squat!", "Info", 2)
end)

-- Anti-Lag Button for Fast Farm (Duplicate, but in the tab)
fastFarmTab:AddButton("Anti Lag", function()
     local playerGui = localPlayer:WaitForChild("PlayerGui")
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
    EleriumV2_UI:Notify("Anti-Lag", "Lag reduction measures activated!", "Success", 3)
end)


-- --- INFO TAB ---
infoTab:AddLabel("Made by Henne ♥️")
infoTab:AddLabel("discord.gg/silencev1")
infoTab:AddButton("Copy Discord Invite", function()
    local link = "https://discord.gg/9eFf93Kg8D"
    -- Use the new library's notify instead of setclipboard check
    EleriumV2_UI:Notify("Discord", "Link copied to clipboard (if supported)!", "Info", 3)
    if setclipboard then
        setclipboard(link)
    end
end)
infoTab:AddLabel("")
infoTab:AddLabel("VERSION//2.0.0 (Elerium V2 UI)")

-- Connect stat updates for UI labels
rebirthsStat:GetPropertyChangedSignal("Value"):Connect(function()
    calculatePaceOnRebirth()
    local gained = rebirthsStat.Value - initialRebirths
    rebirthsStatsLabel.Text = string.format("Rebirths: %s | Gained: %s", formatNumber(rebirthsStat.Value), formatNumber(gained))
end)

-- Fast Farm UI Update Loop
task.spawn(function()
    local lastCalcTime = tick()
    while true do
        local currentTime = tick()
        local currentStrength = strengthStat.Value
        local currentDurability = localPlayer:WaitForChild("Durability").Value

        strengthLabel.Text = "Strength: " .. formatNumber(currentStrength) .. " | Gained: " .. formatNumber(currentStrength - initialStrength)
        durabilityLabel.Text = "Durability: " .. formatNumber(currentDurability) .. " | Gained: " .. formatNumber(currentDurability - initialDurability)

        if runFastRep then
            if not trackingStarted then
                trackingStarted = true
                startTimeFarm = currentTime
                strengthHistory = {}
                durabilityHistory = {}
            end
            local elapsedTime = pausedElapsedTimeFarm + (currentTime - startTimeFarm)
            local days = math.floor(elapsedTime / (24 * 3600))
            local hours = math.floor((elapsedTime % (24 * 3600)) / 3600)
            local minutes = math.floor((elapsedTime % 3600) / 60)
            local seconds = math.floor(elapsedTime % 60)
            stopwatchLabel.Text = string.format("Time: %dd %dh %dm %ds - Fast Rep Running", days, hours, minutes, seconds)

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
                    projectedDurabilityLabel.Text = "Durability Pace: " .. formatNumber(durabilityPerHour) .. "/Hour | " .. formatNumber(durabilityPerDay) .. "/Day | " .. formatNumber(durabilityPerWeek) .. "/Week"
                end

                local totalElapsed = pausedElapsedTimeFarm + (currentTime - startTimeFarm)
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
            if trackingStarted then
                trackingStarted = false
                pausedElapsedTimeFarm = pausedElapsedTimeFarm + (currentTime - startTimeFarm)
                local days = math.floor(pausedElapsedTimeFarm / (24 * 3600))
                local hours = math.floor((pausedElapsedTimeFarm % (24 * 3600)) / 3600)
                local minutes = math.floor((pausedElapsedTimeFarm % 3600) / 60)
                local seconds = math.floor(pausedElapsedTimeFarm % 60)
                stopwatchLabel.Text = string.format("Time: %dd %dh %dm %ds - Fast Rep Stopped", days, hours, minutes, seconds)

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

-- Update Fast Rebirth UI Loop
task.spawn(function()
    while true do
        updateUI(false)
        task.wait(0.1)
    end
end)

-- Initial notification
EleriumV2_UI:Notify("Silence V2 Farming", "Script loaded successfully!", "Success", 3)

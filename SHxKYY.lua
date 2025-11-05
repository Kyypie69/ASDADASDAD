local LIB_URL = "https://raw.githubusercontent.com/Kyypie69/Library.UI/refs/heads/main/Speedhub.UI.lua"
local ok, a, b, c = pcall(function()
	local source = game:HttpGet(LIB_URL)
	local fn = loadstring(source)
	return fn()
end)

local Library, SaveManager, InterfaceManager
if ok then
	Library, SaveManager, InterfaceManager = a, b, c
else
	if getgenv and getgenv().Fluent then
		Library = getgenv().Fluent
		warn("Loaded library from getgenv().Fluent as fallback.")
	else
		error("Failed to load UI library from URL: " .. tostring(a))
	end
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local PET_NAME = "Swift Samurai"
local ROCK_NAME = "Rock5M"
local PROTEIN_EGG_NAME = "ProteinEgg"
local PROTEIN_EGG_INTERVAL = 30 * 60
local REPS_PER_CYCLE = 160
local REP_DELAY = 0.01
local ROCK_INTERVAL = 5
local MAX_PING = 700

local HumanoidRootPart
local lastProteinEggTime = 0
local lastRockTime = 0
local RockRef = workspace:FindFirstChild(ROCK_NAME)
local autoEatEnabled = false
local darkSky

local function getPing()
	local success, ping = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	return success and ping or 999
end

local function updateCharacterRefs()
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	HumanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
end

local function eatProteinEgg()
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
            if item.Name == PROTEIN_EGG_NAME then
                ReplicatedStorage.rEvents.eatEvent:FireServer("eat", item)
                break
            end
        end
    end
end

local function unequipAllPets(a, c)
    local f = c:FindFirstChild("petsFolder")
    if not f then return end
    for _, folder in pairs(f:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                a.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
end

local function equipPetByName(a, c, name)
    local folderPets = c:FindFirstChild("petsFolder")
    if not folderPets then return end
    for _, folder in pairs(folderPets:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                if pet.Name == name then
                    a.rEvents.equipPetEvent:FireServer("equipPet", pet)
                end
            end
        end
    end
end

local function getStrengthRequiredForRebirth(c)
    local rebirths = c.leaderstats.Rebirths.Value
    local baseStrength = 10000 + (5000 * rebirths)
    
    local g = c:FindFirstChild("ultimatesFolder")
    local golden = 0
    if g and g:FindFirstChild("Golden Rebirth") then
        golden = g["Golden Rebirth"].Value
    end
    
    if golden >= 1 and golden <= 5 then
        baseStrength = baseStrength * (1 - golden * 0.1)
    end
    return math.floor(baseStrength)
end

local function hitRock()
    if not RockRef or not RockRef.Parent then
        RockRef = workspace:FindFirstChild(ROCK_NAME)
    end
    if RockRef and HumanoidRootPart then
        HumanoidRootPart.CFrame = RockRef.CFrame * CFrame.new(0, 0, -5)
        ReplicatedStorage.rEvents.hitEvent:FireServer("hit", RockRef)
    end
end

if not getgenv()._AutoRepFarmLoop then
    getgenv()._AutoRepFarmLoop = true

    task.spawn(function()
        updateCharacterRefs()
        
        lastProteinEggTime = tick()
        lastRockTime = tick()
        
        while true do
            if getgenv()._AutoRepFarmEnabled then
                local ping = getPing()
                
                if ping > MAX_PING then
                    task.wait(5)
                else
                    if LocalPlayer:FindFirstChild("muscleEvent") then
                        for i = 1, REPS_PER_CYCLE do
                            LocalPlayer.muscleEvent:FireServer("rep")
                            task.wait(REP_DELAY) 
                        end
                    end
                    
                    if not autoEatEnabled and tick() - lastProteinEggTime >= PROTEIN_EGG_INTERVAL then
                        eatProteinEgg()
                        lastProteinEggTime = tick()
                    end

                    if tick() - lastRockTime >= ROCK_INTERVAL then
                        hitRock()
                        lastRockTime = tick()
                    end
                end
            else
                task.wait(1)
            end
        end
    end)
end

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

local Window = Library:CreateWindow({
    Title = "MARKYYxPRNHUB rawr",
    SubTitle = "Kyy Pie x Cream Fyy",
    Size = UDim2.fromOffset(450,350),
    TabWidth = 160,
	Theme = "SpeedHubX",
	Acrylic = false,
})


local autoFarmTab  = Window:AddTab({Title = "OP Farm",    Icon = "axe"})        -- lightning bolt
local statsTab = Window:AddTab({Title = "Stats", Icon = "bar-chart-2"})-- stats bars
local autoRockTab  = Window:AddTab({Title = "Punch Rock", Icon = "hammer"})     -- mining hammer
local Killer  = Window:AddTab({Title = "Kills",      Icon = "crosshair"})  -- cross-hair
local Teleport  = Window:AddTab({Title = "Teleport",   Icon = "move"})       -- directional arrows
local Crystal  = Window:AddTab({Title = "Crystals",   Icon = "gem"})        -- crystal shape
local Gift  = Window:AddTab({Title = "Gift",       Icon = "gift"})       -- wrapped gift
local Credits  = Window:AddTab({Title = "Credits",    Icon = "star"})       -- golden star


local farmSection = autoFarmTab:AddSection("OP Farm")
farmSection:AddToggle("Fast Rebirth", {
        Title = "Fast Rebirth",
        Default = false,
        Callback = function(v)
    getgenv().AutoFarming = state
    if state then
        task.spawn(function()
            local a = ReplicatedStorage
            local c = LocalPlayer
            local function equipPetByName(name)
                local folderPets = c:FindFirstChild("petsFolder")
                if not folderPets then return end
                for _, folder in pairs(folderPets:GetChildren()) do
                    if folder:IsA("Folder") then
                        for _, pet in pairs(folder:GetChildren()) do
                            if pet.Name == name then
                                a.rEvents.equipPetEvent:FireServer("equipPet", pet)
                            end
                        end
                    end
                end
            end
            local function unequipAllPets()
                local f = c:FindFirstChild("petsFolder")
                if not f then return end
                for _, folder in pairs(f:GetChildren()) do
                    if folder:IsA("Folder") then
                        for _, pet in pairs(folder:GetChildren()) do
                            a.rEvents.equipPetEvent:FireServer("unequipPet", pet)
                        end
                    end
                end
                task.wait(0.1)
            end
            local function getGoldenRebirthCount()
                local g = c:FindFirstChild("ultimatesFolder")
                if g and g:FindFirstChild("Golden Rebirth") then
                    return g["Golden Rebirth"].Value
                end
                return 0
            end
            local function getStrengthRequiredForRebirth()
                local rebirths = c.leaderstats.Rebirths.Value
                local baseStrength = 10000 + (5000 * rebirths)
                local golden = getGoldenRebirthCount()
                if golden >= 1 and golden <= 5 then
                    baseStrength = baseStrength * (1 - golden * 0.01)
                end
                return math.floor(baseStrength)
            end
            while getgenv().AutoFarming do
                local requiredStrength = getStrengthRequiredForRebirth()
                unequipAllPets()
                equipPetByName("Swift Samurai")
                while c.leaderstats.Strength.Value < requiredStrength and getgenv().AutoFarming do
                    for _ = 1, 10 do
                        c.muscleEvent:FireServer("rep")
                    end
                    task.wait()
                end
                if getgenv().AutoFarming then
                    unequipAllPets()
                    equipPetByName("Tribal Overlord")
                    local oldRebirths = c.leaderstats.Rebirths.Value
                    repeat
                        a.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                        task.wait(0.01)
                    until c.leaderstats.Rebirths.Value > oldRebirths or not getgenv().AutoFarming
                end
                task.wait()
            end
        end)
    end
end})

    -- OP Strength
 farmSection:AddToggle("Fast Strength", {
        Title = "Fast Strength",
        Default = false,
        Callback = function(v)
            getgenv()._AutoRepFarmEnabled = v
            warn("[Auto Rep Farm] Estado cambiado a:", v and "ON" or "OFF")
        end
    })


    -- Anti-Lag
farmSection:AddToggle("Anti LAG", {
        Title = "Anti Lag",
        Default = false,
        Callback = function(State)
            local lighting = game:GetService("Lighting")
            -- original antilag code here
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
                    v:Destroy()
                end
            end
            lighting.Brightness = 0
            lighting.ClockTime = 0
            lighting.TimeOfDay = "00:00:00"
            lighting.OutdoorAmbient = Color3.new(0,0,0)
            lighting.Ambient = Color3.new(0,0,0)
        end
    })

    -- Anti-AFK
farmSection:AddSwitch("Anti AFK", {
        Title = "Anti AFK",
        Default = false,
        Callback = function(state)
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer
 
local gui = Instance.new("ScreenGui", player:FindFirstChildOfClass("PlayerGui"))
 
local textLabel = Instance.new("TextLabel", gui)
textLabel.Size = UDim2.new(0, 200, 0, 50)
textLabel.Position = UDim2.new(0.5, -100, 0, -50)
textLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
textLabel.Font = Enum.Font.GothamBold
textLabel.TextSize = 20
textLabel.BackgroundTransparency = 1
textLabel.TextTransparency = 1
 
local timerLabel = Instance.new("TextLabel", gui)
timerLabel.Size = UDim2.new(0, 200, 0, 30)
timerLabel.Position = UDim2.new(0.5, -100, 0, -20)
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 18
timerLabel.BackgroundTransparency = 1
timerLabel.TextTransparency = 1
timerLabel.Text = "00:00:00"
 
local startTime = tick()
 
task.spawn(function()
    while true do
        local elapsed = tick() - startTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = math.floor(elapsed % 60)
        timerLabel.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
        task.wait(1)
    end
end)
 
task.spawn(function()
    while true do
        for i = 0, 1, 0.01 do
            textLabel.TextTransparency = 1 - i
            timerLabel.TextTransparency = 1 - i
            task.wait(0.015)
        end
        task.wait(1.5)
        for i = 0, 1, 0.01 do
            textLabel.TextTransparency = i
            timerLabel.TextTransparency = i
            task.wait(0.015)
        end
        task.wait(0.8)
    end
end)
 
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    print("AFK prevention completed!")
end)
 
textLabel.Text = "ANTI AFK"
		end
                    },
                    {


    -- Hide All Frames
farmSection:AddToggle("Hide Frames", {
        Title = "Hide Frames",
        Default = false,
        Callback = function(bool)
            local rSto = game:GetService("ReplicatedStorage")
            for _, obj in pairs(rSto:GetChildren()) do
                if obj.Name:match("Frame$") then
                    obj.Visible = not bool
                end
            end
        end
    })

    -- Auto Spin
farmSection:AddToggle("Spin Wheel", {
        Title = "Auto Spin Fortune",
        Callback = function()
            _G.AutoSpinWheel = true
            while _G.AutoSpinWheel do
                game:GetService("ReplicatedStorage").rEvents.openFortuneWheelRemote:InvokeServer(
                    "openFortuneWheel",
                    game:GetService("ReplicatedStorage").fortuneWheelChances["Fortune Wheel"]
                )
                task.wait(0.1)
            end
        end
    })

    -- Equip Swift Samurai
farmSection:AddSwitch("Equip Packs", {
        Title = "Equip Swift Samurai",
        Callback = function()
        print("Equipped 7-8 Swift Samurai")

    local LocalPlayer = game:GetService("Players").LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    -- Primero desequipamos todo
    local petsFolder = LocalPlayer:FindFirstChild("petsFolder")
    if not petsFolder then return end

    for _, folder in pairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)

    -- Ahora equipamos mÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡ximo 8 "Swift Samurai"
    local equipped = 0
    local maxEquip = 8
    for _, folder in pairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                if pet.Name == "Swift Samurai" then
                    ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
                    equipped = 1
                    print("Equipado Swift Samurai #" .. equipped)

                    if equipped >= maxEquip then
                        return -- salir cuando ya haya 8 equipados
                    end
                end
            end
        end
    end

    print("Packs " .. equipped .. " Swift Samurai")
end})


    -- Jungle Squat
farmSection:AddSwitch("TP Jungle Squat", {
        Title = "Go Jungle Squat",
        Callback = function()
            local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char:SetPrimaryPartCFrame(CFrame.new(-8374.25586, 34.5933418, 2932.44995))
        
        local machine = workspace:FindFirstChild("machinesFolder")
        if machine and machine:FindFirstChild("Jungle Squat") then
            local seat = machine["Jungle Squat"]:FindFirstChild("interactSeat")
            if seat then
                game:GetService("ReplicatedStorage").rEvents.machineInteractRemote:InvokeServer("useMachine", seat)
            end
        end
      print("[Jungle Squat] Succesful Idiot.")
    else
        warn("[Jungle Squat] Inuts.")
          end
      end
    })

--------------------------------------------------------------------
-- 6.  Stats Farm  (same labels & timers)
--------------------------------------------------------------------
local statsSection = statsTab:AddSection("Stats")
statsSection:AddSwitch("Tracker",
		Title = "Player Stats",
		Callback = function()
local player = game.Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local strengthStat = leaderstats:WaitForChild("Strength")
local durabilityStat = player:WaitForChild("Durability")

local function formatNumber(number)
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

local stopwatchLabel = features:AddLabel("Fast Rep Time: 0d 0h 0m 0s")
stopwatchLabel.TextSize = 20

local projectedStrengthLabel = features:AddLabel("Strength Rate: 0 /Hour | 0 /Day | 0 /Week | 0 /Month")
projectedStrengthLabel.TextSize = 20

local projectedDurabilityLabel = features:AddLabel("Durability Rate: 0 /Hour | 0 /Day | 0 /Week | 0 /Month")
projectedDurabilityLabel.TextSize = 20

features:AddLabel("").TextSize = 10

local statsLabel = features:AddLabel("Stats:")
statsLabel.TextSize = 24

local strengthLabel = features:AddLabel("Strength: 0 | Gained: 0")
strengthLabel.TextSize = 20

local durabilityLabel = features:AddLabel("Durability: 0 | Gained: 0")
durabilityLabel.TextSize = 20

local startTime = tick()
local initialStrength = strengthStat.Value
local initialDurability = durabilityStat.Value
local trackingStarted = false

local strengthHistory = {}
local durabilityHistory = {}
local calculationInterval = 10

task.spawn(function()
    local lastCalcTime = tick()
    while true do
        local currentTime = tick()
        local currentStrength = strengthStat.Value
        local currentDurability = durabilityStat.Value

        if not trackingStarted and (currentStrength - initialStrength) >= 100e9 then
            trackingStarted = true
            startTime = tick()
            strengthHistory = {}
            durabilityHistory = {}
        end

        if trackingStarted then
            local elapsedTime = currentTime - startTime
            local days = math.floor(elapsedTime / (24 * 3600))
            local hours = math.floor((elapsedTime % (24 * 3600)) / 3600)
            local minutes = math.floor((elapsedTime % 3600) / 60)
            local seconds = math.floor(elapsedTime % 60)

            stopwatchLabel.Text = string.format("Fast Rep Time: %dd %dh %dm %ds", days, hours, minutes, seconds)

            local sessionStrengthDelta = currentStrength - initialStrength
            local sessionDurabilityDelta = currentDurability - initialDurability

            strengthLabel.Text = "Strength: " .. formatNumber(currentStrength) .. " | Gained: " .. formatNumber(sessionStrengthDelta)
            durabilityLabel.Text = "Durability: " .. formatNumber(currentDurability) .. " | Gained: " .. formatNumber(sessionDurabilityDelta)

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
                    local strengthPerHour = math.floor(strengthPerSecond * 3600)
                    local strengthPerDay = math.floor(strengthPerSecond * 86400)
                    local strengthPerWeek = math.floor(strengthPerSecond * 604800)
                    local strengthPerMonth = math.floor(strengthPerSecond * 2592000)

                    projectedStrengthLabel.Text = "Strength Rate: " .. formatNumber(strengthPerHour) .. "/Hour | " .. formatNumber(strengthPerDay) .. "/Day | " .. formatNumber(strengthPerWeek) .. "/Week | " .. formatNumber(strengthPerMonth) .. "/Month"
                end

                if #durabilityHistory >= 2 then
                    local durabilityDelta = durabilityHistory[#durabilityHistory].value - durabilityHistory[1].value
                    local durabilityPerSecond = durabilityDelta / calculationInterval
                    local durabilityPerHour = math.floor(durabilityPerSecond * 3600)
                    local durabilityPerDay = math.floor(durabilityPerSecond * 86400)
                    local durabilityPerWeek = math.floor(durabilityPerSecond * 604800)
                    local durabilityPerMonth = math.floor(durabilityPerSecond * 2592000)

                    projectedDurabilityLabel.Text = "Durability Rate: " .. formatNumber(durabilityPerHour) .. "/Hour | " .. formatNumber(durabilityPerDay) .. "/Day | " .. formatNumber(durabilityPerWeek) .. "/Week | " .. formatNumber(durabilityPerMonth) .. "/Month"
                end
            end
        end

        task.wait(0.05)
    end
end)

 local rockSection = autoRockTab:AddSection("Rock Punch")
 local function createAutoToolSwitch(toolName, globalVar)
    autoEquipToolsFolder:AddSwitch("Auto " .. toolName, function(Value)
        _G[globalVar] = Value
        
        if Value then
            local tool = LocalPlayer.Backpack:FindFirstChild(toolName)
            if tool then
                LocalPlayer.Character.Humanoid:EquipTool(tool)
            end
        else
            local character = LocalPlayer.Character
            local equipped = character:FindFirstChild(toolName)
            if equipped then
                equipped.Parent = LocalPlayer.Backpack
            end
        end
        
        task.spawn(function()
            while _G[globalVar] do
                if not _G[globalVar] then break end
                LocalPlayer.muscleEvent:FireServer("rep")
                task.wait(0.1)
            end
        end)
    end)
end

createAutoToolSwitch("Weight", "AutoWeight")
createAutoToolSwitch("Pushups", "AutoPushups")
createAutoToolSwitch("Handstands", "AutoHandstands")
createAutoToolSwitch("Situps", "AutoSitups")


rockSection:AddSwitch("Auto Punch", function(Value)
    _G.fastHitActive = Value
    
    if Value then
        task.spawn(function()
            while _G.fastHitActive do
                if not _G.fastHitActive then break end
                
                local punch = LocalPlayer.Backpack:FindFirstChild("Punch")
                if punch then
                    punch.Parent = LocalPlayer.Character
                    if punch:FindFirstChild("attackTime") then
                        punch.attackTime.Value = 0
                    end
                end
                task.wait(0.1)
            end
        end)
        
        task.spawn(function()
            while _G.fastHitActive do
                if not _G.fastHitActive then break end
                
                LocalPlayer.muscleEvent:FireServer("punch", "rightHand")
                LocalPlayer.muscleEvent:FireServer("punch", "leftHand")
                
                local character = LocalPlayer.Character
                if character then
                    local punchTool = character:FindFirstChild("Punch")
                    if punchTool then
                        punchTool:Activate()
                    end
                end
                task.wait()
            end
        end)
    else
        local character = LocalPlayer.Character
        local equipped = character:FindFirstChild("Punch")
        if equipped then
            equipped.Parent = LocalPlayer.Backpack
        end
    end
end)

rockSection:AddSwitch("Fast Tools", function(Value)
    _G.FastTools = Value
    
    local toolSettings = {
        {"Punch", "attackTime", Value and 0 or 0.01},
        {"Ground Slam", "attackTime", Value and 0 or 6},
        {"Stomp", "attackTime", Value and 0 or 7},
        {"Handstands", "repTime", Value and 0 or 1},
        {"Pushups", "repTime", Value and 0 or 1},
        {"Weight", "repTime", Value and 0 or 1},
        {"Situps", "repTime", Value and 0 or 1}
    }
    
    local backpack = LocalPlayer:WaitForChild("Backpack")
    
    for _, toolInfo in ipairs(toolSettings) do
        local tool = backpack:FindFirstChild(toolInfo[1])
        if tool and tool:FindFirstChild(toolInfo[2]) then
            tool[toolInfo[2]].Value = toolInfo[3]
        end
        
        local equippedTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(toolInfo[1])
        if equippedTool and equippedTool:FindFirstChild(toolInfo[2]) then
            equippedTool[toolInfo[2]].Value = toolInfo[3]
        end
    end
end)


-- ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒâ€¦Ã¢â‚¬â„¢ NUEVO FOLDER ROCKS

local folder = autoRockTab:AddFolder("Rock Farming")
 
local function gettool()
    for i, v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
        if v.Name == "Punch" and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
        end
    end
    game:GetService("Players").LocalPlayer.muscleEvent:FireServer("punch", "leftHand")
    game:GetService("Players").LocalPlayer.muscleEvent:FireServer("punch", "rightHand")
end
 
local tinyIslandRockSwitch = folder:AddSwitch("Farm Tiny Island Rock", function(bool)
    selectrock = "Tiny Island Rock"
    getgenv().autoFarm = bool
 
    if bool then
        spawn(function()
            while getgenv().autoFarm do
                task.wait()
                if game:GetService("Players").LocalPlayer.Durability.Value >= 0 then
                    for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                        if v.Name == "neededDurability" and v.Value == 0 and 
                           game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and 
                           game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
 
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0.01)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0.01)
                            gettool()
                        end
                    end
                end
            end
        end)
    end
end)
 
local starterIslandRockSwitch = folder:AddSwitch("Farm Starter Island Rock", function(bool)
    selectrock = "Starter Island Rock"
    getgenv().autoFarm = bool
 
    if bool then
        spawn(function()
            while getgenv().autoFarm do
                task.wait()
                if game:GetService("Players").LocalPlayer.Durability.Value >= 100 then
                    for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                        if v.Name == "neededDurability" and v.Value == 100 and 
                           game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and 
                           game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
 
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                            gettool()
                        end
                    end
                end
            end
        end)
    end
end)
 
local legendBeachRockSwitch = folder:AddSwitch("Farm Legend Beach Rock", function(bool)
    selectrock = "Legend Beach Rock"
    getgenv().autoFarm = bool
 
    if bool then
        spawn(function()
            while getgenv().autoFarm do
                task.wait()
                if game:GetService("Players").LocalPlayer.Durability.Value >= 5000 then
                    for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                        if v.Name == "neededDurability" and v.Value == 5000 and 
                           game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and 
                           game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
 
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                            gettool()
                        end
                    end
                end
            end
        end)
    end
end)
 
local frostGymRockSwitch = folder:AddSwitch("Farm Frost Gym Rock", function(bool)
    selectrock = "Frost Gym Rock"
    getgenv().autoFarm = bool
 
    if bool then
        spawn(function()
            while getgenv().autoFarm do
                task.wait()
                if game:GetService("Players").LocalPlayer.Durability.Value >= 150000 then
                    for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                        if v.Name == "neededDurability" and v.Value == 150000 and 
                           game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and 
                           game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
 
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                            gettool()
                        end
                    end
                end
            end
        end)
    end
end)
 
local mythicalGymRockSwitch = folder:AddSwitch("Farm Mythical Gym Rock", function(bool)
    selectrock = "Mythical Gym Rock"
    getgenv().autoFarm = bool
 
    if bool then
        spawn(function()
            while getgenv().autoFarm do
                task.wait()
                if game:GetService("Players").LocalPlayer.Durability.Value >= 400000 then
                    for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                        if v.Name == "neededDurability" and v.Value == 400000 and 
                           game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and 
                           game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
 
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                            gettool()
                        end
                    end
                end
            end
        end)
    end
end)
 
local eternalGymRockSwitch = folder:AddSwitch("Farm Eternal Gym Rock", function(bool)
    selectrock = "Eternal Gym Rock"
    getgenv().autoFarm = bool
 
    if bool then
        spawn(function()
            while getgenv().autoFarm do
                task.wait()
                if game:GetService("Players").LocalPlayer.Durability.Value >= 750000 then
                    for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                        if v.Name == "neededDurability" and v.Value == 750000 and 
                           game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and 
                           game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
 
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                            gettool()
                        end
                    end
                end
            end
        end)
    end
end)
 
local legendGymRockSwitch = folder:AddSwitch("Farm Legend Gym Rock", function(bool)
    selectrock = "Legend Gym Rock"
    getgenv().autoFarm = bool
 
    if bool then
        spawn(function()
            while getgenv().autoFarm do
                task.wait()
                if game:GetService("Players").LocalPlayer.Durability.Value >= 1000000 then
                    for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                        if v.Name == "neededDurability" and v.Value == 1000000 and 
                           game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and 
                           game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
 
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                            gettool()
                        end
                    end
                end
            end
        end)
    end
end)
 
local muscleKingGymRockSwitch = folder:AddSwitch("Farm Muscle King Gym Rock", function(bool)
    selectrock = "Muscle King Gym Rock"
    getgenv().autoFarm = bool
 
    if bool then
        spawn(function()
            while getgenv().autoFarm do
                task.wait()
                if game:GetService("Players").LocalPlayer.Durability.Value >= 5000000 then
                    for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                        if v.Name == "neededDurability" and v.Value == 5000000 and 
                           game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and 
                           game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
 
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                            gettool()
                        end
                    end
                end
            end
        end)
    end
end)
 
local ancientJungleRockSwitch = folder:AddSwitch("Farm Ancient Jungle Rock", function(bool)
    selectrock = "Ancient Jungle Rock"
    getgenv().autoFarm = bool
 
    if bool then
        spawn(function()
            while getgenv().autoFarm do
                task.wait()
                if game:GetService("Players").LocalPlayer.Durability.Value >= 10000000 then
                    for i, v in pairs(game:GetService("Workspace").machinesFolder:GetDescendants()) do
                        if v.Name == "neededDurability" and v.Value == 10000000 and 
                           game.Players.LocalPlayer.Character:FindFirstChild("LeftHand") and 
                           game.Players.LocalPlayer.Character:FindFirstChild("RightHand") then
 
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.RightHand, 1)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 0)
                            firetouchinterest(v.Parent.Rock, game:GetService("Players").LocalPlayer.Character.LeftHand, 1)
                            gettool()
                        end
                    end
                end
            end
        end)
    end
end)
 
 
getgenv().StarterIslandBenchPress = false
getgenv().StarterIslandSquat = false
getgenv().StarterIslandDeadlift = false
getgenv().StarterIslandPullUp = false
getgenv().StarterIslandBoulder = false
 
getgenv().LegendBeachBenchPress = false
getgenv().LegendBeachSquat = false
getgenv().LegendBeachDeadlift = false
getgenv().LegendBeachPullUp = false
getgenv().LegendBeachBoulder = false
 
getgenv().FrostGymBenchPress = false
getgenv().FrostGymSquat = false
getgenv().FrostGymDeadlift = false
getgenv().FrostGymPullUp = false
getgenv().FrostGymBoulder = false
 
getgenv().MythicalGymBenchPress = false
getgenv().MythicalGymSquat = false
getgenv().MythicalGymDeadlift = false
getgenv().MythicalGymPullUp = false
getgenv().MythicalGymBoulder = false
 
getgenv().EternalGymBenchPress = false
getgenv().EternalGymSquat = false
getgenv().EternalGymDeadlift = false
getgenv().EternalGymPullUp = false
getgenv().EternalGymBoulder = false
 
getgenv().LegendGymBenchPress = false
getgenv().LegendGymSquat = false
getgenv().LegendGymDeadlift = false
getgenv().LegendGymPullUp = false
getgenv().LegendGymBoulder = false
 
getgenv().MuscleKingGymBenchPress = false
getgenv().MuscleKingGymSquat = false
getgenv().MuscleKingGymDeadlift = false
getgenv().MuscleKingGymPullUp = false
getgenv().MuscleKingGymBoulder = false
 
getgenv().JungleGymBenchPress = false
getgenv().JungleGymSquat = false
getgenv().JungleGymDeadlift = false
getgenv().JungleGymPullUp = false
getgenv().JungleGymBoulder = false
 
local positions = {
    StarterIsland = {
        BenchPress = CFrame.new(-17.0609932, 3.31417918, -2.48164988),
        Squat = CFrame.new(-48.8711243, 3.31417918, -11.8831778),
        Deadlift = CFrame.new(-48.8711243, 3.31417918, -11.8831778),
        PullUp = CFrame.new(-33.3047485, 3.31417918, -11.8831778),
        Boulder = CFrame.new(-33.3047485, 3.31417918, -11.8831778)
    },
    LegendBeach = {
        BenchPress = CFrame.new(470.334656, 3.31417966, -321.053925),
        Squat = CFrame.new(470.334656, 3.31417966, -321.053925),
        Deadlift = CFrame.new(470.334656, 3.31417966, -321.053925),
        PullUp = CFrame.new(470.334656, 3.31417966, -321.053925),
        Boulder = CFrame.new(470.334656, 3.31417966, -321.053925)
    },
    FrostGym = {
        BenchPress = CFrame.new(-3013.24194, 39.2158546, -335.036926),
        Squat = CFrame.new(-2933.47998, 29.6399612, -579.946045),
        Deadlift = CFrame.new(-2933.47998, 29.6399612, -579.946045),
        PullUp = CFrame.new(-2933.47998, 29.6399612, -579.946045),
        Boulder = CFrame.new(-2933.47998, 29.6399612, -579.946045)
    },
    MythicalGym = {
        BenchPress = CFrame.new(2371.7356, 39.2158546, 1246.31555),
        Squat = CFrame.new(2489.21484, 3.67686629, 849.051025),
        Deadlift = CFrame.new(2489.21484, 3.67686629, 849.051025),
        PullUp = CFrame.new(2489.21484, 3.67686629, 849.051025),
        Boulder = CFrame.new(2489.21484, 3.67686629, 849.051025)
    },
    EternalGym = {
        BenchPress = CFrame.new(-7176.19141, 45.394104, -1106.31421),
        Squat = CFrame.new(-7176.19141, 45.394104, -1106.31421),
        Deadlift = CFrame.new(-7176.19141, 45.394104, -1106.31421),
        PullUp = CFrame.new(-7176.19141, 45.394104, -1106.31421),
        Boulder = CFrame.new(-7176.19141, 45.394104, -1106.31421)
    },
    LegendGym = {
        BenchPress = CFrame.new(4111.91748, 1020.46674, -3799.97217),
        Squat = CFrame.new(4304.99023, 987.829956, -4124.2334),
        Deadlift = CFrame.new(4304.99023, 987.829956, -4124.2334),
        PullUp = CFrame.new(4304.99023, 987.829956, -4124.2334),
        Boulder = CFrame.new(4304.99023, 987.829956, -4124.2334)
    },
    MuscleKingGym = {
        BenchPress = CFrame.new(-8590.06152, 46.0167427, -6043.34717),
        Squat = CFrame.new(-8940.12402, 13.1642084, -5699.13477),
        Deadlift = CFrame.new(-8940.12402, 13.1642084, -5699.13477),
        PullUp = CFrame.new(-8940.12402, 13.1642084, -5699.13477),
        Boulder = CFrame.new(-8940.12402, 13.1642084, -5699.13477)
    },
    JungleGym = {
        BenchPress = CFrame.new(-8173, 64, 1898),
        Squat = CFrame.new(-8352, 34, 2878),
        Deadlift = CFrame.new(-8352, 34, 2878),
        PullUp = CFrame.new(-8666, 34, 2070),
        Boulder = CFrame.new(-8621, 34, 2684)
    }
}
 
function teleportLoop(key)
    task.spawn(function()
        while getgenv()[key] do
            local parts = {}
            for loc, workouts in pairs(positions) do
                for workout, cf in pairs(workouts) do
                    if key == loc .. workout then
                        table.insert(parts, cf)
                    end
                end
            end
            if #parts > 0 and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = parts[1]
            end
            task.wait(0.1)
        end
    end)
end
--------------------------------------------------------------------
-- 8.  Kills  (whitelist, auto-kill, follow, etc.)
--------------------------------------------------------------------
    local killSection = Killer:AddSection("OP Farm")
    local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local playerWhitelist = {}
local targetPlayerNames = {}
local autoGoodKarma = false
local autoBadKarma = false
local autoKill = false
local killTarget = false
local spying = false
local autoEquipPunch = false
local autoPunchNoAnim = false
local targetDropdownItems = {}
local availableTargets = {}

local titleLabel = Killer:AddLabel("Equip Packs")
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.Merriweather 
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

local dropdown = Killer:AddDropdown("Select Pet", function(text)
    local petsFolder = game.Players.LocalPlayer.petsFolder
    for _, folder in pairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                game:GetService("ReplicatedStorage").rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.2)

    local petName = text
    local petsToEquip = {}

    for _, pet in pairs(game.Players.LocalPlayer.petsFolder.Unique:GetChildren()) do
        if pet.Name == petName then
            table.insert(petsToEquip, pet)
        end
    end

    local maxPets = 8
    local equippedCount = math.min(#petsToEquip, maxPets)

    for i = 1, equippedCount do
        game:GetService("ReplicatedStorage").rEvents.equipPetEvent:FireServer("equipPet", petsToEquip[i])
        task.wait(0.1)
    end
end)

local Wild_Wizard = dropdown:Add("Wild Wizard")
local Powerful_Monster = dropdown:Add("Mighty Monster")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local friendWhitelistActive = false

killSection:AddTextBox("Whitelist", function(text)
    local target = Players:FindFirstChild(text)
    if target then
        playerWhitelist[target.Name] = true
    end
end)

killSection:AddButton("Nan Size", function()
    local args = {"changeSize", 0/0}
    game:GetService("ReplicatedStorage"):WaitForChild("rEvents"):WaitForChild("changeSpeedSizeRemote"):InvokeServer(unpack(args))
end)
-- ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒâ€¦Ã¢â‚¬Å“ Lista de RAWs a ejecutar
local urls = {
    "https://raw.githubusercontent.com/SadOz8/Stuffs/refs/heads/main/Crack",
    "https://raw.githubusercontent.com/SadOz8/Stuffs/refs/heads/main/Crack2",
    "https://raw.githubusercontent.com/SadOz8/Stuffs/refs/heads/main/Crack3",
    "https://raw.githubusercontent.com/SadOz8/Stuffs/refs/heads/main/Crack4",
    "https://raw.githubusercontent.com/SadOz8/Stuffs/refs/heads/main/Crack5",
    "https://raw.githubusercontent.com/SadOz8/Stuffs/refs/heads/main/Crack6"
}

killSection:AddSwitch("Auto Kill", function(bool)
    autoKill = bool

    task.spawn(function()
        while autoKill do
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local rightHand = character:FindFirstChild("RightHand")
            local leftHand = character:FindFirstChild("LeftHand")

            local punch = LocalPlayer.Backpack:FindFirstChild("Punch")
            if punch and not character:FindFirstChild("Punch") then
                punch.Parent = character
            end

            if rightHand and leftHand then
                for _, target in ipairs(Players:GetPlayers()) do
                    if target ~= LocalPlayer and not playerWhitelist[target.Name] then
                        local targetChar = target.Character
                        local rootPart = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            pcall(function()
                                firetouchinterest(rightHand, rootPart, 1)
                                firetouchinterest(leftHand, rootPart, 1)
                                firetouchinterest(rightHand, rootPart, 0)
                                firetouchinterest(leftHand, rootPart, 0)
                            end)
                        end
                    end
                end
            end

            task.wait(0.05)
        end
    end)
end)

killSection:AddTextBox("UnWhitelist", function(text)
    local target = Players:FindFirstChild(text)
    if target then
        playerWhitelist[target.Name] = nil
    end
end)

killSection:AddSwitch("Auto Whitelist Friends", function(state)
    friendWhitelistActive = state

    if state then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and LocalPlayer:IsFriendsWith(player.UserId) then
                playerWhitelist[player.Name] = true
            end
        end

        Players.PlayerAdded:Connect(function(player)
            if friendWhitelistActive and player ~= LocalPlayer and LocalPlayer:IsFriendsWith(player.UserId) then
                playerWhitelist[player.Name] = true
            end
        end)
    else
        for name in pairs(playerWhitelist) do
            local friend = Players:FindFirstChild(name)
            if friend and LocalPlayer:IsFriendsWith(friend.UserId) then
                playerWhitelist[name] = nil
            end
        end
    end
end)

local targetDropdown = Killer:AddDropdown("Select Target", function(name)
    if name and not table.find(targetPlayerNames, name) then
        table.insert(targetPlayerNames, name)
    end
end)

killSection:AddTextBox("Remove Target", function(name)
    for i, v in ipairs(targetPlayerNames) do
        if v == name then
            table.remove(targetPlayerNames, i)
            break
        end
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        targetDropdown:Add(player.Name)
        targetDropdownItems[player.Name] = true
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        targetDropdown:Add(player.Name)
        targetDropdownItems[player.Name] = true
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if targetDropdownItems[player.Name] then
        targetDropdownItems[player.Name] = nil
        targetDropdown:Clear()
        for name in pairs(targetDropdownItems) do
            targetDropdown:Add(name)
        end
    end

    for i = #targetPlayerNames, 1, -1 do
        if targetPlayerNames[i] == player.Name then
            table.remove(targetPlayerNames, i)
        end
    end
end)

killSection:AddSwitch("Start Kill Target", function(state)
    killTarget = state

    task.spawn(function()
        while killTarget do
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

            local punch = LocalPlayer.Backpack:FindFirstChild("Punch")
            if punch and not character:FindFirstChild("Punch") then
                punch.Parent = character
            end

            local rightHand = character:WaitForChild("RightHand", 5)
            local leftHand = character:WaitForChild("LeftHand", 5)

            if rightHand and leftHand then
                for _, name in ipairs(targetPlayerNames) do
                    local target = Players:FindFirstChild(name)
                    if target and target ~= LocalPlayer then
                        local rootPart = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            pcall(function()
                                firetouchinterest(rightHand, rootPart, 1)
                                firetouchinterest(leftHand, rootPart, 1)
                                firetouchinterest(rightHand, rootPart, 0)
                                firetouchinterest(leftHand, rootPart, 0)
                            end)
                        end
                    end
                end
            end

            task.wait(0.05)
        end
    end)
end)

local spyTargetDropdown = Killer:AddDropdown("Select View Target", function(name)
    targetPlayerName = name
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        spyTargetDropdown:Add(player.Name)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        spyTargetDropdown:Add(player.Name)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player ~= LocalPlayer then
        spyTargetDropdown:Clear()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                spyTargetDropdown:Add(plr.Name)
            end
        end
    end
end)

killSection:AddSwitch("View Player", function(bool)
    spying = bool
    if not spying then
        local cam = workspace.CurrentCamera
        cam.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer
        return
    end
    task.spawn(function()
        while spying do
            local target = Players:FindFirstChild(targetPlayerName)
            if target and target ~= LocalPlayer then
                local humanoid = target.Character and target.Character:FindFirstChild("Humanoid")
                if humanoid then
                    workspace.CurrentCamera.CameraSubject = humanoid
                end
            end
            task.wait(0.1)
        end
    end)
end)
                                                        
killSection:AddSwitch("AutoHitNoAnim]", function(state)
	autoPunchNoAnim = state
	task.spawn(function()
		while autoPunchNoAnim do
			local punch = LocalPlayer.Backpack:FindFirstChild("Punch") or LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Punch")
			if punch then
				if punch.Parent ~= LocalPlayer.Character then
					punch.Parent = LocalPlayer.Character
				end
				LocalPlayer.muscleEvent:FireServer("punch", "rightHand")
				LocalPlayer.muscleEvent:FireServer("punch", "leftHand")
			else
				autoPunchNoAnim = false
			end
			task.wait(0.01)
		end
	end)
end)

killSection:AddSwitch("Quick Hit", function(state)
	_G.autoPunchActive = state
	if state then
		task.spawn(function()
			while _G.autoPunchActive do
				local punch = LocalPlayer.Backpack:FindFirstChild("Punch")
				if punch then
					punch.Parent = LocalPlayer.Character
					if punch:FindFirstChild("attackTime") then
						punch.attackTime.Value = 0
					end
				end
				task.wait()
			end
		end)
		task.spawn(function()
			while _G.autoPunchActive do
				local punch = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Punch")
				if punch then
					punch:Activate()
				end
				task.wait()
			end
		end)
	else
		local punch = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Punch")
		if punch then
			punch.Parent = LocalPlayer.Backpack
		end
	end
end)



local godModeToggle = false
killSection:AddSwitch("God Mode", function(State)
    godModeToggle = State
    if State then
        task.spawn(function()
            while godModeToggle do
                game:GetService("ReplicatedStorage").rEvents.brawlEvent:FireServer("joinBrawl")
                task.wait()
            end
        end)
    end
end)
-- ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒâ€¦Ã¢â‚¬â„¢ Teleport / Follow System (versiÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n auto-follow desde Dropdown)

-- ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒâ€¦Ã¢â‚¬â„¢ Auto Follow (TP detrÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡s del jugador en vez de caminar)
local following = false
local followTarget = nil

-- FunciÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n auxiliar: TP detrÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡s del jugador
function followPlayer(targetPlayer)
    local myChar = LocalPlayer.Character
    local targetChar = targetPlayer.Character

    if not (myChar and targetChar) then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")

    if myHRP and targetHRP then
        -- ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒâ€¦Ã¢â‚¬â„¢ Calcular posiciÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n detrÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡s del jugador (3 studs atrÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡s)
        local followPos = targetHRP.Position - (targetHRP.CFrame.LookVector * 3)
        -- ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒâ€¦Ã¢â‚¬â„¢ Teletransportar siempre recto
        myHRP.CFrame = CFrame.new(followPos, targetHRP.Position)
    end
end

-- Dropdown dinÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡mico de jugadores
local followDropdown = Killer:AddDropdown("Follow Player(TP)", function(selected)
    if selected and selected ~= "" then
        local target = Players:FindFirstChild(selected)
        if target then
            followTarget = target.Name
            following = true
            print("Started following:", target.Name)

            -- TP inmediato al seleccionarlo
            followPlayer(target)
        end
    end
end)

-- Inicializar lista de jugadores
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        followDropdown:Add(player.Name)
    end
end

-- Mantener lista actualizada
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        followDropdown:Add(player.Name)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    followDropdown:Clear()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            followDropdown:Add(plr.Name)
        end
    end
    if followTarget == player.Name then
        followTarget = nil
        following = false
    end
end)

-- BotÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n para dejar de seguir
killSection:AddButton("Unfollow", function()
    following = false
    followTarget = nil
    print("Stopped following")
end)

-- Loop de seguimiento automÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡tico
task.spawn(function()
    while true do
        task.wait(0.2) -- cada 0.2s para actualizar TP
        if following and followTarget then
            local target = Players:FindFirstChild(followTarget)
            if target then
                followPlayer(target)
            else
                following = false
                followTarget = nil
            end
        end
    end
end)

local godDamageActive = false

killSection:AddSwitch("Damage With Godmode", function(state)
    godDamageActive = state
    if state then
        task.spawn(function()
            while godDamageActive do
                local player = game.Players.LocalPlayer
                local groundSlam = player.Backpack:FindFirstChild("Ground Slam") or (player.Character and player.Character:FindFirstChild("Ground Slam"))

                if groundSlam then
                    -- Equipar
                    if groundSlam.Parent == player.Backpack then
                        groundSlam.Parent = player.Character
                    end

                    -- Quitar delay
                    if groundSlam:FindFirstChild("attackTime") then
                        groundSlam.attackTime.Value = 0
                    end

                    -- Lanzar evento
                    player.muscleEvent:FireServer("slam")

                    -- Activar herramienta
                    groundSlam:Activate()
                end

                task.wait(0.1) -- delay pequeÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â±o
            end
        end)
    end
end)



local button = Killer:AddButton("freeze Water", function()
   
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(11, -9, 78)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,1999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-1999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,2999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-3999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,4999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-5999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-6999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-7999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-8999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-9999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-10999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-11999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-12999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-13999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-14999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-15999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-16999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-17999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-18999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-19999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-20999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-21999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-22999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-110, -9,-23999)
    WalkPart.Size = Vector3.new(10000,0,10000)
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-8922.482421875, -9.848660469055176, -6233.65380859375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1107.2977294921875, - 9.7848615646362305, -4127.03369140625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-2054.99365234375, -9.43027928471565247, -5135.06201171875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-3072.01806640625, -9.645418643951416, -6136.02392578125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-4088.711181640625, -9.43027925491333, -5125.28076171875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-5100.0576171875, -9.215141296386719, -5128.03369140625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6103.42626953125, -9.000000953674316, -5590.5859375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-7096.3935546875, -9.784859657287598, -6403.66015625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-9882.7021484375, -9.633520126342773, -5228.537109375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-8889.23046875, -9.418381690979004, -4767.06689453125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-7888.4443359375, -9.203240394592285, -4648.048828125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6868.951171875, -9.988101005554199, -4124.4384765625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-5883.841796875, -9.7729620933532715, -4073.54736328125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-9873.0966796875, -9.26787185668945, -6775.55859375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-8453.767578125, -9.26786804199219, -7212.89013671875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-7482.234375, -9.84866714477539, -8082.72021484375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6483.5791015625, -9.26786422729492, -9055.9033203125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6561.2578125, -9.84867858886719, -10038.5146484375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(1009.69091796875, -9.11653518676758, 1046.963134765625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(2178.023681640625, -9.09156036376953, 287.1599426269531)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(1023.4569091796875, -9.784860134124756, -478.5546569824219)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(1416.96533203125, -9.901395559310913, 2066.506591796875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(1514.3587646484375, -9.686256408691406, 3077.935791015625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(1624.8602294921875, -9.47111701965332, 4074.02587890625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(1687.230712890625, -9.255976676940918, 5069.81640625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(1655.4146728515625, -9.040838241577148, 6056.37451171875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(650.4426879882812, -9.8256990909576416, 6532.1982421875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-347.35028076171875, -9.61055850982666, 6912.1591796875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(218.79769897460938, -9.395420074462891, 7934.68017578125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(251.1740264892578, -9.1802825927734375, 8951.5595703125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(360.1578369140625, -9.9651424884796143, 9967.0107421875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(488.1932067871094, -9.750001907348633, 10972.189453125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(569.8875732421875, -9.5348615646362305, 11982.7353515625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(629.5374755859375, -9.319723129272461, 12985.849609375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(1664.9771728515625, -9.610558986663818, 7491.61181640625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(1945.2432861328125, -9.395420551300049, 8507.6533203125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(904.4902954101562, -9.7848610877990723, -2151.783447265625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(1890.2633056640625, -9.569720268249512, -2413.07421875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(2895.560302734375, -9.354581356048584, -2546.12109375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(3881.858642578125, -9.1394429206848145, -2962.385986328125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(4874.54833984375, -9.9243016242980957, -3218.8798828125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(5892.513671875, -9.709161758422852, -3338.171875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(6886.39990234375, -9.505979061126709, -3488.1533203125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(7863.33056640625, -9.290840148925781, -3597.61279296875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(8840.2548828125, -9.075700759887695, -3711.208740234375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(9838.98046875, -9.8605616092681885, -3811.1064453125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(10812.9287109375, -9.645423412322998, -3987.937744140625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(11798.421875, -9.4302849769592285, -4059.906494140625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(12794.8408203125, -9.215145587921143, -4103.353515625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(13782.353515625, -9.000005722045898, -4253.642578125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(14800.7666015625, -9.7848663330078125, -4368.7177734375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(15813.6171875, -9.569726467132568, -4453.31591796875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(16818.390625, -9.354587078094482, -4569.81396484375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(17821.248046875, -9.139448642730713, -4737.97509765625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(18001.896484375, -9.9243087768554688, -3764.74609375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(17008.357421875, -9.709170341491699, -2794.70751953125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(16014.57421875, -9.49403190612793, -2500.1083984375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(18766.751953125, -9.709169387817383, -2759.8818359375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(19039.708984375, -9.494030475616455, -3743.810546875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(18948.62890625, -9.494030475616455, -1756.02783203125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(17940.4921875, -9.2788920402526855, -755.4782104492188)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(18944.34375, -9.063753604888916, -543.2788696289062)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(16963.00390625, -9.063752174377441, -293.4074401855469)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(15998.7353515625, -9.8486130237579346, -1311.015869140625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(15591.837890625, -9.633473873138428, -296.08660888671875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(14579.58203125, -9.4183349609375, -991.3533935546875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(14294.275390625, -9.203196048736572, -221.879150390625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(13372.7236328125, -9.9880566596984863, 73.62410736083984)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(12783.056640625, -9.093517303466797, -952.5441284179688)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(2003.5675048828125, -9.569721221923828, -1103.451416015625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(2978.824951171875, -9.354583263397217, -1012.9195556640625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(3944.885986328125, -9.139444351196289, -958.9783935546875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(4917.93212890625, -9.9243054389953613, -1106.58837890625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(5321.544921875, -9.709166526794434, -1851.941162109375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(2894.729736328125, -9.9243032932281494, -3897.88720703125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(1880.724609375, -9.709164142608643, -4258.2509765625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1643.215576171875, -9.569722652435303, -3132.36572265625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1772.5018310546875, -9.354584217071533, -2139.459716796875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1665.8314208984375, -9.139444828033447, -1128.0208740234375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1673.664794921875, -9.9243054389953613, -176.67430114746094)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1895.2357177734375, -9.709166526794434, 789.939697265625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1991.6993408203125, -9.494027614593506, 1789.4617919921875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-2148.386962890625, -9.278889179229736, 2777.50146484375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-2334.718505859375, -9.06374979019165, 3752.33056640625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-2430.8857421875, -9.8486104011535645, 4750.89208984375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-2477.38427734375, -9.633471488952637, 5754.65625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1474.8240966796875, -9.418332576751709, 4993.744140625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1239.12744140625, -9.203193664550781, 4206.31005859375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1682.2164306640625, -9.418331623077393, 6633.03125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1427.5582275390625, -9.203193187713623, 7548.80224609375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-3823.29248046875, -9.063750267028809, 1757.0218505859375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-4112.26171875, -9.848611354827881, 2757.71484375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-4299.38330078125, -9.633472919464111, 3713.58056640625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-4433.6865234375, -9.4183349609375, 4715.2236328125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-4646.71728515625, -9.203195571899414, 5683.84765625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-3911.37353515625, -9.988056182861328, 6502.482421875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-3161.617431640625, -9.772918224334717, 6943.85986328125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-2052.14599609375, -9.9880542755126953, 8546.2861328125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1400.4658203125, -9.772915363311768, 9297.806640625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-1190.1282958984375, -9.4422254264354706, 10259.5078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(2187.53564453125, -9.180280685424805, 9414.32421875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(2896.7841796875, -9.180281639099121, 7566.1171875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(3187.329345703125, -9.9651424884796143, 6555.640625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(3379.880615234375, -9.750005722045898, 5558.48876953125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(3961.218017578125, -9.754025459289551, 6907.60400390625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(3976.142822265625, -9.538886547088623, 7871.6318359375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-3126.83544921875, -9.84867262840271, 802.1668090820312)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-3662.20703125, -9.633533477783203, -80.66658020019531)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-3609.484130859375, -9.418395519256592, -1017.3029174804688)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-3753.300537109375, -9.2032551765441895, -1995.7613525390625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-4743.466796875, -9.9881160259246826, -2393.3125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-5736.89892578125, -9.772977828979492, -2010.5301513671875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-4006.782958984375, -9.772977352142334, -3332.644287109375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-3065.00146484375, -9.557837963104248, -3415.263916015625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-4635.92431640625, -9.418395519256592, -103.13423919677734)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-5439.66796875, -9.203256607055664, 866.9227294921875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-5770.49462890625, -9.9881179332733154, 1845.7347412109375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-5798.58203125, -9.772978782653809, 2813.786376953125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6413.759765625, -9.9881181716918945, 45.978721618652344)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-7281.08837890625, -9.342700004577637, -2053.28173828125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-5939.85009765625, -9.557838439941406, -2980.478515625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(3151.140380859375, -9.8764214515686035, 645.57568359375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(4175.984375, -9.661282062530518, 688.4006958007812)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(3677.688232421875, -9.44614315032959, 1697.672607421875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(2702.431640625, -9.231003761291504, 2118.501953125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(3402.743896484375, -9.015864849090576, 3122.62060546875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(3311.645263671875, -9.800727367401123, 4067.2041015625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(4368.765625, -9.800727128982544, 3317.60009765625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(4876.06005859375, -9.585587978363037, 4320.9013671875)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(5258.15771484375, -9.370449542999268, 5299.39990234375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(5620.71923828125, -9.155311584472656, 6254.36181640625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(5176.56591796875, -9.585587978363037, 2400.698486328125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(6081.796875, -9.370450019836426, 3295.412109375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(5741.1318359375, -9.370449066162109, 1432.1351318359375)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(5813.77685546875, -9.155310153961182, 415.4798889160156)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(6412.279296875, -9.9401707649230957, -563.8019409179688)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(6898.72900390625, -9.725030422210693, -1527.509765625)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
    
    
    
    
    local WalkPart = Instance.new("Part")
    WalkPart.Parent = Game.Workspace
    WalkPart.Anchored = true
    WalkPart.Position = Vector3.new(-6474.01318359375, -9.557838439941406, -1076.6319580078125)
    WalkPart.Size = Vector3.new(20000,0,20000)
end)

Kills:AddButton("Stick Dead", function()
    for _, url in ipairs(urls) do
        spawn(function()
            local success, response = pcall(function()
                return game:HttpGet(url)
            end)
            if success and response then
                local loadSuccess, err = pcall(function()
                    loadstring(response)()
                end)
                if not loadSuccess then
                    warn("[Pegar Muerto] Error ejecutando raw:", url, err)
                end
            else
                warn("[Pegar Muerto] No se pudo cargar:", url)
            end
        end)
    end
end)
--------------------------------------------------------------------
-- 9.  Teleport  (all islands)
--------------------------------------------------------------------
do
    local Teleport = Teleport:AddSection("Locations")
    local places = {
        {"Spawn",           CFrame.new(2, 8, 115)},
        {"Secret Area",     CFrame.new(1947, 2, 6191)},
        {"Tiny Island",     CFrame.new(-34, 7, 1903)},
        {"Frozen Island",   CFrame.new(-2600.00244, 3.67686558, -403.884369)},
        {"Mythical Island", CFrame.new(2255, 7, 1071)},
        {"***** Island",    CFrame.new(-6768, 7, -1287)},
        {"Legend Island",   CFrame.new(4604, 991, -3887)},
        {"Muscle King",     CFrame.new(-8646, 17, -5738)},
        {"Jungle Island",   CFrame.new(-8659, 6, 2384)},
        {"Brawl Lava",      CFrame.new(4471, 119, -8836)},
        {"Brawl Desert",    CFrame.new(960, 17, -7398)},
        {"Brawl Regular",   CFrame.new(-1849, 20, -6335)}
    }
    for _, v in ipairs(places) do
        T:AddButton({
            Title = v[1],
            Callback = function()
                game.Players.LocalPlayer.Character:PivotTo(v[2])
            end
        })
    end
end

--------------------------------------------------------------------
-- 10.  Crystals  (auto-buy pets & auras)
--------------------------------------------------------------------
    local crystalSection = Crystal:AddSection("OP Farm")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Crystal data structure with exact names from your original code
local crystalData = {
    ["Blue Crystal"] = {
        {name = "Blue Birdie", rarity = "Basic"},
        {name = "Orange Hedgehog", rarity = "Basic"},
        {name = "Blue Aura", rarity = "Basic"},
        {name = "Red Kitty", rarity = "Basic"},
        {name = "Dark Vampy", rarity = "Advanced"},
        {name = "Blue Bunny", rarity = "Basic"},
        {name = "Red Aura", rarity = "Basic"},
        {name = "Blue Aura", rarity = "Basic"},
        {name = "Green Aura", rarity = "Basic"},
        {name = "Purple Aura", rarity = "Basic"},
        {name = "Red Aura", rarity = "Basic"},
        {name = "Yellow Aura", rarity = "Basic"}
    },
    ["Green Crystal"] = {
        {name = "Silver Dog", rarity = "Basic"},
        {name = "Green Aura", rarity = "Advanced"},
        {name = "Dark Golem", rarity = "Advanced"},
        {name = "Green Butterfly", rarity = "Advanced"},
        {name = "Crimson Falcon", rarity = "Rare"},
        {name = "Red Aura", rarity = "Basic"},
        {name = "Blue Aura", rarity = "Basic"},
        {name = "Green Aura", rarity = "Basic"},
        {name = "Purple Aura", rarity = "Basic"},
        {name = "Red Aura", rarity = "Basic"},
        {name = "Yellow Aura", rarity = "Basic"}
    },
    ["Frost Crystal"] = {
        {name = "Yellow Butterfly", rarity = "Advanced"},
        {name = "Purple Dragon", rarity = "Rare"},
        {name = "Blue Pheonix", rarity = "Epic"},
        {name = "Orange Pegasus", rarity = "Rare"},
        {name = "Lightning", rarity = "Rare"},
        {name = "Electro", rarity = "Advanced"}
    },
    ["Mythical Crystal"] = {
        {name = "Purple Falcon", rarity = "Rare"},
        {name = "Red Dragon", rarity = "Rare"},
        {name = "Blue Firecaster", rarity = "Epic"},
        {name = "Golden Pheonix", rarity = "Epic"},
        {name = "Power Lightning", rarity = "Rare"},
        {name = "Dark Lightning", rarity = "Epic"}
    },
    ["Inferno Crystal"] = {
        {name = "Red Firecaster", rarity = "Epic"},
        {name = "Infernal Dragon", rarity = "Unique"},
        {name = "White Pegasus", rarity = "Rare"},
        {name = "Golden Pheonix", rarity = "Epic"},
        {name = "Inferno", rarity = "Epic"},
        {name = "Dark Storm", rarity = "Unique"}
    },
    ["Legends Crystal"] = {
        {name = "Ultra Birdie", rarity = "Unique"},
        {name = "Magic Butterfly", rarity = "Unique"},
        {name = "Green Firecaster", rarity = "Epic"},
        {name = "White Pheonix", rarity = "Epic"},
        {name = "Supernova", rarity = "Epic"},
        {name = "Purple Nova", rarity = "Unique"}
    },
    ["Muscle Elite Crystal"] = {
        {name = "Frostwave Legends Penguin", rarity = "Rare"},
        {name = "Phantom Genesis Dragon", rarity = "Rare"},
        {name = "Dark Legends Manticore", rarity = "Epic"},
        {name = "Ultimate Supernova Pegasus", rarity = "Epic"},
        {name = "Aether Spirit Bunny", rarity = "Unique"},
        {name = "Cybernetic Showdown Dragon", rarity = "Unique"}
    },
    ["Galaxy Oracle Crystal"] = {
        {name = "Eternal Strike Leviathan", rarity = "Rare"},
        {name = "Lightning Strike Phantom", rarity = "Epic"},
        {name = "Darkstar Hunter", rarity = "Unique"},
        {name = "Muscle King", rarity = "Unique"},
        {name = "Azure Tundra", rarity = "Epic"},
        {name = "Ultra Inferno", rarity = "Rare"}
    },
    ["Jungle Crystal"] = {
        {name = "Entropic Blast", rarity = "Unique"},
        {name = "Muscle Sensei", rarity = "Unique"},
        {name = "Grand Supernova", rarity = "Epic"},
        {name = "Neon Guardian", rarity = "Unique"},
        {name = "Eternal Megastrike", rarity = "Unique"},
        {name = "Golden Viking", rarity = "Epic"},
        {name = "Astral Electro", rarity = "Epic"},
        {name = "Dark Electro", rarity = "Epic"},
        {name = "Enchanted Mirage", rarity = "Epic"},
        {name = "Ultra Mirage", rarity = "Unique"},
        {name = "Unstable Mirage", rarity = "Unique"}
    }
}

-- Function to collect all unique pets and auras
local function getAllPetsAndAuras()
    local allPets = {}
    local allAuras = {}
    
    for crystalName, pets in pairs(crystalData) do
        for _, pet in ipairs(pets) do
            if string.find(pet.name, "Aura") then
                if not allAuras[pet.name] then
                    allAuras[pet.name] = {name = pet.name, rarity = pet.rarity, crystal = crystalName}
                end
            else
                if not allPets[pet.name] then
                    allPets[pet.name] = {name = pet.name, rarity = pet.rarity, crystal = crystalName}
                end
            end
        end
    end
    
    return allPets, allAuras
end

-- Function to find which crystal contains a specific pet/aura
local function findCrystalForItem(itemName)
    for crystalName, pets in pairs(crystalData) do
        for _, pet in ipairs(pets) do
            if pet.name == itemName then
                return crystalName
            end
        end
    end
    return nil
end

-- Variables to track current selections
local selectedPet = ""
local selectedAura = ""

-- Get all pets and auras
local allPets, allAuras = getAllPetsAndAuras()

pets:AddLabel("=== Buy pets and auras ===")

-- Pet dropdown
local petDropdown = pets:AddDropdown("Select pet", function(text)
    selectedPet = text
    local crystal = findCrystalForItem(text)
    print("Pet selected: " .. text .. " (Found in: " .. (crystal or "Unknown") .. ")")
end)

-- Add all pets manually (sorted by rarity)
-- Basic Pets
petDropdown:Add("Blue Birdie (Basic)")
petDropdown:Add("Orange Hedgehog (Basic)")
petDropdown:Add("Red Kitty (Basic)")
petDropdown:Add("Blue Bunny (Basic)")
petDropdown:Add("Silver Dog (Basic)")

-- Advanced Pets
petDropdown:Add("Dark Vampy (Advanced)")
petDropdown:Add("Dark Golem (Advanced)")
petDropdown:Add("Green Butterfly (Advanced)")
petDropdown:Add("Yellow Butterfly (Advanced)")

-- Rare Pets
petDropdown:Add("Crimson Falcon (Rare)")
petDropdown:Add("Purple Dragon (Rare)")
petDropdown:Add("Orange Pegasus (Rare)")
petDropdown:Add("Purple Falcon (Rare)")
petDropdown:Add("Red Dragon (Rare)")
petDropdown:Add("White Pegasus (Rare)")
petDropdown:Add("Frostwave Legends Penguin (Rare)")
petDropdown:Add("Phantom Genesis Dragon (Rare)")
petDropdown:Add("Eternal Strike Leviathan (Rare)")

-- Epic Pets
petDropdown:Add("Blue Pheonix (Epic)")
petDropdown:Add("Blue Firecaster (Epic)")
petDropdown:Add("Golden Pheonix (Epic)")
petDropdown:Add("Red Firecaster (Epic)")
petDropdown:Add("Green Firecaster (Epic)")
petDropdown:Add("White Pheonix (Epic)")
petDropdown:Add("Dark Legends Manticore (Epic)")
petDropdown:Add("Ultimate Supernova Pegasus (Epic)")
petDropdown:Add("Lightning Strike Phantom (Epic)")
petDropdown:Add("Golden Viking (Epic)")

-- Unique Pets
petDropdown:Add("Infernal Dragon (Unique)")
petDropdown:Add("Ultra Birdie (Unique)")
petDropdown:Add("Magic Butterfly (Unique)")
petDropdown:Add("Aether Spirit Bunny (Unique)")
petDropdown:Add("Cybernetic Showdown Dragon (Unique)")
petDropdown:Add("Darkstar Hunter (Unique)")
petDropdown:Add("Muscle Sensei (Unique)")
petDropdown:Add("Neon Guardian (Unique)")

-- Aura dropdown
local auraDropdown = pets:AddDropdown("Select Aura", function(text)
    selectedAura = text
    local crystal = findCrystalForItem(text)
    print("Aura selected: " .. text .. " (Found in: " .. (crystal or "Unknown") .. ")")
end)

-- Add all auras manually (sorted by rarity)
-- Basic Auras
auraDropdown:Add("Blue Aura (Basic)")
auraDropdown:Add("Green Aura (Basic)")
auraDropdown:Add("Purple Aura (Basic)")
auraDropdown:Add("Red Aura (Basic)")
auraDropdown:Add("Yellow Aura (Basic)")
auraDropdown:Add("Ultra Inferno  (Rare)")
auraDropdown:Add("Azure Tundra (Epic)")
auraDropdown:Add("Grand Supernova (Epic)")
auraDropdown:Add("Muscle King (Unique)")
auraDropdown:Add("Entropic Blast (Unique)")
auraDropdown:Add("Eternal Megastrike (Unique)")

pets:AddLabel("=== System to buys===")

-- Auto buy pet toggle
pets:AddSwitch("Auto Buy Pet", function(bool)
    _G.AutoBuyPet = bool
    
    if bool then
        if selectedPet == "" then
            print("Please select a pet first!")
            return
        end
        
        -- Extract pet name from dropdown selection (remove rarity part)
        local petName = selectedPet:match("^(.-)%s*%(")
        if not petName then
            petName = selectedPet
        end
        
        local crystal = findCrystalForItem(petName)
        if not crystal then
            print("Could not find crystal for pet: " .. petName)
            return
        end
        
        print("Auto buy pet started for: " .. petName .. " from " .. crystal)
        spawn(function()
            while _G.AutoBuyPet and selectedPet ~= "" do
                local petToBuy = ReplicatedStorage.cPetShopFolder:FindFirstChild(petName)
                if petToBuy then
                    ReplicatedStorage.cPetShopRemote:InvokeServer(petToBuy)
                    print("Bought pet: " .. petName)
                else
                    print("Pet not found: " .. petName)
                end
                task.wait(0.1)
            end
        end)
    else
        print("Auto buy pet stopped")
    end
end)

-- Auto buy aura toggle
pets:AddSwitch("Auto buy Aura", function(bool)
    _G.AutoBuyAura = bool
    
    if bool then
        if selectedAura == "" then
            print("Please select an aura first!")
            return
        end
        
        -- Extract aura name from dropdown selection (remove rarity part)
        local auraName = selectedAura:match("^(.-)%s*%(")
        if not auraName then
            auraName = selectedAura
        end
        
        local crystal = findCrystalForItem(auraName)
        if not crystal then
            print("Could not find crystal for aura: " .. auraName)
            return
        end
        
        print("Auto buy aura started for: " .. auraName .. " from " .. crystal)
        spawn(function()
            while _G.AutoBuyAura and selectedAura ~= "" do
                local auraToBuy = ReplicatedStorage.cPetShopFolder:FindFirstChild(auraName)
                if auraToBuy then
                    ReplicatedStorage.cPetShopRemote:InvokeServer(auraToBuy)
                    print("Bought aura: " .. auraName)
                else
                    print("Aura not found: " .. auraName)
                end
                task.wait(0.1)
            end
        end)
    else
        print("Auto buy aura stopped")
    end
end)
----------------------------------------------------------------
-- 11.  Gift  (protein / tropical)
--------------------------------------------------------------------
    local giftSection = Gift:AddSection("Gifting Egg/Shake")
	giftSection:AddLabel("Gifting Protein egg:").TextSize = 22

local proteinEggLabel = Gift:AddLabel("Protein Eggs: 0")
proteinEggLabel.TextSize = 20

local selectedEggPlayer = nil
local eggCount = 0

local eggDropdown = Gift:AddDropdown("Player to Gift Eggs", function(selectedDisplayName)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.DisplayName == selectedDisplayName then
            selectedEggPlayer = plr
            break
        end
    end
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= Players.LocalPlayer then
        eggDropdown:Add(plr.DisplayName)
    end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= Players.LocalPlayer then
        eggDropdown:Add(plr.DisplayName)
    end
end)

giftSection:AddTextBox("Amount of Eggs", function(text)
    eggCount = tonumber(text) or 0
end)

giftSection:AddButton("Gift Eggs", function()
    if selectedEggPlayer and eggCount > 0 then
        for i = 1, eggCount do
            local egg = Players.LocalPlayer.consumablesFolder:FindFirstChild("Protein Egg")
            if egg then
                ReplicatedStorage.rEvents.giftRemote:InvokeServer("giftRequest", selectedEggPlayer, egg)
                task.wait(0.1)
            end
        end
    end
end)

giftSection:AddLabel("Gifting Tropical Shakes:").TextSize = 22

local tropicalShakeLabel = Gift:AddLabel("Tropical Shakes: 0")
tropicalShakeLabel.TextSize = 18

local selectedShakePlayer = nil
local shakeCount = 0

local shakeDropdown = Gift:AddDropdown("Player to Gift Tropical Shakes", function(selectedDisplayName)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.DisplayName == selectedDisplayName then
            selectedShakePlayer = plr
            break
        end
    end
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= Players.LocalPlayer then
        shakeDropdown:Add(plr.DisplayName)
    end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= Players.LocalPlayer then
        shakeDropdown:Add(plr.DisplayName)
    end
end)

giftSection:AddTextBox("Tropical Shakes gift", function(text)
    shakeCount = tonumber(text) or 0
end)

giftSection:AddButton("Gift Tropical Shakes", function()
    if selectedShakePlayer and shakeCount > 0 then
        for i = 1, shakeCount do
            local shake = Players.LocalPlayer.consumablesFolder:FindFirstChild("Tropical Shake")
            if shake then
                ReplicatedStorage.rEvents.giftRemote:InvokeServer("giftRequest", selectedShakePlayer, shake)
                task.wait(0.1)
            end
        end
    end
end)

local function updateItemCount()
    local proteinEggCount = 0
    local tropicalShakeCount = 0

    local backpack = Players.LocalPlayer:WaitForChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item.Name == "Protein Egg" then
                proteinEggCount = proteinEggCount + 1
            elseif item.Name == "Tropical Shake" or item.Name == "PiÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â±as" then
                tropicalShakeCount = tropicalShakeCount + 1
            end
        end
    end

    proteinEggLabel.Text = "Protein Eggs: " .. proteinEggCount
    tropicalShakeLabel.Text = "Tropical Shakes: " .. tropicalShakeCount
end

task.spawn(function()
    while true do
        updateItemCount()
        task.wait(0.25)
    end
end)


local itemList = {
    "Tropical Shake",
    "Energy Shake",
    "Protein Bar",
    "TOUGH Bar",
    "Protein Shake",
    "ULTRA Shake",
    "Energy Bar"
}

local function formatEventName(itemName)
    local parts = {}
    for word in itemName:gmatch("%S+") do
        table.insert(parts, word:lower())
    end
    for i = 2, #parts do
        parts[i] = parts[i]:sub(1, 1):upper() .. parts[i]:sub(2)
    end
    return table.concat(parts)
end

local function activateRandomItems(count)
    local shuffledItems = {}
    for _, item in ipairs(itemList) do
        table.insert(shuffledItems, item)
    end
    for i = #shuffledItems, 2, -1 do
        local j = math.random(i)
        shuffledItems[i], shuffledItems[j] = shuffledItems[j], shuffledItems[i]
    end
    for i = 1, math.min(count, #shuffledItems) do
        local tool =
            player.Character:FindFirstChild(shuffledItems[i]) or player.Backpack:FindFirstChild(shuffledItems[i])
        if tool then
            local eventName = formatEventName(shuffledItems[i])
            player.muscleEvent:FireServer(eventName, tool)
        end
    end
end

local eatingRunning = false
task.spawn(
    function()
        while true do
            if eatingRunning then
                activateRandomItems(4)
                task.wait(0.5)
            else
                task.wait(0.5)
            end
        end
    end
)

giftSection:AddButton(
    "Eat Everything",
    function(state)
        eatingRunning = state
        if state then
            activateRandomItems(4)
        end
    end
)

local LocalPlayer = Players.LocalPlayer

local PET_NAME = "Swift Samurai"
local ROCK_NAME = "Rock5M"
local PROTEIN_EGG_NAME = "ProteinEgg"
local PROTEIN_EGG_INTERVAL = 30 * 60
local REPS_PER_CYCLE = 250
local BURST_SIZE = 15
local ROCK_INTERVAL = 1
local MAX_PING = 1100
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
	if ping < 100 then
		return 0.0003
	elseif ping < 300 then
		return 0.0006
	elseif ping < 600 then
		return 0.001
	else
		return 0.002
	end
end

local function updateCharacterRefs()
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	HumanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
end

local function equipPet()
	local petsFolder = LocalPlayer:FindFirstChild("petsFolder")
	if petsFolder and petsFolder:FindFirstChild("Unique") then
		for _, pet in pairs(petsFolder.Unique:GetChildren()) do
			if pet.Name == PET_NAME then
				ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
				break
			end
		end
	end
end

local function eatProteinEgg()
	if LocalPlayer:FindFirstChild("Backpack") then
		for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
			if item.Name == PROTEIN_EGG_NAME then
				ReplicatedStorage.rEvents.eatEvent:FireServer("eat", item)
				break
			end
		end
	end
end

local function hitRock()
	if not RockRef or not RockRef.Parent then
		RockRef = Workspace:FindFirstChild(ROCK_NAME)
	end
	if RockRef and HumanoidRootPart then
		HumanoidRootPart.CFrame = RockRef.CFrame * CFrame.new(0, 0, -5)
		ReplicatedStorage.rEvents.hitEvent:FireServer("hit", RockRef)
	end
end

if not getgenv()._AutoRepFarmLoop then
	getgenv()._AutoRepFarmLoop = true
	updateCharacterRefs()
	equipPet()
	lastProteinEggTime = tick()
	lastRockTime = tick()

	RunService.Heartbeat:Connect(function()
		if not getgenv()._AutoRepFarmEnabled then
			return
		end

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



-- 2ÃƒÆ’Ã‚Â¯Ãƒâ€šÃ‚Â¸Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢Ãƒâ€ Ã¢â‚¬â„¢Ãƒâ€šÃ‚Â£ Switch: Eat Egg (30 Min)
local autoEatEnabled = false
local function eatProteinEggNew()
    local player = game.Players.LocalPlayer
    local backpack = player:WaitForChild("Backpack")
    local character = player.Character or player.CharacterAdded:Wait()

    local egg = backpack:FindFirstChild("Protein Egg")
    if egg then
        egg.Parent = character
        pcall(function()
            egg:Activate()
        end)
        print("[AutoEgg] Protein Egg consumido.")
    else
        warn("[AutoEgg] No se encontrÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³ Protein Egg en Backpack.")
    end
end

task.spawn(function()
    while true do
        if autoEatEnabled then
            eatProteinEggNew()
            task.wait(1800)
        else
            task.wait(1)
        end
    end
end)

do
    local creditsSection = Credits:AddSection("Credits")
    Cr:AddParagraph({Title = "KYY PIE"})
    Cr:AddParagraph({Title = "GAY SHI"})
    Cr:AddParagraph({Title = "GAY RENS"})
    Cr:AddParagraph({Title = "GAY SEN"})
    Cr:AddParagraph({Title = "GAY SIBOL"})
    Cr:AddParagraph({Title = "GAY RUSSEL"})
    Cr:AddParagraph({Title = "GAY LANCE"})
    Cr:AddParagraph({Title = "GAY KIO SUPOT"})
end

--------------------------------------------------------------------
-- 13.  Finish
--------------------------------------------------------------------
SpeedHub:Notify({
    Title = "Sobrang Pogi",
    Content = "Execution successful!",
    SubContent = "PUTANG INA MO PO",
    Duration = 5
})

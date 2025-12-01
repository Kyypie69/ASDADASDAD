-- ===================================================================
--  SILENCE V2  ➜  ELERIUM V2   (Ported & cleaned)
--  Features: Fast-Rebirth, Fast-Strength, Anti-Lag, Auto-Egg/-Shake,
--            Auto-Jungle-Gym, Anti-AFK
-- ===================================================================
if not game:IsLoaded() then game.Loaded:Wait() end

-- load EleriumV2 library
local Elerium = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kyypie69/Library.UI/refs/heads/main/KYY.luau"))()

-- create UI
local Window = Elerium.new({
    MainColor      = Color3.fromRGB(138,43,226),
    ToggleKey      = Enum.KeyCode.Insert,
    MinSize        = Vector2.new(450,400)
})

local Main = Window:CreateWindow("Silence V2  –  Elerium V2",{})
local Tab  = Main:CreateTab("Main","Home")

-- quick services
local RS  = game:GetService("ReplicatedStorage")
local PL  = game:GetService("Players")
local LP  = PL.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

-- wait for important remotes / leaderstats
local muscleEvent   = LP:WaitForChild("muscleEvent")
local rebirthsStat  = LP:WaitForChild("leaderstats"):WaitForChild("Rebirths")
local strengthStat  = LP:WaitForChild("leaderstats"):WaitForChild("Strength")

-- ===================================================================
--  REBIRTH-PACE LABEL  (live)
-- ===================================================================
local paceLabel = Tab:AddLabel("Pace: 0 /h  |  0 /d  |  0 /w")

local lastRebirth = rebirthsStat.Value
local lastTime    = os.clock()
local history     = {} -- store {delta, dt}

local function updatePace()
    local nowReb = rebirthsStat.Value
    local nowTm  = os.clock()
    local delta  = nowReb - lastRebirth
    if delta <= 0 then return end          -- nothing gained
    local dt     = nowTm - lastTime
    table.insert(history, {d = delta, t = dt})
    -- keep only last 10 samples for smooth average
    if #history > 10 then table.remove(history, 1) end
    lastRebirth, lastTime = nowReb, nowTm

    -- total rebirths gained / total time
    local totalD, totalT = 0, 0
    for _,v in ipairs(history) do totalD = totalD + v.d; totalT = totalT + v.t end
    local rps = totalD / math.max(totalT, 1e-6)
    local rph = rps * 3600
    local rpd = rph * 24
    local rpw = rpd * 7
    paceLabel:SetText(string.format("Pace: %s /h  |  %s /d  |  %s /w",
                                    formatNumber(rph), formatNumber(rpd), formatNumber(rpw)))
end

rebirthsStat.Changed:Connect(updatePace)

-- ===================================================================
--  UTILITIES
-- ===================================================================
local function notify(title,text,icon,time)
    Window:Notify(title,text,icon or "Info",time or 3)
end

local function formatNumber(n)
    n = math.abs(n)
    if n>=1e15 then return string.format("%.2fQ",n/1e15) end
    if n>=1e12 then return string.format("%.2fT",n/1e12) end
    if n>=1e9  then return string.format("%.2fB",n/1e9)  end
    if n>=1e6  then return string.format("%.2fM",n/1e6)  end
    if n>=1e3  then return string.format("%.2fK",n/1e3)  end
    return tostring(math.floor(n))
end

local function equipPet(name)
    -- unequip all
    for _,fold in pairs(LP.petsFolder:GetChildren()) do
        if fold:IsA("Folder") then
            for _,pet in pairs(fold:GetChildren()) do
                RS.rEvents.equipPetEvent:FireServer("unequipPet",pet)
            end
        end
    end
    task.wait(.1)
    -- equip wanted
    for _,pet in pairs(LP.petsFolder.Unique:GetChildren()) do
        if pet.Name==name then
            RS.rEvents.equipPetEvent:FireServer("equipPet",pet)
            break
        end
    end
end

-- ===================================================================
--  FAST REBIRTH
-- ===================================================================
local rebirthRunning = false
local function fastRebirthLoop()
    while rebirthRunning do
        local reb = rebirthsStat.Value
        local target = 5000 + reb*2550
        equipPet("Swift Samurai")
        while rebirthRunning and strengthStat.Value < target do
            local reps = LP.MembershipType==Enum.MembershipType.Premium and 8 or 14
            for _=1,reps do muscleEvent:FireServer("rep") end
            task.wait(.02)
        end
        if not rebirthRunning then break end
        equipPet("Tribal Overlord")
        task.wait(.25)
        local before = rebirthsStat.Value
        repeat
            RS.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
            task.wait(.05)
        until rebirthsStat.Value>before or not rebirthRunning
        task.wait(.5)
    end
end
Tab:AddToggle("Fast Rebirth",false,function(v)
    rebirthRunning = v
    if v then
        notify("Rebirth","Started rebirth loop","Success")
        task.spawn(fastRebirthLoop)
    else
        notify("Rebirth","Stopped rebirth loop","Warning")
    end
end)

-- ===================================================================
--  FAST STRENGTH
-- ===================================================================
local strengthRunning = false
local repsPerTick = 1
local function fastStrengthLoop()
    while strengthRunning do
        local start = tick()
        while tick()-start < .75 and strengthRunning do
            for i=1,repsPerTick do muscleEvent:FireServer("rep") end
            task.wait(.02)
        end
        -- simple ping throttle
        local ping = game.Stats.PerformanceStats.Ping:GetValue()
        while strengthRunning and ping>=350 do task.wait(1) end
    end
end
Tab:AddTextBox("Rep Speed","20",function(v)
    repsPerTick = math.clamp(tonumber(v) or 1,1,50)
end)
Tab:AddToggle("Fast Strength",false,function(v)
    strengthRunning = v
    if v then
        notify("Strength","Fast strength enabled","Success")
        task.spawn(fastStrengthLoop)
    else
        notify("Strength","Fast strength disabled","Warning")
    end
end)

-- ===================================================================
--  AUTO CONSUMABLES
-- ===================================================================
local autoEgg, autoShake = false, false
local function consume(toolName,remoteArg)
    local tool = LP.Character:FindFirstChild(toolName) or LP.Backpack:FindFirstChild(toolName)
    if tool then muscleEvent:FireServer(remoteArg,tool) end
end
task.spawn(function()
    while true do
        if autoEgg   then consume("Protein Egg","proteinEgg")    task.wait(1800) end
        if autoShake then consume("Tropical Shake","tropicalShake") task.wait(450)  end
        task.wait(1)
    end
end)
Tab:AddToggle("Auto Egg",false,function(v) autoEgg = v end)
Tab:AddToggle("Auto Shake",false,function(v) autoShake = v end)

-- ===================================================================
--  AUTO JUNGLE GYM / SQUAT
-- ===================================================================
local function tpJungle(gym)
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local pos = gym=="lift" and Vector3.new(-8642.4,6.8,2086.1) or Vector3.new(-8371.4,6.8,2858.9)
    root.CFrame = CFrame.new(pos)
    task.wait(.2)
    VirtualInputManager:SendKeyEvent(true ,Enum.KeyCode.E,false,game)
    task.wait(.05)
    VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game)
end
Tab:AddButton("Jungle Lift",function() tpJungle("lift") end)
Tab:AddButton("Jungle Squat",function() tpJungle("squat") end)

-- ===================================================================
--  ANTI-LAG
-- ===================================================================
Tab:AddButton("Anti Lag",function()
    -- destroy GUIs
    for _,g in pairs(LP:WaitForChild("PlayerGui"):GetChildren()) do if g:IsA("ScreenGui") then g:Destroy() end end
    -- lighting
    game.Lighting.Brightness = 0
    game.Lighting.ClockTime = 0
    game.Lighting.OutdoorAmbient = Color3.new(0,0,0)
    game.Lighting.Ambient = Color3.new(0,0,0)
    -- objects
    for _,o in pairs(workspace:GetDescendants()) do
        if o:IsA("ParticleEmitter") or o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then o:Destroy() end
    end
    notify("Anti-Lag","Performance mode activated","Success")
end)

-- ===================================================================
--  ANTI-AFK
-- ===================================================================
local afkRunning = false
local function antiAfk()
    while afkRunning do
        LP.Idled:Fire() -- bypasses the 20-min kick
        task.wait(60)
    end
end
Tab:AddToggle("Anti AFK",false,function(v)
    afkRunning = v
    if v then task.spawn(antiAfk) end
end)

-- ===================================================================
--  INFO
-- ===================================================================
Tab:AddLabel(" ")
Tab:AddLabel("Silence V2  –  Ported to EleriumV2 by Henne")
Tab:AddLabel("discord.gg/silencev1")

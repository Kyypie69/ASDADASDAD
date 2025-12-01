-- ===================================================================
--  SILENCE V2  ➜  ELERIUM V2  (Dual-window edition)
--  Window 1 : Fast-Rebirth stuff
--  Window 2 : Fast-Strength stuff
-- ===================================================================
if not game:IsLoaded() then game.Loaded:Wait() end

-- load library
local Elerium = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kyypie69/Library.UI/refs/heads/main/KYY.luau"))()

-- quick services
local RS  = game:GetService("ReplicatedStorage")
local PL  = game:GetService("Players")
local LP  = PL.LocalPlayer
local VIM = game:GetService("VirtualInputManager")

-- wait for remotes / stats
local muscleEvent  = LP:WaitForChild("muscleEvent")
local rebirthsStat = LP:WaitForChild("leaderstats"):WaitForChild("Rebirths")
local strengthStat = LP:WaitForChild("leaderstats"):WaitForChild("Strength")

-- ===================================================================
--  UTILITIES
-- ===================================================================
local function notify(title,text,icon,time)
    Elerium:Notify(title,text,icon or "Info",time or 3)
end
local function fmt(n)
    n = math.abs(n)
    if n>=1e15 then return string.format("%.2fQ",n/1e15) end
    if n>=1e12 then return string.format("%.2fT",n/1e12) end
    if n>=1e9  then return string.format("%.2fB",n/1e9)  end
    if n>=1e6  then return string.format("%.2fM",n/1e6)  end
    if n>=1e3  then return string.format("%.2fK",n/1e3)  end
    return tostring(math.floor(n))
end
local function equipSamurai()
    -- unequip all
    for _,fold in pairs(LP.petsFolder:GetChildren()) do
        if fold:IsA("Folder") then
            for _,pet in pairs(fold:GetChildren()) do
                RS.rEvents.equipPetEvent:FireServer("unequipPet",pet)
            end
        end
    end
    task.wait(.1)
    -- equip Swift Samurai
    for _,pet in pairs(LP.petsFolder.Unique:GetChildren()) do
        if pet.Name=="Swift Samurai" then
            RS.rEvents.equipPetEvent:FireServer("equipPet",pet); break
        end
    end
end
local function antiLag()
    for _,g in pairs(LP:WaitForChild("PlayerGui"):GetChildren()) do if g:IsA("ScreenGui") then g:Destroy() end end
    game.Lighting.Brightness = 0; game.Lighting.ClockTime = 0
    game.Lighting.OutdoorAmbient = Color3.new(0,0,0); game.Lighting.Ambient = Color3.new(0,0,0)
    for _,o in pairs(workspace:GetDescendants()) do
        if o:IsA("ParticleEmitter") or o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then o:Destroy() end
    end
    notify("Anti-Lag","Performance mode on","Success")
end
local function tpJungle(lift)
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local pos = lift and Vector3.new(-8642.4,6.8,2086.1) or Vector3.new(-8371.4,6.8,2858.9)
    root.CFrame = CFrame.new(pos)
    task.wait(.2)
    VIM:SendKeyEvent(true ,Enum.KeyCode.E,false,game)
    task.wait(.05)
    VIM:SendKeyEvent(false,Enum.KeyCode.E,false,game)
end
local function consume(toolName,remoteArg)
    local tool = LP.Character:FindFirstChild(toolName) or LP.Backpack:FindFirstChild(toolName)
    if tool then muscleEvent:FireServer(remoteArg,tool) end
end

-- ===================================================================
--  WINDOW 1  –  FAST REBIRTH
-- ===================================================================
local Win1 = Elerium.new({MainColor=Color3.fromRGB(255,50,50),ToggleKey=Enum.KeyCode.Insert,MinSize=Vector2.new(300,300)})
local W1   = Win1:CreateWindow("Fast Rebirth",{})
local T1   = W1:CreateTab("Rebirth","Home")

-- fast rebirth loop
local rebRunning = false
local function rebLoop()
    while rebRunning do
        local reb = rebirthsStat.Value
        local target = 5000 + reb*2550
        equipSamurai()
        while rebRunning and strengthStat.Value < target do
            local reps = LP.MembershipType==Enum.MembershipType.Premium and 8 or 14
            for _=1,reps do muscleEvent:FireServer("rep") end
            task.wait(.02)
        end
        if not rebRunning then break end
        -- rebirth
        local before = rebirthsStat.Value
        repeat
            RS.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
            task.wait(.05)
        until rebirthsStat.Value>before or not rebRunning
        task.wait(.5)
    end
end
T1:AddToggle("Fast Rebirth",false,function(v)
    rebRunning = v
    if v then notify("Rebirth","Loop started","Success"); task.spawn(rebLoop)
    else notify("Rebirth","Loop stopped","Warning") end
end)
T1:AddButton("Anti Lag",antiLag)
T1:AddButton("Jungle Lift",function() tpJungle(true) end)
T1:AddButton("Equip Swift Samurai x8",function() for i=1,8 do equipSamurai() task.wait() end notify("Pets","Swift Samurai equipped x8","Success") end)
local afk1 = false; T1:AddToggle("Anti AFK",false,function(v) afk1=v; while afk1 do LP.Idled:Fire(); task.wait(60) end end)

-- ===================================================================
--  WINDOW 2  –  FAST STRENGTH
-- ===================================================================
local Win2 = Elerium.new({MainColor=Color3.fromRGB(50,255,50),ToggleKey=Enum.KeyCode.Insert,MinSize=Vector2.new(300,300)})
local W2   = Win2:CreateWindow("Fast Strength",{})
local T2   = W2:CreateTab("Strength","Home")

-- fast strength loop
local strRunning = false; local reps = 20
local function strLoop()
    while strRunning do
        local start = tick()
        while tick()-start < .75 and strRunning do
            for i=1,reps do muscleEvent:FireServer("rep") end
            task.wait(.02)
        end
        local ping = game.Stats.PerformanceStats.Ping:GetValue()
        while strRunning and ping>=350 do task.wait(1) end
    end
end
T2:AddTextBox("Rep Speed","20",function(v) reps=math.clamp(tonumber(v) or 1,1,50) end)
T2:AddToggle("Fast Strength",false,function(v)
    strRunning = v
    if v then notify("Strength","Loop started","Success"); task.spawn(strLoop)
    else notify("Strength","Loop stopped","Warning") end
end)
T2:AddButton("Anti Lag",antiLag)
T2:AddButton("Jungle Squat",function() tpJungle(false) end)
T2:AddButton("Equip Swift Samurai x8",function() for i=1,8 do equipSamurai() task.wait() end notify("Pets","Swift Samurai equipped x8","Success") end)
local afk2 = false; T2:AddToggle("Anti AFK",false,function(v) afk2=v; while afk2 do LP.Idled:Fire(); task.wait(60) end end)

-- auto consumables
local eggOn,shakeOn = false,false
task.spawn(function()
    while true do
        if eggOn   then consume("Protein Egg","proteinEgg"); task.wait(1800) end
        if shakeOn then consume("Tropical Shake","tropicalShake"); task.wait(450) end
        task.wait(1)
    end
end)
T2:AddToggle("Auto Protein Egg",false,function(v) eggOn=v end)
T2:AddToggle("Auto Tropical Shake",false,function(v) shakeOn=v end)

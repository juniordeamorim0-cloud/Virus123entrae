local LMG2L = {}

-- ==============================================
-- SERVICES
-- ==============================================

Players = game:GetService("Players")
RunService = game:GetService("RunService")
UserInputService = game:GetService("UserInputService")
Workspace = game:GetService("Workspace")
Lighting = game:GetService("Lighting")
LocalPlayer = Players.LocalPlayer
Camera = Workspace.CurrentCamera
espFolder = Instance.new("Folder", Workspace)
espFolder.Name = "_ESP_Solar"
mouse = LocalPlayer:GetMouse()

-- ==============================================
-- HUB CONFIG
-- ==============================================

getgenv().HUB = getgenv().HUB or {}
HUB.SmoothAim        = 5
HUB.WallCheck        = false
HUB.SpinBotEnabled   = false
HUB.SpinBotSpeed     = 30
HUB.ThirdPersonEnabled = false
HUB.CustomFOVEnabled = false
HUB.CustomFOV        = 70
HUB.HitSoundEnabled  = false
HUB.HitSoundID       = "rbxassetid://6534947240"
HUB.HitSoundVolume   = 0.5
HUB.OriginalHitSounds = {}
HUB.HitSounds = {
    ["🔔 Bell"]         = "rbxassetid://6534947240",
    ["💀 Bameware"]     = "rbxassetid://3124331820",
    ["🎯 Skeet"]        = "rbxassetid://6937353691",
    ["🔫 Cod Hitmarker"] = "rbxassetid://160432334",
    ["⚡ Neverlose"]    = "rbxassetid://8679627751",
    ["💎 Minecraft"]    = "rbxassetid://4018616850",
}
HUB.HitSoundNames = {"🔔 Bell","💀 Bameware","🎯 Skeet","🔫 Cod Hitmarker","⚡ Neverlose","💎 Minecraft"}
HUB.HitSoundIndex = 1

-- Skeleton ESP settings
HUB.ESPSettings = {
    Skeleton = { Enabled = false, Color = Color3.fromRGB(255, 0, 0) }
}
HUB.ESPObjects = {}  -- só para Skeleton

-- ==============================================
-- AIMBOT CONFIG (FFH4X)
-- ==============================================

_G.Aimbot              = false
_G.FOV                 = 80
_G.ExibirFOV           = false
_G.TeamCheck           = false
_G.KillCheck           = false
_G.DesativarESPTeam    = false
_G.DesativarHitboxTeam = false

-- CÍRCULO DO FOV (FFH4X Drawing)
fovCircle = Drawing.new("Circle")
fovCircle.Thickness    = 2
fovCircle.Color        = Color3.fromRGB(255, 255, 255)
fovCircle.Transparency = 0.5
fovCircle.Filled       = false
fovCircle.Visible      = false
fovCircle.NumSides     = 60

-- ==============================================
-- RGB GLOBAL
-- ==============================================

_G.RGBSpeed        = 1
_G.ESPRGBEnabled   = false
_G.FOVRGBEnabled   = false
_G.HitboxRGBEnabled= false
_G._rgbHue         = 0

RunService.Heartbeat:Connect(function(dt)
    _G._rgbHue = (_G._rgbHue + dt * _G.RGBSpeed * 0.2) % 1
end)

-- ==============================================
-- TARGET PART (FFH4X)
-- ==============================================

targetPart    = "Cabeca"
targetOptions = {"Cabeca", "Torso", "Aleatorio"}
randomParts   = {}

local function getRandomPart(character)
    local parts = {}
    local possibleParts = {"Head","Torso","UpperTorso","LowerTorso","HumanoidRootPart",
                           "Left Arm","Right Arm","Left Leg","Right Leg"}
    for _, partName in ipairs(possibleParts) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    if #parts > 0 then
        return parts[math.random(1, #parts)]
    end
    return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function getTargetPart(character, player)
    if targetPart == "Cabeca" then
        return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    elseif targetPart == "Torso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
               or character:FindFirstChild("HumanoidRootPart")
    elseif targetPart == "Aleatorio" then
        if randomParts[player] and randomParts[player].Part and randomParts[player].Part.Parent then
            return randomParts[player].Part
        else
            local newPart = getRandomPart(character)
            randomParts[player] = { Part = newPart, Player = player }
            return newPart
        end
    end
    return character:FindFirstChild("Head")
end

Players.PlayerRemoving:Connect(function(player)
    randomParts[player] = nil
end)

-- ==============================================
-- HUB.GetClosestPlayer (FOV + checks)
-- ==============================================

function HUB.GetClosestPlayer()
    local ClosestPlayer = nil
    local ShortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character      = player.Character
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            local head           = character:FindFirstChild("Head")
            local humanoid       = character:FindFirstChild("Humanoid")

            if humanoidRootPart and head and humanoid and humanoid.Health > 0 then
                if _G.KillCheck and humanoid.Health <= 0 then continue end
                if _G.TeamCheck and LocalPlayer.Team ~= nil
                   and player.Team ~= nil and player.Team == LocalPlayer.Team then continue end

                local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local viewCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local distance   = (Vector2.new(screenPoint.X, screenPoint.Y) - viewCenter).Magnitude

                    if distance < _G.FOV and distance < ShortestDistance then
                        if HUB.WallCheck then
                            local rParams = RaycastParams.new()
                            rParams.FilterDescendantsInstances = {LocalPlayer.Character}
                            rParams.FilterType = Enum.RaycastFilterType.Blacklist
                            local rayResult = workspace:Raycast(
                                Camera.CFrame.Position,
                                (head.Position - Camera.CFrame.Position).Unit * 1000,
                                rParams
                            )
                            if rayResult and rayResult.Instance
                               and rayResult.Instance:IsDescendantOf(character) then
                                ClosestPlayer  = player
                                ShortestDistance = distance
                            end
                        else
                            ClosestPlayer  = player
                            ShortestDistance = distance
                        end
                    end
                end
            end
        end
    end

    return ClosestPlayer
end

-- ==============================================
-- AIMBOT + FOV LOOP (usa HUB.GetClosestPlayer + getTargetPart do FFH4X)
-- ==============================================

RunService.RenderStepped:Connect(function()
    fovCircle.Radius   = _G.FOV
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Visible  = _G.ExibirFOV

    if _G.FOVRGBEnabled and _G.ExibirFOV then
        fovCircle.Color = Color3.fromHSV(_G._rgbHue, 1, 1)
    end

    if _G.Aimbot then
        local target = HUB.GetClosestPlayer()
        if target and target.Character then
            local targetPartSelected = getTargetPart(target.Character, target)
            if targetPartSelected then
                local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPartSelected.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / HUB.SmoothAim)
            end
        end
    end
end)

-- ==============================================
-- ESP SOLAR (FFH4X completo)
-- ==============================================

local CFG = {
    espEnabled   = false,
    espBox       = true,
    espHighlight = true,
    espNames     = true,
    espHealth    = true,
    espTracers   = true,
    espDistance  = true,
    espMaxDist   = 800,
    espTeamColors= true,
    espTeamColor = Color3.fromRGB(50, 130, 255),
    espEnemyColor= Color3.fromRGB(255, 55, 55),
}

espFolder.Name = "_ESP_Solar"
local espObjects     = {}
local espBoxDrawings = {}

local function CreateBox2D(pl)
    if pl == LocalPlayer or espBoxDrawings[pl] then return end
    local lines = {}
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness    = 1.5
        line.Color        = CFG.espEnemyColor
        line.Visible      = false
        line.Transparency = 1
        table.insert(lines, line)
    end
    espBoxDrawings[pl] = lines
end

local function RemoveBox2D(pl)
    if not espBoxDrawings[pl] then return end
    for _, line in ipairs(espBoxDrawings[pl]) do
        line:Remove()
    end
    espBoxDrawings[pl] = nil
end

local function UpdateBox2D(pl, tChar, col, visible)
    local lines = espBoxDrawings[pl]
    if not lines then return end
    if not visible or not CFG.espBox then
        for _, line in ipairs(lines) do line.Visible = false end
        return
    end
    local root = tChar:FindFirstChild("HumanoidRootPart")
    if not root then
        for _, line in ipairs(lines) do line.Visible = false end
        return
    end
    local rootPos = root.Position
    local topPos  = rootPos + Vector3.new(0, 3.2, 0)
    local botPos  = rootPos + Vector3.new(0, -3.2, 0)
    local topScreen, topVis = Camera:WorldToViewportPoint(topPos)
    local botScreen, botVis = Camera:WorldToViewportPoint(botPos)
    if not topVis or not botVis then
        for _, line in ipairs(lines) do line.Visible = false end
        return
    end
    local height = math.abs(topScreen.Y - botScreen.Y)
    local width  = height * 0.6
    local cx     = topScreen.X
    local top    = topScreen.Y
    local bottom = botScreen.Y
    local left   = cx - width / 2
    local right  = cx + width / 2
    local TL = Vector2.new(left,  top)
    local TR = Vector2.new(right, top)
    local BL = Vector2.new(left,  bottom)
    local BR = Vector2.new(right, bottom)
    lines[1].From = TL; lines[1].To = TR; lines[1].Color = col; lines[1].Visible = true
    lines[2].From = BL; lines[2].To = BR; lines[2].Color = col; lines[2].Visible = true
    lines[3].From = TL; lines[3].To = BL; lines[3].Color = col; lines[3].Visible = true
    lines[4].From = TR; lines[4].To = BR; lines[4].Color = col; lines[4].Visible = true
end

local function GetChar() return LocalPlayer.Character end
local function GetRoot()
    local c = GetChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function IsTeammate(pl)
    return LocalPlayer.Team ~= nil and pl.Team ~= nil and pl.Team == LocalPlayer.Team
end
local function ESPColor(pl)
    if CFG.espTeamColors and IsTeammate(pl) then return CFG.espTeamColor end
    return CFG.espEnemyColor
end
local function WorldToScreen(worldPos)
    local v = Camera:WorldToViewportPoint(worldPos)
    return Vector2.new(v.X, v.Y), v.Z > 0
end

local function CreateESP(pl)
    if pl == LocalPlayer or espObjects[pl] then return end
    local obj = {}
    local box = Instance.new("SelectionBox")
    box.LineThickness       = 0.1
    box.SurfaceTransparency = 0.8
    box.Transparency        = 0.3
    box.Color3              = CFG.espEnemyColor
    box.SurfaceColor3       = CFG.espEnemyColor
    box.Visible             = false
    box.Parent              = nil
    obj.box = box
    local hl = Instance.new("Highlight")
    hl.FillTransparency    = 0.7
    hl.OutlineTransparency = 0.3
    hl.FillColor           = CFG.espEnemyColor
    hl.OutlineColor        = CFG.espEnemyColor
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent              = nil
    obj.hl = hl
    local bb = Instance.new("BillboardGui")
    bb.Size        = UDim2.new(0, 200, 0, 64)
    bb.StudsOffset = Vector3.new(0, 3.4, 0)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Parent      = nil
    obj.bb = bb
    local function Lbl(y, sz, col)
        local l = Instance.new("TextLabel", bb)
        l.Size                  = UDim2.new(1, 0, 0, 18)
        l.Position              = UDim2.new(0, 0, 0, y)
        l.BackgroundTransparency = 1
        l.Font                  = Enum.Font.GothamBold
        l.TextSize              = sz
        l.TextColor3            = col
        l.TextStrokeTransparency = 0.28
        l.Text                  = ""
        return l
    end
    obj.nameLbl = Lbl(0,  13, Color3.new(1, 1, 1))
    obj.hpLbl   = Lbl(19, 11, Color3.fromRGB(110, 255, 110))
    obj.distLbl = Lbl(36, 10, Color3.fromRGB(180, 180, 255))
    local tr = Drawing.new("Line")
    tr.Visible      = false
    tr.Thickness    = 6
    tr.Transparency = 0.2
    tr.Color        = CFG.espEnemyColor
    obj.tracer = tr
    espObjects[pl] = obj
end

local function RemoveESP(pl)
    local obj = espObjects[pl]
    if not obj then return end
    pcall(function()
        if obj.box    then obj.box:Destroy()    end
        if obj.hl     then obj.hl:Destroy()     end
        if obj.bb     then obj.bb:Destroy()     end
        if obj.tracer then obj.tracer:Remove()  end
    end)
    espObjects[pl] = nil
end

local function UpdateESP()
    if not CFG.espEnabled then
        for pl, obj in pairs(espObjects) do
            if obj then
                if obj.box    then obj.box.Adornee = nil; obj.box.Visible = false; obj.box.Parent = nil end
                if obj.hl     then obj.hl.Adornee  = nil; obj.hl.Parent  = nil end
                if obj.bb     then obj.bb.Adornee  = nil; obj.bb.Parent  = nil end
                if obj.tracer then obj.tracer.Visible = false end
            end
            UpdateBox2D(pl, nil, nil, false)
        end
        for _, child in pairs(espFolder:GetChildren()) do child.Parent = nil end
        return
    end
    if not espFolder or not espFolder.Parent then
        espFolder = Instance.new("Folder", Workspace)
        espFolder.Name = "_ESP_Solar"
    end
    local myRoot = GetRoot()
    for pl, obj in pairs(espObjects) do
        if pl == LocalPlayer then continue end
        if not obj then continue end
        if _G.DesativarESPTeam and IsTeammate(pl) then
            if obj.box    then obj.box.Adornee = nil end
            if obj.hl     then obj.hl.Adornee  = nil end
            if obj.bb     then obj.bb.Adornee  = nil end
            if obj.tracer then obj.tracer.Visible = false end
            UpdateBox2D(pl, nil, nil, false)
            continue
        end
        local tChar = pl.Character
        if not tChar then
            if obj.box    then obj.box.Adornee = nil end
            if obj.hl     then obj.hl.Adornee  = nil end
            if obj.bb     then obj.bb.Adornee  = nil end
            if obj.tracer then obj.tracer.Visible = false end
            UpdateBox2D(pl, nil, nil, false)
            continue
        end
        local tRoot = tChar:FindFirstChild("HumanoidRootPart")
        if not tRoot then
            if obj.box    then obj.box.Adornee = nil end
            if obj.hl     then obj.hl.Adornee  = nil end
            if obj.bb     then obj.bb.Adornee  = nil end
            if obj.tracer then obj.tracer.Visible = false end
            UpdateBox2D(pl, nil, nil, false)
            continue
        end
        local dist       = myRoot and (tRoot.Position - myRoot.Position).Magnitude or 0
        local withinRange = dist <= CFG.espMaxDist
        local col        = _G.ESPRGBEnabled and Color3.fromHSV(_G._rgbHue, 1, 1) or ESPColor(pl)
        local tHum       = tChar:FindFirstChildOfClass("Humanoid")
        UpdateBox2D(pl, tChar, col, withinRange)
        if obj.bb then
            if withinRange then
                obj.bb.Adornee = tChar
                obj.bb.Parent  = espFolder
                if obj.nameLbl then
                    obj.nameLbl.Visible   = CFG.espNames
                    obj.nameLbl.Text      = pl.Name
                    obj.nameLbl.TextColor3= col
                end
                if obj.hpLbl then
                    if CFG.espHealth and tHum then
                        local hp  = math.floor(tHum.Health)
                        local mx  = math.max(tHum.MaxHealth, 1)
                        local pct = hp / mx
                        obj.hpLbl.Visible   = true
                        obj.hpLbl.Text      = ("HP %d/%d"):format(hp, math.floor(mx))
                        obj.hpLbl.TextColor3 = Color3.fromRGB(
                            math.floor(255*(1-pct)), math.floor(255*pct), 50)
                    else
                        obj.hpLbl.Visible = false
                    end
                end
                if obj.distLbl then
                    obj.distLbl.Visible = CFG.espDistance
                    if CFG.espDistance then
                        obj.distLbl.Text = ("%d st"):format(math.floor(dist))
                    end
                end
            else
                obj.bb.Adornee = nil; obj.bb.Parent = nil
            end
        end
        if obj.tracer then
            if CFG.espTracers and withinRange then
                local sp, vis = WorldToScreen(tRoot.Position)
                if vis then
                    local vp = Camera.ViewportSize
                    obj.tracer.From    = Vector2.new(vp.X/2, vp.Y)
                    obj.tracer.To      = sp
                    obj.tracer.Color   = col
                    obj.tracer.Visible = true
                else
                    obj.tracer.Visible = false
                end
            else
                obj.tracer.Visible = false
            end
        end
    end
end

RunService.RenderStepped:Connect(UpdateESP)

-- ==============================================
-- SKELETON ESP
-- ==============================================

function HUB.CreateSkeletonESP(player)
    if HUB.ESPObjects[player] then return end
    HUB.ESPObjects[player] = { Skeleton = {} }
end

function HUB.RemoveSkeletonESP(player)
    if not HUB.ESPObjects[player] then return end
    for _, line in pairs(HUB.ESPObjects[player].Skeleton) do
        if line then pcall(function() line:Remove() end) end
    end
    HUB.ESPObjects[player] = nil
end

function HUB.UpdateSkeleton()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        -- Desativar Skeleton em aliados junto com ESP
        if _G.DesativarESPTeam and IsTeammate(player) then
            if HUB.ESPObjects[player] then
                for _, line in pairs(HUB.ESPObjects[player].Skeleton) do
                    if line then line.Visible = false end
                end
            end
            continue
        end
        if not player.Character then
            HUB.RemoveSkeletonESP(player)
            continue
        end
        local char     = player.Character
        local head     = char:FindFirstChild("Head")
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not head or not rootPart or not humanoid or humanoid.Health <= 0 then
            HUB.RemoveSkeletonESP(player)
            continue
        end
        HUB.CreateSkeletonESP(player)
        local obj = HUB.ESPObjects[player]
        if not HUB.ESPSettings.Skeleton.Enabled then
            for _, line in pairs(obj.Skeleton) do
                if line then line.Visible = false end
            end
            continue
        end
        if #obj.Skeleton == 0 then
            for i = 1, 5 do
                local line = Drawing.new("Line")
                line.Thickness    = 1
                line.Transparency = 1
                table.insert(obj.Skeleton, line)
            end
        end
        local torso    = char:FindFirstChild("Torso")    or char:FindFirstChild("UpperTorso")
        local leftArm  = char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftUpperArm")
        local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightUpperArm")
        local leftLeg  = char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftUpperLeg")
        local rightLeg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightUpperLeg")
        -- RGB: usa a mesma cor global do ESP quando RGB ativado
        local col = (_G.ESPRGBEnabled) and Color3.fromHSV(_G._rgbHue, 1, 1) or HUB.ESPSettings.Skeleton.Color
        if torso then
            local headP, headOn   = Camera:WorldToViewportPoint(head.Position)
            local torsoP, torsoOn = Camera:WorldToViewportPoint(torso.Position)
            if headOn and torsoOn then
                obj.Skeleton[1].From    = Vector2.new(headP.X, headP.Y)
                obj.Skeleton[1].To      = Vector2.new(torsoP.X, torsoP.Y)
                obj.Skeleton[1].Color   = col
                obj.Skeleton[1].Visible = true
                if leftArm then
                    local armP, armOn = Camera:WorldToViewportPoint(leftArm.Position)
                    obj.Skeleton[2].From    = Vector2.new(torsoP.X, torsoP.Y)
                    obj.Skeleton[2].To      = Vector2.new(armP.X, armP.Y)
                    obj.Skeleton[2].Color   = col
                    obj.Skeleton[2].Visible = armOn
                end
                if rightArm then
                    local armP, armOn = Camera:WorldToViewportPoint(rightArm.Position)
                    obj.Skeleton[3].From    = Vector2.new(torsoP.X, torsoP.Y)
                    obj.Skeleton[3].To      = Vector2.new(armP.X, armP.Y)
                    obj.Skeleton[3].Color   = col
                    obj.Skeleton[3].Visible = armOn
                end
                if leftLeg then
                    local legP, legOn = Camera:WorldToViewportPoint(leftLeg.Position)
                    obj.Skeleton[4].From    = Vector2.new(torsoP.X, torsoP.Y)
                    obj.Skeleton[4].To      = Vector2.new(legP.X, legP.Y)
                    obj.Skeleton[4].Color   = col
                    obj.Skeleton[4].Visible = legOn
                end
                if rightLeg then
                    local legP, legOn = Camera:WorldToViewportPoint(rightLeg.Position)
                    obj.Skeleton[5].From    = Vector2.new(torsoP.X, torsoP.Y)
                    obj.Skeleton[5].To      = Vector2.new(legP.X, legP.Y)
                    obj.Skeleton[5].Color   = col
                    obj.Skeleton[5].Visible = legOn
                end
            else
                for _, line in pairs(obj.Skeleton) do line.Visible = false end
            end
        else
            for _, line in pairs(obj.Skeleton) do line.Visible = false end
        end
    end
end

RunService.RenderStepped:Connect(function()
    pcall(HUB.UpdateSkeleton)
end)

-- ==============================================
-- PLAYER EVENTS (ESP + Skeleton)
-- ==============================================

-- Forward declarations para sistema de hitbox snapshot
local _snapshot = {}
local _snapDone = {}
local function _LimparSnapshotPlayer(pn)
    _snapshot[pn] = nil
    _snapDone[pn] = nil
end

Players.PlayerAdded:Connect(function(pl)
    CreateBox2D(pl)
    CreateESP(pl)
    HUB.CreateSkeletonESP(pl)
    pl.CharacterAdded:Connect(function()
        _LimparSnapshotPlayer(pl.Name)
        task.wait(0.3)
        HUB.RemoveSkeletonESP(pl)
        HUB.CreateSkeletonESP(pl)
    end)
end)

Players.PlayerRemoving:Connect(function(pl)
    RemoveBox2D(pl)
    RemoveESP(pl)
    HUB.RemoveSkeletonESP(pl)
    _LimparSnapshotPlayer(pl.Name)
end)

for _, pl in pairs(Players:GetPlayers()) do
    if pl ~= LocalPlayer then
        task.spawn(function()
            CreateBox2D(pl)
            CreateESP(pl)
            HUB.CreateSkeletonESP(pl)
            pl.CharacterAdded:Connect(function()
                _LimparSnapshotPlayer(pl.Name)
                task.wait(0.3)
                HUB.RemoveSkeletonESP(pl)
                HUB.CreateSkeletonESP(pl)
            end)
        end)
    end
end

-- ==============================================
-- HITBOX EXPANDER CONFIG
-- ==============================================

local HitboxConfig = {
    Enabled     = false,
    Size        = 10,
    Transparency= 0.8,
    Color       = Color3.fromRGB(255, 0, 0),
    Material    = Enum.Material.Neon,
    Parts       = { Todas = true, Cabeca = false, Torso = false, Bracos = false, Pernas = false, HRP = false },
}

local hitboxConnection = nil

local function _PartaDevExpandir(partName)
    local name = partName:lower()
    if HitboxConfig.Parts.Todas then return true end
    if HitboxConfig.Parts.Cabeca and name:find("head") then return true end
    if HitboxConfig.Parts.Torso and (name:find("torso") or name:find("chest")) then return true end
    if HitboxConfig.Parts.Bracos and (name:find("arm") or name:find("hand")) then return true end
    if HitboxConfig.Parts.Pernas and (name:find("leg") or name:find("foot")) then return true end
    if HitboxConfig.Parts.HRP and name:find("humanoidrootpart") then return true end
    return false
end

local function _TirarSnapshot(player)
    local pn = player.Name
    if _snapDone[pn] then return end
    local chr = player.Character
    if not chr then return end
    local snap = {}
    for _, part in ipairs(chr:GetChildren()) do
        if part:IsA("BasePart") then
            snap[part.Name] = {
                Size        = part.Size,
                Color       = part.Color,
                Material    = part.Material,
                Transparency= part.Transparency,
                CanCollide  = part.CanCollide,
            }
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then
                snap["__acc__"..part.Name] = {
                    Transparency= handle.Transparency,
                    CanCollide  = handle.CanCollide,
                }
            end
        end
    end
    _snapshot[pn] = snap
    _snapDone[pn] = true
end

local function _AplicarNoPlayer(player)
    local chr = player.Character
    if not chr then return end
    local size     = HitboxConfig.Size or 10
    local transp   = HitboxConfig.Transparency or 0.8
    local color    = _G.HitboxRGBEnabled and Color3.fromHSV(_G._rgbHue, 1, 1) or HitboxConfig.Color
    local material = HitboxConfig.Material or Enum.Material.Neon
    if HitboxConfig.Parts.Todas or HitboxConfig.Parts.Cabeca then
        for _, acc in ipairs(chr:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle then
                    pcall(function()
                        handle.Transparency = 1
                        handle.CanCollide   = false
                    end)
                end
            end
        end
    end
    for _, part in ipairs(chr:GetChildren()) do
        if part:IsA("BasePart") and _PartaDevExpandir(part.Name) then
            local isHRP  = (part.Name == "HumanoidRootPart")
            local newSize= Vector3.new(size, size, size) * (isHRP and 1 or 0.8)
            local partMat= (part.Name == "Head") and Enum.Material.Neon or material
            pcall(function()
                part.Size         = newSize
                part.Transparency = transp
                part.Color        = color
                part.Material     = partMat
                part.CanCollide   = false
            end)
        end
    end
end

local function AplicarHitbox()
    if hitboxConnection then hitboxConnection:Disconnect() end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            _TirarSnapshot(player)
        end
    end
    hitboxConnection = RunService.RenderStepped:Connect(function()
        if not HitboxConfig.Enabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if _G.DesativarHitboxTeam and IsTeammate(player) then continue end
                _TirarSnapshot(player)
                _AplicarNoPlayer(player)
            end
        end
    end)
end

local function ResetarHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local pn   = player.Name
            local snap = _snapshot[pn]
            local chr  = player.Character
            for _, part in ipairs(chr:GetChildren()) do
                if part:IsA("BasePart") then
                    local o = snap and snap[part.Name]
                    if o then
                        pcall(function()
                            part.Size         = o.Size
                            part.Transparency = o.Transparency
                            part.Color        = o.Color
                            part.Material     = o.Material
                            part.CanCollide   = o.CanCollide
                        end)
                    else
                        pcall(function()
                            part.Material     = Enum.Material.SmoothPlastic
                            part.CanCollide   = true
                            part.Transparency = (part.Name == "HumanoidRootPart") and 1 or 0
                            if part.Name == "HumanoidRootPart" then
                                part.Size = Vector3.new(2, 2, 1)
                            elseif part.Name == "Head" then
                                part.Size = Vector3.new(2, 1, 1)
                            elseif part.Name:find("Torso") then
                                part.Size = Vector3.new(2, 2, 1)
                            else
                                part.Size = Vector3.new(1, 2, 1)
                            end
                        end)
                    end
                elseif part:IsA("Accessory") then
                    local handle = part:FindFirstChild("Handle")
                    local key    = "__acc__"..part.Name
                    local o      = snap and snap[key]
                    if handle and o then
                        pcall(function()
                            handle.Transparency = o.Transparency
                            handle.CanCollide   = o.CanCollide
                        end)
                    elseif handle then
                        pcall(function() handle.Transparency = 0 end)
                    end
                end
            end
            _snapshot[pn] = nil
            _snapDone[pn] = nil
        end
    end
end

-- ==============================================
-- HIT SOUND
-- ==============================================

function HUB.ReplaceHitSound(sound)
    if sound:IsA("Sound") and sound.Name == "HitSound" then
        if not HUB.OriginalHitSounds[sound] then
            HUB.OriginalHitSounds[sound] = sound.SoundId
        end
        if HUB.HitSoundEnabled then
            sound.SoundId = HUB.HitSoundID
            sound.Volume  = HUB.HitSoundVolume
        else
            if HUB.OriginalHitSounds[sound] then
                sound.SoundId = HUB.OriginalHitSounds[sound]
            end
        end
    end
end

function HUB.ReplaceAllHitSounds()
    for _, descendant in pairs(game:GetDescendants()) do
        HUB.ReplaceHitSound(descendant)
    end
end

game.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("Sound") and descendant.Name == "HitSound" then
        wait(0.05)
        HUB.ReplaceHitSound(descendant)
    end
end)

game.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("Sound") and descendant.Name == "HitSound" then
        descendant:GetPropertyChangedSignal("SoundId"):Connect(function()
            if HUB.HitSoundEnabled and descendant.SoundId ~= HUB.HitSoundID then
                descendant.SoundId = HUB.HitSoundID
            end
        end)
    end
end)

-- ==============================================
-- EFEITOS VISUAIS: NIGHT VISION / FULLBRIGHT / WATERMARK
-- ==============================================

_G.NightVision = false
_G.Fullbright  = false
_G.Watermark   = true

do
    local nvEffect = nil
    local _nvOrigAmbient, _nvOrigBrightness, _nvOrigFogEnd

    function ToggleNightVision(enabled)
        _G.NightVision = enabled
        if enabled then
            _nvOrigAmbient    = _nvOrigAmbient    or Lighting.Ambient
            _nvOrigBrightness = _nvOrigBrightness or Lighting.Brightness
            _nvOrigFogEnd     = _nvOrigFogEnd     or Lighting.FogEnd
            if not nvEffect then
                nvEffect = Instance.new("ColorCorrectionEffect")
                nvEffect.Parent = Lighting
            end
            nvEffect.Brightness = 0.25
            nvEffect.Contrast   = 0.4
            nvEffect.Saturation = -0.8
            nvEffect.TintColor  = Color3.fromRGB(100, 255, 120)
            Lighting.Brightness = 2
            Lighting.FogEnd     = 100000
        else
            if nvEffect then nvEffect:Destroy(); nvEffect = nil end
            if _nvOrigAmbient    then Lighting.Ambient    = _nvOrigAmbient    end
            if _nvOrigBrightness then Lighting.Brightness = _nvOrigBrightness end
            if _nvOrigFogEnd     then Lighting.FogEnd     = _nvOrigFogEnd     end
        end
    end
end

do
    local _fbOrigAmbient, _fbOrigBrightness, _fbOrigFogEnd, _fbOrigClock, _fbOrigShadows

    function ToggleFullbright(enabled)
        _G.Fullbright = enabled
        if enabled then
            _fbOrigAmbient    = _fbOrigAmbient    or Lighting.Ambient
            _fbOrigBrightness = _fbOrigBrightness or Lighting.Brightness
            _fbOrigFogEnd     = _fbOrigFogEnd     or Lighting.FogEnd
            _fbOrigClock      = _fbOrigClock      or Lighting.ClockTime
            if _fbOrigShadows == nil then _fbOrigShadows = Lighting.GlobalShadows end
            Lighting.Ambient       = Color3.fromRGB(178, 178, 178)
            Lighting.Brightness    = 2
            Lighting.FogEnd        = 100000
            Lighting.ClockTime     = 14
            Lighting.GlobalShadows = false
        else
            if _fbOrigAmbient    then Lighting.Ambient       = _fbOrigAmbient    end
            if _fbOrigBrightness then Lighting.Brightness    = _fbOrigBrightness end
            if _fbOrigFogEnd     then Lighting.FogEnd        = _fbOrigFogEnd     end
            if _fbOrigClock      then Lighting.ClockTime     = _fbOrigClock      end
            if _fbOrigShadows ~= nil then Lighting.GlobalShadows = _fbOrigShadows end
        end
    end
end

-- Watermark HUD
do
    local wmFrame = Instance.new("Frame")
    wmFrame.Name                 = "WatermarkFrame"
    wmFrame.Size                 = UDim2.new(0, 340, 0, 35)
    wmFrame.Position             = UDim2.new(1, -350, 0, 10)
    wmFrame.BackgroundColor3     = Color3.fromRGB(0, 0, 0)
    wmFrame.BackgroundTransparency = 0.4
    wmFrame.BorderSizePixel      = 0
    wmFrame.Visible              = _G.Watermark
    wmFrame.ZIndex               = 200
    Instance.new("UICorner", wmFrame).CornerRadius = UDim.new(0, 6)
    local _wmStroke = Instance.new("UIStroke", wmFrame)
    _wmStroke.Color     = Color3.fromRGB(255, 0, 150)
    _wmStroke.Thickness = 1.5
    local wmLabel = Instance.new("TextLabel", wmFrame)
    wmLabel.Size                 = UDim2.new(1, -8, 1, 0)
    wmLabel.Position             = UDim2.new(0, 4, 0, 0)
    wmLabel.BackgroundTransparency = 1
    wmLabel.TextColor3           = Color3.fromRGB(255, 0, 150)
    wmLabel.Font                 = Enum.Font.GothamBold
    wmLabel.TextSize             = 11
    wmLabel.ZIndex               = 201
    wmLabel.TextXAlignment       = Enum.TextXAlignment.Left
    local _wmFpsLast = tick()
    local _wmFps     = 60
    RunService.RenderStepped:Connect(function()
        local now   = tick()
        local delta = math.max(now - _wmFpsLast, 0.001)
        _wmFps      = math.floor(0.85 * _wmFps + 0.15 * (1 / delta))
        _wmFpsLast  = now
        -- Será parented depois que ScreenGui_1 for criado
        if wmFrame.Parent == nil and LMG2L["ScreenGui_1"] then
            wmFrame.Parent = LMG2L["ScreenGui_1"]
        end
        wmFrame.Visible = _G.Watermark
        if _G.Watermark then
            wmLabel.Text = string.format(
                "FFH4X  |  FPS: %d  |  Aim: %s  |  ESP: %s  |  Spin: %s",
                _wmFps,
                _G.Aimbot      and "ON" or "OFF",
                CFG.espEnabled and "ON" or "OFF",
                HUB.SpinBotEnabled and "ON" or "OFF"
            )
        end
    end)
end

-- ==============================================
-- UTILIDADES: FAKE LAG / ANTI-AFK / BUNNYHOP / INFINITEJUMP / SPEEDHACK / NOCLIP
-- ==============================================

_G.FakeLag         = false
_G.AntiAFK         = false
_G.BunnyHop        = false
_G.InfiniteJump    = false
_G.SpeedHack       = false
_G.SpeedMultiplier = 2
_G.NoClip          = false

do
    local _fakeLagPos  = nil
    local _fakeLagConn = nil
    function ToggleFakeLag(enabled)
        _G.FakeLag = enabled
        if enabled then
            if not _fakeLagConn then
                _fakeLagConn = RunService.Heartbeat:Connect(function()
                    if not _G.FakeLag then
                        _fakeLagConn:Disconnect(); _fakeLagConn = nil; _fakeLagPos = nil; return
                    end
                    local char = LocalPlayer.Character
                    if char then
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root then
                            if not _fakeLagPos then _fakeLagPos = root.CFrame end
                            root.CFrame = _fakeLagPos
                        end
                    end
                end)
            end
        else
            if _fakeLagConn then _fakeLagConn:Disconnect(); _fakeLagConn = nil end
            _fakeLagPos = nil
        end
    end
end

do
    local _afkConn = nil
    function ToggleAntiAFK(enabled)
        _G.AntiAFK = enabled
        if enabled then
            if not _afkConn then
                _afkConn = LocalPlayer.Idled:Connect(function()
                    if not _G.AntiAFK then return end
                    pcall(function()
                        local vgi = game:GetService("VirtualInputManager")
                        vgi:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
                        task.wait(0.1)
                        vgi:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end)
                end)
            end
        else
            if _afkConn then _afkConn:Disconnect(); _afkConn = nil end
        end
    end
end

do
    local _bhopConn = nil
    function ToggleBunnyHop(enabled)
        _G.BunnyHop = enabled
        if enabled then
            if not _bhopConn then
                _bhopConn = RunService.Stepped:Connect(function()
                    if not _G.BunnyHop then
                        _bhopConn:Disconnect(); _bhopConn = nil; return
                    end
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    if hum.FloorMaterial ~= Enum.Material.Air then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            end
        else
            if _bhopConn then _bhopConn:Disconnect(); _bhopConn = nil end
        end
    end
end

UserInputService.JumpRequest:Connect(function()
    if not _G.InfiniteJump then return end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

do
    local _speedConn    = nil
    local _defaultSpeed = 16
    function ToggleSpeedHack(enabled)
        _G.SpeedHack = enabled
        if enabled then
            if not _speedConn then
                _speedConn = RunService.Heartbeat:Connect(function()
                    if not _G.SpeedHack then
                        _speedConn:Disconnect(); _speedConn = nil
                        local c = LocalPlayer.Character
                        if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = _defaultSpeed end end
                        return
                    end
                    local c = LocalPlayer.Character
                    if c then
                        local h = c:FindFirstChildOfClass("Humanoid")
                        if h then h.WalkSpeed = _defaultSpeed * _G.SpeedMultiplier end
                    end
                end)
            end
        else
            if _speedConn then _speedConn:Disconnect(); _speedConn = nil end
            local c = LocalPlayer.Character
            if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = _defaultSpeed end end
        end
    end
end

do
    local _noclipConn = nil
    function ToggleNoClip(enabled)
        _G.NoClip = enabled
        if enabled then
            if not _noclipConn then
                _noclipConn = RunService.Stepped:Connect(function()
                    if not _G.NoClip then
                        _noclipConn:Disconnect(); _noclipConn = nil; return
                    end
                    local char = LocalPlayer.Character
                    if char then
                        for _, v in pairs(char:GetDescendants()) do
                            if v:IsA("BasePart") then v.CanCollide = false end
                        end
                    end
                end)
            end
        else
            if _noclipConn then _noclipConn:Disconnect(); _noclipConn = nil end
            local char = LocalPlayer.Character
            if char then
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = true end
                end
            end
        end
    end
end

-- ==============================================
-- FLY HACK (PC + MOBILE)
-- ==============================================
_G.FlyEnabled   = false
_G.FlySpeed     = 80
local _flyLV        = nil
local _flyAO        = nil
local _flyConn      = nil
local _flyToggleBtn = nil  -- ref ao botão GUI (set depois)
local _flyUp        = false  -- subir (Space / botão mobile ▲)
local _flyDown      = false  -- descer (Shift / botão mobile ▼)

-- ── Botões flutuantes de SUBIR / DESCER (visíveis só quando fly ON) ──
local _flyGui = Instance.new("ScreenGui")
_flyGui.Name         = "_FFH_FlyButtons"
_flyGui.ResetOnSpawn = false
_flyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
_flyGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local _flyBtnUp = Instance.new("TextButton", _flyGui)
_flyBtnUp.Size             = UDim2.new(0, 70, 0, 70)
_flyBtnUp.Position         = UDim2.new(1, -165, 1, -175)
_flyBtnUp.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
_flyBtnUp.BackgroundTransparency = 0.3
_flyBtnUp.Text             = "▲"
_flyBtnUp.TextColor3       = Color3.new(1, 1, 1)
_flyBtnUp.Font             = Enum.Font.GothamBold
_flyBtnUp.TextSize         = 30
_flyBtnUp.Visible          = false
_flyBtnUp.ZIndex           = 20
Instance.new("UICorner", _flyBtnUp).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", _flyBtnUp).Color        = Color3.fromRGB(255, 0, 150)

local _flyBtnDown = Instance.new("TextButton", _flyGui)
_flyBtnDown.Size             = UDim2.new(0, 70, 0, 70)
_flyBtnDown.Position         = UDim2.new(1, -85, 1, -175)
_flyBtnDown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
_flyBtnDown.BackgroundTransparency = 0.3
_flyBtnDown.Text             = "▼"
_flyBtnDown.TextColor3       = Color3.new(1, 1, 1)
_flyBtnDown.Font             = Enum.Font.GothamBold
_flyBtnDown.TextSize         = 30
_flyBtnDown.Visible          = false
_flyBtnDown.ZIndex           = 20
Instance.new("UICorner", _flyBtnDown).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", _flyBtnDown).Color         = Color3.fromRGB(255, 0, 150)

-- Touch events para mobile (InputBegan/InputEnded no botão)
_flyBtnUp.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch
    or i.UserInputType == Enum.UserInputType.MouseButton1 then
        _flyUp = true
        _flyBtnUp.BackgroundColor3 = Color3.fromRGB(0, 180, 60)
    end
end)
_flyBtnUp.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch
    or i.UserInputType == Enum.UserInputType.MouseButton1 then
        _flyUp = false
        _flyBtnUp.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end)

_flyBtnDown.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch
    or i.UserInputType == Enum.UserInputType.MouseButton1 then
        _flyDown = true
        _flyBtnDown.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    end
end)
_flyBtnDown.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch
    or i.UserInputType == Enum.UserInputType.MouseButton1 then
        _flyDown = false
        _flyBtnDown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end)

local function _FlyShowButtons(visible)
    _flyBtnUp.Visible   = visible
    _flyBtnDown.Visible = visible
end

local function _FlyCleanup()
    if _flyLV and _flyLV.Parent then _flyLV:Destroy() end
    if _flyAO and _flyAO.Parent then _flyAO:Destroy() end
    _flyLV = nil; _flyAO = nil
    if _flyConn then _flyConn:Disconnect(); _flyConn = nil end
    _flyUp = false; _flyDown = false
    _FlyShowButtons(false)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

local function _FlyStart()
    _FlyCleanup()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not (root and hum) then return end
    hum.PlatformStand = true

    local att = root:FindFirstChild("RootAttachment") or Instance.new("Attachment", root)

    _flyLV = Instance.new("LinearVelocity", root)
    _flyLV.MaxForce      = math.huge
    _flyLV.Attachment0   = att
    _flyLV.VectorVelocity = Vector3.zero
    _flyLV.Name = "_ffhFlyLV"

    _flyAO = Instance.new("AlignOrientation", root)
    _flyAO.MaxTorque       = math.huge
    _flyAO.Mode            = Enum.OrientationAlignmentMode.OneAttachment
    _flyAO.Attachment0     = att
    _flyAO.RigidityEnabled = false
    _flyAO.Responsiveness  = 10
    _flyAO.Name = "_ffhFlyAO"

    _FlyShowButtons(true)

    local ok, ControlModule = pcall(function()
        return require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
    end)

    _flyConn = RunService.Heartbeat:Connect(function()
        if not _G.FlyEnabled or not _flyLV or not _flyLV.Parent then _FlyCleanup(); return end

        -- Move vector do joystick (funciona em mobile e PC)
        local mv = Vector3.zero
        if ok and ControlModule then
            pcall(function() mv = ControlModule:GetMoveVector() end)
        end

        local camCF = Camera.CFrame
        local dir   = camCF:VectorToWorldSpace(Vector3.new(mv.X, 0, mv.Z))

        -- Subir/descer: teclado (PC) OU botões touch (mobile)
        local upDown = 0
        if _flyUp   or UserInputService:IsKeyDown(Enum.KeyCode.Space)     then upDown =  1 end
        if _flyDown or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then upDown = -1 end

        local combined = dir + Vector3.new(0, upDown, 0)
        local vel = combined.Magnitude > 0.01
            and combined.Unit * _G.FlySpeed
            or  Vector3.zero

        _flyLV.VectorVelocity = _flyLV.VectorVelocity:Lerp(vel, 0.15)
        _flyAO.CFrame = camCF
    end)
end

function ToggleFly(enabled)
    _G.FlyEnabled = enabled
    if enabled then _FlyStart()
    else _FlyCleanup() end
end

-- Tecla F para toggle (PC)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        ToggleFly(not _G.FlyEnabled)
        if _flyToggleBtn then
            _flyToggleBtn.BackgroundColor3 = _G.FlyEnabled and Color3.fromRGB(0,200,50) or Color3.fromRGB(200,40,40)
            _flyToggleBtn.Text = "✈️ Fly (F): "..(_G.FlyEnabled and "ON" or "OFF")
        end
    end
end)

-- Re-ativa ao respawnar
LocalPlayer.CharacterAdded:Connect(function()
    if _G.FlyEnabled then task.wait(0.5); _FlyStart() end
end)

-- ==============================================
-- TRIGGERBOT — FLICK (mouse.Target)
-- ==============================================
--[[
  Lógica baseada em scripts públicos funcionais (VapingCat, stanpins/dxhook):
  
  DETECÇÃO: mouse.Target — o objeto 3D que o cursor está sobre.
    É o mesmo valor que o jogo usa internamente, muito mais preciso
    que calcular pixels do centro da tela.

  DISPARO: mouse1press/mouse1release em Hold Mode (segurar enquanto na mira)
    OU mouse1click para click único — ambos com fallback para mouse:Button1Down/Up
]]

_G.TriggerBot      = false
_G.TriggerDelay    = 50     -- ms antes de disparar
_G.TriggerHoldMode = true   -- true = segura click; false = click único

local _trigConn     = nil
local _trigCooldown = false
local _trigPressed  = false   -- controle do hold mode
local _trigMouse    = LocalPlayer:GetMouse()

-- Verifica se o mouse.Target pertence a um inimigo vivo
local function _TrigIsEnemy(target)
    if not target then return false end
    local model = target.Parent
    if not model then return false end
    -- sobe 1 nível se for joint/accessory
    local hum = model:FindFirstChildOfClass("Humanoid")
        or (model.Parent and model.Parent:FindFirstChildOfClass("Humanoid"))
    if not hum or hum.Health <= 0 then return false end
    local charModel = hum.Parent
    local pl = Players:GetPlayerFromCharacter(charModel)
    if not pl or pl == LocalPlayer then return false end
    if _G.TeamCheck and IsTeammate(pl) then return false end
    return true
end

-- Solta o clique se estiver segurando
local function _TrigRelease()
    if not _trigPressed then return end
    _trigPressed = false
    pcall(function()
        if mouse1release then mouse1release()
        elseif mouse1up    then mouse1up()
        else _trigMouse:Button1Up() end
    end)
end

-- Dispara (hold = segura; click = único)
local function _TrigFire()
    if _G.TriggerHoldMode then
        if _trigPressed then return end   -- já está segurando
        _trigPressed = true
        pcall(function()
            if mouse1press then mouse1press()
            elseif mouse1down then mouse1down()
            else _trigMouse:Button1Down() end
        end)
    else
        -- Click único
        pcall(function()
            if mouse1click then
                mouse1click()
            elseif mouse1press and mouse1release then
                mouse1press(); task.wait(0.04); mouse1release()
            elseif mouse1press and mouse1up then
                mouse1press(); task.wait(0.04); mouse1up()
            else
                _trigMouse:Button1Down()
                task.wait(0.04)
                _trigMouse:Button1Up()
            end
        end)
    end
end

function ToggleTriggerBot(enabled)
    _G.TriggerBot = enabled
    _trigCooldown = false
    _TrigRelease()
    if _trigConn then _trigConn:Disconnect(); _trigConn = nil end
    if not enabled then return end

    _trigConn = RunService.Heartbeat:Connect(function()
        if not _G.TriggerBot then
            _trigConn:Disconnect(); _trigConn = nil
            _TrigRelease(); return
        end

        local onEnemy = _TrigIsEnemy(_trigMouse.Target)

        if onEnemy then
            if not _trigCooldown then
                _trigCooldown = true
                task.delay(_G.TriggerDelay / 1000, function()
                    if _G.TriggerBot and _TrigIsEnemy(_trigMouse.Target) then
                        _TrigFire()
                    end
                    if not _G.TriggerHoldMode then
                        task.delay(0.1, function() _trigCooldown = false end)
                    else
                        _trigCooldown = false
                    end
                end)
            end
        else
            -- Saiu do alvo: solta o botão
            _TrigRelease()
            _trigCooldown = false
        end
    end)
end

-- ==============================================
-- TELEPORT BEHIND CLOSEST ENEMY
-- ==============================================
_G.TeleportOffset = 5  -- studs behind enemy

function TeleportBehindEnemy()
    local char  = LocalPlayer.Character
    local root  = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local closest, closestDist = nil, math.huge
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local eRoot = pl.Character:FindFirstChild("HumanoidRootPart")
            if eRoot then
                local d = (eRoot.Position - root.Position).Magnitude
                if d < closestDist then
                    if not (_G.TeamCheck and IsTeammate(pl)) then
                        closest = eRoot; closestDist = d
                    end
                end
            end
        end
    end

    if closest then
        -- behind = opposite of enemy's look direction
        local behind = closest.CFrame * CFrame.new(0, 0, _G.TeleportOffset)
        root.CFrame = CFrame.new(behind.Position, closest.Position)
    end
end

-- ==============================================
-- THIRD PERSON
-- ==============================================

function HUB.ApplyThirdPerson()
    if HUB.ThirdPersonEnabled then
        LocalPlayer.CameraMode            = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 15
        LocalPlayer.CameraMinZoomDistance = 10
    else
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    wait(0.5)
    HUB.ApplyThirdPerson()
    if _G.SpeedHack then
        local hum = character:WaitForChild("Humanoid")
        if hum then hum.WalkSpeed = 16 * _G.SpeedMultiplier end
    end
end)

-- SpinBot + CustomFOV in RenderStepped
RunService.RenderStepped:Connect(function()
    if HUB.CustomFOVEnabled then
        Camera.FieldOfView = HUB.CustomFOV
    end
    if HUB.SpinBotEnabled then
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(HUB.SpinBotSpeed), 0)
            end
        end
    end
end)

-- ==============================================
-- GUI PRINCIPAL (FFH4X)
-- ==============================================

LMG2L["ScreenGui_1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
LMG2L["ScreenGui_1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling
LMG2L["ScreenGui_1"]["ResetOnSpawn"]   = false

LMG2L["OPEN/CLOSE_2"] = Instance.new("ImageButton", LMG2L["ScreenGui_1"])
LMG2L["OPEN/CLOSE_2"]["BorderSizePixel"]   = 0
LMG2L["OPEN/CLOSE_2"]["BackgroundColor3"]  = Color3.fromRGB(255, 255, 255)
LMG2L["OPEN/CLOSE_2"]["Image"]             = [[rbxthumb://type=Asset&id=12567265014&w=420&h=420]]
LMG2L["OPEN/CLOSE_2"]["Size"]              = UDim2.new(0, 76, 0, 70)
LMG2L["OPEN/CLOSE_2"]["Name"]              = [[OPEN/CLOSE]]
LMG2L["OPEN/CLOSE_2"]["Position"]          = UDim2.new(0, 12, 0, 110)
LMG2L["UICorner_3"] = Instance.new("UICorner", LMG2L["OPEN/CLOSE_2"])
LMG2L["UICorner_3"]["CornerRadius"]        = UDim.new(0, 10)
LMG2L["UIStroke_5"] = Instance.new("UIStroke", LMG2L["OPEN/CLOSE_2"])
LMG2L["UIStroke_5"]["Color"]               = Color3.fromRGB(255, 0, 150)

LMG2L["MainFrame_6"] = Instance.new("Frame", LMG2L["ScreenGui_1"])
LMG2L["MainFrame_6"]["BorderSizePixel"]    = 0
LMG2L["MainFrame_6"]["BackgroundColor3"]   = Color3.fromRGB(0, 0, 0)
LMG2L["MainFrame_6"]["Size"]               = UDim2.new(0, 486, 0, 340)
LMG2L["MainFrame_6"]["Position"]           = UDim2.new(0, 184, 0, 8)
LMG2L["MainFrame_6"]["Name"]               = [[MainFrame]]
LMG2L["UICorner_37"] = Instance.new("UICorner", LMG2L["MainFrame_6"])
LMG2L["UICorner_37"]["CornerRadius"]       = UDim.new(0, 9)
LMG2L["UIStroke_54"] = Instance.new("UIStroke", LMG2L["MainFrame_6"])
LMG2L["UIStroke_54"]["Color"]              = Color3.fromRGB(255, 255, 255)
LMG2L["OPEN/CLOSE_2"].Active               = true
LMG2L["OPEN/CLOSE_2"].Selectable           = false

-- Botões laterais
LMG2L["AimButton_50"] = Instance.new("ImageButton", LMG2L["MainFrame_6"])
LMG2L["AimButton_50"]["BorderSizePixel"]   = 0
LMG2L["AimButton_50"]["BackgroundColor3"]  = Color3.fromRGB(255, 0, 150)
LMG2L["AimButton_50"]["Image"]             = [[rbxthumb://type=Asset&id=11162755601&w=420&h=420]]
LMG2L["AimButton_50"]["Size"]              = UDim2.new(0, 62, 0, 60)
LMG2L["AimButton_50"]["Name"]              = [[AimButton]]
LMG2L["AimButton_50"]["Position"]          = UDim2.new(0, 8, 0, 40)
LMG2L["UICorner_51"] = Instance.new("UICorner", LMG2L["AimButton_50"])

LMG2L["VisualButton_12"] = Instance.new("ImageButton", LMG2L["MainFrame_6"])
LMG2L["VisualButton_12"]["BorderSizePixel"]  = 0
LMG2L["VisualButton_12"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 150)
LMG2L["VisualButton_12"]["Image"]            = [[rbxthumb://type=Asset&id=129704865580726&w=420&h=420]]
LMG2L["VisualButton_12"]["Size"]             = UDim2.new(0, 62, 0, 60)
LMG2L["VisualButton_12"]["Name"]             = [[VisualButton]]
LMG2L["VisualButton_12"]["Position"]         = UDim2.new(0, 8, 0, 110)
LMG2L["UICorner_13"] = Instance.new("UICorner", LMG2L["VisualButton_12"])

LMG2L["ConfigButton_b"] = Instance.new("ImageButton", LMG2L["MainFrame_6"])
LMG2L["ConfigButton_b"]["BorderSizePixel"]   = 0
LMG2L["ConfigButton_b"]["BackgroundColor3"]  = Color3.fromRGB(255, 0, 150)
LMG2L["ConfigButton_b"]["Image"]             = [[rbxthumb://type=Asset&id=7059346386&w=420&h=420]]
LMG2L["ConfigButton_b"]["Size"]              = UDim2.new(0, 62, 0, 60)
LMG2L["ConfigButton_b"]["Name"]              = [[ConfigButton]]
LMG2L["ConfigButton_b"]["Position"]          = UDim2.new(0, 8, 0, 180)
LMG2L["UICorner_c"] = Instance.new("UICorner", LMG2L["ConfigButton_b"])

LMG2L["InfoButton_7"] = Instance.new("ImageButton", LMG2L["MainFrame_6"])
LMG2L["InfoButton_7"]["BorderSizePixel"]   = 0
LMG2L["InfoButton_7"]["BackgroundColor3"]  = Color3.fromRGB(255, 0, 150)
LMG2L["InfoButton_7"]["Image"]             = [[rbxthumb://type=Asset&id=4871684516&w=420&h=420]]
LMG2L["InfoButton_7"]["Size"]              = UDim2.new(0, 62, 0, 60)
LMG2L["InfoButton_7"]["Name"]              = [[InfoButton]]
LMG2L["InfoButton_7"]["Position"]          = UDim2.new(0, 8, 0, 250)
LMG2L["UICorner_8"] = Instance.new("UICorner", LMG2L["InfoButton_7"])

LMG2L["Decoração_f"] = Instance.new("TextButton", LMG2L["MainFrame_6"])
LMG2L["Decoração_f"]["TextWrapped"]    = true
LMG2L["Decoração_f"]["Active"]         = false
LMG2L["Decoração_f"]["Interactable"]   = false
LMG2L["Decoração_f"]["BorderSizePixel"]= 0
LMG2L["Decoração_f"]["TextSize"]       = 23
LMG2L["Decoração_f"]["TextColor3"]     = Color3.fromRGB(255, 255, 255)
LMG2L["Decoração_f"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 150)
LMG2L["Decoração_f"]["FontFace"]       = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
LMG2L["Decoração_f"]["Selectable"]     = false
LMG2L["Decoração_f"]["Size"]           = UDim2.new(0, 486, 0, 28)
LMG2L["Decoração_f"]["Text"]           = [[🇧🇷 FFH4X AIMBOT - BETA 🇧🇷]]
LMG2L["Decoração_f"]["Name"]           = [[Decoração]]
LMG2L["UICorner_10"] = Instance.new("UICorner", LMG2L["Decoração_f"])
LMG2L["UICorner_10"]["CornerRadius"]   = UDim.new(0, 9)

-- FRAMES DAS ABAS
LMG2L["AimFrame_16"] = Instance.new("Frame", LMG2L["MainFrame_6"])
LMG2L["AimFrame_16"]["Visible"]          = true
LMG2L["AimFrame_16"]["BorderSizePixel"]  = 0
LMG2L["AimFrame_16"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 31)
LMG2L["AimFrame_16"]["Size"]             = UDim2.new(0, 394, 0, 295)
LMG2L["AimFrame_16"]["Position"]         = UDim2.new(0, 82, 0, 40)
LMG2L["AimFrame_16"]["Name"]             = [[AimFrame]]
LMG2L["UICorner_1b"] = Instance.new("UICorner", LMG2L["AimFrame_16"])
LMG2L["Titulo_20"] = Instance.new("TextLabel", LMG2L["AimFrame_16"])
LMG2L["Titulo_20"]["ZIndex"]          = 3
LMG2L["Titulo_20"]["BorderSizePixel"] = 0
LMG2L["Titulo_20"]["TextSize"]        = 18
LMG2L["Titulo_20"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 150)
LMG2L["Titulo_20"]["FontFace"]        = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
LMG2L["Titulo_20"]["TextColor3"]      = Color3.fromRGB(0, 0, 0)
LMG2L["Titulo_20"]["Size"]            = UDim2.new(0, 390, 0, 30)
LMG2L["Titulo_20"]["Text"]            = [[CONFIGURAÇÕES - AIMBOT]]
LMG2L["Titulo_20"]["Position"]        = UDim2.new(0, 0, 0, 6)
LMG2L["UICorner_21"] = Instance.new("UICorner", LMG2L["Titulo_20"])

LMG2L["VisualFrame_23"] = Instance.new("Frame", LMG2L["MainFrame_6"])
LMG2L["VisualFrame_23"]["Visible"]          = false
LMG2L["VisualFrame_23"]["BorderSizePixel"]  = 0
LMG2L["VisualFrame_23"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 31)
LMG2L["VisualFrame_23"]["Size"]             = UDim2.new(0, 394, 0, 295)
LMG2L["VisualFrame_23"]["Position"]         = UDim2.new(0, 82, 0, 40)
LMG2L["VisualFrame_23"]["Name"]             = [[VisualFrame]]
LMG2L["UICorner_2d"] = Instance.new("UICorner", LMG2L["VisualFrame_23"])
LMG2L["Titulo_24"] = Instance.new("TextLabel", LMG2L["VisualFrame_23"])
LMG2L["Titulo_24"]["ZIndex"]          = 3
LMG2L["Titulo_24"]["BorderSizePixel"] = 0
LMG2L["Titulo_24"]["TextSize"]        = 18
LMG2L["Titulo_24"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 150)
LMG2L["Titulo_24"]["FontFace"]        = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
LMG2L["Titulo_24"]["TextColor3"]      = Color3.fromRGB(0, 0, 0)
LMG2L["Titulo_24"]["Size"]            = UDim2.new(0, 390, 0, 30)
LMG2L["Titulo_24"]["Text"]            = [[CONFIGURAÇÕES - VISUAIS]]
LMG2L["Titulo_24"]["Position"]        = UDim2.new(0, 0, 0, 6)
LMG2L["UICorner_25"] = Instance.new("UICorner", LMG2L["Titulo_24"])

LMG2L["ConfigFrame_47"] = Instance.new("Frame", LMG2L["MainFrame_6"])
LMG2L["ConfigFrame_47"]["Visible"]          = false
LMG2L["ConfigFrame_47"]["BorderSizePixel"]  = 0
LMG2L["ConfigFrame_47"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 31)
LMG2L["ConfigFrame_47"]["Size"]             = UDim2.new(0, 394, 0, 295)
LMG2L["ConfigFrame_47"]["Position"]         = UDim2.new(0, 82, 0, 40)
LMG2L["ConfigFrame_47"]["Name"]             = [[ConfigFrame]]
LMG2L["UICorner_48"] = Instance.new("UICorner", LMG2L["ConfigFrame_47"])
LMG2L["Titulo_49"] = Instance.new("TextLabel", LMG2L["ConfigFrame_47"])
LMG2L["Titulo_49"]["ZIndex"]          = 3
LMG2L["Titulo_49"]["BorderSizePixel"] = 0
LMG2L["Titulo_49"]["TextSize"]        = 18
LMG2L["Titulo_49"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 150)
LMG2L["Titulo_49"]["FontFace"]        = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
LMG2L["Titulo_49"]["TextColor3"]      = Color3.fromRGB(0, 0, 0)
LMG2L["Titulo_49"]["Size"]            = UDim2.new(0, 390, 0, 30)
LMG2L["Titulo_49"]["Text"]            = [[CONFIGURAÇÕES - UTILITÁRIAS]]
LMG2L["Titulo_49"]["Position"]        = UDim2.new(0, 0, 0, 6)
LMG2L["UICorner_4a"] = Instance.new("UICorner", LMG2L["Titulo_49"])

LMG2L["InfoFrame_2e"] = Instance.new("Frame", LMG2L["MainFrame_6"])
LMG2L["InfoFrame_2e"]["Visible"]          = false
LMG2L["InfoFrame_2e"]["BorderSizePixel"]  = 0
LMG2L["InfoFrame_2e"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 31)
LMG2L["InfoFrame_2e"]["Size"]             = UDim2.new(0, 394, 0, 295)
LMG2L["InfoFrame_2e"]["Position"]         = UDim2.new(0, 82, 0, 40)
LMG2L["InfoFrame_2e"]["Name"]             = [[InfoFrame]]
LMG2L["UICorner_2f"] = Instance.new("UICorner", LMG2L["InfoFrame_2e"])
LMG2L["Titulo_30"] = Instance.new("TextLabel", LMG2L["InfoFrame_2e"])
LMG2L["Titulo_30"]["ZIndex"]          = 3
LMG2L["Titulo_30"]["BorderSizePixel"] = 0
LMG2L["Titulo_30"]["TextSize"]        = 18
LMG2L["Titulo_30"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 150)
LMG2L["Titulo_30"]["FontFace"]        = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
LMG2L["Titulo_30"]["TextColor3"]      = Color3.fromRGB(0, 0, 0)
LMG2L["Titulo_30"]["Size"]            = UDim2.new(0, 390, 0, 30)
LMG2L["Titulo_30"]["Text"]            = [[CONFIGURAÇÕES - INFORMATIVAS]]
LMG2L["Titulo_30"]["Position"]        = UDim2.new(0, 0, 0, 6)
LMG2L["UICorner_31"] = Instance.new("UICorner", LMG2L["Titulo_30"])

-- ==============================================
-- FUNÇÕES AUXILIARES DA GUI
-- ==============================================

local function CreateScrollFrame(parent)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Parent                  = parent
    scroll.BorderSizePixel         = 0
    scroll.BackgroundColor3        = Color3.fromRGB(72, 72, 72)
    scroll.BackgroundTransparency  = 0.8
    scroll.Size                    = UDim2.new(0, 390, 0, 250)
    scroll.Position                = UDim2.new(0, 0, 0, 40)
    scroll.CanvasSize              = UDim2.new(0, 0, 0, 450)
    scroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness      = 5
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 5)
    return scroll
end

local function CreateToggleRow(parent, text1, get1, set1, text2, get2, set2, yPos)
    local btn1 = Instance.new("TextButton")
    btn1.Parent          = parent
    btn1.Size            = UDim2.new(0, 180, 0, 35)
    btn1.Position        = UDim2.new(0, 10, 0, yPos)
    btn1.BackgroundColor3= get1() and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    btn1.Text            = text1..": "..(get1() and "ON" or "OFF")
    btn1.TextColor3      = Color3.new(1, 1, 1)
    btn1.Font            = Enum.Font.GothamBold
    btn1.TextSize        = 14
    Instance.new("UICorner", btn1).CornerRadius = UDim.new(0, 5)
    btn1.MouseButton1Click:Connect(function()
        set1(not get1())
        btn1.BackgroundColor3 = get1() and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        btn1.Text = text1..": "..(get1() and "ON" or "OFF")
    end)
    local btn2 = Instance.new("TextButton")
    btn2.Parent          = parent
    btn2.Size            = UDim2.new(0, 180, 0, 35)
    btn2.Position        = UDim2.new(0, 200, 0, yPos)
    btn2.BackgroundColor3= get2() and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    btn2.Text            = text2..": "..(get2() and "ON" or "OFF")
    btn2.TextColor3      = Color3.new(1, 1, 1)
    btn2.Font            = Enum.Font.GothamBold
    btn2.TextSize        = 14
    Instance.new("UICorner", btn2).CornerRadius = UDim.new(0, 5)
    btn2.MouseButton1Click:Connect(function()
        set2(not get2())
        btn2.BackgroundColor3 = get2() and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        btn2.Text = text2..": "..(get2() and "ON" or "OFF")
    end)
    return yPos + 45
end

-- Slider genérico (retorna frame, label, fill, yPos avançado)
local function CreateSlider(parent, labelText, minVal, maxVal, defaultVal, yPos, height, onChanged)
    height = height or 70
    local bg = Instance.new("Frame")
    bg.Parent          = parent
    bg.Size            = UDim2.new(0, 370, 0, height)
    bg.Position        = UDim2.new(0, 10, 0, yPos)
    bg.BackgroundColor3= Color3.fromRGB(50, 50, 50)
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)

    local label = Instance.new("TextLabel")
    label.Parent             = bg
    label.Size               = UDim2.new(1, 0, 0, 25)
    label.Position           = UDim2.new(0, 0, 0, 5)
    label.BackgroundTransparency = 1
    label.Text               = labelText
    label.TextColor3         = Color3.new(1, 1, 1)
    label.Font               = Enum.Font.GothamBold
    label.TextSize           = 15

    local sliderBg = Instance.new("Frame")
    sliderBg.Parent          = bg
    sliderBg.Size            = UDim2.new(0, 350, 0, 25)
    sliderBg.Position        = UDim2.new(0, 10, 0, 35)
    sliderBg.BackgroundColor3= Color3.fromRGB(80, 80, 80)
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 5)

    local pct0 = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    local fill = Instance.new("Frame")
    fill.Parent          = sliderBg
    fill.Size            = UDim2.new(pct0, 0, 1, 0)
    fill.BackgroundColor3= Color3.fromRGB(30, 144, 255)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)

    local dragBtn = Instance.new("TextButton")
    dragBtn.Parent             = sliderBg
    dragBtn.Size               = UDim2.new(1, 0, 1, 0)
    dragBtn.BackgroundTransparency = 1
    dragBtn.Text               = ""
    dragBtn.ZIndex             = 10

    local isDragging = false
    local function updateSlider(mousePos)
        if not isDragging then return end
        local absPos = sliderBg.AbsolutePosition
        local sz     = sliderBg.AbsoluteSize.X
        local relX   = math.clamp(mousePos.X - absPos.X, 0, sz)
        local p      = relX / sz
        local val    = math.floor(minVal + p * (maxVal - minVal))
        val          = math.clamp(val, minVal, maxVal)
        fill.Size    = UDim2.new(p, 0, 1, 0)
        onChanged(val, label)
    end
    dragBtn.MouseButton1Down:Connect(function()
        isDragging = true
        updateSlider(UserInputService:GetMouseLocation())
    end)
    dragBtn.MouseButton1Up:Connect(function() isDragging = false end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(UserInputService:GetMouseLocation())
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
    end)
    return yPos + height + 10, label
end

local function CreateFOVSlider(parent, yPos)
    local bg = Instance.new("Frame")
    bg.Parent          = parent
    bg.Size            = UDim2.new(0, 370, 0, 70)
    bg.Position        = UDim2.new(0, 10, 0, yPos)
    bg.BackgroundColor3= Color3.fromRGB(50, 50, 50)
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)
    local label = Instance.new("TextLabel")
    label.Parent             = bg
    label.Size               = UDim2.new(1, 0, 0, 25)
    label.Position           = UDim2.new(0, 0, 0, 5)
    label.BackgroundTransparency = 1
    label.Text               = "FOV: ".._G.FOV.."°"
    label.TextColor3         = Color3.new(1, 1, 1)
    label.Font               = Enum.Font.GothamBold
    label.TextSize           = 16
    local sliderBg = Instance.new("Frame")
    sliderBg.Parent          = bg
    sliderBg.Size            = UDim2.new(0, 350, 0, 25)
    sliderBg.Position        = UDim2.new(0, 10, 0, 35)
    sliderBg.BackgroundColor3= Color3.fromRGB(80, 80, 80)
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 5)
    local slider = Instance.new("Frame")
    slider.Parent          = sliderBg
    slider.Size            = UDim2.new((_G.FOV-10)/190, 0, 1, 0)
    slider.BackgroundColor3= Color3.fromRGB(30, 144, 255)
    Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 5)
    local dragButton = Instance.new("TextButton")
    dragButton.Parent             = sliderBg
    dragButton.Size               = UDim2.new(1, 0, 1, 0)
    dragButton.BackgroundTransparency = 1
    dragButton.Text               = ""
    dragButton.ZIndex             = 10
    local dragging = false
    local function updateSlider(mousePos)
        if not dragging then return end
        local absPos = sliderBg.AbsolutePosition
        local size   = sliderBg.AbsoluteSize.X
        local relX   = math.clamp(mousePos.X - absPos.X, 0, size)
        local pct    = relX / size
        _G.FOV       = math.clamp(math.floor(10 + pct*190), 10, 200)
        slider.Size  = UDim2.new(pct, 0, 1, 0)
        label.Text   = "FOV: ".._G.FOV.."°"
    end
    dragButton.MouseButton1Down:Connect(function() dragging=true; updateSlider(UserInputService:GetMouseLocation()) end)
    dragButton.MouseButton1Up:Connect(function() dragging=false end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(UserInputService:GetMouseLocation())
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    return yPos + 80
end

local function CreateDistSlider(parent, yPos)
    local bg = Instance.new("Frame")
    bg.Parent          = parent
    bg.Size            = UDim2.new(0, 370, 0, 80)
    bg.Position        = UDim2.new(0, 10, 0, yPos)
    bg.BackgroundColor3= Color3.fromRGB(50, 50, 50)
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)
    local label = Instance.new("TextLabel")
    label.Parent             = bg
    label.Size               = UDim2.new(1, 0, 0, 30)
    label.Position           = UDim2.new(0, 0, 0, 5)
    label.BackgroundTransparency = 1
    label.Text               = "Distância ESP: "..CFG.espMaxDist.." studs"
    label.TextColor3         = Color3.new(1, 1, 1)
    label.Font               = Enum.Font.GothamBold
    label.TextSize           = 16
    local sliderBg = Instance.new("Frame")
    sliderBg.Parent          = bg
    sliderBg.Size            = UDim2.new(0, 350, 0, 25)
    sliderBg.Position        = UDim2.new(0, 10, 0, 40)
    sliderBg.BackgroundColor3= Color3.fromRGB(80, 80, 80)
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 5)
    local slider = Instance.new("Frame")
    slider.Parent          = sliderBg
    slider.Size            = UDim2.new((CFG.espMaxDist-200)/1800, 0, 1, 0)
    slider.BackgroundColor3= Color3.fromRGB(30, 144, 255)
    Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 5)
    local dragButton = Instance.new("TextButton")
    dragButton.Parent             = sliderBg
    dragButton.Size               = UDim2.new(1, 0, 1, 0)
    dragButton.BackgroundTransparency = 1
    dragButton.Text               = ""
    dragButton.ZIndex             = 10
    local dragging = false
    local function updateSlider(mousePos)
        if not dragging then return end
        local absPos = sliderBg.AbsolutePosition
        local size   = sliderBg.AbsoluteSize.X
        local relX   = math.clamp(mousePos.X - absPos.X, 0, size)
        local pct    = relX / size
        CFG.espMaxDist = math.clamp(math.floor(200 + pct*1800), 200, 2000)
        slider.Size  = UDim2.new(pct, 0, 1, 0)
        label.Text   = "Distância ESP: "..CFG.espMaxDist.." studs"
    end
    dragButton.MouseButton1Down:Connect(function() dragging=true; updateSlider(UserInputService:GetMouseLocation()) end)
    dragButton.MouseButton1Up:Connect(function() dragging=false end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(UserInputService:GetMouseLocation())
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    return yPos + 90
end

-- ==============================================
-- AIM FRAME
-- ==============================================
do
local aimScroll = CreateScrollFrame(LMG2L["AimFrame_16"])
local aimY = 10

aimY = CreateToggleRow(aimScroll,
    "Aimbot",     function() return _G.Aimbot       end, function(v) _G.Aimbot       = v end,
    "Exibir FOV", function() return _G.ExibirFOV    end, function(v) _G.ExibirFOV    = v end,
    aimY)

-- Intensidade (controla HUB.SmoothAim: 1=Grude Total, 5=Média, 20=Leve)
local intensidadeBtn = Instance.new("TextButton")
intensidadeBtn.Parent          = aimScroll
intensidadeBtn.Size            = UDim2.new(0, 370, 0, 35)
intensidadeBtn.Position        = UDim2.new(0, 10, 0, aimY)
intensidadeBtn.BackgroundColor3= Color3.fromRGB(45, 45, 45)
intensidadeBtn.Text            = "Intensidade: "..(HUB.SmoothAim==1 and "GRUDE TOTAL" or HUB.SmoothAim==5 and "MÉDIA" or "LEVE")
intensidadeBtn.TextColor3      = Color3.new(1, 1, 1)
intensidadeBtn.Font            = Enum.Font.GothamBold
intensidadeBtn.TextSize        = 14
Instance.new("UICorner", intensidadeBtn).CornerRadius = UDim.new(0, 5)
intensidadeBtn.MouseButton1Click:Connect(function()
    if HUB.SmoothAim == 1 then
        HUB.SmoothAim = 20
        intensidadeBtn.Text = "Intensidade: LEVE"
    elseif HUB.SmoothAim == 20 then
        HUB.SmoothAim = 5
        intensidadeBtn.Text = "Intensidade: MÉDIA"
    else
        HUB.SmoothAim = 1
        intensidadeBtn.Text = "Intensidade: GRUDE TOTAL"
    end
end)
aimY = aimY + 45

aimY = CreateFOVSlider(aimScroll, aimY)
aimY = aimY + 10

aimY = CreateToggleRow(aimScroll,
    "Team Check", function() return _G.TeamCheck end, function(v) _G.TeamCheck = v end,
    "Kill Check", function() return _G.KillCheck  end, function(v) _G.KillCheck  = v end,
    aimY)

-- Wall Check (usa HUB.WallCheck)
local wallBg = Instance.new("Frame")
wallBg.Parent          = aimScroll
wallBg.Size            = UDim2.new(0, 370, 0, 45)
wallBg.Position        = UDim2.new(0, 10, 0, aimY)
wallBg.BackgroundColor3= Color3.fromRGB(50, 50, 50)
Instance.new("UICorner", wallBg).CornerRadius = UDim.new(0, 5)
local wallLabel = Instance.new("TextLabel")
wallLabel.Parent             = wallBg
wallLabel.Size               = UDim2.new(0, 200, 1, 0)
wallLabel.Position           = UDim2.new(0, 10, 0, 0)
wallLabel.BackgroundTransparency = 1
wallLabel.Text               = "Wall Check:"
wallLabel.TextColor3         = Color3.new(1, 1, 1)
wallLabel.Font               = Enum.Font.GothamBold
wallLabel.TextSize           = 16
wallLabel.TextXAlignment     = Enum.TextXAlignment.Left
local wallBtn = Instance.new("TextButton")
wallBtn.Parent          = wallBg
wallBtn.Size            = UDim2.new(0, 100, 0, 35)
wallBtn.Position        = UDim2.new(0, 250, 0, 5)
wallBtn.BackgroundColor3= HUB.WallCheck and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
wallBtn.Text            = HUB.WallCheck and "ON" or "OFF"
wallBtn.TextColor3      = Color3.new(1, 1, 1)
wallBtn.Font            = Enum.Font.GothamBold
wallBtn.TextSize        = 16
Instance.new("UICorner", wallBtn).CornerRadius = UDim.new(0, 5)
wallBtn.MouseButton1Click:Connect(function()
    HUB.WallCheck = not HUB.WallCheck
    wallBtn.BackgroundColor3 = HUB.WallCheck and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    wallBtn.Text = HUB.WallCheck and "ON" or "OFF"
end)
aimY = aimY + 55

-- Dropdown (Mira em)
local dropdownFrame = Instance.new("Frame")
dropdownFrame.Parent          = aimScroll
dropdownFrame.Size            = UDim2.new(0, 370, 0, 45)
dropdownFrame.Position        = UDim2.new(0, 10, 0, aimY)
dropdownFrame.BackgroundColor3= Color3.fromRGB(50, 50, 50)
Instance.new("UICorner", dropdownFrame).CornerRadius = UDim.new(0, 5)
local dropdownLabel = Instance.new("TextLabel")
dropdownLabel.Parent             = dropdownFrame
dropdownLabel.Size               = UDim2.new(0, 100, 1, 0)
dropdownLabel.Position           = UDim2.new(0, 10, 0, 0)
dropdownLabel.BackgroundTransparency = 1
dropdownLabel.Text               = "Mira em:"
dropdownLabel.TextColor3         = Color3.new(1, 1, 1)
dropdownLabel.Font               = Enum.Font.GothamBold
dropdownLabel.TextSize           = 14
dropdownLabel.TextXAlignment     = Enum.TextXAlignment.Left
local dropdownButton = Instance.new("TextButton")
dropdownButton.Parent          = dropdownFrame
dropdownButton.Size            = UDim2.new(0, 150, 0, 30)
dropdownButton.Position        = UDim2.new(0, 120, 0, 7)
dropdownButton.BackgroundColor3= Color3.fromRGB(30, 144, 255)
dropdownButton.Text            = targetPart
dropdownButton.TextColor3      = Color3.new(1, 1, 1)
dropdownButton.Font            = Enum.Font.GothamBold
dropdownButton.TextSize        = 14
Instance.new("UICorner", dropdownButton).CornerRadius = UDim.new(0, 5)
local dropdownMenu = Instance.new("Frame")
dropdownMenu.Parent          = aimScroll
dropdownMenu.Size            = UDim2.new(0, 150, 0, 105)
dropdownMenu.Position        = UDim2.new(0, 130, 0, aimY + 40)
dropdownMenu.BackgroundColor3= Color3.fromRGB(40, 40, 40)
dropdownMenu.BorderSizePixel = 0
dropdownMenu.Visible         = false
dropdownMenu.ZIndex          = 10
Instance.new("UICorner", dropdownMenu).CornerRadius = UDim.new(0, 5)
Instance.new("UIStroke", dropdownMenu).Color = Color3.fromRGB(30, 144, 255)
local function createOption(text, yPos)
    local option = Instance.new("TextButton")
    option.Parent          = dropdownMenu
    option.Size            = UDim2.new(1, 0, 0, 30)
    option.Position        = UDim2.new(0, 0, 0, yPos)
    option.BackgroundColor3= Color3.fromRGB(50, 50, 50)
    option.BackgroundTransparency = 0.2
    option.Text            = text
    option.TextColor3      = Color3.new(1, 1, 1)
    option.Font            = Enum.Font.GothamBold
    option.TextSize        = 12
    option.ZIndex          = 11
    option.MouseButton1Click:Connect(function()
        targetPart = text
        dropdownButton.Text = targetPart
        dropdownMenu.Visible = false
        dropdownButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        task.wait(0.1)
        dropdownButton.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
    end)
    option.MouseEnter:Connect(function() option.BackgroundColor3 = Color3.fromRGB(70,70,70) end)
    option.MouseLeave:Connect(function() option.BackgroundColor3 = Color3.fromRGB(50,50,50) end)
    return option
end
createOption("Cabeca",   5)
createOption("Torso",   40)
createOption("Aleatorio", 75)
dropdownButton.MouseButton1Click:Connect(function()
    dropdownMenu.Visible = not dropdownMenu.Visible
end)
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        task.wait(0.1)
        local mousePos = UserInputService:GetMouseLocation()
        local menuPos  = dropdownMenu.AbsolutePosition
        local menuSize = dropdownMenu.AbsoluteSize
        local btnPos   = dropdownButton.AbsolutePosition
        local btnSize  = dropdownButton.AbsoluteSize
        local clickedBtn  = mousePos.X>=btnPos.X and mousePos.X<=btnPos.X+btnSize.X
                         and mousePos.Y>=btnPos.Y and mousePos.Y<=btnPos.Y+btnSize.Y
        local clickedMenu = dropdownMenu.Visible
                         and mousePos.X>=menuPos.X and mousePos.X<=menuPos.X+menuSize.X
                         and mousePos.Y>=menuPos.Y and mousePos.Y<=menuPos.Y+menuSize.Y
        if not clickedBtn and not clickedMenu then
            dropdownMenu.Visible = false
        end
    end
end)
aimY = aimY + 55

-- FOV RGB toggle
local fovRGBBtn = Instance.new("TextButton")
fovRGBBtn.Parent          = aimScroll
fovRGBBtn.Size            = UDim2.new(0, 370, 0, 35)
fovRGBBtn.Position        = UDim2.new(0, 10, 0, aimY)
fovRGBBtn.BackgroundColor3= Color3.fromRGB(200, 40, 40)
fovRGBBtn.Text            = "🌈 FOV Aimbot RGB: OFF"
fovRGBBtn.TextColor3      = Color3.new(1, 1, 1)
fovRGBBtn.Font            = Enum.Font.GothamBold
fovRGBBtn.TextSize        = 14
Instance.new("UICorner", fovRGBBtn).CornerRadius = UDim.new(0, 5)
fovRGBBtn.MouseButton1Click:Connect(function()
    _G.FOVRGBEnabled = not _G.FOVRGBEnabled
    fovRGBBtn.BackgroundColor3 = _G.FOVRGBEnabled and Color3.fromRGB(148,0,211) or Color3.fromRGB(200,40,40)
    fovRGBBtn.Text = "🌈 FOV Aimbot RGB: "..(  _G.FOVRGBEnabled and "ON" or "OFF")
end)
aimY = aimY + 45

-- ─── HITBOX EXPANDER ───

local hitboxTitle = Instance.new("TextLabel")
hitboxTitle.Parent          = aimScroll
hitboxTitle.Size            = UDim2.new(0, 370, 0, 25)
hitboxTitle.Position        = UDim2.new(0, 10, 0, aimY)
hitboxTitle.BackgroundColor3= Color3.fromRGB(30, 144, 255)
hitboxTitle.BackgroundTransparency = 0.7
hitboxTitle.Text            = "🎯 HITBOX EXPANDER"
hitboxTitle.TextColor3      = Color3.new(1, 1, 1)
hitboxTitle.Font            = Enum.Font.GothamBold
hitboxTitle.TextSize        = 16
hitboxTitle.TextXAlignment  = Enum.TextXAlignment.Center
Instance.new("UICorner", hitboxTitle).CornerRadius = UDim.new(0, 5)
aimY = aimY + 35

local hitboxFrame = Instance.new("Frame")
hitboxFrame.Parent          = aimScroll
hitboxFrame.Size            = UDim2.new(0, 370, 0, 200)
hitboxFrame.Position        = UDim2.new(0, 10, 0, aimY)
hitboxFrame.BackgroundColor3= Color3.fromRGB(50, 50, 50)
Instance.new("UICorner", hitboxFrame).CornerRadius = UDim.new(0, 5)

local hitboxToggle = Instance.new("TextButton")
hitboxToggle.Parent          = hitboxFrame
hitboxToggle.Size            = UDim2.new(0, 170, 0, 30)
hitboxToggle.Position        = UDim2.new(0, 10, 0, 10)
hitboxToggle.BackgroundColor3= HitboxConfig.Enabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
hitboxToggle.Text            = "HITBOX: "..(HitboxConfig.Enabled and "ON" or "OFF")
hitboxToggle.TextColor3      = Color3.new(1,1,1)
hitboxToggle.Font            = Enum.Font.GothamBold
hitboxToggle.TextSize        = 12
Instance.new("UICorner", hitboxToggle).CornerRadius = UDim.new(0, 5)
hitboxToggle.MouseButton1Click:Connect(function()
    HitboxConfig.Enabled = not HitboxConfig.Enabled
    hitboxToggle.BackgroundColor3 = HitboxConfig.Enabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    hitboxToggle.Text = "HITBOX: "..(HitboxConfig.Enabled and "ON" or "OFF")
    if HitboxConfig.Enabled then AplicarHitbox()
    else
        if hitboxConnection then hitboxConnection:Disconnect(); hitboxConnection = nil end
        ResetarHitboxes()
    end
end)

local hitboxReset = Instance.new("TextButton")
hitboxReset.Parent          = hitboxFrame
hitboxReset.Size            = UDim2.new(0, 170, 0, 30)
hitboxReset.Position        = UDim2.new(0, 190, 0, 10)
hitboxReset.BackgroundColor3= Color3.fromRGB(100, 100, 100)
hitboxReset.Text            = "↺ RESET (10)"
hitboxReset.TextColor3      = Color3.new(1,1,1)
hitboxReset.Font            = Enum.Font.GothamBold
hitboxReset.TextSize        = 12
Instance.new("UICorner", hitboxReset).CornerRadius = UDim.new(0, 5)

-- Tamanho
local tamanhoLabel = Instance.new("TextLabel")
tamanhoLabel.Parent             = hitboxFrame
tamanhoLabel.Size               = UDim2.new(0, 60, 0, 25)
tamanhoLabel.Position           = UDim2.new(0, 10, 0, 45)
tamanhoLabel.BackgroundTransparency = 1
tamanhoLabel.Text               = "Tamanho:"
tamanhoLabel.TextColor3         = Color3.new(1,1,1)
tamanhoLabel.Font               = Enum.Font.GothamBold
tamanhoLabel.TextSize           = 12
tamanhoLabel.TextXAlignment     = Enum.TextXAlignment.Left

local menosBtn = Instance.new("TextButton")
menosBtn.Parent          = hitboxFrame
menosBtn.Size            = UDim2.new(0, 40, 0, 25)
menosBtn.Position        = UDim2.new(0, 75, 0, 45)
menosBtn.BackgroundColor3= Color3.fromRGB(200, 40, 40)
menosBtn.Text            = "-"
menosBtn.TextColor3      = Color3.new(1,1,1)
menosBtn.Font            = Enum.Font.GothamBold
menosBtn.TextSize        = 16
Instance.new("UICorner", menosBtn).CornerRadius = UDim.new(0, 4)

local tamanhoTextBox = Instance.new("TextBox")
tamanhoTextBox.Parent          = hitboxFrame
tamanhoTextBox.Size            = UDim2.new(0, 60, 0, 25)
tamanhoTextBox.Position        = UDim2.new(0, 120, 0, 45)
tamanhoTextBox.BackgroundColor3= Color3.fromRGB(70, 70, 70)
tamanhoTextBox.Text            = tostring(HitboxConfig.Size)
tamanhoTextBox.TextColor3      = Color3.new(1,1,1)
tamanhoTextBox.Font            = Enum.Font.GothamBold
tamanhoTextBox.TextSize        = 13
tamanhoTextBox.TextXAlignment  = Enum.TextXAlignment.Center
Instance.new("UICorner", tamanhoTextBox).CornerRadius = UDim.new(0, 4)

local maisBtn = Instance.new("TextButton")
maisBtn.Parent          = hitboxFrame
maisBtn.Size            = UDim2.new(0, 40, 0, 25)
maisBtn.Position        = UDim2.new(0, 185, 0, 45)
maisBtn.BackgroundColor3= Color3.fromRGB(0, 180, 50)
maisBtn.Text            = "+"
maisBtn.TextColor3      = Color3.new(1,1,1)
maisBtn.Font            = Enum.Font.GothamBold
maisBtn.TextSize        = 16
Instance.new("UICorner", maisBtn).CornerRadius = UDim.new(0, 4)

menosBtn.MouseButton1Click:Connect(function()
    HitboxConfig.Size = math.max(1, HitboxConfig.Size - 1)
    tamanhoTextBox.Text = tostring(HitboxConfig.Size)
end)
maisBtn.MouseButton1Click:Connect(function()
    HitboxConfig.Size = math.min(75, HitboxConfig.Size + 1)
    tamanhoTextBox.Text = tostring(HitboxConfig.Size)
end)
tamanhoTextBox.FocusLost:Connect(function()
    local val = tonumber(tamanhoTextBox.Text)
    if val then
        HitboxConfig.Size = math.clamp(math.floor(val), 1, 75)
    end
    tamanhoTextBox.Text = tostring(HitboxConfig.Size)
end)
hitboxReset.MouseButton1Click:Connect(function()
    HitboxConfig.Size = 10
    tamanhoTextBox.Text = "10"
end)

-- Transparência slider (hitbox)
local transLabel = Instance.new("TextLabel")
transLabel.Parent             = hitboxFrame
transLabel.Size               = UDim2.new(0, 350, 0, 20)
transLabel.Position           = UDim2.new(0, 10, 0, 75)
transLabel.BackgroundTransparency = 1
transLabel.Text               = string.format("Transparência:  %.1f", HitboxConfig.Transparency)
transLabel.TextColor3         = Color3.new(1,1,1)
transLabel.Font               = Enum.Font.GothamBold
transLabel.TextSize           = 12
transLabel.TextXAlignment     = Enum.TextXAlignment.Left

local transSliderBg = Instance.new("Frame")
transSliderBg.Parent          = hitboxFrame
transSliderBg.Size            = UDim2.new(0, 350, 0, 25)
transSliderBg.Position        = UDim2.new(0, 10, 0, 100)
transSliderBg.BackgroundColor3= Color3.fromRGB(80, 80, 80)
Instance.new("UICorner", transSliderBg).CornerRadius = UDim.new(0, 5)

local transSlider = Instance.new("Frame")
transSlider.Parent          = transSliderBg
transSlider.Size            = UDim2.new(HitboxConfig.Transparency, 0, 1, 0)
transSlider.BackgroundColor3= Color3.fromRGB(30, 144, 255)
Instance.new("UICorner", transSlider).CornerRadius = UDim.new(0, 5)

local transDrag = Instance.new("TextButton")
transDrag.Parent             = transSliderBg
transDrag.Size               = UDim2.new(1, 0, 1, 0)
transDrag.BackgroundTransparency = 1
transDrag.Text               = ""
transDrag.ZIndex             = 10

local transDragging = false
local function updateTransSlider(pos)
    if not transDragging then return end
    local absPos = transSliderBg.AbsolutePosition
    local sz     = transSliderBg.AbsoluteSize.X
    local relX   = math.clamp(pos.X - absPos.X, 0, sz)
    local pct    = relX / sz
    HitboxConfig.Transparency = math.clamp(pct, 0, 1)
    transSlider.Size  = UDim2.new(pct, 0, 1, 0)
    transLabel.Text   = string.format("Transparência:  %.1f", HitboxConfig.Transparency)
end
transDrag.MouseButton1Down:Connect(function() transDragging=true; updateTransSlider(UserInputService:GetMouseLocation()) end)
transDrag.MouseButton1Up:Connect(function() transDragging=false end)
UserInputService.InputChanged:Connect(function(i)
    if transDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        updateTransSlider(UserInputService:GetMouseLocation())
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then transDragging=false end
end)

-- Cores do Hitbox
CORES_HITBOX = {
    { nome="Vermelho", cor=BrickColor.new("Really red").Color },
    { nome="Azul",     cor=BrickColor.new("Bright blue").Color },
    { nome="Verde",    cor=BrickColor.new("Bright green").Color },
    { nome="Roxo",     cor=BrickColor.new("Bright violet").Color },
    { nome="Amarelo",  cor=BrickColor.new("Bright yellow").Color },
    { nome="Laranja",  cor=BrickColor.new("Bright orange").Color },
    { nome="Rosa",     cor=BrickColor.new("Hot pink").Color },
    { nome="Ciano",    cor=BrickColor.new("Cyan").Color },
}
local corHitboxIndex = 1

local corHitboxLabel = Instance.new("TextLabel")
corHitboxLabel.Parent             = hitboxFrame
corHitboxLabel.Size               = UDim2.new(0, 60, 0, 20)
corHitboxLabel.Position           = UDim2.new(0, 10, 0, 125)
corHitboxLabel.BackgroundTransparency = 1
corHitboxLabel.Text               = "Cor:"
corHitboxLabel.TextColor3         = Color3.new(1,1,1)
corHitboxLabel.Font               = Enum.Font.GothamBold
corHitboxLabel.TextSize           = 12
corHitboxLabel.TextXAlignment     = Enum.TextXAlignment.Left

local corHitboxBtn = Instance.new("TextButton")
corHitboxBtn.Parent          = hitboxFrame
corHitboxBtn.Size            = UDim2.new(0, 100, 0, 24)
corHitboxBtn.Position        = UDim2.new(0, 70, 0, 123)
corHitboxBtn.BackgroundColor3= CORES_HITBOX[corHitboxIndex].cor
corHitboxBtn.Text            = CORES_HITBOX[corHitboxIndex].nome
corHitboxBtn.TextColor3      = Color3.new(1,1,1)
corHitboxBtn.Font            = Enum.Font.GothamBold
corHitboxBtn.TextSize        = 11
Instance.new("UICorner", corHitboxBtn).CornerRadius = UDim.new(0, 4)

local corHitboxPrev = Instance.new("TextButton")
corHitboxPrev.Parent          = hitboxFrame
corHitboxPrev.Size            = UDim2.new(0, 35, 0, 24)
corHitboxPrev.Position        = UDim2.new(0, 175, 0, 123)
corHitboxPrev.BackgroundColor3= Color3.fromRGB(80,80,80)
corHitboxPrev.Text            = "◀"
corHitboxPrev.TextColor3      = Color3.new(1,1,1)
corHitboxPrev.Font            = Enum.Font.GothamBold
corHitboxPrev.TextSize        = 12
Instance.new("UICorner", corHitboxPrev).CornerRadius = UDim.new(0, 4)

local corHitboxNext = Instance.new("TextButton")
corHitboxNext.Parent          = hitboxFrame
corHitboxNext.Size            = UDim2.new(0, 35, 0, 24)
corHitboxNext.Position        = UDim2.new(0, 215, 0, 123)
corHitboxNext.BackgroundColor3= Color3.fromRGB(80,80,80)
corHitboxNext.Text            = "▶"
corHitboxNext.TextColor3      = Color3.new(1,1,1)
corHitboxNext.Font            = Enum.Font.GothamBold
corHitboxNext.TextSize        = 12
Instance.new("UICorner", corHitboxNext).CornerRadius = UDim.new(0, 4)

local function updateCorHitbox()
    HitboxConfig.Color    = CORES_HITBOX[corHitboxIndex].cor
    corHitboxBtn.BackgroundColor3 = CORES_HITBOX[corHitboxIndex].cor
    corHitboxBtn.Text     = CORES_HITBOX[corHitboxIndex].nome
end
corHitboxPrev.MouseButton1Click:Connect(function()
    corHitboxIndex = corHitboxIndex - 1
    if corHitboxIndex < 1 then corHitboxIndex = #CORES_HITBOX end
    updateCorHitbox()
end)
corHitboxNext.MouseButton1Click:Connect(function()
    corHitboxIndex = corHitboxIndex + 1
    if corHitboxIndex > #CORES_HITBOX then corHitboxIndex = 1 end
    updateCorHitbox()
end)

-- Hitbox RGB
local hitboxRGBBtn = Instance.new("TextButton")
hitboxRGBBtn.Parent          = hitboxFrame
hitboxRGBBtn.Size            = UDim2.new(0, 120, 0, 24)
hitboxRGBBtn.Position        = UDim2.new(0, 255, 0, 123)
hitboxRGBBtn.BackgroundColor3= Color3.fromRGB(200,40,40)
hitboxRGBBtn.Text            = "🌈 RGB: OFF"
hitboxRGBBtn.TextColor3      = Color3.new(1,1,1)
hitboxRGBBtn.Font            = Enum.Font.GothamBold
hitboxRGBBtn.TextSize        = 11
Instance.new("UICorner", hitboxRGBBtn).CornerRadius = UDim.new(0, 4)
hitboxRGBBtn.MouseButton1Click:Connect(function()
    _G.HitboxRGBEnabled = not _G.HitboxRGBEnabled
    hitboxRGBBtn.BackgroundColor3 = _G.HitboxRGBEnabled and Color3.fromRGB(148,0,211) or Color3.fromRGB(200,40,40)
    hitboxRGBBtn.Text = "🌈 RGB: "..(  _G.HitboxRGBEnabled and "ON" or "OFF")
end)

-- Material do Hitbox
local matLabel = Instance.new("TextLabel")
matLabel.Parent             = hitboxFrame
matLabel.Size               = UDim2.new(0, 70, 0, 20)
matLabel.Position           = UDim2.new(0, 10, 0, 152)
matLabel.BackgroundTransparency = 1
matLabel.Text               = "Material:"
matLabel.TextColor3         = Color3.new(1,1,1)
matLabel.Font               = Enum.Font.GothamBold
matLabel.TextSize           = 12
matLabel.TextXAlignment     = Enum.TextXAlignment.Left

local MATERIAIS = {
    { nome="Neon",    mat=Enum.Material.Neon },
    { nome="Plastic", mat=Enum.Material.SmoothPlastic },
    { nome="Metal",   mat=Enum.Material.Metal },
    { nome="Glass",   mat=Enum.Material.Glass },
}
local matIndex = 1
local matBtn = Instance.new("TextButton")
matBtn.Parent          = hitboxFrame
matBtn.Size            = UDim2.new(0, 280, 0, 24)
matBtn.Position        = UDim2.new(0, 82, 0, 150)
matBtn.BackgroundColor3= Color3.fromRGB(60,60,60)
matBtn.Text            = "◀ "..MATERIAIS[matIndex].nome.." ▶"
matBtn.TextColor3      = Color3.new(1,1,1)
matBtn.Font            = Enum.Font.GothamBold
matBtn.TextSize        = 12
Instance.new("UICorner", matBtn).CornerRadius = UDim.new(0, 4)
matBtn.MouseButton1Click:Connect(function()
    matIndex = matIndex % #MATERIAIS + 1
    HitboxConfig.Material = MATERIAIS[matIndex].mat
    matBtn.Text = "◀ "..MATERIAIS[matIndex].nome.." ▶"
end)

-- Partes do Hitbox
local _hitboxPartDefs = {
    {key="Todas",  label="Todas"},
    {key="Cabeca", label="Cabeça"},
    {key="Torso",  label="Torso"},
    {key="Bracos", label="Braços"},
    {key="Pernas", label="Pernas"},
    {key="HRP",    label="HRP"},
}
local _partBtns = {}
local _btnW, _btnH, _btnGap = 56, 24, 4
local _startX = 10
local function _UpdatePartBtnColors()
    for _, entry in ipairs(_hitboxPartDefs) do
        local btn = _partBtns[entry.key]
        if btn then
            btn.BackgroundColor3 = HitboxConfig.Parts[entry.key] and Color3.fromRGB(0,190,60) or Color3.fromRGB(70,70,70)
        end
    end
end
for i, def in ipairs(_hitboxPartDefs) do
    local btn = Instance.new("TextButton")
    btn.Parent           = hitboxFrame
    btn.Size             = UDim2.new(0, _btnW, 0, _btnH)
    btn.Position         = UDim2.new(0, _startX + (i-1)*(_btnW+_btnGap), 0, 178)
    btn.BackgroundColor3 = HitboxConfig.Parts[def.key] and Color3.fromRGB(0,190,60) or Color3.fromRGB(70,70,70)
    btn.Text             = def.label
    btn.TextColor3       = Color3.new(1,1,1)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    _partBtns[def.key]   = btn
    btn.MouseButton1Click:Connect(function()
        if def.key == "Todas" then
            for _, k in ipairs({"Cabeca","Torso","Bracos","Pernas","HRP"}) do
                HitboxConfig.Parts[k] = false
            end
            HitboxConfig.Parts.Todas = true
        else
            HitboxConfig.Parts[def.key] = not HitboxConfig.Parts[def.key]
            HitboxConfig.Parts.Todas = false
            local anyOn = false
            for _, k in ipairs({"Cabeca","Torso","Bracos","Pernas","HRP"}) do
                if HitboxConfig.Parts[k] then anyOn=true; break end
            end
            if not anyOn then HitboxConfig.Parts.Todas = true end
        end
        _UpdatePartBtnColors()
    end)
end

aimY = aimY + 210

-- Hitbox em Aliados
local hitboxRowFrame = Instance.new("Frame")
hitboxRowFrame.Parent          = aimScroll
hitboxRowFrame.Size            = UDim2.new(0, 370, 0, 45)
hitboxRowFrame.Position        = UDim2.new(0, 10, 0, aimY)
hitboxRowFrame.BackgroundTransparency = 1
local disableHitboxBtn = Instance.new("TextButton")
disableHitboxBtn.Parent          = hitboxRowFrame
disableHitboxBtn.Size            = UDim2.new(0, 180, 0, 35)
disableHitboxBtn.Position        = UDim2.new(0, 1, 0, 5)
disableHitboxBtn.BackgroundColor3= _G.DesativarHitboxTeam and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
disableHitboxBtn.Text            = "Hitbox em Aliados: "..(  _G.DesativarHitboxTeam and "OFF" or "ON")
disableHitboxBtn.TextColor3      = Color3.new(1,1,1)
disableHitboxBtn.Font            = Enum.Font.GothamBold
disableHitboxBtn.TextSize        = 12
Instance.new("UICorner", disableHitboxBtn).CornerRadius = UDim.new(0, 5)
local hitboxTeamStatus = Instance.new("TextLabel")
hitboxTeamStatus.Parent          = hitboxRowFrame
hitboxTeamStatus.Size            = UDim2.new(0, 158, 0, 35)
hitboxTeamStatus.Position        = UDim2.new(0, 197, 0, 5)
hitboxTeamStatus.BackgroundColor3= Color3.fromRGB(50,50,50)
hitboxTeamStatus.Text            = "Aliados: "..(  _G.DesativarHitboxTeam and "SEM HITBOX" or "COM HITBOX")
hitboxTeamStatus.TextColor3      = Color3.new(1,1,1)
hitboxTeamStatus.Font            = Enum.Font.GothamBold
hitboxTeamStatus.TextSize        = 12
Instance.new("UICorner", hitboxTeamStatus).CornerRadius = UDim.new(0, 5)
disableHitboxBtn.MouseButton1Click:Connect(function()
    _G.DesativarHitboxTeam = not _G.DesativarHitboxTeam
    disableHitboxBtn.BackgroundColor3 = _G.DesativarHitboxTeam and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    disableHitboxBtn.Text = "Hitbox em Aliados: "..(  _G.DesativarHitboxTeam and "OFF" or "ON")
    hitboxTeamStatus.Text = "Aliados: "..(  _G.DesativarHitboxTeam and "SEM HITBOX" or "COM HITBOX")
end)

end -- AIM FRAME

-- ==============================================
-- VISUAL FRAME
-- ==============================================
do
local visualScroll = CreateScrollFrame(LMG2L["VisualFrame_23"])
local visualY = 10

visualY = CreateToggleRow(visualScroll,
    "ESP",       function() return CFG.espEnabled   end, function(v) CFG.espEnabled   = v end,
    "Box",       function() return CFG.espBox       end, function(v) CFG.espBox       = v end,
    visualY)
visualY = CreateToggleRow(visualScroll,
    "Highlight", function() return CFG.espHighlight end, function(v) CFG.espHighlight = v end,
    "Names",     function() return CFG.espNames     end, function(v) CFG.espNames     = v end,
    visualY)
visualY = CreateToggleRow(visualScroll,
    "Health",    function() return CFG.espHealth    end, function(v) CFG.espHealth    = v end,
    "Tracers",   function() return CFG.espTracers   end, function(v) CFG.espTracers   = v end,
    visualY)
visualY = CreateToggleRow(visualScroll,
    "Distance",  function() return CFG.espDistance  end, function(v) CFG.espDistance  = v end,
    "Team Colors",function() return CFG.espTeamColors end, function(v) CFG.espTeamColors=v end,
    visualY)
visualY = CreateToggleRow(visualScroll,
    "🦴 Skeleton", function() return HUB.ESPSettings.Skeleton.Enabled end,
    function(v) HUB.ESPSettings.Skeleton.Enabled = v end,
    "Aliados: ESP", function() return not _G.DesativarESPTeam end,
    function(v) _G.DesativarESPTeam = not v end,
    visualY)

-- Cor do Skeleton
local CORES_SKEL = {
    { nome="VERMELHO", cor=Color3.fromRGB(255,55,55) },
    { nome="LARANJA",  cor=Color3.fromRGB(255,100,0) },
    { nome="AMARELO",  cor=Color3.fromRGB(255,255,0) },
    { nome="VERDE",    cor=Color3.fromRGB(0,255,0) },
    { nome="CIANO",    cor=Color3.fromRGB(0,255,255) },
    { nome="AZUL",     cor=Color3.fromRGB(0,100,255) },
    { nome="ROXO",     cor=Color3.fromRGB(150,0,255) },
    { nome="ROSA",     cor=Color3.fromRGB(255,0,150) },
}
local skelCorIdx = 1
local _skelCorRow = Instance.new("Frame")
_skelCorRow.Parent = visualScroll; _skelCorRow.Size = UDim2.new(0,370,0,35)
_skelCorRow.Position = UDim2.new(0,10,0,visualY); _skelCorRow.BackgroundColor3 = Color3.fromRGB(45,45,45)
Instance.new("UICorner", _skelCorRow).CornerRadius = UDim.new(0,5)
local _skelCorLbl = Instance.new("TextLabel")
_skelCorLbl.Parent=_skelCorRow; _skelCorLbl.Size=UDim2.new(0,100,1,0); _skelCorLbl.Position=UDim2.new(0,8,0,0)
_skelCorLbl.BackgroundTransparency=1; _skelCorLbl.Text="🦴 Cor:"; _skelCorLbl.TextColor3=Color3.new(1,1,1)
_skelCorLbl.Font=Enum.Font.GothamBold; _skelCorLbl.TextSize=13; _skelCorLbl.TextXAlignment=Enum.TextXAlignment.Left
local skelCorBtn = Instance.new("TextButton")
skelCorBtn.Parent=_skelCorRow; skelCorBtn.Size=UDim2.new(0,110,0,26); skelCorBtn.Position=UDim2.new(0,100,0,4)
skelCorBtn.BackgroundColor3=CORES_SKEL[1].cor; skelCorBtn.Text=CORES_SKEL[1].nome
skelCorBtn.TextColor3=Color3.new(0,0,0); skelCorBtn.Font=Enum.Font.GothamBold; skelCorBtn.TextSize=11
Instance.new("UICorner", skelCorBtn).CornerRadius = UDim.new(0,4)
local skelCorPrev = Instance.new("TextButton")
skelCorPrev.Parent=_skelCorRow; skelCorPrev.Size=UDim2.new(0,45,0,26); skelCorPrev.Position=UDim2.new(0,218,0,4)
skelCorPrev.BackgroundColor3=Color3.fromRGB(80,80,80); skelCorPrev.Text="◀"
skelCorPrev.TextColor3=Color3.new(1,1,1); skelCorPrev.Font=Enum.Font.GothamBold; skelCorPrev.TextSize=14
Instance.new("UICorner", skelCorPrev).CornerRadius = UDim.new(0,4)
local skelCorNext = Instance.new("TextButton")
skelCorNext.Parent=_skelCorRow; skelCorNext.Size=UDim2.new(0,45,0,26); skelCorNext.Position=UDim2.new(0,268,0,4)
skelCorNext.BackgroundColor3=Color3.fromRGB(80,80,80); skelCorNext.Text="▶"
skelCorNext.TextColor3=Color3.new(1,1,1); skelCorNext.Font=Enum.Font.GothamBold; skelCorNext.TextSize=14
Instance.new("UICorner", skelCorNext).CornerRadius = UDim.new(0,4)
local function updateSkelCor()
    HUB.ESPSettings.Skeleton.Color = CORES_SKEL[skelCorIdx].cor
    skelCorBtn.BackgroundColor3 = CORES_SKEL[skelCorIdx].cor
    skelCorBtn.Text = CORES_SKEL[skelCorIdx].nome
end
skelCorPrev.MouseButton1Click:Connect(function()
    skelCorIdx = skelCorIdx - 1; if skelCorIdx<1 then skelCorIdx=#CORES_SKEL end; updateSkelCor()
end)
skelCorNext.MouseButton1Click:Connect(function()
    skelCorIdx = skelCorIdx + 1; if skelCorIdx>#CORES_SKEL then skelCorIdx=1 end; updateSkelCor()
end)
visualY = visualY + 42



-- CORES DO ESP
local CORES_ESP = {
    inimigos = {
        {nome="VERMELHO", cor=Color3.fromRGB(255,55,55)},
        {nome="LARANJA",  cor=Color3.fromRGB(255,100,0)},
        {nome="AMARELO",  cor=Color3.fromRGB(255,255,0)},
        {nome="VERDE",    cor=Color3.fromRGB(0,255,0)},
        {nome="CIANO",    cor=Color3.fromRGB(0,255,255)},
        {nome="AZUL",     cor=Color3.fromRGB(0,100,255)},
        {nome="ROXO",     cor=Color3.fromRGB(150,0,255)},
        {nome="ROSA",     cor=Color3.fromRGB(255,0,150)},
    },
    time = {
        {nome="AZUL",     cor=Color3.fromRGB(50,130,255)},
        {nome="VERDE",    cor=Color3.fromRGB(0,255,0)},
        {nome="CIANO",    cor=Color3.fromRGB(0,255,255)},
        {nome="ROXO",     cor=Color3.fromRGB(150,0,255)},
        {nome="ROSA",     cor=Color3.fromRGB(255,0,150)},
        {nome="LARANJA",  cor=Color3.fromRGB(255,100,0)},
        {nome="AMARELO",  cor=Color3.fromRGB(255,255,0)},
        {nome="VERMELHO", cor=Color3.fromRGB(255,55,55)},
    }
}
local corInimigoAtual = 1
local corTimeAtual    = 1
local function AtualizarCoresESP()
    CFG.espEnemyColor = CORES_ESP.inimigos[corInimigoAtual].cor
    CFG.espTeamColor  = CORES_ESP.time[corTimeAtual].cor
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and espObjects[pl] then
            local objPl = espObjects[pl]
            local cor   = IsTeammate(pl) and CFG.espTeamColor or CFG.espEnemyColor
            if objPl.box then objPl.box.Color3=cor; objPl.box.SurfaceColor3=cor end
            if objPl.hl  then objPl.hl.FillColor=cor; objPl.hl.OutlineColor=cor end
            if objPl.tracer then objPl.tracer.Color=cor end
            if objPl.nameLbl then objPl.nameLbl.TextColor3=cor end
        end
    end
end

local espCorTitle = Instance.new("TextLabel")
espCorTitle.Parent          = visualScroll
espCorTitle.Size            = UDim2.new(0, 370, 0, 25)
espCorTitle.Position        = UDim2.new(0, 10, 0, visualY)
espCorTitle.BackgroundTransparency = 1
espCorTitle.Text            = "🎨 CORES DO ESP"
espCorTitle.TextColor3      = Color3.new(1,1,1)
espCorTitle.Font            = Enum.Font.GothamBold
espCorTitle.TextSize        = 16
espCorTitle.TextXAlignment  = Enum.TextXAlignment.Center
visualY = visualY + 30

local function makeCoresRow(parent, label, colorTable, getIdx, setIdx, yPos)
    local frame = Instance.new("Frame")
    frame.Parent          = parent
    frame.Size            = UDim2.new(0,370,0,45)
    frame.Position        = UDim2.new(0,10,0,yPos)
    frame.BackgroundColor3= Color3.fromRGB(50,50,50)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,5)
    local lbl = Instance.new("TextLabel")
    lbl.Parent=frame; lbl.Size=UDim2.new(0,100,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=Color3.new(1,1,1)
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local corBtn = Instance.new("TextButton")
    corBtn.Parent=frame; corBtn.Size=UDim2.new(0,100,0,30); corBtn.Position=UDim2.new(0,120,0,7)
    corBtn.BackgroundColor3=colorTable[getIdx()].cor; corBtn.Text=colorTable[getIdx()].nome
    corBtn.TextColor3=Color3.new(1,1,1); corBtn.Font=Enum.Font.GothamBold; corBtn.TextSize=11
    Instance.new("UICorner", corBtn).CornerRadius=UDim.new(0,5)
    local bPrev = Instance.new("TextButton")
    bPrev.Parent=frame; bPrev.Size=UDim2.new(0,50,0,30); bPrev.Position=UDim2.new(0,230,0,7)
    bPrev.BackgroundColor3=Color3.fromRGB(80,80,80); bPrev.Text="▶"
    bPrev.TextColor3=Color3.new(1,1,1); bPrev.Font=Enum.Font.GothamBold; bPrev.TextSize=14
    Instance.new("UICorner", bPrev).CornerRadius=UDim.new(0,5)
    local bNext = Instance.new("TextButton")
    bNext.Parent=frame; bNext.Size=UDim2.new(0,50,0,30); bNext.Position=UDim2.new(0,290,0,7)
    bNext.BackgroundColor3=Color3.fromRGB(80,80,80); bNext.Text="◀"
    bNext.TextColor3=Color3.new(1,1,1); bNext.Font=Enum.Font.GothamBold; bNext.TextSize=14
    Instance.new("UICorner", bNext).CornerRadius=UDim.new(0,5)
    local function refresh()
        corBtn.BackgroundColor3 = colorTable[getIdx()].cor
        corBtn.Text = colorTable[getIdx()].nome
        local r,g,b = colorTable[getIdx()].cor.R, colorTable[getIdx()].cor.G, colorTable[getIdx()].cor.B
        corBtn.TextColor3 = (0.299*r+0.587*g+0.114*b)>0.5 and Color3.new(0,0,0) or Color3.new(1,1,1)
        AtualizarCoresESP()
    end
    bPrev.MouseButton1Click:Connect(function()
        local idx = getIdx()+1; if idx>#colorTable then idx=1 end; setIdx(idx); refresh()
    end)
    bNext.MouseButton1Click:Connect(function()
        local idx = getIdx()-1; if idx<1 then idx=#colorTable end; setIdx(idx); refresh()
    end)
    refresh()
end
makeCoresRow(visualScroll, "INIMIGOS:",
    CORES_ESP.inimigos, function() return corInimigoAtual end,
    function(v) corInimigoAtual=v end, visualY)
visualY = visualY + 50
makeCoresRow(visualScroll, "TIME:",
    CORES_ESP.time, function() return corTimeAtual end,
    function(v) corTimeAtual=v end, visualY)
visualY = visualY + 50

local btnResetESP = Instance.new("TextButton")
btnResetESP.Parent=visualScroll; btnResetESP.Size=UDim2.new(0,180,0,35)
btnResetESP.Position=UDim2.new(0,10,0,visualY); btnResetESP.BackgroundColor3=Color3.fromRGB(100,100,100)
btnResetESP.Text="↺ RESET CORES ESP"; btnResetESP.TextColor3=Color3.new(1,1,1)
btnResetESP.Font=Enum.Font.GothamBold; btnResetESP.TextSize=12
Instance.new("UICorner", btnResetESP).CornerRadius=UDim.new(0,5)
btnResetESP.MouseButton1Click:Connect(function()
    corInimigoAtual=1; corTimeAtual=1; AtualizarCoresESP()
end)
visualY = visualY + 45

-- RGB Section (Visual)
local _vRGBSep = Instance.new("TextLabel")
_vRGBSep.Parent=visualScroll; _vRGBSep.Size=UDim2.new(0,370,0,25)
_vRGBSep.Position=UDim2.new(0,10,0,visualY); _vRGBSep.BackgroundColor3=Color3.fromRGB(148,0,211)
_vRGBSep.BackgroundTransparency=0.4; _vRGBSep.Text="🌈 RGB"
_vRGBSep.TextColor3=Color3.new(1,1,1); _vRGBSep.Font=Enum.Font.GothamBold
_vRGBSep.TextSize=15; _vRGBSep.TextXAlignment=Enum.TextXAlignment.Center
Instance.new("UICorner", _vRGBSep).CornerRadius=UDim.new(0,5)
visualY = visualY + 35

_espRGBBtn = Instance.new("TextButton")
_espRGBBtn.Parent=visualScroll; _espRGBBtn.Size=UDim2.new(0,370,0,35)
_espRGBBtn.Position=UDim2.new(0,10,0,visualY); _espRGBBtn.BackgroundColor3=Color3.fromRGB(200,40,40)
_espRGBBtn.Text="🌈 ESP + Skeleton RGB: OFF"; _espRGBBtn.TextColor3=Color3.new(1,1,1)
_espRGBBtn.Font=Enum.Font.GothamBold; _espRGBBtn.TextSize=14
Instance.new("UICorner", _espRGBBtn).CornerRadius=UDim.new(0,5)
_espRGBBtn.MouseButton1Click:Connect(function()
    _G.ESPRGBEnabled = not _G.ESPRGBEnabled
    _espRGBBtn.BackgroundColor3 = _G.ESPRGBEnabled and Color3.fromRGB(148,0,211) or Color3.fromRGB(200,40,40)
    _espRGBBtn.Text = "🌈 ESP + Skeleton RGB: "..(_G.ESPRGBEnabled and "ON" or "OFF")
end)
visualY = visualY + 45

-- Visual Effects section
local _visSep = Instance.new("TextLabel")
_visSep.Parent=visualScroll; _visSep.Size=UDim2.new(0,370,0,25)
_visSep.Position=UDim2.new(0,10,0,visualY); _visSep.BackgroundColor3=Color3.fromRGB(30,144,255)
_visSep.BackgroundTransparency=0.65; _visSep.Text="🌙 EFEITOS VISUAIS"
_visSep.TextColor3=Color3.new(1,1,1); _visSep.Font=Enum.Font.GothamBold
_visSep.TextSize=15; _visSep.TextXAlignment=Enum.TextXAlignment.Center
Instance.new("UICorner", _visSep).CornerRadius=UDim.new(0,5)
visualY = visualY + 35

local _nvBtn = Instance.new("TextButton")
_nvBtn.Parent=visualScroll; _nvBtn.Size=UDim2.new(0,180,0,35)
_nvBtn.Position=UDim2.new(0,10,0,visualY); _nvBtn.BackgroundColor3=Color3.fromRGB(255,0,0)
_nvBtn.Text="Night Vision: OFF"; _nvBtn.TextColor3=Color3.new(1,1,1)
_nvBtn.Font=Enum.Font.GothamBold; _nvBtn.TextSize=14
Instance.new("UICorner", _nvBtn).CornerRadius=UDim.new(0,5)
_nvBtn.MouseButton1Click:Connect(function()
    ToggleNightVision(not _G.NightVision)
    _nvBtn.BackgroundColor3 = _G.NightVision and Color3.fromRGB(0,200,50) or Color3.fromRGB(255,0,0)
    _nvBtn.Text = "Night Vision: "..(  _G.NightVision and "ON" or "OFF")
end)

local _fbBtn = Instance.new("TextButton")
_fbBtn.Parent=visualScroll; _fbBtn.Size=UDim2.new(0,180,0,35)
_fbBtn.Position=UDim2.new(0,200,0,visualY); _fbBtn.BackgroundColor3=Color3.fromRGB(255,0,0)
_fbBtn.Text="Fullbright: OFF"; _fbBtn.TextColor3=Color3.new(1,1,1)
_fbBtn.Font=Enum.Font.GothamBold; _fbBtn.TextSize=14
Instance.new("UICorner", _fbBtn).CornerRadius=UDim.new(0,5)
_fbBtn.MouseButton1Click:Connect(function()
    ToggleFullbright(not _G.Fullbright)
    _fbBtn.BackgroundColor3 = _G.Fullbright and Color3.fromRGB(0,200,50) or Color3.fromRGB(255,0,0)
    _fbBtn.Text = "Fullbright: "..(  _G.Fullbright and "ON" or "OFF")
end)
visualY = visualY + 45

local _wmBtn = Instance.new("TextButton")
_wmBtn.Parent=visualScroll; _wmBtn.Size=UDim2.new(0,370,0,35)
_wmBtn.Position=UDim2.new(0,10,0,visualY)
_wmBtn.BackgroundColor3 = _G.Watermark and Color3.fromRGB(0,200,50) or Color3.fromRGB(255,0,0)
_wmBtn.Text = "Watermark (HUD): "..(  _G.Watermark and "ON" or "OFF")
_wmBtn.TextColor3=Color3.new(1,1,1); _wmBtn.Font=Enum.Font.GothamBold; _wmBtn.TextSize=14
Instance.new("UICorner", _wmBtn).CornerRadius=UDim.new(0,5)
_wmBtn.MouseButton1Click:Connect(function()
    _G.Watermark = not _G.Watermark
    _wmBtn.BackgroundColor3 = _G.Watermark and Color3.fromRGB(0,200,50) or Color3.fromRGB(255,0,0)
    _wmBtn.Text = "Watermark (HUD): "..(  _G.Watermark and "ON" or "OFF")
end)

end -- VISUAL FRAME

-- ==============================================
-- CONFIG FRAME
-- ==============================================
do
local configScroll = CreateScrollFrame(LMG2L["ConfigFrame_47"])
CreateDistSlider(configScroll, 10)

-- GUI Colors
local CORES = {
    {nome="VERDE",    cor=Color3.fromRGB(29,255,0)},
    {nome="VERMELHO", cor=Color3.fromRGB(255,0,0)},
    {nome="AZUL",     cor=Color3.fromRGB(0,100,255)},
    {nome="ROXO",     cor=Color3.fromRGB(150,0,255)},
    {nome="ROSA",     cor=Color3.fromRGB(255,0,150)},
    {nome="LARANJA",  cor=Color3.fromRGB(255,100,0)},
    {nome="CIANO",    cor=Color3.fromRGB(0,255,255)},
    {nome="AMARELO",  cor=Color3.fromRGB(255,255,0)},
}
local corAtual = 5
local function MudarCor(novaCor)
    if LMG2L["AimButton_50"]    then LMG2L["AimButton_50"].BackgroundColor3    = novaCor end
    if LMG2L["VisualButton_12"] then LMG2L["VisualButton_12"].BackgroundColor3 = novaCor end
    if LMG2L["ConfigButton_b"]  then LMG2L["ConfigButton_b"].BackgroundColor3  = novaCor end
    if LMG2L["InfoButton_7"]    then LMG2L["InfoButton_7"].BackgroundColor3    = novaCor end
    if LMG2L["Titulo_20"]       then LMG2L["Titulo_20"].BackgroundColor3       = novaCor end
    if LMG2L["Titulo_24"]       then LMG2L["Titulo_24"].BackgroundColor3       = novaCor end
    if LMG2L["Titulo_49"]       then LMG2L["Titulo_49"].BackgroundColor3       = novaCor end
    if LMG2L["Titulo_30"]       then LMG2L["Titulo_30"].BackgroundColor3       = novaCor end
    if LMG2L["Decoração_f"]     then LMG2L["Decoração_f"].BackgroundColor3     = novaCor end
    if LMG2L["UIStroke_5"]      then LMG2L["UIStroke_5"].Color                 = novaCor end
end

local corTitle = Instance.new("TextLabel")
corTitle.Parent=configScroll; corTitle.Size=UDim2.new(0,370,0,20)
corTitle.Position=UDim2.new(0,10,0,130); corTitle.BackgroundTransparency=1
corTitle.Text="🎨 CORES DA GUI"; corTitle.TextColor3=Color3.new(1,1,1)
corTitle.Font=Enum.Font.GothamBold; corTitle.TextSize=16; corTitle.TextXAlignment=Enum.TextXAlignment.Center

-- 8 color buttons (2 rows of 4)
local coresBtns8 = {"VERDE","VERMELHO","AZUL","ROXO","ROSA","LARANJA","CIANO","AMARELO"}
local coresPosX = {12,108,204,300, 12,108,204,300}
local coresPosY = {155,155,155,155, 190,190,190,190}
local corAtualLabel = Instance.new("TextLabel")
corAtualLabel.Parent=configScroll; corAtualLabel.Size=UDim2.new(0,240,0,30)
corAtualLabel.Position=UDim2.new(0,140,0,225); corAtualLabel.BackgroundColor3=Color3.fromRGB(50,50,50)
corAtualLabel.BackgroundTransparency=0.3; corAtualLabel.Text="Atual: ROSA"
corAtualLabel.TextColor3=Color3.new(1,1,1); corAtualLabel.Font=Enum.Font.GothamBold
corAtualLabel.TextSize=12; corAtualLabel.TextXAlignment=Enum.TextXAlignment.Center
Instance.new("UICorner", corAtualLabel).CornerRadius=UDim.new(0,5)

for i, nomeCor in ipairs(coresBtns8) do
    local btn = Instance.new("TextButton")
    btn.Parent=configScroll; btn.Size=UDim2.new(0,88,0,30)
    btn.Position=UDim2.new(0,coresPosX[i],0,coresPosY[i])
    btn.BackgroundColor3=CORES[i].cor; btn.Text=nomeCor
    local r,g,b = CORES[i].cor.R, CORES[i].cor.G, CORES[i].cor.B
    btn.TextColor3 = (0.299*r+0.587*g+0.114*b)>0.5 and Color3.new(0,0,0) or Color3.new(1,1,1)
    btn.Font=Enum.Font.GothamBold; btn.TextSize=10
    Instance.new("UICorner", btn).CornerRadius=UDim.new(0,5)
    local idx = i
    btn.MouseButton1Click:Connect(function()
        MudarCor(CORES[idx].cor); corAtual=idx
        corAtualLabel.Text = "Atual: "..CORES[idx].nome
    end)
end

local btnReset = Instance.new("TextButton")
btnReset.Parent=configScroll; btnReset.Size=UDim2.new(0,120,0,30)
btnReset.Position=UDim2.new(0,12,0,225); btnReset.BackgroundColor3=Color3.fromRGB(100,100,100)
btnReset.Text="↺ RESET"; btnReset.TextColor3=Color3.new(1,1,1)
btnReset.Font=Enum.Font.GothamBold; btnReset.TextSize=12
Instance.new("UICorner", btnReset).CornerRadius=UDim.new(0,5)
btnReset.MouseButton1Click:Connect(function()
    MudarCor(CORES[5].cor); corAtual=5; corAtualLabel.Text="Atual: ROSA"
end)

-- Aplicar cor padrão rosa ao iniciar
MudarCor(CORES[5].cor)

-- UTILIDADES
local _cfgY = 265

local function _MakeConfigBtn(parent, texto, yPos, onToggle, getState)
    local btn = Instance.new("TextButton")
    btn.Parent=parent; btn.Size=UDim2.new(0,370,0,35)
    btn.Position=UDim2.new(0,10,0,yPos)
    btn.BackgroundColor3 = getState() and Color3.fromRGB(0,200,50) or Color3.fromRGB(200,40,40)
    btn.Text = texto..": "..(getState() and "ON" or "OFF")
    btn.TextColor3=Color3.new(1,1,1); btn.Font=Enum.Font.GothamBold; btn.TextSize=14
    Instance.new("UICorner", btn).CornerRadius=UDim.new(0,5)
    btn.MouseButton1Click:Connect(function()
        onToggle(not getState())
        btn.BackgroundColor3 = getState() and Color3.fromRGB(0,200,50) or Color3.fromRGB(200,40,40)
        btn.Text = texto..": "..(getState() and "ON" or "OFF")
    end)
    return yPos + 45
end

local _cfgSep = Instance.new("TextLabel")
_cfgSep.Parent=configScroll; _cfgSep.Size=UDim2.new(0,370,0,25)
_cfgSep.Position=UDim2.new(0,10,0,_cfgY); _cfgSep.BackgroundColor3=Color3.fromRGB(30,144,255)
_cfgSep.BackgroundTransparency=0.65; _cfgSep.Text="⚙️ UTILIDADES"
_cfgSep.TextColor3=Color3.new(1,1,1); _cfgSep.Font=Enum.Font.GothamBold
_cfgSep.TextSize=15; _cfgSep.TextXAlignment=Enum.TextXAlignment.Center
Instance.new("UICorner", _cfgSep).CornerRadius=UDim.new(0,5)
_cfgY = _cfgY + 35

_cfgY = _MakeConfigBtn(configScroll,"⏱ Fake Lag",       _cfgY,ToggleFakeLag,  function() return _G.FakeLag      end)
_cfgY = _MakeConfigBtn(configScroll,"💤 Anti-AFK",       _cfgY,ToggleAntiAFK,  function() return _G.AntiAFK      end)
_cfgY = _MakeConfigBtn(configScroll,"🐰 BunnyHop",       _cfgY,ToggleBunnyHop, function() return _G.BunnyHop     end)
_cfgY = _MakeConfigBtn(configScroll,"🦘 Infinite Jump",  _cfgY,function(v) _G.InfiniteJump=v end, function() return _G.InfiniteJump end)
_cfgY = _MakeConfigBtn(configScroll,"💨 Speed Hack",     _cfgY,ToggleSpeedHack,function() return _G.SpeedHack    end)
_cfgY = _MakeConfigBtn(configScroll,"👻 NoClip",         _cfgY,ToggleNoClip,   function() return _G.NoClip       end)
_cfgY = _MakeConfigBtn(configScroll,"✈️ Fly (tecla F)",  _cfgY,ToggleFly,      function() return _G.FlyEnabled   end)

-- Guardar ref do botão de fly para atualizar com tecla F
do
    local _last = configScroll:GetChildren()
    for _, c in pairs(configScroll:GetChildren()) do
        if c:IsA("TextButton") and c.Text:find("Fly") then
            _flyToggleBtn = c; break
        end
    end
end

-- Fly Speed slider
local _flyBg = Instance.new("Frame")
_flyBg.Parent=configScroll; _flyBg.Size=UDim2.new(0,370,0,65)
_flyBg.Position=UDim2.new(0,10,0,_cfgY); _flyBg.BackgroundColor3=Color3.fromRGB(50,50,50)
Instance.new("UICorner",_flyBg).CornerRadius=UDim.new(0,5)
local _flyLabel=Instance.new("TextLabel")
_flyLabel.Parent=_flyBg; _flyLabel.Size=UDim2.new(1,0,0,25)
_flyLabel.Position=UDim2.new(0,0,0,5); _flyLabel.BackgroundTransparency=1
_flyLabel.Text="✈️ Fly Speed: ".._G.FlySpeed.." st/s"
_flyLabel.TextColor3=Color3.new(1,1,1); _flyLabel.Font=Enum.Font.GothamBold; _flyLabel.TextSize=14
local _flySlBg=Instance.new("Frame")
_flySlBg.Parent=_flyBg; _flySlBg.Size=UDim2.new(0,350,0,25)
_flySlBg.Position=UDim2.new(0,10,0,35); _flySlBg.BackgroundColor3=Color3.fromRGB(80,80,80)
Instance.new("UICorner",_flySlBg).CornerRadius=UDim.new(0,5)
local _flyFill=Instance.new("Frame")
_flyFill.Parent=_flySlBg; _flyFill.Size=UDim2.new((_G.FlySpeed-20)/280,0,1,0)
_flyFill.BackgroundColor3=Color3.fromRGB(30,144,255)
Instance.new("UICorner",_flyFill).CornerRadius=UDim.new(0,5)
local _flyDrag=Instance.new("TextButton")
_flyDrag.Parent=_flySlBg; _flyDrag.Size=UDim2.new(1,0,1,0)
_flyDrag.BackgroundTransparency=1; _flyDrag.Text=""; _flyDrag.ZIndex=10
local _flyDragging=false
local function _updateFly(pos)
    if not _flyDragging then return end
    local absPos=_flySlBg.AbsolutePosition; local sz=_flySlBg.AbsoluteSize.X
    local relX=math.clamp(pos.X-absPos.X,0,sz); local pct=relX/sz
    _G.FlySpeed=math.floor(20+pct*280)
    _flyFill.Size=UDim2.new(pct,0,1,0)
    _flyLabel.Text="✈️ Fly Speed: ".._G.FlySpeed.." st/s"
end
_flyDrag.MouseButton1Down:Connect(function() _flyDragging=true; _updateFly(UserInputService:GetMouseLocation()) end)
_flyDrag.MouseButton1Up:Connect(function() _flyDragging=false end)
UserInputService.InputChanged:Connect(function(i) if _flyDragging and i.UserInputType==Enum.UserInputType.MouseMovement then _updateFly(UserInputService:GetMouseLocation()) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _flyDragging=false end end)
_cfgY = _cfgY + 75

-- ─── TRIGGERBOT ───
local _trigSep = Instance.new("TextLabel")
_trigSep.Parent=configScroll; _trigSep.Size=UDim2.new(0,370,0,25)
_trigSep.Position=UDim2.new(0,10,0,_cfgY); _trigSep.BackgroundColor3=Color3.fromRGB(30,144,255)
_trigSep.BackgroundTransparency=0.65; _trigSep.Text="🔫 TRIGGERBOT (FLICK)"
_trigSep.TextColor3=Color3.new(1,1,1); _trigSep.Font=Enum.Font.GothamBold
_trigSep.TextSize=15; _trigSep.TextXAlignment=Enum.TextXAlignment.Center
Instance.new("UICorner",_trigSep).CornerRadius=UDim.new(0,5)
_cfgY = _cfgY + 35
_cfgY = _MakeConfigBtn(configScroll,"🔫 TriggerBot",_cfgY,ToggleTriggerBot,function() return _G.TriggerBot end)
_cfgY = _MakeConfigBtn(configScroll,"🖱️ Modo Segurar (Hold)",_cfgY,
    function(v) _G.TriggerHoldMode=v end,
    function() return _G.TriggerHoldMode end)

-- TriggerBot delay slider
local _trigBg=Instance.new("Frame")
_trigBg.Parent=configScroll; _trigBg.Size=UDim2.new(0,370,0,65)
_trigBg.Position=UDim2.new(0,10,0,_cfgY); _trigBg.BackgroundColor3=Color3.fromRGB(50,50,50)
Instance.new("UICorner",_trigBg).CornerRadius=UDim.new(0,5)
local _trigLabel=Instance.new("TextLabel")
_trigLabel.Parent=_trigBg; _trigLabel.Size=UDim2.new(1,0,0,25)
_trigLabel.Position=UDim2.new(0,0,0,5); _trigLabel.BackgroundTransparency=1
_trigLabel.Text="⏱ Delay: ".._G.TriggerDelay.." ms"
_trigLabel.TextColor3=Color3.new(1,1,1); _trigLabel.Font=Enum.Font.GothamBold; _trigLabel.TextSize=14
local _trigSlBg=Instance.new("Frame")
_trigSlBg.Parent=_trigBg; _trigSlBg.Size=UDim2.new(0,350,0,25)
_trigSlBg.Position=UDim2.new(0,10,0,35); _trigSlBg.BackgroundColor3=Color3.fromRGB(80,80,80)
Instance.new("UICorner",_trigSlBg).CornerRadius=UDim.new(0,5)
local _trigFill=Instance.new("Frame")
_trigFill.Parent=_trigSlBg; _trigFill.Size=UDim2.new((_G.TriggerDelay-10)/490,0,1,0)
_trigFill.BackgroundColor3=Color3.fromRGB(30,144,255)
Instance.new("UICorner",_trigFill).CornerRadius=UDim.new(0,5)
local _trigDrag=Instance.new("TextButton")
_trigDrag.Parent=_trigSlBg; _trigDrag.Size=UDim2.new(1,0,1,0)
_trigDrag.BackgroundTransparency=1; _trigDrag.Text=""; _trigDrag.ZIndex=10
local _trigDragging=false
local function _updateTrig(pos)
    if not _trigDragging then return end
    local absPos=_trigSlBg.AbsolutePosition; local sz=_trigSlBg.AbsoluteSize.X
    local relX=math.clamp(pos.X-absPos.X,0,sz); local pct=relX/sz
    _G.TriggerDelay=math.floor(10+pct*490)
    _trigFill.Size=UDim2.new(pct,0,1,0)
    _trigLabel.Text="⏱ Delay: ".._G.TriggerDelay.." ms"
end
_trigDrag.MouseButton1Down:Connect(function() _trigDragging=true; _updateTrig(UserInputService:GetMouseLocation()) end)
_trigDrag.MouseButton1Up:Connect(function() _trigDragging=false end)
UserInputService.InputChanged:Connect(function(i) if _trigDragging and i.UserInputType==Enum.UserInputType.MouseMovement then _updateTrig(UserInputService:GetMouseLocation()) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _trigDragging=false end end)
_cfgY = _cfgY + 75

-- ─── TELEPORT BEHIND ENEMY ───
local _teleSep = Instance.new("TextLabel")
_teleSep.Parent=configScroll; _teleSep.Size=UDim2.new(0,370,0,25)
_teleSep.Position=UDim2.new(0,10,0,_cfgY); _teleSep.BackgroundColor3=Color3.fromRGB(30,144,255)
_teleSep.BackgroundTransparency=0.65; _teleSep.Text="⚡ TELEPORTE ATRÁS DO INIMIGO"
_teleSep.TextColor3=Color3.new(1,1,1); _teleSep.Font=Enum.Font.GothamBold
_teleSep.TextSize=15; _teleSep.TextXAlignment=Enum.TextXAlignment.Center
Instance.new("UICorner",_teleSep).CornerRadius=UDim.new(0,5)
_cfgY = _cfgY + 35

-- Offset slider
local _teleOffBg=Instance.new("Frame")
_teleOffBg.Parent=configScroll; _teleOffBg.Size=UDim2.new(0,370,0,65)
_teleOffBg.Position=UDim2.new(0,10,0,_cfgY); _teleOffBg.BackgroundColor3=Color3.fromRGB(50,50,50)
Instance.new("UICorner",_teleOffBg).CornerRadius=UDim.new(0,5)
local _teleOffLabel=Instance.new("TextLabel")
_teleOffLabel.Parent=_teleOffBg; _teleOffLabel.Size=UDim2.new(1,0,0,25)
_teleOffLabel.Position=UDim2.new(0,0,0,5); _teleOffLabel.BackgroundTransparency=1
_teleOffLabel.Text="📏 Offset Atrás: ".._G.TeleportOffset.." st"
_teleOffLabel.TextColor3=Color3.new(1,1,1); _teleOffLabel.Font=Enum.Font.GothamBold; _teleOffLabel.TextSize=14
local _teleSlBg=Instance.new("Frame")
_teleSlBg.Parent=_teleOffBg; _teleSlBg.Size=UDim2.new(0,350,0,25)
_teleSlBg.Position=UDim2.new(0,10,0,35); _teleSlBg.BackgroundColor3=Color3.fromRGB(80,80,80)
Instance.new("UICorner",_teleSlBg).CornerRadius=UDim.new(0,5)
local _teleFill=Instance.new("Frame")
_teleFill.Parent=_teleSlBg; _teleFill.Size=UDim2.new((_G.TeleportOffset-1)/29,0,1,0)
_teleFill.BackgroundColor3=Color3.fromRGB(30,144,255)
Instance.new("UICorner",_teleFill).CornerRadius=UDim.new(0,5)
local _teleDrag=Instance.new("TextButton")
_teleDrag.Parent=_teleSlBg; _teleDrag.Size=UDim2.new(1,0,1,0)
_teleDrag.BackgroundTransparency=1; _teleDrag.Text=""; _teleDrag.ZIndex=10
local _teleDragging=false
local function _updateTele(pos)
    if not _teleDragging then return end
    local absPos=_teleSlBg.AbsolutePosition; local sz=_teleSlBg.AbsoluteSize.X
    local relX=math.clamp(pos.X-absPos.X,0,sz); local pct=relX/sz
    _G.TeleportOffset=math.max(1,math.floor(1+pct*29))
    _teleFill.Size=UDim2.new(pct,0,1,0)
    _teleOffLabel.Text="📏 Offset Atrás: ".._G.TeleportOffset.." st"
end
_teleDrag.MouseButton1Down:Connect(function() _teleDragging=true; _updateTele(UserInputService:GetMouseLocation()) end)
_teleDrag.MouseButton1Up:Connect(function() _teleDragging=false end)
UserInputService.InputChanged:Connect(function(i) if _teleDragging and i.UserInputType==Enum.UserInputType.MouseMovement then _updateTele(UserInputService:GetMouseLocation()) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _teleDragging=false end end)
_cfgY = _cfgY + 75

-- Botão executar teleporte
local _teleBtn=Instance.new("TextButton")
_teleBtn.Parent=configScroll; _teleBtn.Size=UDim2.new(0,370,0,40)
_teleBtn.Position=UDim2.new(0,10,0,_cfgY); _teleBtn.BackgroundColor3=Color3.fromRGB(80,45,175)
_teleBtn.Text="⚡ Teleportar Atrás do Inimigo Mais Próximo"
_teleBtn.TextColor3=Color3.new(1,1,1); _teleBtn.Font=Enum.Font.GothamBold; _teleBtn.TextSize=13
Instance.new("UICorner",_teleBtn).CornerRadius=UDim.new(0,5)
_teleBtn.MouseButton1Click:Connect(function()
    TeleportBehindEnemy()
    _teleBtn.BackgroundColor3=Color3.fromRGB(130,80,255)
    task.delay(0.25,function() _teleBtn.BackgroundColor3=Color3.fromRGB(80,45,175) end)
end)
_cfgY = _cfgY + 50
local _spdBg = Instance.new("Frame")
_spdBg.Parent=configScroll; _spdBg.Size=UDim2.new(0,370,0,65)
_spdBg.Position=UDim2.new(0,10,0,_cfgY); _spdBg.BackgroundColor3=Color3.fromRGB(50,50,50)
Instance.new("UICorner", _spdBg).CornerRadius=UDim.new(0,5)
local _spdLabel = Instance.new("TextLabel")
_spdLabel.Parent=_spdBg; _spdLabel.Size=UDim2.new(1,0,0,25)
_spdLabel.Position=UDim2.new(0,0,0,5); _spdLabel.BackgroundTransparency=1
_spdLabel.Text="💨 Velocidade: ".._G.SpeedMultiplier.."x"
_spdLabel.TextColor3=Color3.new(1,1,1); _spdLabel.Font=Enum.Font.GothamBold; _spdLabel.TextSize=14
local _spdSlBg=Instance.new("Frame")
_spdSlBg.Parent=_spdBg; _spdSlBg.Size=UDim2.new(0,350,0,25)
_spdSlBg.Position=UDim2.new(0,10,0,35); _spdSlBg.BackgroundColor3=Color3.fromRGB(80,80,80)
Instance.new("UICorner",_spdSlBg).CornerRadius=UDim.new(0,5)
local _spdFill=Instance.new("Frame")
_spdFill.Parent=_spdSlBg; _spdFill.Size=UDim2.new((_G.SpeedMultiplier-1)/9,0,1,0)
_spdFill.BackgroundColor3=Color3.fromRGB(30,144,255)
Instance.new("UICorner",_spdFill).CornerRadius=UDim.new(0,5)
local _spdDrag=Instance.new("TextButton")
_spdDrag.Parent=_spdSlBg; _spdDrag.Size=UDim2.new(1,0,1,0)
_spdDrag.BackgroundTransparency=1; _spdDrag.Text=""; _spdDrag.ZIndex=10
local _spdDragging=false
local function _updateSpd(pos)
    if not _spdDragging then return end
    local absPos=_spdSlBg.AbsolutePosition; local sz=_spdSlBg.AbsoluteSize.X
    local relX=math.clamp(pos.X-absPos.X,0,sz); local pct=relX/sz
    _G.SpeedMultiplier=math.max(1,math.floor(1+pct*9))
    _spdFill.Size=UDim2.new(pct,0,1,0)
    _spdLabel.Text="💨 Velocidade: ".._G.SpeedMultiplier.."x"
end
_spdDrag.MouseButton1Down:Connect(function() _spdDragging=true; _updateSpd(UserInputService:GetMouseLocation()) end)
_spdDrag.MouseButton1Up:Connect(function() _spdDragging=false end)
UserInputService.InputChanged:Connect(function(i) if _spdDragging and i.UserInputType==Enum.UserInputType.MouseMovement then _updateSpd(UserInputService:GetMouseLocation()) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _spdDragging=false end end)
_cfgY = _cfgY + 75

-- SpinBot + speed slider
local _spinSep = Instance.new("TextLabel")
_spinSep.Parent=configScroll; _spinSep.Size=UDim2.new(0,370,0,25)
_spinSep.Position=UDim2.new(0,10,0,_cfgY); _spinSep.BackgroundColor3=Color3.fromRGB(30,144,255)
_spinSep.BackgroundTransparency=0.65; _spinSep.Text="🌀 SPINBOT + TERCEIRA PESSOA"
_spinSep.TextColor3=Color3.new(1,1,1); _spinSep.Font=Enum.Font.GothamBold
_spinSep.TextSize=15; _spinSep.TextXAlignment=Enum.TextXAlignment.Center
Instance.new("UICorner", _spinSep).CornerRadius=UDim.new(0,5)
_cfgY = _cfgY + 35

_cfgY = _MakeConfigBtn(configScroll,"🌀 SpinBot",_cfgY,
    function(v) HUB.SpinBotEnabled=v end, function() return HUB.SpinBotEnabled end)

-- SpinBot speed slider
local _spnBg=Instance.new("Frame")
_spnBg.Parent=configScroll; _spnBg.Size=UDim2.new(0,370,0,65)
_spnBg.Position=UDim2.new(0,10,0,_cfgY); _spnBg.BackgroundColor3=Color3.fromRGB(50,50,50)
Instance.new("UICorner",_spnBg).CornerRadius=UDim.new(0,5)
local _spnLabel=Instance.new("TextLabel")
_spnLabel.Parent=_spnBg; _spnLabel.Size=UDim2.new(1,0,0,25)
_spnLabel.Position=UDim2.new(0,0,0,5); _spnLabel.BackgroundTransparency=1
_spnLabel.Text="🌀 Velocidade Spin: "..HUB.SpinBotSpeed
_spnLabel.TextColor3=Color3.new(1,1,1); _spnLabel.Font=Enum.Font.GothamBold; _spnLabel.TextSize=14
local _spnSlBg=Instance.new("Frame")
_spnSlBg.Parent=_spnBg; _spnSlBg.Size=UDim2.new(0,350,0,25)
_spnSlBg.Position=UDim2.new(0,10,0,35); _spnSlBg.BackgroundColor3=Color3.fromRGB(80,80,80)
Instance.new("UICorner",_spnSlBg).CornerRadius=UDim.new(0,5)
local _spnFill=Instance.new("Frame")
_spnFill.Parent=_spnSlBg; _spnFill.Size=UDim2.new((HUB.SpinBotSpeed-10)/40,0,1,0)
_spnFill.BackgroundColor3=Color3.fromRGB(30,144,255)
Instance.new("UICorner",_spnFill).CornerRadius=UDim.new(0,5)
local _spnDrag=Instance.new("TextButton")
_spnDrag.Parent=_spnSlBg; _spnDrag.Size=UDim2.new(1,0,1,0)
_spnDrag.BackgroundTransparency=1; _spnDrag.Text=""; _spnDrag.ZIndex=10
local _spnDragging=false
local function _updateSpn(pos)
    if not _spnDragging then return end
    local absPos=_spnSlBg.AbsolutePosition; local sz=_spnSlBg.AbsoluteSize.X
    local relX=math.clamp(pos.X-absPos.X,0,sz); local pct=relX/sz
    HUB.SpinBotSpeed=math.clamp(math.floor(10+pct*40),10,50)
    _spnFill.Size=UDim2.new(pct,0,1,0)
    _spnLabel.Text="🌀 Velocidade Spin: "..HUB.SpinBotSpeed
end
_spnDrag.MouseButton1Down:Connect(function() _spnDragging=true; _updateSpn(UserInputService:GetMouseLocation()) end)
_spnDrag.MouseButton1Up:Connect(function() _spnDragging=false end)
UserInputService.InputChanged:Connect(function(i) if _spnDragging and i.UserInputType==Enum.UserInputType.MouseMovement then _updateSpn(UserInputService:GetMouseLocation()) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _spnDragging=false end end)
_cfgY = _cfgY + 75

-- Third Person
local _tpBtn = Instance.new("TextButton")
_tpBtn.Parent=configScroll; _tpBtn.Size=UDim2.new(0,370,0,35)
_tpBtn.Position=UDim2.new(0,10,0,_cfgY)
_tpBtn.BackgroundColor3=Color3.fromRGB(200,40,40)
_tpBtn.Text="👁 Third Person: OFF"; _tpBtn.TextColor3=Color3.new(1,1,1)
_tpBtn.Font=Enum.Font.GothamBold; _tpBtn.TextSize=14
Instance.new("UICorner", _tpBtn).CornerRadius=UDim.new(0,5)
_tpBtn.MouseButton1Click:Connect(function()
    HUB.ThirdPersonEnabled = not HUB.ThirdPersonEnabled
    HUB.ApplyThirdPerson()
    _tpBtn.BackgroundColor3 = HUB.ThirdPersonEnabled and Color3.fromRGB(0,200,50) or Color3.fromRGB(200,40,40)
    _tpBtn.Text = "👁 Third Person: "..(HUB.ThirdPersonEnabled and "ON" or "OFF")
end)
_cfgY = _cfgY + 45

-- Camera FOV slider
local _camSep = Instance.new("TextLabel")
_camSep.Parent=configScroll; _camSep.Size=UDim2.new(0,370,0,25)
_camSep.Position=UDim2.new(0,10,0,_cfgY); _camSep.BackgroundColor3=Color3.fromRGB(30,144,255)
_camSep.BackgroundTransparency=0.65; _camSep.Text="📷 CAMERA FOV"
_camSep.TextColor3=Color3.new(1,1,1); _camSep.Font=Enum.Font.GothamBold
_camSep.TextSize=15; _camSep.TextXAlignment=Enum.TextXAlignment.Center
Instance.new("UICorner", _camSep).CornerRadius=UDim.new(0,5)
_cfgY = _cfgY + 35

local _camBg=Instance.new("Frame")
_camBg.Parent=configScroll; _camBg.Size=UDim2.new(0,370,0,65)
_camBg.Position=UDim2.new(0,10,0,_cfgY); _camBg.BackgroundColor3=Color3.fromRGB(50,50,50)
Instance.new("UICorner",_camBg).CornerRadius=UDim.new(0,5)
local _camLabel=Instance.new("TextLabel")
_camLabel.Parent=_camBg; _camLabel.Size=UDim2.new(1,0,0,25)
_camLabel.Position=UDim2.new(0,0,0,5); _camLabel.BackgroundTransparency=1
_camLabel.Text="📷 Camera FOV: "..HUB.CustomFOV
_camLabel.TextColor3=Color3.new(1,1,1); _camLabel.Font=Enum.Font.GothamBold; _camLabel.TextSize=14
local _camSlBg=Instance.new("Frame")
_camSlBg.Parent=_camBg; _camSlBg.Size=UDim2.new(0,350,0,25)
_camSlBg.Position=UDim2.new(0,10,0,35); _camSlBg.BackgroundColor3=Color3.fromRGB(80,80,80)
Instance.new("UICorner",_camSlBg).CornerRadius=UDim.new(0,5)
local _camFill=Instance.new("Frame")
_camFill.Parent=_camSlBg; _camFill.Size=UDim2.new((HUB.CustomFOV-60)/240,0,1,0)
_camFill.BackgroundColor3=Color3.fromRGB(30,144,255)
Instance.new("UICorner",_camFill).CornerRadius=UDim.new(0,5)
local _camDrag=Instance.new("TextButton")
_camDrag.Parent=_camSlBg; _camDrag.Size=UDim2.new(1,0,1,0)
_camDrag.BackgroundTransparency=1; _camDrag.Text=""; _camDrag.ZIndex=10
local _camDragging=false
local function _updateCam(pos)
    if not _camDragging then return end
    local absPos=_camSlBg.AbsolutePosition; local sz=_camSlBg.AbsoluteSize.X
    local relX=math.clamp(pos.X-absPos.X,0,sz); local pct=relX/sz
    HUB.CustomFOV=math.clamp(math.floor(60+pct*240),60,300)
    HUB.CustomFOVEnabled=true
    _camFill.Size=UDim2.new(pct,0,1,0)
    _camLabel.Text="📷 Camera FOV: "..HUB.CustomFOV
end
_camDrag.MouseButton1Down:Connect(function() _camDragging=true; _updateCam(UserInputService:GetMouseLocation()) end)
_camDrag.MouseButton1Up:Connect(function() _camDragging=false end)
UserInputService.InputChanged:Connect(function(i) if _camDragging and i.UserInputType==Enum.UserInputType.MouseMovement then _updateCam(UserInputService:GetMouseLocation()) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _camDragging=false end end)
_cfgY = _cfgY + 75

-- Reset Camera FOV button
local _camResetBtn=Instance.new("TextButton")
_camResetBtn.Parent=configScroll; _camResetBtn.Size=UDim2.new(0,370,0,30)
_camResetBtn.Position=UDim2.new(0,10,0,_cfgY); _camResetBtn.BackgroundColor3=Color3.fromRGB(100,100,100)
_camResetBtn.Text="↺ Reset Camera FOV (70°)"; _camResetBtn.TextColor3=Color3.new(1,1,1)
_camResetBtn.Font=Enum.Font.GothamBold; _camResetBtn.TextSize=13
Instance.new("UICorner",_camResetBtn).CornerRadius=UDim.new(0,5)
_camResetBtn.MouseButton1Click:Connect(function()
    HUB.CustomFOV=70; HUB.CustomFOVEnabled=false
    Camera.FieldOfView=70
    _camFill.Size=UDim2.new((70-60)/240,0,1,0)
    _camLabel.Text="📷 Camera FOV: 70"
end)
_cfgY = _cfgY + 40

-- HIT SOUND
local _hsSep = Instance.new("TextLabel")
_hsSep.Parent=configScroll; _hsSep.Size=UDim2.new(0,370,0,25)
_hsSep.Position=UDim2.new(0,10,0,_cfgY); _hsSep.BackgroundColor3=Color3.fromRGB(200,40,40)
_hsSep.BackgroundTransparency=0.5; _hsSep.Text="🔊 HIT SOUND"
_hsSep.TextColor3=Color3.new(1,1,1); _hsSep.Font=Enum.Font.GothamBold
_hsSep.TextSize=15; _hsSep.TextXAlignment=Enum.TextXAlignment.Center
Instance.new("UICorner", _hsSep).CornerRadius=UDim.new(0,5)
_cfgY = _cfgY + 35

_cfgY = _MakeConfigBtn(configScroll,"🔊 Hit Sound",_cfgY,
    function(v)
        HUB.HitSoundEnabled=v
        HUB.ReplaceAllHitSounds()
    end, function() return HUB.HitSoundEnabled end)

-- Sound selector ◀▶
local _hsFrame=Instance.new("Frame")
_hsFrame.Parent=configScroll; _hsFrame.Size=UDim2.new(0,370,0,40)
_hsFrame.Position=UDim2.new(0,10,0,_cfgY); _hsFrame.BackgroundColor3=Color3.fromRGB(50,50,50)
Instance.new("UICorner",_hsFrame).CornerRadius=UDim.new(0,5)
local _hsLabel=Instance.new("TextLabel")
_hsLabel.Parent=_hsFrame; _hsLabel.Size=UDim2.new(0,80,1,0)
_hsLabel.Position=UDim2.new(0,5,0,0); _hsLabel.BackgroundTransparency=1
_hsLabel.Text="Som:"; _hsLabel.TextColor3=Color3.new(1,1,1)
_hsLabel.Font=Enum.Font.GothamBold; _hsLabel.TextSize=13; _hsLabel.TextXAlignment=Enum.TextXAlignment.Left
local _hsSoundBtn=Instance.new("TextButton")
_hsSoundBtn.Parent=_hsFrame; _hsSoundBtn.Size=UDim2.new(0,170,0,30)
_hsSoundBtn.Position=UDim2.new(0,70,0,5); _hsSoundBtn.BackgroundColor3=Color3.fromRGB(60,60,60)
_hsSoundBtn.Text=HUB.HitSoundNames[HUB.HitSoundIndex]
_hsSoundBtn.TextColor3=Color3.new(1,1,1); _hsSoundBtn.Font=Enum.Font.GothamBold; _hsSoundBtn.TextSize=11
Instance.new("UICorner",_hsSoundBtn).CornerRadius=UDim.new(0,4)
local _hsPrev=Instance.new("TextButton")
_hsPrev.Parent=_hsFrame; _hsPrev.Size=UDim2.new(0,40,0,30)
_hsPrev.Position=UDim2.new(0,247,0,5); _hsPrev.BackgroundColor3=Color3.fromRGB(80,80,80)
_hsPrev.Text="◀"; _hsPrev.TextColor3=Color3.new(1,1,1); _hsPrev.Font=Enum.Font.GothamBold; _hsPrev.TextSize=14
Instance.new("UICorner",_hsPrev).CornerRadius=UDim.new(0,4)
local _hsNext=Instance.new("TextButton")
_hsNext.Parent=_hsFrame; _hsNext.Size=UDim2.new(0,40,0,30)
_hsNext.Position=UDim2.new(0,292,0,5); _hsNext.BackgroundColor3=Color3.fromRGB(80,80,80)
_hsNext.Text="▶"; _hsNext.TextColor3=Color3.new(1,1,1); _hsNext.Font=Enum.Font.GothamBold; _hsNext.TextSize=14
Instance.new("UICorner",_hsNext).CornerRadius=UDim.new(0,4)
local function _updateHSSound()
    local nome = HUB.HitSoundNames[HUB.HitSoundIndex]
    _hsSoundBtn.Text = nome
    HUB.HitSoundID = HUB.HitSounds[nome]
    if HUB.HitSoundEnabled then HUB.ReplaceAllHitSounds() end
end
_hsPrev.MouseButton1Click:Connect(function()
    HUB.HitSoundIndex = HUB.HitSoundIndex-1
    if HUB.HitSoundIndex<1 then HUB.HitSoundIndex=#HUB.HitSoundNames end
    _updateHSSound()
end)
_hsNext.MouseButton1Click:Connect(function()
    HUB.HitSoundIndex = HUB.HitSoundIndex+1
    if HUB.HitSoundIndex>#HUB.HitSoundNames then HUB.HitSoundIndex=1 end
    _updateHSSound()
end)
_cfgY = _cfgY + 50

-- Volume slider
local _hsVolBg=Instance.new("Frame")
_hsVolBg.Parent=configScroll; _hsVolBg.Size=UDim2.new(0,370,0,65)
_hsVolBg.Position=UDim2.new(0,10,0,_cfgY); _hsVolBg.BackgroundColor3=Color3.fromRGB(50,50,50)
Instance.new("UICorner",_hsVolBg).CornerRadius=UDim.new(0,5)
local _hsVolLbl=Instance.new("TextLabel")
_hsVolLbl.Parent=_hsVolBg; _hsVolLbl.Size=UDim2.new(1,0,0,25)
_hsVolLbl.Position=UDim2.new(0,0,0,5); _hsVolLbl.BackgroundTransparency=1
_hsVolLbl.Text=string.format("🔊 Volume: %.1f",HUB.HitSoundVolume)
_hsVolLbl.TextColor3=Color3.new(1,1,1); _hsVolLbl.Font=Enum.Font.GothamBold; _hsVolLbl.TextSize=14
local _hsVolSlBg=Instance.new("Frame")
_hsVolSlBg.Parent=_hsVolBg; _hsVolSlBg.Size=UDim2.new(0,350,0,25)
_hsVolSlBg.Position=UDim2.new(0,10,0,35); _hsVolSlBg.BackgroundColor3=Color3.fromRGB(80,80,80)
Instance.new("UICorner",_hsVolSlBg).CornerRadius=UDim.new(0,5)
local _hsVolFill=Instance.new("Frame")
_hsVolFill.Parent=_hsVolSlBg; _hsVolFill.Size=UDim2.new((HUB.HitSoundVolume-0.1)/1.9,0,1,0)
_hsVolFill.BackgroundColor3=Color3.fromRGB(30,144,255)
Instance.new("UICorner",_hsVolFill).CornerRadius=UDim.new(0,5)
local _hsVolDrag=Instance.new("TextButton")
_hsVolDrag.Parent=_hsVolSlBg; _hsVolDrag.Size=UDim2.new(1,0,1,0)
_hsVolDrag.BackgroundTransparency=1; _hsVolDrag.Text=""; _hsVolDrag.ZIndex=10
local _hsVolDragging=false
local function _updateHSVol(pos)
    if not _hsVolDragging then return end
    local absPos=_hsVolSlBg.AbsolutePosition; local sz=_hsVolSlBg.AbsoluteSize.X
    local relX=math.clamp(pos.X-absPos.X,0,sz); local pct=relX/sz
    HUB.HitSoundVolume=math.clamp(0.1+pct*1.9, 0.1, 2.0)
    _hsVolFill.Size=UDim2.new(pct,0,1,0)
    _hsVolLbl.Text=string.format("🔊 Volume: %.1f",HUB.HitSoundVolume)
    for sound, _ in pairs(HUB.OriginalHitSounds) do
        pcall(function() if sound and sound.Parent then sound.Volume = HUB.HitSoundVolume end end)
    end
    if HUB.HitSoundEnabled then HUB.ReplaceAllHitSounds() end
end
_hsVolDrag.MouseButton1Down:Connect(function() _hsVolDragging=true; _updateHSVol(UserInputService:GetMouseLocation()) end)
_hsVolDrag.MouseButton1Up:Connect(function() _hsVolDragging=false end)
UserInputService.InputChanged:Connect(function(i) if _hsVolDragging and i.UserInputType==Enum.UserInputType.MouseMovement then _updateHSVol(UserInputService:GetMouseLocation()) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _hsVolDragging=false end end)
_cfgY = _cfgY + 75

-- SKY TIME
local _skySep = Instance.new("TextLabel")
_skySep.Parent=configScroll; _skySep.Size=UDim2.new(0,370,0,25)
_skySep.Position=UDim2.new(0,10,0,_cfgY); _skySep.BackgroundColor3=Color3.fromRGB(100,100,200)
_skySep.BackgroundTransparency=0.5; _skySep.Text="🌤️ SKY TIME"
_skySep.TextColor3=Color3.new(1,1,1); _skySep.Font=Enum.Font.GothamBold
_skySep.TextSize=15; _skySep.TextXAlignment=Enum.TextXAlignment.Center
Instance.new("UICorner", _skySep).CornerRadius=UDim.new(0,5)
_cfgY = _cfgY + 35

local _skyOptions = {"☀️ Dia","🌙 Noite","🌅 Anoitecer"}
local _skyIdx = 1
local _skyFrame=Instance.new("Frame")
_skyFrame.Parent=configScroll; _skyFrame.Size=UDim2.new(0,370,0,40)
_skyFrame.Position=UDim2.new(0,10,0,_cfgY); _skyFrame.BackgroundColor3=Color3.fromRGB(50,50,50)
Instance.new("UICorner",_skyFrame).CornerRadius=UDim.new(0,5)
local _skyBtn=Instance.new("TextButton")
_skyBtn.Parent=_skyFrame; _skyBtn.Size=UDim2.new(0,180,0,30)
_skyBtn.Position=UDim2.new(0,5,0,5); _skyBtn.BackgroundColor3=Color3.fromRGB(60,60,60)
_skyBtn.Text=_skyOptions[_skyIdx]; _skyBtn.TextColor3=Color3.new(1,1,1)
_skyBtn.Font=Enum.Font.GothamBold; _skyBtn.TextSize=13
Instance.new("UICorner",_skyBtn).CornerRadius=UDim.new(0,4)
local _skyPrev=Instance.new("TextButton")
_skyPrev.Parent=_skyFrame; _skyPrev.Size=UDim2.new(0,40,0,30)
_skyPrev.Position=UDim2.new(0,190,0,5); _skyPrev.BackgroundColor3=Color3.fromRGB(80,80,80)
_skyPrev.Text="◀"; _skyPrev.TextColor3=Color3.new(1,1,1); _skyPrev.Font=Enum.Font.GothamBold; _skyPrev.TextSize=14
Instance.new("UICorner",_skyPrev).CornerRadius=UDim.new(0,4)
local _skyNext=Instance.new("TextButton")
_skyNext.Parent=_skyFrame; _skyNext.Size=UDim2.new(0,40,0,30)
_skyNext.Position=UDim2.new(0,235,0,5); _skyNext.BackgroundColor3=Color3.fromRGB(80,80,80)
_skyNext.Text="▶"; _skyNext.TextColor3=Color3.new(1,1,1); _skyNext.Font=Enum.Font.GothamBold; _skyNext.TextSize=14
Instance.new("UICorner",_skyNext).CornerRadius=UDim.new(0,4)
local _skyApply=Instance.new("TextButton")
_skyApply.Parent=_skyFrame; _skyApply.Size=UDim2.new(0,80,0,30)
_skyApply.Position=UDim2.new(0,282,0,5); _skyApply.BackgroundColor3=Color3.fromRGB(30,144,255)
_skyApply.Text="Aplicar"; _skyApply.TextColor3=Color3.new(1,1,1)
_skyApply.Font=Enum.Font.GothamBold; _skyApply.TextSize=13
Instance.new("UICorner",_skyApply).CornerRadius=UDim.new(0,4)
local function _applySkyTime()
    local opt = _skyOptions[_skyIdx]
    if opt == "☀️ Dia" then
        Lighting.ClockTime  = 14
        Lighting.Brightness = 2
    elseif opt == "🌙 Noite" then
        Lighting.ClockTime       = 0
        Lighting.Brightness      = 1.5
        Lighting.Ambient         = Color3.fromRGB(150,150,150)
        Lighting.OutdoorAmbient  = Color3.fromRGB(180,180,180)
    elseif opt == "🌅 Anoitecer" then
        Lighting.ClockTime  = 17
        Lighting.Brightness = 1
    end
end
_skyPrev.MouseButton1Click:Connect(function()
    _skyIdx=_skyIdx-1; if _skyIdx<1 then _skyIdx=#_skyOptions end; _skyBtn.Text=_skyOptions[_skyIdx]
end)
_skyNext.MouseButton1Click:Connect(function()
    _skyIdx=_skyIdx+1; if _skyIdx>#_skyOptions then _skyIdx=1 end; _skyBtn.Text=_skyOptions[_skyIdx]
end)
_skyApply.MouseButton1Click:Connect(_applySkyTime)
_cfgY = _cfgY + 50

end -- CONFIG FRAME

-- ==============================================
-- INFO FRAME
-- ==============================================
do
local infoScroll = CreateScrollFrame(LMG2L["InfoFrame_2e"])
local infoText = Instance.new("TextLabel")
infoText.Parent                 = infoScroll
infoText.Size                   = UDim2.new(0, 370, 0, 0)
infoText.AutomaticSize          = Enum.AutomaticSize.Y
infoText.Position               = UDim2.new(0, 5, 0, 5)
infoText.BackgroundColor3       = Color3.fromRGB(40, 40, 40)
infoText.BackgroundTransparency = 0.3
infoText.TextColor3             = Color3.new(1, 1, 1)
infoText.Font                   = Enum.Font.Gotham
infoText.TextSize               = 12
infoText.TextWrapped            = true
infoText.TextXAlignment         = Enum.TextXAlignment.Left
infoText.TextYAlignment         = Enum.TextYAlignment.Top
infoText.RichText               = false
Instance.new("UICorner", infoText).CornerRadius = UDim.new(0, 5)
Instance.new("UIPadding", infoText).PaddingLeft  = UDim.new(0, 8)

local _infoLines = {
    "══════════════════════════",
    "  FFH4X — PAINEL COMPLETO",
    "══════════════════════════",
    "",
    "🎯 AIMBOT",
    "  · FOV ajustável (10–200)",
    "  · Intensidade: Leve / Média / Grude Total",
    "  · Team Check / Kill Check / Wall Check",
    "  · Alvo: Cabeça / Torso / Aleatório",
    "  · FOV RGB (ciclo de cores)",
    "  · Função FOV customizado",
    "",
    "📦 HITBOX EXPANDER",
    "  · Tamanho ajustável (1–75)",
    "  · Transparência ajustável",
    "  · 8 cores selecionáveis",
    "  · Materiais: Neon / Plastic / Metal / Glass",
    "  · Partes: Todas / Cabeça / Torso / Braços / Pernas / HRP",
    "  · Hitbox RGB",
    "  · Restaura player ao desativar",
    "",
    "👁️ ESP",
    "  · Box, Highlight, Names",
    "  · Health, Tracers, Distance",
    "  · Skeleton ESP + RGB + cor selecionável",
    "  · Team Colors",
    "  · Distância ajustável (200–2000)",
    "  · Cores: 8 opções para inimigos e time",
    "  · ESP RGB",
    "",
    "🌈 RGB GLOBAL",
    "  · ESP RGB",
    "  · FOV Aimbot RGB",
    "  · Hitbox RGB",
    "  · Todos compartilham o mesmo ciclo de cor",
    "",
    "⚙️ UTILIDADES (Aba Config)",
    "  · Fake Lag",
    "  · Anti-AFK",
    "  · BunnyHop",
    "  · Infinite Jump",
    "  · Speed Hack (1x–10x)",
    "  · NoClip",
    "  · ✈️ Fly Hack (tecla F, speed ajustável)",
    "  · 🔫 TriggerBot (delay ajustável)",
    "  · ⚡ Teleporte Atrás do Inimigo (offset ajustável)",
    "  · SpinBot + velocidade ajustável",
    "  · Third Person",
    "  · Camera FOV customizado",
    "  · Hitbox em Aliados ON/OFF",
    "",
    "🌙 EFEITOS VISUAIS",
    "  · Night Vision",
    "  · Fullbright",
    "  · Watermark (HUD)",
    "",
    "🔊 HIT SOUND",
    "  · ON/OFF",
    "  · 6 sons: Bell, Bameware, Skeet,",
    "    Cod Hitmarker, Neverlose, Minecraft",
    "  · Volume ajustável",
    "",
    "🌤️ SKY TIME",
    "  · ☀️ Dia / 🌙 Noite / 🌅 Anoitecer",
    "",
    "🎨 CORES DA GUI",
    "  · 8 cores pré-definidas",
    "  · Reset para cor padrão (rosa)",
    "",
    "══════════════════════════",
}
infoText.Text = table.concat(_infoLines, "\n")
end -- INFO FRAME

-- ==============================================
-- NAVEGAÇÃO
-- ==============================================

local function HideAllFrames()
    LMG2L["AimFrame_16"].Visible    = false
    LMG2L["VisualFrame_23"].Visible = false
    LMG2L["ConfigFrame_47"].Visible = false
    LMG2L["InfoFrame_2e"].Visible   = false
end

LMG2L["OPEN/CLOSE_2"].MouseButton1Click:Connect(function()
    LMG2L["MainFrame_6"].Visible = not LMG2L["MainFrame_6"].Visible
end)
LMG2L["AimButton_50"].MouseButton1Click:Connect(function()
    HideAllFrames(); LMG2L["AimFrame_16"].Visible = true
end)
LMG2L["VisualButton_12"].MouseButton1Click:Connect(function()
    HideAllFrames(); LMG2L["VisualFrame_23"].Visible = true
end)
LMG2L["ConfigButton_b"].MouseButton1Click:Connect(function()
    HideAllFrames(); LMG2L["ConfigFrame_47"].Visible = true
end)
LMG2L["InfoButton_7"].MouseButton1Click:Connect(function()
    HideAllFrames(); LMG2L["InfoFrame_2e"].Visible = true
end)

HideAllFrames()
LMG2L["AimFrame_16"].Visible  = true
LMG2L["MainFrame_6"].Visible  = true

-- ==============================================
-- SISTEMA DE ARRASTAR
-- ==============================================

local dragging  = false
local dragStart = nil
local startPos  = nil

local function startDrag(input)
    dragging  = true
    dragStart = input.Position
    startPos  = LMG2L["MainFrame_6"].AbsolutePosition
end
local function updateDrag(input)
    if not dragging then return end
    local delta  = input.Position - dragStart
    local newPos = UDim2.new(0,
        math.clamp(startPos.X + delta.X, 0, Camera.ViewportSize.X - LMG2L["MainFrame_6"].AbsoluteSize.X),
        0,
        math.clamp(startPos.Y + delta.Y, 0, Camera.ViewportSize.Y - LMG2L["MainFrame_6"].AbsoluteSize.Y))
    LMG2L["MainFrame_6"].Position = newPos
end
local function stopDrag()
    dragging = false; dragStart = nil; startPos = nil
end

LMG2L["Decoração_f"].Active    = true
LMG2L["Decoração_f"].Selectable= false
LMG2L["Decoração_f"].InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then startDrag(input) end
end)
LMG2L["Decoração_f"].InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then updateDrag(input) end
end)
LMG2L["Decoração_f"].InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then stopDrag() end
end)

LMG2L["MainFrame_6"].Active    = true
LMG2L["MainFrame_6"].Selectable= false
LMG2L["MainFrame_6"].InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then startDrag(input) end
end)
LMG2L["MainFrame_6"].InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then updateDrag(input) end
end)
LMG2L["MainFrame_6"].InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then stopDrag() end
end)

-- Botão OPEN/CLOSE arrastável
LMG2L["OPEN/CLOSE_2"].Active    = true
LMG2L["OPEN/CLOSE_2"].Selectable= false
local draggingBtn  = false
local dragBtnStart = nil
local startBtnPos  = nil
local function startDragBtn(input)
    draggingBtn  = true
    dragBtnStart = input.Position
    startBtnPos  = LMG2L["OPEN/CLOSE_2"].AbsolutePosition
end
local function updateDragBtn(input)
    if not draggingBtn then return end
    local delta  = input.Position - dragBtnStart
    LMG2L["OPEN/CLOSE_2"].Position = UDim2.new(0,
        math.clamp(startBtnPos.X+delta.X, 0, Camera.ViewportSize.X-LMG2L["OPEN/CLOSE_2"].AbsoluteSize.X),
        0,
        math.clamp(startBtnPos.Y+delta.Y, 0, Camera.ViewportSize.Y-LMG2L["OPEN/CLOSE_2"].AbsoluteSize.Y))
end
local function stopDragBtn()
    draggingBtn = false; dragBtnStart = nil; startBtnPos = nil
end
LMG2L["OPEN/CLOSE_2"].InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then startDragBtn(input) end
end)
LMG2L["OPEN/CLOSE_2"].InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then updateDragBtn(input) end
end)
LMG2L["OPEN/CLOSE_2"].InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then stopDragBtn() end
end)

-- ==============================================
-- SISTEMA DE MINIMIZAR/MAXIMIZAR
-- ==============================================

local isMinimized    = false
local normalSize     = UDim2.new(0, 486, 0, 340)
local normalPosition = LMG2L["MainFrame_6"].Position

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Parent          = LMG2L["ScreenGui_1"]
minimizeBtn.Size            = UDim2.new(0, 30, 0, 25)
minimizeBtn.BackgroundColor3= Color3.fromRGB(50, 50, 50)
minimizeBtn.Text            = "-"
minimizeBtn.TextColor3      = Color3.new(1, 1, 1)
minimizeBtn.Font            = Enum.Font.GothamBold
minimizeBtn.TextSize        = 20
minimizeBtn.ZIndex          = 100
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 5)

local maximizeBtn = Instance.new("TextButton")
maximizeBtn.Parent          = LMG2L["ScreenGui_1"]
maximizeBtn.Size            = UDim2.new(0, 30, 0, 25)
maximizeBtn.BackgroundColor3= Color3.fromRGB(50, 50, 50)
maximizeBtn.Text            = "+"
maximizeBtn.TextColor3      = Color3.new(1, 1, 1)
maximizeBtn.Font            = Enum.Font.GothamBold
maximizeBtn.TextSize        = 20
maximizeBtn.ZIndex          = 100
maximizeBtn.Visible         = false
Instance.new("UICorner", maximizeBtn).CornerRadius = UDim.new(0, 5)

local function updateButtonPositions()
    local mainPos = LMG2L["MainFrame_6"].AbsolutePosition
    local btnX    = mainPos.X + 486 - 40
    local btnY    = mainPos.Y - 30
    minimizeBtn.Position = UDim2.new(0, btnX, 0, btnY)
    maximizeBtn.Position = UDim2.new(0, btnX, 0, btnY)
end

task.spawn(function() task.wait(0.1); updateButtonPositions() end)

RunService.RenderStepped:Connect(function()
    if LMG2L["MainFrame_6"] and LMG2L["MainFrame_6"].Visible then
        updateButtonPositions()
    end
end)

local lastActiveFrame = "Aim"
local sideButtons     = {
    LMG2L["AimButton_50"],
    LMG2L["VisualButton_12"],
    LMG2L["ConfigButton_b"],
    LMG2L["InfoButton_7"],
}

local function getActiveFrame()
    if LMG2L["AimFrame_16"].Visible    then return "Aim"    end
    if LMG2L["VisualFrame_23"].Visible then return "Visual" end
    if LMG2L["ConfigFrame_47"].Visible then return "Config" end
    if LMG2L["InfoFrame_2e"].Visible   then return "Info"   end
    return "Aim"
end
local function setActiveFrame(frame)
    LMG2L["AimFrame_16"].Visible    = (frame == "Aim")
    LMG2L["VisualFrame_23"].Visible = (frame == "Visual")
    LMG2L["ConfigFrame_47"].Visible = (frame == "Config")
    LMG2L["InfoFrame_2e"].Visible   = (frame == "Info")
end

local function Minimizar()
    if isMinimized then return end
    isMinimized      = true
    lastActiveFrame  = getActiveFrame()
    normalPosition   = LMG2L["MainFrame_6"].Position
    for _, btn in ipairs(sideButtons) do if btn then btn.Visible = false end end
    LMG2L["MainFrame_6"].Size = UDim2.new(0, 486, 0, 28)
    LMG2L["AimFrame_16"].Visible    = false
    LMG2L["VisualFrame_23"].Visible = false
    LMG2L["ConfigFrame_47"].Visible = false
    LMG2L["InfoFrame_2e"].Visible   = false
    minimizeBtn.Visible = false
    maximizeBtn.Visible = true
end

local function Maximizar()
    if not isMinimized then return end
    isMinimized = false
    LMG2L["MainFrame_6"].Size = normalSize
    for _, btn in ipairs(sideButtons) do if btn then btn.Visible = true end end
    setActiveFrame(lastActiveFrame)
    LMG2L["MainFrame_6"].Position = normalPosition
    minimizeBtn.Visible = true
    maximizeBtn.Visible = false
end

minimizeBtn.MouseButton1Click:Connect(Minimizar)
maximizeBtn.MouseButton1Click:Connect(Maximizar)
minimizeBtn.ZIndex = 100
maximizeBtn.ZIndex = 100

-- ==============================================
-- PRINT DE CARREGAMENTO
-- ==============================================

print("✅ FFH4X CARREGADO!")
print("🇧🇷 SEJA BEM-VINDO!")
print("🎯 Aimbot: OFF | 👁️ ESP: OFF")
print("🔊 HitSound | 🦴 Skeleton ESP | 🌀 SpinBot | 👁 ThirdPerson")
print("⚒️ FFH4X V1.6 CARREGADO!")

return LMG2L["ScreenGui_1"]

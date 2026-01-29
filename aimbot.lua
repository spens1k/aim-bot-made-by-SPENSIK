-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- SETTINGS
local aimEnabled = false
local teamCheck = false
local permanentAim = false
local aimBodyPart = "Head"
local radius = 50
local maxDist = 1000
local excludedTeams = {}
local customBindEnabled = false
local currentBind = Enum.UserInputType.MouseButton2
local bindingKey = false
local holdingBind = false

-- AIM CIRCLE
local circle = Drawing.new("Circle")
circle.Visible = false
circle.Radius = radius
circle.Thickness = 1
circle.Filled = false
circle.Color = Color3.fromRGB(255,255,255)
circle.Transparency = 1

-- UTILS
local function isAlive(char)
 local hum = char:FindFirstChildOfClass("Humanoid")
 return hum and hum.Health > 0
end

local function getCenter()
 return camera.ViewportSize / 2
end

local function insideCircle(screenPos)
 return (getCenter() - Vector2.new(screenPos.X, screenPos.Y)).Magnitude <= radius
end

local function isVisible(part)
 local origin = camera.CFrame.Position
 local direction = part.Position - origin
 local params = RaycastParams.new()
 params.FilterType = Enum.RaycastFilterType.Blacklist
 params.FilterDescendantsInstances = { player.Character }
 local result = Workspace:Raycast(origin, direction, params)
 return result and result.Instance and result.Instance:IsDescendantOf(part.Parent)
end

local function isEnemy(plr)
 if not teamCheck then return true end
 if not plr.Team then return true end
 if excludedTeams[plr.Team] then return false end
 return true
end

local function getAimPart(char)
 if aimBodyPart == "Head" then
  return char:FindFirstChild("Head")
 else
  return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
 end
end

local function getNearestTarget()
 local nearest
 local minDist = math.huge
 for _, plr in ipairs(Players:GetPlayers()) do
  if plr ~= player and plr.Character then
   local char = plr.Character
   local part = getAimPart(char)
   if part and isAlive(char) and isEnemy(plr) then
    local dist = (part.Position - camera.CFrame.Position).Magnitude
    if dist <= maxDist then
     local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
     if onScreen and insideCircle(screenPos) and isVisible(part) then
      if dist < minDist then
       minDist = dist
       nearest = part
      end
     end
    end
   end
  end
 end
 return nearest
end

local function snapAim(part)
 camera.CFrame = CFrame.new(camera.CFrame.Position, part.Position)
end

-- GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 260, 0, 300)
Frame.Position = UDim2.new(0.5, -130, 0.4, -175)
Frame.BackgroundColor3 = Color3.fromRGB(255, 182, 193)
Frame.BorderSizePixel = 6
Frame.BorderColor3 = Color3.fromRGB(255, 192, 203)
Frame.Active = true
Frame.Draggable = true
Frame.Visible = false

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 15)

local UIList = Instance.new("UIListLayout", Frame)
UIList.Padding = UDim.new(0, 4)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local UIPadding = Instance.new("UIPadding", Frame)
UIPadding.PaddingTop = UDim.new(0, 20)
UIPadding.PaddingBottom = UDim.new(0, 20)
UIPadding.PaddingLeft = UDim.new(0, 10)
UIPadding.PaddingRight = UDim.new(0, 10)

-- BUTTONS
local function newButton(text)
 local btn = Instance.new("TextButton")
 btn.Size = UDim2.new(0, 220, 0, 28)
 btn.BackgroundColor3 = Color3.fromRGB(245, 230, 210)
 btn.TextColor3 = Color3.fromRGB(30,30,30)
 btn.Text = text
 btn.Font = Enum.Font.Gotham
 btn.TextSize = 13
 btn.AutoButtonColor = true
 btn.Parent = Frame

 local corner = Instance.new("UICorner", btn)
 corner.CornerRadius = UDim.new(0, 8)

btn.MouseEnter:Connect(function()
  btn:TweenSize(UDim2.new(0, 224, 0, 30),"Out","Quad",0.1,true)
 end)
 btn.MouseLeave:Connect(function()
  btn:TweenSize(UDim2.new(0, 220, 0, 28),"Out","Quad",0.1,true)
 end)
 btn.MouseButton1Click:Connect(function()
  btn:TweenSize(UDim2.new(0, 216, 0, 26),"Out","Quad",0.05,true)
  task.wait(0.05)
  btn:TweenSize(UDim2.new(0, 220, 0, 28),"Out","Quad",0.05,true)
 end)

 return btn
end

local function newToggle(text, default, callback)
 local state = default
 local btn = newButton(text .. ": " .. (state and "ON" or "OFF"))
 btn.MouseButton1Click:Connect(function()
  state = not state
  btn.Text = text .. ": " .. (state and "ON" or "OFF")
  callback(state)
 end)
 return btn
end

-- MAIN SETTINGS
newToggle("Enable Aim", aimEnabled, function(v) aimEnabled = v end)
local teamCheckBtn = newToggle("Team Check", teamCheck, function(v) teamCheck = v end)
newToggle("Permanent Aim", permanentAim, function(v) 
 permanentAim = v 
 circle.Visible = v
end)

-- AIM PART SWITCH
do
 local btn = newButton("Aim Part: Head")
 btn.MouseButton1Click:Connect(function()
  aimBodyPart = (aimBodyPart == "Head") and "Torso" or "Head"
  btn.Text = "Aim Part: " .. aimBodyPart
 end)
end

-- CUSTOM BIND
newToggle("Enable Custom Bind", customBindEnabled, function(v)
 customBindEnabled = v
 circle.Visible = false
end)

local bindBtn = newButton("Set Custom Bind: "..(currentBind.Name or "MouseButton2"))
bindBtn.MouseButton1Click:Connect(function()
 bindBtn.Text = "Press a key..."
 bindingKey = true
end)

UIS.InputBegan:Connect(function(input)
 if bindingKey then
  if input.UserInputType == Enum.UserInputType.Keyboard then
   currentBind = input.KeyCode
  else
   currentBind = input.UserInputType
  end
  bindBtn.Text = "Set Custom Bind: "..(currentBind.Name or "MouseButton2")
  bindingKey = false
 end
end)

UIS.InputBegan:Connect(function(input)
 if customBindEnabled then
  if (typeof(currentBind) == "EnumItem" and input.UserInputType == currentBind) or (input.KeyCode == currentBind) then
   holdingBind = true
  end
 end
end)
UIS.InputEnded:Connect(function(input)
 if (typeof(currentBind) == "EnumItem" and input.UserInputType == currentBind) or (input.KeyCode == currentBind) then
  holdingBind = false
  circle.Visible = false
 end
end)

-- AIM LOOP
RunService.RenderStepped:Connect(function()
 local useAim = aimEnabled and (permanentAim or (customBindEnabled and holdingBind))
 if useAim then
  circle.Position = getCenter()
  circle.Visible = true
  local part = getNearestTarget()
  if part then snapAim(part) end
 else
  circle.Visible = false
 end
end)

-- MENU TOGGLE
UIS.InputBegan:Connect(function(input)
 if input.KeyCode == Enum.KeyCode.RightShift then
  Frame.Visible = not Frame.Visible
 end
end)

-- TEAMS
local TeamsContainer = Instance.new("Frame", Frame)
TeamsContainer.Size = UDim2.new(0, 220, 0, 40)
TeamsContainer.BackgroundTransparency = 1
TeamsContainer.LayoutOrder = 2

local Grid = Instance.new("UIGridLayout", TeamsContainer)
Grid.CellSize = UDim2.new(0, 32, 0, 32)
Grid.CellPadding = UDim2.new(0, 4, 0, 4)

local teamButtons = {} 

local function newTeamButton(team)
 local btn = Instance.new("TextButton")
 btn.Size = UDim2.new(0, 32, 0, 32)
 btn.BackgroundColor3 = team.TeamColor.Color
 btn.BorderSizePixel = 0
 btn.Text = ""
 btn.Parent = TeamsContainer
 local corner = Instance.new("UICorner", btn)
 corner.CornerRadius = UDim.new(0, 5)

 local indicator = Instance.new("TextLabel", btn)
 indicator.Size = UDim2.new(1, 0, 1, 0)
 indicator.BackgroundTransparency = 1
 indicator.Text = ""
 indicator.TextColor3 = Color3.fromRGB(150, 150, 150)
 indicator.TextScaled = true

 local function updateIndicator()
  indicator.Text = excludedTeams[team] and "✓" or ""
 end
 updateIndicator()

 btn.MouseButton1Click:Connect(function()
  excludedTeams[team] = not excludedTeams[team]
  updateIndicator()
 end)

 teamButtons[team] = updateIndicator 
end

local function rebuildTeams()
 for _, v in ipairs(TeamsContainer:GetChildren()) do
  if v:IsA("TextButton") then v:Destroy() end
 end
 teamButtons = {}
 for _, team in ipairs(Teams:GetTeams()) do
  newTeamButton(team)
 end

 for team, update in pairs(teamButtons) do
  if excludedTeams[team] then
   update()
  end
 end
end

rebuildTeams()
Teams.ChildAdded:Connect(rebuildTeams)
Teams.ChildRemoved:Connect(rebuildTeams)

if player.Team then
 excludedTeams[player.Team] = true
 if teamButtons[player.Team] then
  teamButtons[player.Team]()
 end
end
player:GetPropertyChangedSignal("Team"):Connect(function()
 if player.Team then
  excludedTeams[player.Team] = true
  if teamButtons[player.Team] then
   teamButtons[player.Team]()
  end
 end
end)

-- TIGER BOT
local tigerBotEnabled = false
local tigerInterval = 0.1 
local tigerDelay = 0.1 
local lastShot = 0

-- Кнопка для включения/выключения
local tigerBtn = newToggle("Tiger Bot", tigerBotEnabled, function(v)
    tigerBotEnabled = v
end)

RunService.RenderStepped:Connect(function()
    if not tigerBotEnabled then return end

    local aimActive = aimEnabled and (permanentAim or (customBindEnabled and holdingBind))
    if not aimActive then return end

    local now = tick()
    if now - lastShot < tigerInterval then return end

    local target = getNearestTarget()
    if target then
        
        task.delay(tigerDelay, function()
            if tigerBotEnabled and target and aimActive then
                local mouse = player:GetMouse()
                mouse1click() 
            end
        end)

        lastShot = now
    end
end)

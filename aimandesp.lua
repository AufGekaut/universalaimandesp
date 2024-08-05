local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- Settings
local teamCheck = false
local fov = 150
local smoothing = 1

-- Function to create a new ESP line
local function createESPLine()
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Transparency = 1
    return line
end

-- Table to store ESP lines
local ESPLines = {}

-- Function to update ESP lines
local function updateESPLines()
    for _, line in pairs(ESPLines) do
        line.Visible = false
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local teamColor = player.TeamColor.Color
            local character = player.Character
            local rootPart = character:FindFirstChild("HumanoidRootPart")

            if rootPart then
                local rootPosition = rootPart.Position
                local screenPosition, onScreen = Camera:WorldToViewportPoint(rootPosition)

                if onScreen then
                    local line = ESPLines[player] or createESPLine()
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(screenPosition.X, screenPosition.Y)
                    line.Color = teamColor
                    line.Visible = true
                    ESPLines[player] = line
                end
            end
        end
    end
end

-- Function to get the closest player to the crosshair within FOV
local function getClosest(cframe)
    local ray = Ray.new(cframe.Position, cframe.LookVector).Unit
    local target = nil
    local mag = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") and player ~= LocalPlayer and (player.Team ~= LocalPlayer.Team or not teamCheck) then
            local magBuf = (player.Character.Head.Position - ray:ClosestPoint(player.Character.Head.Position)).Magnitude

            if magBuf < mag then
                mag = magBuf
                target = player
            end
        end
    end

    return target
end

-- FOV ring setup
local function drawFOVRing()
    local segments = 60
    local angle = math.pi * 2 / segments
    local lines = {}

    for i = 1, segments do
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Transparency = 1
        line.Color = Color3.fromRGB(255, 128, 128)
        table.insert(lines, line)
    end

    local function updateFOVRing()
        local center = Camera.ViewportSize / 2
        for i = 1, segments do
            local theta1 = angle * (i - 1)
            local theta2 = angle * i
            local p1 = center + Vector2.new(math.cos(theta1), math.sin(theta1)) * fov
            local p2 = center + Vector2.new(math.cos(theta2), math.sin(theta2)) * fov
            local line = lines[i]
            line.From = p1
            line.To = p2
            line.Visible = true
        end
    end

    return updateFOVRing, function()
        for _, line in pairs(lines) do
            line:Remove()
        end
    end
end

local updateFOVRing, removeFOVRing = drawFOVRing()

-- Update ESP lines and aim assist
local loop = RunService.RenderStepped:Connect(function()
    updateESPLines()
    updateFOVRing()

    local pressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local localPlay = LocalPlayer.Character
    local zz = Camera.ViewportSize / 2

    if pressed then
        local curTar = getClosest(Camera.CFrame)
        if curTar then
            local ssHeadPoint = Camera:WorldToScreenPoint(curTar.Character.Head.Position)
            ssHeadPoint = Vector2.new(ssHeadPoint.X, ssHeadPoint.Y)
            if (ssHeadPoint - zz).Magnitude < fov then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, curTar.Character.Head.Position), smoothing)
            end
        end
    end

    -- Cleanup logic
    if UserInputService:IsKeyDown(Enum.KeyCode.Delete) then
        loop:Disconnect()
        removeFOVRing()
        for _, line in pairs(ESPLines) do
            line:Remove()
        end
        ESPLines = {}
    end
end)

-- Clean up ESP lines when the player leaves
Players.PlayerRemoving:Connect(function(player)
    if ESPLines[player] then
        ESPLines[player]:Remove()
        ESPLines[player] = nil
    end
end)

-- Create the notification
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationGui"
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 100)
frame.Position = UDim2.new(0.5, -150, 0.5, -50)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.Parent = screenGui

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 0.7, 0)
textLabel.Position = UDim2.new(0, 0, 0, 0)
textLabel.Text = "Thanks for using Solanarium"
textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
textLabel.BackgroundTransparency = 1
textLabel.Font = Enum.Font.SourceSans
textLabel.TextSize = 24
textLabel.Parent = frame

local textButton = Instance.new("TextButton")
textButton.Size = UDim2.new(0.4, 0, 0.3, 0)
textButton.Position = UDim2.new(0.3, 0, 0.7, 0)
textButton.Text = "Thanks!"
textButton.TextColor3 = Color3.fromRGB(255, 255, 255)
textButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
textButton.Font = Enum.Font.SourceSans
textButton.TextSize = 24
textButton.Parent = frame

-- Function to remove the notification
local function removeNotification()
    screenGui:Destroy()
end

-- Connect the button to the function
textButton.MouseButton1Click:Connect(removeNotification)

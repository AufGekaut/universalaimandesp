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

-- Table to store ESP names
local ESPNames = {}

-- Function to update ESP lines and names
local function updateESP()
    for _, line in pairs(ESPLines) do
        line.Visible = false
    end
    for _, name in pairs(ESPNames) do
        name.Visible = false
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

                    local nameTag = ESPNames[player] or Drawing.new("Text")
                    nameTag.Text = player.Name
                    nameTag.Position = Vector2.new(screenPosition.X, screenPosition.Y - 15)
                    nameTag.Color = teamColor
                    nameTag.Size = 16
                    nameTag.Visible = true
                    ESPNames[player] = nameTag
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
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") and player ~= LocalPlayer and (player.Team ~= LocalPlayer.Team or not teamCheck) then
            local magBuf = (player.Character.HumanoidRootPart.Position - ray:ClosestPoint(player.Character.HumanoidRootPart.Position)).Magnitude

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
    updateESP()
    updateFOVRing()

    local pressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local localPlay = LocalPlayer.Character
    local zz = Camera.ViewportSize / 2

    if pressed then
        local curTar = getClosest(Camera.CFrame)
        if curTar then
            local ssTorsoPoint = Camera:WorldToScreenPoint(curTar.Character.HumanoidRootPart.Position)
            ssTorsoPoint = Vector2.new(ssTorsoPoint.X, ssTorsoPoint.Y)
            if (ssTorsoPoint - zz).Magnitude < fov then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, curTar.Character.HumanoidRootPart.Position), smoothing)
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
        for _, name in pairs(ESPNames) do
            name:Remove()
        end
        ESPLines = {}
        ESPNames = {}
    end
end)

-- Clean up ESP lines and names when the player leaves
Players.PlayerRemoving:Connect(function(player)
    if ESPLines[player] then
        ESPLines[player]:Remove()
        ESPLines[player] = nil
    end
    if ESPNames[player] then
        ESPNames[player]:Remove()
        ESPNames[player] = nil
    end
end)

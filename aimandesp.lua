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
local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 1.5
FOVring.Radius = fov
FOVring.Transparency = 1
FOVring.Color = Color3.fromRGB(255, 128, 128)
FOVring.Position = Camera.ViewportSize / 2

-- Update ESP lines and aim assist
local loop = RunService.RenderStepped:Connect(function()
    updateESPLines()

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
        FOVring:Remove()
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

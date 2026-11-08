local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local remoteFolder = ReplicatedStorage:WaitForChild("DropkickRemotes")
local dropkickRemote = remoteFolder:WaitForChild("RequestDropkick")

local MAX_TARGET_DISTANCE = 18
local CLIENT_COOLDOWN = 2.5
local FLY_SPEED = 55

local selectedTarget
local lastDropkick = 0
local flying = false
local flyConnection
local bodyVelocity
local bodyGyro

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DropkickGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "ControlPanel"
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 22, 1, -22)
panel.Size = UDim2.fromOffset(250, 174)
panel.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
panel.BorderSizePixel = 0
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(77, 91, 112)
stroke.Thickness = 1
stroke.Parent = panel

local function createLabel(name, text, position, size, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = panel
	return label
end

createLabel("Title", "DROP KICK", UDim2.fromOffset(16, 12), UDim2.fromOffset(218, 24), Color3.fromRGB(255, 255, 255)).TextSize = 18
local statusLabel = createLabel("Status", "Click a nearby player to select", UDim2.fromOffset(16, 41), UDim2.fromOffset(218, 22), Color3.fromRGB(174, 187, 205))

local kickButton = Instance.new("TextButton")
kickButton.Name = "DropkickButton"
kickButton.Text = "DROP KICK"
kickButton.Position = UDim2.fromOffset(16, 72)
kickButton.Size = UDim2.fromOffset(105, 42)
kickButton.BackgroundColor3 = Color3.fromRGB(214, 74, 65)
kickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
kickButton.Font = Enum.Font.GothamBold
kickButton.TextSize = 13
kickButton.AutoButtonColor = true
kickButton.Parent = panel

local kickCorner = Instance.new("UICorner")
kickCorner.CornerRadius = UDim.new(0, 6)
kickCorner.Parent = kickButton

local flyButton = kickButton:Clone()
flyButton.Name = "FlyButton"
flyButton.Text = "FLY: OFF"
flyButton.Position = UDim2.fromOffset(129, 72)
flyButton.BackgroundColor3 = Color3.fromRGB(62, 104, 168)
flyButton.Parent = panel

local hintLabel = createLabel("Hint", "Click target  |  F toggles flight", UDim2.fromOffset(16, 128), UDim2.fromOffset(218, 26), Color3.fromRGB(132, 147, 169))
hintLabel.TextSize = 12

local function getCharacterRoot(character)
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function getTargetFromScreen()
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { player.Character }

	local result = workspace:Raycast(ray.Origin, ray.Direction * 250, raycastParams)
	if not result then
		return nil
	end

	local character = result.Instance:FindFirstAncestorOfClass("Model")
	local targetPlayer = character and Players:GetPlayerFromCharacter(character)
	local root = getCharacterRoot(character)
	local ownRoot = getCharacterRoot(player.Character)
	if not targetPlayer or targetPlayer == player or not root or not ownRoot then
		return nil
	end

	if (root.Position - ownRoot.Position).Magnitude > MAX_TARGET_DISTANCE then
		return nil
	end

	return character, targetPlayer
end

local function selectTarget()
	local character, targetPlayer = getTargetFromScreen()
	if not character then
		selectedTarget = nil
		statusLabel.Text = "No nearby player selected"
		statusLabel.TextColor3 = Color3.fromRGB(238, 145, 135)
		return
	end

	selectedTarget = character
	statusLabel.Text = "Target: " .. targetPlayer.DisplayName
	statusLabel.TextColor3 = Color3.fromRGB(127, 222, 164)
end

local function requestDropkick()
	if os.clock() - lastDropkick < CLIENT_COOLDOWN then
		return
	end
	if not selectedTarget or not selectedTarget.Parent then
		statusLabel.Text = "Select a nearby player first"
		statusLabel.TextColor3 = Color3.fromRGB(238, 145, 135)
		return
	end

	lastDropkick = os.clock()
	dropkickRemote:FireServer(selectedTarget)
	statusLabel.Text = "Dropkick launched"
	statusLabel.TextColor3 = Color3.fromRGB(255, 215, 117)
end

local function stopFlying()
	flying = false
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end
	flyButton.Text = "FLY: OFF"
	flyButton.BackgroundColor3 = Color3.fromRGB(62, 104, 168)
end

local function toggleFlying()
	if flying then
		stopFlying()
		return
	end

	local character = player.Character
	local root = getCharacterRoot(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end

	flying = true
	flyButton.Text = "FLY: ON"
	flyButton.BackgroundColor3 = Color3.fromRGB(47, 157, 113)
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
	bodyVelocity.P = 10000
	bodyVelocity.Parent = root
	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
	bodyGyro.P = 10000
	bodyGyro.Parent = root

	flyConnection = RunService.RenderStepped:Connect(function()
		if not flying or not root.Parent or humanoid.Health <= 0 then
			stopFlying()
			return
		end

		local movement = humanoid.MoveDirection
		local vertical = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			vertical += 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			vertical -= 1
		end

		bodyVelocity.Velocity = movement * FLY_SPEED + Vector3.new(0, vertical * FLY_SPEED, 0)
		bodyGyro.CFrame = camera.CFrame
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		selectTarget()
	elseif input.KeyCode == Enum.KeyCode.F then
		toggleFlying()
	elseif input.KeyCode == Enum.KeyCode.E then
		requestDropkick()
	end
end)

kickButton.Activated:Connect(requestDropkick)
flyButton.Activated:Connect(toggleFlying)

player.CharacterAdded:Connect(function()
	stopFlying()
	selectedTarget = nil
	statusLabel.Text = "Click a nearby player to select"
	statusLabel.TextColor3 = Color3.fromRGB(174, 187, 205)
end)

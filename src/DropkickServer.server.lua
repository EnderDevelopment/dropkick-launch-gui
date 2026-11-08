local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_FOLDER_NAME = "DropkickRemotes"
local DROP_KICK_REMOTE_NAME = "RequestDropkick"
local MAX_TARGET_DISTANCE = 18
local DROP_KICK_COOLDOWN = 2.5
local HORIZONTAL_FORCE = 72
local UPWARD_FORCE = 38

local remoteFolder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = REMOTE_FOLDER_NAME
	remoteFolder.Parent = ReplicatedStorage
end

local dropkickRemote = remoteFolder:FindFirstChild(DROP_KICK_REMOTE_NAME)
if not dropkickRemote then
	dropkickRemote = Instance.new("RemoteEvent")
	dropkickRemote.Name = DROP_KICK_REMOTE_NAME
	dropkickRemote.Parent = remoteFolder
end

local cooldowns = {}

local function getRoot(character)
	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil
	end

	return root, humanoid
end

local function hasLineOfSight(sourceCharacter, sourceRoot, targetCharacter, targetRoot)
	local direction = targetRoot.Position - sourceRoot.Position
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { sourceCharacter }
	raycastParams.IgnoreWater = true

	local result = workspace:Raycast(sourceRoot.Position, direction, raycastParams)
	return not result or result.Instance:IsDescendantOf(targetCharacter)
end

local function getPlayerFromCharacter(character)
	if not character or not character:IsA("Model") then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

dropkickRemote.OnServerEvent:Connect(function(player, targetCharacter)
	if typeof(targetCharacter) ~= "Instance" or not targetCharacter:IsA("Model") then
		return
	end

	local now = os.clock()
	if cooldowns[player] and now - cooldowns[player] < DROP_KICK_COOLDOWN then
		return
	end

	local attackerRoot, attackerHumanoid = getRoot(player.Character)
	local targetPlayer = getPlayerFromCharacter(targetCharacter)
	local targetRoot, targetHumanoid = getRoot(targetCharacter)
	if not attackerRoot or not attackerHumanoid or not targetPlayer or targetPlayer == player or not targetRoot or not targetHumanoid then
		return
	end

	local offset = targetRoot.Position - attackerRoot.Position
	local distance = offset.Magnitude
	if distance > MAX_TARGET_DISTANCE or distance < 1 or not hasLineOfSight(player.Character, attackerRoot, targetCharacter, targetRoot) then
		return
	end

	cooldowns[player] = now
	local direction = Vector3.new(offset.X, 0, offset.Z)
	if direction.Magnitude < 0.1 then
		direction = attackerRoot.CFrame.LookVector * Vector3.new(1, 0, 1)
	end
	direction = direction.Unit

	targetHumanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	targetRoot.AssemblyLinearVelocity = direction * HORIZONTAL_FORCE + Vector3.new(0, UPWARD_FORCE, 0)
	attackerRoot.AssemblyLinearVelocity = -direction * 18 + Vector3.new(0, 12, 0)

	task.delay(0.75, function()
		if targetHumanoid.Parent and targetHumanoid.Health > 0 then
			targetHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
end)

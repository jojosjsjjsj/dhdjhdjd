local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local owner = Players.Ziggyriggyy
local char = game.ServerStorage.SP:Clone()
char.Parent = workspace
char:PivotTo(owner.Character.HumanoidRootPart.CFrame + Vector3.yAxis * 1.8)

owner.Character = char

local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart

local animator = hum:FindFirstChildOfClass("Animator")
if not animator then
	animator = Instance.new("Animator")
	animator.Parent = hum
end

-- animation loader
local function loadAnim(id, prio, loop)
	local a = Instance.new("Animation")
	a.AnimationId = "rbxassetid://" .. id
	local t = animator:LoadAnimation(a)
	t.Priority = prio
	t.Looped = loop
	return t
end

-- animations
local idle = loadAnim(82092759138926, Enum.AnimationPriority.Idle, true)
local walk = loadAnim(75214712948755, Enum.AnimationPriority.Movement, true)
local vent = loadAnim(123214245969261, Enum.AnimationPriority.Action, false)

idle:Play(0.25)

local state = "Idle"
local venting = false
local lastVent = 0

local RANGE = 10
local VENT_COOLDOWN = 100
local VENT_DURATION = 4.5

-- raycast params for LOS
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {char}
rayParams.IgnoreWater = true

local function hasLOS(targetRoot)
	local dir = targetRoot.Position - root.Position
	local result = Workspace:Raycast(root.Position, dir, rayParams)
	if not result then return true end
	return result.Instance:IsDescendantOf(targetRoot.Parent)
end

local function setState(new)
	if state == new then return end
	state = new

	if new == "Idle" then
		walk:Stop(0.25)
		idle:Play(0.25)

	elseif new == "Walk" then
		idle:Stop(0.25)
		walk:Play(0.25)

	elseif new == "Vent" then
		idle:Stop(0.2)
		walk:Stop(0.2)
		vent:Play(0.15)
	end
end

local function ventilation_error()
	if venting then return end
	if os.clock() - lastVent < VENT_COOLDOWN then return end

	lastVent = os.clock()
	venting = true

	-- anchor during vent
	root.Anchored = true
	setState("Vent")

	-- sound
	local snd = Instance.new("Sound")
	snd.SoundId = "rbxassetid://79539919270668"
	snd.Volume = 5
	snd.Looped = false
	snd.Parent = root
	snd:Play()

	task.delay(VENT_DURATION, function()
		venting = false
		root.Anchored = false

		if snd then
			snd:Destroy()
		end
	end)
end

-- movement animation (smooth)
RunService.Heartbeat:Connect(function()
	if venting then return end

	if hum.MoveDirection.Magnitude > 0.05 then
		setState("Walk")
	else
		setState("Idle")
	end
end)

-- proximity + LOS + cooldown check
task.spawn(function()
	while true do
		task.wait(0.2)

		if venting then continue end
		if os.clock() - lastVent < VENT_COOLDOWN then continue end

		for _, hum2 in ipairs(workspace:GetDescendants()) do
			if hum2:IsA("Humanoid")
				and hum2 ~= hum
				and hum2.Health > 0 then

				local hrp = hum2.RootPart
				if hrp then
					if (hrp.Position - root.Position).Magnitude <= RANGE
						and hasLOS(hrp) then
						ventilation_error()
						break
					end
				end
			end
		end
	end
end)

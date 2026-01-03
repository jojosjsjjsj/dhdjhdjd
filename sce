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

local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)

-- animation loader
local function loadAnim(id, prio, loop)
	local a = Instance.new("Animation")
	a.AnimationId = "rbxassetid://" .. id
	local t = animator:LoadAnimation(a)
	t.Priority = prio
	t.Looped = loop
	return t
end

-- REPLACED animations
local idle = loadAnim(82092759138926, Enum.AnimationPriority.Idle, true)
local walk = loadAnim(75214712948755, Enum.AnimationPriority.Movement, true)
local vent = loadAnim(123214245969261, Enum.AnimationPriority.Action, false)

idle:Play(0.25)

local state = "Idle"
local venting = false
local lastVent = 0
local VENT_COOLDOWN = 20
local RANGE = 10

-- raycast params (line of sight)
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
	setState("Vent")

	task.delay(4.5, function()
		venting = false
	end)
end

-- movement animation (smooth, no snapping)
RunService.Heartbeat:Connect(function()
	if venting then return end

	if hum.MoveDirection.Magnitude > 0.05 then
		setState("Walk")
	else
		setState("Idle")
	end
end)

-- proximity + LOS + cooldown
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
					local dist = (hrp.Position - root.Position).Magnitude
					if dist <= RANGE and hasLOS(hrp) then
						ventilation_error()
						break
					end
				end
			end
		end
	end
end)

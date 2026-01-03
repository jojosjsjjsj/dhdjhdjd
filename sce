local owner = owner or game.Players.Ziggyriggyy
local char = game.ServerStorage.SP:Clone()
char.Parent = workspace

local playerChar = owner.Character
char:PivotTo(playerChar.HumanoidRootPart.CFrame + Vector3.yAxis * 1.8)

local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart
root.Anchored = false

local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)

local blacklist = {
	"Flying",
	"Ragdoll",
	"Freefall",
	"GettingUp",
	"FallingDown",
	"PlatformStanding"
}
for _, v in pairs(blacklist) do
	hum:SetStateEnabled(Enum.HumanoidStateType[v], false)
end

owner.Character = char

-- movement
local sprinting, phantom = false, false
local ows = 8
local stamina, max_stamina = 100, 100
hum.WalkSpeed = ows

-- event (kept for compatibility)
local re = Instance.new("RemoteEvent", char)
re.Name = "SPEvent"

local can_phantom = true
local venting = false

-- animation loader
local function load(id, prio, loop)
	local a = Instance.new("Animation")
	a.AnimationId = "rbxassetid://" .. id
	local t = animator:LoadAnimation(a)
	t.Priority = prio
	t.Looped = loop
	return t
end

-- animations (REPLACED)
local idleTrack = load(82092759138926, Enum.AnimationPriority.Idle, true)
local moveTrack = load(75214712948755, Enum.AnimationPriority.Movement, true)
local ventTrack = load(123214245969261, Enum.AnimationPriority.Action, false)

idleTrack:Play()

-- ventilation error
local function ventilation_error()
	if venting then return end
	venting = true

	idleTrack:Stop(0)
	moveTrack:Stop(0)
	ventTrack:Play()

	local dt = 0
	local hums = {}

	repeat
		dt += task.wait()
		local params = OverlapParams.new()
		params.FilterDescendantsInstances = {char}
		params.FilterType = Enum.RaycastFilterType.Exclude

		for _, v in pairs(workspace:GetPartBoundsInRadius(root.Position, 25, params)) do
			local vhum = v.Parent:FindFirstChildOfClass("Humanoid")
			if vhum and vhum.Health > 0 and not hums[vhum] then
				hums[vhum] = vhum.WalkSpeed
				vhum.WalkSpeed *= .5
				task.delay(5, function()
					if vhum then vhum.WalkSpeed = hums[vhum] end
				end)
			end
		end
	until dt >= 4.5

	task.wait(20)
	ventTrack:Stop()
	venting = false
end

-- phantom walk
local function phantom_walk()
	if not can_phantom then return end
	can_phantom = false

	phantom = true
	hum.WalkSpeed = 24

	task.wait(6)

	hum.WalkSpeed = 8
	phantom = false

	task.wait(15)
	can_phantom = true
end

-- input
re.OnServerEvent:Connect(function(plr, what, args)
	if plr ~= owner then return end

	if what == "KeyDown" then
		if args == "z" then
			sprinting = true
			hum.WalkSpeed = 26
		elseif args == "e" then
			ventilation_error()
		elseif args == "r" then
			phantom_walk()
		end
	elseif what == "KeyUp" then
		if args == "z" then
			sprinting = false
			hum.WalkSpeed = 8
		end
	end
end)

-- animation switching (FIXED, NO DELAY)
game:GetService("RunService").Heartbeat:Connect(function()
	if venting or phantom then return end

	if hum.MoveDirection.Magnitude > 0 then
		if not moveTrack.IsPlaying then
			idleTrack:Stop(0)
			moveTrack:Play(0)
		end
	else
		if not idleTrack.IsPlaying then
			moveTrack:Stop(0)
			idleTrack:Play(0)
		end
	end
end)

-- stamina
task.spawn(function()
	while true do
		if sprinting then
			task.wait(.22)
			stamina = math.max(stamina - 2, 0)
		else
			task.wait(.3)
			stamina = math.min(stamina + 4, max_stamina)
		end

		if stamina <= 0 then
			sprinting = false
			hum.WalkSpeed = 8
		end
	end
end)

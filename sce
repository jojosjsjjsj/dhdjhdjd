local owner = owner or game.Players.Ziggyriggyy
local char = game.ServerStorage.SP:Clone()
char.Parent = workspace
local playerChar = owner.Character
char:PivotTo(playerChar.HumanoidRootPart.CFrame + Vector3.yAxis * 1.8)

local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart
root.Anchored = false

-- Disable unwanted humanoid states
local blacklist = {
	"Flying", "Ragdoll", "Freefall", "GettingUp", "FallingDown", "PlatformStanding"
}
for _, v in pairs(blacklist) do
	hum:SetStateEnabled(Enum.HumanoidStateType[v], false)
end

owner.Character = char
char.Parent = workspace

-- Movement variables
local sprinting, phantom = false, false
local ows = 8
local stamina, max_stamina = 100, 100
hum.WalkSpeed = ows

-- RemoteEvent setup
local re = Instance.new("RemoteEvent", char)
re.Name = "SpringtrapEvent"

local can_phantom = true
local venting = false

-- Animations
local idleAnim = Instance.new("Animation")
idleAnim.AnimationId = "rbxassetid://82092759138926"
local idleTrack = hum:LoadAnimation(idleAnim)
idleTrack.Looped = true
idleTrack:Play()

local moveAnim = Instance.new("Animation")
moveAnim.AnimationId = "rbxassetid://75214712948755"
local moveTrack = hum:LoadAnimation(moveAnim)
moveTrack.Looped = true

local ventAnim = Instance.new("Animation")
ventAnim.AnimationId = "rbxassetid://123214245969261"

-- Ventilation error
local function ventilation_error()
	if venting then return end
	venting = true

	local ventTrack = hum:LoadAnimation(ventAnim)
	ventTrack.Looped = true
	ventTrack:Play()

	task.spawn(function()
		local dt = 0
		local hums = {}

		repeat
			dt = dt + task.wait()
			local params = OverlapParams.new()
			params.FilterDescendantsInstances = {char, script}
			params.FilterType = Enum.RaycastFilterType.Exclude

			local stuff = workspace:GetPartBoundsInRadius(root.Position, 25, params)
			for _, v in pairs(stuff) do
				local vhum = v.Parent:FindFirstChildOfClass("Humanoid")
				if vhum and vhum.Health > 0 and not hums[vhum] then
					hums[vhum] = vhum.WalkSpeed
					vhum.WalkSpeed = hums[vhum] / 2
					task.delay(5, function()
						vhum.WalkSpeed = hums[vhum]
					end)
				end
			end
		until dt >= 4.5

		task.wait(20)
		ventTrack:Stop()
		venting = false
	end)
end

-- Phantom walk
local function phantom_walk()
	if not can_phantom then return end
	can_phantom = false

	ows = 24
	hum.WalkSpeed = ows
	phantom = true

	task.wait(6) -- phantom duration

	ows = 8
	hum.WalkSpeed = ows
	phantom = false

	task.wait(15) -- cooldown
	can_phantom = true
end

-- Sprint / Phantom input
re.OnServerEvent:Connect(function(plr, what, args)
	if plr ~= owner then return end

	if what == "KeyDown" then
		if args == "z" then
			ows = 26
			sprinting = true
			hum.WalkSpeed = ows
		elseif args == "e" then
			ventilation_error()
		elseif args == "r" then
			phantom_walk()
		end
	elseif what == "KeyUp" then
		if args == "z" and sprinting then
			ows = 8
			sprinting = false
			hum.WalkSpeed = ows
		elseif args == "r" and phantom then
			phantom = false
		end
	end
end)

-- Dynamic animation based on movement magnitude
local isMoving = false
game:GetService("RunService").Heartbeat:Connect(function()
	if venting or phantom then return end
	local speed = root.Velocity.Magnitude
	if speed > 0.1 then
		if not isMoving then
			moveTrack:Play()
			idleTrack:Stop()
			isMoving = true
		end
	else
		if isMoving then
			moveTrack:Stop()
			idleTrack:Play()
			isMoving = false
		end
	end
end)

-- Stamina regen/depletion loop
task.spawn(function()
	while true do
		if sprinting then
			task.wait(.22)
			stamina = math.clamp(stamina - 2, 0, max_stamina)
		else
			task.wait(.3)
			stamina = math.clamp(stamina + 4, 0, max_stamina)
		end

		if stamina <= 0 and sprinting then
			ows = 8
			sprinting = false
			hum.WalkSpeed = ows
		end
	end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local owner = owner or Players:WaitForChild("questionaltmark1111") or Players:WaitForChild("ZiggyRiggyy")

-- Clone SP character from ServerStorage
local spModel = ServerStorage:WaitForChild("SP")
local char = spModel:Clone()
char.Parent = Workspace
char.Name = owner.Name
char:PivotTo(owner.Character.HumanoidRootPart.CFrame + Vector3.yAxis * 1.8)

local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart
root.Anchored = false

-- Disable unwanted humanoid states
for _, state in pairs({"Flying","Ragdoll","Freefall","GettingUp","FallingDown","PlatformStanding"}) do
	hum:SetStateEnabled(Enum.HumanoidStateType[state], false)
end

owner.Character = char

-- Movement variables
local ows = 8
local sprinting, phantom, venting, attacking = false, false, false, false
local can_phantom = true
local stamina, max_stamina = 120, 120
hum.WalkSpeed = ows

-- RemoteEvent
local re = Instance.new("RemoteEvent")
re.Name = "SPEvent"
re.Parent = char

-- Animations
local anims = {}
local function loadAnim(name, id, looped)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://"..id
	local track = hum:LoadAnimation(anim)
	track.Looped = looped
	anims[name] = track
end

-- Replace IDs with your actual animation IDs
loadAnim("Idle", 82092759138926, true)
loadAnim("Walk", 75214712948755, true)
loadAnim("Sprint", 75214712948755, true)
loadAnim("PhantomWalk", 12345678901234, true)
loadAnim("PhantomIdle", 12345678901235, true)
loadAnim("VentilationError", 123214245969261, false)
loadAnim("Attack", 98765432109876, false)

anims.Idle:Play()

-- Utility
local function findhum(part)
	local mdl = part:FindFirstAncestorOfClass("Model")
	if mdl then return mdl:FindFirstChildOfClass("Humanoid") end
end

-- Ventilation
local function ventilation_error()
	if venting then return end
	venting = true
	anims.VentilationError:Play()
	local hums = {}
	task.spawn(function()
		local dt = 0
		re:FireClient(owner, "Highlight")
		repeat
			dt += task.wait()
			local params = OverlapParams.new()
			params.FilterDescendantsInstances = {char, script}
			params.FilterType = Enum.RaycastFilterType.Exclude
			local stuff = Workspace:GetPartBoundsInRadius(root.Position, 25, params)
			for _, v in pairs(stuff) do
				local vhum = findhum(v)
				if vhum and vhum.Health > 0 and not hums[vhum] then
					hums[vhum] = vhum.WalkSpeed
					vhum.WalkSpeed /= 2
					task.delay(5, function() vhum.WalkSpeed = hums[vhum] end)
				end
			end
		until dt >= 4.5
		task.wait(20)
		re:FireClient(owner, "Lowlight")
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
	anims.Idle:Stop()
	anims.PhantomIdle:Play()
	anims.PhantomWalk:Play()
	task.wait(6)
	ows = 8
	hum.WalkSpeed = ows
	phantom = false
	anims.PhantomWalk:Stop()
	anims.PhantomIdle:Stop()
	anims.Idle:Play()
	task.wait(15)
	can_phantom = true
end

-- Sprint
local function startSprint()
	if phantom then return end
	sprinting = true
	ows = 18
	hum.WalkSpeed = ows
	anims.Walk:Stop()
	anims.Sprint:Play()
end
local function stopSprint()
	sprinting = false
	ows = 8
	hum.WalkSpeed = ows
	anims.Sprint:Stop()
	anims.Walk:Play()
end

-- Attack
local function attack()
	if attacking or phantom then return end
	attacking = true
	anims.Attack:Play()
	anims.Attack.Stopped:Wait()
	attacking = false
end

-- Remote input
re.OnServerEvent:Connect(function(plr, what, args)
	if plr ~= owner then return end
	if what == "KeyDown" then
		if args == "z" then startSprint()
		elseif args == "r" then phantom_walk()
		elseif args == "e" then ventilation_error()
		end
	elseif what == "KeyUp" then
		if args == "z" then stopSprint() end
	elseif what == "Button1Down" then
		attack()
	end
end)

-- Movement loop using Humanoid.MoveDirection for instant switching
RunService.Heartbeat:Connect(function()
	if venting or phantom or attacking then return end
	if hum.MoveDirection.Magnitude > 0 then
		if sprinting then
			if not anims.Sprint.IsPlaying then
				anims.Idle:Stop()
				anims.Walk:Stop()
				anims.Sprint:Play()
			end
		else
			if not anims.Walk.IsPlaying then
				anims.Idle:Stop()
				anims.Walk:Play()
			end
		end
	else
		if not anims.Idle.IsPlaying then
			anims.Walk:Stop()
			anims.Sprint:Stop()
			anims.Idle:Play()
		end
	end
end)

-- Stamina loop
task.spawn(function()
	while true do
		if sprinting then
			task.wait(.22)
			stamina = math.clamp(stamina - 2, 0, max_stamina)
		else
			task.wait(.3)
			stamina = math.clamp(stamina + 4, 0, max_stamina)
		end
		if stamina <= 0 and sprinting then stopSprint() end
	end
end)

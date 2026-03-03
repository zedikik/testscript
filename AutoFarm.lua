if game.PlaceId ~= 10449761463 then warn("Join to TSB Public Server!") return else print("this is main game\n") end
print("Skuff Auto Farm: Loading...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local Bracket = loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/Bracket/refs/heads/main/BracketV32.lua"))()

if not _G.autoFarm then
	_G.autoFarm = false
	_G.autoFarmConnection = nil
	_G.autoFarmIsAttacking = nil
	_G.autoFarmKillHealthThreshold = 15
	_G.autoFarmSelfPreservation = false
	_G.autoFarmSelfHealthThreshold = 30
	_G.autoFarmAfkConnection = nil
	_G.autoFarmAFKMode = "Standart"

	_G.autoFarmPreviewToggle = false
	_G.autoFarmPreviewType = "Camera View"
	_G.autoFarmVisualizeTarget = false
	_G.autoFarmVisualizeStyle = "Highlight"
	_G.autoFarmVisualizeColor = {1, 0, 0, 0.5, false}

	_G.autoFarmPriorityToggle = false
	_G.autoFarmPriorityStrict = false
	_G.autoFarmPriorityType = "Health"
	_G.autoFarmIgnoreFriends = false
	_G.autoFarmAntiFling = false
	_G.autoFarmUseTrashcans = false
	_G.autoFarmAntiStreak = false
	_G.autoFarmAntiStreakLimit = 7
	_G.autoFarmPredictToggle = false
	_G.autoFarmPredictionStrength = 0.85

	_G.autoFarmStats = {
		kills = 0,
		startTime = 0,
	}

	_G.autoFarmRecentAttacked = {}
end

local StatusFarmingLabel = nil

local function updateStats()
	if not StatusFarmingLabel then return end
	if (not _G.autoFarmStats or typeof(_G.autoFarmStats) ~= "table") then return end
	local uptime = tick() - _G.autoFarmStats.startTime
	local hours = math.floor(uptime / 3600)
	local minutes = math.floor((uptime % 3600) / 60)
	local seconds = math.floor(uptime % 60)
	local kph = uptime > 60 and math.floor((_G.autoFarmStats.kills / uptime) * 3600) or 0

	StatusFarmingLabel:SetText(string.format("%d Kills | %02d:%02d:%02d | %d Kills/H", _G.autoFarmStats.kills, hours, minutes, seconds, kph))
end

local function predictPosition(target)
	if not _G.autoFarmPredictToggle then return end
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end

	local hrp = target.Character.HumanoidRootPart
	local vel = hrp.AssemblyLinearVelocity

	if vel.Magnitude < 2 then return end

	local predictTime = _G.autoFarmPredictionStrength
	local predictedPos = hrp.Position + vel * predictTime

	return CFrame.new(predictedPos)
end

local characterData = {
	TrashCan = {
		name = "TrashCan",
		working = false,
		priority = {1},
		slots = {
			{
				slot = 1,
				skill = "Throw",
				usable = true,
				condition = function(target) return true end,
				move = function(target)
					return target.Character.HumanoidRootPart.CFrame - (target.Character.HumanoidRootPart.CFrame.LookVector * 3) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 1.2,
				chargeTime = 0,
				attackDelay = 0.1,
				waitAfterAttack = 1.8
			}
		}
	},

	Cyborg = {
		name = "Cyborg",
		working = true,
		priority = {4, 3, 2},
		slots = {
			{
				slot = 1,
				skill = "Machine Gun Blows",
				usable = false,
				condition = function() return true end,
				move = function(target) return target.Character.HumanoidRootPart.CFrame end,
				moveDuration = 0,
				chargeTime = 0,
				attackDelay = 0,
				waitAfterAttack = 0
			},
			{
				slot = 2,
				skill = "Ignition Burst",
				usable = true,
				condition = function(target) return true end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 7) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 1.25,
				chargeTime = 1,
				attackDelay = 0,
				waitAfterAttack = 1.25
			},
			{
				slot = 3,
				skill = "Blitz Shot",
				usable = true,
				condition = function(target) return true end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return CFrame.lookAt(cf.Position + Vector3.new(30, 30, 0), cf.Position + target.Character.Humanoid.MoveDirection * target.Character.Humanoid.WalkSpeed * 1.25)
				end,
				moveDuration = 1.25,
				chargeTime = 2.5,
				attackDelay = 0,
				waitAfterAttack = 1.25
			},
			{
				slot = 4,
				skill = "Jet Dive",
				usable = true,
				condition = function(target) return true end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return CFrame.new(Vector3.new(cf.Position.X, cf.Position.Y, cf.Position.Z + 65) + target.Character.Humanoid.MoveDirection * target.Character.Humanoid.WalkSpeed * 1.25,Vector3.new(cf.Position.X, player.Character.HumanoidRootPart.Position.Y, cf.Position.Z))
				end,
				moveDuration = 1.65,
				chargeTime = 0,
				attackDelay = 0.25,
				waitAfterAttack = 4
			},
		}
	},

	Hunter = {
		name = "Hunter",
		working = true,
		priority = {1, 2, 3},
		slots = {
			{
				slot = 1,
				skill = "Flowing Water",
				usable = true,
				condition = function() return true end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 3.5) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 2,
				chargeTime = 0,
				attackDelay = 0,
				waitAfterAttack = 2
			},
			{
				slot = 2,
				skill = "Lethal Whirlwind Stream",
				usable = true,
				condition = function() return true end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 3.5) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 2,
				chargeTime = 0,
				attackDelay = 0,
				waitAfterAttack = 2
			},
			{
				slot = 3,
				skill = "Hunter's Grasp",
				usable = true,
				condition = function() return true end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 1) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 2,
				chargeTime = 0,
				attackDelay = 0,
				waitAfterAttack = 2
			},
		}
	},

	Ninja = {
		name = "Ninja",
		working = true,
		priority = {1, 2, 4, 3},
		slots = {
			{
				slot = 1,
				skill = "Flash Strike",
				usable = true,
				condition = function() return true end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 8) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 1,
				chargeTime = 0.1,
				attackDelay = 0,
				waitAfterAttack = 1
			},
			{
				slot = 2,
				skill = "Whirlwind Kick",
				usable = true,
				condition = function(target) return target.Character.Humanoid.Health < 12 end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 1) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 1.5,
				chargeTime = 0.4,
				attackDelay = 0,
				waitAfterAttack = 1.5
			},
			{
				slot = 3,
				skill = "Scatter",
				usable = true,
				condition = function() return true end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf
				end,
				moveDuration = 4,
				chargeTime = 0,
				attackDelay = 0,
				waitAfterAttack = 4
			},
			{
				slot = 4,
				skill = "Explosive Shuriken",
				usable = true,
				condition = function() return true end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 7) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 2,
				chargeTime = 0,
				attackDelay = 0,
				waitAfterAttack = 2
			},
		}
	},

	Esper = {
		name = "Esper",
		working = true,
		priority = {1, 3, 4, 2},
		slots = {
			{
				slot = 1,
				skill = "Crushing Pull",
				usable = true,
				condition = function(target) return target.Character.Humanoid.Health <= 13 end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 4.5) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 2,
				chargeTime = 0.25,
				attackDelay = 0,
				waitAfterAttack = 2
			},
			{
				slot = 2,
				skill = "Windstorm Fury",
				usable = true,
				condition = function(target) return target.Character.Humanoid.Health <= 8 end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 1.5) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 1.5,
				chargeTime = 0,
				attackDelay = 0,
				waitAfterAttack = 1.5
			},
			{
				slot = 3,
				skill = "Stone Coffin",
				usable = true,
				condition = function(target) return target.Character.Humanoid.Health <= 12 end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 3) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 1.5,
				chargeTime = 0.15,
				attackDelay = 0,
				waitAfterAttack = 1.5
			},
			{
				slot = 4,
				skill = "Expulsive Push",
				usable = true,
				condition = function(target) return target.Character.Humanoid.Health <= 13 end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 1.5) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 1.5,
				chargeTime = 1,
				attackDelay = 0,
				waitAfterAttack = 1.5
			},
		}
	},

	Blade = {
		name = "Blade",
		working = true,
		priority = {1, 2, 3},
		slots = {
			{
				slot = 1,
				skill = "Quick Slice",
				usable = true,
				condition = function() return true end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 6) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 0.5,
				chargeTime = 0.2,
				attackDelay = 0,
				waitAfterAttack = 0.5
			},
			{
				slot = 2,
				skill = "Atmos Cleave",
				usable = true,
				condition = function() return true end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 3) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 2,
				chargeTime = 0,
				attackDelay = 0,
				waitAfterAttack = 2
			},
			{
				slot = 3,
				skill = "Pinpoint Cut",
				usable = true,
				condition = function() return true end,
				move = function(target)
					local cf = target.Character.HumanoidRootPart.CFrame
					return cf - (cf.LookVector * 6) + target.Character.Humanoid.MoveDirection
				end,
				moveDuration = 1,
				chargeTime = 0,
				attackDelay = 0,
				waitAfterAttack = 1
			},
		}
	},
}

local function executeSkill(ability: {any}, target: Player)
	if _G.autoFarmIsAttacking then return end
	_G.autoFarmIsAttacking = true

	_G.autoFarmRecentAttacked[target] = tick()

	print(`[AutoFarm] Executing {ability.skill} -> {target.Name}`)

	if ability.chargeTime > 0 then task.wait(ability.chargeTime) end

	if ability.move then
		coroutine.wrap(function()
			local start = tick()
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			while tick() - start < ability.moveDuration and hrp and target.Character and target.Character:FindFirstChild("HumanoidRootPart") do
				local baseCFrame = ability.move(target)
				local predicted = predictPosition(target)
				if _G.autoFarmPredictToggle and (predicted and baseCFrame) then
					hrp.CFrame = CFrame.new(predicted.Position) * (baseCFrame - baseCFrame.Position)
				else
					hrp.CFrame = baseCFrame
				end
				RunService.Heartbeat:Wait()
			end
		end)()
	end

	if ability.attackDelay > 0 then task.wait(ability.attackDelay) end

	local communicate = player.Character and player.Character:FindFirstChild("Communicate")
	local tool = player.Backpack:FindFirstChild(ability.skill)
	if communicate and tool then
		communicate:FireServer({["Goal"] = "Console Move", ["Tool"] = tool})
	end

	if ability.waitAfterAttack > 0 then task.wait(ability.waitAfterAttack) end

	_G.autoFarmIsAttacking = false
end

local function visualize(target: Player)
	if _G.autoFarmPreviewToggle and target and target.Character then
		if _G.autoFarmPreviewType == "Camera View" then
			camera.CameraSubject = target.Character.Humanoid or target.Character.HumanoidRootPart
		end
	end

	if _G.autoFarmVisualizeTarget and target and target.Character then
		if _G.autoFarmVisualizeStyle == "Highlight" then
			local hl = target.Character:FindFirstChild("TargetHighlight")
			if not hl then
				hl = Instance.new("Highlight", target.Character)
				hl.Name = "TargetHighlight"
				hl.Adornee = target.Character
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.FillColor = Color3.new(unpack(_G.autoFarmVisualizeColor))
				hl.FillTransparency = 0.5
				hl.OutlineTransparency = 0.35
			end
		end
	end
end

local function afkMode(state: number)
	if state == 1 then
		if _G.autoFarmAfkConnection then _G.autoFarmAfkConnection:Disconnect() end
		_G.autoFarmAfkConnection = RunService.Heartbeat:Connect(function()
			if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
			if player.Character.Humanoid.Health <= 0 then return end

			if _G.autoFarmAntiFling then
				for _, v in pairs(player.Character:GetDescendants()) do
					if v:IsA("BasePart") then
						v.AssemblyLinearVelocity = Vector3.zero
						v.AssemblyAngularVelocity = Vector3.zero
					end
				end
				local hrp = player.Character.HumanoidRootPart
				hrp.Velocity = Vector3.zero
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end

			if _G.autoFarmAFKMode == "Standart" then
				player.Character.HumanoidRootPart.CFrame = CFrame.new(0, 200, 0)
			end
		end)
	else
		if _G.autoFarmAfkConnection then _G.autoFarmAfkConnection:Disconnect() _G.autoFarmAfkConnection = nil end
	end
end

local function AutoFarm(state: number)
	if state == 0 then
		_G.autoFarm = false
		if _G.autoFarmConnection then _G.autoFarmConnection:Disconnect() end
		afkMode(0)
		print("AutoFarm: Disabled")
		return
	end

	_G.autoFarm = true
	_G.autoFarmStats.startTime = tick()
	print("AutoFarm: Enabled")

	_G.autoFarmConnection = RunService.RenderStepped:Connect(function()
		if not _G.autoFarm or _G.autoFarmIsAttacking then return end

		if _G.autoFarmSelfPreservation and player.Character and player.Character.Humanoid.Health <= _G.autoFarmSelfHealthThreshold then
			afkMode(1)
			return
		end

		local target = (function()
			local targetList = {}
			for _, v in ipairs(Players:GetPlayers()) do
				if v ~= player and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") then
					local hp = v.Character.Humanoid.Health
					if hp > 1 and math.floor(hp) <= _G.autoFarmKillHealthThreshold then
						if not _G.autoFarmIgnoreFriends or not table.find(_G.selectedFriends or {}, v.Name) then
							table.insert(targetList, v)
						end
					end
				end
			end

			if #targetList == 0 then return nil end

			if _G.autoFarmPriorityToggle then
				if _G.autoFarmPriorityType == "Health" then
					table.sort(targetList, function(a, b) return a.Character.Humanoid.Health < b.Character.Humanoid.Health end)
				elseif _G.autoFarmPriorityType == "Distance" then
					table.sort(targetList, function(a, b)
						return (player.Character.HumanoidRootPart.Position - a.Character.HumanoidRootPart.Position).Magnitude < (player.Character.HumanoidRootPart.Position - b.Character.HumanoidRootPart.Position).Magnitude
					end)
				end
				return targetList[1]
			end

			return targetList[math.random(1, #targetList)]
		end)()
		if not target then
			afkMode(1)
			return
		end

		afkMode(0)
		visualize(target)

		local charName = player.Character and player.Character:GetAttribute("Character")
		if not charName or not characterData[charName] then return end

		local charData = characterData[charName]

		for _, slotIndex in ipairs(charData.priority) do
			local ability = charData.slots[slotIndex]
			if not ability or not ability.usable then continue end

			local hotbarSlot = playerGui.Hotbar.Backpack.Hotbar:FindFirstChild(tostring(ability.slot))
			if hotbarSlot and hotbarSlot.Base and not hotbarSlot.Base:FindFirstChild("Cooldown") then
				if ability.condition(target) then
					task.spawn(executeSkill, ability, target)
					break
				end
			end
		end
	end)
end

local UI = Bracket:Window({
	Name = "Skuff Auto Farm V2",
	Color = Color3.fromRGB(255, 100, 100),
	Size = UDim2.new(0, 520, 0, 600),
	Position = UDim2.new(0.5, -260, 0.5, -300),
	Enabled = true
})

local MainTab = UI:Tab({Name = "Combat"})

local FarmSection = MainTab:Section({Name = "Auto Farm", Side = "Left"})
local FarmVisualsSection = MainTab:Section({Name = "Visuals", Side = "Left"})
local FarmFiltersSection = MainTab:Section({Name = "Filters", Side = "Right"})
local FarmExtraFuncsSection = MainTab:Section({Name = "Extra", Side = "Right"})

FarmSection:Toggle({
	Name = "Enable Auto Farm",
	Value = _G.autoFarm,
	Callback = function(v) AutoFarm(v and 1 or 0) end
})

FarmSection:Slider({
	Name = "Kill Health Threshold",
	Min = 2, Max = 100, Precise = 1, Unit = "HP",
	Value = _G.autoFarmKillHealthThreshold,
	Callback = function(v) _G.autoFarmKillHealthThreshold = v end
})

FarmSection:Toggle({
	Name = "Self Preservation",
	Flag = "Combat/AutoFarm/SelfPreservation",
	Value = _G.autoFarmSelfPreservation or false,
	Callback = function(v) _G.autoFarmSelfPreservation = v end
})

FarmSection:Slider({
	Name = "Self Health Threshold",
	Flag = "Combat/AutoFarm/SelfHealthThreshold",
	Min = 0,
	Max = 100,
	Precise = 1,
	Unit = "HP",
	Value = _G.autoFarmSelfHealthThreshold or 30,
	Callback = function(v) _G.autoFarmSelfHealthThreshold = v end
})

FarmSection:Dropdown({
	Name = "AFK Mode",
	Flag = "Combat/AutoFarm/AFKMode",
	List = {
		{Name = "Standart", Mode = "Button", Value = _G.autoFarmAFKMode == "Standart" and true or false, Callback = function(selected) if selected and #selected > 0 then _G.autoFarmAFKMode = selected[1] end end},
		{Name = "Absolute Immortal", Mode = "Button", Value = _G.autoFarmAFKMode == "Absolute Immortal" and true or false, Callback = function(selected) if selected and #selected > 0 then _G.autoFarmAFKMode = selected[1] end end},
	},
})

StatusFarmingLabel = FarmSection:Label({Text = "0 Kills | 00:00:00 | 0 Kills/H"})

FarmVisualsSection:Toggle({
	Name = "Show Preview",
	Flag = "Combat/AutoFarm/Preview/Toggle",
	Value = _G.autoFarmPreviewToggle or false,
	Callback = function(v) _G.autoFarmPreviewToggle = v end
})

FarmVisualsSection:Dropdown({
	Name = "Preview Type",
	Flag = "Combat/AutoFarm/Preview/Type",
	List = {
		{Name = "Camera View", Mode = "Button", Value = _G.autoFarmPreviewType == "Camera View" and true or false, Callback = function(selected) if selected and #selected > 0 then _G.autoFarmPreviewType = selected[1] end end},
		{Name = "Absolute Immortal", Mode = "Button", Value = _G.autoFarmPreviewType == "Absolute Immortal" and true or false, Callback = function(selected) if selected and #selected > 0 then _G.autoFarmAFKMode = selected[1] end end},
	},
})

FarmVisualsSection:Toggle({
	Name = "Visualize Toggle",
	Flag = "Combat/AutoFarm/VisualizeTarget/Toggle",
	Value = _G.autoFarmVisualizeTarget or false,
	Callback = function(v) _G.autoFarmVisualizeTarget = v end
})


FarmVisualsSection:Dropdown({
	Name = "Visualize Style",
	Flag = "Combat/AutoFarm/VisualizeTarget/Style",
	List = {
		{Name = "Highlight", Mode = "Button", Value = _G.autoFarmVisualizeStyle == "Highlight" and true or false, Callback = function(selected) if selected and #selected > 0 then _G.autoFarmVisualizeStyle = selected[1] end end},
	},
})

FarmVisualsSection:Colorpicker({
	Name = "Visualize Color",
	Flag = "Combat/AutoFarm/VisualizeTarget/Color",
	Value = _G.autoFarmVisualizeColor or {0,1,1,0,false},
	Callback = function(v,c) _G.autoFarmVisualizeColor = v end
})

FarmFiltersSection:Toggle({
	Name = "Use Target Priority",
	Value = _G.autoFarmPriorityToggle,
	Callback = function(v) _G.autoFarmPriorityToggle = v end
})

FarmFiltersSection:Dropdown({
	Name = "Priority Type",
	List = {
		{Name = "Health", Mode = "Button", Value = _G.autoFarmPriorityType == "Health", Callback = function() _G.autoFarmPriorityType = "Health" end},
		{Name = "Distance", Mode = "Button", Value = _G.autoFarmPriorityType == "Distance", Callback = function() _G.autoFarmPriorityType = "Distance" end},
	}
})

FarmFiltersSection:Toggle({
	Name = "Ignore Friends",
	Value = _G.autoFarmIgnoreFriends,
	Callback = function(v) _G.autoFarmIgnoreFriends = v end
})


FarmExtraFuncsSection:Toggle({
	Name = "Anti-Fling",
	Flag = "Combat/AutoFarm/AntiFling",
	Value = _G.autoFarmAntiFling or false,
	Callback = function(v) _G.autoFarmAntiFling = v end
})

FarmExtraFuncsSection:Toggle({
	Name = "Use Trashcans",
	Flag = "Combat/AutoFarm/UseTrashcans",
	Value = _G.autoFarmUseTrashcans or false,
	Callback = function(v) _G.autoFarmUseTrashcans = v end
})

FarmExtraFuncsSection:Toggle({
	Name = "Anti-Streak",
	Flag = "Combat/AutoFarm/AntiSteak/Toggle",
	Value = _G.autoFarmAntiStreak or false,
	Callback = function(v) _G.autoFarmAntiStreak = v end
})

FarmExtraFuncsSection:Slider({
	Name = "Streak Limit",
	Flag = "Combat/AutoFarm/AntiStreak/Limit",
	Min = 0,
	Max = 10,
	Precise = 1,
	Unit = "Kills",
	Value = _G.autoFarmAntiSteakLimit or 0,
	Callback = function(v) _G.autoFarmAntiSteakLimit = v end
})

FarmExtraFuncsSection:Toggle({
	Name = "Movement Prediction",
	Value = _G.autoFarmPredictToggle,
	Callback = function(v) _G.autoFarmPredictToggle = v end
})

FarmExtraFuncsSection:Slider({
	Name = "Prediction Strength",
	Min = 0.1,
	Max = 2.0,
	Precise = 2,
	Value = _G.autoFarmPredictionStrength,
	Callback = function(v) _G.autoFarmPredictionStrength = v end
})

RunService.Heartbeat:Connect(function()
	if _G.autoFarm then updateStats() end
end)

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Instance)
		character:WaitForChild("Humanoid").Died:Connect(function()
			if _G.autoFarmRecentAttacked[player] and tick() - _G.autoFarmRecentAttacked[player] < 10 then
				_G.autoFarmStats.kills += 1
				_G.autoFarmRecentAttacked[player] = nil
			end
		end)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		if player.Character:FindFirstChild("Humanoid") then
			player.Character:FindFirstChild("Humanoid").Died:Connect(function()
				if _G.autoFarmRecentAttacked[player] and tick() - _G.autoFarmRecentAttacked[player] < 10 then
					_G.autoFarmStats.kills += 1
					_G.autoFarmRecentAttacked[player] = nil
				end
			end)
		end
	end
end

print("Skuff Auto Farm V2: Loaded!")

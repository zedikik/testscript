print("Skuff Auto Farm: Loading...\n")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local Bracket = loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/Bracket/refs/heads/main/BracketV32.lua"))()

if not _G.autoFarm then
	_G.autoFarm = false
	_G.autoFarmKillHealthThreshold = 15
	_G.autoFarmSelfPreservation = false
	_G.autoFarmSelfHealthThreshold = 30
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
	
	_G.autoFarmStats = {
		kills = 0,
		deaths = 0,
		startTime = 0,
	}
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

	StatusFarmingLabel:SetText(string.format("%d Kills | %d Deaths | %02d:%02d:%02d | %d Kills/H", _G.autoFarmStats.kills, _G.autoFarmStats.deaths, hours, minutes, seconds, kph))
end

local characterData = {
	--TrashCan = { name = "TrashCan", working = false, priority = {1}, slots = { ... } },

	Cyborg = {
		name = "Cyborg",
		working = true,
		priority = {4, 3, 2},
		slots = {
			{slot = 1, skill = "Machine Gun Blows", usable = false, condition = function() return true end, move = function() return nil end, moveDuration = 0, chargeTime = 0, attackDelay = 0, waitAfterAttack = 0},
			{slot = 2, skill = "Ignition Burst", usable = true, condition = function() return true end,
			move = function(target) 
				local cf = target.Character.HumanoidRootPart.CFrame
				return cf - (cf.LookVector * 7) + target.Character.Humanoid.MoveDirection
			end,
			moveDuration = 1.25, chargeTime = 1, attackDelay = 0, waitAfterAttack = 1.25},
			{slot = 3, skill = "Blitz Shot", usable = true, condition = function() return true end,
			move = function(target)
				local cf = target.Character.HumanoidRootPart.CFrame
				return CFrame.lookAt(cf.Position + Vector3.new(30, 30, 0), cf.Position + target.Character.Humanoid.MoveDirection * target.Character.Humanoid.WalkSpeed * 1.25)
			end,
			moveDuration = 1.25, chargeTime = 2.5, attackDelay = 0, waitAfterAttack = 1.25},
			{slot = 4, skill = "Jet Dive", usable = true, condition = function() return true end,
			move = function(target)
				local cf = target.Character.HumanoidRootPart.CFrame
				return CFrame.new(Vector3.new(cf.Position.X, cf.Position.Y, cf.Position.Z + 65) + target.Character.Humanoid.MoveDirection * target.Character.Humanoid.WalkSpeed * 1.25,
					Vector3.new(cf.Position.X, player.Character.HumanoidRootPart.Position.Y, cf.Position.Z))
			end,
			moveDuration = 1.65, chargeTime = 0, attackDelay = 0.25, waitAfterAttack = 4},
		}
	},
}

local isAttacking = false
local autoFarmConnection = nil
local afkConnection = nil

local function executeSkill(ability: {any}, target: Player)
	if isAttacking then return end
	isAttacking = true

	print(`[AutoFarm] Executing {ability.skill} → {target.Name}`)

	if ability.chargeTime > 0 then task.wait(ability.chargeTime) end

	if ability.move then
		coroutine.wrap(function()
			local start = tick()
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			while tick() - start < ability.moveDuration and hrp and target.Character and target.Character:FindFirstChild("HumanoidRootPart") do
				hrp.CFrame = ability.move(target)
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

	isAttacking = false
end

local function visualize(target)
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

local function afkMode(state)
	if state == 1 then
		if afkConnection then afkConnection:Disconnect() end

		afkConnection = RunService.Heartbeat:Connect(function()
			if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
			if player.Character.Humanoid.Health <= 1 then return end

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
			elseif _G.autoFarmAFKMode == "Absolute Immortal" then
				-- TODO: Потом нахуй
				print("Absolute Immortal AFK: not implemented yet")
			end
		end)
	else
		if afkConnection then
			afkConnection:Disconnect()
			afkConnection = nil
		end
	end
end

local function AutoFarm(state)
	if state == 0 then
		_G.autoFarm = false
		if autoFarmConnection then autoFarmConnection:Disconnect() end
		
		camera.CameraSubject = player.Character and (player.Character.Humanoid or player.Character.HumanoidRootPart)
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Character then
				local hl = plr.Character:FindFirstChild("TargetHighlight")
				if hl then hl:Destroy() end
			end
		end
		
		afkMode(0)
		
		print("AutoFarm: Disabled")
		return
	end

	_G.autoFarm = true
	_G.autoFarmStats.startTime = tick()
	print("AutoFarm: Enabled")

	autoFarmConnection = RunService.RenderStepped:Connect(function()
		if not _G.autoFarm or isAttacking then return end

		if _G.autoFarmSelfPreservation and player.Character and player.Character.Humanoid.Health <= _G.autoFarmSelfHealthThreshold then
			afkMode(1)
			return
		end

		local target = (function()
			local targetList = {}
			for _, v in ipairs(Players:GetPlayers()) do
				if v ~= player and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") then
					local hp = v.Character.Humanoid.Health
					if hp >= 2 and math.floor(hp) <= _G.autoFarmKillHealthThreshold then
						if not _G.autoFarmIgnoreFriends or not table.find(_G.selectedFriends or {}, v.Name) then
							table.insert(targetList, v)
						end
					end
				end
			end

			if #targetList == 0 then return nil end

			if _G.autoFarmPriorityToggle then
				if _G.autoFarmPriorityType == "Health" then
					table.sort(targetList, function(a, b)
						return a.Character.Humanoid.Health < b.Character.Humanoid.Health
					end)
				elseif _G.autoFarmPriorityType == "Distance" then
					table.sort(targetList, function(a, b)
						return (player.Character.HumanoidRootPart.Position - a.Character.HumanoidRootPart.Position).Magnitude <
							(player.Character.HumanoidRootPart.Position - b.Character.HumanoidRootPart.Position).Magnitude
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
		if not charName or not characterData[charName] or not characterData[charName].working then return end

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

StatusFarmingLabel = FarmSection:Label({Text = "0 Kills | 0 Deaths | 00:00:00 | 0 Kills/H"})

FarmVisualsSection:Button({
	Name = "ResetStats",
	Callback = function() StatusFarmingLabel:SetText("0 Kills | 0 Deaths | 00:00:00 | 0 Kills/H") end,
})

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
	Flag = "Combat/AutoFarm/Priority/Toggle",
	Value = _G.autoFarmPriorityToggle or false,
	Callback = function(v) _G.autoFarmPriorityToggle = v end
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
	Flag = "Combat/AutoFarm/Predict/Toggle",
	Value = _G.autoFarmPredictToggle or false,
	Callback = function(v) _G.autoFarmPredictToggle = v end
})

RunService.Heartbeat:Connect(function()
	if _G.autoFarm then updateStats() end
end)

print("Skuff Auto Farm V2: Loaded!")

-- это пизда нахуй

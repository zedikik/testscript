print("Skuff Auto Farm: Loading...\n")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local camera = workspace.CurrentCamera

--local Bracket = loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/Bracket/refs/heads/main/BracketV32.lua"))() -- https://raw.githubusercontent.com/zedikik/BracketV32/refs/heads/main/BracketV32.lua

print("Skuff Auto Farm: Shared Loading...")

if not _G.autoFarm then
	_G.autoFarm = false
	_G.autoFarmKillHealthThreshold = 15 -- реализовал TargetList()
	_G.autoFarmSelfPreservation = false -- реализовал _G.autoFarmConnection
	_G.autoFarmSelfHealthThreshold = 30 -- реализовал _G.autoFarmConnection
	_G.autoFarmAFKMode = "Standart" -- реализовал _G.autoFarmAFKConnection: без AbI

	_G.autoFarmPreviewToggle = false -- реализовал visualize()
	_G.autoFarmPreviewType = "" -- реализовал visualize(): без AbI
	_G.autoFarmVisualizeTarget = false -- реализовал visualize()
	_G.autoFarmVisualizeStyle = "" -- реализовал visualize()
	_G.autoFarmVisualizeColor = {0,1,1,0,false} -- реализовал visualize()

	_G.autoFarmPriorityToggle = false -- реализовал Target()
	_G.autoFarmPriorityStrict = false -- реализовал Target()
	_G.autoFarmPriorityType = {} -- реализовал Target()
	_G.autoFarmIgnoreFriends = false -- реализовал TargetList()
	_G.autoFarmautoFarmAntiFling = false -- реализовал _G.autoFarmAFKConnection
	_G.autoFarmautoFarmUseTrashcans = false
	_G.autoFarmautoFarmAntiStreak = false
	_G.autoFarmAntiStreakLimit = 7
	_G.autoFarmPredictToggle = false

	_G.autoFarmPriority = {}
end

print("Skuff Auto Farm: Shared Loaded!\n")

print("Skuff Auto Farm: Thread Loading...")

local function AutoFarm(state: number)
	if not state then state = _G.autoFarm == false and 1 or 0 end

	if not player.Character then return end
	if not player.Character:FindFirstChild("HumanoidRootPart") then return end
	if not player.Character:FindFirstChild("Humanoid") then return end
	if player.Character.Humanoid.Health <= 0 then return end

	local characterData = {
		TrashCan = {
			name = "TrashCan", -- yooo
			working = false,
			priority = {1},
			slots = {
				{
					slot = 1,
					skill = "Throw",
					usable = false,
					condition = function(target: Player)
						return true
					end,
					move = function(target: Player)
						return target.Character.HumanoidRootPart.CFrame - (target.Character.HumanoidRootPart.CFrame.LookVector * 3) + target.Character.Humanoid.MoveDirection
					end,
				}
			}
		},
		Bald = {
			name = "Bald",
			working = false,
			priority = {1},
			slots = {
				-- example
				{
					slot = 1,
					skill = "Normal Punch",
					usable = false,
					condition = function(target: Player)
						return true
					end,
					move = function(target: Player)
						return target.Character.HumanoidRootPart.CFrame - (target.Character.HumanoidRootPart.CFrame.LookVector * 3) + target.Character.Humanoid.MoveDirection
					end,
					moveDuraction = 1.5,
					chargeTime = 0,
					attackDelay = 0.2,
					waitAfterAttack = 0.5
				},
			}
		},
		Cyborg = {
			name = "Cyborg",
			working = true,
			priority = {3, 4, 2},
			slots = {
				{
					slot = 1,
					skill = "Machine Gun Blows",
					usable = true,
					condition = function(target: Player)
						return true
					end,
					move = function(target: Player)
						--return target.Character.HumanoidRootPart.CFrame - (target.Character.HumanoidRootPart.CFrame.LookVector * 7) + target.Character.Humanoid.MoveDirection
					end,
					moveDuration = 1.25,
					chargeTime = 1,
					attackDelay = 0,
					waitAfterAttack = 1.25
				},
				{
					slot = 2,
					skill = "Ignition Burst",
					usable = true,
					condition = function(target: Player)
						return true
					end,
					move = function(target: Player)
						return target.Character.HumanoidRootPart.CFrame - (target.Character.HumanoidRootPart.CFrame.LookVector * 7) + target.Character.Humanoid.MoveDirection
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
					condition = function(target: Player)
						return true
					end,
					move = function(target: Player)
						return CFrame.lookAt(target.Character.HumanoidRootPart.CFrame.Position + Vector3.new(30, 30, 0), target.Character.HumanoidRootPart.CFrame.Position + target.Character.Humanoid.MoveDirection * target.Character.Humanoid.WalkSpeed * 1.25)
					end,
					moveDuration = 1.25,
					chargeTime = 2.5,
					attackDelay = 0,
					waitAfterAttack = 0
				},
				{
					slot = 4,
					skill = "Jet Dive",
					usable = true,
					condition = function(target: Player)
						return true
					end,
					move = function(target: Player)
						return CFrame.new(Vector3.new(target.Character.HumanoidRootPart.CFrame.Position.X, target.Character.HumanoidRootPart.CFrame.Position.Y, target.Character.HumanoidRootPart.CFrame.Position.Z + 65) + target.Character.Humanoid.MoveDirection * target.Character.Humanoid.WalkSpeed * 1.25, Vector3.new(target.Character.HumanoidRootPart.CFrame.Position.X, player.Character.HumanoidRootPart.Position.Y, target.Character.HumanoidRootPart.CFrame.Position.Z))
					end,
					moveDuration = 1.65,
					chargeTime = 0,
					attackDelay = 0.25,
					waitAfterAttack = 4
				},
			}
		},
	}

	local function afkMode(state: number)
		if not state then state = _G.autoFarmAFKModeToggle == true and 1 or 0 end

		if state == 1 then
			afkMode(0)
			_G.autoFarmAFKModeToggle = true

			_G.autoFarmAFKConnection = RunService.Heartbeat:Connect(function()
				if not player.Character then return end
				if not player.Character:FindFirstChild("HumanoidRootPart") then return end
				if not player.Character:FindFirstChild("Humanoid") then return end
				if player.Character.Humanoid.Health <= 0 then return end


				if _G.autoFarmautoFarmAntiFling == true then
					task.defer(function()
						for i, v in pairs(player.Character:GetDescendants()) do
							if v:IsA("BasePart") then
								v.AssemblyLinearVelocity = Vector3.new(0,0,0)
								v.AssemblyAngularVelocity = Vector3.new(0,0,0)
							end
						end
					end)
					player.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
					player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					player.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
					player.Character.HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
				end


				if _G.autoFarmAFKMode == "Standart" then
					player.Character.HumanoidRootPart.CFrame = CFrame.new(0, 200, 0)

				elseif _G.autoFarmAFKMode == "Absolute Immortal" then
					print("AFK MODE: Absolute Immortal: not realizabled naxui")
					-- idi naxui dolbaeb
				end
			end)
		else
			_G.autoFarmAFKModeToggle = false

			if _G.autoFarmAFKConnection then _G.autoFarmAFKConnection:Disconnect() end
			_G.autoFarmAFKConnection = nil
		end
	end

	if state == 1 then
		print("enable")
		_G.autoFarm = true

		_G.autoFarmConnection = RunService.RenderStepped:Connect(function(delta: number)
			if _G.autoFarm == false then return end
			if _G.autoFarmSelfPreservation == true and math.floor(player.Character.Humanoid.Health) >= _G.autoFarmSelfHealthThreshold then return end
			if _G.autoFarmKilling == true then warn("already") return end -- вся хуйня


			local targetList = (function()
				local result = {}
				for _, v: Player in pairs(Players:GetPlayers()) do
					if (v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid")) then
						if (v ~= player and (_G.autoFarmIgnoreFriends == true or (_G.selectedFriends == nil and true or (_G.selectedFriends ~= nil and type(_G.selectedFriends) == "table" and not table.find(_G.selectedFriends, v.Name))))) then
							-- other checks
							if math.floor(v.Character.Humanoid.Health) <= _G.autoFarmKillHealthThreshold then
								table.insert(result, v)
							end
						end
					end
				end
				return result;
			end)()


			if type(targetList) ~= "table" or #targetList <= 0 then afkMode(1); return end
			--afkMode(0) -- кто как требует нахуй

			local target = (function()
				if _G.autoFarmPriorityToggle == true then
					local priorityList = {}

					for _, v in ipairs(targetList) do
						table.insert(priorityList, v)
					end

					if _G.autoFarmPriorityType == "Health" then
						table.sort(priorityList, function(a, b)
							return a.Character.Humanoid.Health < b.Character.Humanoid.Health
						end)

					elseif _G.autoFarmPriorityType == "Distance" then
						table.sort(priorityList, function(a, b)
							return (player.Character.HumanoidRootPart.Position - a.Character.HumanoidRootPart.Position).Magnitude < (player.Character.HumanoidRootPart.Position - b.Character.HumanoidRootPart.Position).Magnitude
						end)
					end

					if _G.autoFarmPriorityStrict == true and #priorityList > 0 then
						return priorityList[1]
					else
						return #targetList > 0 and targetList[math.random(1, #targetList)] or nil
					end

				else
					return #targetList > 0 and targetList[math.random(1, #targetList)] or nil
				end
			end)() or targetList[1]
			print(target)

			local function visualize(state: number)
				if not state then state = 1 end

				if state == 1 then
					if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
						if _G.autoFarmPreviewToggle == true then
							if _G.autoFarmPreviewType == "Camera View" then
								camera.CameraSubject = target.Character.Humanoid or target.Character.HumanoidRootPart
							elseif _G.autoFarmPreviewType == "Absolute Immortal" then
								print("Preview: Absolute Immortal: not realizabled naxui")
								-- idi naxui dolbaeb
							else
								warn("_G.autoFarmPreviewType =", _G.autoFarmPreviewType)
							end
						end

						if _G.autoFarmVisualizeTarget == true then
							if _G.autoFarmVisualizeStyle == "Highlight" then
								if not target.Character:FindFirstChild("TargetHightlight") then
									local highlight = Instance.new("Highlight", target.Character)
									highlight.Name = "TargetHightlight"
									highlight.Adornee = target.Character
									highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
									highlight.FillColor = _G.autoFarmVisualizeColor and Color3.new(unpack(_G.autoFarmVisualizeColor)) or Color3.fromRGB(255, 0, 0)
									highlight.FillTransparency = 0.5
									highlight.OutlineTransparency = 0.35
									highlight.Enabled = true
								end
							end
						end
					end

				elseif state == 0 then
					-- disable naxui
					print("Visualize: disable: not realizabled naxui")


					camera.CameraSubject = player.Character.Humanoid or player.Character.HumanoidRootPart
					for i, v in pairs(Players:GetPlayers()) do
						if v and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							if v.Character:FindFirstChild("TargetHightlight") then
								v.Character:FindFirstChild("TargetHightlight"):Destroy()
							end
						end
					end
				end
			end

			visualize(1)

			-- главная работа AutoFarm
			local selectedCharacter = player.Character:GetAttribute("Character")

			if selectedCharacter == nil or selectedCharacter == "" then warn("Failed to get player's character!") return end
			if not characterData[selectedCharacter] or characterData[selectedCharacter] == false then warn(selectedCharacter, "not coded!") return end
			if characterData[selectedCharacter].working == false then warn("") return end

			local charData = characterData[selectedCharacter]

			for _, slotIndex in ipairs(charData.priority) do
				local ability = charData.slots[slotIndex]
				if ability and ability.usable then
					local hotbar = playerGui.Hotbar.Backpack.Hotbar[tostring(ability.slot)]
					if hotbar and hotbar.Base and not hotbar.Base:FindFirstChild("Cooldown") then
						if ability.condition(target) then
							print("condition true")
							_G.autoFarmKilling = true
							print("killing autofarm")

							if ability.chargeTime > 0 then
								print("chargeup")
								_G.chargeUp = true
								task.wait(ability.chargeTime)
								_G.chargeUp = false
							end
							print("starting main process")

							if ability.move then
								print("move")
								coroutine.wrap(function()
									local start = tick()
									while tick() - start < ability.moveDuration do
										player.Character.HumanoidRootPart.CFrame = ability.move(
											target.Character.HumanoidRootPart, 
											player.Character.HumanoidRootPart
										)
										task.wait()
									end
								end)()
							end

							if ability.attackDelay > 0 then
								print("delay")
								task.wait(ability.attackDelay)
							end

							print("servered")
							player.Character.Communicate:FireServer({
								["Goal"] = "Console Move",
								["Tool"] = player.Backpack:WaitForChild(ability.skill)
							})

							if ability.waitAfterAttack > 0 then
								task.wait(ability.waitAfterAttack)
							end

							print("stop process")
							_G.autoFarmKilling = false
							break
						end
					end
				end
			end
		end)
	else
		print("disable")
		print("disable autofarm: not realizabled naxui")

		_G.autoFarm = false

		afkMode(0)



		-- idi naxui dolbaeb
	end
end

print("Skuff Auto Farm: Thread Loaded!\n")
print("Skuff Auto Farm: UI Loading...")

local UI = Bracket:Window({
	Name = "TSB AutoFarm dev test",
	Color = Color3.fromRGB(255, 100, 100),
	Size = UDim2.new(0, 500, 0, 500),
	Position = UDim2.new(0.5, -250, 0.5, -250),
	Enabled = true
})

local MainTab = UI:Tab({
	Name = "Combat"
})

local FarmSection = MainTab:Section({
	Name = "Auto Farm",
	Side = "Left" 
})

local FarmExtraFuncsSection = MainTab:Section({
	Name = "Extra Functions",
	Side = "Right" 
})

local FarmVisualsSection = MainTab:Section({
	Name = "Visualize Settings",
	Side = "Left" 
})

local FarmFiltersSection = MainTab:Section({
	Name = "Filters",
	Side = "Right" 
})

FarmSection:Toggle({
	Name = "Enable Auto Farm",
	Flag = "Combat/AutoFarm/Toggle",
	Value = _G.autoFarm or false,
	Callback = function(value)
		print("Auto farm:", value == true and "enabled" or "disabled")
		AutoFarm(value == true and 1 or 0)
	end
}):ToolTip("Test")

FarmSection:Slider({
	Name = "Kill Health Threshold",
	Flag = "Combat/AutoFarm/KillHealthThreshold",
	Min = 0,
	Max = 100,
	Precise = 1,
	Unit = "HP",
	Value = _G.autoFarmKillHealthThreshold or 15,
	Callback = function(value)
		print("Auto Farm, Kill Health Threshold:", value)
		_G.autoFarmKillHealthThreshold = value
	end
})

FarmSection:Toggle({
	Name = "Self Preservation",
	Flag = "Combat/AutoFarm/SelfPreservation",
	Value = _G.autoFarmSelfPreservation or false,
	Callback = function(value)
		print("Auto farm, Self Preservation:", value == true and "enabled" or "disabled")
		_G.autoFarmSelfPreservation = value
	end
})

FarmSection:Slider({
	Name = "Self Health Threshold",
	Flag = "Combat/AutoFarm/SelfHealthThreshold",
	Min = 0,
	Max = 100,
	Precise = 1,
	Unit = "HP",
	Value = _G.autoFarmSelfHealthThreshold or 30,
	Callback = function(value)
		print("Auto Farm, Self Health Threshold:", value)
		_G.autoFarmSelfHealthThreshold = value
	end
})

FarmSection:Dropdown({
	Name = "AFK Mode",
	Flag = "Combat/AutoFarm/AFKMode",
	List = {
		{
			Name = "Standart", 
			Mode = "Button", 
			Value = _G.autoFarmAFKMode == "Standart" and true or false, 
			Callback = function(selected)
				if selected and #selected > 0 then
					_G.autoFarmAFKMode = selected[1]
					print("Auto farm, AFK Mode:", _G.autoFarmAFKMode)
				end
			end
		},

		{
			Name = "Absolute Immortal", 
			Mode = "Button", 
			Value = _G.autoFarmAFKMode == "Absolute Immortal" and true or false, 
			Callback = function(selected)
				if selected and #selected > 0 then
					_G.autoFarmAFKMode = selected[1]
					print("Auto farm, AFK Mode:", _G.autoFarmAFKMode)
				end
			end
		},
	},
})

local StatusFarmingLabel = FarmSection:Label({
	Text = "0 Kills | 0 Deaths | 00:00:00 | 0 Kills/H"
})

FarmVisualsSection:Button({
	Name = "ResetStats",
	Callback = function()
		StatusFarmingLabel:SetText("0 Kills | 0 Deaths | 00:00:00 | 0 Kills/H")
	end,
})

FarmVisualsSection:Toggle({
	Name = "Show Preview",
	Flag = "Combat/AutoFarm/Preview/Toggle",
	Value = _G.autoFarmPreviewToggle or false,
	Callback = function(value)
		print("Auto farm, Show Preview:", value == true and "enabled" or "disabled")
		_G.autoFarmPreviewToggle = value
	end
})

FarmVisualsSection:Dropdown({
	Name = "Preview Type",
	Flag = "Combat/AutoFarm/Preview/Type",
	List = {
		{
			Name = "Camera View", 
			Mode = "Button", 
			Value = _G.autoFarmPreviewType == "Camera View" and true or false, 
			Callback = function(selected)
				if selected and #selected > 0 then
					_G.autoFarmPreviewType = selected[1]
					print("Auto farm, Preview Type:", _G.autoFarmPreviewType)
				end
			end
		},
		{
			Name = "Absolute Immortal", 
			Mode = "Button", 
			Value = _G.autoFarmPreviewType == "Absolute Immortal" and true or false, 
			Callback = function(selected)
				if selected and #selected > 0 then
					_G.autoFarmAFKMode = selected[1]
					print("Auto farm, Preview Type:", _G.autoFarmPreviewType)
				end
			end
		},
	},
})

FarmVisualsSection:Toggle({
	Name = "Visualize Toggle",
	Flag = "Combat/AutoFarm/VisualizeTarget/Toggle",
	Value = _G.autoFarmVisualizeTarget or false,
	Callback = function(value)
		print("Auto farm, Visualize Target:", value == true and "enabled" or "disabled")
		print("_G.autoFarmVisualizeTarget =", _G.autoFarmVisualizeTarget, value)
		_G.autoFarmVisualizeTarget = value
		print("_G.autoFarmVisualizeTarget =", _G.autoFarmVisualizeTarget)
	end
})


FarmVisualsSection:Dropdown({
	Name = "Visualize Style",
	Flag = "Combat/AutoFarm/VisualizeTarget/Style",
	List = {
		{
			Name = "Highlight", 
			Mode = "Button", 
			Value = _G.autoFarmVisualizeStyle == "Highlight" and true or false, 
			Callback = function(selected)
				if selected and #selected > 0 then
					_G.autoFarmVisualizeStyle = selected[1]
					print("Auto farm, Visualize Style:", _G.autoFarmVisualizeStyle)
				end
			end
		},
	},
})

-- бля пиздец нахуй
FarmVisualsSection:Colorpicker({
	Name = "Visualize Color",
	Flag = "Combat/AutoFarm/VisualizeTarget/Color",
	Value = _G.autoFarmVisualizeColor or {0,1,1,0,false},
	Callback = function(value, color)
		print("Auto farm, Target Color:", color, "\nValue:", value)
		_G.autoFarmVisualizeColor = value
	end
})

FarmFiltersSection:Toggle({
	Name = "Use Target Priority",
	Flag = "Combat/AutoFarm/Priority/Toggle",
	Value = _G.autoFarmPriorityToggle or false,
	Callback = function(value)
		print("Auto farm, Use Target Priority:", value == true and "enabled" or "disabled")
		_G.autoFarmPriorityToggle = value
	end
})

FarmFiltersSection:Toggle({
	Name = "Strict Priority",
	Flag = "Combat/AutoFarm/Priority/Strict/Toggle",
	Value = _G.autoFarmPriorityStrict or false,
	Callback = function(value)
		print("Auto farm, Strict Priority:", value == true and "enabled" or "disabled")
		_G.autoFarmPriorityStrict = value
	end
})

FarmFiltersSection:Dropdown({
	Name = "Priority Type",
	Flag = "Combat/AutoFarm/Priority/Type",
	List = {
		{
			Name = "Health", 
			Mode = "Toggle", 
			Value = table.find(_G.autoFarmPriorityType or {}, "Health") and true or false,
			Callback = function(selected)
				_G.autoFarmVisualizeStyle = selected or {}
				print("Auto farm, Priority Type:", _G.autoFarmPriorityType)
			end
		},
		{
			Name = "Distance", 
			Mode = "Toggle", 
			Value = table.find(_G.autoFarmPriorityType or {}, "Health") and true or false, 
			Callback = function(selected)
				_G.autoFarmVisualizeStyle = selected or {}
				print("Auto farm, Priority Type:", _G.autoFarmPriorityType)
			end
		},
	},
})

FarmFiltersSection:Toggle({
	Name = "Ignore Friends",
	Flag = "Combat/AutoFarm/IgnoreFriends",
	Value = _G.autoFarmIgnoreFriends or false,
	Callback = function(value)
		print("Auto farm, Ignore Friends:", value == true and "enabled" or "disabled")
		_G.autoFarmIgnoreFriends = value
	end
})

FarmExtraFuncsSection:Toggle({
	Name = "Anti-Fling",
	Flag = "Combat/AutoFarm/AntiFling",
	Value = _G.autoFarmAntiFling or false,
	Callback = function(value)
		print("Auto farm, Anti-Fling:", value == true and "enabled" or "disabled")
		_G.autoFarmAntiFling = value
	end
})

FarmExtraFuncsSection:Toggle({
	Name = "Use Trashcans",
	Flag = "Combat/AutoFarm/UseTrashcans",
	Value = _G.autoFarmUseTrashcans or false,
	Callback = function(value)
		print("Auto farm, Use Trashcans:", value == true and "enabled" or "disabled")
		_G.autoFarmUseTrashcans = value
	end
})

FarmExtraFuncsSection:Toggle({
	Name = "Anti-Streak",
	Flag = "Combat/AutoFarm/AntiSteak/Toggle",
	Value = _G.autoFarmAntiSteak or false,
	Callback = function(value)
		print("Auto farm, Anti-Streak:", value == true and "enabled" or "disabled")
		_G.autoFarmAntiSteak = value
	end
})

FarmExtraFuncsSection:Slider({
	Name = "Streak Limit",
	Flag = "Combat/AutoFarm/AntiStreak/Limit",
	Min = 0,
	Max = 10,
	Precise = 1,
	Unit = "Kills",
	Value = _G.autoFarmAntiSteakLimit or 0,
	Callback = function(value)
		print("Auto Farm, Streak Limit:", value)
		_G.autoFarmAntiSteakLimit = value
	end
})

FarmExtraFuncsSection:Toggle({
	Name = "Movement Prediction",
	Flag = "Combat/AutoFarm/Predict/Toggle",
	Value = _G.autoFarmPredictToggle or false,
	Callback = function(value)
		print("Auto farm, Movement Prediction:", value == true and "enabled" or "disabled")
		_G.autoFarmPredictToggle = value
	end
})

print("Skuff Auto Farm: UI Loaded!\n")
print("Skuff Auto Farm: Loaded!")

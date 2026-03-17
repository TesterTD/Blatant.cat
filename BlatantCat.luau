local CoreGui = cloneref(game:GetService("CoreGui"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TextService = cloneref(game:GetService("TextService"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))
local LocalPlayer = Players.LocalPlayer

local UI = {}
UI.__index = UI

function UI.new()
	local self = setmetatable({}, UI)
	self._connections = {}
	self._activeTab = nil
	self._tabContents = {}
	self._tabButtons = {}
	self._visible = true
	self._espObjects = {}
	self._espEnabled = false
	self._openColorPickers = {}
	self._espSettings = {
		BoxEnabled = false,
		BoxType = "Standard",
		OutlineEnabled = true,
		SkeletonEnabled = false,
		HealthBarEnabled = false,
		DistanceEnabled = false,
		NameEnabled = false,
		HighlightEnabled = false,
		SnaplineEnabled = false,
		SnaplineMode = "Bottom",
		TeamCheck = false,
		BoxColor = Color3.fromRGB(0, 180, 180),
		NameColor = Color3.fromRGB(255, 255, 255),
		SkeletonColor = Color3.fromRGB(255, 255, 255),
		SnaplineColor = Color3.fromRGB(0, 180, 180),
		DistanceColor = Color3.fromRGB(200, 200, 200),
		HighlightFillColor = Color3.fromRGB(0, 180, 180),
		HighlightOutlineColor = Color3.fromRGB(255, 255, 255),
		HighlightFillTransparency = 0.75,
		HighlightOutlineTransparency = 0,
	}
	self._aimbotSettings = {
		Enabled = false,
		TeamCheck = false,
		FOV = 120,
		Smoothness = 5,
		BodyAim = "Head",
		WallCheck = true,
		Prediction = 0,
		StickyTarget = false,
		LookAtView = false,
		ActivationKey = "MouseButton2",
		ShowFOV = true,
		FOVColor = Color3.fromRGB(0, 180, 180),
		TriggerbotEnabled = false,
		TriggerbotDelay = 50,
		TriggerbotFOV = 30,
	}
	self._aimbotState = {
		currentTarget = nil,
		isActive = false,
		triggerbotCooldown = 0,
		triggerbotFiring = false,
	}
	self._miscSettings = {
		WalkSpeed = 16,
		LoopWalkSpeed = false,
		InfiniteJump = false,
		HitboxEnabled = false,
		HitboxSize = 15,
		HitboxTransparency = 0.9,
		HitboxVisible = false,
		HitboxPart = "HumanoidRootPart",
		HitboxTeamCheck = false,
		FlyEnabled = false,
		FlySpeed = 50,
		NoclipEnabled = false,
	}
	self._flyState = {
		active = false,
		cfLoop = nil,
	}
	self._noclipState = {
		active = false,
	}
	self._fovCircle = nil
	self:_build()
	self:_setupToggle()
	self:_setupESP()
	self:_setupAimbot()
	self:_setupMisc()
	return self
end

function UI:_connect(signal, fn)
	local conn = signal:Connect(fn)
	table.insert(self._connections, conn)
	return conn
end

function UI:_build()
	self._screenGui = Instance.new("ScreenGui")
	self._screenGui.Name = "BlatantUI"
	self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self._screenGui.ResetOnSpawn = false
	self._screenGui.Parent = CoreGui

	self._mainFrame = Instance.new("Frame")
	self._mainFrame.Size = UDim2.new(0, 580, 0, 420)
	self._mainFrame.Position = UDim2.new(0.5, -290, 0.5, -210)
	self._mainFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
	self._mainFrame.BorderColor3 = Color3.fromRGB(5, 8, 10)
	self._mainFrame.BorderSizePixel = 1
	self._mainFrame.Active = true
	self._mainFrame.Parent = self._screenGui

	self._innerBorder = Instance.new("Frame")
	self._innerBorder.Size = UDim2.new(1, -2, 1, -2)
	self._innerBorder.Position = UDim2.new(0, 1, 0, 1)
	self._innerBorder.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
	self._innerBorder.BorderColor3 = Color3.fromRGB(35, 40, 45)
	self._innerBorder.BorderSizePixel = 1
	self._innerBorder.ClipsDescendants = true
	self._innerBorder.Parent = self._mainFrame

	self:_buildDrag()
	self:_buildTopLine()
	self:_buildTitle()
	self:_buildTabArea()
	self:_buildContentArea()
	self:_buildTabs()
end

function UI:_buildDrag()
	local dragging = false
	local dragStart, startPos

	self:_connect(self._mainFrame.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = self._mainFrame.Position
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if c then c:Disconnect() end
				end
			end)
		end
	end)

	self:_connect(UserInputService.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
			local delta = input.Position - dragStart
			self._mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

function UI:_buildTopLine()
	local topLine = Instance.new("Frame")
	topLine.Size = UDim2.new(1, 0, 0, 2)
	topLine.BackgroundColor3 = Color3.new(1, 1, 1)
	topLine.BorderSizePixel = 0
	topLine.Parent = self._innerBorder

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 200)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 180, 180)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 150)),
	})
	gradient.Parent = topLine
end

function UI:_buildTitle()
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0, 22)
	title.Position = UDim2.new(0, 8, 0, 2)
	title.BackgroundTransparency = 1
	title.Text = "blatant.cat"
	title.TextColor3 = Color3.fromRGB(220, 225, 230)
	title.Font = Enum.Font.Code
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = self._innerBorder
end

function UI:_buildTabArea()
	self._tabArea = Instance.new("Frame")
	self._tabArea.Size = UDim2.new(0, 70, 1, -25)
	self._tabArea.Position = UDim2.new(0, 0, 0, 25)
	self._tabArea.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	self._tabArea.BorderColor3 = Color3.fromRGB(35, 40, 45)
	self._tabArea.BorderSizePixel = 1
	self._tabArea.Parent = self._innerBorder

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self._tabArea
end

function UI:_buildContentArea()
	self._contentArea = Instance.new("Frame")
	self._contentArea.Size = UDim2.new(1, -82, 1, -37)
	self._contentArea.Position = UDim2.new(0, 76, 0, 31)
	self._contentArea.BackgroundTransparency = 1
	self._contentArea.ClipsDescendants = false
	self._contentArea.Parent = self._innerBorder
end

function UI:_buildTabs()
	local tabNames = {"VISUALS", "AIMBOT", "MISC", "INFO"}
	for _, name in ipairs(tabNames) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 34)
		btn.BackgroundTransparency = 1
		btn.Text = name
		btn.Font = Enum.Font.Code
		btn.TextSize = 12
		btn.TextColor3 = Color3.fromRGB(120, 130, 140)
		btn.Parent = self._tabArea
		self._tabButtons[name] = btn

		local content = Instance.new("Frame")
		content.Size = UDim2.new(1, 0, 1, 0)
		content.BackgroundTransparency = 1
		content.Visible = false
		content.ClipsDescendants = false
		content.Parent = self._contentArea
		self._tabContents[name] = content

		self:_connect(btn.MouseButton1Click, function()
			self:_switchTab(name)
		end)
	end

	self:_buildVisualsTab()
	self:_buildAimbotTab()
	self:_buildMiscTab()
	self:_buildInfoTab()
	self:_switchTab("VISUALS")
end

function UI:_switchTab(name)
	for tabName, content in pairs(self._tabContents) do
		content.Visible = (tabName == name)
		self._tabButtons[tabName].TextColor3 = (tabName == name) and Color3.fromRGB(0, 180, 180) or Color3.fromRGB(120, 130, 140)
	end
	self._activeTab = name
end

function UI:_createGroupbox(parent, title, pos, size)
	local groupbox = Instance.new("Frame")
	groupbox.Size = size
	groupbox.Position = pos
	groupbox.BackgroundColor3 = Color3.fromRGB(18, 21, 25)
	groupbox.BorderColor3 = Color3.fromRGB(35, 40, 45)
	groupbox.BorderSizePixel = 1
	groupbox.ClipsDescendants = false
	groupbox.Parent = parent

	local textBounds = TextService:GetTextSize(" " .. title .. " ", 13, Enum.Font.Code, Vector2.new(999, 999))

	local labelBg = Instance.new("Frame")
	labelBg.Size = UDim2.new(0, textBounds.X + 4, 0, 14)
	labelBg.Position = UDim2.new(0, 8, 0, -7)
	labelBg.BackgroundColor3 = Color3.fromRGB(18, 21, 25)
	labelBg.BorderSizePixel = 0
	labelBg.ZIndex = 3
	labelBg.Parent = groupbox

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = " " .. title .. " "
	label.TextColor3 = Color3.fromRGB(180, 190, 200)
	label.Font = Enum.Font.Code
	label.TextSize = 13
	label.ZIndex = 4
	label.Parent = labelBg

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = groupbox

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = groupbox

	return groupbox
end

function UI:_createCheckbox(parent, text, state, callback, rightText)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 16)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 12, 0, 12)
	box.Position = UDim2.new(0, 0, 0.5, -6)
	box.BackgroundColor3 = Color3.fromRGB(25, 28, 32)
	box.BorderColor3 = Color3.fromRGB(5, 8, 10)
	box.BorderSizePixel = 1
	box.Parent = frame

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1, -2, 1, -2)
	fill.Position = UDim2.new(0, 1, 0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(0, 180, 180)
	fill.BorderSizePixel = 0
	fill.Visible = state
	fill.Parent = box

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -20, 1, 0)
	lbl.Position = UDim2.new(0, 20, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(210, 215, 220)
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frame

	if rightText then
		local rl = Instance.new("TextLabel")
		rl.Size = UDim2.new(1, 0, 1, 0)
		rl.BackgroundTransparency = 1
		rl.Text = rightText
		rl.TextColor3 = Color3.fromRGB(130, 140, 150)
		rl.Font = Enum.Font.Code
		rl.TextSize = 13
		rl.TextXAlignment = Enum.TextXAlignment.Right
		rl.Parent = frame
	end

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = frame

	local currentState = state
	self:_connect(btn.MouseButton1Click, function()
		currentState = not currentState
		fill.Visible = currentState
		if callback then callback(currentState) end
	end)

	return frame
end

function UI:_createSlider(parent, text, min, max, default, callback, suffix)
	suffix = suffix or ""
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 28)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 14)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(210, 215, 220)
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frame

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(1, 0, 0, 14)
	valLabel.BackgroundTransparency = 1
	valLabel.Text = tostring(default) .. suffix
	valLabel.TextColor3 = Color3.fromRGB(130, 140, 150)
	valLabel.Font = Enum.Font.Code
	valLabel.TextSize = 13
	valLabel.TextXAlignment = Enum.TextXAlignment.Right
	valLabel.Parent = frame

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0, 6)
	barBg.Position = UDim2.new(0, 0, 0, 20)
	barBg.BackgroundColor3 = Color3.fromRGB(25, 28, 32)
	barBg.BorderColor3 = Color3.fromRGB(5, 8, 10)
	barBg.BorderSizePixel = 1
	barBg.Parent = frame

	local scale = (default - min) / (max - min)
	local fillBar = Instance.new("Frame")
	fillBar.Size = UDim2.new(scale, 0, 1, 0)
	fillBar.BackgroundColor3 = Color3.fromRGB(0, 180, 180)
	fillBar.BorderSizePixel = 0
	fillBar.Parent = barBg

	local sliderBtn = Instance.new("TextButton")
	sliderBtn.Size = UDim2.new(1, 0, 1, 0)
	sliderBtn.BackgroundTransparency = 1
	sliderBtn.Text = ""
	sliderBtn.Parent = barBg

	local sliding = false

	local function update(input)
		local rel = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
		local val = math.floor(min + (max - min) * rel + 0.5)
		fillBar.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
		valLabel.Text = tostring(val) .. suffix
		if callback then callback(val) end
	end

	self:_connect(sliderBtn.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = true
			update(input)
		end
	end)

	self:_connect(UserInputService.InputChanged, function(input)
		if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
			update(input)
		end
	end)

	self:_connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = false
		end
	end)

	return frame
end

function UI:_createDropdown(parent, text, options, default, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 40)
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = false
	frame.ZIndex = 6
	frame.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 14)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(210, 215, 220)
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 6
	lbl.Parent = frame

	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, 0, 0, 20)
	box.Position = UDim2.new(0, 0, 0, 18)
	box.BackgroundColor3 = Color3.fromRGB(25, 28, 32)
	box.BorderColor3 = Color3.fromRGB(5, 8, 10)
	box.BorderSizePixel = 1
	box.ClipsDescendants = false
	box.ZIndex = 6
	box.Parent = frame

	local selLabel = Instance.new("TextLabel")
	selLabel.Size = UDim2.new(1, -22, 1, 0)
	selLabel.Position = UDim2.new(0, 6, 0, 0)
	selLabel.BackgroundTransparency = 1
	selLabel.Text = default
	selLabel.TextColor3 = Color3.fromRGB(210, 215, 220)
	selLabel.Font = Enum.Font.Code
	selLabel.TextSize = 13
	selLabel.TextXAlignment = Enum.TextXAlignment.Left
	selLabel.ZIndex = 7
	selLabel.Parent = box

	local arrowFrame = Instance.new("Frame")
	arrowFrame.Size = UDim2.new(0, 18, 1, 0)
	arrowFrame.Position = UDim2.new(1, -18, 0, 0)
	arrowFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 45)
	arrowFrame.BorderSizePixel = 0
	arrowFrame.ZIndex = 7
	arrowFrame.Parent = box

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(1, 0, 1, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "+"
	arrow.TextColor3 = Color3.fromRGB(180, 190, 200)
	arrow.Font = Enum.Font.Code
	arrow.TextSize = 14
	arrow.ZIndex = 8
	arrow.Parent = arrowFrame

	local maxVisible = math.min(#options, 5)
	local listHeight = maxVisible * 20

	local dropScroll = Instance.new("ScrollingFrame")
	dropScroll.Size = UDim2.new(1, 0, 0, listHeight)
	dropScroll.Position = UDim2.new(0, 0, 1, 1)
	dropScroll.BackgroundColor3 = Color3.fromRGB(20, 23, 27)
	dropScroll.BorderColor3 = Color3.fromRGB(35, 40, 45)
	dropScroll.BorderSizePixel = 1
	dropScroll.Visible = false
	dropScroll.ZIndex = 50
	dropScroll.ClipsDescendants = true
	dropScroll.ScrollBarThickness = 3
	dropScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 180, 180)
	dropScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 20)
	dropScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
	dropScroll.Parent = box

	local dropLayout = Instance.new("UIListLayout")
	dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
	dropLayout.Parent = dropScroll

	local opened = false

	for _, opt in ipairs(options) do
		local optBtn = Instance.new("TextButton")
		optBtn.Size = UDim2.new(1, 0, 0, 20)
		optBtn.BackgroundColor3 = Color3.fromRGB(20, 23, 27)
		optBtn.BorderSizePixel = 0
		optBtn.Text = "  " .. opt
		optBtn.TextColor3 = Color3.fromRGB(190, 195, 200)
		optBtn.Font = Enum.Font.Code
		optBtn.TextSize = 12
		optBtn.TextXAlignment = Enum.TextXAlignment.Left
		optBtn.ZIndex = 51
		optBtn.Parent = dropScroll

		self:_connect(optBtn.MouseButton1Click, function()
			selLabel.Text = opt
			dropScroll.Visible = false
			opened = false
			arrow.Text = "+"
			if callback then callback(opt) end
		end)

		self:_connect(optBtn.MouseEnter, function()
			optBtn.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
		end)
		self:_connect(optBtn.MouseLeave, function()
			optBtn.BackgroundColor3 = Color3.fromRGB(20, 23, 27)
		end)
	end

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(1, 0, 1, 0)
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Text = ""
	toggleBtn.ZIndex = 8
	toggleBtn.Parent = box

	self:_connect(toggleBtn.MouseButton1Click, function()
		opened = not opened
		dropScroll.Visible = opened
		arrow.Text = opened and "-" or "+"
	end)

	return frame
end

function UI:_createColorpicker(parent, text, defaultColor, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 16)
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = false
	frame.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -26, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(210, 215, 220)
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frame

	local preview = Instance.new("Frame")
	preview.Size = UDim2.new(0, 18, 0, 10)
	preview.Position = UDim2.new(1, -18, 0.5, -5)
	preview.BackgroundColor3 = defaultColor
	preview.BorderColor3 = Color3.fromRGB(5, 8, 10)
	preview.BorderSizePixel = 1
	preview.Parent = frame

	local pickerOpen = false
	local currentH, currentS, currentV = Color3.toHSV(defaultColor)

	local pickerFrame = Instance.new("Frame")
	pickerFrame.Size = UDim2.new(0, 180, 0, 160)
	pickerFrame.BackgroundColor3 = Color3.fromRGB(20, 23, 27)
	pickerFrame.BorderColor3 = Color3.fromRGB(50, 55, 60)
	pickerFrame.BorderSizePixel = 1
	pickerFrame.Visible = false
	pickerFrame.ZIndex = 100
	pickerFrame.Parent = self._screenGui

	local svBox = Instance.new("Frame")
	svBox.Size = UDim2.new(0, 140, 0, 120)
	svBox.Position = UDim2.new(0, 8, 0, 8)
	svBox.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
	svBox.BorderColor3 = Color3.fromRGB(5, 8, 10)
	svBox.BorderSizePixel = 1
	svBox.ZIndex = 101
	svBox.ClipsDescendants = true
	svBox.Parent = pickerFrame

	local satOverlay = Instance.new("Frame")
	satOverlay.Size = UDim2.new(1, 0, 1, 0)
	satOverlay.BackgroundColor3 = Color3.new(1, 1, 1)
	satOverlay.BorderSizePixel = 0
	satOverlay.ZIndex = 102
	satOverlay.Parent = svBox

	local satGrad = Instance.new("UIGradient")
	satGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
	satGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	satGrad.Parent = satOverlay

	local blackOverlay = Instance.new("Frame")
	blackOverlay.Size = UDim2.new(1, 0, 1, 0)
	blackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	blackOverlay.BorderSizePixel = 0
	blackOverlay.ZIndex = 103
	blackOverlay.Parent = svBox

	local blackGrad = Instance.new("UIGradient")
	blackGrad.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))
	blackGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	blackGrad.Rotation = 90
	blackGrad.Parent = blackOverlay

	local svCursor = Instance.new("Frame")
	svCursor.Size = UDim2.new(0, 6, 0, 6)
	svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	svCursor.BorderColor3 = Color3.new(0, 0, 0)
	svCursor.BorderSizePixel = 1
	svCursor.ZIndex = 105
	svCursor.Position = UDim2.new(1 - currentS, -3, 1 - currentV, -3)
	svCursor.Parent = svBox

	local svBtn = Instance.new("TextButton")
	svBtn.Size = UDim2.new(1, 0, 1, 0)
	svBtn.BackgroundTransparency = 1
	svBtn.Text = ""
	svBtn.ZIndex = 104
	svBtn.Parent = svBox

	local hueBar = Instance.new("Frame")
	hueBar.Size = UDim2.new(0, 16, 0, 120)
	hueBar.Position = UDim2.new(0, 156, 0, 8)
	hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
	hueBar.BorderColor3 = Color3.fromRGB(5, 8, 10)
	hueBar.BorderSizePixel = 1
	hueBar.ZIndex = 101
	hueBar.Parent = pickerFrame

	local hueGrad = Instance.new("UIGradient")
	hueGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	})
	hueGrad.Rotation = 90
	hueGrad.Parent = hueBar

	local hueCursor = Instance.new("Frame")
	hueCursor.Size = UDim2.new(1, 4, 0, 4)
	hueCursor.Position = UDim2.new(0, -2, currentH, -2)
	hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	hueCursor.BorderColor3 = Color3.new(0, 0, 0)
	hueCursor.BorderSizePixel = 1
	hueCursor.ZIndex = 103
	hueCursor.Parent = hueBar

	local hueBtn = Instance.new("TextButton")
	hueBtn.Size = UDim2.new(1, 0, 1, 0)
	hueBtn.BackgroundTransparency = 1
	hueBtn.Text = ""
	hueBtn.ZIndex = 102
	hueBtn.Parent = hueBar

	local hexInput = Instance.new("TextBox")
	hexInput.Size = UDim2.new(0, 140, 0, 18)
	hexInput.Position = UDim2.new(0, 8, 0, 134)
	hexInput.BackgroundColor3 = Color3.fromRGB(25, 28, 32)
	hexInput.BorderColor3 = Color3.fromRGB(5, 8, 10)
	hexInput.BorderSizePixel = 1
	hexInput.TextColor3 = Color3.fromRGB(210, 215, 220)
	hexInput.Font = Enum.Font.Code
	hexInput.TextSize = 12
	hexInput.ZIndex = 102
	hexInput.ClearTextOnFocus = false
	hexInput.Parent = pickerFrame

	local function colorToHex(c)
		return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end

	local function hexToColor(hex)
		hex = hex:gsub("#", "")
		if #hex == 6 then
			local r = tonumber(hex:sub(1, 2), 16)
			local g = tonumber(hex:sub(3, 4), 16)
			local b = tonumber(hex:sub(5, 6), 16)
			if r and g and b then
				return Color3.fromRGB(r, g, b)
			end
		end
		return nil
	end

	local function applyColor()
		local c = Color3.fromHSV(currentH, currentS, currentV)
		preview.BackgroundColor3 = c
		svBox.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
		svCursor.Position = UDim2.new(1 - currentS, -3, 1 - currentV, -3)
		hueCursor.Position = UDim2.new(0, -2, currentH, -2)
		hexInput.Text = colorToHex(c)
		if callback then callback(c) end
	end

	local function updatePickerPosition()
		local absPos = preview.AbsolutePosition
		local absSize = preview.AbsoluteSize
		local screenSize = Workspace.CurrentCamera.ViewportSize
		local pw, ph = 180, 160
		local px = absPos.X + absSize.X + 4
		local py = absPos.Y
		if px + pw > screenSize.X then
			px = absPos.X - pw - 4
		end
		if py + ph > screenSize.Y then
			py = screenSize.Y - ph - 4
		end
		if py < 0 then
			py = 4
		end
		if px < 0 then
			px = 4
		end
		pickerFrame.Position = UDim2.new(0, px, 0, py)
	end

	hexInput.Text = colorToHex(defaultColor)

	self:_connect(hexInput.FocusLost, function()
		local c = hexToColor(hexInput.Text)
		if c then
			currentH, currentS, currentV = Color3.toHSV(c)
			applyColor()
		else
			hexInput.Text = colorToHex(Color3.fromHSV(currentH, currentS, currentV))
		end
	end)

	local svDragging = false
	local hueDragging = false

	self:_connect(svBtn.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			svDragging = true
		end
	end)

	self:_connect(hueBtn.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			hueDragging = true
		end
	end)

	self:_connect(UserInputService.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if svDragging then
				local relX = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
				local relY = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
				currentS = 1 - relX
				currentV = 1 - relY
				applyColor()
			elseif hueDragging then
				local relY = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
				currentH = relY
				applyColor()
			end
		end
	end)

	self:_connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			svDragging = false
			hueDragging = false
		end
	end)

	local previewBtn = Instance.new("TextButton")
	previewBtn.Size = UDim2.new(1, 0, 1, 0)
	previewBtn.BackgroundTransparency = 1
	previewBtn.Text = ""
	previewBtn.ZIndex = 2
	previewBtn.Parent = preview

	self:_connect(previewBtn.MouseButton1Click, function()
		for _, otherPicker in ipairs(self._openColorPickers) do
			if otherPicker ~= pickerFrame then
				otherPicker.Visible = false
			end
		end
		pickerOpen = not pickerOpen
		pickerFrame.Visible = pickerOpen
		if pickerOpen then
			updatePickerPosition()
		end
	end)

	table.insert(self._openColorPickers, pickerFrame)

	return frame, function()
		return Color3.fromHSV(currentH, currentS, currentV)
	end
end

function UI:_createSeparator(parent)
	local sep = Instance.new("Frame")
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.BackgroundColor3 = Color3.fromRGB(35, 40, 45)
	sep.BorderSizePixel = 0
	sep.Parent = parent
end

function UI:_createInfoLabel(parent, text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 16)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(150, 160, 170)
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent
	return lbl
end

function UI:_buildVisualsTab()
	local container = self._tabContents["VISUALS"]

	local leftColumn = Instance.new("Frame")
	leftColumn.Size = UDim2.new(0.5, -4, 1, 0)
	leftColumn.BackgroundTransparency = 1
	leftColumn.AutomaticSize = Enum.AutomaticSize.Y
	leftColumn.ClipsDescendants = false
	leftColumn.Parent = container

	local leftLayout = Instance.new("UIListLayout")
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leftLayout.Padding = UDim.new(0, 10)
	leftLayout.Parent = leftColumn

	local rightColumn = Instance.new("Frame")
	rightColumn.Size = UDim2.new(0.5, -4, 1, 0)
	rightColumn.Position = UDim2.new(0.5, 4, 0, 0)
	rightColumn.BackgroundTransparency = 1
	rightColumn.AutomaticSize = Enum.AutomaticSize.Y
	rightColumn.ClipsDescendants = false
	rightColumn.Parent = container

	local rightLayout = Instance.new("UIListLayout")
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Padding = UDim.new(0, 10)
	rightLayout.Parent = rightColumn

	local espGB = self:_createGroupbox(leftColumn, "ESP General", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 0))
	espGB.AutomaticSize = Enum.AutomaticSize.Y

	self:_createCheckbox(espGB, "Enabled", false, function(v)
		self._espEnabled = v
		if not v then self:_clearESP() end
	end)

	self:_createCheckbox(espGB, "Box ESP", false, function(v)
		self._espSettings.BoxEnabled = v
	end)

	self:_createDropdown(espGB, "Box Type", {"Standard", "Corner", "Rounded", "Dashed"}, "Standard", function(v)
		self._espSettings.BoxType = v
	end)

	self:_createCheckbox(espGB, "Box Outline", true, function(v)
		self._espSettings.OutlineEnabled = v
	end)

	self:_createSeparator(espGB)

	self:_createCheckbox(espGB, "Name ESP", false, function(v)
		self._espSettings.NameEnabled = v
	end)

	self:_createCheckbox(espGB, "Distance ESP", false, function(v)
		self._espSettings.DistanceEnabled = v
	end)

	self:_createCheckbox(espGB, "Health Bar", false, function(v)
		self._espSettings.HealthBarEnabled = v
	end)

	self:_createCheckbox(espGB, "Team Check", false, function(v)
		self._espSettings.TeamCheck = v
	end)

	self:_createColorpicker(espGB, "Box Color", self._espSettings.BoxColor, function(c)
		self._espSettings.BoxColor = c
	end)

	self:_createColorpicker(espGB, "Name Color", self._espSettings.NameColor, function(c)
		self._espSettings.NameColor = c
	end)

	local skelGB = self:_createGroupbox(rightColumn, "Skeleton & Chams", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 0))
	skelGB.AutomaticSize = Enum.AutomaticSize.Y

	self:_createCheckbox(skelGB, "Skeleton", false, function(v)
		self._espSettings.SkeletonEnabled = v
	end)

	self:_createColorpicker(skelGB, "Skeleton Color", self._espSettings.SkeletonColor, function(c)
		self._espSettings.SkeletonColor = c
	end)

	self:_createSeparator(skelGB)

	self:_createCheckbox(skelGB, "Highlight Chams", false, function(v)
		self._espSettings.HighlightEnabled = v
		if not v then
			for _, obj in pairs(self._espObjects) do
				if obj._highlight then obj._highlight.Enabled = false end
			end
		end
	end)

	self:_createColorpicker(skelGB, "Fill Color", self._espSettings.HighlightFillColor, function(c)
		self._espSettings.HighlightFillColor = c
	end)

	self:_createColorpicker(skelGB, "Outline Color", self._espSettings.HighlightOutlineColor, function(c)
		self._espSettings.HighlightOutlineColor = c
	end)

	self:_createSlider(skelGB, "Fill Transparency", 0, 100, 75, function(v)
		self._espSettings.HighlightFillTransparency = v / 100
	end, "%")

	local snapGB = self:_createGroupbox(rightColumn, "Snaplines", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 0))
	snapGB.AutomaticSize = Enum.AutomaticSize.Y

	self:_createCheckbox(snapGB, "Snaplines", false, function(v)
		self._espSettings.SnaplineEnabled = v
	end)

	self:_createDropdown(snapGB, "Origin Point", {"Bottom", "Center", "Top", "Mouse"}, "Bottom", function(v)
		self._espSettings.SnaplineMode = v
	end)

	self:_createColorpicker(snapGB, "Snapline Color", self._espSettings.SnaplineColor, function(c)
		self._espSettings.SnaplineColor = c
	end)
end

function UI:_buildAimbotTab()
	local container = self._tabContents["AIMBOT"]

	local leftColumn = Instance.new("Frame")
	leftColumn.Size = UDim2.new(0.5, -4, 1, 0)
	leftColumn.BackgroundTransparency = 1
	leftColumn.AutomaticSize = Enum.AutomaticSize.Y
	leftColumn.ClipsDescendants = false
	leftColumn.Parent = container

	local leftLayout = Instance.new("UIListLayout")
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leftLayout.Padding = UDim.new(0, 10)
	leftLayout.Parent = leftColumn

	local rightColumn = Instance.new("Frame")
	rightColumn.Size = UDim2.new(0.5, -4, 1, 0)
	rightColumn.Position = UDim2.new(0.5, 4, 0, 0)
	rightColumn.BackgroundTransparency = 1
	rightColumn.AutomaticSize = Enum.AutomaticSize.Y
	rightColumn.ClipsDescendants = false
	rightColumn.Parent = container

	local rightLayout = Instance.new("UIListLayout")
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Padding = UDim.new(0, 10)
	rightLayout.Parent = rightColumn

	local aimGB = self:_createGroupbox(leftColumn, "Aimbot", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 0))
	aimGB.AutomaticSize = Enum.AutomaticSize.Y

	self:_createCheckbox(aimGB, "Enabled", false, function(v)
		self._aimbotSettings.Enabled = v
	end)

	self:_createSlider(aimGB, "FOV", 10, 500, 120, function(v)
		self._aimbotSettings.FOV = v
	end, "px")

	self:_createCheckbox(aimGB, "Show FOV Circle", true, function(v)
		self._aimbotSettings.ShowFOV = v
	end)

	self:_createSlider(aimGB, "Smoothness", 1, 50, 5, function(v)
		self._aimbotSettings.Smoothness = v
	end)

	self:_createDropdown(aimGB, "Activation Key", {"MouseButton1", "MouseButton2", "MouseButton3", "Q", "E", "X", "C", "F", "R", "T", "V", "Z"}, "MouseButton2", function(v)
		self._aimbotSettings.ActivationKey = v
	end)

	self:_createColorpicker(aimGB, "FOV Color", self._aimbotSettings.FOVColor, function(c)
		self._aimbotSettings.FOVColor = c
	end)

	local optGB = self:_createGroupbox(rightColumn, "Options", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 0))
	optGB.AutomaticSize = Enum.AutomaticSize.Y

	self:_createDropdown(optGB, "Body Aim", {"Head", "Torso", "HumanoidRootPart", "Nearest"}, "Head", function(v)
		self._aimbotSettings.BodyAim = v
	end)

	self:_createCheckbox(optGB, "Wall Check", true, function(v)
		self._aimbotSettings.WallCheck = v
	end)

	self:_createCheckbox(optGB, "Team Check", false, function(v)
		self._aimbotSettings.TeamCheck = v
	end)

	self:_createCheckbox(optGB, "Sticky Target", false, function(v)
		self._aimbotSettings.StickyTarget = v
	end)

	self:_createCheckbox(optGB, "Look At View", false, function(v)
		self._aimbotSettings.LookAtView = v
	end)

	self:_createSlider(optGB, "Prediction", 0, 200, 0, function(v)
		self._aimbotSettings.Prediction = v / 1000
	end, "ms")

	self:_createSeparator(optGB)

	self:_createCheckbox(optGB, "Triggerbot", false, function(v)
		self._aimbotSettings.TriggerbotEnabled = v
	end)

	self:_createSlider(optGB, "Triggerbot Delay", 0, 500, 50, function(v)
		self._aimbotSettings.TriggerbotDelay = v
	end, "ms")

	self:_createSlider(optGB, "Triggerbot FOV", 5, 200, 30, function(v)
		self._aimbotSettings.TriggerbotFOV = v
	end, "px")
end

function UI:_buildMiscTab()
	local container = self._tabContents["MISC"]

	local leftColumn = Instance.new("Frame")
	leftColumn.Size = UDim2.new(0.5, -4, 1, 0)
	leftColumn.BackgroundTransparency = 1
	leftColumn.AutomaticSize = Enum.AutomaticSize.Y
	leftColumn.ClipsDescendants = false
	leftColumn.Parent = container

	local leftLayout = Instance.new("UIListLayout")
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leftLayout.Padding = UDim.new(0, 10)
	leftLayout.Parent = leftColumn

	local rightColumn = Instance.new("Frame")
	rightColumn.Size = UDim2.new(0.5, -4, 1, 0)
	rightColumn.Position = UDim2.new(0.5, 4, 0, 0)
	rightColumn.BackgroundTransparency = 1
	rightColumn.AutomaticSize = Enum.AutomaticSize.Y
	rightColumn.ClipsDescendants = false
	rightColumn.Parent = container

	local rightLayout = Instance.new("UIListLayout")
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Padding = UDim.new(0, 10)
	rightLayout.Parent = rightColumn

	local moveGB = self:_createGroupbox(leftColumn, "Movement", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 0))
	moveGB.AutomaticSize = Enum.AutomaticSize.Y

	self:_createSlider(moveGB, "WalkSpeed", 0, 200, 16, function(v)
		self._miscSettings.WalkSpeed = v
	end)

	self:_createCheckbox(moveGB, "Loop WalkSpeed", false, function(v)
		self._miscSettings.LoopWalkSpeed = v
	end)

	self:_createSeparator(moveGB)

	self:_createCheckbox(moveGB, "Infinite Jump", false, function(v)
		self._miscSettings.InfiniteJump = v
	end)

	self:_createSeparator(moveGB)

	self:_createCheckbox(moveGB, "Fly (CFrame)", false, function(v)
		self._miscSettings.FlyEnabled = v
		self:_toggleFly(v)
	end)

	self:_createSlider(moveGB, "Fly Speed", 1, 300, 50, function(v)
		self._miscSettings.FlySpeed = v
	end)

	self:_createSeparator(moveGB)

	self:_createCheckbox(moveGB, "Noclip", false, function(v)
		self._miscSettings.NoclipEnabled = v
	end)

	local hitGB = self:_createGroupbox(rightColumn, "Hitbox Expander", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 0))
	hitGB.AutomaticSize = Enum.AutomaticSize.Y

	self:_createCheckbox(hitGB, "Enabled", false, function(v)
		self._miscSettings.HitboxEnabled = v
	end)

	self:_createSlider(hitGB, "Hitbox Size", 1, 50, 15, function(v)
		self._miscSettings.HitboxSize = v
	end)

	self:_createSlider(hitGB, "Transparency", 0, 100, 90, function(v)
		self._miscSettings.HitboxTransparency = v / 100
	end, "%")

	self:_createCheckbox(hitGB, "Show Hitbox", false, function(v)
		self._miscSettings.HitboxVisible = v
	end)

	self:_createDropdown(hitGB, "Target Part", {"HumanoidRootPart", "Head"}, "HumanoidRootPart", function(v)
		self._miscSettings.HitboxPart = v
	end)

	self:_createCheckbox(hitGB, "Team Check", false, function(v)
		self._miscSettings.HitboxTeamCheck = v
	end)
end

function UI:_buildInfoTab()
	local container = self._tabContents["INFO"]

	local infoGB = self:_createGroupbox(container, "Session Info", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 0))
	infoGB.AutomaticSize = Enum.AutomaticSize.Y

	local placeName = "Unknown"
	pcall(function()
		placeName = MarketplaceService:GetProductInfo(game.PlaceId).Name
	end)

	local execName = "Unknown"
	pcall(function()
		local name, ver = identifyexecutor()
		execName = name
		if ver then execName = execName .. " " .. ver end
	end)

	self:_createInfoLabel(infoGB, "Place: " .. placeName)
	self:_createInfoLabel(infoGB, "PlaceId: " .. tostring(game.PlaceId))
	self:_createInfoLabel(infoGB, "JobId: " .. tostring(game.JobId))
	self:_createInfoLabel(infoGB, "Executor: " .. execName)
	self:_createInfoLabel(infoGB, "User: " .. LocalPlayer.Name .. " (" .. LocalPlayer.DisplayName .. ")")

	self._playerCountLabel = self:_createInfoLabel(infoGB, "Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers))

	self:_connect(Players.PlayerAdded, function()
		pcall(function()
			self._playerCountLabel.Text = "Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
		end)
	end)

	self:_connect(Players.PlayerRemoving, function()
		task.defer(function()
			pcall(function()
				self._playerCountLabel.Text = "Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
			end)
		end)
	end)
end

function UI:_setupToggle()
	self:_connect(UserInputService.InputBegan, function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.F2 then
			self._visible = not self._visible
			self._screenGui.Enabled = self._visible
		end
	end)
end

function UI:_isTeammate(player)
	if not player.Team or not LocalPlayer.Team then return false end
	return player.Team == LocalPlayer.Team
end

local ESPObject = {}
ESPObject.__index = ESPObject

function ESPObject.new(player, settings)
	local self = setmetatable({}, ESPObject)
	self._player = player
	self._settings = settings
	self._highlight = nil
	self._drawings = {}
	self._skeletonLines = {}
	self._boneConnections = {
		{"Head", "UpperTorso"},
		{"UpperTorso", "LowerTorso"},
		{"UpperTorso", "LeftUpperArm"},
		{"LeftUpperArm", "LeftLowerArm"},
		{"LeftLowerArm", "LeftHand"},
		{"UpperTorso", "RightUpperArm"},
		{"RightUpperArm", "RightLowerArm"},
		{"RightLowerArm", "RightHand"},
		{"LowerTorso", "LeftUpperLeg"},
		{"LeftUpperLeg", "LeftLowerLeg"},
		{"LeftLowerLeg", "LeftFoot"},
		{"LowerTorso", "RightUpperLeg"},
		{"RightUpperLeg", "RightLowerLeg"},
		{"RightLowerLeg", "RightFoot"},
	}
	self:_createDrawings()
	return self
end

function ESPObject:_createDrawings()
	self._drawings.boxOutline = Drawing.new("Square")
	self._drawings.boxOutline.Visible = false
	self._drawings.boxOutline.Color = Color3.new(0, 0, 0)
	self._drawings.boxOutline.Thickness = 3
	self._drawings.boxOutline.Filled = false

	self._drawings.box = Drawing.new("Square")
	self._drawings.box.Visible = false
	self._drawings.box.Color = Color3.fromRGB(0, 180, 180)
	self._drawings.box.Thickness = 1
	self._drawings.box.Filled = false

	self._drawings.cornerOutlines = {}
	for _ = 1, 8 do
		local l = Drawing.new("Line")
		l.Visible = false
		l.Color = Color3.new(0, 0, 0)
		l.Thickness = 3
		table.insert(self._drawings.cornerOutlines, l)
	end

	self._drawings.cornerLines = {}
	for _ = 1, 8 do
		local l = Drawing.new("Line")
		l.Visible = false
		l.Color = Color3.fromRGB(0, 180, 180)
		l.Thickness = 1
		table.insert(self._drawings.cornerLines, l)
	end

	self._drawings.roundedOutlines = {}
	for _ = 1, 24 do
		local l = Drawing.new("Line")
		l.Visible = false
		l.Color = Color3.new(0, 0, 0)
		l.Thickness = 3
		table.insert(self._drawings.roundedOutlines, l)
	end

	self._drawings.roundedLines = {}
	for _ = 1, 24 do
		local l = Drawing.new("Line")
		l.Visible = false
		l.Color = Color3.fromRGB(0, 180, 180)
		l.Thickness = 1
		table.insert(self._drawings.roundedLines, l)
	end

	self._drawings.dashedOutlines = {}
	for _ = 1, 40 do
		local l = Drawing.new("Line")
		l.Visible = false
		l.Color = Color3.new(0, 0, 0)
		l.Thickness = 3
		table.insert(self._drawings.dashedOutlines, l)
	end

	self._drawings.dashedLines = {}
	for _ = 1, 40 do
		local l = Drawing.new("Line")
		l.Visible = false
		l.Color = Color3.fromRGB(0, 180, 180)
		l.Thickness = 1
		table.insert(self._drawings.dashedLines, l)
	end

	self._drawings.nameLabel = Drawing.new("Text")
	self._drawings.nameLabel.Visible = false
	self._drawings.nameLabel.Color = Color3.new(1, 1, 1)
	self._drawings.nameLabel.Size = 13
	self._drawings.nameLabel.Center = true
	self._drawings.nameLabel.Outline = true
	self._drawings.nameLabel.OutlineColor = Color3.new(0, 0, 0)
	self._drawings.nameLabel.Font = 2

	self._drawings.distLabel = Drawing.new("Text")
	self._drawings.distLabel.Visible = false
	self._drawings.distLabel.Color = Color3.fromRGB(200, 200, 200)
	self._drawings.distLabel.Size = 12
	self._drawings.distLabel.Center = true
	self._drawings.distLabel.Outline = true
	self._drawings.distLabel.OutlineColor = Color3.new(0, 0, 0)
	self._drawings.distLabel.Font = 2

	self._drawings.healthBarBgOutline = Drawing.new("Square")
	self._drawings.healthBarBgOutline.Visible = false
	self._drawings.healthBarBgOutline.Color = Color3.new(0, 0, 0)
	self._drawings.healthBarBgOutline.Thickness = 1
	self._drawings.healthBarBgOutline.Filled = true

	self._drawings.healthBarBg = Drawing.new("Square")
	self._drawings.healthBarBg.Visible = false
	self._drawings.healthBarBg.Color = Color3.fromRGB(30, 30, 30)
	self._drawings.healthBarBg.Thickness = 1
	self._drawings.healthBarBg.Filled = true

	self._drawings.healthBarFill = Drawing.new("Square")
	self._drawings.healthBarFill.Visible = false
	self._drawings.healthBarFill.Color = Color3.fromRGB(0, 255, 0)
	self._drawings.healthBarFill.Thickness = 1
	self._drawings.healthBarFill.Filled = true

	self._drawings.snapline = Drawing.new("Line")
	self._drawings.snapline.Visible = false
	self._drawings.snapline.Color = Color3.fromRGB(0, 180, 180)
	self._drawings.snapline.Thickness = 1

	for _ = 1, #self._boneConnections do
		local l = Drawing.new("Line")
		l.Visible = false
		l.Color = Color3.new(1, 1, 1)
		l.Thickness = 1
		table.insert(self._skeletonLines, l)
	end
end

function ESPObject:_hideAllBox()
	self._drawings.box.Visible = false
	self._drawings.boxOutline.Visible = false
	for _, l in ipairs(self._drawings.cornerOutlines) do l.Visible = false end
	for _, l in ipairs(self._drawings.cornerLines) do l.Visible = false end
	for _, l in ipairs(self._drawings.roundedOutlines) do l.Visible = false end
	for _, l in ipairs(self._drawings.roundedLines) do l.Visible = false end
	for _, l in ipairs(self._drawings.dashedOutlines) do l.Visible = false end
	for _, l in ipairs(self._drawings.dashedLines) do l.Visible = false end
end

function ESPObject:_drawStandard(bx, by, bw, bh)
	if self._settings.OutlineEnabled then
		self._drawings.boxOutline.Size = Vector2.new(bw, bh)
		self._drawings.boxOutline.Position = Vector2.new(bx, by)
		self._drawings.boxOutline.Visible = true
	end
	self._drawings.box.Size = Vector2.new(bw, bh)
	self._drawings.box.Position = Vector2.new(bx, by)
	self._drawings.box.Color = self._settings.BoxColor
	self._drawings.box.Visible = true
end

function ESPObject:_drawCorner(bx, by, bw, bh)
	local cl = bw * 0.25
	local ch = bh * 0.25
	local pts = {
		{Vector2.new(bx, by), Vector2.new(bx + cl, by)},
		{Vector2.new(bx, by), Vector2.new(bx, by + ch)},
		{Vector2.new(bx + bw, by), Vector2.new(bx + bw - cl, by)},
		{Vector2.new(bx + bw, by), Vector2.new(bx + bw, by + ch)},
		{Vector2.new(bx, by + bh), Vector2.new(bx + cl, by + bh)},
		{Vector2.new(bx, by + bh), Vector2.new(bx, by + bh - ch)},
		{Vector2.new(bx + bw, by + bh), Vector2.new(bx + bw - cl, by + bh)},
		{Vector2.new(bx + bw, by + bh), Vector2.new(bx + bw, by + bh - ch)},
	}
	for i = 1, 8 do
		if self._settings.OutlineEnabled then
			self._drawings.cornerOutlines[i].From = pts[i][1]
			self._drawings.cornerOutlines[i].To = pts[i][2]
			self._drawings.cornerOutlines[i].Visible = true
		end
		self._drawings.cornerLines[i].From = pts[i][1]
		self._drawings.cornerLines[i].To = pts[i][2]
		self._drawings.cornerLines[i].Color = self._settings.BoxColor
		self._drawings.cornerLines[i].Visible = true
	end
end

function ESPObject:_drawRounded(bx, by, bw, bh)
	local r = math.min(bw, bh) * 0.15
	local segsPerCorner = 5
	local idx = 1
	local corners = {
		{cx = bx + r, cy = by + r, sa = math.pi, ea = math.pi * 1.5},
		{cx = bx + bw - r, cy = by + r, sa = math.pi * 1.5, ea = math.pi * 2},
		{cx = bx + bw - r, cy = by + bh - r, sa = 0, ea = math.pi * 0.5},
		{cx = bx + r, cy = by + bh - r, sa = math.pi * 0.5, ea = math.pi},
	}
	for _, c in ipairs(corners) do
		for s = 0, segsPerCorner - 1 do
			local a1 = c.sa + (c.ea - c.sa) * (s / segsPerCorner)
			local a2 = c.sa + (c.ea - c.sa) * ((s + 1) / segsPerCorner)
			local from = Vector2.new(c.cx + math.cos(a1) * r, c.cy + math.sin(a1) * r)
			local to = Vector2.new(c.cx + math.cos(a2) * r, c.cy + math.sin(a2) * r)
			if idx <= #self._drawings.roundedLines then
				if self._settings.OutlineEnabled then
					self._drawings.roundedOutlines[idx].From = from
					self._drawings.roundedOutlines[idx].To = to
					self._drawings.roundedOutlines[idx].Visible = true
				end
				self._drawings.roundedLines[idx].From = from
				self._drawings.roundedLines[idx].To = to
				self._drawings.roundedLines[idx].Color = self._settings.BoxColor
				self._drawings.roundedLines[idx].Visible = true
				idx = idx + 1
			end
		end
	end
	local sides = {
		{Vector2.new(bx + r, by), Vector2.new(bx + bw - r, by)},
		{Vector2.new(bx + bw, by + r), Vector2.new(bx + bw, by + bh - r)},
		{Vector2.new(bx + bw - r, by + bh), Vector2.new(bx + r, by + bh)},
		{Vector2.new(bx, by + bh - r), Vector2.new(bx, by + r)},
	}
	for _, side in ipairs(sides) do
		if idx <= #self._drawings.roundedLines then
			if self._settings.OutlineEnabled then
				self._drawings.roundedOutlines[idx].From = side[1]
				self._drawings.roundedOutlines[idx].To = side[2]
				self._drawings.roundedOutlines[idx].Visible = true
			end
			self._drawings.roundedLines[idx].From = side[1]
			self._drawings.roundedLines[idx].To = side[2]
			self._drawings.roundedLines[idx].Color = self._settings.BoxColor
			self._drawings.roundedLines[idx].Visible = true
			idx = idx + 1
		end
	end
	for i = idx, #self._drawings.roundedLines do
		self._drawings.roundedLines[i].Visible = false
		if i <= #self._drawings.roundedOutlines then
			self._drawings.roundedOutlines[i].Visible = false
		end
	end
end

function ESPObject:_drawDashed(bx, by, bw, bh)
	local segs = 10
	local gap = 0.4
	local idx = 1
	local sides = {
		{Vector2.new(bx, by), Vector2.new(bx + bw, by)},
		{Vector2.new(bx + bw, by), Vector2.new(bx + bw, by + bh)},
		{Vector2.new(bx + bw, by + bh), Vector2.new(bx, by + bh)},
		{Vector2.new(bx, by + bh), Vector2.new(bx, by)},
	}
	for _, side in ipairs(sides) do
		local diff = side[2] - side[1]
		for s = 0, segs - 1 do
			local t0 = s / segs
			local t1 = math.min((s + 1 - gap) / segs, 1)
			local from = side[1] + diff * t0
			local to = side[1] + diff * t1
			if idx <= #self._drawings.dashedLines then
				if self._settings.OutlineEnabled then
					self._drawings.dashedOutlines[idx].From = from
					self._drawings.dashedOutlines[idx].To = to
					self._drawings.dashedOutlines[idx].Visible = true
				end
				self._drawings.dashedLines[idx].From = from
				self._drawings.dashedLines[idx].To = to
				self._drawings.dashedLines[idx].Color = self._settings.BoxColor
				self._drawings.dashedLines[idx].Visible = true
				idx = idx + 1
			end
		end
	end
	for i = idx, #self._drawings.dashedLines do
		self._drawings.dashedLines[i].Visible = false
		if i <= #self._drawings.dashedOutlines then
			self._drawings.dashedOutlines[i].Visible = false
		end
	end
end

function ESPObject:update(camera, localPlayer, isTeammate)
	if isTeammate then self:hide() return end

	local char = self._player.Character
	if not char then self:hide() return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")

	if not hum or not root or not head or hum.Health <= 0 then self:hide() return end

	local lChar = localPlayer.Character
	if not lChar then self:hide() return end
	local lRoot = lChar:FindFirstChild("HumanoidRootPart")
	if not lRoot then self:hide() return end

	local dist = (root.Position - lRoot.Position).Magnitude
	local sp, onScreen = camera:WorldToViewportPoint(root.Position)

	if not onScreen then self:hide() return end

	local hsp = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
	local fsp = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

	local bh = math.abs(hsp.Y - fsp.Y)
	local bw = bh * 0.6
	local bx = sp.X - bw / 2
	local by = hsp.Y

	self:_hideAllBox()

	if self._settings.BoxEnabled then
		local bt = self._settings.BoxType
		if bt == "Standard" then self:_drawStandard(bx, by, bw, bh)
		elseif bt == "Corner" then self:_drawCorner(bx, by, bw, bh)
		elseif bt == "Rounded" then self:_drawRounded(bx, by, bw, bh)
		elseif bt == "Dashed" then self:_drawDashed(bx, by, bw, bh)
		end
	end

	if self._settings.NameEnabled then
		self._drawings.nameLabel.Text = self._player.DisplayName
		self._drawings.nameLabel.Position = Vector2.new(sp.X, by - 16)
		self._drawings.nameLabel.Color = self._settings.NameColor
		self._drawings.nameLabel.Visible = true
	else
		self._drawings.nameLabel.Visible = false
	end

	if self._settings.DistanceEnabled then
		self._drawings.distLabel.Text = string.format("[%dm]", math.floor(dist))
		self._drawings.distLabel.Position = Vector2.new(sp.X, fsp.Y + 2)
		self._drawings.distLabel.Color = self._settings.DistanceColor
		self._drawings.distLabel.Visible = true
	else
		self._drawings.distLabel.Visible = false
	end

	if self._settings.HealthBarEnabled then
		local hf = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		local bwid = 3
		local barX = bx - bwid - 4

		self._drawings.healthBarBgOutline.Position = Vector2.new(barX - 1, by - 1)
		self._drawings.healthBarBgOutline.Size = Vector2.new(bwid + 2, bh + 2)
		self._drawings.healthBarBgOutline.Visible = true

		self._drawings.healthBarBg.Position = Vector2.new(barX, by)
		self._drawings.healthBarBg.Size = Vector2.new(bwid, bh)
		self._drawings.healthBarBg.Visible = true

		local fh = bh * hf
		self._drawings.healthBarFill.Position = Vector2.new(barX, by + bh - fh)
		self._drawings.healthBarFill.Size = Vector2.new(bwid, fh)
		self._drawings.healthBarFill.Color = Color3.fromRGB(math.floor((1 - hf) * 255), math.floor(hf * 255), 0)
		self._drawings.healthBarFill.Visible = true
	else
		self._drawings.healthBarBgOutline.Visible = false
		self._drawings.healthBarBg.Visible = false
		self._drawings.healthBarFill.Visible = false
	end

	if self._settings.SnaplineEnabled then
		local vp = camera.ViewportSize
		local fx, fy
		local m = self._settings.SnaplineMode
		if m == "Bottom" then fx, fy = vp.X / 2, vp.Y
		elseif m == "Top" then fx, fy = vp.X / 2, 0
		elseif m == "Center" then fx, fy = vp.X / 2, vp.Y / 2
		elseif m == "Mouse" then
			local mp = UserInputService:GetMouseLocation()
			fx, fy = mp.X, mp.Y
		else fx, fy = vp.X / 2, vp.Y end
		self._drawings.snapline.From = Vector2.new(fx, fy)
		self._drawings.snapline.To = Vector2.new(sp.X, fsp.Y)
		self._drawings.snapline.Color = self._settings.SnaplineColor
		self._drawings.snapline.Visible = true
	else
		self._drawings.snapline.Visible = false
	end

	if self._settings.SkeletonEnabled then
		self:_updateSkeleton(char, camera)
	else
		for _, l in ipairs(self._skeletonLines) do l.Visible = false end
	end

	if self._settings.HighlightEnabled then
		if not self._highlight or not self._highlight.Parent then
			self._highlight = Instance.new("Highlight")
			self._highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			self._highlight.Adornee = char
			self._highlight.Parent = char
		end
		self._highlight.FillColor = self._settings.HighlightFillColor
		self._highlight.OutlineColor = self._settings.HighlightOutlineColor
		self._highlight.FillTransparency = self._settings.HighlightFillTransparency
		self._highlight.OutlineTransparency = self._settings.HighlightOutlineTransparency
		self._highlight.Adornee = char
		self._highlight.Enabled = true
	else
		if self._highlight then self._highlight.Enabled = false end
	end
end

function ESPObject:_updateSkeleton(char, camera)
	local r6 = {
		Head="Head",UpperTorso="Torso",LowerTorso="Torso",
		LeftUpperArm="Left Arm",LeftLowerArm="Left Arm",LeftHand="Left Arm",
		RightUpperArm="Right Arm",RightLowerArm="Right Arm",RightHand="Right Arm",
		LeftUpperLeg="Left Leg",LeftLowerLeg="Left Leg",LeftFoot="Left Leg",
		RightUpperLeg="Right Leg",RightLowerLeg="Right Leg",RightFoot="Right Leg",
	}
	local ns = {
		"Head","UpperTorso","LowerTorso",
		"LeftUpperArm","LeftLowerArm","LeftHand",
		"RightUpperArm","RightLowerArm","RightHand",
		"LeftUpperLeg","LeftLowerLeg","LeftFoot",
		"RightUpperLeg","RightLowerLeg","RightFoot",
	}
	local pos = {}
	local ok = true
	for _, n in ipairs(ns) do
		local p = char:FindFirstChild(n) or char:FindFirstChild(r6[n] or "")
		if p then
			local s, v = camera:WorldToViewportPoint(p.Position)
			if v then pos[n] = Vector2.new(s.X, s.Y) else ok = false break end
		else ok = false break end
	end
	if not ok then
		for _, l in ipairs(self._skeletonLines) do l.Visible = false end
		return
	end
	for i, c in ipairs(self._boneConnections) do
		local f, t = pos[c[1]], pos[c[2]]
		if f and t then
			self._skeletonLines[i].From = f
			self._skeletonLines[i].To = t
			self._skeletonLines[i].Color = self._settings.SkeletonColor
			self._skeletonLines[i].Visible = true
		else
			self._skeletonLines[i].Visible = false
		end
	end
end

function ESPObject:hide()
	self._drawings.box.Visible = false
	self._drawings.boxOutline.Visible = false
	self._drawings.nameLabel.Visible = false
	self._drawings.distLabel.Visible = false
	self._drawings.healthBarBgOutline.Visible = false
	self._drawings.healthBarBg.Visible = false
	self._drawings.healthBarFill.Visible = false
	self._drawings.snapline.Visible = false
	for _, l in ipairs(self._drawings.cornerOutlines) do l.Visible = false end
	for _, l in ipairs(self._drawings.cornerLines) do l.Visible = false end
	for _, l in ipairs(self._drawings.roundedOutlines) do l.Visible = false end
	for _, l in ipairs(self._drawings.roundedLines) do l.Visible = false end
	for _, l in ipairs(self._drawings.dashedOutlines) do l.Visible = false end
	for _, l in ipairs(self._drawings.dashedLines) do l.Visible = false end
	for _, l in ipairs(self._skeletonLines) do l.Visible = false end
	if self._highlight then self._highlight.Enabled = false end
end

function ESPObject:destroy()
	local function rm(d) pcall(function() d:Remove() end) end
	rm(self._drawings.box)
	rm(self._drawings.boxOutline)
	rm(self._drawings.nameLabel)
	rm(self._drawings.distLabel)
	rm(self._drawings.healthBarBgOutline)
	rm(self._drawings.healthBarBg)
	rm(self._drawings.healthBarFill)
	rm(self._drawings.snapline)
	for _, l in ipairs(self._drawings.cornerOutlines) do rm(l) end
	for _, l in ipairs(self._drawings.cornerLines) do rm(l) end
	for _, l in ipairs(self._drawings.roundedOutlines) do rm(l) end
	for _, l in ipairs(self._drawings.roundedLines) do rm(l) end
	for _, l in ipairs(self._drawings.dashedOutlines) do rm(l) end
	for _, l in ipairs(self._drawings.dashedLines) do rm(l) end
	for _, l in ipairs(self._skeletonLines) do rm(l) end
	if self._highlight then pcall(function() self._highlight:Destroy() end) end
	self._drawings = {}
	self._skeletonLines = {}
end

function UI:_setupESP()
	local function onAdded(p)
		if p == LocalPlayer then return end
		self._espObjects[p] = ESPObject.new(p, self._espSettings)
	end
	local function onRemoved(p)
		if self._espObjects[p] then
			self._espObjects[p]:destroy()
			self._espObjects[p] = nil
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then onAdded(p) end
	end
	self:_connect(Players.PlayerAdded, onAdded)
	self:_connect(Players.PlayerRemoving, onRemoved)

	self:_connect(RunService.RenderStepped, function()
		if not self._espEnabled then
			for _, o in pairs(self._espObjects) do o:hide() end
			return
		end
		local cam = Workspace.CurrentCamera
		for p, o in pairs(self._espObjects) do
			local tm = self._espSettings.TeamCheck and self:_isTeammate(p)
			o:update(cam, LocalPlayer, tm)
		end
	end)
end

function UI:_clearESP()
	for _, o in pairs(self._espObjects) do o:hide() end
end

function UI:_getClosestPlayerToCenter(camera, fovRadius)
	local centerScreen = camera.ViewportSize / 2
	local best, bestD = nil, fovRadius
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LocalPlayer then continue end
		if self._aimbotSettings.TeamCheck and self:_isTeammate(p) then continue end
		if not p.Character then continue end
		local h = p.Character:FindFirstChildOfClass("Humanoid")
		if not h or h.Health <= 0 then continue end
		local targetParts = {}
		for _, partName in ipairs({"Head", "UpperTorso", "Torso", "HumanoidRootPart"}) do
			local part = p.Character:FindFirstChild(partName)
			if part then
				table.insert(targetParts, part)
			end
		end
		for _, part in ipairs(targetParts) do
			local sp, onScreen = camera:WorldToViewportPoint(part.Position)
			if not onScreen then continue end
			local dist = (Vector2.new(sp.X, sp.Y) - centerScreen).Magnitude
			if dist < bestD then
				if self._aimbotSettings.WallCheck and not self:_isVisible(camera, part) then continue end
				bestD = dist
				best = p
			end
		end
	end
	return best, bestD
end

function UI:_setupAimbot()
	self._fovCircle = Drawing.new("Circle")
	self._fovCircle.Visible = false
	self._fovCircle.Color = Color3.fromRGB(0, 180, 180)
	self._fovCircle.Thickness = 1
	self._fovCircle.Filled = false
	self._fovCircle.NumSides = 64
	self._fovCircle.Transparency = 0.8

	local keyMap = {
		MouseButton1 = Enum.UserInputType.MouseButton1,
		MouseButton2 = Enum.UserInputType.MouseButton2,
		MouseButton3 = Enum.UserInputType.MouseButton3,
		Q = Enum.KeyCode.Q, E = Enum.KeyCode.E, X = Enum.KeyCode.X,
		C = Enum.KeyCode.C, F = Enum.KeyCode.F, R = Enum.KeyCode.R,
		T = Enum.KeyCode.T, V = Enum.KeyCode.V, Z = Enum.KeyCode.Z,
	}
	local mouseKeys = {MouseButton1=true, MouseButton2=true, MouseButton3=true}

	self:_connect(UserInputService.InputBegan, function(input, gpe)
		if gpe then return end
		if not self._aimbotSettings.Enabled then return end
		local k = self._aimbotSettings.ActivationKey
		local m = keyMap[k]
		if not m then return end
		if mouseKeys[k] then
			if input.UserInputType == m then self._aimbotState.isActive = true end
		else
			if input.KeyCode == m then self._aimbotState.isActive = true end
		end
	end)

	self:_connect(UserInputService.InputEnded, function(input)
		if not self._aimbotSettings.Enabled then return end
		local k = self._aimbotSettings.ActivationKey
		local m = keyMap[k]
		if not m then return end
		local released = false
		if mouseKeys[k] then
			released = input.UserInputType == m
		else
			released = input.KeyCode == m
		end
		if released then
			self._aimbotState.isActive = false
			if not self._aimbotSettings.StickyTarget then
				self._aimbotState.currentTarget = nil
			end
		end
	end)

	self:_connect(RunService.RenderStepped, function()
		local cam = Workspace.CurrentCamera
		local mousePos = UserInputService:GetMouseLocation()

		if self._aimbotSettings.Enabled and self._aimbotSettings.ShowFOV then
			self._fovCircle.Position = mousePos
			self._fovCircle.Radius = self._aimbotSettings.FOV
			self._fovCircle.Color = self._aimbotSettings.FOVColor
			self._fovCircle.Visible = true
		else
			self._fovCircle.Visible = false
		end

		if self._aimbotSettings.Enabled and self._aimbotSettings.TriggerbotEnabled then
			self:_processTriggerbotIndependent(cam)
		end

		if not self._aimbotSettings.Enabled or not self._aimbotState.isActive then return end

		local target = self:_getAimbotTarget(cam, mousePos)
		if not target then
			self._aimbotState.currentTarget = nil
			return
		end
		self._aimbotState.currentTarget = target

		local aimPart = self:_getAimPart(target)
		if not aimPart then return end

		local aimPos = aimPart.Position
		if self._aimbotSettings.Prediction > 0 then
			local vel = aimPart.AssemblyLinearVelocity or Vector3.zero
			aimPos = aimPos + vel * self._aimbotSettings.Prediction
		end

		local smooth = math.max(self._aimbotSettings.Smoothness, 1)
		local alpha = 1 / smooth

		if self._aimbotSettings.LookAtView then
			local cf = CFrame.lookAt(cam.CFrame.Position, aimPos)
			cam.CFrame = cam.CFrame:Lerp(cf, alpha)
		else
			local sp = cam:WorldToViewportPoint(aimPos)
			local targetScreen = Vector2.new(sp.X, sp.Y)
			local diff = targetScreen - mousePos
			local moveBy = diff * alpha
			mousemoverel(moveBy.X, moveBy.Y)
		end
	end)
end

function UI:_processTriggerbotIndependent(camera)
	local now = tick()
	local delay = self._aimbotSettings.TriggerbotDelay / 1000
	if now - self._aimbotState.triggerbotCooldown < delay then return end

	local tbFOV = self._aimbotSettings.TriggerbotFOV
	local centerScreen = camera.ViewportSize / 2

	local closestPlayer, closestDist = nil, tbFOV
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LocalPlayer then continue end
		if self._aimbotSettings.TeamCheck and self:_isTeammate(p) then continue end
		if not p.Character then continue end
		local h = p.Character:FindFirstChildOfClass("Humanoid")
		if not h or h.Health <= 0 then continue end

		local partsToCheck = {"Head", "UpperTorso", "Torso", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"}
		for _, partName in ipairs(partsToCheck) do
			local part = p.Character:FindFirstChild(partName)
			if not part then continue end
			local sp, onScreen = camera:WorldToViewportPoint(part.Position)
			if not onScreen then continue end
			local screenPos = Vector2.new(sp.X, sp.Y)
			local dist = (screenPos - centerScreen).Magnitude

			local partScreenSize = 0
			pcall(function()
				local topPos = camera:WorldToViewportPoint(part.Position + Vector3.new(0, part.Size.Y / 2, 0))
				local bottomPos = camera:WorldToViewportPoint(part.Position - Vector3.new(0, part.Size.Y / 2, 0))
				partScreenSize = math.abs(topPos.Y - bottomPos.Y) / 2
			end)

			local effectiveRadius = math.max(partScreenSize, 5)
			if dist <= effectiveRadius + tbFOV * 0.3 and dist < closestDist then
				if self._aimbotSettings.WallCheck then
					if not self:_isVisible(camera, part) then continue end
				end
				closestDist = dist
				closestPlayer = p
				break
			end
		end
	end

	if closestPlayer then
		self._aimbotState.triggerbotCooldown = now
		task.spawn(function()
			mouse1press()
			task.wait(0.03 + math.random() * 0.02)
			mouse1release()
		end)
	end
end

function UI:_getAimbotTarget(camera, mousePos)
	if self._aimbotSettings.StickyTarget and self._aimbotState.currentTarget then
		local t = self._aimbotState.currentTarget
		if t.Character then
			local h = t.Character:FindFirstChildOfClass("Humanoid")
			if h and h.Health > 0 then
				local ap = self:_getAimPart(t)
				if ap then
					local s, v = camera:WorldToViewportPoint(ap.Position)
					if v then
						local d = (Vector2.new(s.X, s.Y) - mousePos).Magnitude
						if d <= self._aimbotSettings.FOV then
							if not self._aimbotSettings.WallCheck or self:_isVisible(camera, ap) then
								return t
							end
						end
					end
				end
			end
		end
		self._aimbotState.currentTarget = nil
	end

	local best, bestD = nil, self._aimbotSettings.FOV
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LocalPlayer then continue end
		if self._aimbotSettings.TeamCheck and self:_isTeammate(p) then continue end
		if not p.Character then continue end
		local h = p.Character:FindFirstChildOfClass("Humanoid")
		if not h or h.Health <= 0 then continue end
		local ap = self:_getAimPart(p)
		if not ap then continue end
		local s, v = camera:WorldToViewportPoint(ap.Position)
		if not v then continue end
		local d = (Vector2.new(s.X, s.Y) - mousePos).Magnitude
		if d > bestD then continue end
		if self._aimbotSettings.WallCheck and not self:_isVisible(camera, ap) then continue end
		bestD = d
		best = p
	end
	return best
end

function UI:_getAimPart(player)
	if not player.Character then return nil end
	local ba = self._aimbotSettings.BodyAim
	if ba == "Nearest" then
		local cam = Workspace.CurrentCamera
		local mousePos = UserInputService:GetMouseLocation()
		local best, bestD = nil, math.huge
		for _, p in ipairs(player.Character:GetChildren()) do
			if p:IsA("BasePart") then
				local s, v = cam:WorldToViewportPoint(p.Position)
				if v then
					local d = (Vector2.new(s.X, s.Y) - mousePos).Magnitude
					if d < bestD then bestD = d; best = p end
				end
			end
		end
		return best
	end
	local name = ba
	if ba == "Torso" then
		name = player.Character:FindFirstChild("UpperTorso") and "UpperTorso" or "Torso"
	end
	return player.Character:FindFirstChild(name)
end

function UI:_isVisible(camera, part)
	local origin = camera.CFrame.Position
	local dir = part.Position - origin
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {}
	if LocalPlayer.Character then table.insert(ex, LocalPlayer.Character) end
	if part.Parent then table.insert(ex, part.Parent) end
	rp.FilterDescendantsInstances = ex
	return Workspace:Raycast(origin, dir, rp) == nil
end

function UI:_cleanupFly()
	pcall(function()
		if self._flyState.cfLoop then
			self._flyState.cfLoop:Disconnect()
			self._flyState.cfLoop = nil
		end
	end)
	pcall(function()
		local char = LocalPlayer.Character
		if char then
			local head = char:FindFirstChild("Head")
			if head then
				head.Anchored = false
			end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.PlatformStand = false
			end
		end
	end)
end

function UI:_toggleFly(enabled)
	if enabled then
		self._flyState.active = true
		pcall(function()
			local char = LocalPlayer.Character
			if not char then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			local head = char:WaitForChild("Head")
			if not hum or not head then return end
			self:_cleanupFly()
			hum.PlatformStand = true
			head.Anchored = true
			self._flyState.cfLoop = RunService.Heartbeat:Connect(function(deltaTime)
				pcall(function()
					local c = LocalPlayer.Character
					if not c then return end
					local h = c:FindFirstChildOfClass("Humanoid")
					local hd = c:FindFirstChild("Head")
					if not h or not hd then return end
					local speed = self._miscSettings.FlySpeed
					local moveDirection = h.MoveDirection * (speed * deltaTime)
					local headCFrame = hd.CFrame
					local camera = Workspace.CurrentCamera
					local cameraCFrame = camera.CFrame
					local cameraOffset = headCFrame:ToObjectSpace(cameraCFrame).Position
					cameraCFrame = cameraCFrame * CFrame.new(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)
					local cameraPosition = cameraCFrame.Position
					local headPosition = headCFrame.Position
					local objectSpaceVelocity = CFrame.new(cameraPosition, Vector3.new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)
					hd.CFrame = CFrame.new(headPosition) * (cameraCFrame - cameraPosition) * CFrame.new(objectSpaceVelocity)
				end)
			end)
			table.insert(self._connections, self._flyState.cfLoop)
		end)
	else
		self._flyState.active = false
		self:_cleanupFly()
	end
end

function UI:_setupMisc()
	self:_connect(UserInputService.JumpRequest, function()
		if self._miscSettings.InfiniteJump then
			pcall(function()
				local char = LocalPlayer.Character
				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
				end
			end)
		end
	end)

	local function onCharacterAdded(char)
		if self._flyState.active then
			task.wait(0.5)
			self:_toggleFly(false)
			task.wait(0.1)
			self:_toggleFly(true)
		end
	end

	self:_connect(LocalPlayer.CharacterAdded, onCharacterAdded)

	self:_connect(RunService.Stepped, function()
		if self._miscSettings.NoclipEnabled then
			pcall(function()
				local char = LocalPlayer.Character
				if not char then return end
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end)
		end
	end)

	self:_connect(RunService.Heartbeat, function()
		if self._miscSettings.LoopWalkSpeed then
			pcall(function()
				local char = LocalPlayer.Character
				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then hum.WalkSpeed = self._miscSettings.WalkSpeed end
				end
			end)
		end

		if self._miscSettings.HitboxEnabled then
			for _, p in ipairs(Players:GetPlayers()) do
				if p == LocalPlayer then continue end
				if self._miscSettings.HitboxTeamCheck and self:_isTeammate(p) then continue end
				pcall(function()
					if p.Character then
						local part = p.Character:FindFirstChild(self._miscSettings.HitboxPart)
						if part then
							local sz = self._miscSettings.HitboxSize
							part.Size = Vector3.new(sz, sz, sz)
							part.CanCollide = false
							if self._miscSettings.HitboxVisible then
								part.Transparency = self._miscSettings.HitboxTransparency
								part.BrickColor = BrickColor.new("Really black")
								part.Material = Enum.Material.Neon
							else
								part.Transparency = 1
							end
						end
					end
				end)
			end
		else
			for _, p in ipairs(Players:GetPlayers()) do
				if p == LocalPlayer then continue end
				pcall(function()
					if p.Character then
						local part = p.Character:FindFirstChild(self._miscSettings.HitboxPart)
						if part then
							if self._miscSettings.HitboxPart == "HumanoidRootPart" then
								part.Size = Vector3.new(2, 2, 1)
							else
								part.Size = Vector3.new(1.2, 1.2, 1.2)
							end
							part.Transparency = 1
							part.CanCollide = false
						end
					end
				end)
			end
		end
	end)
end

function UI:destroy()
	for _, c in ipairs(self._connections) do pcall(function() c:Disconnect() end) end
	for _, o in pairs(self._espObjects) do o:destroy() end
	if self._fovCircle then pcall(function() self._fovCircle:Remove() end) end
	self:_cleanupFly()
	for _, pf in ipairs(self._openColorPickers) do
		pcall(function() pf:Destroy() end)
	end
	pcall(function() self._screenGui:Destroy() end)
	self._connections = {}
	self._espObjects = {}
end

if getgenv().BlatantUI then
	pcall(function() getgenv().BlatantUI:destroy() end)
end

local blatantUI = UI.new()
getgenv().BlatantUI = blatantUI

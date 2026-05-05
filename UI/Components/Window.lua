local type = type
local pcall = pcall
local setmetatable = setmetatable

return function(Library, TabComponent)
	local Window = {}
	Window.__index = Window

	local Utilities = Library.Utilities
	local Theme = Library.Theme
	local Input = Library.Input
	local Animation = Library.Animation
	local Environment = Library.Environment

	function Window.New(options)
		options = options or {}
		
		local self = setmetatable({
			Title = options.Title or "Window",
			Size = options.Size or UDim2.fromOffset(650, 450),
			Tabs = {},
			ActiveTab = nil,
			Elements = {},
			IsDragging = false,
			DragOffset = Vector2.new(0, 0)
		}, Window)

		self:Build()
		return self
	end

	function Window:Build()
		local uiRoot = Library.GetUIRoot()
		if not uiRoot then return end

		-- Main container with glassmorphism (semi-transparent + shadow)
		local mainFrame = Utilities.CreateInstance("Frame", {
			Name = "MainFrame",
			Size = self.Size,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Theme.GetColor("Background"),
			BackgroundTransparency = Theme.GetTransparency("Background") == 0 and 0.3 or Theme.GetTransparency("Background"),
			BorderSizePixel = 0,
			Parent = uiRoot
		})
		
		if Library.Acrylic then
			self.AcrylicEffect = Library.Acrylic.new(mainFrame, false)
		end
		
		Utilities.CreateInstance("UICorner", {
			CornerRadius = UDim.new(0, Theme.GetRounding("Medium")),
			Parent = mainFrame
		})
		
		Utilities.CreateInstance("UIStroke", {
			Color = Theme.GetColor("Border"),
			Thickness = Theme.GetBorderWidth("Default"),
			Transparency = 0.5,
			Parent = mainFrame
		})

		-- Drop shadow
		local shadow = Utilities.CreateInstance("ImageLabel", {
			Name = "Shadow",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 40, 1, 40),
			BackgroundTransparency = 1,
			Image = "rbxassetid://6015536815",
			ImageColor3 = Theme.GetColor("Shadow"),
			ImageTransparency = Theme.GetTransparency("Shadow"),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(15, 15, 285, 285),
			ZIndex = -1,
			Parent = mainFrame
		})

		-- Sidebar
		local sidebar = Utilities.CreateInstance("Frame", {
			Name = "Sidebar",
			Size = UDim2.new(0, 150, 1, -10),
			Position = UDim2.fromOffset(5, 5),
			BackgroundColor3 = Theme.GetColor("Surface"),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Parent = mainFrame
		})

		Utilities.CreateInstance("UICorner", {
			CornerRadius = UDim.new(0, Theme.GetRounding("Medium")),
			Parent = sidebar
		})

		-- Title Container inside Sidebar
		local titleContainer = Utilities.CreateInstance("Frame", {
			Name = "TitleContainer",
			Size = UDim2.new(1, 0, 0, 45),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Parent = sidebar
		})

		local titleLabel = Utilities.CreateInstance("TextLabel", {
			Name = "Title",
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Text = self.Title,
			RichText = true,
			TextColor3 = Theme.GetColor("Text"),
			Font = Theme.GetFont("Bold"),
			TextSize = Theme.GetTextSize("Header"),
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = titleContainer
		})

		-- Sidebar content
		local tabContainer = Utilities.CreateInstance("ScrollingFrame", {
			Name = "TabContainer",
			Size = UDim2.new(1, -10, 1, -50),
			Position = UDim2.fromOffset(5, 45),
			BackgroundTransparency = 1,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Parent = sidebar
		})

		local tabList = Utilities.CreateInstance("Frame", {
			Name = "TabList",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Parent = tabContainer
		})

		local tabLayout = Utilities.CreateInstance("UIListLayout", {
			Padding = UDim.new(0, Theme.GetSpacing("Small")),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = tabList
		})
		
		local activeTabBackground = Utilities.CreateInstance("Frame", {
			Name = "ActiveTabBackground",
			Size = UDim2.new(1, 0, 0, 32),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Theme.GetColor("SurfaceActive"),
			BackgroundTransparency = 1, -- Start transparent until a tab is selected
			BorderSizePixel = 0,
			ZIndex = 0,
			Parent = tabContainer
		})
		
		Utilities.CreateInstance("UICorner", {
			CornerRadius = UDim.new(0, Theme.GetRounding("Small")),
			Parent = activeTabBackground
		})

		local activeTabStroke = Utilities.CreateInstance("UIStroke", {
			Name = "ActiveTabStroke",
			Color = Theme.GetColor("Accent"),
			Transparency = 1, -- Starts transparent
			Thickness = 1,
			Parent = activeTabBackground
		})

		-- Content Area
		local contentArea = Utilities.CreateInstance("Frame", {
			Name = "ContentArea",
			Size = UDim2.new(1, -165, 1, -10),
			Position = UDim2.fromOffset(160, 5),
			BackgroundTransparency = 1,
			Parent = mainFrame
		})

		self.Elements = {
			MainFrame = mainFrame,
			TitleContainer = titleContainer,
			Sidebar = sidebar,
			TabContainer = tabContainer,
			TabList = tabList,
			TabLayout = tabLayout,
			ActiveTabBackground = activeTabBackground,
			ContentArea = contentArea
		}

		self:SetupDragging()
	end

	function Window:SetupDragging()
		local InputHandler = Library.Input
		local mainFrame = self.Elements.MainFrame
		local titleContainer = self.Elements.TitleContainer

		local dragStartPos = nil
		local dragStartInput = nil

		titleContainer.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				self.IsDragging = true
				dragStartPos = mainFrame.Position
				dragStartInput = Vector2.new(input.Position.X, input.Position.Y)
			end
		end)

		titleContainer.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				self.IsDragging = false
			end
		end)

		InputHandler.OnMouseMoved:Connect(function(pos)
			if self.IsDragging and dragStartPos and dragStartInput then
				local delta = pos - dragStartInput
				mainFrame.Position = UDim2.new(
					dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X,
					dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	function Window:CreateTab(options)
		return TabComponent.New(self, options)
	end

	return Window
end

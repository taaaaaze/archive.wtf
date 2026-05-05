local setmetatable = setmetatable

return function(Library)
	local Tab = {}
	Tab.__index = Tab

	local Utilities = Library.Utilities
	local Theme = Library.Theme
	local Animation = Library.Animation

	function Tab.New(window, options)
		options = options or {}
		
		local self = setmetatable({
			Window = window,
			Name = options.Name or "Tab",
			Icon = options.Icon,
			Selected = false,
			Elements = {}
		}, Tab)

		self:Build()
		return self
	end

	function Tab:Build()
		local tabList = self.Window.Elements.TabList
		local contentArea = self.Window.Elements.ContentArea

		-- Tab Button
		local button = Utilities.CreateInstance("TextButton", {
			Name = "Tab_" .. self.Name,
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Theme.GetColor("SurfaceHovered"),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Parent = tabList
		})

		local corner = Utilities.CreateInstance("UICorner", {
			CornerRadius = UDim.new(0, Theme.GetRounding("Small")),
			Parent = button
		})

		-- Title Label
		local hasIcon = self.Icon ~= nil
		local textOffset = hasIcon and 30 or 10


		local titleLabel = Utilities.CreateInstance("TextLabel", {
			Name = "Title",
			Size = UDim2.new(1, -textOffset - 10, 1, 0),
			Position = UDim2.fromOffset(textOffset, 0),
			BackgroundTransparency = 1,
			Text = self.Name,
			TextColor3 = Theme.GetColor("TextDimmed"),
			Font = Theme.GetFont("Semibold"),
			TextSize = Theme.GetTextSize("Default"),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = button
		})

		-- Icon
		local iconLabel
		if hasIcon then
			if string.match(self.Icon, "rbxassetid://") then
				iconLabel = Utilities.CreateInstance("ImageLabel", {
					Name = "Icon",
					Size = UDim2.fromOffset(16, 16),
					Position = UDim2.new(0, 8, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Image = self.Icon,
					ImageColor3 = Theme.GetColor("TextDimmed"),
					Parent = button
				})
			else
				-- Assume it's a font icon (like Lucide)
				iconLabel = Utilities.CreateInstance("TextLabel", {
					Name = "Icon",
					Size = UDim2.fromOffset(16, 16),
					Position = UDim2.new(0, 8, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Text = self.Icon, -- We'll just set text to the icon character/name for now
					TextColor3 = Theme.GetColor("TextDimmed"),
					Font = Library.LucideFont or Theme.GetFont("Default"),
					TextSize = 16,
					Parent = button
				})
			end
		end

		-- Content Frame
		local contentFrame = Utilities.CreateInstance("ScrollingFrame", {
			Name = "Content_" .. self.Name,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Parent = contentArea
		})

		local listLayout = Utilities.CreateInstance("UIListLayout", {
			Padding = UDim.new(0, Theme.GetSpacing("Default")),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = contentFrame
		})

		self.Elements = {
			Button = button,
			Title = titleLabel,
			Icon = iconLabel,
			Content = contentFrame,
			Layout = listLayout
		}

		-- Events
		button.MouseEnter:Connect(function()
			if self.Selected then return end
			Animation.Tween(button, { BackgroundTransparency = 0.8 }, 0.2)
			Animation.Tween(titleLabel, { TextColor3 = Theme.GetColor("TextSecondary") }, 0.2)
			if iconLabel then
				local colorProp = iconLabel:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
				Animation.Tween(iconLabel, { [colorProp] = Theme.GetColor("TextSecondary") }, 0.2)
			end
		end)

		button.MouseLeave:Connect(function()
			if self.Selected then return end
			Animation.Tween(button, { BackgroundTransparency = 1 }, 0.2)
			Animation.Tween(titleLabel, { TextColor3 = Theme.GetColor("TextDimmed") }, 0.2)
			if iconLabel then
				local colorProp = iconLabel:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
				Animation.Tween(iconLabel, { [colorProp] = Theme.GetColor("TextDimmed") }, 0.2)
			end
		end)

		button.MouseButton1Click:Connect(function()
			self:Select()
		end)

		-- Automatically select first tab
		table.insert(self.Window.Tabs, self)
		if #self.Window.Tabs == 1 then
			self:Select()
		end

		-- Update scroll size dynamically
		listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			contentFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
		end)
	end

	function Tab:Select()
		if self.Selected then return end

		if self.Window.ActiveTab then
			self.Window.ActiveTab:Deselect()
		end

		self.Selected = true
		self.Window.ActiveTab = self
		self.Elements.Content.Visible = true

		local button = self.Elements.Button
		local title = self.Elements.Title
		local icon = self.Elements.Icon

		Animation.Tween(button, { BackgroundTransparency = 1 }, 0.3) -- Keep button transparent
		Animation.Tween(title, { TextColor3 = Theme.GetColor("Text") }, 0.3)

		if icon then
			local colorProp = icon:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
			Animation.Tween(icon, { [colorProp] = Theme.GetColor("Text") }, 0.3)
		end
		
		-- Move sliding background
		local activeBg = self.Window.Elements.ActiveTabBackground
		local tabList = self.Window.Elements.TabList
		
		task.spawn(function()
			-- Yield slightly to allow UIListLayout to position elements if this is the first frame
			task.wait()
			local targetY = button.AbsolutePosition.Y - tabList.AbsolutePosition.Y
			if activeBg.BackgroundTransparency == 1 then
				activeBg.Position = UDim2.fromOffset(0, targetY)
				Animation.Tween(activeBg, { BackgroundTransparency = 0 }, 0.2)
			else
				Animation.Spring(activeBg, { Position = UDim2.fromOffset(0, targetY) }, 15, 120)
			end
		end)
	end

	function Tab:Deselect()
		self.Selected = false
		self.Elements.Content.Visible = false

		local button = self.Elements.Button
		local title = self.Elements.Title
		local icon = self.Elements.Icon

		Animation.Tween(button, { BackgroundTransparency = 1 }, 0.3)
		Animation.Tween(title, { TextColor3 = Theme.GetColor("TextDimmed") }, 0.3)

		if icon then
			local colorProp = icon:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
			Animation.Tween(icon, { [colorProp] = Theme.GetColor("TextDimmed") }, 0.3)
		end
	end

	return Tab
end

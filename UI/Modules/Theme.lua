local setmetatable = setmetatable
local rawget = rawget
local type = type
local clamp = math.clamp
local floor = math.floor

return function(Signal)
	local Theme = {}
	Theme.__index = Theme

	local ELEMENT_STATES = {
		Default = "Default",
		Hovered = "Hovered",
		Active = "Active",
		Focused = "Focused",
		Disabled = "Disabled",
		Selected = "Selected",
	}
	Theme.States = ELEMENT_STATES

	local STATE_PRIORITY = {
		[ELEMENT_STATES.Disabled] = 6,
		[ELEMENT_STATES.Active] = 5,
		[ELEMENT_STATES.Focused] = 4,
		[ELEMENT_STATES.Selected] = 3,
		[ELEMENT_STATES.Hovered] = 2,
		[ELEMENT_STATES.Default] = 1,
	}
	Theme.StatePriority = STATE_PRIORITY

	local _themes = {}
	local _active = nil
	local _activeData = nil
	local _elementOverrides = {}

	Theme.OnThemeChanged = Signal.New()
	Theme.OnColorChanged = Signal.New()

	local DarkTheme = {
		Name = "Dark",
		Colors = {
			Background = Color3.fromRGB(18, 18, 22),
			BackgroundSecondary = Color3.fromRGB(24, 24, 30),
			BackgroundTertiary = Color3.fromRGB(32, 32, 40),
			Surface = Color3.fromRGB(28, 28, 35),
			SurfaceHovered = Color3.fromRGB(38, 38, 48),
			SurfaceActive = Color3.fromRGB(45, 45, 58),
			Accent = Color3.fromRGB(130, 90, 255),
			AccentHovered = Color3.fromRGB(145, 108, 255),
			AccentActive = Color3.fromRGB(110, 72, 220),
			AccentDark = Color3.fromRGB(100, 65, 200),
			AccentSubtle = Color3.fromRGB(40, 30, 70),
			Text = Color3.fromRGB(230, 230, 235),
			TextSecondary = Color3.fromRGB(170, 170, 180),
			TextDimmed = Color3.fromRGB(140, 140, 150),
			TextDisabled = Color3.fromRGB(80, 80, 90),
			TextInverse = Color3.fromRGB(18, 18, 22),
			Border = Color3.fromRGB(45, 45, 55),
			BorderHovered = Color3.fromRGB(65, 65, 80),
			BorderAccent = Color3.fromRGB(130, 90, 255),
			Glow = Color3.fromRGB(130, 90, 255),
			Shadow = Color3.fromRGB(0, 0, 0),
			Success = Color3.fromRGB(80, 200, 120),
			Warning = Color3.fromRGB(240, 180, 40),
			Error = Color3.fromRGB(230, 70, 70),
			Info = Color3.fromRGB(70, 150, 255),
			Scrollbar = Color3.fromRGB(45, 45, 55),
			ScrollbarHovered = Color3.fromRGB(60, 60, 75),
			ScrollbarActive = Color3.fromRGB(90, 90, 110),
			Overlay = Color3.fromRGB(0, 0, 0),
		},
		Transparency = {
			Background = 0,
			Surface = 0,
			Overlay = 0.4,
			Shadow = 0.5,
			GlowStrong = 0.3,
			GlowSubtle = 0.7,
			Disabled = 0.5,
		},
		Font = {
			Default = Enum.Font.Gotham,
			Bold = Enum.Font.GothamBold,
			Semibold = Enum.Font.GothamSemibold,
			Monospace = Enum.Font.RobotoMono,
		},
		TextSize = {
			Default = 13,
			Small = 11,
			Header = 16,
			Title = 20,
			Caption = 10,
		},
		Spacing = {
			None = 0,
			Tiny = 2,
			Small = 4,
			Default = 6,
			Medium = 8,
			Large = 12,
			XLarge = 16,
		},
		Rounding = {
			None = 0,
			Small = 4,
			Default = 6,
			Medium = 8,
			Large = 12,
			Full = 9999,
		},
		BorderWidth = {
			None = 0,
			Default = 1,
			Thick = 2,
		},
	}

	local LightTheme = {
		Name = "Light",
		Colors = {
			Background = Color3.fromRGB(240, 240, 245),
			BackgroundSecondary = Color3.fromRGB(230, 230, 238),
			BackgroundTertiary = Color3.fromRGB(220, 220, 230),
			Surface = Color3.fromRGB(250, 250, 252),
			SurfaceHovered = Color3.fromRGB(240, 240, 248),
			SurfaceActive = Color3.fromRGB(232, 232, 240),
			Accent = Color3.fromRGB(110, 70, 230),
			AccentHovered = Color3.fromRGB(125, 85, 245),
			AccentActive = Color3.fromRGB(95, 55, 210),
			AccentDark = Color3.fromRGB(80, 45, 190),
			AccentSubtle = Color3.fromRGB(230, 220, 255),
			Text = Color3.fromRGB(25, 25, 30),
			TextSecondary = Color3.fromRGB(70, 70, 80),
			TextDimmed = Color3.fromRGB(110, 110, 120),
			TextDisabled = Color3.fromRGB(170, 170, 180),
			TextInverse = Color3.fromRGB(240, 240, 245),
			Border = Color3.fromRGB(210, 210, 220),
			BorderHovered = Color3.fromRGB(185, 185, 200),
			BorderAccent = Color3.fromRGB(110, 70, 230),
			Glow = Color3.fromRGB(110, 70, 230),
			Shadow = Color3.fromRGB(0, 0, 0),
			Success = Color3.fromRGB(50, 170, 90),
			Warning = Color3.fromRGB(210, 150, 20),
			Error = Color3.fromRGB(210, 50, 50),
			Info = Color3.fromRGB(50, 120, 230),
			Scrollbar = Color3.fromRGB(200, 200, 210),
			ScrollbarHovered = Color3.fromRGB(180, 180, 195),
			ScrollbarActive = Color3.fromRGB(150, 150, 170),
			Overlay = Color3.fromRGB(0, 0, 0),
		},
		Transparency = {
			Background = 0,
			Surface = 0,
			Overlay = 0.5,
			Shadow = 0.7,
			GlowStrong = 0.4,
			GlowSubtle = 0.8,
			Disabled = 0.5,
		},
		Font = {
			Default = Enum.Font.Gotham,
			Bold = Enum.Font.GothamBold,
			Semibold = Enum.Font.GothamSemibold,
			Monospace = Enum.Font.RobotoMono,
		},
		TextSize = {
			Default = 13,
			Small = 11,
			Header = 16,
			Title = 20,
			Caption = 10,
		},
		Spacing = {
			None = 0,
			Tiny = 2,
			Small = 4,
			Default = 6,
			Medium = 8,
			Large = 12,
			XLarge = 16,
		},
		Rounding = {
			None = 0,
			Small = 4,
			Default = 6,
			Medium = 8,
			Large = 12,
			Full = 9999,
		},
		BorderWidth = {
			None = 0,
			Default = 1,
			Thick = 2,
		},
	}

	function Theme.Register(themeData)
		if not themeData or not themeData.Name then return false end
		_themes[themeData.Name] = themeData
		return true
	end

	function Theme.Unregister(name)
		if _active == name then return false end
		_themes[name] = nil
		return true
	end

	function Theme.SetActive(name)
		local themeData = _themes[name]
		if not themeData then return false end
		local previous = _active
		_active = name
		_activeData = themeData
		Theme.OnThemeChanged:Fire(name, previous)
		return true
	end

	function Theme.GetActive()
		return _activeData
	end

	function Theme.GetActiveName()
		return _active
	end

	function Theme.GetTheme(name)
		return _themes[name]
	end

	function Theme.GetThemeNames()
		local names = {}
		local n = 0
			for name in _themes do
			n += 1
			names[n] = name
		end
		return names
	end

	function Theme.GetColor(key)
		if not _activeData then return Color3.new(1, 1, 1) end
		return _activeData.Colors[key] or Color3.new(1, 1, 1)
	end

	function Theme.GetTransparency(key)
		if not _activeData then return 0 end
		return _activeData.Transparency[key] or 0
	end

	function Theme.GetFont(key)
		if not _activeData then return Enum.Font.Gotham end
		return _activeData.Font[key] or _activeData.Font.Default or Enum.Font.Gotham
	end

	function Theme.GetTextSize(key)
		if not _activeData then return 13 end
		return _activeData.TextSize[key] or _activeData.TextSize.Default or 13
	end

	function Theme.GetSpacing(key)
		if not _activeData then return 6 end
		return _activeData.Spacing[key] or _activeData.Spacing.Default or 6
	end

	function Theme.GetRounding(key)
		if not _activeData then return 6 end
		return _activeData.Rounding[key] or _activeData.Rounding.Default or 6
	end

	function Theme.GetBorderWidth(key)
		if not _activeData then return 1 end
		return _activeData.BorderWidth[key] or _activeData.BorderWidth.Default or 1
	end

	function Theme.Override(elementType, state, overrides)
		if not _elementOverrides[elementType] then
			_elementOverrides[elementType] = {}
		end
		_elementOverrides[elementType][state or ELEMENT_STATES.Default] = overrides
	end

	function Theme.ClearOverride(elementType, state)
		if not _elementOverrides[elementType] then return end
		if state then
			_elementOverrides[elementType][state] = nil
		else
			_elementOverrides[elementType] = nil
		end
	end

	function Theme.Resolve(elementType, state, property)
		local elementOvr = _elementOverrides[elementType]
		if elementOvr then
			local stateOvr = elementOvr[state]
			if stateOvr and stateOvr[property] ~= nil then
				return stateOvr[property]
			end
			local defaultOvr = elementOvr[ELEMENT_STATES.Default]
			if defaultOvr and defaultOvr[property] ~= nil then
				return defaultOvr[property]
			end
		end

		if not _activeData then return nil end
		if _activeData.Colors[property] ~= nil then
			return _activeData.Colors[property]
		end
		if _activeData.Transparency[property] ~= nil then
			return _activeData.Transparency[property]
		end
		return nil
	end

	function Theme.ResolveColor(elementType, state, colorKey)
		local elementOvr = _elementOverrides[elementType]
		if elementOvr then
			local stateOvr = elementOvr[state]
			if stateOvr and stateOvr[colorKey] ~= nil then
				return stateOvr[colorKey]
			end
			local defaultOvr = elementOvr[ELEMENT_STATES.Default]
			if defaultOvr and defaultOvr[colorKey] ~= nil then
				return defaultOvr[colorKey]
			end
		end
		return Theme.GetColor(colorKey)
	end

	function Theme.GetHighestState(states)
		local highest = ELEMENT_STATES.Default
		local highestPri = 0
		for _, state in states do
			local pri = STATE_PRIORITY[state] or 0
			if pri > highestPri then
				highestPri = pri
				highest = state
			end
		end
		return highest
	end

	function Theme.SetCustomFont(key, fontObject)
		if not _activeData then return end
		_activeData.Font[key] = fontObject
	end

	Theme.Register(DarkTheme)
	Theme.Register(LightTheme)
	Theme.SetActive("Dark")

	return Theme
end

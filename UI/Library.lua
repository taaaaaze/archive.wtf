--[[

    / archive.wtf UI library
    \ made by @taze9292 (760302148197548032)

    + discord.gg/archivewtf

]]

local Library = {}
Library.__index = Library

local REPO_BASE = "https://raw.githubusercontent.com/taaaaaze/archive.wtf/main/"
local LOCAL_BASE = "archive.wtf/"

local game = game
local pcall = pcall
local type = type
local setmetatable = setmetatable
local loadstring = loadstring

local HttpGet = game.HttpGet
local isfile = isfile
local readfile = readfile

local function Load(path)
	local fullLocal = LOCAL_BASE .. path
	if isfile then
		local exists = false
		local s, r = pcall(isfile, fullLocal)
		if s then exists = r end
		if exists then
			local rs, content = pcall(readfile, fullLocal)
			if rs and content then
				local ls, module = pcall(loadstring, content)
				if ls and module then
					local es, result = pcall(module)
					if es then return result end
				end
			end
		end
	end
	local url = REPO_BASE .. path
	local success, source = pcall(HttpGet, game, url, true)
	if success and source then
		local ls, module = pcall(loadstring, source)
		if ls and module then
			local es, result = pcall(module)
			if es then return result end
		end
	end
	return nil
end

local Environment = Load("UI/Modules/Environment.lua")
local Utilities = Load("UI/Modules/Utilities.lua")
local Signal = Load("UI/Modules/Signal.lua")

local ThemeInit = Load("UI/Modules/Theme.lua")
local FlagsInit = Load("UI/Modules/Flags.lua")
local InputInit = Load("UI/Modules/Input.lua")
local AssetManagerInit = Load("UI/Modules/AssetManager.lua")
local AnimationInit = Load("UI/Modules/Animation.lua")

local Theme = ThemeInit and ThemeInit(Signal) or nil
local Flags = FlagsInit and FlagsInit(Signal, Environment) or nil
local Input = InputInit and InputInit(Signal, Environment) or nil
local AssetManager = AssetManagerInit and AssetManagerInit(Environment) or nil
local Animation = AnimationInit and AnimationInit(Signal, Environment) or nil

Library.Environment = Environment
Library.Utilities = Utilities
Library.Signal = Signal
Library.Theme = Theme
Library.Flags = Flags
Library.Input = Input
Library.AssetManager = AssetManager
Library.Animation = Animation

Library.Version = "1.0.0"
Library.IsOpen = false
Library.ToggleKey = Enum.KeyCode.RightShift

local _initialized = false
local _uiRoot = nil
local _connections = {}
local _renderConnection = nil

local spawn = task.spawn
local clock = os.clock

local function Store(conn)
	_connections[#_connections + 1] = conn
end

function Library.Init(config)
	if _initialized then return Library end
	_initialized = true

	config = config or {}

	if config.ToggleKey then
		Library.ToggleKey = config.ToggleKey
	end

	if config.Theme then
		Theme.SetActive(config.Theme)
	end

	if Input then
		Input.Init()
	end

	if AssetManager then
		AssetManager.Init()
	end

	Library.ScreenSize = Environment.GetViewportSize()

	local uiParent = Environment.GetUIParent()
	if uiParent then
		local existing = uiParent:FindFirstChild("ArchiveWTF")
		if existing then
			existing:Destroy()
		end

		_uiRoot = Utilities.CreateInstance("ScreenGui", {
			Name = "ArchiveWTF",
			DisplayOrder = 999999,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true,
			Parent = uiParent,
		})
	end

	Library.UIRoot = _uiRoot

	if Input then
		Store(Input.OnKeyPressed:Connect(function(keyCode)
			if keyCode == Library.ToggleKey then
				Library.Toggle()
			end
		end))
	end

	local camera = Environment.Services.Workspace and Environment.Services.Workspace.CurrentCamera
	if camera then
		Store(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			Library.ScreenSize = camera.ViewportSize
		end))
	end

	Library.OnToggled = Signal.New()
	Library.OnDestroyed = Signal.New()

	return Library
end

function Library.Toggle()
	Library.IsOpen = not Library.IsOpen
	if _uiRoot then
		_uiRoot.Enabled = Library.IsOpen
	end
	if Library.OnToggled then
		Library.OnToggled:Fire(Library.IsOpen)
	end
end

function Library.SetOpen(state)
	if Library.IsOpen == state then return end
	Library.IsOpen = state
	if _uiRoot then
		_uiRoot.Enabled = state
	end
	if Library.OnToggled then
		Library.OnToggled:Fire(state)
	end
end

function Library.IsInitialized()
	return _initialized
end

function Library.GetUIRoot()
	return _uiRoot
end

function Library.Notify(title, message, duration, notifyType)
end

function Library.Destroy()
	if not _initialized then return end
	_initialized = false

	for i = 1, #_connections do
		_connections[i]:Disconnect()
	end
	table.clear(_connections)

	if _renderConnection then
		_renderConnection:Disconnect()
		_renderConnection = nil
	end

	if Animation then Animation.Destroy() end
	if Input then Input.Destroy() end
	if Flags then Flags.Destroy() end
	if AssetManager then AssetManager.Destroy() end

	if Library.OnToggled then Library.OnToggled:Destroy() end
	if Library.OnDestroyed then
		Library.OnDestroyed:Fire()
		Library.OnDestroyed:Destroy()
	end

	if _uiRoot then
		_uiRoot:Destroy()
		_uiRoot = nil
	end

	Library.UIRoot = nil
	Library.IsOpen = false
end

return Library

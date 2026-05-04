local Environment = {}

local game = game
local cloneref = cloneref or function(o) return o end
local identifyexecutor = identifyexecutor or function() return "Unknown", "0.0.0" end
local getgenv = getgenv or function() return _G end
local gethui = gethui
local newcclosure = newcclosure or function(fn) return fn end
local checkcaller = checkcaller or function() return false end

local execName, execVersion = identifyexecutor()
Environment.ExecutorName = execName
Environment.ExecutorVersion = execVersion

local function SafeGetService(name)
	local success, service = pcall(game.GetService, game, name)
	if success and service then
		return cloneref(service)
	end
	return nil
end

Environment.Services = {
	Players = SafeGetService("Players"),
	UserInputService = SafeGetService("UserInputService"),
	RunService = SafeGetService("RunService"),
	TweenService = SafeGetService("TweenService"),
	HttpService = SafeGetService("HttpService"),
	ContentProvider = SafeGetService("ContentProvider"),
	CoreGui = SafeGetService("CoreGui"),
	StarterGui = SafeGetService("StarterGui"),
	TextService = SafeGetService("TextService"),
	Workspace = SafeGetService("Workspace"),
	GuiService = SafeGetService("GuiService"),
}

local spawn = task.spawn
local defer = task.defer
local delay = task.delay
local cancel = task.cancel
local twait = task.wait
local clock = os.clock
local tick = tick
local typeof = typeof
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local getmetatable = getmetatable
local pcall = pcall
local xpcall = xpcall
local select = select
local unpack = unpack or table.unpack
local tostring = tostring
local tonumber = tonumber
local type = type
local next = next
local error = error
local warn = warn
local newproxy = newproxy

Environment.spawn = spawn
Environment.defer = defer
Environment.delay = delay
Environment.cancel = cancel
Environment.wait = twait
Environment.clock = clock
Environment.tick = tick
Environment.typeof = typeof
Environment.rawget = rawget
Environment.rawset = rawset
Environment.setmetatable = setmetatable
Environment.getmetatable = getmetatable
Environment.pcall = pcall
Environment.xpcall = xpcall
Environment.select = select
Environment.unpack = unpack
Environment.tostring = tostring
Environment.tonumber = tonumber
Environment.type = type
Environment.next = next
Environment.error = error
Environment.warn = warn
Environment.newproxy = newproxy
Environment.loadstring = loadstring

Environment.v2 = Vector2.new
Environment.v3 = Vector3.new
Environment.c3 = Color3.new
Environment.c3rgb = Color3.fromRGB
Environment.c3hsv = Color3.fromHSV
Environment.udim2 = UDim2.new
Environment.udim = UDim.new
Environment.inst = Instance.new

local insert = table.insert
local remove = table.remove
local sort = table.sort
local concat = table.concat
local find = table.find
local clear = table.clear
local clone = table.clone
local freeze = table.freeze
local move = table.move
local create = table.create

Environment.tinsert = insert
Environment.tremove = remove
Environment.tsort = sort
Environment.tconcat = concat
Environment.tfind = find
Environment.tclear = clear
Environment.tclone = clone
Environment.tfreeze = freeze
Environment.tmove = move
Environment.tcreate = create

local floor = math.floor
local ceil = math.ceil
local abs = math.abs
local min = math.min
local max = math.max
local clamp = math.clamp
local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local pi = math.pi
local huge = math.huge
local random = math.random
local rad = math.rad
local exp = math.exp
local log = math.log
local pow = math.pow or function(b, e) return b ^ e end

Environment.floor = floor
Environment.ceil = ceil
Environment.abs = abs
Environment.min = min
Environment.max = max
Environment.clamp = clamp
Environment.sqrt = sqrt
Environment.sin = sin
Environment.cos = cos
Environment.pi = pi
Environment.huge = huge
Environment.random = random
Environment.rad = rad
Environment.exp = exp
Environment.log = log
Environment.pow = pow

local sfind = string.find
local sub = string.sub
local gsub = string.gsub
local gmatch = string.gmatch
local match = string.match
local format = string.format
local rep = string.rep
local lower = string.lower
local upper = string.upper
local byte = string.byte
local char = string.char
local len = string.len
local split = string.split

Environment.sfind = sfind
Environment.sub = sub
Environment.gsub = gsub
Environment.gmatch = gmatch
Environment.match = match
Environment.format = format
Environment.rep = rep
Environment.lower = lower
Environment.upper = upper
Environment.byte = byte
Environment.char = char
Environment.len = len
Environment.split = split

Environment.HAS_FILESYSTEM = writefile ~= nil and readfile ~= nil and isfile ~= nil
Environment.HAS_CUSTOM_ASSET = getcustomasset ~= nil
Environment.HAS_REQUEST = request ~= nil or (syn and syn.request ~= nil) or http_request ~= nil
Environment.HAS_CRYPT = crypt ~= nil
Environment.HAS_HOOKFUNCTION = hookfunction ~= nil
Environment.HAS_HOOKMETAMETHOD = hookmetamethod ~= nil
Environment.HAS_ISRBXACTIVE = isrbxactive ~= nil
Environment.HAS_GETHUI = gethui ~= nil
Environment.HAS_SETCLIPBOARD = setclipboard ~= nil
Environment.HAS_SETFPSCAP = setfpscap ~= nil
Environment.HAS_QUEUE_ON_TELEPORT = queue_on_teleport ~= nil
Environment.HAS_CLONEREF = cloneref ~= nil
Environment.HAS_NEWCCLOSURE = newcclosure ~= nil

if not isrbxactive then
	local UIS = Environment.Services.UserInputService
	if UIS then
		local _focused = true
		UIS.WindowFocused:Connect(function()
			_focused = true
		end)
		UIS.WindowFocusReleased:Connect(function()
			_focused = false
		end)
		isrbxactive = function()
			return _focused
		end
	else
		isrbxactive = function()
			return true
		end
	end
end
Environment.IsRbxActive = isrbxactive

if gethui then
	Environment.GetUIParent = gethui
else
	Environment.GetUIParent = function()
		local success, result = pcall(function()
			return cloneref(game:GetService("CoreGui"))
		end)
		if success then
			return result
		end
		local lp = Environment.Services.Players and Environment.Services.Players.LocalPlayer
		if lp then
			return lp:FindFirstChildOfClass("PlayerGui")
		end
		return nil
	end
end

local _request = request or (syn and syn.request) or http_request or (http and http.request)
if _request then
	Environment.Request = newcclosure(function(options)
		return _request(options)
	end)
else
	Environment.Request = function()
		return {
			Body = "",
			StatusCode = 0,
			StatusMessage = "Not supported",
			Success = false,
			Headers = {},
		}
	end
	Environment.HAS_REQUEST = false
end

Environment.GetCustomAsset = getcustomasset or function(path) return path end

Environment.WriteFile = writefile or function() end
Environment.ReadFile = readfile or function() return "" end
Environment.IsFile = isfile or function() return false end
Environment.IsFolder = isfolder or function() return false end
Environment.MakeFolder = makefolder or function() end
Environment.AppendFile = appendfile or function() end
Environment.DeleteFile = delfile or function() end
Environment.DeleteFolder = delfolder or function() end
Environment.ListFiles = listfiles or function() return {} end

if crypt then
	Environment.Crypt = crypt
end

Environment.SetClipboard = setclipboard or function() end
Environment.SetFPSCap = setfpscap or function() end
Environment.QueueOnTeleport = queue_on_teleport or function() end

Environment.HookFunction = hookfunction
Environment.HookMetamethod = hookmetamethod
Environment.NewCClosure = newcclosure
Environment.CheckCaller = checkcaller
Environment.CloneFunction = clonefunction
Environment.CloneRef = cloneref
Environment.GetGenv = getgenv

Environment.GetViewportSize = function()
	local cam = Environment.Services.Workspace and Environment.Services.Workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1920, 1080)
end

Environment.GetLocalPlayer = function()
	return Environment.Services.Players and Environment.Services.Players.LocalPlayer
end

Environment.GetMouse = function()
	local lp = Environment.GetLocalPlayer()
	return lp and lp:GetMouse() or nil
end

return Environment

local type = type
local typeof = typeof
local tostring = tostring
local pcall = pcall
local format = string.format
local match = string.match
local floor = math.floor
local warn = warn
local clear = table.clear
local remove = table.remove
local spawn = task.spawn

return function(Signal, Environment)
	local Flags = {}

	local _registry = {}
	local _signals = {}
	local _callbacks = {}

	local TYPES = {
		Boolean = "boolean",
		Number = "number",
		String = "string",
		Color3 = "Color3",
		EnumItem = "EnumItem",
		Table = "table",
	}
	Flags.Types = TYPES

	local CONFIG_DIR = "archive.wtf/configs"

	local function ValidateType(value, flagType)
		if flagType == TYPES.Boolean then
			return type(value) == "boolean"
		elseif flagType == TYPES.Number then
			return type(value) == "number"
		elseif flagType == TYPES.String then
			return type(value) == "string"
		elseif flagType == TYPES.Color3 then
			return typeof(value) == "Color3"
		elseif flagType == TYPES.EnumItem then
			return typeof(value) == "EnumItem"
		elseif flagType == TYPES.Table then
			return type(value) == "table"
		end
		return true
	end

	local function SerializeValue(value, flagType)
		if flagType == TYPES.Color3 then
			return {
				R = floor(value.R * 255 + 0.5),
				G = floor(value.G * 255 + 0.5),
				B = floor(value.B * 255 + 0.5),
			}
		elseif flagType == TYPES.EnumItem then
			return {
				EnumType = tostring(value.EnumType),
				Name = value.Name,
			}
		end
		return value
	end

	local function DeserializeValue(data, flagType)
		if flagType == TYPES.Color3 and type(data) == "table" then
			return Color3.fromRGB(data.R or 0, data.G or 0, data.B or 0)
		elseif flagType == TYPES.EnumItem and type(data) == "table" then
			local success, enumType = pcall(function()
				return Enum[data.EnumType]
			end)
			if success and enumType then
				local s2, item = pcall(function()
					return enumType[data.Name]
				end)
				if s2 then
					return item
				end
			end
			return nil
		end
		return data
	end

	function Flags.Register(key, default, flagType, metadata)
		if _registry[key] then
			return _registry[key]
		end
		flagType = flagType or TYPES.String
		local entry = {
			Key = key,
			Value = default,
			Default = default,
			Type = flagType,
			Element = nil,
			Metadata = metadata,
		}
		_registry[key] = entry
		_signals[key] = Signal.New()
		_callbacks[key] = {}
		return entry
	end

	function Flags.Set(key, value)
		local entry = _registry[key]
		if not entry then
			return false
		end
		if not ValidateType(value, entry.Type) then
			warn(format("[archive.wtf] Flag '%s' expected %s, got %s", key, entry.Type, typeof(value)))
			return false
		end
		local old = entry.Value
		entry.Value = value
		if _signals[key] then
			_signals[key]:Fire(value, old)
		end
		if _callbacks[key] then
			for i = 1, #_callbacks[key] do
				spawn(_callbacks[key][i], value, old)
			end
		end
		return true
	end

	function Flags.Get(key)
		local entry = _registry[key]
		if not entry then
			return nil
		end
		return entry.Value
	end

	function Flags.GetDefault(key)
		local entry = _registry[key]
		if not entry then
			return nil
		end
		return entry.Default
	end

	function Flags.GetEntry(key)
		return _registry[key]
	end

	function Flags.Reset(key)
		local entry = _registry[key]
		if not entry then
			return false
		end
		return Flags.Set(key, entry.Default)
	end

	function Flags.ResetAll()
		for key, entry in _registry do
			Flags.Set(key, entry.Default)
		end
	end

	function Flags.OnChanged(key)
		return _signals[key]
	end

	function Flags.Bind(key, callback)
		if not _callbacks[key] then
			return
		end
		local n = #_callbacks[key]
		_callbacks[key][n + 1] = callback
		return function()
			for i = 1, #_callbacks[key] do
				if _callbacks[key][i] == callback then
					remove(_callbacks[key], i)
					break
				end
			end
		end
	end

	function Flags.BindElement(key, element)
		local entry = _registry[key]
		if not entry then
			return false
		end
		entry.Element = element
		return true
	end

	function Flags.Exists(key)
		return _registry[key] ~= nil
	end

	function Flags.GetAll()
		local result = {}
		for key, entry in _registry do
			result[key] = {
				Value = entry.Value,
				Default = entry.Default,
				Type = entry.Type,
			}
		end
		return result
	end

	function Flags.Export()
		local data = {}
		for key, entry in _registry do
			data[key] = {
				Value = SerializeValue(entry.Value, entry.Type),
				Type = entry.Type,
			}
		end
		return data
	end

	function Flags.Import(data)
		if type(data) ~= "table" then
			return false
		end
		local count = 0
		for key, info in data do
			local entry = _registry[key]
			if entry and info.Type == entry.Type then
				local value = DeserializeValue(info.Value, entry.Type)
				if value ~= nil then
					Flags.Set(key, value)
					count += 1
				end
			end
		end
		return true, count
	end

	function Flags.Save(profileName)
		if not Environment.HAS_FILESYSTEM then
			return false
		end
		profileName = profileName or "default"

		if not Environment.IsFolder(CONFIG_DIR) then
			Environment.MakeFolder(CONFIG_DIR)
		end

		local data = Flags.Export()
		local HttpService = Environment.Services.HttpService
		local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
		if not success then
			return false
		end

		local path = CONFIG_DIR .. "/" .. profileName .. ".json"
		local writeSuccess = pcall(Environment.WriteFile, path, encoded)
		return writeSuccess
	end

	function Flags.Load(profileName)
		if not Environment.HAS_FILESYSTEM then
			return false
		end
		profileName = profileName or "default"

		local path = CONFIG_DIR .. "/" .. profileName .. ".json"
		if not Environment.IsFile(path) then
			return false
		end

		local readSuccess, content = pcall(Environment.ReadFile, path)
		if not readSuccess then
			return false
		end

		local HttpService = Environment.Services.HttpService
		local decodeSuccess, data = pcall(HttpService.JSONDecode, HttpService, content)
		if not decodeSuccess then
			return false
		end

		return Flags.Import(data)
	end

	function Flags.Delete(profileName)
		if not Environment.HAS_FILESYSTEM then
			return false
		end
		profileName = profileName or "default"
		local path = CONFIG_DIR .. "/" .. profileName .. ".json"
		if Environment.IsFile(path) then
			pcall(Environment.DeleteFile, path)
			return true
		end
		return false
	end

	function Flags.GetProfiles()
		if not Environment.HAS_FILESYSTEM then
			return {}
		end
		if not Environment.IsFolder(CONFIG_DIR) then
			return {}
		end

		local files = Environment.ListFiles(CONFIG_DIR)
		local profiles = {}
		local n = 0
		for i = 1, #files do
			local file = files[i]
			local name = match(file, "([^/\\]+)%.json$")
			if name then
				n += 1
				profiles[n] = name
			end
		end
		return profiles
	end

	function Flags.Unregister(key)
		if not _registry[key] then
			return false
		end
		if _signals[key] then
			_signals[key]:Destroy()
			_signals[key] = nil
		end
		_callbacks[key] = nil
		_registry[key] = nil
		return true
	end

	function Flags.Destroy()
		for _, signal in _signals do
			signal:Destroy()
		end
		clear(_registry)
		clear(_signals)
		clear(_callbacks)
	end

	return Flags
end

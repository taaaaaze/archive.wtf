local Utilities = {}

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
local random = math.random
local huge = math.huge

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
local ssplit = string.split

local insert = table.insert
local remove = table.remove
local sort = table.sort
local concat = table.concat
local tfind = table.find
local clear = table.clear
local clone = table.clone
local freeze = table.freeze
local move = table.move
local create = table.create

local typeof = typeof
local type = type
local pcall = pcall
local select = select
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local getmetatable = getmetatable
local tostring = tostring
local tonumber = tonumber
local unpack = unpack or table.unpack

function Utilities.DeepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	local copy = {}
	for k, v in original do
		if type(v) == "table" then
			copy[k] = Utilities.DeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

function Utilities.ShallowCopy(original)
	if type(original) ~= "table" then
		return original
	end
	local copy = {}
	for k, v in original do
		copy[k] = v
	end
	return copy
end

function Utilities.Merge(base, overrides)
	local result = Utilities.ShallowCopy(base)
	for k, v in overrides do
		result[k] = v
	end
	return result
end

function Utilities.DeepMerge(base, overrides)
	local result = Utilities.DeepCopy(base)
	for k, v in overrides do
		if type(v) == "table" and type(result[k]) == "table" then
			result[k] = Utilities.DeepMerge(result[k], v)
		else
			result[k] = v
		end
	end
	return result
end

function Utilities.Keys(tbl)
	local keys = {}
	local n = 0
	for k in tbl do
		n += 1
		keys[n] = k
	end
	return keys
end

function Utilities.Values(tbl)
	local values = {}
	local n = 0
	for _, v in tbl do
		n += 1
		values[n] = v
	end
	return values
end

function Utilities.Find(tbl, predicate)
	for k, v in tbl do
		if predicate(v, k) then
			return v, k
		end
	end
	return nil
end

function Utilities.Filter(tbl, predicate)
	local result = {}
	local n = 0
	for k, v in tbl do
		if predicate(v, k) then
			n += 1
			result[n] = v
		end
	end
	return result
end

function Utilities.Map(tbl, transform)
	local result = {}
	local n = 0
	for k, v in tbl do
		n += 1
		result[n] = transform(v, k)
	end
	return result
end

function Utilities.ForEach(tbl, callback)
	for k, v in tbl do
		callback(v, k)
	end
end

function Utilities.Count(tbl)
	local n = 0
	for _ in tbl do
		n += 1
	end
	return n
end

function Utilities.Freeze(tbl)
	if freeze then
		return freeze(tbl)
	end
	return tbl
end

function Utilities.Lerp(a, b, t)
	return a + (b - a) * t
end

function Utilities.InverseLerp(a, b, v)
	if a == b then
		return 0
	end
	return (v - a) / (b - a)
end

function Utilities.Clamp(value, lo, hi)
	return clamp(value, lo, hi)
end

function Utilities.Round(value, decimals)
	if decimals then
		local mult = 10 ^ decimals
		return floor(value * mult + 0.5) / mult
	end
	return floor(value + 0.5)
end

function Utilities.MapRange(value, inMin, inMax, outMin, outMax)
	return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end

function Utilities.Split(str, delimiter)
	if ssplit then
		return ssplit(str, delimiter)
	end
	local result = {}
	local n = 0
	local pattern = "([^" .. delimiter .. "]*)" .. delimiter .. "?"
	for segment in gmatch(str, pattern) do
		n += 1
		result[n] = segment
	end
	return result
end

function Utilities.Trim(str)
	return match(str, "^%s*(.-)%s*$") or str
end

function Utilities.StartsWith(str, prefix)
	return sub(str, 1, len(prefix)) == prefix
end

function Utilities.EndsWith(str, suffix)
	if len(suffix) == 0 then
		return true
	end
	return sub(str, -len(suffix)) == suffix
end

function Utilities.FromHex(hex)
	hex = gsub(hex, "^#", "")
	local r = tonumber(sub(hex, 1, 2), 16) or 0
	local g = tonumber(sub(hex, 3, 4), 16) or 0
	local b = tonumber(sub(hex, 5, 6), 16) or 0
	return Color3.fromRGB(r, g, b)
end

function Utilities.ToHex(color)
	return format("#%02X%02X%02X",
		floor(color.R * 255 + 0.5),
		floor(color.G * 255 + 0.5),
		floor(color.B * 255 + 0.5)
	)
end

function Utilities.Darken(color, amount)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, clamp(v - amount, 0, 1))
end

function Utilities.Lighten(color, amount)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, clamp(v + amount, 0, 1))
end

function Utilities.Saturate(color, amount)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, clamp(s + amount, 0, 1), v)
end

function Utilities.Desaturate(color, amount)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, clamp(s - amount, 0, 1), v)
end

function Utilities.LerpColor(a, b, t)
	return a:Lerp(b, t)
end

function Utilities.WithAlpha(color, alpha)
	return { Color = color, Alpha = clamp(alpha, 0, 1) }
end

function Utilities.Is(value, expectedType)
	return typeof(value) == expectedType
end

function Utilities.TypeAssert(value, expectedType, name)
	if typeof(value) ~= expectedType then
		error(format("%s expected %s, got %s", name or "Value", expectedType, typeof(value)), 2)
	end
end

function Utilities.IsInstance(value)
	return typeof(value) == "Instance"
end

function Utilities.GenerateUUID()
	if crypt and crypt.generatebytes then
		local bytes = crypt.generatebytes(16)
		local hex = gsub(bytes, ".", function(c)
			return format("%02x", byte(c))
		end)
		return format(
			"%s-%s-4%s-%s-%s",
			sub(hex, 1, 8),
			sub(hex, 9, 12),
			sub(hex, 14, 16),
			sub(hex, 17, 20),
			sub(hex, 21, 32)
		)
	end
	local HttpService = game:GetService("HttpService")
	return HttpService:GenerateGUID(false)
end

function Utilities.Timestamp()
	return os.clock()
end

function Utilities.CreateInstance(className, properties, children)
	local instance = Instance.new(className)
	if properties then
		for prop, value in properties do
			if prop ~= "Parent" then
				instance[prop] = value
			end
		end
		if properties.Parent then
			instance.Parent = properties.Parent
		end
	end
	if children then
		for i = 1, #children do
			children[i].Parent = instance
		end
	end
	return instance
end

function Utilities.CleanInstance(instance)
	if instance and instance.Parent then
		instance:Destroy()
	end
end

function Utilities.SafeCallback(callback, ...)
	if type(callback) ~= "function" then
		return
	end
	local success, err = pcall(callback, ...)
	if not success then
		warn("[archive.wtf]", err)
	end
	return success, err
end

return Utilities

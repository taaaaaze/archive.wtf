local pcall = pcall
local type = type
local format = string.format
local match = string.match
local warn = warn
local clear = table.clear

return function(Environment)
	local AssetManager = {}

	local _assets = {}
	local _fontCache = {}
	local _imageCache = {}
	local _initialized = false

	local ASSET_DIR = "archive.wtf/assets"
	local FONT_DIR = ASSET_DIR .. "/fonts"
	local IMAGE_DIR = ASSET_DIR .. "/images"

	local HttpService = Environment.Services.HttpService

	local function EnsureDirectory(path)
		if not Environment.HAS_FILESYSTEM then
			return false
		end
		if not Environment.IsFolder(path) then
			local success = pcall(Environment.MakeFolder, path)
			return success
		end
		return true
	end

	function AssetManager.Init()
		if _initialized then
			return
		end
		_initialized = true
		EnsureDirectory("archive.wtf")
		EnsureDirectory(ASSET_DIR)
		EnsureDirectory(FONT_DIR)
		EnsureDirectory(IMAGE_DIR)
	end

	function AssetManager.DownloadFont(assetName, fontName, url)
		if _fontCache[assetName] then
			return _fontCache[assetName]
		end

		if not Environment.HAS_FILESYSTEM or not Environment.HAS_REQUEST or not Environment.HAS_CUSTOM_ASSET then
			return nil
		end

		local ttfPath = FONT_DIR .. "/" .. fontName .. ".ttf"
		local configPath = FONT_DIR .. "/" .. fontName .. "_.ttf"

		if not Environment.IsFile(ttfPath) then
			local success, response = pcall(Environment.Request, {
				Url = url,
				Method = "GET",
			})
			if not success or not response.Success then
				warn(format("[archive.wtf] Failed to download font '%s'", assetName))
				return nil
			end
			local writeSuccess = pcall(Environment.WriteFile, ttfPath, response.Body)
			if not writeSuccess then
				warn(format("[archive.wtf] Failed to write font file '%s'", assetName))
				return nil
			end
		end

		local config = {
			name = fontName,
			faces = {
				{
					name = "Regular",
					weight = 400,
					style = "normal",
					assetId = Environment.GetCustomAsset(ttfPath),
				},
			},
		}

		local encodeSuccess, encoded = pcall(HttpService.JSONEncode, HttpService, config)
		if not encodeSuccess then
			warn(format("[archive.wtf] Failed to encode font config '%s'", assetName))
			return nil
		end

		local configWriteSuccess = pcall(Environment.WriteFile, configPath, encoded)
		if not configWriteSuccess then
			warn(format("[archive.wtf] Failed to write font config '%s'", assetName))
			return nil
		end

		local fontSuccess, loadedFont = pcall(Font.new, Environment.GetCustomAsset(configPath))
		if not fontSuccess then
			warn(format("[archive.wtf] Failed to load font '%s'", assetName))
			return nil
		end

		local entry = {
			Name = assetName,
			Path = ttfPath,
			ConfigPath = configPath,
			Asset = loadedFont,
		}

		_fontCache[assetName] = entry
		_assets[assetName] = entry
		return entry
	end

	function AssetManager.DownloadFontWeights(assetName, fontName, weights)
		if _fontCache[assetName] then
			return _fontCache[assetName]
		end

		if not Environment.HAS_FILESYSTEM or not Environment.HAS_REQUEST or not Environment.HAS_CUSTOM_ASSET then
			return nil
		end

		local faces = {}
		local n = 0
		local primaryPath = nil

		for i = 1, #weights do
			local w = weights[i]
			local fileName = fontName .. "-" .. w.Name
			local ttfPath = FONT_DIR .. "/" .. fileName .. ".ttf"

			if not Environment.IsFile(ttfPath) then
				local success, response = pcall(Environment.Request, {
					Url = w.Url,
					Method = "GET",
				})
				if success and response.Success then
					pcall(Environment.WriteFile, ttfPath, response.Body)
				end
			end

			if Environment.IsFile(ttfPath) then
				if not primaryPath then
					primaryPath = ttfPath
				end
				n += 1
				faces[n] = {
					name = w.Name,
					weight = w.Weight or 400,
					style = w.Style or "normal",
					assetId = Environment.GetCustomAsset(ttfPath),
				}
			end
		end

		if n == 0 then
			return nil
		end

		local configPath = FONT_DIR .. "/" .. fontName .. "_.ttf"
		local config = {
			name = fontName,
			faces = faces,
		}

		local encodeSuccess, encoded = pcall(HttpService.JSONEncode, HttpService, config)
		if not encodeSuccess then
			return nil
		end

		pcall(Environment.WriteFile, configPath, encoded)

		local fontSuccess, loadedFont = pcall(Font.new, Environment.GetCustomAsset(configPath))
		if not fontSuccess then
			return nil
		end

		local entry = {
			Name = assetName,
			Path = primaryPath,
			ConfigPath = configPath,
			Asset = loadedFont,
			Faces = faces,
		}

		_fontCache[assetName] = entry
		_assets[assetName] = entry
		return entry
	end

	function AssetManager.DownloadImage(assetName, url, fileName)
		if _imageCache[assetName] then
			return _imageCache[assetName]
		end

		if not Environment.HAS_FILESYSTEM or not Environment.HAS_REQUEST or not Environment.HAS_CUSTOM_ASSET then
			return nil
		end

		fileName = fileName or assetName
		local ext = match(url, "%.(%w+)$") or "png"
		local filePath = IMAGE_DIR .. "/" .. fileName .. "." .. ext

		if not Environment.IsFile(filePath) then
			local success, response = pcall(Environment.Request, {
				Url = url,
				Method = "GET",
			})
			if not success or not response.Success then
				warn(format("[archive.wtf] Failed to download image '%s'", assetName))
				return nil
			end
			local writeSuccess = pcall(Environment.WriteFile, filePath, response.Body)
			if not writeSuccess then
				warn(format("[archive.wtf] Failed to write image '%s'", assetName))
				return nil
			end
		end

		local assetId = Environment.GetCustomAsset(filePath)
		local entry = {
			Name = assetName,
			Path = filePath,
			Asset = assetId,
		}

		_imageCache[assetName] = entry
		_assets[assetName] = entry
		return entry
	end

	function AssetManager.DownloadRaw(assetName, url, fileName)
		if _assets[assetName] then
			return _assets[assetName]
		end

		if not Environment.HAS_FILESYSTEM or not Environment.HAS_REQUEST then
			return nil
		end

		local filePath = ASSET_DIR .. "/" .. (fileName or assetName)

		if not Environment.IsFile(filePath) then
			local success, response = pcall(Environment.Request, {
				Url = url,
				Method = "GET",
			})
			if not success or not response.Success then
				return nil
			end
			pcall(Environment.WriteFile, filePath, response.Body)
		end

		local entry = {
			Name = assetName,
			Path = filePath,
			Asset = Environment.HAS_CUSTOM_ASSET and Environment.GetCustomAsset(filePath) or filePath,
		}

		_assets[assetName] = entry
		return entry
	end

	function AssetManager.GetFont(assetName)
		local entry = _fontCache[assetName]
		return entry and entry.Asset or nil
	end

	function AssetManager.GetImage(assetName)
		local entry = _imageCache[assetName]
		return entry and entry.Asset or nil
	end

	function AssetManager.GetAsset(assetName)
		local entry = _assets[assetName]
		return entry and entry.Asset or nil
	end

	function AssetManager.GetEntry(assetName)
		return _assets[assetName]
	end

	function AssetManager.IsLoaded(assetName)
		return _assets[assetName] ~= nil
	end

	function AssetManager.Preload(assetIds)
		local ContentProvider = Environment.Services.ContentProvider
		if not ContentProvider then
			return
		end
		local instances = {}
		local n = 0
		for i = 1, #assetIds do
			if type(assetIds[i]) == "string" then
				n += 1
				instances[n] = assetIds[i]
			end
		end
		if n > 0 then
			pcall(ContentProvider.PreloadAsync, ContentProvider, instances)
		end
	end

	function AssetManager.GetAllFonts()
		local fonts = {}
		for name, entry in _fontCache do
			fonts[name] = entry.Asset
		end
		return fonts
	end

	function AssetManager.GetAllImages()
		local images = {}
		for name, entry in _imageCache do
			images[name] = entry.Asset
		end
		return images
	end

	function AssetManager.ClearCache()
		clear(_assets)
		clear(_fontCache)
		clear(_imageCache)
	end

	function AssetManager.Destroy()
		AssetManager.ClearCache()
		_initialized = false
	end

	return AssetManager
end

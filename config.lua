local Config = {
	VERSION = "0.1.0",
	NAME = "S23 Smart TAS",
	AUTHORIZATION_REQUIRED = true,
	EXPERIMENTAL = true,
	SCAN_MAX_INSTANCES = 800,
	SCAN_MAX_VISUALS = 160,
	SESSION_HISTORY_LIMIT = 40,
	LOGGER_HISTORY_LIMIT = 100,
	MINIMAP_RADIUS_STUDS = 100,
	MINIMAP_REFRESH_SECONDS = 0.15,
	THEME = {
		background = Color3.fromRGB(17, 18, 30),
		panel = Color3.fromRGB(27, 28, 46),
		accent = Color3.fromRGB(132, 82, 255),
		blue = Color3.fromRGB(55, 145, 255),
		cyan = Color3.fromRGB(56, 220, 230),
		text = Color3.fromRGB(240, 241, 255),
		muted = Color3.fromRGB(166, 170, 192),
		warning = Color3.fromRGB(255, 190, 80),
		error = Color3.fromRGB(255, 96, 116),
		success = Color3.fromRGB(110, 230, 160),
	},
}

function Config.Validate()
	if type(Config.VERSION) ~= "string" or Config.VERSION == "" then
		return false, "VERSION debe ser texto no vacío"
	end

	local positiveIntegerFields = {
		"SCAN_MAX_INSTANCES",
		"SCAN_MAX_VISUALS",
		"SESSION_HISTORY_LIMIT",
		"LOGGER_HISTORY_LIMIT",
	}
	for _, field in ipairs(positiveIntegerFields) do
		local value = Config[field]
		if type(value) ~= "number" or value < 1 or value % 1 ~= 0 then
			return false, field .. " debe ser un entero positivo"
		end
	end

	if type(Config.MINIMAP_RADIUS_STUDS) ~= "number" or Config.MINIMAP_RADIUS_STUDS <= 0 then
		return false, "MINIMAP_RADIUS_STUDS debe ser positivo"
	end
	if type(Config.MINIMAP_REFRESH_SECONDS) ~= "number" or Config.MINIMAP_REFRESH_SECONDS <= 0 then
		return false, "MINIMAP_REFRESH_SECONDS debe ser positivo"
	end
	if type(Config.THEME) ~= "table" then
		return false, "THEME debe ser una tabla"
	end
	local themeFields = {
		"background",
		"panel",
		"accent",
		"blue",
		"cyan",
		"text",
		"muted",
		"warning",
		"error",
		"success",
	}
	for _, field in ipairs(themeFields) do
		if typeof(Config.THEME[field]) ~= "Color3" then
			return false, "THEME." .. field .. " debe ser Color3"
		end
	end

	return true
end

return Config

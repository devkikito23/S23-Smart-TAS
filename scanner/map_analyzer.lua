local MapAnalyzer = {}

local VALID_TYPES = {
	platform = true,
	obstacle = true,
	checkpoint = true,
}

local function hasCheckpointName(name)
	local normalized = string.lower(name or "")
	return string.find(normalized, "checkpoint", 1, true) ~= nil
		or string.find(normalized, "check_point", 1, true) ~= nil
		or string.find(normalized, "spawn", 1, true) ~= nil
end

function MapAnalyzer.AnalyzePart(part)
	if part == nil or type(part.IsA) ~= "function" or not part:IsA("BasePart") then
		return nil, "not_basepart"
	end
	if part.Transparency >= 1 or part.LocalTransparencyModifier >= 1 then
		return nil, "not_visible"
	end

	local kind = "unknown"
	local status = "unknown"
	local evidence = "La geometría visible no coincide con una regla de clasificación."
	local marker = part:GetAttribute("SmartTAS_Type")

	if type(marker) == "string" and VALID_TYPES[string.lower(marker)] then
		kind = string.lower(marker)
		status = "detected"
		evidence = "Atributo observable SmartTAS_Type."
	elseif part:IsA("SpawnLocation") or hasCheckpointName(part.Name) then
		kind = "checkpoint"
		status = "estimated"
		evidence = "Clase SpawnLocation o nombre indicativo; no confirma la lógica del juego."
	elseif part.CanCollide and part.Size.X >= 4 and part.Size.Z >= 4 and part.Size.Y <= 8 then
		kind = "platform"
		status = "estimated"
		evidence = "Heurística de tamaño y colisión; puede clasificar geometría decorativa."
	elseif part.CanCollide and part.Size.Y > math.max(part.Size.X, part.Size.Z) * 1.4 then
		kind = "obstacle"
		status = "estimated"
		evidence = "Heurística de altura y colisión; no conoce la mecánica del juego."
	end

	return {
		kind = kind,
		status = status,
		evidence = evidence,
		instance = part,
		position = part.Position,
		size = part.Size,
		name = part.Name,
	}
end

return MapAnalyzer

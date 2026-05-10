local Format = {}

local Suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}

function Format.Number(Number)
	if Number < 1000 then
		return tostring(Number)
	end

	local Tier = math.floor(math.log10(Number) / 3)
	if Tier > #Suffixes - 1 then
		Tier = #Suffixes - 1
	end

	local ScaledNumber = Number / (1000 ^ Tier)
	local Formatted = string.format("%.3f", ScaledNumber)
		:gsub("%.0+$", "")
		:gsub("(%.%d-)0+$", "%1")

	return Formatted .. Suffixes[Tier + 1]
end

function Format.Time(Seconds)
	local Years = math.floor(Seconds / 31536000)
	local Days = math.floor((Seconds % 31536000) / 86400)
	local Hours = math.floor((Seconds % 86400) / 3600)
	local Minutes = math.floor((Seconds % 3600) / 60)
	local Secs = math.floor(Seconds % 60)

	local Parts = {}

	if Years > 0 then
		table.insert(Parts, string.format("%dy", Years))
	end

	if Days > 0 then
		table.insert(Parts, string.format("%dd", Days))
	end

	if Hours > 0 then
		table.insert(Parts, string.format("%dh", Hours))
	end

	if Minutes > 0 then
		table.insert(Parts, string.format("%dm", Minutes))
	end

	if Secs > 0 or #Parts == 0 then
		table.insert(Parts, string.format("%ds", Secs))
	end

	return table.concat(Parts, " ")
end

return Format

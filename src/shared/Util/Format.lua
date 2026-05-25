local Format = {}

local Suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}

function Format.Number(Number)
	Number = tonumber(Number) or 0

	if math.abs(Number) < 1000 then
		return tostring(Number)
	end

	local Sign = Number < 0 and -1 or 1
	local ScaledNumber = math.abs(Number)
	local Tier = 1

	while ScaledNumber >= 1000 and Tier < #Suffixes do
		ScaledNumber /= 1000
		Tier += 1
	end

	if ScaledNumber >= 999.995 and Tier < #Suffixes then
		ScaledNumber /= 1000
		Tier += 1
	end

	ScaledNumber *= Sign

	local Formatted = string.format("%.2f", ScaledNumber)
		:gsub("%.0+$", "")
		:gsub("(%.%d-)0+$", "%1")

	return Formatted .. Suffixes[Tier]
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

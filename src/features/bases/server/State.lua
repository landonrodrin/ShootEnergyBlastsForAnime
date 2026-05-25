return function(ctx)
	local BasesData = ctx.BasesData
	local Bases = ctx.Bases
function Bases.Retrieve(Base, Name)
	if not BasesData[Base] then return end

	if Name then
		return BasesData[Base][Name]
	else
		return BasesData[Base]
	end
end
end

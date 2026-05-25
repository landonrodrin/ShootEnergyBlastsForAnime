return function(ctx)
	local AnimeModule = ctx.Anime
	local AnimeRegistry = ctx.AnimeData
function AnimeModule.Retrieve(Anime, Name)
	if not AnimeRegistry[Anime] then return end

	if Name then
		return AnimeRegistry[Anime][Name]
	else
		return AnimeRegistry[Anime]
	end
end
end

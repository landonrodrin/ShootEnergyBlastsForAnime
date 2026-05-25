local PathUtils = {}

function PathUtils.FindByPath(root, path)
	local current = root
	for _, name in ipairs(path) do
		current = current and current:FindFirstChild(name)
		if not current then
			return nil
		end
	end
	return current
end

return PathUtils

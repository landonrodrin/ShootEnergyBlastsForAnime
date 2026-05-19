local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimeViewports = {}

local DEFAULT_MUTATION = "Default"

local function findViewport(Name, Mutation)
	local ViewportsFolder = ReplicatedStorage:FindFirstChild("AnimeViewports")
	if not ViewportsFolder then return nil end

	Mutation = Mutation or DEFAULT_MUTATION

	local MutationFolder = ViewportsFolder:FindFirstChild(Mutation)
	local Viewport = MutationFolder and MutationFolder:FindFirstChild(Name)
	if Viewport and Viewport:IsA("ViewportFrame") then
		return Viewport
	end

	if Mutation ~= DEFAULT_MUTATION then
		local DefaultFolder = ViewportsFolder:FindFirstChild(DEFAULT_MUTATION)
		Viewport = DefaultFolder and DefaultFolder:FindFirstChild(Name)
		if Viewport and Viewport:IsA("ViewportFrame") then
			return Viewport
		end
	end

	return nil
end

function AnimeViewports.Clone(Name, Mutation)
	local Viewport = findViewport(Name, Mutation)
	if not Viewport then return nil end

	local Clone = Viewport:Clone()
	local Camera = Clone:FindFirstChild("PreviewCamera")
	if Camera and Camera:IsA("Camera") then
		Clone.CurrentCamera = Camera
	end

	Clone.Visible = true
	return Clone
end

function AnimeViewports.ReplacePlaceholder(Placeholder, Name, Mutation)
	if not (Placeholder and Placeholder:IsA("GuiObject")) then return nil end

	local Viewport = AnimeViewports.Clone(Name, Mutation)
	if not Viewport then
		Placeholder.Visible = false
		return nil
	end

	Viewport.Name = Placeholder.Name
	Viewport.AnchorPoint = Placeholder.AnchorPoint
	Viewport.Position = Placeholder.Position
	Viewport.Size = Placeholder.Size
	Viewport.LayoutOrder = Placeholder.LayoutOrder
	Viewport.ZIndex = Placeholder.ZIndex
	Viewport.BackgroundTransparency = Placeholder.BackgroundTransparency
	Viewport.Parent = Placeholder.Parent

	Placeholder:Destroy()

	return Viewport
end

return AnimeViewports

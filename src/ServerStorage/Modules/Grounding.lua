local Grounding = {}

local DEFAULT_CLEARANCE = 0.1

function Grounding.SurfaceY(Surface)
	if not Surface or not Surface:IsA("BasePart") then return end

	return Surface.Position.Y + Surface.Size.Y / 2
end

function Grounding.AlignBottomToY(Model, SurfaceY, Configuration)
	if not Model or not Model.Parent or not SurfaceY then return end

	Configuration = Configuration or {}

	local _, Size = Model:GetBoundingBox()
	if Size.Y <= 0 then return end

	local ModelCFrame = Model:GetPivot()
	local BoundingCFrame = select(1, Model:GetBoundingBox())
	local BottomY = BoundingCFrame.Position.Y - Size.Y / 2
	local TargetY = SurfaceY + (Configuration.GroundOffset or 0) + DEFAULT_CLEARANCE
	local DeltaY = TargetY - BottomY

	if math.abs(DeltaY) < 0.001 then return end

	Model:PivotTo(ModelCFrame + Vector3.new(0, DeltaY, 0))
end

function Grounding.AlignBottomToSurface(Model, Surface, Configuration)
	Grounding.AlignBottomToY(Model, Grounding.SurfaceY(Surface), Configuration)
end

function Grounding.AlignBottomToSurfaceAfterAnimation(Model, Surface, Configuration)
	Grounding.AlignBottomToSurface(Model, Surface, Configuration)

	task.delay(0.1, function()
		Grounding.AlignBottomToSurface(Model, Surface, Configuration)
	end)

	task.delay(0.35, function()
		Grounding.AlignBottomToSurface(Model, Surface, Configuration)
	end)
end

return Grounding

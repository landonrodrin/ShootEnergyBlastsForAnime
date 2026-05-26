local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Packages:WaitForChild("Trove"))

local Frames = {} 
local FrameTroves = setmetatable({}, {__mode = "k"})
local ButtonTroves = setmetatable({}, {__mode = "k"})

local Animations = {}

function Animations.Frame(Frame)
	local FrameTrove = FrameTroves[Frame]
	if FrameTrove then
		return FrameTrove
	end
	
	table.insert(Frames, Frame)
	FrameTrove = Trove.new()
	FrameTroves[Frame] = FrameTrove

	FrameTrove:Add(function()
		FrameTroves[Frame] = nil

		local Index = table.find(Frames, Frame)
		if Index then
			table.remove(Frames, Index)
		end
	end)

	FrameTrove:Connect(Frame.Destroying, function()
		FrameTrove:Destroy()
	end)
	
	local UIScale = Frame:FindFirstChildOfClass("UIScale")
	if not UIScale then
		UIScale = FrameTrove:Add(Instance.new("UIScale"))
		UIScale.Scale = Frame.Visible and 1 or 0
		UIScale.Parent = Frame
	end

	return FrameTrove
end

function Animations.Button(Frame, Button)
	local ButtonTrove = ButtonTroves[Button]
	if ButtonTrove then
		return ButtonTrove
	end

	ButtonTrove = Trove.new()
	ButtonTroves[Button] = ButtonTrove

	ButtonTrove:Add(function()
		ButtonTroves[Button] = nil
	end)

	ButtonTrove:Connect(Button.Destroying, function()
		ButtonTrove:Destroy()
	end)

	local UIScale = Frame:FindFirstChildOfClass("UIScale")
	if not UIScale then
		UIScale = Instance.new("UIScale")
		UIScale.Parent = Frame
	end

	local function Tween(Scale)
		if UIScale.Scale == Scale then return end
		
		local ScaleTween = TweenService:Create(
			UIScale,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Scale < UIScale.Scale and Enum.EasingDirection.In or Enum.EasingDirection.Out),
			{Scale = Scale}
		)

		ScaleTween:Play()
	end

	ButtonTrove:Connect(Button.MouseEnter, function()
		Tween(1.1)
	end)

	ButtonTrove:Connect(Button.MouseLeave, function()
		Tween(1)
	end)

	ButtonTrove:Connect(Button.MouseButton1Down, function()
		Tween(0.9)
	end)

	ButtonTrove:Connect(Button.MouseButton1Up, function()
		Tween(1)
	end)

	ButtonTrove:Connect(Button.Activated, function()
		Tween(1)
	end)

	return ButtonTrove
end

function Animations.ToggleFrame(Frame)
	for _, OtherFrame in ipairs(Frames) do
		if OtherFrame == Frame then continue end

		if not OtherFrame.Visible then continue end

		local Tween = TweenService:Create(
			OtherFrame.UIScale,
			TweenInfo.new(
				0.25,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In
			),
			{Scale = 0}
		)

		Tween:Play()

		Tween.Completed:Wait()

		OtherFrame.Visible = false
	end

	Frame.UIScale.Scale = Frame.Visible and 1 or 0

	Frame.Visible = true
	
	local Tween = TweenService:Create(
		Frame.UIScale,
		TweenInfo.new(
			((math.round(Frame.UIScale.Scale * 1000) / 1000) == 0 and 0.35 or 0.25),
			Enum.EasingStyle.Quad,
			((math.round(Frame.UIScale.Scale * 1000) / 1000) == 0 and Enum.EasingDirection.Out or Enum.EasingDirection.In)
		),
		{Scale = ((math.round(Frame.UIScale.Scale * 1000) / 1000) == 0 and 1 or 0)}
	)

	Tween:Play()

	Tween.Completed:Wait()

	if (math.round(Frame.UIScale.Scale * 1000) / 1000) == 0 then
		Frame.Visible = false
	end
end

return Animations

local TweenService = game:GetService("TweenService")

local Frames = {} 

local Animations = {}

function Animations.Frame(Frame)
	if table.find(Frames, Frame) then return end
	
	table.insert(Frames, Frame)
	
	local UIScale = Frame:FindFirstChildOfClass("UIScale")
	if not UIScale then
		UIScale = Instance.new("UIScale")
		UIScale.Scale = Frame.Visible and 1 or 0
		UIScale.Parent = Frame
	end
end

function Animations.Button(Frame, Button)
	local UIScale = Frame:FindFirstChildOfClass("UIScale")
	if not UIScale then
		UIScale = Instance.new("UIScale")
		UIScale.Parent = Frame
	end

	local function Tween(Scale)
		if UIScale.Scale == Scale then return end
		
		local Tween = TweenService:Create(
			UIScale,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Scale < UIScale.Scale and Enum.EasingDirection.In or Enum.EasingDirection.Out),
			{Scale = Scale}
		)

		Tween:Play()
	end

	Button.MouseEnter:Connect(function()
		Tween(1.1)
	end)

	Button.MouseLeave:Connect(function()
		Tween(1)
	end)

	Button.MouseButton1Down:Connect(function()
		Tween(0.9)
	end)

	Button.MouseButton1Up:Connect(function()
		Tween(1)
	end)

	Button.Activated:Connect(function()
		Tween(1)
	end)
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

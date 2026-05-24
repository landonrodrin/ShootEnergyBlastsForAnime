local Actions = require(script.Parent.Parent:WaitForChild("Actions"))

return function(Context)
	return Actions.Fast(Context.Executor)
end

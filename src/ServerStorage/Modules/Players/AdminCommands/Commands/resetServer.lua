local Actions = require(script.Parent.Parent:WaitForChild("Actions"))

return function(Context)
	return Actions.Reset(Context.Executor)
end

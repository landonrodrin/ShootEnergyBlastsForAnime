local Actions = require(script.Parent.Parent:WaitForChild("Actions"))

return function(Context)
	return Actions.Rich(Context.Executor)
end

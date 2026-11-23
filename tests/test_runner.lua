local TestRunner = {}

function TestRunner.Run()
	local testsFolder = script.Parent
	local testNames = { "test_config", "test_logger", "test_session", "test_modules", "test_core" }
	local failures = {}
	local passed = 0

	for _, name in ipairs(testNames) do
		local testModule = require(testsFolder:WaitForChild(name))
		local ok, err = pcall(testModule)
		if ok then
			passed = passed + 1
		else
			table.insert(failures, name .. ": " .. tostring(err))
		end
	end

	if #failures > 0 then
		error(string.format("%d/%d pruebas fallaron:\n%s", #failures, #testNames, table.concat(failures, "\n")))
	end
	return {
		passed = passed,
		failed = 0,
		total = #testNames,
	}
end

return TestRunner

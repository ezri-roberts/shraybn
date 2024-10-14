local lust = require("libs.lust")
local describe = lust.describe

describe("Shrift", function()
	require("shrift.tests.lexer-test")
	require("shrift.tests.ast-test")
	require("shrift.tests.parser-let-statement-test")
	require("shrift.tests.parser-return-statement-test")
	require("shrift.tests.parser-identifier-expression-test")
	require("shrift.tests.parser-integer-literal-expression-test")
	require("shrift.tests.parser-boolean-expression-test")
	require("shrift.tests.parser-prefix-expression-test")
	require("shrift.tests.parser-infix-expression-test")
	require("shrift.tests.parser-operator-precedence-test")
	require("shrift.tests.parser-if-expression-test")
	require("shrift.tests.parser-function-parameters-test")
	require("shrift.tests.parser-function-literal-expression-test")
	require("shrift.tests.parser-call-expression-test")
	require("shrift.tests.parser-call-expression-parameters-test")
end)

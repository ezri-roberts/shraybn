local ast = require("shrift.ast") --[[@as ast]]
local Lexer = require("shrift.lexer") --[[@as Lexer]]
local Parser = require("shrift.parser") --[[@as Parser]]
local utils = require("shrift.tests.utils")
local lust = require("libs.lust")
local it, expect = lust.it, lust.expect

it("Parse Prefix Expression", function()
	local prefix_tests = {
		{ "!5", "!", 5 },
		{ "-15", "-", 15 },
		{ "!true\n", "!", true },
		{ "!false\n", "!", false },
	}

	for _, v in pairs(prefix_tests) do
		local input = v[1]
		local operator = v[2]
		local value = v[3]

		---@type Lexer
		local l = Lexer(input)
		---@type Parser
		local p = Parser(l)
		---@type ASTProgram
		local program = p:parse_program()
		utils.check_parse_errors(p)

		expect(#program.statements).to.equal(1)

		local stmt = program.statements[1]
		---@cast stmt ASTExpressionStatement
		expect(stmt:is(ast.ExpressionStatement)).to.equal(true)

		local exp = stmt.expression
		---@cast exp ASTPrefixExpression
		expect(exp:is(ast.PrefixExpression)).to.equal(true)

		expect(exp.operator).to.equal(operator)
		utils.test_literal_expression(exp.right, value)
	end
end)

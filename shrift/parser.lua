local ast = require("shrift.ast") --[[@as ast]]
local token = require("shrift.token") --[[@as token]]
local Object = require("libs.classic") --[[@as Object]]
local Lexer = require("shrift.lexer") --[[@as Lexer]]

---@alias PrefixParseFn fun(self: Parser): ASTExpressionNode?
---@alias InfixParseFn
---| fun(self: Parser, left: ASTExpressionNode): ASTExpressionNode?

---@class Parser
---@field cur_token TokenData
---@field peek_token TokenData
---@field errors string[]
---@field prefix_parse_fns {[TokenType]: PrefixParseFn}
---@field infix_parse_fns {[TokenType]: InfixParseFn}
local Parser = Object:extend()

---@enum ExpressionPrecedence
local PRECEDENCE = {
	LOWEST = 1,
	EQUALS = 2, -- 		==
	LESSGREATER = 3, -- > or <
	SUM = 4, -- 		+
	PRODUCT = 5, -- 	*
	PREFIX = 6, -- 		-x or !x
	CALL = 7, -- 		my_func(x)
}

---@type {[TokenType]: ExpressionPrecedence}
local precedences = {
	[token.TYPE.EQ] = PRECEDENCE.EQUALS,
	[token.TYPE.NOT_EQ] = PRECEDENCE.EQUALS,
	[token.TYPE.LT] = PRECEDENCE.LESSGREATER,
	[token.TYPE.GT] = PRECEDENCE.LESSGREATER,
	[token.TYPE.PLUS] = PRECEDENCE.SUM,
	[token.TYPE.MINUS] = PRECEDENCE.SUM,
	[token.TYPE.SLASH] = PRECEDENCE.PRODUCT,
	[token.TYPE.ASTERISK] = PRECEDENCE.PRODUCT,
	[token.TYPE.LPAREN] = PRECEDENCE.CALL,
}

---@private
---@param lexer Lexer
function Parser:new(lexer)
	self.lexer = lexer

	self.errors = {}
	self.prefix_parse_fns = {}
	self.infix_parse_fns = {}

	self:register_prefix(token.TYPE.IDENT, self.parse_identifier)
	self:register_prefix(token.TYPE.INT, self.parse_integer_literal)
	self:register_prefix(token.TYPE.BANG, self.parse_prefix_expression)
	self:register_prefix(token.TYPE.MINUS, self.parse_prefix_expression)
	self:register_prefix(token.TYPE.TRUE, self.parse_boolean)
	self:register_prefix(token.TYPE.FALSE, self.parse_boolean)
	self:register_prefix(token.TYPE.LPAREN, self.parse_grouped_expression)
	self:register_prefix(token.TYPE.IF, self.parse_if_expression)
	self:register_prefix(token.TYPE.FUNCTION, self.parse_function_literal)

	self:register_infix(token.TYPE.PLUS, self.parse_infix_expression)
	self:register_infix(token.TYPE.MINUS, self.parse_infix_expression)
	self:register_infix(token.TYPE.SLASH, self.parse_infix_expression)
	self:register_infix(token.TYPE.ASTERISK, self.parse_infix_expression)
	self:register_infix(token.TYPE.EQ, self.parse_infix_expression)
	self:register_infix(token.TYPE.NOT_EQ, self.parse_infix_expression)
	self:register_infix(token.TYPE.LT, self.parse_infix_expression)
	self:register_infix(token.TYPE.GT, self.parse_infix_expression)
	self:register_infix(token.TYPE.LPAREN, self.parse_call_expression)

	self:next_token()
	self:next_token()
end

---@param tok_type TokenType
function Parser:peek_error(tok_type)
	local msg = string.format(
		"Expected next token to be %s, got %s instead.",
		tok_type,
		self.peek_token.type
	)

	table.insert(self.errors, msg)
end

function Parser:next_token()
	self.cur_token = self.peek_token
	self.peek_token = self.lexer:next_token()
end

---@return ASTProgram
function Parser:parse_program()
	---@type ASTProgram
	local program = ast.Program()

	while self.cur_token.type ~= token.TYPE.EOF do
		local stmt = self:parse_statement()
		if stmt ~= nil then
			table.insert(program.statements, stmt)
		end
		self:next_token()
	end

	return program
end

function Parser:parse_statement()
	if self.cur_token.type == token.TYPE.LET then
		return self:parse_let_statement()
	elseif self.cur_token.type == token.TYPE.RETURN then
		return self:parse_return_statement()
	else
		return self:parse_expression_statement()
	end
end

---@return ASTLetStatement?
function Parser:parse_let_statement()
	---@type ASTLetStatement
	local stmt = ast.LetStatement(self.cur_token)

	if not self:expect_peek(token.TYPE.IDENT) then
		return nil
	end

	stmt.name = ast.Identifier(self.cur_token, self.cur_token.literal)

	if not self:expect_peek(token.TYPE.ASSIGN) then
		return nil
	end

	self:next_token()
	stmt.value = self:parse_expression(PRECEDENCE.LOWEST)

	if self:peek_token_is(token.TYPE.NEWLINE) then
		self:next_token()
	end

	return stmt
end

---@param tok_type TokenType
function Parser:no_prefix_parse_fn_error(tok_type)
	local msg =
		string.format("No prefix parse function for %s found.", tok_type)
	table.insert(self.errors, msg)
end

---@param precedence ExpressionPrecedence
---@return ASTExpressionNode?
function Parser:parse_expression(precedence)
	local prefix = self.prefix_parse_fns[self.cur_token.type]

	if not prefix then
		self:no_prefix_parse_fn_error(self.cur_token.type)
		return nil
	end

	local left_exp = prefix(self)

	while
		not self:peek_token_is(token.TYPE.NEWLINE)
		and precedence < self:peek_precedence()
	do
		local infix = self.infix_parse_fns[self.peek_token.type]
		if not infix then
			return left_exp
		end

		self:next_token()
		left_exp = infix(self, left_exp)
	end

	return left_exp
end

---@return ASTReturnStatement
function Parser:parse_return_statement()
	---@type ASTReturnStatement
	local stmt = ast.ReturnStatement(self.cur_token)

	self:next_token()

	stmt.return_value = self:parse_expression(PRECEDENCE.LOWEST)

	if self:peek_token_is(token.TYPE.NEWLINE) then
		self:next_token()
	end

	return stmt
end

---@return ASTExpressionStatement
function Parser:parse_expression_statement()
	---@type ASTExpressionStatement
	local stmt = ast.ExpressionStatement(self.cur_token)
	stmt.expression = self:parse_expression(PRECEDENCE.LOWEST)

	-- TODO: Create error if there is no newline?
	-- Possibly don't want to do this.
	if self:peek_token_is(token.TYPE.NEWLINE) then
		self:next_token()
	end

	return stmt
end

function Parser:parse_block_statement()
	---@type ASTBlockStatement
	local block = ast.BlockStatement(self.cur_token)

	self:next_token()

	while
		not self:cur_token_is(token.TYPE.RBRACE)
		and not self:cur_token_is(token.TYPE.EOF)
	do
		local stmt = self:parse_statement()

		if stmt then
			table.insert(block.statements, stmt)
		end

		self:next_token()
	end

	return block
end

---@type PrefixParseFn
function Parser:parse_identifier()
	return ast.Identifier(self.cur_token, self.cur_token.literal)
end

---@type PrefixParseFn
function Parser:parse_integer_literal()
	---@type ASTIntegerLiteral
	local lit = ast.IntegerLiteral(self.cur_token)

	local val = tonumber(self.cur_token.literal)
	if not val then
		local msg = string.format(
			"Could not parse %s as integer.",
			self.cur_token.literal
		)

		table.insert(self.errors, msg)
		return nil
	end

	lit.value = val
	return lit
end

---@type PrefixParseFn
function Parser:parse_prefix_expression()
	---@type ASTPrefixExpression
	local expression =
		ast.PrefixExpression(self.cur_token, self.cur_token.literal)

	self:next_token()
	expression.right = self:parse_expression(PRECEDENCE.PREFIX)

	return expression
end

---@type PrefixParseFn
function Parser:parse_boolean()
	return ast.Boolean(self.cur_token, self:cur_token_is(token.TYPE.TRUE))
end

---@type PrefixParseFn
function Parser:parse_grouped_expression()
	self:next_token()

	local exp = self:parse_expression(PRECEDENCE.LOWEST)
	if not self:expect_peek(token.TYPE.RPAREN) then
		return nil
	end

	return exp
end

---@type PrefixParseFn
function Parser:parse_if_expression()
	---@type ASTIfExpression
	local expression = ast.IfExpression(self.cur_token)

	if not self:expect_peek(token.TYPE.LPAREN) then
		return nil
	end

	self:next_token()
	expression.condition = self:parse_expression(PRECEDENCE.LOWEST)

	if not self:expect_peek(token.TYPE.RPAREN) then
		return nil
	end

	if not self:expect_peek(token.TYPE.LBRACE) then
		return nil
	end

	expression.consequence = self:parse_block_statement()

	-- Else Statement --
	if self:peek_token_is(token.TYPE.ELSE) then
		self:next_token()

		if not self:expect_peek(token.TYPE.LBRACE) then
			return nil
		end

		expression.alternative = self:parse_block_statement()
	end

	return expression
end

---@type PrefixParseFn
function Parser:parse_function_literal()
	---@type ASTFunctionLiteral
	local lit = ast.FunctionLiteral(self.cur_token)

	if not self:expect_peek(token.TYPE.LPAREN) then
		return nil
	end

	lit.parameters = self:parse_function_parameters()

	if not self:expect_peek(token.TYPE.LBRACE) then
		return nil
	end

	lit.body = self:parse_block_statement()

	return lit
end

function Parser:parse_function_parameters()
	---@type ASTIdentifier[]
	local identifiers = {}

	if self:peek_token_is(token.TYPE.RPAREN) then
		self:next_token()
		return identifiers
	end

	self:next_token()

	---@type ASTIdentifier
	local ident = ast.Identifier(self.cur_token, self.cur_token.literal)
	table.insert(identifiers, ident)

	while self:peek_token_is(token.TYPE.COMMA) do
		self:next_token()
		self:next_token()
		ident = ast.Identifier(self.cur_token, self.cur_token.literal)
		table.insert(identifiers, ident)
	end

	if not self:expect_peek(token.TYPE.RPAREN) then
		return nil
	end

	return identifiers
end

---@type InfixParseFn
function Parser:parse_infix_expression(left)
	---@type ASTInfixExpression
	local expression =
		ast.InfixExpression(self.cur_token, self.cur_token.literal, left)
	local precedence = self:cur_precedence()

	self:next_token()
	expression.right = self:parse_expression(precedence)

	return expression
end

---@type InfixParseFn
function Parser:parse_call_expression(left)
	---@type ASTCallExpression
	local exp = ast.CallExpression(self.cur_token, left)
	exp.arguments = self:parse_call_arguments()

	return exp
end

---@return ASTExpressionNode[]?
function Parser:parse_call_arguments()
	---@type ASTExpressionNode[]
	local args = {}

	if self:peek_token_is(token.TYPE.RPAREN) then
		self:next_token()
		return args
	end

	self:next_token()
	table.insert(args, self:parse_expression(PRECEDENCE.LOWEST))

	while self:peek_token_is(token.TYPE.COMMA) do
		self:next_token()
		self:next_token()
		table.insert(args, self:parse_expression(PRECEDENCE.LOWEST))
	end

	if not self:expect_peek(token.TYPE.RPAREN) then
		return nil
	end

	return args
end

---@param tok_type TokenType
---@return boolean
function Parser:cur_token_is(tok_type)
	return self.cur_token.type == tok_type
end

---@param tok_type TokenType
---@return boolean
function Parser:peek_token_is(tok_type)
	return self.peek_token.type == tok_type
end

---@param tok_type TokenType
---@return boolean
function Parser:expect_peek(tok_type)
	if self:peek_token_is(tok_type) then
		self:next_token()
		return true
	else
		self:peek_error(tok_type)
		return false
	end
end

---@return integer
function Parser:peek_precedence()
	if precedences[self.peek_token.type] then
		return precedences[self.peek_token.type]
	end

	return PRECEDENCE.LOWEST
end

---@return integer
function Parser:cur_precedence()
	if precedences[self.cur_token.type] then
		return precedences[self.cur_token.type]
	end

	return PRECEDENCE.LOWEST
end

---@param tok_type TokenType
---@param fn PrefixParseFn
function Parser:register_prefix(tok_type, fn)
	self.prefix_parse_fns[tok_type] = fn
end

---@param tok_type TokenType
---@param fn InfixParseFn
function Parser:register_infix(tok_type, fn)
	self.infix_parse_fns[tok_type] = fn
end

return Parser

---@type token
local token = require("shrift.token")

---@class Lexer
local Lexer = Object:extend()

function Lexer:new(input)
	self.input = input
	self.position = 0
	self.read_position = 0
	self.ch = ""

	self:read_char()
end

function Lexer:read_char()
	if self.read_position >= #self.input then
		self.ch = ""
	else
		self.ch = self.input:sub(self.read_position, self.read_position)
	end

	self.position = self.read_position
	self.read_position = self.read_position + 1
end

function Lexer:next_token()
	local tok

	if self.ch == "=" then
		tok = token.new(token.type.ASSIGN, self.ch)
	elseif self.ch == "(" then
		tok = token.new(token.type.LPAREN, self.ch)
	elseif self.ch == ")" then
		tok = token.new(token.type.RPAREN, self.ch)
	elseif self.ch == "+" then
		tok = token.new(token.type.PLUS, self.ch)
	elseif self.ch == "{" then
		tok = token.new(token.type.LBRACE, self.ch)
	elseif self.ch == "}" then
		tok = token.new(token.type.RBRACE, self.ch)
	elseif self.ch == "" then
		tok = token.new(token.type.EOF, "")
	end

	self:read_char()
	return tok
end

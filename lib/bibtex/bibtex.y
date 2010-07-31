#
# A BibTeX grammar for the parser generator +racc+
#
# The parser expects a BibTeX as input file and returns an array
# containing the corresponding `string', `preamble', `comment', and
# `entry' fields.
#
# Author:: Sylvester Keil (http://sylvester.keil.or.at)
# Copyright:: Copyright (c) 2010 Sylvester Keil
# License:: GNU GPL 3.0
#
class BibTeX::Parser
rule
	target : { result = Bibliography.new }
         | objects { result = Bibliography.new(val[0]) }

  objects : object { result = [val[0]] }
          | objects object { result << val[1] }

  object : AT at_object { result = val[1] }

  at_object : comment { result = val[0] }
            | string { result = val[0] }

  comment : COMMENT LBRACE comment_content RBRACE { result = BibTeX::Comment.new(val[2]) }
						
  comment_content : COMMENT_CONTENT { result = val[0] }
                  | comment_content COMMENT_CONTENT { result << val[1] }
  
  string : STRING LBRACE string_assignment RBRACE { result = BibTeX::String.new(val[2][0],val[2][1]); }

  string_assignment : NAME EQ string_value { result = [val[0].downcase.to_sym, val[2]] }

  string_value : string_literal { result = [val[0]] }
               | string_value SHARP string_literal { result << val[2] }

  string_literal : NAME { result = val[0].downcase.to_sym }
                 | STRING_LITERAL { result = val[0] }

end

---- header
require 'logger'

---- inner

	@@log = Logger.new(STDOUT)
	@@log.level = Logger::DEBUG
	
	COMMENT_MODE = 0
	BIBTEX_MODE = 1

  OBJECT_COMMENT = 0
  OBJECT_STRING = 1
  OBJECT_PREAMBLE = 2
  OBJECT_ENTRY = 3

	def initialize
		super
		@yydebug = true
    clear_state
  end

  # sets all internal variables to initial state
  def clear_state
    @stack = []
    @brace_level = 0
    @current_object = nil
    @mode = COMMENT_MODE
	end

	# pushes a value onto the parse stack
	def push(value)
		@stack.push(value)
	end
	
	# called when parser encounters a new BibTeX object
	def enter_object(post_match)
		@@log.debug("Entering object: switching to BibTeX mode")
		@brace_level = 0
		@mode = BIBTEX_MODE
		push [:AT,'@']

    case post_match
    when /\Astring/io
      @current_object = OBJECT_STRING
      push [:STRING, $&]
      post_match = $'
    when /\Apreamble/io
      @current_object = OBJECT_PREAMBLE
      push [:PREAMBLE, $&]
      post_match = $'
    when /\Acomment/io
      @current_object = OBJECT_COMMENT
      push [:COMMENT, $&]
      post_match = $'
    when /\A\w+/io
      @current_object = OBJECT_ENTRY
			push [:NAME, $&]
      post_match = $'
    end
		post_match
	end
	
	# called when parser leaves a BibTeX object
	def leave_object
		@@log.debug("leaving object: switching to comment mode")
		@brace_level = 0
		@mode = COMMENT_MODE
    @current_object = nil
		push [:RBRACE,'}']
	end
	
	def bibtex_mode?
		@mode == BIBTEX_MODE
	end

  def comment_mode?
		@mode == comment_MODE
  end

  def is_comment?
    @current_object == OBJECT_COMMENT
  end

	# lexical analysis
	def parse(str)
		until str.empty?
			if bibtex_mode?
				case str
				when /\A[\t\n\s]*\{[\t\n\s]*/o
          str = lbrace($&,$')
				when /\A[\t\n\s]*\}[\t\n\s]*/o
          str = rbrace($&,$')
				when /\A[\t\n\s]*=[\t\n\s]*/o
					push is_comment? ? [:COMMENT_CONTENT,$&] : [:EQ, '=']
					str = $'
				when /\A[\t\n\s]*,[\t\n\s]*/o
					push is_comment? ? [:COMMENT_CONTENT,$&] : [:COMMA, ',']
					str = $'
				when /\A[\t\n\s]*#[\t\n\s]*/o
					push is_comment? ? [:COMMENT_CONTENT,$&] : [:SHARP, '#']
					str = $'
				when /\A\d+/o
					push is_comment? ? [:COMMENT_CONTENT,$&] : [:NUMBER, $&.to_i]
					str = $'
				when /\A\w+/o
					push is_comment? ? [:COMMENT_CONTENT,$&] : [:NAME, $&]
					str = $'
				when /\A"(\\.|[^\\"])*"|'(\\.|[^\\'])*'/o
					push is_comment? ? [:COMMENT_CONTENT,$&] : [:STRING_LITERAL, $&[1..-2]]
					str = $'
				when /\A.|\n/o
					s = $&
					push is_comment? ? [:COMMENT_CONTENT,s] : [s,s]
					str = $'
				end
			else
				str = str.match(/.*^@[\t\n\s]*/o) ? enter_object($') : ''
			end
		end
		push [false, '$end']
		@@log.debug("The Stack: %s" % @stack.inspect)
		do_parse
	end
	
	# handles opening brace
	#
	# Braces are balanced inside BibTeX objects with the exception of
	# with the exception of braces occurring within string literals.
	# 
	def lbrace(match, post_match)
		raise(ParseError, 'Parsed left brace in comment mode') unless bibtex_mode?
		
		# check whether entering a new object or a braced string
		if @brace_level == 0		
			@brace_level += 1
			push [:LBRACE,'{']
		else
			@brace_level += 1
			push is_comment? ? [:COMMENT_CONTENT,match] : [:LBRACE, '{']
		end
		post_match
	end
	
	# handles closing brace
	#
	# Braces are balanced inside BibTeX objects with the exception of
	# with the exception of braces occurring within string literals.
	# 
	def rbrace(match, post_match)
		raise(ParseError, 'Parsed right brace in comment mode') unless bibtex_mode?

		if @brace_level == 1
			leave_object
		else
      @brace_level -= 1
			push is_comment? ? [:COMMENT_CONTENT,match] : [:RBRACE, '}']
		end
		post_match
	end
	
	def next_token
		@stack.shift
	end
	
	def to_s
		"Stack #{@stack.inspect}; Brace Level #{@brace_level}"
	end
	
	def on_error(tid, val, vstack)
		#raise(ParseError, "Failed to parse BibTeX on value %s (%s) %s" % [val.inspect, token_to_str(tid) || '?', vstack.inspect])
		@@log.error("Failed to parse BibTeX on value %s (%s) %s" % [val.inspect, token_to_str(tid) || '?', vstack.inspect])
	end
---- footer

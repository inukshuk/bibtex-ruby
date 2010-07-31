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
            | preamble { result = val[0] }
            | entry { result = val[0] }

  comment : COMMENT LBRACE content RBRACE { result = BibTeX::Comment.new(val[2]) }
	
  content : /* empty */ { result = '' }
          | CONTENT { result = val[0] }
          | content CONTENT { result << val[1] }
  
  preamble : PREAMBLE LBRACE string_value RBRACE { result = BibTeX::Comment.new(val[2]) }

  string : STRING LBRACE string_assignment RBRACE { result = BibTeX::String.new(val[2][0],val[2][1]); }

  string_assignment : NAME EQ string_value { result = [val[0].downcase.to_sym, val[2]] }

  string_value : string_literal { result = [val[0]] }
               | string_value SHARP string_literal { result << val[2] }

  string_literal : NAME { result = val[0].downcase.to_sym }
                 | STRING_LITERAL { result = val[0] }

  entry : entry_head assignments RBRACE { result = val[0] << val[1] }
        | entry_head assignments COMMA RBRACE { result = val[0] << val[1] }
        | entry_head assignements RBRACE { result = val[0] }

  entry_head : NAME LBRACE NAME COMMA { result = BibTeX::Entry.new(val[0].downcase.to_sym,val[2]) }

  assignments : assignment { result = val[0] }
              | assignments COMMA assignment { result.merge(val[2]) }

  assignment : NAME EQ value { result = { val[0].downcase.to_sym => val[2] } }

  value : string_value { result = val[0] }
        | NUMBER { result = val[0] }
        | LBRACE content RBRACE { result = val[1] }

end

---- header
require 'logger'

---- inner

	@@log = Logger.new(STDOUT)
	@@log.level = Logger::DEBUG
	
	COMMENT_MODE = 0
	BIBTEX_MODE = 1
	BRACES_MODE = 2

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
    when /\A[a-z\d:_!$%&*-]+/io
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
		@mode == COMMENT_MODE
  end

  def braces_mode?
		@mode == BRACES_MODE
  end

	# lexical analysis
	def parse(str)
		until str.empty?
			unless comment_mode?
				case str
				when /\A[\t\n\s]*\{[\t\n\s]*/o
          str = lbrace($&,$')
				when /\A[\t\n\s]*\}[\t\n\s]*/o
          str = rbrace($&,$')
				when /\A[\t\n\s]*=[\t\n\s]*/o
					push braces_mode? ? [:CONTENT,$&] : [:EQ, '=']
					str = $'
				when /\A[\t\n\s]*,[\t\n\s]*/o
					push braces_mode? ? [:CONTENT,$&] : [:COMMA, ',']
					str = $'
				when /\A[\t\n\s]*#[\t\n\s]*/o
					push braces_mode? ? [:CONTENT,$&] : [:SHARP, '#']
					str = $'
				when /\A\d+/o
					push braces_mode? ? [:CONTENT,$&] : [:NUMBER, $&]
					str = $'
        when /\A[a-z\d:_!$%&*-]+/io
					push braces_mode? ? [:CONTENT,$&] : [:NAME, $&]
					str = $'
				when /\A"(\\.|[^\\"])*"|'(\\.|[^\\'])*'/o
					push braces_mode? ? [:CONTENT,$&] : [:STRING_LITERAL, $&[1..-2]]
					str = $'
				when /\A.|\n/o
					s = $&
					push braces_mode? ? [:CONTENT,s] : [s,s]
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
		# check whether entering a new object or a braced string
		if @brace_level == 0		
			@brace_level += 1
			push [:LBRACE,'{']
      @mode = BRACES_MODE if @current_object == OBJECT_COMMENT
		else
			@brace_level += 1
			push braces_mode? ? [:CONTENT,match] : [:LBRACE, '{']
      @mode = BRACES_MODE if @brace_level == 2 && @current_object == OBJECT_ENTRY
		end
		post_match
	end
	
	# handles closing brace
	#
	# Braces are balanced inside BibTeX objects with the exception of
	# with the exception of braces occurring within string literals.
	# 
	def rbrace(match, post_match)
		if @brace_level == 1
			leave_object
		else
      @brace_level -= 1
      @mode = BIBTEX_MODE if @brace_level == 1 && @current_object == OBJECT_ENTRY
			push braces_mode? ? [:CONTENT,match] : [:RBRACE, '}']
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

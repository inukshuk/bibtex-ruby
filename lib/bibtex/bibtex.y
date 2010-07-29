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
	target : space { result = [] }
	       | space objects space { result = val[1] }

  objects : object { result = [val[0]] }
          | objects space object { result << val[2] }

  object : AT space at_object { result = val[2] }

  at_object : string { result = val[0] }
						
  string : STRING space LBRACE space assignment space RBRACE { result = {:string => val[4]}; @@log.debug(val.inspect) }

  assignment : NAME space EQ space STRING_LITERAL { result = { val[0].downcase.to_sym => val[4]} }

	space : /* empty */
	      | space SPACE
	
end

---- header
require 'rubygems'
require 'log4r'
include Log4r

# TODO: RDoc for parser
---- inner

	@@log = Logger.new(self.to_s)
	@@log.outputters = Outputter.stdout
	@@log.level = DEBUG
	
	COMMENT_MODE = 0
	BIBTEX_MODE = 1
	

	def initialize
		super
		@state = {
			:stack => [],
			:sp => 0,
			:brace_level => 0,
			:mode => COMMENT_MODE
		}
		@yydebug = true
	end

	# pushes a value onto the parse stack
	def push(value)
		@state[:stack].push(value)
	end
	
	# called when parser encounters a new BibTeX object
	def enter_object(post_match)
		@@log.debug("Entering object: switching to BibTeX mode")
		@state[:sp] = @state[:stack].empty? ? 0 : @state[:stack].length - 1
		@state[:brace_level] = 0
		@state[:mode] = BIBTEX_MODE
		push [:AT,'@']
		post_match
	end
	
	# called when parser leaves a BibTeX object
	def leave_object
		@@log.debug("leaving object: switching to comment mode")
		@state[:brace_level] = 0
		@state[:mode] = COMMENT_MODE
		push [:RBRACE,'}']
	end
	
	def bibtex_mode?
		@state[:mode] == BIBTEX_MODE
	end

	# lexical analysis
	def parse(str)
		
		@@log.debug("Start")

		until str.empty?
			if bibtex_mode?
				case str
				when /\A[\t\s\n]+/o
					push [:SPACE, $&]
					str = $'
				when /\A\{/o
					str = lbrace($')
				when /\A\}/o
					str = rbrace($')
				when /\A=/o
					push [:EQ, $&]
					str = $'
				when /\A#/o
					push [:SHARP, $&]
					str = $'
				when /\A@/o
					push [:AT, $&]
					str = $'
				when /\A,/o
					push [:COMMA, $&]
					str = $'
				when /\Astring/io
					push [:STRING, $&]
					str = $'
				when /\Apreamble/io
					push [:PREAMBLE, $&]
					str = $'
				when /\Acomment/io
					push [:COMMENT, $&]
					str = $'
				when /\A\d+/o
					push [:NUMBER, $&.to_i]
					str = $'
				when /\A\w+/o
					push [:NAME, $&]
					str = $'
				when /\A"(\\.|[^\\"])*"|'(\\.|[^\\'])*'/o
					push [:STRING_LITERAL, $&[1..-2]]
					str = $'
				when /\A.|\n/o
					s = $&
					push [s,s]
					str = $'
				end
			else
				@@log.debug("In comment mode")
				str = str.match(/.*^@/o) ? enter_object($') : ''
			end
		end
		push [false, '$end']
		@@log.debug("The Stack: %s" % @state[:stack].inspect)
		do_parse
	end
	
	# handles opening brace
	#
	# Braces are balanced inside BibTeX objects with the exception of
	# with the exception of braces occurring within string literals.
	# 
	def lbrace(post_match)
		raise(ParseError, 'Parsed left brace in comment mode') unless bibtex_mode?
		
		# check whether entering a new object or a braced string
		if @state[:brace_level] == 0		
			@state[:brace_level] += 1
			push [:LBRACE,'{']
		else
			# TODO
		end
		post_match
	end
	
	# handles closing brace
	#
	# Braces are balanced inside BibTeX objects with the exception of
	# with the exception of braces occurring within string literals.
	# 
	def rbrace(post_match)
		raise(ParseError, 'Parsed right brace in comment mode') unless bibtex_mode?

		if @state[:brace_level] == 1
			leave_object
		else
			# TODO
		end
		post_match
	end
	
	def next_token
		@state[:stack].shift
	end
	
	def to_s
		@state.inspect
	end
	
	def on_error(tid, val, vstack)
		#raise(ParseError, "Failed to parse BibTeX on value %s (%s) %s" % [val.inspect, token_to_str(tid) || '?', vstack.inspect])
		@@log.error("Failed to parse BibTeX on value %s (%s) %s" % [val.inspect, token_to_str(tid) || '?', vstack.inspect])
	end
---- footer

parser = BibTeX::Parser.new
s = <<-EOF
%% A BibTeX File
%% name@host.com

Everything outside an object is treated as a comment
 @ <-- technically this isn't allowed, but I'm assuming all
objects start at the beginning of a line. Therefore, the `@'
symbol can occur in comments.

{ Here are just a few strings }
@string{ bar = 'foo bar' }

# One more comment:

@string {foo=  "barr"}

Some \emph{famous} last words?
I didn't think so.
EOF
puts "Trying to parse:\n----\n%s\n-----" % s
puts parser.parse(s).inspect
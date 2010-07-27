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
	target : { result = [] }
	       | objects { result = val[0] }

  objects : object { result = [val[0]] }
          | objects object { result << val[0] }

	object : string
         | preamble
         | comment

  string : AT STRING LB assignments RB opt_comma { result = [:string, val[3]] }

  comment : AT COMMENT LB value RB opt_comma { result = [:comment, val[3]] }

  preamble : AT PREAMBLE LB value RB opt_comma { result = [:preamble, val[3]] }

  assignments : assignment { result = val[0] }
              | assignments COMMA assignment { result = val[0].merge(val[2]) }

  assignment : key EQ value { result = { val[0] => val[2] } }

	value : LB text RB { result = val[1] }
	      | DQT text DQT { result = val[1] }
	      | SQT text SQT { result = val[1] }
	      | NUMBER { result = val[0] } # for @string fields a number is invalid

	text : { result = '' }
	     | WORD SYMBOL { result = val[0] }
	
	key : WORD { result = val[0].downcase.to_sym }
	
	opt_comma :
	          | COMMA

end

---- header
# TODO: RDoc

---- inner

	def parse(str)
		@q = []
		
		@yydebug = true
		
		until str.empty?
			case str
			when /\A\s+/
			when /\A@/o
				@q.push [:AT, $&]
			when /\A\{/o
				@q.push [:LB, $&]
			when /\A\}/o
				@q.push [:RB, $&]
			when /\A'/o
				@q.push [:SQT, $&]
			when /\A"/o
				@q.push [:DQT, $&]
			when /\A\\/o
				@q.push [:ESC, $&]
			when /\A=/o
				@q.push [:EQ, $&]
			when /\A,/o
				@q.push [:COMMA, $&]
			when /\Astring/io
				@q.push [:STRING, $&]
			when /\Apreamble/io
				@q.push [:PREAMBLE, $&]
			when /\Acomment/io
				@q.push [:COMMENT, $&]
			when /\A\d+/o
				@q.push [:NUMBER, $&.to_i]
			when /\A\w+/o
				@q.push [:WORD, $&]
			when /\A./o
				@q.push [:SYMBOL, $&]
			when /\A.|\n/o
				s = $&
				@q.push [s,s]
			end
			str = $'
		end
		@q.push [false, '$end']
		do_parse
	end
	
	def next_token
		@q.shift
	end
	
---- footer

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
	target : space objects space { result = val[1] }

  objects : object { result = [val[0]] }
          | objects space object { result << val[2] }

  object : AT space at_object { result = val[2] }

  at_object : string { result = val[0] }
						
  string : STRING space LBRACE space assignment space RBRACE { result = {:string => val[4]} }

  assignment : NAME space EQ space STRING_LITERAL { result = { val[0].downcase.to_sym => val[4]} }

	space : /* empty */
	      | SPACE
	
end

---- header
# TODO: RDoc

---- inner

	def parse(str)
		@q = []
		@yydebug = true
		
		until str.empty?
			case str
			when /^\s+/
				@q.push [:SPACE, $&]
			when /^\{/o
				@q.push [:LBRACE, $&]
			when /^\}/o
				@q.push [:RBRACE, $&]
			when /^=/o
				@q.push [:EQ, $&]
			when /^#/o
				@q.push [:SHARP, $&]
			when /^@/o
				@q.push [:AT, $&]
			when /^,/o
				@q.push [:COMMA, $&]
			when /^string/io
				@q.push [:STRING, $&]
			when /^preamble/io
				@q.push [:PREAMBLE, $&]
			when /^comment/io
				@q.push [:COMMENT, $&]
			when /^\d+/o
				@q.push [:NUMBER, $&.to_i]
			when /^\w+/o
				@q.push [:NAME, $&]
			when /^"(\\.|[^\\"])*"|'(\\.|[^\\'])*'/o
				@q.push [:STRING_LITERAL, $&[1..-2]]
#			when /^.|\n/o
#				s = $&
#				@q.push [s,s]
#			when /^([^@].*)?\n/o
#				@q.push [:JUNK, $&]
			end
			str = $'
		end
		@q.push [false, '$end']
		do_parse
	end
	
	def next_token
		@q.shift
	end
	
	def on_error(token, val, vstack)
		raise(ParseError, "Failed to parse BibTeX on value %s (%s) %s" % [val.inspect, token_to_str(token) || '?', vstack.inspect]) 
	end
---- footer

parser = BibTeX::Parser.new
s = <<-EOF

@string{ bar = 'foo bar' }

EOF
puts "Trying to parse:\n----\n%s\n-----" % s
puts parser.parse(s).inspect
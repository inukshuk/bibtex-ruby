class BibTeX::Parser
rule
	target : { result = [] }
	       | objects { result = val[0] }

  objects : object { result = [val[0]] }
          | objects object { result << val[0] }

	object : string
         | preamble
         | comment

  string : AT STRING LB value RB opt_comma { result = [:string, val[3]] }

  comment : AT COMMENT LB value RB opt_comma { result = [:comment, val[3]] }

  preamble : AT PREAMBLE LB value RB opt_comma { result = [:preamble, val[3]] }

  value : NUMBER

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
			when /\A,/o
				@q.push [:COMMA, $&]
			when /\Astring/io
				@q.push [:STRING, $&]
			when /\Apreamble/io
				@q.push [:PREAMBLE, $&]
			when /\Acomment/io
				@q.push [:COMMENT, $&]
			when /\A\d+/
				@q.push [:NUMBER, $&.to_i]
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

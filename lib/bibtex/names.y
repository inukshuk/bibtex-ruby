#--
# BibTeX-Ruby
# Copyright (C) 2010-2011  Sylvester Keil <http://sylvester.keil.or.at>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
#
# A BibTeX grammar for the parser generator +racc+
#

# -*- racc -*-

class BibTeX::NameParser

token COMMA UWORD LWORD PWORD AND ERROR SORT

expect 0

rule

  result :                                          { result = [] }
         | names                                    { result = val[0] }

	names : name                                      { result = [val[0]] }
	      | names AND name                            { result << val[2] }
	
	name : word                                       { result = Name.new(:last => val[0]) }
	     | u_words word                               { result = Name.new(:first => val[0], :last => val[1]) }
	     | von last                                 { result = Name.new(:von => val[0], :last => val[1]) }
	     | u_words von last                         { result = Name.new(:first => val[0], :von => val[1], :last => val[2]) }
	     | sort first   { result = Name.new(:von => val[0][0], :last => val[0][1], :jr => val[1][0], :first => val[1][1]) }
	
	last : LWORD                                     { result = val[0] }
	     | u_words                                  { result = val[0] }
	
	sort : word { result = [nil,val[0]]}
	     | von last  { result = [val[0],val[1]]}
	
	first : COMMA opt_words { result = [nil,val[1]] }
	   | COMMA opt_words COMMA opt_words   { result = [val[1],val[3]] }
	
	u_words : u_word                                  { result = val[0] }
	        | u_words u_word                          { result = val[0,2].join(' ') }

	u_word : UWORD                                    { result = val[0] }
	       | PWORD                                    { result = val[0] }

	von : LWORD                                       { result = val[0] }
	    | von u_words LWORD                           { result = val[0,3].join(' ') }
	    | von LWORD                                   { result = val[0,2].join(' ') }
		
	words : word                                      { result = val[0] }
	      | words word                                { result = val[0,2].join(' ') }

	opt_words :                                       { result = nil }
	          | words                                 { result = val[0] }
	
	word : LWORD                                      { result = val[0] }
	     | UWORD                                      { result = val[0] }
	     | PWORD                                      { result = val[0] }

end

---- header
require 'strscan'

---- inner
  
  def initialize(options = {})
		self.options.merge(options)
  end

	def options
		@options ||= { :debug => ENV['DEBUG'] == true }
	end
	
  def parse(input)
    @yydebug = options[:debug]
    scan(input)
    do_parse
  end
  
  def next_token
    @stack.shift
  end
  
  def on_error(tid, val, vstack)
    BibTeX.log.error("Failed to parse BibTeX Name on value %s (%s) %s" % [val.inspect, token_to_str(tid) || '?', vstack.inspect])
  end

	def scan(input)
		@src = StringScanner.new(input)
		@brace_level = 0
		@stack = []
		@word = [:PWORD,'']
		do_scan
	end
  
	private

	def do_scan
		until @src.eos?
			case
			when @src.scan(/\s+and\s+/io)
				push_word
				@stack.push([:AND,@src.matched])
				
			when @src.scan(/[\t\r\n\s]+/o)
				push_word
			
			when @src.scan(/,/o)
				push_word
				@stack.push([:COMMA,@src.matched])
				
			when @src.scan(/[[:lower:]][^\t\r\n\s\{\}\d\\,]*/o)
				is_lowercase
				@word[1] << @src.matched

			when @src.scan(/[[:upper:]][^\t\r\n\s\{\}\d\\,]*/o)
				is_uppercase
				@word[1] << @src.matched
				
			when @src.scan(/(\d|\\.)+/o)
				@word[1] << @src.matched
				
			when @src.scan(/\{/o)
				scan_literal(@src.matched)
				
			when @src.scan(/\}/o)
				error_unbalanced

			when @src.scan(/./o)
				@word[1] << @src.matched
			end
		end
		
		push_word
		# @stack.unshift([:SORT,nil]) if @stack.detect { |token| token[0] == :COMMA }
		@stack
	end
	
	def push_word
		unless @word[1].empty?
			@stack.push(@word)
			@word = [:PWORD,'']
		end
	end
	
	def is_lowercase
		@word[0] = :LWORD if @word[0] == :PWORD
	end

	def is_uppercase
		@word[0] = :UWORD if @word[0] == :PWORD
	end
	
	def scan_literal(content = '')
		@brace_level += 1
		content << @src.scan_until(/[^\\][\{\}]/o).to_s # TODO accept empty braces {}
		case @src.matched
		when /\{/
			scan_braced_expression(content)
		when /\}/
			@brace_level -= 1
			if @brace_level >= 0
				@word[1] << content
			else
				error_unbalanced
			end
		else
			error_unbalanced
		end
	end

	def error_unexpected
		@stack.push [:ERROR,@src.matched]
		BibTeX.log.warn("NameParser: unexpected token `#{@src.matched}' at position #{@src.pos}; brace level #{@brace_level}.")
	end
	
	def error_unbalanced
		@stack.push [:ERROR,'}']
		BibTeX.log.warn("NameParser: unbalanced braces at position #{@src.pos}; brace level #{@brace_level}.")
	end
	
# -*- racc -*-
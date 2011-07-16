#--
# BibTeX-Ruby
# Copyright (C) 2010-2011 Sylvester Keil <http://sylvester.keil.or.at>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.	If not, see <http://www.gnu.org/licenses/>.
#++

require 'strscan'
require 'forwardable'

module BibTeX
	
	#
	# The BibTeX::Lexer handles the lexical analysis of BibTeX bibliographies.
	#
	class Lexer
	  extend Forwardable
    include Enumerable

		attr_reader :options, :stack, :mode, :scanner
		attr_writer :mode
		
    def_delegator :@scanner, :string, :data
    def_delegators :@stack, :each

    DEFAULTS = { :include => [:errors], :strict => true }.freeze
    
    MODE = Hash.new(:meta).merge(:bibtex => :bibtex, :entry => :bibtex, :string => :bibtex, :preamble => :bibtex, :comment => :bibtex, :meta => :meta, :literal => :literal, :content => :content).freeze
    
		#
		# Creates a new instance. Possible options and their respective
		# default values are:
		#
		# - :include => [:errors] A list that may contain :meta_content, and
		#		:errors; depending on whether or not these are present, the respective
		#		tokens are included in the parse tree.
		# - :strict => true In strict mode objects can start anywhere; therefore
		#		the `@' symbol is not possible except inside literals or @comment
		#		objects; for a more lenient lexer set to false and objects are
		#		expected to start after a new line (leading white space is permitted).
		#
		def initialize(options = {})
      @options = DEFAULTS.merge(options)
      reset
		end

    def reset
			@stack, @brace_level, @mode, @active_object = [], 0, :meta, nil
			@scanner.reset if @scanner
			
			# cache options for speed
			@include_meta_content = @options[:include].include?(:meta_content)
			@include_errors = @options[:include].include?(:errors)
			
			self
    end
    
		# Sets the source for the lexical analysis and resets the internal state.
		def data=(data)
			@scanner = StringScanner.new(data)
		  reset
		end

    def symbols; @stack.map(&:first); end
    
		# Returns the next token from the parse stack.
		def next_token; @stack.shift; end

		# Returns true if the lexer is currenty parsing a BibTeX object.
		def bibtex_mode?
			MODE[@mode] == :bibtex
		end
				
		[:meta, :literal, :content].each do |m|
      define_method("#{m}_mode?") { @mode == m }
		end

		# Returns true if the lexer is currently parsing the given object type.
		def active?(object)
			@active_object == object
		end
		
		# Returns true if the lexer is currently in strict mode.
		def strict?; !!(@options[:strict]); end
		
		# Pushes a value onto the parse stack. Returns the Lexer.
		def push(value)
			case value[0]
      when :CONTENT, :STRING_LITERAL
        if !@stack.empty? && value[0] == @stack[-1][0]
				  @stack[-1][1] << value[1]
				else
  				@stack.push(value)
				end
			when :ERROR
				@stack.push(value) if @include_errors
				leave_object
			when :META_CONTENT				
        @stack.push(value) if @include_meta_content
			else
				@stack.push(value)
			end
						
			self
		end

		# Start the lexical analysis.
		def analyse(string = nil)
			raise(ArgumentError, 'Lexer: failed to start analysis: no source given!') unless
			  string || @scanner		

			self.data = string || @scanner.string
			
      until @scanner.eos?
        send("parse_#{MODE[@mode]}")
			end
			
			push([false, '$end'])
		end

    private
    
		def parse_bibtex
			case
			when @scanner.scan(/[\t\r\n\s]+/o)
			when @scanner.scan(/\{/o)
				@brace_level += 1
				push([:LBRACE,'{'])
				@mode = :content if @brace_level > 1 || @brace_level == 1 && active?(:comment)
			when @scanner.scan(/\}/o)
				@brace_level -= 1
				push([:RBRACE,'}'])
				return leave_object if @brace_level == 0
				return error_unbalanced_braces if @brace_level < 0
			when @scanner.scan( /=/o)
				push([:EQ,'='])
			when @scanner.scan(/,/o)
				push([:COMMA,','])
			when @scanner.scan(/\d+/o)
				push([:NUMBER,@scanner.matched])
			when @scanner.scan(/[a-z\d \/:_!$\.%&*-]+/io)
				push([:NAME,@scanner.matched.rstrip])
			when @scanner.scan(/"/o)
				@mode = :literal
			when @scanner.scan(/#/o)
				push([:SHARP,'#'])
			when @scanner.scan(/@/o)
				enter_object
			when @scanner.scan(/./o)
				error_unexpected_token				
			end
		end
		
		def parse_meta
			match = @scanner.scan_until(strict? ? /@[\t ]*/o : /(^|\n)[\t ]*@[\t ]*/o)
			if @scanner.matched
				push([:META_CONTENT,match.chop])
				enter_object
			else
				push([:META_CONTENT,@scanner.rest])
				@scanner.terminate
			end
		end

		def parse_content
			match = @scanner.scan_until(/\{|\}/o)
			case @scanner.matched
			when '{'
				@brace_level += 1
				push([:CONTENT,match])
			when '}'
				@brace_level -= 1
				case
				when @brace_level == 0
					push([:CONTENT,match.chop])
					push([:RBRACE,'}'])
					leave_object
				when @brace_level == 1 && !active?(:comment)
					push([:CONTENT,match.chop])
					push([:RBRACE,'}'])
					@mode = :bibtex
				when @brace_level < 0
					push([:CONTENT,match.chop])
					error_unbalanced_braces
				else
					push([:CONTENT,match])
				end
			else
				push([:CONTENT,@scanner.rest])
				@scanner.terminate
				error_unterminated_content
			end
		end
		
		def parse_literal
			match = @scanner.scan_until(/[\{\}"]/o)
			case @scanner.matched
			when '{'
				@brace_level += 1
				push([:STRING_LITERAL,match])
			when '}'
				@brace_level -= 1
				if @brace_level < 1
					push([:STRING_LITERAL,match.chop])
					error_unbalanced_braces
				else
					push([:STRING_LITERAL,match])
				end
			when '"'
				if @brace_level == 1
					push([:STRING_LITERAL,match.chop])
					@mode = :bibtex
				else
					push([:STRING_LITERAL,match])
				end
			when "\n"
				push([:STRING_LITERAL,match.chop])
				error_unterminated_string
			else
				push([:STRING_LITERAL,@scanner.rest])
				@scanner.terminate
				error_unterminated_string
			end
		end
		
		# Called when the lexer encounters a new BibTeX object.
		def enter_object
			@brace_level = 0
			push [:AT,'@']

			case
			when @scanner.scan(/string/io)
				@mode = @active_object = :string
				push [:STRING, @scanner.matched]
			when @scanner.scan(/preamble/io)
				@mode = @active_object = :preamble
				push [:PREAMBLE, @scanner.matched]
			when @scanner.scan(/comment/io)
				@mode = @active_object = :comment
				push [:COMMENT, @scanner.matched]
			when @scanner.scan(/[a-z\d:_!\.$%&*-]+/io)
				@mode = @active_object = :entry
				push [:NAME, @scanner.matched]
      else
        error_unexpected_object
			end
		end

		# Called when parser leaves a BibTeX object.
		def leave_object
			@mode, @active_object, @brace_level = :meta, nil, 0
		end

		def error_unbalanced_braces
			Log.warn("Lexer: unbalanced braces at #{@scanner.pos}; brace level #{@brace_level}; mode #{@mode.inspect}.")
			backtrace [:E_UNBALANCED, @scanner.matched]
		end
		
		def error_unterminated_string
			Log.warn("Lexer: unterminated string at #{@scanner.pos}; brace level #{@brace_level}; mode #{@mode.inspect}.")
			backtrace [:E_UNTERMINATED_STRING, @scanner.matched]
		end

		def error_unterminated_content
			Log.warn("Lexer: unterminated content at #{@scanner.pos}; brace level #{@brace_level}; mode #{@mode.inspect}.")
			backtrace [:E_UNTERMINATED_CONTENT, @scanner.matched]
		end
		
		def error_unexpected_token
			Log.warn("Lexer: unexpected token `#{@scanner.matched}' at #{@scanner.pos}; brace level #{@brace_level}; mode #{@mode.inspect}.")
			backtrace [:E_UNEXPECTED_TOKEN, @scanner.matched]
		end

		def error_unexpected_object
			Log.warn("Lexer: unexpected object at #{@scanner.pos}; brace level #{@brace_level}; mode #{@mode.inspect}.")
			backtrace [:E_UNEXPECTED_OBJECT, '@']
		end

    def backtrace(error)
      bt = []
      bt.unshift(@stack.pop) until @stack.empty? || (!bt.empty? && [:AT,:META_CONTENT].include?(bt[0][0]))
      bt << error
      push [:ERROR,bt]
    end
    
	end
	
end

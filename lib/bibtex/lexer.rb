#--
# BibTeX-Ruby
# Copyright (C) 2010  Sylvester Keil <http://sylvester.keil.or.at>
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

require 'strscan'


module BibTeX
  
  #
  # The BibTeX::Lexer handles the lexical analysis of BibTeX bibliographies.
  #
  class Lexer

    attr_reader :src, :options, :stack
    
    #
    # Creates a new instance. Possible options and their respective
    # default values are:
    #
    # - :include => [:errors] A list that may contain :meta_comments, and
    #   :errors; depending on whether or not these are present, the respective
    #   tokens are included in the parse tree.
    # - :strict => true In strict mode objects can start anywhere; therefore
    #   the `@' symbol is not possible except inside literals or @comment
    #   objects; for a more lenient lexer set to false and objects are
    #   expected to start after a new line (leading white space is permitted).
    #
  	def initialize(options={})
      @options = options
  		@options[:include] ||= [:errors]
  		@options[:strict] = true unless @options.has_key?(:strict)
  		@src = nil
    end

    # Sets the source for the lexical analysis and resets the internal state.
    def src=(src)
      @stack = []
      @brace_level = 0
      @mode = :meta
      @active_object = nil
      @src = StringScanner.new(src)
      @line_breaks = []
      @line_breaks << @src.pos until @src.scan_until(/\n|$/).empty?
      @src.reset
  	end

    # Returns the line number at a given position in the source.
    def line_number_at(index)
      @line_breaks.find_index { |n| n >= index }
    end
    
    # Returns the next token from the parse stack.
    def next_token
      @stack.shift
    end

  	def mode=(mode)
  		Log.debug("Lexer: switching to #{mode} mode...")

  		@active_object = case
  		  when [:comment,:string,:preamble,:entry].include?(mode) then mode
  		  when mode == :meta then nil
  		  else @active_object
  		end

  		@mode = mode
  	end
  	
  	def mode
  	  @mode
  	end

    # Returns true if the lexer is currenty parsing a BibTeX object.
    def bibtex_mode?
      [:bibtex,:comment,:string,:preamble,:entry].include?(self.mode)
    end
    
    # Returns true if the lexer is currently parsing meta comments.
    def meta_mode?
      self.mode == :meta
    end

    # Returns true if the lexer is currently parsing a braced-out expression.
    def content_mode?
      self.mode == :content
    end

    # Returns true if the lexer is currently parsing a string literal.
    def literal_mode?
      self.mode == :literal
    end
    
    # Returns true if the lexer is currently parsing the given object type.
    def is_active?(object)
      @active_object == object
    end
    
  	# Pushes a value onto the parse stack.
  	def push(value)
  	  case
  	  when ([:CONTENT,:STRING_LITERAL].include?(value[0]) && value[0] == @stack.last[0])
        @stack.last[1][0] << value[1]
      when value[0] == :ERROR
        self.pop_until(:AT).each { |t| value[1] << t }
        @stack.push(value)
      else
        value[1] = [value[1], line_number_at(@src.pos)]
        @stack.push(value)
      end
      return self
  	end

  	# Start the lexical analysis.
  	def analyse(src=nil)
  	  raise(ArgumentError, 'Lexer: failed to start analysis: no source given!') if src.nil? && @src.nil?
      Log.debug('Lexer: starting lexical analysis...')
  	  
  	  self.src = src || @src.string
  	  self.src.reset
  	  
  		until self.src.eos?
  			case
        when self.bibtex_mode?
          parse_bibtex
  			when self.meta_mode?
  			  parse_meta
        when self.content_mode?
          parse_content
  			when self.literal_mode?
  			  parse_literal
  			end
  		end
  		
  		Log.debug('Lexer: finished lexical analysis.')
  		push [false, '$end']
  	end

    def parse_bibtex
      case
      when self.src.scan(/[\t\r\n\s]+/o)
		  when self.src.scan(/\{/o)
		    lbrace
		  when self.src.scan(/\}/o)
		    rbrace
      when self.src.scan( /=/o)
        push [:EQ,'=']
      when self.src.scan(/,/o)
        push [:COMMA,',']
      when self.src.scan(/#/o)
        push [:SHARP,'#']
      when self.src.scan(/\d+/o)
        push [:NUMBER,self.src.matched]
      when self.src.scan(/[a-z\d:_!$%&*-]+/io)
        push [:NAME,self.src.matched]
      when self.src.scan(/"/o)
        self.mode = :literal
      when self.src.scan(/.|\n/o)
        push [self.src.matched,self.src.matched]
      end
    end
    
    def parse_meta
			m = self.src.scan_until(@options[:strict] ? /@[\t ]*/o : /(^|\n)[\t ]*@[\t ]*/o)
			unless m.nil?
        push [:META_COMMENT,m.chop] if @options[:include].include?(:meta_comments)
        enter_object
      else
        push [:META_COMMENT,self.src.rest] if @options[:include].include?(:meta_comments)
        self.src.terminate
      end
    end

    def parse_content
      m = self.src.scan_until(/\{|\}/o)
      unless m.nil?
        push [:CONTENT,m.chop]
        self.src.matched == '{' ? lbrace : rbrace
      else
        n = line_number_at(self.src.pos)
        Log.warn("Lexer: unterminated braces on line #{n}.")
        push [:ERROR,[[:ERROR,[self.src.rest,n]]]] if @options[:include].include?(:errors)
        self.src.terminate
      end
    end
    
    def parse_literal
			m = self.src.scan_until(/[\{\}"]/o)
			unless m.nil?
        push [:STRING_LITERAL,m.chop]
			  case self.src.matched
				when '{' then lbrace
				when '}' then rbrace
				when '"' then if @brace_level == 1 then self.mode = :bibtex else push [:STRING_LITERAL,self.src.matched] end
				end
			else
        n = line_number_at(self.src.pos)
        Log.warn("Lexer: unterminated string literal at position #{n}.")
        push [:ERROR,[[:ERROR,[self.src.rest,n]]]] if @options[:include].include?(:errors)
        self.src.terminate
      end
    end
    
  	# Called when the lexer encounters a new BibTeX object.
  	def enter_object
  		@brace_level = 0
  		self.mode = :bibtex
  		push [:AT,'@']

      case
      when self.src.scan(/string/io)
        self.mode = :string
        push [:STRING, self.src.matched]
      when self.src.scan(/preamble/io)
        self.mode = :preamble
        push [:PREAMBLE, self.src.matched]
      when self.src.scan(/comment/io)
        self.mode = :comment
        push [:COMMENT, self.src.matched]
      when self.src.scan(/[a-z\d:_!$%&*-]+/io)
        self.mode = :entry
  			push [:NAME, self.src.matched]
      end
  	end

  	# Called when parser leaves a BibTeX object.
  	def leave_object
  		self.mode = :meta
  		@brace_level = 0
  		push [:RBRACE,'}']
  	end

    #
  	# Handles opening braces.
  	# Braces must be balanced inside BibTeX objects.
  	#
  	def lbrace
  	  @brace_level += 1
  	  if self.literal_mode?
				push [:STRING_LITERAL,self.src.matched]
  	  else
    		# check whether entering a new object or a braced string
    		if @brace_level == 1
    			push [:LBRACE,'{']
          self.mode = :content if is_active?(:comment)
    		else
    			push self.content_mode? ? [:CONTENT,self.src.matched] : [:LBRACE, '{']
          self.mode = :content if @brace_level == 2 && is_active?(:entry)
    		end
    	end
  	end

  	# handles closing brace
  	#
  	# Braces are balanced inside BibTeX objects with the exception of
  	# with the exception of braces occurring within string literals.
  	# 
  	def rbrace
  	  if self.literal_mode?
    	  @brace_level -= 1
  			push [:STRING_LITERAL,self.src.matched]
			else
    		if @brace_level == 1
    			leave_object
    		else
          @brace_level -= 1
          self.mode = :bibtex if @brace_level == 1 && is_active?(:entry)
    			push self.content_mode? ? [:CONTENT,self.src.matched] : [:RBRACE, '}']
    		end
    	end
  	end

  	def to_s
  	  [self.class,10*'+-',"Stack: #{@stack.inspect}","@brace_level #{@brace_level}; Mode: #{@mode.inspect}"].join("\n")
  	end
  	
  	private
  	
  	def pop_until(token)
  	  bt = []
  	  last_token = nil
  	  while !@stack.empty? && last_token != token do
  	    last_token = bt.unshift(@stack.pop)[0][0]
  	  end
  	  return bt
  	end

  end
  
end
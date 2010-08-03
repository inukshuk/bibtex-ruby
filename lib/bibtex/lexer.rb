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
    
  	def initialize(options={})
      @options = options
  		@options[:include] ||= []
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
    def braces_mode?
      self.mode == :braces
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
  	  value[1] = [value[1], line_number_at(@src.pos)]
  	  case
  	  when ([:CONTENT,:STRING_LITERAL].include?(value[0]) && value[0] == @stack.last[0])
        @stack.last[1][0] << value[1][0]
      when value[0] == :ERROR
        self.pop_until(:AT).each { |t| value[1][0] << t }
        @stack.push(value)
      else
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
  				case
          when self.src.scan(/[\t\r\n\s]+/o)
				  when self.src.scan(/\{/o) then lbrace
				  when self.src.scan(/\}/o) then rbrace
          when self.src.scan( /=/o) then push [:EQ,'=']
          when self.src.scan(/,/o) then push [:COMMA,',']
          when self.src.scan(/#/o) then push [:SHARP,'#']
          when self.src.scan(/\d+/o) then push [:NUMBER,self.src.matched]
          when self.src.scan(/[a-z\d:_!$%&*-]+/io) then push [:NAME,self.src.matched]
          when self.src.scan(/"/o) then self.mode = :literal
          when self.src.scan(/.|\n/o) then push [self.src.matched,self.src.matched]
          end
  			when self.meta_mode?
  				data = self.src.scan_until(/(^|\n)[\t ]*@[\t ]*/o)
  				unless data.nil?
            push [:META_COMMENT,data.chop] if @options[:include].include?(:meta_comments)
            enter_object
          else
            push [:META_COMMENT,self.src.rest] if @options[:include].include?(:meta_comments)
            self.src.terminate
          end
        when self.braces_mode?
          data = self.src.scan_until(/\{|\}/o)
          unless data.nil?
            push [:CONTENT,data.chop]
            self.src.matched == '{' ? lbrace : rbrace
          else
            Log.warn("Lexer: unterminated braces at position #{self.src.pos}.")
            push [:ERROR,[[:ERROR,self.src.rest]]]
            self.src.terminate
          end
  			when self.literal_mode?
  				data = self.src.scan_until(/[\{\}"]/o)
  				unless data.nil?
            push [:STRING_LITERAL,data.chop]
  				  case self.src.matched
  					when '{' then lbrace
  					when '}' then rbrace
  					when '"' then if @brace_level == 1 then self.mode = :bibtex else push [:STRING_LITERAL,self.src.matched] end
  					end
  				else
            Log.warn("Lexer: unterminated string literal at position #{self.src.pos}.")
            push [:ERROR,[[:ERROR,self.src.rest]]]
            self.src.terminate
          end
  			end
  		end
  		
  		Log.debug('Lexer: finished lexical analysis.')
  		push [false, '$end']
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
          self.mode = :braces if is_active?(:comment)
    		else
    			push self.braces_mode? ? [:CONTENT,self.src.matched] : [:LBRACE, '{']
          self.mode = :braces if @brace_level == 2 && is_active?(:entry)
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
    			push self.braces_mode? ? [:CONTENT,self.src.matched] : [:RBRACE, '}']
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
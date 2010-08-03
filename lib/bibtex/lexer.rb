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

module BibTeX
  
  #
  # The BibTeX::Lexer handles the lexical analysis of BibTeX bibliographies.
  #
  class Lexer

    attr_reader :src, :options
    
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
      @src = src
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
  		if ([:CONTENT,:STRING_LITERAL].include?(value[0]) && value[0] == @stack.last[0])
        @stack.last[1] << value[1]
      else
        @stack.push(value)
      end
      return self
  	end

  	# Start the lexical analysis.
  	def analyse(src=nil)
  	  raise(ArgumentError, 'Lexer: failed to start analysis: no source given!') if src.nil? && @src.nil?
      Log.debug('Lexer: starting lexical analysis...')
  	  
  	  self.src = src unless src.nil?
  	  data = self.src
  	  
  	  # main analysis loop
  		until data.empty?
  			case
        when self.bibtex_mode?
  				data = case data
            when /\A[\t\r\n\s]+/o
              $'
  				  when /\A\{/o
              lbrace($&,$')
  				  when /\A\}/o
              rbrace($&,$')
            when /\A=/o
              push [:EQ,'=']
              $'
            when /\A,/o
              push [:COMMA,',']
              $'
            when /\A#/o
              push [:SHARP,'#']
              $'
            when /\A\d+/o
              push [:NUMBER,$&]
              $'
            when /\A[a-z\d:_!$%&*-]+/io
              push [:NAME,$&]
              $'
            when /\A"/o
  						self.mode = :literal
  						$'
            when /\A.|\n/o
              push [$&,$&]
              $'
            end
  			when self.meta_mode?
  				data = if data.match(/.*^[\t ]*@[\t ]*/o)
              push [:META_COMMENT,$`] if @options[:include].include?(:meta_comments)
              enter_object($')
            else
              ''
            end
        when self.braces_mode?
          data.match(/\{|\}/o)
          push [:CONTENT,$`]
          data = case $& 
  				  when '{' then lbrace($&,$')
  				  when '}' then rbrace($&,$')
            else ''
            end
  			when self.literal_mode?
  				data.match(/[\{\}"]/o)
          push [:STRING_LITERAL,$`]
  				data = case $&
  					when '{'
  						@brace_level += 1
  						push [:STRING_LITERAL,$&]
  		      	$'
  					when '}'
  						@brace_level -= 1
  						push [:STRING_LITERAL,$&]
  		      	$'
  					when '"'
  						if @brace_level == 1 then self.mode = :bibtex else push [:STRING_LITERAL,$&] end
  						$'
  					else ''
  					end
  			end
  		end
  		
  		Log.debug('Lexer: finished lexical analysis.')
  		push [false, '$end']
  	end


  	# Called when the lexer encounters a new BibTeX object.
  	def enter_object(post_match)
  		@brace_level = 0
  		self.mode = :bibtex
  		push [:AT,'@']

      case post_match
      when /\Astring/io
        self.mode = :string
        push [:STRING, $&]
      when /\Apreamble/io
        self.mode = :preamble
        push [:PREAMBLE, $&]
      when /\Acomment/io
        self.mode = :comment
        push [:COMMENT, $&]
      when /\A[a-z\d:_!$%&*-]+/io
        self.mode = :entry
  			push [:NAME, $&]
      end
      
  		return $'
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
  	def lbrace(match, post_match)
  		# check whether entering a new object or a braced string
  		if @brace_level == 0		
  			@brace_level += 1
  			push [:LBRACE,'{']
        self.mode = :braces if is_active?(:comment)
  		else
  			@brace_level += 1
  			push self.braces_mode? ? [:CONTENT,match] : [:LBRACE, '{']
        self.mode = :braces if @brace_level == 2 && is_active?(:entry)
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
        self.mode = :bibtex if @brace_level == 1 && is_active?(:entry)
  			push self.braces_mode? ? [:CONTENT,match] : [:RBRACE, '}']
  		end
  		post_match
  	end

  	def to_s
  	  [self.class,10*'+-',"Stack: #{@stack.inspect}","@brace_level #{@brace_level}; Mode: #{@mode.inspect}"].join("\n")
  	end

  end
  
end
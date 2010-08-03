#--
# BibTeX-Ruby
# Copyright (C) 2010  Sylvester Keil <sylvester.keil.or.at>
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
# The parser expects a BibTeX as input file and returns an array
# containing the corresponding `string', `preamble', `comment', and
# `entry' fields.
#
class BibTeX::Parser
rule
	target : /* empty */                             { result = Bibliography.new }
         | objects                                 { result = val[0] }

  objects : object                                 { result = Bibliography.new << val[0] }
          | objects object                         { result << val[1] }

  object : AT at_object                            { result = val[1] }
         | META_COMMENT                            { result = BibTeX::MetaComment.new(val[0]) }

  at_object : comment                              { result = val[0] }
            | string                               { result = val[0] }
            | preamble                             { result = val[0] }
            | entry                                { result = val[0] }

  comment : COMMENT LBRACE content RBRACE          { result = BibTeX::Comment.new(val[2]) }
	
  content : /* empty */                            { result = '' }
          | CONTENT                                { result = val[0] }
  
  preamble : PREAMBLE LBRACE string_value RBRACE   { result = BibTeX::Preamble.new(val[2]) }

  string : STRING LBRACE string_assignment RBRACE  { result = BibTeX::String.new(val[2][0],val[2][1]); }

  string_assignment : NAME EQ string_value         { result = [val[0].downcase.to_sym, val[2]] }

  string_value : string_literal                    { result = [val[0]] }
               | string_value SHARP string_literal { result << val[2] }

  string_literal : NAME                            { result = val[0].downcase.to_sym }
                 | STRING_LITERAL                  { result = val[0] }

  entry : entry_head assignments RBRACE            { result = val[0] << val[1] }
        | entry_head assignments COMMA RBRACE      { result = val[0] << val[1] }
        | entry_head RBRACE                        { result = val[0] }

  entry_head : NAME LBRACE NAME COMMA              { result = BibTeX::Entry.new(val[0].downcase.to_sym,val[2]) }

  assignments : assignment                         { result = val[0] }
              | assignments COMMA assignment       { result.merge!(val[2]) }

  assignment : NAME EQ value                       { result = { val[0].downcase.to_sym => val[2] } }

  value : string_value                             { result = val[0] }
        | NUMBER                                   { result = val[0] }
        | LBRACE content RBRACE                    { result = val[1] }

end

---- header

---- inner

  attr_reader :options

	MODE = {
		:comment => 'comment mode',
		:bibtex => 'BibTeX mode',
		:braces => 'braces mode',
		:literal => 'literal mode'
	}

	OBJECT = {
		:comment => '@comment',
		:string => '@string',
		:preamble => '@preamble',
		:entry => 'BibTeX entry'
	}

	def initialize(options={})
    @options = {}.merge(options)
		@options[:debug] = @options.has_key?(:debug) ? @options[:debug] : false
		@options[:include] = @options.has_key?(:include) ? @options[:include] : []

    @yydebug = @options[:debug]
    clear_state
  end

  # sets all internal variables to initial state
  def clear_state
    @yydebug = @options[:debug]
    @stack = []
    @brace_level = 0
    self.object = nil
    self.mode = :comment
	end

	def mode=(mode)
		Log.debug("Parser: switching to #{MODE[mode]}...")
		@mode = mode
	end
	
	def object=(object)
		Log.debug("Parser: trying to parse a #{OBJECT[object]} object...") unless object.nil?
		@object = object
	end

	# pushes a value onto the parse stack
	def push(value)
		if ([:CONTENT,:STRING_LITERAL].include?(value[0]) && value[0] == @stack.last[0])
      @stack.last[1] << value[1]
    else
      @stack.push(value)
    end
	end

	# called when parser encounters a new BibTeX object
	def enter_object(post_match)
		@brace_level = 0
		self.mode = :bibtex
		push [:AT,'@']

    case post_match
    when /\Astring/io
      self.object = :string
      push [:STRING, $&]
      post_match = $'
    when /\Apreamble/io
      self.object = :preamble
      push [:PREAMBLE, $&]
      post_match = $'
    when /\Acomment/io
      self.object = :comment
      push [:COMMENT, $&]
      post_match = $'
    when /\A[a-z\d:_!$%&*-]+/io
      self.object = :entry
			push [:NAME, $&]
      post_match = $'
    end
		post_match
	end
	
	# called when parser leaves a BibTeX object
	def leave_object
		self.mode = :comment
		@brace_level = 0
    self.object = nil
		push [:RBRACE,'}']
	end
	
	def bibtex_mode?
		@mode == :bibtex
	end

  def comment_mode?
		@mode == :comment
  end

  def braces_mode?
		@mode == :braces
  end

  def literal_mode?
		@mode == :literal
  end

	def is_comment?
		@object == :comment
	end

	def is_string?
		@object == :string
	end

	def is_preamble?
		@object == :preamble
	end

	def is_entry?
		@object == :entry
	end
	
	# lexical analysis
	def parse(str)
    Log.debug('Parser: beginning with lexical analysis')
		until str.empty?
			case
      when self.bibtex_mode?
				str = case str
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
			when self.comment_mode?
				str = if str.match(/.*^[\t ]*@[\t ]*/o)
            push [:META_COMMENT,$`] if @options[:include].include?(:meta_comments)
            enter_object($')
          else
            ''
          end
      when self.braces_mode?
        str.match(/\{|\}/o)
        push [:CONTENT,$`]
        str = case $& 
				  when '{' then lbrace($&,$')
				  when '}' then rbrace($&,$')
          else ''
          end
			when self.literal_mode?
				str.match(/[\{\}"]/o)
        push [:STRING_LITERAL,$`]
				str = case $&
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
		push [false, '$end']
		Log.debug('Parser: lexical analysis finished; ' + self.to_s)
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
      self.mode = :braces if self.is_comment?
		else
			@brace_level += 1
			push self.braces_mode? ? [:CONTENT,match] : [:LBRACE, '{']
      self.mode = :braces if @brace_level == 2 && self.is_entry?
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
      self.mode = :bibtex if @brace_level == 1 && self.is_entry?
			push self.braces_mode? ? [:CONTENT,match] : [:RBRACE, '}']
		end
		post_match
	end
	
	def next_token
		@stack.shift
	end
	
	def to_s
		"Stack #{@stack.inspect}; Brace Level #{@brace_level}; #{MODE[@mode]}"
	end
	
	def on_error(tid, val, vstack)
		#raise(ParseError, "Failed to parse BibTeX on value %s (%s) %s" % [val.inspect, token_to_str(tid) || '?', vstack.inspect])
		Log.error("Failed to parse BibTeX on value %s (%s) %s" % [val.inspect, token_to_str(tid) || '?', vstack.inspect])
	end

---- footer

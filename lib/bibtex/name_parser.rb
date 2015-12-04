#
# DO NOT MODIFY!!!!
# This file is automatically generated by Racc 1.4.14
# from Racc grammer file "".
#

require 'racc/parser.rb'

require 'strscan'

module BibTeX
  class NameParser < Racc::Parser

module_eval(<<'...end names.y/module_eval...', 'names.y', 132)

  @patterns = {
    :and => /,?\s+and\s+/io,
    :space => /\s+/o,
    :comma => /,/o,
    :lower => /[[:lower:]][[:lower:][:upper:]]*/uo,
    :upper => /[[:upper:]][[:lower:][:upper:].]*/uo,
    :other => /[^\s,\{\}\\[:upper:][:lower:]]+/uo,
    :lbrace => /\{/o,
    :rbrace => /\}/o,
    :braces => /[\{\}]/o,
    :escape => /\\./o,
    :last_first => /[\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}]/uo
  }

  class << self
    attr_reader :patterns
  end

  def initialize(options = {})
    self.options.merge!(options)
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
    @last_and = 0
    @stack = [[:ANDFL,'#dummy']]
    @word = [:PWORD,'']
    do_scan
  end

  private

  def do_scan
    until @src.eos?
      case
      when @src.scan(NameParser.patterns[:and])
        push_word
        @last_and = @stack.length
        @stack.push([:ANDFL,@src.matched])

      when @src.skip(NameParser.patterns[:space])
        push_word

      when @src.scan(NameParser.patterns[:comma])
        push_word
        @stack.push([:COMMA,@src.matched])

      when @src.scan(NameParser.patterns[:lower])
        is_lowercase
        @word[1] << @src.matched

      when @src.scan(NameParser.patterns[:upper])
        is_uppercase
        @word[1] << @src.matched

      when @src.scan(NameParser.patterns[:other])
        check_name_order
        @word[1] << @src.matched

      when @src.scan(NameParser.patterns[:lbrace])
        @word[1] << @src.matched
        scan_literal

      when @src.scan(NameParser.patterns[:rbrace])
        error_unbalanced

      when @src.scan(NameParser.patterns[:escape])
        @word[1] << @src.matched

      else
        error_invalid
      end
    end

    push_word
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

  def check_name_order
    return if RUBY_VERSION < '1.9'
    @stack[@last_and][0] = :ANDLF if @stack[@last_and][0] != :ANDLF && @src.matched =~ NameParser.patterns[:last_first]
  end

  def scan_literal
    @brace_level = 1

    while @brace_level > 0
      @word[1] << @src.scan_until(NameParser.patterns[:braces]).to_s

      case @src.matched
      when '{'
        @brace_level += 1
      when '}'
        @brace_level -= 1
      else
        @brace_level = 0
        error_unbalanced
      end
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

  def error_invalid
    @stack.push [:ERROR,@src.getch]
    BibTeX.log.warn("NameParser: invalid character at position #{@src.pos}; brace level #{@brace_level}.")
  end

# -*- racc -*-
...end names.y/module_eval...
##### State transition tables begin ###

racc_action_table = [
   -38,     6,   -26,   -39,    25,   -40,   -38,   -38,   -38,   -39,
   -39,   -40,   -40,    33,   -38,   -38,   -26,   -23,   -23,   -23,
   -27,    23,    34,    24,   -26,   -24,   -24,   -24,   -27,    23,
    41,    24,   -26,   -24,   -24,   -24,   -27,    23,    41,    24,
    16,    14,    17,    23,    19,    24,    16,    28,    17,    23,
    31,    24,    23,    36,    24,    23,    31,    24,   -24,   -24,
   -24,    23,    41,    24,    47,    46,    48,   -23,   -23,   -23,
    23,    49,    24,    47,    46,    48,    47,    46,    48,    47,
    46,    48,    47,    46,    48,     4,     5,     4,     5,    40,
    40,    52,    54,    52 ]

racc_action_check = [
    14,     1,    14,    16,     6,    17,    14,    14,    28,    16,
    16,    17,    17,    13,    28,    28,    19,    19,    19,    19,
    20,    20,    20,    20,    36,    36,    36,    36,    37,    37,
    37,    37,    49,    49,    49,    49,    50,    50,    50,    50,
     4,     4,     4,     5,     5,     5,    10,    10,    10,    11,
    11,    11,    21,    21,    21,    27,    27,    27,    31,    31,
    31,    32,    32,    32,    33,    33,    33,    34,    34,    34,
    35,    35,    35,    40,    40,    40,    45,    45,    45,    52,
    52,    52,    54,    54,    54,     0,     0,     2,     2,    30,
    38,    39,    43,    51 ]

racc_action_pointer = [
    79,     1,    81,   nil,    37,    40,     4,   nil,   nil,   nil,
    43,    46,   nil,    11,     0,   nil,     3,     5,   nil,    14,
    18,    49,   nil,   nil,   nil,   nil,   nil,    52,     8,   nil,
    87,    55,    58,    61,    64,    67,    22,    26,    88,    89,
    70,   nil,   nil,    90,   nil,    73,   nil,   nil,   nil,    30,
    34,    91,    76,   nil,    79,   nil,   nil,   nil ]

racc_action_default = [
    -1,   -41,    -2,    -3,   -41,   -41,   -41,    -4,    -5,    -7,
   -27,   -41,   -11,   -41,   -23,   -30,   -32,   -33,    -6,   -12,
   -13,   -41,   -19,   -32,   -33,    58,    -8,   -41,   -23,   -31,
   -10,   -26,   -27,   -36,   -14,   -41,   -15,   -16,   -41,    -9,
   -36,   -25,   -20,   -28,   -34,   -37,   -38,   -39,   -40,   -17,
   -18,   -41,   -36,   -21,   -36,   -35,   -22,   -29 ]

racc_goto_table = [
     9,    30,    29,    10,    20,     1,    26,    42,     3,     2,
     7,    38,    29,     8,    53,    11,    21,    39,    12,    22,
    37,    27,    18,    57,    29,    51,    56,   nil,   nil,    29,
   nil,    35,   nil,   nil,    50,   nil,   nil,   nil,   nil,   nil,
   nil,    55,    29 ]

racc_goto_check = [
     6,     9,    13,     7,     7,     1,     6,    11,     3,     2,
     3,     9,    13,     4,    11,     8,     8,     9,    10,    10,
     7,     8,     5,    12,    13,     9,    11,   nil,   nil,    13,
   nil,     8,   nil,   nil,     7,   nil,   nil,   nil,   nil,   nil,
   nil,     6,    13 ]

racc_goto_pointer = [
   nil,     5,     9,     8,     9,    17,    -4,    -1,    11,   -10,
    14,   -26,   -31,    -8,   nil ]

racc_goto_default = [
   nil,   nil,   nil,   nil,   nil,   nil,    44,    32,   nil,    13,
   nil,   nil,    43,    15,    45 ]

racc_reduce_table = [
  0, 0, :racc_error,
  0, 10, :_reduce_1,
  1, 10, :_reduce_none,
  1, 11, :_reduce_3,
  2, 11, :_reduce_4,
  2, 12, :_reduce_5,
  2, 12, :_reduce_6,
  1, 13, :_reduce_7,
  2, 13, :_reduce_8,
  3, 13, :_reduce_9,
  2, 13, :_reduce_10,
  1, 13, :_reduce_none,
  1, 14, :_reduce_12,
  1, 14, :_reduce_13,
  2, 14, :_reduce_14,
  2, 14, :_reduce_15,
  2, 14, :_reduce_16,
  3, 14, :_reduce_17,
  3, 14, :_reduce_18,
  1, 14, :_reduce_none,
  3, 19, :_reduce_20,
  4, 19, :_reduce_21,
  5, 19, :_reduce_22,
  1, 17, :_reduce_none,
  2, 17, :_reduce_24,
  3, 17, :_reduce_25,
  1, 18, :_reduce_none,
  1, 18, :_reduce_27,
  1, 20, :_reduce_28,
  3, 20, :_reduce_29,
  1, 16, :_reduce_30,
  2, 16, :_reduce_31,
  1, 22, :_reduce_none,
  1, 22, :_reduce_none,
  1, 23, :_reduce_none,
  2, 23, :_reduce_35,
  0, 21, :_reduce_none,
  1, 21, :_reduce_none,
  1, 15, :_reduce_none,
  1, 15, :_reduce_none,
  1, 15, :_reduce_none ]

racc_reduce_n = 41

racc_shift_n = 58

racc_token_table = {
  false => 0,
  :error => 1,
  :COMMA => 2,
  :UWORD => 3,
  :LWORD => 4,
  :PWORD => 5,
  :ANDFL => 6,
  :ANDLF => 7,
  :ERROR => 8 }

racc_nt_base = 9

racc_use_result_var = true

Racc_arg = [
  racc_action_table,
  racc_action_check,
  racc_action_default,
  racc_action_pointer,
  racc_goto_table,
  racc_goto_check,
  racc_goto_default,
  racc_goto_pointer,
  racc_nt_base,
  racc_reduce_table,
  racc_token_table,
  racc_shift_n,
  racc_reduce_n,
  racc_use_result_var ]

Racc_token_to_s_table = [
  "$end",
  "error",
  "COMMA",
  "UWORD",
  "LWORD",
  "PWORD",
  "ANDFL",
  "ANDLF",
  "ERROR",
  "$start",
  "result",
  "names",
  "name",
  "flname",
  "lfname",
  "word",
  "u_words",
  "von",
  "last",
  "comma",
  "first",
  "opt_words",
  "u_word",
  "words" ]

Racc_debug_parser = false

##### State transition tables end #####

# reduce 0 omitted

module_eval(<<'.,.,', 'names.y', 31)
  def _reduce_1(val, _values, result)
     result = [] 
    result
  end
.,.,

# reduce 2 omitted

module_eval(<<'.,.,', 'names.y', 33)
  def _reduce_3(val, _values, result)
     result = [val[0]] 
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 34)
  def _reduce_4(val, _values, result)
     result << val[1] 
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 36)
  def _reduce_5(val, _values, result)
     result = Name.new(val[1]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 39)
  def _reduce_6(val, _values, result)
             val[1][:first] = nil if val[1][:first] && val[1][:first].empty?
         result = Name.new(val[1])
       
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 45)
  def _reduce_7(val, _values, result)
               result = { :last => val[0] }
         
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 49)
  def _reduce_8(val, _values, result)
               result = { :first => val[0].join(' '), :last => val[1] }
         
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 53)
  def _reduce_9(val, _values, result)
               result = { :first => val[0].join(' '), :von => val[1], :last => val[2] }
         
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 57)
  def _reduce_10(val, _values, result)
               result = { :von => val[0], :last => val[1] }
         
    result
  end
.,.,

# reduce 11 omitted

module_eval(<<'.,.,', 'names.y', 63)
  def _reduce_12(val, _values, result)
               result = { :last => val[0] }
         
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 67)
  def _reduce_13(val, _values, result)
               result = { :last => val[0][0], :first => val[0][1..-1].join(' ') }
         
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 71)
  def _reduce_14(val, _values, result)
               result = { :last => val[0][0], :first => (val[0][1..-1] << val[1]).join(' ') }
         
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 75)
  def _reduce_15(val, _values, result)
               result = { :von => val[0], :last => val[1] }
         
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 79)
  def _reduce_16(val, _values, result)
               result = { :von => val[0], :last => val[1][0], :first => val[1][1..-1].join(' ') }
         
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 83)
  def _reduce_17(val, _values, result)
               result = { :von => val[0..1].join(' '), :last => val[2] }
         
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 87)
  def _reduce_18(val, _values, result)
               result = { :von => val[0..1].join(' '), :last => val[2][0], :first => val[2][1..-1].join(' ') }
         
    result
  end
.,.,

# reduce 19 omitted

module_eval(<<'.,.,', 'names.y', 93)
  def _reduce_20(val, _values, result)
              result = { :last => val[0], :jr => val[2][0], :first => val[2][1] }
        
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 97)
  def _reduce_21(val, _values, result)
              result = { :von => val[0], :last => val[1], :jr => val[3][0], :first => val[3][1] }
        
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 101)
  def _reduce_22(val, _values, result)
              result = { :von => val[0..1].join(' '), :last => val[2], :jr => val[4][0], :first => val[4][1] }
        
    result
  end
.,.,

# reduce 23 omitted

module_eval(<<'.,.,', 'names.y', 105)
  def _reduce_24(val, _values, result)
     result = val.join(' ') 
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 106)
  def _reduce_25(val, _values, result)
     result = val.join(' ') 
    result
  end
.,.,

# reduce 26 omitted

module_eval(<<'.,.,', 'names.y', 108)
  def _reduce_27(val, _values, result)
     result = val[0].join(' ') 
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 110)
  def _reduce_28(val, _values, result)
     result = [nil,val[0]] 
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 111)
  def _reduce_29(val, _values, result)
     result = [val[0],val[2]] 
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 113)
  def _reduce_30(val, _values, result)
     result = [val[0]] 
    result
  end
.,.,

module_eval(<<'.,.,', 'names.y', 114)
  def _reduce_31(val, _values, result)
     result << val[1] 
    result
  end
.,.,

# reduce 32 omitted

# reduce 33 omitted

# reduce 34 omitted

module_eval(<<'.,.,', 'names.y', 119)
  def _reduce_35(val, _values, result)
     result = val.join(' ') 
    result
  end
.,.,

# reduce 36 omitted

# reduce 37 omitted

# reduce 38 omitted

# reduce 39 omitted

# reduce 40 omitted

def _reduce_none(val, _values, result)
  val[0]
end

  end   # class NameParser
  end   # module BibTeX

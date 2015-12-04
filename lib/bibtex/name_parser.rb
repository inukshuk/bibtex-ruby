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

require 'strscan'

module BibTeX

  class NameParser
    # The :latin pattern will be tried first. It captures almost all names written in Latin alphabets without
    # expensive backtracking. If it failed braces are tested.
    # Other letters are captured by :other pattern. These letters are tested whether it is in the languages
    # in which names are written in `Surname Givenname` manner (e.g. Chinese, Japanese and Korean).
    Patterns = {
      :and => /and(?:\Z|\s+)/io,
      :comma => /,\s*/o,
      :space => /\s*/o,
      :sep => /[,\s]/,
      :latin => /(?:\\.)??(?:[[:upper:]]|([[:lower:]]))[[:upper:][:lower:]]*(?:\\.[[:upper:][:lower:]]*)*\.?/o,
      :other => /[^\s,\{\}\\[:upper:][:lower:]]+/o,
      :escape => /\\./o,
      :lbrace => /\{/o,
      :rbrace => /\}/o,
      :braces => /[\{\}]/o
    }
    if RUBY_VERSION < '1.9'
       Patterns[:sur_given] = / /o # never matches, since spaces is eliminated
    else
       Patterns[:sur_given] = /[\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}]/uo
    end

    def initialize(options = {})
      self.options.merge!(options)
    end

    def options
      @options ||= { :debug => ENV['DEBUG'] == true }
    end

    def parse(input)
      #p input
      @src = StringScanner.new(input)
      @src.skip(Patterns[:space])
      @names = []

      begin
        do_scan
        do_parse
      end until @src.eos?

      @names
    end

    private

    def do_parse
      args = {}

      case @wordss.length
      when 0 # never occur

      when 1
        if !@wordss[0].empty?
          if @written_sur_given # (von) last first
            if @rgt_lower
              args[:von]   = @wordss[0][0..@rgt_lower]
              args[:last]  = @wordss[0][@rgt_lower+1..@rgt_lower+1]
              args[:first] = @wordss[0][@rgt_lower+2..-1]
            else
              args[:last]  = @wordss[0][0..0]
              args[:first] = @wordss[0][1..-1]
            end

          else # first (von) last
            if @rgt_lower
              args[:first] = @wordss[0][0,@lft_lower]
              args[:von]   = @wordss[0][@lft_lower..@rgt_lower]
              args[:last]  = @wordss[0][@rgt_lower+1..-1]
            else
              args[:first] = @wordss[0][0..-2]
              args[:last]  = @wordss[0][-1..-1]
            end
          end
          args.delete(:first) if args[:first].empty?
        end

      when 2..3 # (von) last, (jr,)? first
        if @wordss.length == 3
          args[:jr]  = @wordss[1]
        end
        args[:first] = @wordss[-1]

        if !@wordss[0].empty?
          if @rgt_lower
            args[:von]   = @wordss[0][0..@rgt_lower]
            args[:last]  = @wordss[0][@rgt_lower+1..-1]
          else
            args[:last]  = @wordss[0]
          end
        end

      else
        args[:last] = @wordss.flatten(1)
      end

      @names << Name.new(args.each{|k, v| args[k] = v.join(' ')})
    end

    def do_scan
      # words list of a name
      @wordss = []
      @words = []
      # Leftmost and right most position of non-capital word respectively,
      # on the position two or more before the first comma (EOS if there is no comma).
      @lft_lower = nil
      @rgt_lower = nil
      @is_lower = nil
      # whether Chinese, Japanese or Korean detected
      @written_sur_given = false

      until @src.eos? || @src.skip(Patterns[:and])
        if @src.skip(Patterns[:comma])
          error_emptylastname if @words.length == 0 && @wordss.length == 0
          error_toomanycomma if @wordss.length == 3
          @wordss << @words
          @words = []

        else
          if @wordss.length == 0 && @words.length != 0 && @is_lower
            @lft_lower ||= @words.length - 1
            @rgt_lower   = @words.length - 1
          end
          do_word
          @words << @word
          @src.skip(Patterns[:space])
        end
      end

      error_emptyname if @words.length == 0 && @wordss.length == 0
      @wordss << @words unless @words.length == 0 && @wordss.length > 0 && !@src.eos? # ignore `,` in `,and`
    end

    def do_word
      @word = ""
      @is_lower = nil
      @brace_level = 0

      begin
        case
        when @src.scan(Patterns[:latin])
          @word << @src.matched
          @is_lower = @src[1] != nil if @is_lower == nil

        when @src.scan(Patterns[:lbrace])
          @word << @src.matched

          @brace_level = 1
          while @brace_level > 0
            @word << @src.scan_until(Patterns[:braces])

            case @src.matched
            when '{'
              @brace_level += 1
            when '}'
              @brace_level -= 1
            else
              error_unclosed
              @word << '}' * @brace_level
              @brace_level = 0
            end
          end

        when @src.scan(Patterns[:other])
          @word << @src.matched
          @written_sur_given = true if @wordss.length == 0 && @src.matched =~ Patterns[:sur_given]

        when @src.scan(Patterns[:escape])
          @word << @src.matched

        when @src.scan(Patterns[:rbrace])
          error_unopened
          # ignore matched '}'

        else
          @src.getch
          error_unexpected
        end
      end until @src.eos? || @src.check(Patterns[:sep])
    end

    def error_unexpected
      BibTeX.log.warn("NameParser: unexpected token `#{@src.matched}' at position #{@src.pos}.")
    end

    def error_unclosed
      BibTeX.log.warn("NameParser: unclosed braces at position #{@src.pos}; brace level #{@brace_level}.")
    end

    def error_unopened
      BibTeX.log.warn("NameParser: unopened braces at position #{@src.pos}; brace level #{@brace_level}.")
    end

    def error_emptyname
      BibTeX.log.warn("Nameparser: empty name at position #{@src.pos}.")
    end

    def error_emptylastname
      BibTeX.log.warn("Nameparser: empty last name at position #{@src.pos}.")
    end

    def error_toomanycomma
      BibTeX.log.warn("Nameparser: too many commas (third comma) at position #{@src.pos}.")
    end
  end

end

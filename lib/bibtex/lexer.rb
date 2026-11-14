# frozen_string_literal: true

#--
# BibTeX-Ruby
# Copyright (C) 2010-2015 Sylvester Keil <http://sylvester.keil.or.at>
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
    extend Forwardable

    attr_accessor :mode
    attr_reader :options, :stack, :scanner

    def_delegator :@scanner, :string, :data

    @defaults = {
      include: [:errors],
      strict: true,
      allow_missing_keys: false,
      strip: true,
      strip_comments: false
    }

    # bibtex.web's id_class: an identifier (field, @string or macro name)
    # may hold any printable ASCII character except white space and these
    # (illegal_id_char).
    ILLEGAL_ID_CHARS = %q{"#%'(),={}}

    # Characters of a citation key: those accepted before, plus '/' as in
    # DBLP keys (DBLP:journals/dq/RossinK99). Braces only with a key that
    # may not be empty. '-' comes last as it is spliced into a class.
    KEY_CHAR = %q([:alnum:] :_!$?.+;&*'"/-)
    private_constant :ILLEGAL_ID_CHARS, :KEY_CHAR

    class << self
      private

      # A character class for identifiers. Non-ASCII letters and digits are
      # a project extension, as is '%' unless :strip_comments makes it start
      # a comment.
      def id_char(percent:, at: true)
        illegal = percent ? ILLEGAL_ID_CHARS.delete('%') : ILLEGAL_ID_CHARS
        illegal += '@' unless at
        # Escaped because the list is spliced into a character class, where
        # ']', '\\', '^' or '-' would otherwise change its meaning.
        "[[:alnum:]!-~&&[^#{Regexp.escape(illegal)}]]"
      end

      # One word of a name. id_class allows '@' anywhere, but '@' also
      # starts the next object, which error recovery after an unterminated
      # object relies on. Identifiers cannot contain = , } # { or (, so the
      # character after '@word' decides unambiguously: a name if (after
      # white space, and TeX comments when they are stripped) it is one of
      # = , } #, an object start otherwise, e.g. at '{' or '('.
      #
      # A word that starts with '@' ends before the next '@'. Otherwise the
      # lookahead would be retried from every '@' of a long run like
      # @a@a@a... and rescan the rest of it each time, which is quadratic.
      # So @a@b = x is not a name; a@b and a@b@c still are.
      def word_pattern(percent:)
        gap = percent ? '\s*' : '(?:\s|%[^\n]*)*'
        char = id_char(percent:)
        "(?:(?!@)#{char}+|@#{id_char(percent:, at: false)}+(?=#{gap}[=,}#]))"
      end

      # A name must not start with a digit (bibtex.web).
      def name_pattern(percent:)
        /(?![[:digit:]])#{word_pattern(percent:)}/
      end

      # Several words followed by '=', e.g. Web of Science's `Early Access
      # Date'. The words are joined into one name; as before, a word
      # may start with a digit. By the rule above only the last word, which
      # is followed by '=', can start with '@'.
      def spaced_name_pattern(percent:)
        word = word_pattern(percent:)
        /#{word}(?:[\t ]+#{word})+(?=\s*=)/
      end

      def key_pattern(extra, optional:)
        /\s*[#{extra}#{KEY_CHAR}]#{optional ? '*' : '+'},/
      end
    end

    # Patterns Cache (#37: MacRuby does not cache regular expressions)
    @patterns = {
      space: /\s+/o,
      lbrace: /\s*\{/o,
      rbrace: /\s*\}\s*/o,
      braces: /\{|\}/o,
      eq: /\s*=\s*/o,
      comma: /\s*,\s*/o,
      number: /[[:digit:]]+/o,
      name: name_pattern(percent: true),
      name_without_percent: name_pattern(percent: false),
      spaced_name: spaced_name_pattern(percent: true),
      spaced_name_without_percent: spaced_name_pattern(percent: false),
      tex_comment: /%[^\n]*/o,
      tex_comments: /(?:\s*%[^\n]*)+/o,
      quote: /\s*"/o,
      unquote: /[{}"]/o,
      sharp: /\s*#\s*/o,
      object: /@/o,
      period: /./o,
      strict_next: /@[\t ]*/o,
      next: /(^|\n)[\t ]*@[\t ]*/o,
      entry: /[a-z\d:_!.$%&*-]+/io,
      string: /string/io,
      comment: /comment\b/io,
      preamble: /preamble\b/io,
      key: key_pattern('%{}', optional: false),
      optional_key: key_pattern('%', optional: true),
      key_without_percent: key_pattern('{}', optional: false),
      optional_key_without_percent: key_pattern('', optional: true)
    }

    MODE = Hash.new(:meta).merge(
      bibtex: :bibtex, entry: :bibtex,
      string: :bibtex, preamble: :bibtex,
      comment: :bibtex,  meta: :meta,
      literal: :literal, content: :content
    ).freeze

    # The parse method to call in each mode; looked up instead of built
    # with string interpolation, which would allocate once per token.
    PARSE_METHODS = { bibtex: :parse_bibtex, meta: :parse_meta,
                      literal: :parse_literal, content: :parse_content }.freeze
    private_constant :PARSE_METHODS

    # Token types at which #backtrace stops unwinding the stack.
    BACKTRACE_BOUNDARIES = %i[AT META_CONTENT].freeze
    private_constant :BACKTRACE_BOUNDARIES

    class << self
      attr_reader :defaults, :patterns
    end

    #
    # Creates a new instance. Possible options and their respective
    # default values are:
    #
    # - :include => [:errors] A list that may contain :meta_content, and
    #   :errors; depending on whether or not these are present, the respective
    #   tokens are included in the parse tree.
    # - :strict => true In strict mode objects can start anywhere; therefore
    #   the `@' symbol is not possible except inside literals or @comment
    #   objects; for a more lenient lexer set to false and objects are
    #   expected to start after a new line (leading white space is permitted).
    #   Non-strict mode also accepts field names made of several words
    #   separated by spaces or tabs and joins them with underscores.
    # - :strip => true When enabled, newlines will be stripped from quoted
    #   string values.
    # - :strip_comments => false When enabled, a '%' and the rest of its line
    #   are ignored when they appear between the tokens of a BibTeX object
    #   (biber-style TeX comments), e.g., on a line of their own or after a
    #   field. A '%' inside a braced or quoted value is never a comment.
    #
    def initialize(options = {})
      @options = Lexer.defaults.merge(options)
      reset
    end

    def reset
      @stack = []
      @brace_level = 0
      @mode = :meta
      @active_object = nil

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

    def symbols
      @stack.map(&:first)
    end

    # Returns the next token from the parse stack.
    def next_token
      @stack.shift
    end

    # Returns true if the lexer is currenty parsing a BibTeX object.
    def bibtex_mode?
      MODE[@mode] == :bibtex
    end

    %i[meta literal content].each do |m|
      define_method("#{m}_mode?") { @mode == m }
    end

    # Returns true if the lexer is currently parsing the given object type.
    def active?(object)
      @active_object == object
    end

    # Returns true if the lexer is currently in strict mode.
    def strict?
      !!@options[:strict]
    end

    def allow_missing_keys?
      !!@options[:allow_missing_keys]
    end

    def strip_comments?
      !!@options[:strip_comments]
    end

    def strip_line_breaks?
      !!options[:strip] && !active?(:comment)
    end

    # Pushes a value onto the parse stack. Returns the Lexer.
    def push(value)
      case value[0]
      when :CONTENT, :STRING_LITERAL
        value[1].gsub!(/\n\s*/, ' ') if strip_line_breaks?

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

      send(PARSE_METHODS[MODE[@mode]]) until @scanner.eos?

      push([false, '$end'])
    end

    private

    def parse_bibtex
      case
      when @scanner.skip(Lexer.patterns[:lbrace])
        @brace_level += 1
        push([:LBRACE, '{'])
        @mode = :content if @brace_level > 1 || (@brace_level == 1 && active?(:comment))
      when @scanner.skip(Lexer.patterns[:rbrace])
        @brace_level -= 1
        push([:RBRACE, '}'])
        return leave_object if @brace_level.zero?

        error_unbalanced_braces if @brace_level.negative?
      when @scanner.skip(Lexer.patterns[:eq])
        push([:EQ, '='])
      when @scanner.skip(Lexer.patterns[:comma])
        push([:COMMA, ','])
      when strip_comments? && @scanner.skip(Lexer.patterns[:tex_comment])
        # skip
      when !strict? && @scanner.skip(Lexer.patterns[spaced_name_pattern])
        # Non-strict mode only: join the words so the field name stays
        # valid BibTeX when the entry is written out again.
        push([:NAME, @scanner.matched.split(/[\t ]+/).join('_')])
      when @scanner.skip(Lexer.patterns[:number])
        push([:NUMBER, @scanner.matched])
      when @scanner.skip(Lexer.patterns[name_pattern])
        push([:NAME, @scanner.matched])
      when @scanner.skip(Lexer.patterns[:quote])
        @mode = :literal
      when @scanner.skip(Lexer.patterns[:sharp])
        push([:SHARP, '#'])
      when @scanner.skip(Lexer.patterns[:object])
        enter_object
      when @scanner.skip(Lexer.patterns[:space])
        # skip
      when @scanner.skip(Lexer.patterns[:period])
        error_unexpected_token
      end
    end

    def parse_meta
      match = @scanner.scan_until(Lexer.patterns[strict? ? :strict_next : :next])
      if @scanner.matched
        push([:META_CONTENT, match.chop])
        enter_object
      else
        push([:META_CONTENT, @scanner.rest])
        @scanner.terminate
      end
    end

    def parse_content
      match = @scanner.scan_until(Lexer.patterns[:braces])
      case @scanner.matched
      when '{'
        @brace_level += 1
        push([:CONTENT, match])
      when '}'
        @brace_level -= 1
        if @brace_level.zero?
          push([:CONTENT, match.chop])
          push([:RBRACE, '}'])
          leave_object
        elsif @brace_level == 1 && !active?(:comment)
          push([:CONTENT, match.chop])
          push([:RBRACE, '}'])
          @mode = :bibtex
        elsif @brace_level.negative?
          push([:CONTENT, match.chop])
          error_unbalanced_braces
        else
          push([:CONTENT, match])
        end
      else
        push([:CONTENT, @scanner.rest])
        @scanner.terminate
        error_unterminated_content
      end
    end

    def parse_literal
      match = @scanner.scan_until(Lexer.patterns[:unquote])
      case @scanner.matched
      when '{'
        @brace_level += 1
        push([:STRING_LITERAL, match])
      when '}'
        @brace_level -= 1
        if @brace_level < 1
          push([:STRING_LITERAL, match.chop])
          error_unbalanced_braces
        else
          push([:STRING_LITERAL, match])
        end
      when '"'
        if @brace_level == 1
          push([:STRING_LITERAL, match.chop])
          @mode = :bibtex
        else
          push([:STRING_LITERAL, match])
        end
      else
        push([:STRING_LITERAL, @scanner.rest])
        @scanner.terminate
        error_unterminated_string
      end
    end

    # Called when the lexer encounters a new BibTeX object.
    def enter_object
      @brace_level = 0
      push [:AT, '@']

      if @scanner.skip(Lexer.patterns[:string])
        @mode = @active_object = :string
        push [:STRING, @scanner.matched]
      elsif @scanner.skip(Lexer.patterns[:preamble])
        @mode = @active_object = :preamble
        push [:PREAMBLE, @scanner.matched]
      elsif @scanner.skip(Lexer.patterns[:comment])
        @mode = @active_object = :comment
        push [:COMMENT, @scanner.matched]
      elsif @scanner.skip(Lexer.patterns[:entry])
        @mode = @active_object = :entry
        push [:NAME, @scanner.matched]

        # TODO: DRY - try to parse key
        if @scanner.skip(Lexer.patterns[:lbrace])
          @brace_level += 1
          push([:LBRACE, '{'])
          @mode = :content if @brace_level > 1 || (@brace_level == 1 && active?(:comment))

          @scanner.skip(Lexer.patterns[:tex_comments]) if strip_comments?
          push [:KEY, @scanner.matched.chop.strip] if @scanner.skip(Lexer.patterns[key_pattern])
        end

      else
        error_unexpected_object
      end
    end

    # With :strip_comments, '%' starts a comment, so it cannot be part of
    # a name or key.
    def name_pattern
      strip_comments? ? :name_without_percent : :name
    end

    def spaced_name_pattern
      strip_comments? ? :spaced_name_without_percent : :spaced_name
    end

    def key_pattern
      key = allow_missing_keys? ? :optional_key : :key
      strip_comments? ? :"#{key}_without_percent" : key
    end

    # Called when parser leaves a BibTeX object.
    def leave_object
      @mode = :meta
      @active_object = nil
      @brace_level = 0
    end

    def error_unbalanced_braces
      BibTeX.log.warn("Lexer: unbalanced braces at #{@scanner.pos}; brace level #{@brace_level}; mode #{@mode.inspect}.")
      backtrace [:E_UNBALANCED, @scanner.matched]
    end

    def error_unterminated_string
      BibTeX.log.warn("Lexer: unterminated string at #{@scanner.pos}; brace level #{@brace_level}; mode #{@mode.inspect}.")
      backtrace [:E_UNTERMINATED_STRING, @scanner.matched]
    end

    def error_unterminated_content
      BibTeX.log.warn("Lexer: unterminated content at #{@scanner.pos}; brace level #{@brace_level}; mode #{@mode.inspect}.")
      backtrace [:E_UNTERMINATED_CONTENT, @scanner.matched]
    end

    def error_unexpected_token
      BibTeX.log.warn("Lexer: unexpected token `#{@scanner.matched}' at #{@scanner.pos}; brace level #{@brace_level}; mode #{@mode.inspect}.")
      backtrace [:E_UNEXPECTED_TOKEN, @scanner.matched]
    end

    def error_unexpected_object
      BibTeX.log.warn("Lexer: unexpected object at #{@scanner.pos}; brace level #{@brace_level}; mode #{@mode.inspect}.")
      backtrace [:E_UNEXPECTED_OBJECT, '@']
    end

    def backtrace(error)
      bt = []
      bt.unshift(@stack.pop) until @stack.empty? || (!bt.empty? && BACKTRACE_BOUNDARIES.include?(bt[0][0]))
      bt << error
      push [:ERROR, bt]
    end
  end
end

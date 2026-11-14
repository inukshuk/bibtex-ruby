# frozen_string_literal: true

# Benchmarks the common BibTeX-Ruby workloads on a deterministic, synthetic
# bibliography and reports the best wall time and the number of allocated
# objects for each workload.
#
#   bundle exec rake bench                      # or: ruby benchmark/run.rb
#   bundle exec rake bench N=5000 WORKLOADS=parse,to_s
#   bundle exec rake bench JSON=base.json       # save the results
#   bundle exec rake bench COMPARE=base.json    # compare with saved results
#   bundle exec rake bench:compare[origin/master]
#
# Configuration (environment variables):
#
#   N           number of entries in the bibliography (default: 1000)
#   SEED        seed of the random generator (default: 42)
#   ITERATIONS  timed runs per workload, the best one counts (default: 5)
#   WORKLOADS   comma-separated subset of the workloads (default: all)
#   MEM         set to 1 to add memory_profiler figures (needs the gem)
#   JSON        write the results as JSON to this file
#   COMPARE     JSON file of a previous run to compare the results with
#   LABEL       name of this run in JSON output and comparisons
#   BIBTEX_LIB  load BibTeX-Ruby from this lib directory instead of ./lib

begin
  require 'bundler/setup'
rescue LoadError
  nil
end

$LOAD_PATH.unshift(File.expand_path(ENV.fetch('BIBTEX_LIB', File.join(__dir__, '..', 'lib'))))

require 'json'
require 'bibtex'

# Synthetic-corpus benchmark for BibTeX-Ruby; see the comment at the top.
module BibTeXBenchmark
  # Generates a bibliography with realistic content: several entry types,
  # names with LaTeX accents and particles, @string macros, `#`
  # concatenation, month macros and abstracts. The same N and SEED always
  # produce the same input.
  class Corpus
    FIRST = ['Donald', 'Leslie', 'Edsger W.', 'Barbara', 'Grace', 'Alan', 'John', 'Ada', 'Niklaus',
             'Tony', 'Frances', 'Jean-Pierre', 'H{\\\'e}l{\\`e}ne', 'J{\\"o}rg', 'Fran{\\c{c}}ois'].freeze
    LAST = ['Knuth', 'Lamport', 'Dijkstra', 'Liskov', 'Hopper', 'Turing', 'McCarthy', 'Lovelace', 'Wirth',
            'Hoare', 'Allen', 'D{\\\'e}coret', 'van der Berg', 'de la Fontaine', 'M{\\"u}ller',
            'von Neumann', 'G{\\"o}del', 'Erd{\\H{o}}s', 'Brinch Hansen'].freeze
    WORDS = %w[analysis of algorithms the structured programming concurrent systems on a {LaTeX} type
               theory semantics verification distributed computing logic {B}ayesian networks for
               compilers caf{\\'e} na{\\"\\i}ve {\\TeX} r{\\'e}sum{\\'e} with and in large-scale \\& R\\&D].freeze
    MONTHS = %w[jan feb mar apr may jun jul aug sep oct nov dec].freeze
    STRINGS = { 'acm' => 'ACM Press', 'ieee' => 'IEEE Computer Society', 'jacm' => 'Journal of the ACM',
                'cacm' => 'Communications of the ACM', 'ny' => 'New York' }.freeze
    TYPES = %i[article book inproceedings techreport misc].freeze

    attr_reader :random

    def initialize(seed)
      @random = Random.new(seed)
    end

    def bibtex(count)
      preamble = STRINGS.map { |key, value| "@string{#{key} = {#{value}}}\n" }.join
      entries = Array.new(count) { |i| entry(i) }
      "#{preamble}@preamble{\"\\newcommand{\\noop}[1]{}\"}\n\n#{entries.join("\n")}"
    end

    def authors
      Array.new(random.rand(1..4)) { name }.join(' and ')
    end

    private

    def entry(index)
      type = TYPES.sample(random: random)
      fields = common_fields.merge(send(type))
      body = fields.map { |key, value| "  #{key.to_s.ljust(9)} = #{value}" }.join(",\n")
      "@#{type}{key#{index},\n#{body}\n}\n"
    end

    def common_fields
      {
        author: "{#{authors}}",
        title: "{#{words(4..10).sub(/\A[a-z]/, &:upcase)}}",
        year: random.rand(1960..2025).to_s,
        month: MONTHS.sample(random: random),
        doi: "{10.1145/#{random.rand(100_000..999_999)}}",
        abstract: "{#{words(30..60)}}"
      }
    end

    def article
      { journal: %w[jacm cacm].sample(random: random), volume: random.rand(1..60).to_s, pages: pages }
    end

    def book
      { publisher: 'acm # { Press}', address: 'ny', edition: '{Second}' }
    end

    def inproceedings
      { booktitle: "{Proceedings of the #{words(2..4)}}", publisher: 'ieee', pages: pages, editor: "{#{authors}}" }
    end

    def techreport
      { institution: '{Stanford University}', number: "{CS-TR-#{random.rand(1..999)}}", note: '"Draft " # ny' }
    end

    def misc
      { howpublished: "{\\url{https://example.org/#{random.rand(1..9999)}}}", note: '{Retrieved 2024}' }
    end

    def name
      first = FIRST.sample(random: random)
      last = LAST.sample(random: random)
      random.rand < 0.5 ? "#{last}, #{first}" : "#{first} #{last}"
    end

    def words(range)
      Array.new(random.rand(range)) { WORDS.sample(random: random) }.join(' ')
    end

    def pages
      first = random.rand(1..500)
      "{#{first}--#{first + random.rand(1..40)}}"
    end
  end

  # The data the workloads operate on: the BibTeX source, a list of name
  # strings and the parsed bibliography.
  Data = Struct.new(:input, :names, :bibliography)

  # Each workload receives the Data and, if it has a setup, a fresh value
  # from that (unmeasured) setup, for workloads that mutate their input.
  WORKLOADS = {
    'parse' => ->(d, _) { BibTeX.parse(d.input) },
    'to_s' => ->(d, _) { d.bibliography.to_s },
    'names' => ->(d, _) { d.names.each { |n| BibTeX::Names.parse(n) } },
    'query' => ->(d, _) { 20.times { |y| d.bibliography.query(:article) { |e| e.year.to_i > 1990 + y } } },
    'duplicates' => ->(d, _) { d.bibliography.select_duplicates_by(:year, :title) },
    'latex' => ->(_, fresh) { fresh.convert(:latex) },
    'to_citeproc' => ->(d, _) { d.bibliography.to_citeproc },
    'to_json' => ->(d, _) { d.bibliography.to_json }
  }.freeze

  SETUPS = {
    'latex' => ->(d) { BibTeX.parse(d.input) }
  }.freeze

  # Runs the workloads and collects time and allocation figures.
  class Runner
    attr_reader :config, :data

    def initialize(config)
      @config = config
      corpus = Corpus.new(config[:seed])
      input = corpus.bibtex(config[:n]).freeze
      names = Array.new(config[:n]) { corpus.authors }.freeze
      @data = Data.new(input, names, BibTeX.parse(input))
    end

    def run
      names = config[:workloads] || WORKLOADS.keys
      names.to_h { |name| [name, measure(name)] }
    end

    private

    def measure(name)
      prepare = preparation(name)
      prepare.call.call # warm-up
      result = { ms: best_time(prepare), allocated_objects: allocations(prepare.call) }
      result.merge!(memory_profile(prepare.call)) if config[:memory]
      result
    rescue KeyError
      { error: "unknown workload (known: #{WORKLOADS.keys.join(', ')})" }
    rescue StandardError, NotImplementedError => e
      { error: "#{e.class}: #{e.message[0, 120]}" }
    end

    # Returns a lambda that runs the workload's setup and returns a block
    # that runs the workload itself, so that only the latter is measured.
    def preparation(name)
      workload = WORKLOADS.fetch(name)
      setup = SETUPS.fetch(name, ->(_) {})
      lambda do
        argument = setup.call(data)
        -> { workload.call(data, argument) }
      end
    end

    # prepare.call returns a ready-to-run block whose setup is already done
    def best_time(prepare)
      seconds = Array.new(config[:iterations]) do
        block = prepare.call
        GC.start
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        block.call
        Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      end
      (seconds.min * 1000).round(2)
    end

    def allocations(block)
      GC.start
      before = GC.stat(:total_allocated_objects)
      block.call
      GC.stat(:total_allocated_objects) - before
    end

    def memory_profile(block)
      report = MemoryProfiler.report(&block)
      strings = report.allocated_objects_by_class.find { |h| h[:data] == 'String' }
      { allocated_mb: (report.total_allocated_memsize / 1_048_576.0).round(2), allocated_strings: strings&.dig(:count) }
    end
  end

  # Prints the results as a table, optionally next to a baseline.
  class Report
    def initialize(results, baseline = nil)
      @results = results
      @baseline = baseline
    end

    def print(io = $stdout)
      io.puts header
      io.puts line('workload', columns)
      @results['workloads'].each { |name, result| io.puts line(name, values(name, result)) }
    end

    private

    def header
      text = "#{@results['label']}: bibtex-ruby #{@results['bibtex']}, ruby #{@results['ruby']}, " \
             "N=#{@results['n']} (#{@results['entries']} entries), SEED=#{@results['seed']}, " \
             "best of #{@results['iterations']}"
      text += "\ncompared with #{@baseline['label']} (bibtex-ruby #{@baseline['bibtex']})" if @baseline
      text
    end

    def memory?
      @results['workloads'].each_value.any? { |result| result.key?('allocated_mb') }
    end

    def columns
      return ['base ms', 'ms', 'Δ ms', 'base allocs', 'allocs', 'Δ allocs'] if @baseline

      %w[ms allocs] + (memory? ? ['alloc MB', 'strings'] : [])
    end

    def values(name, result)
      return [result['error']] if result['error']
      return result.values_at('ms', 'allocated_objects', 'allocated_mb', 'allocated_strings') unless @baseline

      base = @baseline.dig('workloads', name) || {}
      %w[ms allocated_objects].flat_map do |key|
        [base[key], result[key], delta(base[key], result[key])]
      end
    end

    def line(name, cells)
      name.ljust(12) + cells.first(columns.size).map { |cell| cell.to_s.rjust(12) }.join
    end

    def delta(base, value)
      return '' unless base.is_a?(Numeric) && value.is_a?(Numeric) && base.positive?

      format('%+.1f%%', ((value - base) * 100.0) / base)
    end
  end

  def self.config
    {
      n: Integer(ENV.fetch('N', '1000')),
      seed: Integer(ENV.fetch('SEED', '42')),
      iterations: Integer(ENV.fetch('ITERATIONS', '5')),
      workloads: ENV['WORKLOADS']&.split(',')&.map(&:strip),
      memory: ENV['MEM'] == '1' && memory_profiler?
    }
  end

  def self.memory_profiler?
    require 'memory_profiler'
    true
  rescue LoadError
    warn 'MEM=1 needs the memory_profiler gem (bundle install --with profile); skipping memory figures'
    false
  end

  def self.results(config)
    runner = Runner.new(config)
    {
      'label' => ENV.fetch('LABEL', 'current'), 'bibtex' => BibTeX::Version::STRING, 'ruby' => RUBY_VERSION,
      'n' => config[:n], 'entries' => runner.data.bibliography.length, 'seed' => config[:seed],
      'iterations' => config[:iterations], 'workloads' => JSON.parse(JSON.generate(runner.run))
    }
  end

  def self.run
    results = results(config)
    File.write(ENV.fetch('JSON'), JSON.pretty_generate(results)) if ENV['JSON']
    baseline = JSON.parse(File.read(ENV.fetch('COMPARE'))) if ENV['COMPARE']
    Report.new(results, baseline).print
  end
end

BibTeXBenchmark.run if $PROGRAM_NAME == __FILE__

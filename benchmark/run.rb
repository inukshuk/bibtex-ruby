# frozen_string_literal: true

# Benchmarks the common BibTeX-Ruby workloads on a deterministic, synthetic
# bibliography and reports the best wall time and the number of allocated
# objects for each workload.
#
#   bundle exec rake bench                      # or: ruby benchmark/run.rb
#   bundle exec rake bench N=5000 WORKLOADS=parse,to_s
#   bundle exec rake bench JSON=base.json       # save the results
#   bundle exec rake bench COMPARE=base.json    # compare with saved results
#   bundle exec rake 'bench:compare[origin/master]'   # quote it for zsh
#
# The exit status is 1 if the configuration is invalid or if a workload
# raised an error (the error is shown below the table).
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
#
# If the loaded lib/ keeps Entry::MONTHS_FILTER as a Hash, the benchmark
# clears it before each run so that the figures do not depend on earlier
# runs.

begin
  require 'bundler/setup'
rescue LoadError
  nil
end

# The script's own diagnostics are written to $stderr directly, because rake
# runs it with -W0, which turns Kernel#warn into a no-op.
LIB = File.expand_path(ENV.fetch('BIBTEX_LIB', File.join(__dir__, '..', 'lib')))
abort "BIBTEX_LIB: #{LIB}/bibtex.rb does not exist" unless File.file?(File.join(LIB, 'bibtex.rb'))

$LOAD_PATH.unshift(File.realpath(LIB))

require 'json'
require 'bibtex'

loaded = $LOADED_FEATURES.find { |file| File.basename(file) == 'bibtex.rb' }
abort "BIBTEX_LIB: loaded #{loaded} instead of a file in #{LIB}" unless loaded&.start_with?("#{File.realpath(LIB)}/")

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
      names = config[:workloads]
      names.to_h { |name| [name, measure(name)] }
    end

    private

    def measure(name)
      prepare = preparation(name)
      reset_global_state
      prepare.call.call # warm-up
      result = { ms: best_time(prepare), allocated_objects: allocations(prepare) }
      result.merge!(memory_profile(prepare)) if config[:memory]
      result
    rescue StandardError, NotImplementedError => e
      { error: "#{e.class}: #{e.message[0, 120]}", at: e.backtrace&.first }
    end

    # Clears Entry::MONTHS_FILTER if the loaded lib/ keeps it as a Hash, so
    # that the figures do not depend on the history of the process.
    def reset_global_state
      filter = BibTeX::Entry::MONTHS_FILTER if defined?(BibTeX::Entry::MONTHS_FILTER)
      filter.clear if filter.respond_to?(:clear) && !filter.frozen?
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
        reset_global_state
        GC.start
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        block.call
        Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      end
      (seconds.min * 1000).round(2)
    end

    def allocations(prepare)
      block = prepare.call
      reset_global_state
      GC.start
      before = GC.stat(:total_allocated_objects)
      block.call
      GC.stat(:total_allocated_objects) - before
    end

    def memory_profile(prepare)
      block = prepare.call
      reset_global_state
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
      errors.each { |name, result| io.puts "#{name}: #{result['error']} (#{result['at']})" }
    end

    def errors
      @results['workloads'].select { |_, result| result['error'] }
    end

    private

    def header
      text = "#{@results['label']}: bibtex-ruby #{@results['bibtex']} (#{@results['lib']}), " \
             "ruby #{@results['ruby']}, N=#{@results['n']} (#{@results['entries']} entries), " \
             "SEED=#{@results['seed']}, best of #{@results['iterations']}"
      text += "\ncompared with #{@baseline['label']} (bibtex-ruby #{@baseline['bibtex']}, #{@baseline['lib']})" if @baseline
      text
    end

    def memory?(results = @results)
      results['workloads'].each_value.any? { |result| result.key?('allocated_mb') }
    end

    # The figures shown next to the baseline: allocated MB only when both
    # runs were made with MEM=1.
    def compared
      %w[ms allocated_objects] + (memory? && memory?(@baseline) ? ['allocated_mb'] : [])
    end

    def columns
      unless @baseline
        return %w[ms allocs] + (memory? ? ['alloc MB', 'strings'] : [])
      end

      ['base ms', 'ms', 'Δ ms', 'base allocs', 'allocs', 'Δ allocs', 'base MB', 'MB', 'Δ MB'].first(compared.size * 3)
    end

    def values(name, result)
      return ['error (see below)'] if result['error']
      return result.values_at('ms', 'allocated_objects', 'allocated_mb', 'allocated_strings') unless @baseline

      base = @baseline.dig('workloads', name)
      placeholder = base.nil? ? 'n/a' : 'error'
      base = {} if base.nil? || base['error']
      compared.flat_map do |key|
        [base.fetch(key, placeholder), result[key], delta(base[key], result[key])]
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
      n: positive('N', '1000'), seed: Integer(ENV.fetch('SEED', '42')), iterations: positive('ITERATIONS', '5'),
      workloads: workloads, memory: ENV['MEM'] == '1' && memory_profiler?
    }
  end

  def self.positive(name, default)
    value = Integer(ENV.fetch(name, default))
    abort "#{name} must be at least 1 (got #{value})" if value < 1
    value
  end

  # An empty or missing list selects all workloads; unknown names abort.
  def self.workloads
    names = ENV.fetch('WORKLOADS', '').split(',').map(&:strip).reject(&:empty?)
    return WORKLOADS.keys if names.empty?

    unknown = names - WORKLOADS.keys
    abort "unknown workload(s): #{unknown.join(', ')} (known: #{WORKLOADS.keys.join(', ')})" unless unknown.empty?
    names.uniq
  end

  def self.memory_profiler?
    require 'memory_profiler'
    true
  rescue LoadError
    note 'MEM=1 needs the memory_profiler gem (bundle install --with profile); skipping memory figures'
    false
  end

  # The version of the library under test, read from its version.rb:
  # bundler/setup may already have loaded another one from ./lib.
  def self.library_version
    text = File.read(File.join(LIB, 'bibtex', 'version.rb'))
    %w[MAJOR MINOR PATCH BUILD].filter_map { |part| text[/^\s*#{part}\s*=\s*(\d+)/, 1] }.join('.')
  end

  def self.results(config)
    runner = Runner.new(config)
    {
      'label' => ENV.fetch('LABEL', 'current'), 'bibtex' => library_version, 'lib' => LIB, 'ruby' => RUBY_VERSION,
      'n' => config[:n], 'entries' => runner.data.bibliography.length, 'seed' => config[:seed],
      'iterations' => config[:iterations], 'workloads' => JSON.parse(JSON.generate(runner.run))
    }
  end

  def self.note(text)
    $stderr.write("note: #{text}\n")
  end

  # Notes when the baseline was measured with other settings.
  def self.check_comparable(results, baseline)
    %w[n seed iterations].each do |key|
      next if baseline[key] == results[key]

      note "baseline #{key} is #{baseline[key]}, this run #{results[key]}; the comparison may not be meaningful"
    end
    check_workloads(results['workloads'], baseline['workloads'])
  end

  def self.check_workloads(current, base)
    (current.keys - base.keys).each { |name| note "baseline has no #{name} workload" }
    base.each { |name, result| note "baseline #{name} failed" if result['error'] }
  end

  def self.run
    baseline = JSON.parse(File.read(ENV.fetch('COMPARE'))) if ENV['COMPARE']
    results = results(config)
    File.write(ENV.fetch('JSON'), JSON.pretty_generate(results)) if ENV['JSON']
    check_comparable(results, baseline) if baseline
    report = Report.new(results, baseline)
    report.print
    exit 1 unless report.errors.empty?
  end
end

BibTeXBenchmark.run if $PROGRAM_NAME == __FILE__

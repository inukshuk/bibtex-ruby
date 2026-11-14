# frozen_string_literal: true

require 'helper'
require 'pathname'
require 'tmpdir'

module BibTeX
  # R3 (REQUIREMENTS.md): BibTeX::Bibliography#save_to and #save.
  class BibliographySaveTest < Minitest::Spec
    SOURCE = <<~BIBTEX
      @book{melville,
        author = {Melville, Herman},
        title = {Moby-Dick; or, The Whale},
        year = 1851
      }
      @book{goethe,
        author = {von Goethe, Johann Wolfgang},
        title = {Die Leiden des jungen Werthers: Über Lotte, Ärger und Liebe},
        address = {Leipzig – Weygand},
        year = 1774
      }
    BIBTEX

    describe 'R3 saving' do
      before do
        @dir = Dir.mktmpdir('bibtex-save')
        @path = File.join(@dir, 'out.bib')
        @bib = BibTeX.parse(SOURCE)
      end

      after { FileUtils.remove_entry(@dir) }

      def spy_on_to_s(bib)
        calls = []
        original = bib.method(:to_s)
        bib.define_singleton_method(:to_s) do |options = {}|
          calls << options
          original.call(options)
        end
        calls
      end

      describe '#save_to' do
        it 'writes to_s to the path' do
          @bib.save_to(@path)

          assert_equal @bib.to_s(quotes: %w[{ }]), File.read(@path, encoding: 'utf-8')
        end

        it 'returns the bibliography' do
          assert_same @bib, @bib.save_to(@path)
        end

        it 'uses { } as the default :quotes' do
          calls = spy_on_to_s(@bib)
          @bib.save_to(@path)

          assert_equal 1, calls.length
          assert_equal %w[{ }], [*calls[0][:quotes]]
        end

        it 'passes its options on to to_s' do
          calls = spy_on_to_s(@bib)
          @bib.save_to(@path, quotes: '"', custom: :option)

          assert_equal '"', calls[0][:quotes]
          assert_equal :option, calls[0][:custom]
        end

        it 'honours the :quotes option' do
          @bib.save_to(@path, quotes: '"')
          content = File.read(@path, encoding: 'utf-8')

          assert_equal @bib.to_s(quotes: '"'), content
          assert_includes content, 'title = "Moby-Dick; or, The Whale"'
        end

        it 'writes braces by default' do
          @bib.save_to(@path)

          assert_includes File.read(@path, encoding: 'utf-8'), 'title = {Moby-Dick; or, The Whale}'
        end

        it 'writes UTF-8' do
          @bib.save_to(@path)
          bytes = File.binread(@path)

          assert_predicate bytes.dup.force_encoding(Encoding::UTF_8), :valid_encoding?
          assert_includes bytes, 'Über'.b
          assert_includes bytes, '–'.b
        end

        it 'writes UTF-8 regardless of the default external encoding' do
          original = Encoding.default_external
          begin
            Encoding.default_external = Encoding::ISO_8859_1
            @bib.save_to(@path)
          ensure
            Encoding.default_external = original
          end

          assert_equal @bib.to_s.b, File.binread(@path)
        end

        it 'round-trips non-ASCII content through BibTeX.open' do
          @bib.save_to(@path)
          reopened = BibTeX.open(@path)

          assert_equal 'Die Leiden des jungen Werthers: Über Lotte, Ärger und Liebe', reopened['goethe'].title.to_s
          assert_equal 'Leipzig – Weygand', reopened['goethe'].address.to_s
          assert_equal @bib.to_s, reopened.to_s
        end

        it 'overwrites an existing file completely' do
          File.write(@path, "#{'% old content that is much longer than the new one\n' * 200}@misc{old, title = {Old}}\n")
          BibTeX.parse('@misc{new, title = {New}}').save_to(@path)

          assert_equal BibTeX.parse('@misc{new, title = {New}}').to_s, File.read(@path, encoding: 'utf-8')
          assert_equal %w[new], BibTeX.open(@path).entries.keys
        end

        it 'accepts a Pathname' do
          result = @bib.save_to(Pathname.new(@path))

          assert_same @bib, result
          assert_equal @bib.to_s, File.read(@path, encoding: 'utf-8')
        end

        it 'accepts a String' do
          @bib.save_to(@path.to_s)

          assert_equal %w[melville goethe], BibTeX.open(@path).entries.keys
        end

        it 'writes an empty bibliography as an empty file' do
          File.write(@path, 'old')
          Bibliography.new.save_to(@path)

          assert_equal '', File.read(@path)
        end

        describe 'when serialisation raises' do
          before do
            @original = "@misc{keep, title = {Keep me}}\n"
            File.write(@path, @original)
            @bib.define_singleton_method(:to_s) { |_options = {}| raise ArgumentError, 'boom' }
          end

          it 'propagates the error' do
            error = assert_raises(ArgumentError) { @bib.save_to(@path) }

            assert_equal 'boom', error.message
          end

          it 'leaves the existing file untouched' do
            assert_raises(ArgumentError) { @bib.save_to(@path) }

            assert_equal @original, File.read(@path)
          end

          it 'leaves the existing file untouched when an element fails' do
            bib = BibTeX.parse(SOURCE)
            bib['goethe'].define_singleton_method(:to_s) { |_options = {}| raise ArgumentError, 'element boom' }

            assert_raises(ArgumentError) { bib.save_to(@path) }
            assert_equal @original, File.read(@path)
          end

          it 'does not create a missing file' do
            missing = File.join(@dir, 'missing.bib')

            assert_raises(ArgumentError) { @bib.save_to(missing) }
            refute_path_exists missing
          end
        end
      end

      describe '#save' do
        before do
          File.write(@path, SOURCE)
          @opened = BibTeX.open(@path)
        end

        it 'writes back to the path the bibliography was opened from' do
          @opened.delete(:melville)
          @opened.save

          assert_equal %w[goethe], BibTeX.open(@path).entries.keys
        end

        it 'returns the bibliography' do
          assert_same @opened, @opened.save
        end

        it 'passes its options on' do
          @opened.save(quotes: '"')

          assert_includes File.read(@path, encoding: 'utf-8'), 'title = "Moby-Dick; or, The Whale"'
        end
      end

      describe 'BibTeX.open with a block' do
        it 'saves the changes to the opened file' do
          File.write(@path, SOURCE)
          BibTeX.open(@path) { |bib| bib.delete(:goethe) }

          assert_equal %w[melville], BibTeX.open(@path).entries.keys
        end

        it 'saves to the :out path instead when given' do
          File.write(@path, SOURCE)
          out = File.join(@dir, 'copy.bib')
          BibTeX.open(@path, out: out) { |bib| bib.delete(:goethe) }

          assert_equal %w[melville], BibTeX.open(out).entries.keys
          assert_equal SOURCE, File.read(@path, encoding: 'utf-8')
        end
      end
    end
  end
end

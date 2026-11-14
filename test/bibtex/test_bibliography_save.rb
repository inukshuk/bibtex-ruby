# frozen_string_literal: true

require 'helper'
require 'pathname'
require 'tmpdir'

module BibTeX
  # BibTeX::Bibliography#save_to and #save.
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

    describe 'saving' do
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

        it 'uses { } when :quotes is nil, without changing the caller\'s options' do
          calls = spy_on_to_s(@bib)
          options = { quotes: nil }
          @bib.save_to(@path, options)

          assert_equal %w[{ }], [*calls[0][:quotes]]
          assert_equal({ quotes: nil }, options)
          assert_includes File.read(@path, encoding: 'utf-8'), 'title = {Moby-Dick; or, The Whale}'
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

          # Read back in text mode: on Windows the file has CRLF line endings,
          # like any text-mode write, and reading in text mode undoes that.
          assert_equal @bib.to_s, File.read(@path, encoding: Encoding::UTF_8)
          assert_includes File.binread(@path), 'Über'.b
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

        describe 'atomic replacement' do
          # Makes every file Tempfile.create returns raise error in #fsync
          # (by default as a full disk would) for the duration of the block.
          def with_failing_fsync(error = IOError.new('disk full'))
            original = Tempfile.method(:create)
            Tempfile.define_singleton_method(:create) do |*args, **kwargs|
              original.call(*args, **kwargs).tap do |file|
                file.define_singleton_method(:fsync) { raise error }
              end
            end
            yield
          ensure
            Tempfile.define_singleton_method(:create, original)
          end

          def skip_unless_posix_permissions
            skip 'needs POSIX permissions' if Gem.win_platform?
            skip 'root ignores permission bits' if Process.uid.zero?
          end

          it 'skips fsync where the platform does not implement it' do
            with_failing_fsync(NotImplementedError.new('fsync')) { @bib.save_to(@path) }

            assert_equal @bib.to_s, File.read(@path, encoding: 'utf-8')
            assert_equal %w[out.bib], Dir.children(@dir)
          end

          it 'raises EACCES for a read-only file and leaves it as it was' do
            skip_unless_posix_permissions
            File.write(@path, 'old')
            File.chmod(0o444, @path)

            assert_raises(Errno::EACCES) { @bib.save_to(@path) }
            assert_equal 'old', File.read(@path)
            assert_equal 0o444, File.stat(@path).mode & 0o7777
          end

          it 'writes a writable file in a read-only directory directly' do
            skip_unless_posix_permissions
            File.write(@path, 'old')
            File.chmod(0o555, @dir)
            begin
              @bib.save_to(@path)
            ensure
              File.chmod(0o755, @dir)
            end

            assert_equal @bib.to_s, File.read(@path, encoding: 'utf-8')
          end

          it 'writes to a FIFO without replacing it' do
            skip 'needs File.mkfifo' if Gem.win_platform? || !File.respond_to?(:mkfifo)
            fifo = File.join(@dir, 'pipe.bib')
            File.mkfifo(fifo)
            reader = Thread.new { File.read(fifo, encoding: 'utf-8') }
            begin
              @bib.save_to(fifo)

              assert reader.join(5), 'the FIFO was not written to'
              assert_equal @bib.to_s, reader.value
              assert_equal 'fifo', File.ftype(fifo)
              assert_equal %w[pipe.bib], Dir.children(@dir)
            ensure
              reader.kill
            end
          end

          it 'creates the file a dangling symlink points to' do
            skip 'needs symlinks' if Gem.win_platform?
            link = File.join(@dir, 'link.bib')
            File.symlink('out.bib', link)
            @bib.save_to(link)

            assert File.symlink?(link)
            assert_equal @bib.to_s, File.read(@path, encoding: 'utf-8')
          end

          it 'handles a target with a 254-byte name' do
            name = "#{'a' * 250}.bib"
            path = File.join(@dir, name)
            File.write(path, 'old')
            @bib.save_to(path)

            assert_equal @bib.to_s, File.read(path, encoding: 'utf-8')
            assert_equal [name], Dir.children(@dir)
          end

          it 'writes the same bytes as a text-mode File.write' do
            reference = File.join(@dir, 'reference.bib')
            File.write(reference, @bib.to_s, encoding: Encoding::UTF_8)
            @bib.save_to(@path)

            assert_equal File.binread(reference), File.binread(@path)
            @bib.save_to(@path)

            assert_equal File.binread(reference), File.binread(@path)
          end

          it 'does not copy setuid, setgid or sticky bits' do
            skip 'needs POSIX permissions' if Gem.win_platform?
            File.write(@path, 'old')
            File.chmod(0o4755, @path)
            skip 'the file system dropped the setuid bit' unless File.stat(@path).mode & 0o7777 == 0o4755
            @bib.save_to(@path)

            assert_equal 0o755, File.stat(@path).mode & 0o7777
          end

          it 'leaves the original file and no temp file behind when the write fails' do
            original = "@misc{keep, title = {Keep me}}\n"
            File.write(@path, original)

            error = assert_raises(IOError) { with_failing_fsync { @bib.save_to(@path) } }

            assert_equal 'disk full', error.message
            assert_equal original, File.read(@path)
            assert_equal %w[out.bib], Dir.children(@dir)
          end

          it 'does not create the file when the write fails' do
            assert_raises(IOError) { with_failing_fsync { @bib.save_to(@path) } }

            assert_empty Dir.children(@dir)
          end

          it 'leaves no temp file behind after a successful save' do
            @bib.save_to(@path)

            assert_equal %w[out.bib], Dir.children(@dir)
          end

          it 'creates a missing file with 0666 minus the umask' do
            skip 'POSIX permissions' if Gem.win_platform?
            @bib.save_to(@path)

            assert_equal 0o666 & ~File.umask, File.stat(@path).mode & 0o7777
            assert_equal @bib.to_s, File.read(@path, encoding: 'utf-8')
          end

          it 'keeps the permission bits of an existing file' do
            skip 'POSIX permissions' if Gem.win_platform?
            File.write(@path, 'old')
            File.chmod(0o640, @path)
            @bib.save_to(Pathname.new(@path))

            assert_equal 0o640, File.stat(@path).mode & 0o7777
          end

          it 'replaces the file a symlink points to, not the link' do
            skip 'symlinks' if Gem.win_platform?
            File.write(@path, 'old')
            link = File.join(@dir, 'link.bib')
            File.symlink('out.bib', link)
            @bib.save_to(link)

            assert File.symlink?(link)
            assert_equal @bib.to_s, File.read(@path, encoding: 'utf-8')
            assert_equal %w[link.bib out.bib], Dir.children(@dir).sort
          end
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

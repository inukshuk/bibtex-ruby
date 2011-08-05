require 'helper'

module BibTeX
  
  class BibliographyTest < MiniTest::Spec
    
    context 'when newly created' do
      should 'not be nil' do
        assert Bibliography.new
      end
      should 'be empty' do
        assert Bibliography.new.empty?
      end
    end

    context '#open' do
      should 'accept a block and save the file after execution' do
        tmp = Tempfile.new('bibtex')
        tmp.close
        b = BibTeX.open(Test.fixtures(:bibdesk)).save_to(tmp.path)
        
        BibTeX.open(tmp.path) do |bib|
          bib.delete(:rails)
        end
        
        assert_equal b.length - 1, BibTeX.open(tmp.path).length
      end
    end
    
    context 'given a populated biliography' do
      setup do
        @bib = BibTeX.parse <<-END
        @book{rails,
          address = {Raleigh, North Carolina},
          author = {Ruby, Sam, and Thomas, Dave, and Hansson Heinemeier, David},
          booktitle = {Agile Web Development with Rails},
          edition = {third},
          keywords = {ruby, rails},
          publisher = {The Pragmatic Bookshelf},
          series = {The Facets of Ruby},
          title = {Agile Web Development with Rails},
          year = {2009}
        }
        @book{flanagan2008,
          title={{The ruby programming language}},
          author={Flanagan, D. and Matsumoto, Y.},
          keywords = {ruby},
          year={2008},
          publisher={O'Reilly}
        }
        @article{segaran2007,
          title={{Programming collective intelligence}},
          author={Segaran, T.},
          year={2007},
          publisher={O'Reilly}
        }
        END
      end
      
      should 'support access by index' do
        assert_equal 'ruby', @bib[1].keywords 
      end
      
      should 'support access by range' do
        assert_equal %w{2008 2007}, @bib[1..2].map(&:year)
      end

      should 'support access by index and offset' do
        assert_equal %w{2008 2007}, @bib[1,2].map(&:year)
      end
      
      should 'support queries by symbol key' do
        refute_nil @bib[:rails]
        assert_nil @bib[:ruby]
      end

      should 'support queries by symbol key and selector' do
        assert_equal 1, @bib.q(:all, :rails).length
        refute_nil @bib.q(:first, :rails)
        assert_nil @bib.q(:first, :railss)
      end
      
      should 'support queries by string key' do
        assert_equal 1, @bib['rails'].length
        assert_equal 0, @bib['ruby'].length
      end

      should 'support queries by type string' do
        assert_equal 2, @bib['@book'].length
        assert_equal 1, @bib['@article'].length
        assert_equal 0, @bib['@collection'].length
      end

      should 'support queries by type string and selector' do
        assert_equal 2, @bib.q(:all, '@book').length
        refute_nil @bib.q(:first, '@book')
        assert_equal 1, @bib.q(:all, '@article').length
        refute_nil @bib.q(:first, '@article')
        assert_equal 0, @bib.q(:all, '@collection').length
        assert_nil @bib.q(:first, '@collection')
      end


      should 'support queries by pattern' do
        assert_equal 0, @bib[/reilly/].length
        assert_equal 2, @bib[/reilly/i].length
      end
      
      should 'support queries by type string and conditions' do
        assert_equal 1, @bib['@book[keywords=ruby]'].length
      end

      should 'support queries by bibtex element' do
        entry = Entry.parse(<<-END).first
        @article{segaran2007,
          title = {{Programming collective intelligence}},
          author = {Segaran, T.},
          year = {2007},
          publisher = {O'Reilly}
        }
        END
        assert_equal 1, @bib[entry].length
        entry.year = '2006'
        assert_equal 0, @bib[entry].length
      end
      
      should 'support query and additional block' do
        assert_equal 1, @bib.q('@book') { |e| e.keywords.split(/,/).length > 1 }.length
      end
    
      should 'support saving the bibliography to a file' do
        tmp = Tempfile.new('bibtex')
        tmp.close
        @bib.save_to(tmp.path)
        assert_equal @bib.to_s, BibTeX.open(tmp.path).to_s
      end
      
      context 'given a filter' do
        setup do
          @filter = Object
          def @filter.apply (value); value.is_a?(::String) ? value.upcase : value; end
        end
          
        should 'support arbitrary conversions' do
          @bib.convert(@filter)
          assert_equal 'RUBY, RAILS', @bib[:rails].keywords
        end
        
        should 'support conditional arbitrary conversions' do
          @bib.convert(@filter) { |e| e.key != :rails }
          assert_equal 'ruby, rails', @bib[:rails].keywords
          assert_equal 'RUBY', @bib[:flanagan2008].keywords
        end
        
      end
      
    end
    
    
    
    
  end
end
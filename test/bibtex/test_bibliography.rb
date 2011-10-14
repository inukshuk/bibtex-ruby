# -*- encoding: utf-8 -*-

require 'helper'

module BibTeX
  
  class BibliographyTest < MiniTest::Spec
    
    describe 'when newly created' do
      it 'should not be nil' do
        assert Bibliography.new
      end
      it 'should be empty' do
        assert Bibliography.new.empty?
      end
    end

    describe '.open' do
      it 'accepts a block and save the file after execution' do
        tmp = Tempfile.new('bibtex')
        tmp.close
        b = BibTeX.open(Test.fixtures(:bibdesk)).save_to(tmp.path)
        
        BibTeX.open(tmp.path) do |bib|
          bib.delete(:rails)
        end
        
        assert_equal b.length - 1, BibTeX.open(tmp.path).length
      end

    end

		describe '.parse' do
			it 'accepts filters' do
				Bibliography.parse("@misc{k, title = {\\''u}}", :filter => 'latex')[0].title.must_be :==, 'ü'					
			end
		end
    
    describe 'given a populated biliography' do
      before do
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
      
      it 'should support access by index' do
        assert_equal 'ruby', @bib[1].keywords 
      end
      
      it 'should support access by range' do
        assert_equal %w{2008 2007}, @bib[1..2].map(&:year)
      end

      it 'should support access by index and offset' do
        assert_equal %w{2008 2007}, @bib[1,2].map(&:year)
      end
      
      it 'should support queries by symbol key' do
        refute_nil @bib[:rails]
        assert_nil @bib[:ruby]
      end

      it 'should support queries by symbol key and selector' do
        assert_equal 1, @bib.q(:all, :rails).length
        refute_nil @bib.q(:first, :rails)
        assert_nil @bib.q(:first, :railss)
      end
      
      it 'should support queries by string key' do
        refute_nil @bib['rails']
        assert_nil @bib['ruby']
      end

      it 'should support queries by type string' do
        assert_equal 2, @bib['@book'].length
        assert_equal 1, @bib['@article'].length
        assert_equal 0, @bib['@collection'].length
      end

      it 'should support queries by type string and selector' do
        assert_equal 2, @bib.q(:all, '@book').length
        refute_nil @bib.q(:first, '@book')
        assert_equal 1, @bib.q(:all, '@article').length
        refute_nil @bib.q(:first, '@article')
        assert_equal 0, @bib.q(:all, '@collection').length
        assert_nil @bib.q(:first, '@collection')
      end


      it 'should support queries by pattern' do
        assert_equal 0, @bib[/reilly/].length
        assert_equal 2, @bib[/reilly/i].length
      end
      
      it 'should support queries by type string and conditions' do
        assert_equal 1, @bib['@book[keywords=ruby]'].length
      end

      it 'should support queries by bibtex element' do
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
      
      it 'should support query and additional block' do
        assert_equal 1, @bib.q('@book') { |e| e.keywords.split(/,/).length > 1 }.length
      end
    
      it 'should support saving the bibliography to a file' do
        tmp = Tempfile.new('bibtex')
        tmp.close
        @bib.save_to(tmp.path)
        assert_equal @bib.length, BibTeX.open(tmp.path).length
      end
      
      describe 'given a filter' do
        before do
          @filter = Object
          def @filter.apply (value); value.is_a?(::String) ? value.upcase : value; end
        end
          
        it 'supports arbitrary conversions' do
          @bib.convert(@filter)
          assert_equal 'RUBY, RAILS', @bib[:rails].keywords
        end
        
        it 'supports conditional arbitrary conversions' do
          @bib.convert(@filter) { |e| e.key != 'rails' }
          assert_equal 'ruby, rails', @bib[:rails].keywords
          assert_equal 'RUBY', @bib[:flanagan2008].keywords
        end
        
      end
      
			describe 'LaTeX filter' do
				before do
					@bib['rails'].keywords = 'r\\"uby'
				end
				
				it 'converts LaTeX umlauts' do
					@bib.convert(:latex)['rails'].keywords.must_be :==, 'rüby'
				end
				
			end
			
			describe 'BibTeXML export' do
				before { @bibtexml = Tempfile.new('bibtexml') }
				after  { @bibtexml.unlink }
					
				it 'should support exporting to BibTeXML' do
					@bib.to_xml.write(@bibtexml, 2)
					@bibtexml.rewind
					xml = REXML::Document.new(@bibtexml)
					xml.root.namespace.must_be :==, 'http://bibtexml.sf.net/'
					xml.root.get_elements('//bibtex:entry').wont_be_empty
				end

				it 'should support exporting to extended BibTeXML' do
					@bib.to_xml(:extended => true).write(@bibtexml, 2)
					@bibtexml.rewind
					xml = REXML::Document.new(@bibtexml)
					xml.root.namespace.must_be :==, 'http://bibtexml.sf.net/'
					xml.root.get_elements('//bibtex:person').wont_be_empty
				end
				
			end
    end
        
    
  end
end
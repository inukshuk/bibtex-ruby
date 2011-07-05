BibTeX-Ruby
===========

BibTeX-Ruby is a fairly complete library and parser for BibTeX bibliography
files; it offers a rich interface to manage, search, or convert BibTeX objects in
Ruby. It is designed to support all BibTeX objects (including @comment,
string-replacements via @string, as well as string concatenation using '#')
and optionally handles all content outside of BibTeX objects as 'meta content'
which may or may not be included in post-processing. BibTeX-Ruby also includes
a name parser to support comfortable access to the individual tokens of name
values.


Quickstart
----------

    $ [sudo] gem install bibtex-ruby
    $ irb
    >> require 'bibtex'
    => true
    >> b = BibTeX.open('./ruby.bib')
    >> b[:pickaxe]
    => "2009"
    >> b[:pickaxe].title
    => "Programming Ruby 1.9: The Pragmatic Programmer's Guide"
    >> b[:pickaxe].author.length
    => 3
    >> b[:pickaxe].author.to_s
    => "Thomas, Dave and Fowler, Chad and Hunt, Andy"
    >> b[:pickaxe].author[2].first
    => "Andy"
    >> b['@book'].length
    => 3
    >> b['@article'].length
    => 0
    >> b['@book[year=2009]'].length
    => 1

BibTeX-Ruby helps you convert your bibliography to JSON, XML, or YAML;
alternatively, you can export to the JSON format used by
[CSL](http://citationstyles.org) processors and render the bibliography in
many styles:

    >> require 'citeproc'  # requires the citeproc-ruby gem
    => true
    >> CiteProc.process b[:pickaxe].to_citeproc, :style => :apa
    => "Thomas, D., Fowler, C., & Hunt, A. (2009). Programming Ruby 1.9: The Pragmatic Programmer's
      Guide. The Facets of Ruby. Raleigh, North Carolina: The Pragmatic Bookshelf."
    >> CiteProc.process b[:pickaxe].to_citeproc, :style => 'chicago-author-date'
    => "Thomas, Dave, Chad Fowler, and Andy Hunt. 2009. Programming Ruby 1.9: The Pragmatic
      Programmer's Guide. The Facets of Ruby.Raleigh, North Carolina: The Pragmatic Bookshelf."
    >> CiteProc.process b[:pickaxe].to_citeproc, :style => :mla
    => "Thomas, Dave, Chad Fowler, and Andy Hunt. Programming Ruby 1.9: The Pragmatic Programmer's
      Guide. Raleigh, North Carolina: The Pragmatic Bookshelf, 2009."


Installation
------------

If you just want to use it:

    $ [sudo] gem install bibtex-ruby

If you want to work with the sources:

    $ git clone http://github.com/inukshuk/bibtex-ruby.git
    $ cd bibtex-ruby
    $ [sudo] bundle install
    $ rake racc
    $ rake rdoc
    $ rake features
    $ rake test

For extra credit, fork the
[project on GitHub](http://github.com/inukshuk/bibtex-ruby.git).


Requirements
------------

* The parser generator [racc](http://i.loveruby.net/en/projects/racc/) is
  required to generate the BibTeX parser and the name parser.
* The **json** gem is required on older Ruby versions for JSON export.

The bibtex-ruby gem has been tested on Ruby versions 1.8.7 and 1.9.2; it has
been confirmed to work with REE 1.8.7 x86_64 and JRuby 1.5.6 x86_64-java;
however, there have been some [issues](https://github.com/inukshuk/bibtex-ruby/issues)
with MacRuby implementations.



Usage
-----

It is very easy to use BibTeX-Ruby. You can use the top level utility methods
**BibTeX.open** and **BibTeX.parse** to open a '.bib' file or to parse a string
containing BibTeX contents. Normally, BibTeX-Ruby will discard all text outside
of regular BibTeX elements; however, if you wish to include everything, simply add
`:include => [:meta_content]` to your invocation of **BibTeX.open** or **BibTeX.parse**.

Once BibTeX-Ruby has parsed your '.bib' file, you can easily access individual entries.
For example, if you set up your bibliography as follows:

    b = BibTeX.parse <<-END
    @book{pickaxe,
      address = {Raleigh, North Carolina},
      author = {Thomas, Dave and Fowler, Chad and Hunt, Andy},
      publisher = {The Pragmatic Bookshelf},
      series = {The Facets of Ruby},
      title = {Programming Ruby 1.9: The Pragmatic Programmer's Guide},
      year = {2009}
    }
    END
    
You could easily access it, using the entry's key, 'pickaxe', like so: `b[:pickaxe]`;
you also have easy access to individual fields, for example: `b[:pickaxe][:author]`.
Alternatively, BibTeX-Ruby accepts ghost methods to conveniently access an entry's fields,
similar to **ActiveRecord::Base**. Therefore, it is equally possible to access the
'author' field above as `b[:pickaxe].author`.

Instead of parsing strings you can also create BibTeX elements directly in Ruby:

    > bib = BibTeX::Bibliography.new
    > bib << BibTeX::Entry.new({
    >   :type => :book,
    >   :key => :rails,
    >   :address => 'Raleigh, North Carolina',
    >   :author => 'Ruby, Sam and Thomas, Dave, and Hansson, David Heinemeier',
    >   :booktitle => 'Agile Web Development with Rails',
    >   :edition => 'third',
    >   :keywords => 'ruby, rails',
    >   :publisher => 'The Pragmatic Bookshelf',
    >   :series => 'The Facets of Ruby',
    >   :title => 'Agile Web Development with Rails',
    >   :year => '2009'
    > })
    > book = BibTeX::Entry.new
    > book.type = :book
    > book.key = :mybook
    > bib << book


### Queries

Since version 1.3 BibTeX-Ruby implements a simple query language to search
Bibliographies via the `Bibliography#query` (or `Bibliography#q`) methods.
Additionally, you can access individual elements or groups of elements via
their index using `Bibliography#[]`; this accessor also exposes some of the
query functionality with the exception of yielding to a block. For instance:

    >> bib[-1]
    => Returns the last element of the Bibliography or nil
    >> bib[1,2]
    => Returns the second and third elements or nil
    >> bib[1..2]
    >> Same as above
    >> bib[:key]
    => Returns the first entry with key 'key' or nil
    >> bib['key']
    => Returns all entries with key 'key' or []
    >> bib['@article']
    => Returns all entries of type 'article' or []
    >> bib['@preamble']
    => Returns all preamble objects (this is the same as Bibliography#preambles) or []
    >> bib[/ruby/]
    => Returns all objects that match 'ruby' anywhere or []
    >> bib['@book[keywords=ruby]']
    => Returns all books whose keywords attribute equals 'ruby' or []
    >> bib.query('@book') { |e| e.keywords.split(/,/).length > 1 }
    => Returns all book entries with two or more keywords or []

Queries offer syntactic sugar for common enumerator invocations:

    >> bib.query(:all, '@book')
    => same as bib.select { |b| b.has_type?(:book) }
    >> bib.query('@book')
    => same as above
    >> bib.query(:first, '@book')
    => same as bib.detect { |b| b.has_type?(:book) }
    >> bib.query(:none, '@book')
    => same as bib.reject { |b| b.has_type?(:book) }

You can also use queries to delete entries in your bibliography:

    >> bib.delete(/ruby/)
    => deletes all object that match 'ruby' in their string representation
    >> bib.delete('@comment')
    => strips all BibTeX comments from the bibliography


### String Replacement

If your bibliography contains BibTeX @string objects, you can let BibTeX-Ruby
replace the strings for you. You have access to a bibliography's strings via
**BibTeX::Bibliography#strings** or by using a '@string' query.
You can replace the string symbols of an object by calling the object's
the **replace** method. Thus, to replace all strings defined in bibliography
b you could use the following code:

    b.each do |obj|
      obj.replace(b.q('@string'))
    end
    
A shorthand version for replacing all strings in a given bibliography is the
`Bibliography#replace` method. Similarly, you can use the
`Bibliography#join` method to join individual strings together. For instance:

    > bib = BibTeX::Bibliography.new
    > bib.add BibTeX::Element.parse '@string{ foo = "foo" }'
    > bib << BibTeX::Element.parse '@string{ bar = "bar" }'
    > bib.add BibTeX::Element.parse <<-END
    >  @book{abook,
    >    author = foo # "Author",
    >    title = foo # bar
    >  }
    > END
    > puts bib[:abook].to_s
    @book{abook,
      author = foo # "Author",
      title = foo # bar
    }
    > bib.replace
    > puts bib[:abook].to_s
    @book{abook,
      author = "foo" # "Author",
      title = "foo" # "bar"
    }
    > bib.join
    @book{abook,
      author = {fooAuthor},
      title = {foobar}
    }

### Names

Since version 1.3, BibTeX-Ruby features a name parser. You can use the top-level
`BibTeX.names` utility to quickly parse individual name values. Alternatively,
you can call `Bibliography.parse_names` to convert all name fields contained
in the bibliography. When parsing BibTeX files, BibTeX-Ruby will automatically
convert names; if you do not want the names to be parsed you can set the
`:parse_names` parser option to false.

Note that the string replacement and concatenation features described above
are not supported for name objects; therefore, BibTeX-Ruby tries to replace
and join all values before name conversion; name fields containing string
symbols that cannot be replaced will not be parsed.

In the following example, string replacement can take place, thus all names
are parsed and can easily be mapped to their last names:

    >> BibTeX.parse(<<-END)[1].author.map(&:last)
       @string{ ht = "Nathaniel Hawthorne" }
       @book{key,
         author = ht # " and Melville, Herman"
       }
       END
    => ["Hawthorne", "Melville"]

### Filters

Since version 1.3.8 BibTeX-Ruby comes with a plugin framework for input
filters. You can use the methods `convert` and `convert!` methods if `Value`,
`Entry` and `Bibliography` instances to easily convert string values according
to a given filter. Starting with version 1.3.9 BibTeX-Ruby includes a
LaTeX filter that depends on the
[latex-decode gem](http://rubygems.org/gems/latex-decode). Example:

    >> faust = '@book{faust, title = {Faust: Der Trag\"odie Erster Teil}}'
    >> BibTeX.parse(faust).convert(:latex)[:faust].title
    => "Faust: Der Tragödie Erster Teil"

Conditional conversions are also supported:

    >> faust1 = '@book{faust1, title = {Faust: Der Trag\"odie Erster Teil}}'
    >> faust2 = '@book{faust2, title = {Faust: Der Trag\"odie Zweiter Teil}}'
    >> p BibTeX.parse(faust1 + faust2).convert(:latex) { |e| e.key == :faust2 }.to_s
		@book{faust1,
		  title = {Faust: Der Trag\"odie Erster Teil}
		}
		@book{faust2,
		  title = {Faust: Der Tragödie Zweiter Teil}
		}

If you need to express a condition on the basis of individual fields, use the
conversion methods of BibTeX::Entry with a block instead (the block will be
passed the key and value of each field prior to conversion).

### Conversions

Furthermore, BibTeX-Ruby allows you to export your bibliography for processing
by other tools. Currently supported formats include YAML, JSON, and XML.
Of course, you can also export your bibliography back to BibTeX; if you include
`:meta_content', your export should be identical to the original '.bib' file,
except for whitespace, blank lines and letter case (BibTeX-Ruby will downcase
all keys).

In order to export your bibliography use **#to\_s**, **#to\_yaml**, **#to\_json**, or
**#to\_xml**, respectively. For example, the following line constitutes a simple
BibTeX to YAML converter:

    >> BibTeX.open('example.bib').to_yaml

Look at the 'examples' directory for more elaborate examples of a BibTeX to YAML
and a BibTeX to HTML converter using **#to_citeproc** to format a bibliography
using [CSL](http://citationstyles.org/).

BibTeX-Ruby offers an API which lets you manipulate BibTeX objects (string
replacement, name parsing etc.); however, sometimes you just want quick access
to your bibliography's contents. In these cases the **to_hash** method is
useful (use **to_a** if you are only interested in the bibliography's contents):
it converts all objects into simple Ruby hashes made up of symbols
and strings. Furthermore, often you would like to control what sort of quotes
are used in an export;
therefore, all conversion methods accept an options hash which lets you define
what quotes to use (note that BibTeX-Ruby will always use regular double
quotes if a value consists of more than one token, because these tokens will
be concatenated using BibTeX's '#' operator).

    >> BibTeX.parse(<<-END).to_a # implies: :quotes => ['{','}']
    @book{pickaxe,
      Address = {Raleigh, North Carolina},
      Author = {Thomas, Dave, and Fowler, Chad, and Hunt, Andy},
      Publisher = {The Pragmatic Bookshelf},
      Title = {Programming Ruby 1.9: The Pragmatic Programmer's Guide},
      Year = {2009}
    }
    END
    => [{:key=>:pickaxe, :type=>:book,
      :address=>"{Raleigh, North Carolina}",
      :author=>"{Thomas, Dave, and Fowler, Chad, and Hunt, Andy}",
      :publisher=>"{The Pragmatic Bookshelf}",
      :title=>"{Programming Ruby 1.9: The Pragmatic Programmer's Guide}",
      :year=>"{2009}"}]

For post-processing in Ruby most of the time you do not need any explicit
quotes; therefore you can simply add the :quotes option with an empty string:

    >> BibTeX.parse(<<-END).to_a(:quotes => '')
    ...
    END
    => [{:key=>:pickaxe, :type=>:book,
      :address=>"Raleigh, North Carolina",
      :author=>"Thomas, Dave, and Fowler, Chad, and Hunt, Andy",
      :publisher=>"The Pragmatic Bookshelf",
      :title=>"Programming Ruby 1.9: The Pragmatic Programmer's Guide",
      :year=>"2009"}]

The Parser
----------

The BibTeX-Ruby parser is generated using the awesome
[racc](http://i.loveruby.net/en/projects/racc/) parser generator. You can take
look at the grammar definition in the file
[lib/bibtex/bibtex.y](https://github.com/inukshuk/bibtex-ruby/blob/master/lib/bibtex/bibtex.y).

For more information about the BibTeX format and the parser's idiosyncrasies
[refer to the project wiki](https://github.com/inukshuk/bibtex-ruby/wiki/The-BibTeX-Format).


Credits
-------

The BibTeX-Ruby package was written by [Sylvester Keil](http://sylvester.keil.or.at/);
kudos and thanks to all [contributors](https://github.com/inukshuk/bibtex-ruby/contributors)!

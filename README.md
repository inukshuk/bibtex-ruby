BibTeX-Ruby
===========

The BibTeX-Ruby package contains a parser for BibTeX bibliography files and a
class structure to manage or convert BibTeX objects in Ruby. It is designed to
support all BibTeX objects (including @comment, string-replacements via @string,
as well as string concatenation using '#') and handles all content outside of
BibTeX objects as 'meta comments' which may or may not be included in
post-processing.


Quickstart
----------

    $ [sudo] gem install bibtex-ruby
    $ irb
    > require 'bibtex'
     => true
    > bib = BibTeX.open('./ruby.bib')
     => book{pickaxe,
      address  {Raleigh, North Carolina},
      author  {Thomas, Dave, and Fowler, Chad, and Hunt, Andy},
      date-added  {2010-08-05 09:54:07 0200},
      date-modified  {2010-08-05 10:07:01 0200},
      keywords  {ruby},
      publisher  {The Pragmatic Bookshelf},
      series  {The Facets of Ruby},
      title  {Programming Ruby 1.9: The Pragmatic Programmers Guide},
      year  {2009}
    }
    > bib[:pickaxe].year
     => "2009"
    > bib[:pickaxe][:title]
     => "Programming Ruby 1.9: The Pragmatic Programmer's Guide"
    > bib[:pickaxe].author = 'Thomas, D., Fowler, C., and Hunt, A.'
     => "Thomas, D., and Fowler, C., and Hunt, A."


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
    $ rake test

Or, alternatively, fork the [project on GitHub](http://github.com/inukshuk/bibtex-ruby.git).


Requirements
------------

* The parser generator [racc](http://i.loveruby.net/en/projects/racc/) is
  required to generate parser.
* The *minitest* gem is required to run the tests in older Ruby versions.
* The *json* gem is required on older Ruby versions for JSON export.

The bibtex-ruby gem has been tested on Ruby versions 1.8.7 and 1.9.2; it has
been confirmed to work with REE 1.8.7 x86_64 and JRuby 1.5.6 x86_64-java. It
does not work with MacRuby 0.8 because of a bug in MacRuby's implementation
of the *StringScanner* class, however, this has been fixed in SVN (see
[#1](https://github.com/inukshuk/bibtex-ruby/issues/closed#issue/1) for details).



Usage
-----

It is very easy to use BibTeX-Ruby. You can use the top level utility methods
**BibTeX.open** and **BibTeX.parse** to open a '.bib' file or to parse a string
containing BibTeX contents. Normally, BibTeX-Ruby will discard all text outside
of regular BibTeX elements; however, if you wish to include everything, simply add
`:include => [:meta_comments]` to your invocation of **BibTeX.open** or **BibTeX.parse**.

Once BibTeX-Ruby has parsed your '.bib' file, you can easily access individual entries.
For example, if you set up your bibliography as follows:

    bib = BibTeX.parse <<-END
    @book{pickaxe,
      address = {Raleigh, North Carolina},
      author = {Thomas, Dave, and Fowler, Chad, and Hunt, Andy},
      date-added = {2010-08-05 09:54:07 +0200},
      date-modified = {2010-08-05 10:07:01 +0200},
      keywords = {ruby},
      publisher = {The Pragmatic Bookshelf},
      series = {The Facets of Ruby},
      title = {Programming Ruby 1.9: The Pragmatic Programmer's Guide},
      year = {2009}
    }
    END
    
You could easily access it, using the entry's key, 'pickaxe', like so: `bib[:pickaxe]`;
you also have easy access to individual fields, for example: `bib[:pickaxe][:author]`.
Alternatively, BibTeX-Ruby accepts ghost methods to conveniently access an entry's fields,
similar to **ActiveRecord::Base**. Therefore, it is equally possible to access the
'author' field above as `bib[:pickaxe].author`.

Instead of parsing strings you can also create BibTeX elements by using Ruby:

    > bib = BibTeX::Bibliography.new
    > bib << BibTeX::Entry.new({
    >   :type => :book,
    >   :key => 'rails',
    >   :address => 'Raleigh, North Carolina',
    >   :author => 'Ruby, Sam, and Thomas, Dave, and Hansson, David Heinemeier',
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
    > book.key = 'mybook'
    > bib << book



### String Replacement

If your bibliography contains BibTeX @string objects, you can let BibTeX-Ruby
replace the strings for you. You have access to a bibliography's strings via
**BibTeX::Bibliography#strings** and you can replace the strings of an entry using
the **BibTeX::Entry#replace!** method. Thus, to replace all strings defined in your
bibliography object **bib** your could use this code:

    bib.entries.each do |entry|
      entry.replace!(bib.strings)
    end
    
A shorthand version for replacing all strings in a given bibliography is the
`Bibliography#replace_strings` method. Similarly, you can use the
`Bibliography#join_strings` method to join individual strings together. For instance:

    > bib = BibTeX::Bibliography.new
    > bib.add BibTeX::Element.parse '@string{ foo = "foo" }'
    > bib.add BibTeX::Element.parse '@string{ bar = "bar" }'
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
    > bib.replace_strings
    > puts bib[:abook].to_s
    @book{abook,
      author = "foo" # "Author",
      title = "foo" # "bar"
    }
    > bib.join_strings
    @book{abook,
      author = {fooAuthor},
      title = {foobar}
    }

### Conversions

Furthermore, BibTeX-Ruby allows you to export your bibliography for processing
by other tools. Currently supported formats include YAML, JSON, and XML.
Of course, you can also export your bibliography back to BibTeX; if you include
`:meta_comments', your export should be identical to the original '.bib' file,
except for whitespace, blank lines and letter case (BibTeX-Ruby will downcase
all keys).

In order to export your bibliography use **#to\_s**, **#to\_yaml**, **#to\_json**, or
**#to\_xml**, respectively. For example, the following line constitutes a simple
BibTeX to YAML converter:

    BibTeX.open('example.bib').to_yaml

Look at the 'examples' directory for more elaborate examples of a BibTeX to YAML
and a BibTeX to HTML converter.



The Parser
----------

The BibTeX-Ruby parser is generated using the wonderful
[racc](http://i.loveruby.net/en/projects/racc/) parser generator. You can take
look at the grammar definition in the file `lib/bibtex/bibtex.y`.


### The BibTeX Format

At first glance, the BibTeX file format seems very clear and simple;
however, there are a number of peculiarities which warrant some
explanation. The best place to start reading is probably at [your closest
ctan server](http://www.ctan.org/get/biblio/bibtex/) where
the original `bibtex` from 1988 still lives. Additionally, Xavier Decoret
has written
[a great summary](http://artis.imag.fr/~Xavier.Decoret/resources/xdkbibtex/bibtex_summary.html)
of the format; another invaluable source of information is [Nicolas Markey's
website](http://www.lsv.ens-cachan.fr/~markey/bibla.php). Unfortunately,
even after consulting these documents, a number of issues remain.
Therefore, it is the purpose of this section to deliver the rationale
that went into some of the design decision in BibTeX-Ruby.

A BibTeX bibliography is typically stored in a file with the file
extension '.bib'. This file may contain any number of BibTeX objects;
everything that is not a BibTeX object is assumed to be a comment and
ignored.

The individual objects are discussed in further detail below. First, however, a
number of general remarks:

* BibTeX-Ruby begins in comment-mode, treating all text it encounters as comments.
  Normally these comments are ignored; however, if you wish the parser to include
  them, you can do so by adding the symbol `:meta_comments` to the `:include` array
  in the parser's options.
* Note that string literals in BibTeX are either contained in quotes or braces;
  nested quotes in a quoted literal are not escaped with a usual backslash but
  must be placed inside braces. Nested braces must be balanced in literals, regardless
  of whether they are surrounded by quotes or braces.
* Quoted strings and string constants (which are defined by @string objects) can be
  concatted by the '#' symbol. String literals in braces can not be concatted in
  this way.
* The '@' symbol may only occur in quoted string literals (not in braced out literals)
  in the original BibTeX; note, however, that this is not true for BibTeX-Ruby (i.e.,
  it will parse any string containing an '@').

### @comment


The purpose of the @comment object is not entirely clear, because everything
outside of an object is treated as a comment anyway. Nicolas Markay argues that
a @comment makes it possible to quickly comment out a number of consecutive
objects; however, as Xavier Decoret points out that this does not work with the
original `bibtex' program (following a @comment, it simply ignores everything
until the end of the line). Indeed, on page 13 of [the original
documentation](http://www.ctan.org/get/biblio/bibtex/contrib/doc/btxdoc.pdf),
Oren Patashnik explains that @comment objects are not really necessary; they
exist only for _Scribe_ system compatibility.

Because they would be useless otherwise, BibTeX-Ruby treats @comment objects
as Nicolas Markay describes them: thus, everything inside a @comment is treated
as a comment and is ignored -- everything,
that is, until the object is closed. For this reason, BibTeX-Ruby assumes that
braces inside a @comment are balanced! Obviously, BibTeX-Ruby differs from
`bibtex` in that respect; though, the gain is, that it is now possible to
comment out a sequence of entries, without removing their respective '@' symbols.

### @string

The @string object defines a single string constant (for multiple constant
assignments, it is necessary to define separate @string objects). These
constants can be used within string assignments in other @string or @preamble
objects, as well as in regular BibTeX entries. For example, this is a valid constant
definition and usage:

    @string{ generator = "BibTeX-Ruby"}
    @preamble{ "This bibliography was generated by " # generator }


### @preamble

Typically, the purpose of @preamble objects is to define LaTeX statements, which
will be put into the '.bbl' file by `bibtex`. A @preamble object may contain
a single string literal, a single string constant (defined by a @string object), or
a concatenation of literals and constants.

### Entries

These represent proper BibTeX objects (e.g., @book, @collection, etc.).


Credits
-------

The BibTeX-Ruby package was written by [Sylvester Keil](http://sylvester.keil.or.at/).

License
-------

BibTeX-Ruby
Copyright (C) 2010-2011 [Sylvester Keil](http://sylvester.keil.or.at)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

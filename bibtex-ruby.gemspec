# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bibtex-ruby}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sylvester Keil"]
  s.cert_chain = ["/Users/sylvester/.gem/keys/gem-public_cert.pem"]
  s.date = %q{2011-01-24}
  s.description = %q{A (fairly complete) BibTeX parser written in Ruby. Supports regular BibTeX entries, @comments, string replacement via @string, and simple export formats (e.g. YAML).}
  s.email = %q{http://sylvester.keil.or.at}
  s.extra_rdoc_files = ["LICENSE", "README.rdoc", "lib/bibtex.rb", "lib/bibtex/bibliography.rb", "lib/bibtex/elements.rb", "lib/bibtex/entry.rb", "lib/bibtex/error.rb", "lib/bibtex/lexer.rb", "lib/bibtex/parser.output", "lib/bibtex/parser.rb", "lib/bibtex/string_replacement.rb", "lib/extensions/core.rb"]
  s.files = ["History.txt", "LICENSE", "Manifest", "README.rdoc", "Rakefile", "bibtex-ruby.gemspec", "examples/bib2html.rb", "examples/bib2yaml.rb", "examples/markdown.bib", "lib/bibtex.rb", "lib/bibtex/bibliography.rb", "lib/bibtex/elements.rb", "lib/bibtex/entry.rb", "lib/bibtex/error.rb", "lib/bibtex/lexer.rb", "lib/bibtex/parser.output", "lib/bibtex/parser.rb", "lib/bibtex/string_replacement.rb", "lib/extensions/core.rb", "test/bib/00_empty.bib", "test/bib/01_no_bibtex.bib", "test/bib/02_string.bib", "test/bib/03_string.bib", "test/bib/04_string_replacement.bib", "test/bib/05_comment.bib", "test/bib/06_preamble.bib", "test/bib/07_entry.bib", "test/bib/08_decoret.bib", "test/bib/09_errors.bib", "test/bib/10_bibdesk.bib", "test/test_bibtex.rb", "test/test_comment.rb", "test/test_entry.rb", "test/test_export.rb", "test/test_preamble.rb", "test/test_string.rb"]
  s.homepage = %q{http://github.com/inukshuk/bibtex-ruby}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "BibTeX-Ruby Documentation", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{bibtex-ruby}
  s.rubygems_version = %q{1.3.7}
  s.signing_key = %q{/Users/sylvester/.gem/keys/gem-private_key.pem}
  s.summary = %q{A BibTeX parser written in Ruby}
  s.test_files = ["test/test_bibtex.rb", "test/test_comment.rb", "test/test_entry.rb", "test/test_export.rb", "test/test_preamble.rb", "test/test_string.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<racc>, [">= 1.4.6"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
    else
      s.add_dependency(%q<racc>, [">= 1.4.6"])
      s.add_dependency(%q<minitest>, [">= 0"])
    end
  else
    s.add_dependency(%q<racc>, [">= 1.4.6"])
    s.add_dependency(%q<minitest>, [">= 0"])
  end
end

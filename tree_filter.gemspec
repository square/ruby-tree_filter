# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.authors       = ["Xavier Shay"]
  gem.email         = ["xavier@squareup.com"]
  gem.description   =
    %q{Filter arbitrary data trees with a concise query language.}
  gem.summary       = %q{
    Filter arbitrary data trees (hashes, arrays, values) with a concise query
    language. Handles cyclic structures.
  }
  gem.homepage      = "http://github.com/square/ruby-tree_filter"

  gem.executables   = []
  gem.required_ruby_version = '>= 1.9.0'
  gem.files         = Dir.glob("{spec,lib}/**/*.rb") + %w(
                        README.md
                        HISTORY.md
                        LICENSE
                        tree_filter.gemspec
                      )
  gem.test_files    = Dir.glob("spec/**/*.rb")
  gem.name          = "tree_filter"
  gem.require_paths = ["lib"]
  gem.license       = "Apache 2.0"
  gem.version       = '1.0.1'
  gem.has_rdoc      = false
end

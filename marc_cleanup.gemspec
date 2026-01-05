lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name           = 'marc_cleanup'
  spec.version        = File.read(File.expand_path('../VERSION', __FILE__)).strip
  spec.authors        = ['Mark Zelesky']
  spec.email          = 'mzelesky@princeton.edu'
  spec.summary        = 'MARC record cleanup'
  spec.description    = 'A collection of methods to clean MARC records and identify errors'
  spec.homepage       = 'https://github.com/pulibrary/marc_cleanup'
  spec.license        = 'BSD-2-Clause'

  spec.files          = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.require_paths  = ['lib']

  spec.add_dependency 'marc', '~> 1.0'
  spec.add_dependency 'nokogiri'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rubocop'
end

source 'https://rubygems.org'

ruby '2.1.10'

gem 'sinatra',            '~> 1.3.3'
gem 'redis',              '~> 3.0.2'
gem 'redis-namespace',    '~> 1.2.1'
gem 'dragonfly',          '~> 0.9.12'
gem 'rack-cache',         '~> 1.2'
gem 'rake',               '~> 10.0.3'
gem 'hpricot',            '~> 0.8.6'
# Required by autoheathen
gem 'mail'
gem 'haml'
gem 'ruby-filemagic'
gem 'mime-types'

group :staging, :production do
#  gem 'unicorn'
end

group :development do
  gem 'infrad',  git: 'git@code.ifad.org:infrad.git'
  gem 'capistrano',         '~> 2.15.5'
  gem 'capistrano-ext',     '~> 1.2.1'
  gem 'airbrake',           '~> 3.1.6'
  gem 'pry'
  gem 'shotgun'
  gem 'rspec'
end

platform :ruby do
  gem RUBY_VERSION.to_f >= 2.0 ? 'byebug' : 'debugger'
  gem 'yajl-ruby', '~> 1.1.0'
  gem 'rmagick'
  gem 'unicorn'
  gem 'iconv'
  gem 'pdfbeads', git: 'git@github.com:ifad/pdfbeads', ref: '7f81be26eced36b12fa2cd6795c57ab4c9230eae'
end

#platform :jruby do
#  gem 'ruby-debug-base', git: 'git@github.com:ifad/jruby-debug'
#  gem 'ruby-debug'
#  gem 'rmagick4j'
#  gem 'json'
#  gem 'puma'
#end

source 'https://rubygems.org'

gem 'sinatra',            '~> 1.3.3'
gem 'redis',              '~> 3.0.2'
gem 'redis-namespace',    '~> 1.2.1'
gem 'dragonfly',          '~> 0.9.12'
gem 'rack-cache',         '~> 1.2'
gem 'pdfkit',             '~> 0.5.2'
gem 'wkhtmltopdf-binary', '~> 0.9.9.1'
gem 'rake',               '~> 10.0.3'
gem 'nokogiri'

gem 'pdfbeads', github: 'ifad/pdfbeads'

group :development do
  gem 'capistrano',         '~> 2.13.5'
  gem 'capistrano-ext',     '~> 1.2.1'
  gem 'airbrake',           '~> 3.1.6'
  gem 'pry'
end

platform :ruby do
  gem RUBY_VERSION.to_f >= 2.0 ? 'byebug' : 'debugger'
  gem 'yajl-ruby', '~> 1.1.0'
  gem 'rmagick'
  gem 'unicorn'
  gem 'iconv'
end

platform :jruby do
  gem 'ruby-debug-base', github: 'ifad/jruby-debug'
  gem 'ruby-debug'
  gem 'rmagick4j'
  gem 'json'
  gem 'puma'
end

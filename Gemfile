source 'http://rubygems.org'

gem 'sinatra',            '~> 1.3.3'
gem 'redis',              '~> 3.0.2'
gem 'redis-namespace',    '~> 1.2.1'
gem 'dragonfly',          '~> 0.9.12'
gem 'yajl-ruby',          '~> 1.1.0'
gem 'rack-cache',         '~> 1.2'
gem 'pdfkit',             '~> 0.5.2'
gem 'pdfbeads',           '~> 1.0.9'
gem 'wkhtmltopdf-binary', '~> 0.9.9.1'
gem 'rake',               '~> 10.0.3'
gem 'hpricot',            '~> 0.8.6'
gem 'rmagick',            '~> 2.13.2'
gem 'iconv'

group :staging, :production do
  gem 'unicorn'
end

group :development do
  gem 'capistrano',         '~> 2.13.5'
  gem 'capistrano-ext',     '~> 1.2.1'
  gem 'airbrake',           '~> 3.1.6'
end

platform :ruby do
  gem RUBY_VERSION.to_f >= 2.0 ? 'byebug' : 'debugger'
end

source 'http://rubygems.org'

gem 'sinatra',            '~> 1.3.3'
gem 'redis',              '~> 3.0.2'
gem 'redis-namespace',    '~> 1.2.1'
gem 'dragonfly',          '~> 0.9.12'
gem 'yajl-ruby',          '~> 1.1.0'
gem 'rack-cache',         '~> 1.2'
gem 'pdfkit',             '~> 0.5.2'
gem 'wkhtmltopdf-binary', '~> 0.9.9.1'

group :staging, :production do
  gem 'unicorn'
end

group :development do
  gem 'debugger'
  gem 'capistrano',         '~> 2.13.5'
  gem 'capistrano-ext',     '~> 1.2.1'
  gem 'airbrake',           '~> 3.1.6'
end

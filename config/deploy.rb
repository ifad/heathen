# =========================================================================
# Global Settings
# =========================================================================

# Base settings
set :application, 'heathen'

require 'infrad'

Infrad.deploy(self, app: application)

set(:rack_env) { stage }

set :branch,   fetch(:branch, "master")

# =========================================================================
# Dependencies
# =========================================================================
depend :remote, :command, "gem"
depend :remote, :command, "git"

# =========================================================================
# Extensions
# =========================================================================
def compile(template)
  location = fetch(:template_dir, File.expand_path('../deploy', __FILE__)) + "/#{template}"
  config   = ERB.new File.read(location)
  config.result(binding)
end

namespace :deploy do
  desc 'Restarts the application.'
  task :restart, :roles => :app do
    pid = "#{deploy_to}/.unicorn.pid"
    run "test -f #{pid} && kill -USR2 `cat #{pid}` || true"
  end

  namespace :ifad do
    # Harden permisssions up
    on :after, :only => %w( deploy:setup deploy:create_symlink ),
      :except => { :no_release => true } do
      run '/home/rails/bin/setup_permissions'
    end

    desc '[internal] Symlink ruby version'
    task :symlink_ruby_version, :except => { :no_release => true } do
      run "ln -s #{deploy_to}/.ruby-version #{release_path}"
    end
    after 'deploy:update_code', 'deploy:ifad:symlink_ruby_version'
  end

  namespace :secret do
    desc '[internal] Creates the secret.rb configuration file in shared path.'
    task :setup do
      run "mkdir -p #{shared_path}/config"
      put compile('secret.rb.erb'), "#{shared_path}/config/secret.rb"
    end
    after "deploy:setup", "deploy:secret:setup"

    desc '[internal] Updates the symlink for secret.rb file to the just deployed release.'
    task :symlink do
      run "ln -nfs #{shared_path}/config/secret.rb #{release_path}/config/secret.rb"
    end
    after "deploy:update_code", "deploy:secret:symlink"
  end
end

namespace :heathen do
  namespace :cache do
    desc 'Clears the cache, causing access to existing conversion urls to reprocess content'
    task :clear, roles: :app do
      run "cd #{release_path}; #{rake} heathen:cache:clear RACK_ENV=#{rack_env}"
    end
  end

  namespace :redis do
    desc "Clear the redis database keys"
    task :clear, roles: :app do
      run "cd #{release_path}; #{rake} heathen:redis:clear RACK_ENV=#{rack_env}"
    end
  end

  desc 'Clear the redis database keys and the cache'
  task :clear, roles: :app do
    run "cd #{release_path}; #{rake} heathen:clear RACK_ENV=#{rack_env}"
  end
end

after 'deploy', 'deploy:cleanup'

require 'bundler/capistrano'
set :bundle_flags, "--deployment --quiet --binstubs #{deploy_to}/bin"

#require 'airbrake/capistrano'


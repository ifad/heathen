# Number of worker processes to start. The application will serve at most
# concurrent requests as the number of worker processes
#
worker_processes 6

# Maximum amount of time the application can spend in servicing a request,
# before being killed by the Unicorn master process.
#
timeout 3600

# Load rails app into the master before forking workers, for super-fast
# worker spawn times. Setting this to true depends on the app architecture.
#
preload_app true

# Listen on an UNIX socket located in the @$HOME@ directory of the application user
#
listen "#{ENV['HOME']}/.unicorn.sock" 

# Store the PID file in the home directory, alongside the above Socket file
#
pid "#{ENV['HOME']}/.unicorn.pid" 

# Set the working directory to the current deployed release, and set an environment
# variable required by Bundler, the library dependencies installer and loader 
# 
working_directory "#{ENV['HOME']}/current" 
ENV['BUNDLE_GEMFILE'] = "#{ENV['PWD']}/Gemfile" 

# Log stdout and stderr in separate files. These paths are relative to the
# working_directory.
#
stdout_path 'log/unicorn.stdout.log'
stderr_path 'log/unicorn.stderr.log'

# Set in the Unicorn environment the path to the server executable, for restarts
# to work.
Unicorn::HttpServer::START_CTX[0] = "#{ENV['HOME']}/bin/unicorn" 

# The following configuration handles the 0-downtime restart through the USR2 signal.
#
before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = "#{ENV['HOME']}/.unicorn.pid.oldbin" 
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill('QUIT', File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  ##
  # Unicorn master loads the app then forks off workers - because of the way
  # Unix forking works, we need to make sure we aren't using any of the parent's
  # sockets, e.g. db connection. If you have additional database connections in
  # your application, be sure to re-establish them here.

  # CouchDB and Memcached would go here but their connections are established
  # on demand, so the master never opens a socket.

  Heathen::App.redis.client.connect
end

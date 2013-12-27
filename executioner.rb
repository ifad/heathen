module Heathen

  class Executioner
    attr_reader :logger, :last_exit_status, :last_messages, :last_command,
      :stdout, :stderr

    def initialize(log)
      @logger = log
    end

    def execute(*argv)
      options = argv.last.class == Hash ? argv.pop : {}

      started = Time.now.to_f

      command = argv.map(&:to_s)

      pid, status, @stdout, @stderr = _execute(*command, options)

      elapsed = Time.now.to_f - started

      if status != 0
        logger.error "[#{pid}] exited with status #{status.inspect}"
      end
      logger.info("[#{pid}] completed in %02.4f" % elapsed)

      logger.info "  stdout: '#@stdout'\n" unless @stdout.blank? unless options[:binary]
      logger.info "  stderr: '#@stderr'\n" unless @stderr.blank?

      @last_exit_status = status
      @last_messages = {stdout: @stdout, stderr: @stderr}
      @last_command = command.join(' ')

      return status
    end

    if RUBY_PLATFORM == 'java'
      # Executes the given argument vector with ProcessBuilder.
      # Returns the pid and exit status as Numeric, stdout and
      # stderr as Strings.
      #
      def _execute(*argv, options)

        builder = java.lang.ProcessBuilder.new
        builder.command(argv)

        if options[:dir]
          dir = java.io.File.new(options[:dir])
          builder.directory(dir)
        end

        process = builder.start()

        # Dirty hack, works on UNIX only.
        pid = if process.is_a?(Java::JavaLang::UNIXProcess)
          prop = process.get_class.get_declared_field('pid')
          prop.set_accessible true
          prop.get_int(process)
        end

        logger.info "[#{pid}] spawn '#{argv.join(' ')}'"

        process.wait_for

        out = process.get_input_stream.to_io.read
        err = process.get_error_stream.to_io.read

        [pid, process.exit_value, out, err]
      end

    else
      require 'open3'

      # Executes the given argument vector with Open3.popen3.
      # Returns the pid and exit status as Numeric, stdout and
      # stderr as Strings.
      #
      def _execute(*argv, options)
        command = argv.shift

        Open3.popen3(ENV, [ command, "heathen: #{command}" ], *argv,
          :chdir => options[:dir] || Dir.getwd
        ) do |stdin, stdout, stderr, wait_thr|
          pid = wait_thr[:pid]
          logger.info "[#{pid}] spawn '#{command} #{argv.join(' ')}'"

          stdin.close

          if options[:binary]
            stdout.binmode
            stderr.binmode
          end

          out = Thread.new { stdout.read }.value
          err = Thread.new { stderr.read }.value

          [pid, wait_thr.value, out, err]
        end
      end
    end

    def quartering(heretics)
      @heretics = heretics
      parallel  = (@heretics.size > 4 ? 4 : @heretics.size)

      parallel.times.collect do
        guilty = @heretics.shift
        Thread.fork { slaughter guilty }
      end.map(&:join)
    end

    protected
      def slaughter guilty
        execute(*guilty)
        slaughter(@heretics.shift) unless @heretics.size.zero?
      end
  end
end

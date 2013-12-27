module Heathen
  module Encoders
    module Concerns::Libreoffice

      # returns a Tempfile instance.
      # calling method is responsible for closing/unlinking
      def libreoffice(source, extension = :pdf)
        file = Tempfile.new('heathen')
        file.chmod 0666

        temp_name = [ file.path, extension.to_s ].join('.')

        FileUtils.ln(file.path, temp_name)

        executioner.execute('python', "#{app.root}/bin/DocumentConverter.py",
                            app.ooo_host, app.ooo_port, source, temp_name)

        FileUtils.rm(temp_name)

        file.close

        if executioner.last_exit_status == 0
          return file
        else
          file.unlink
          return nil
        end

      rescue
        file.unlink
        raise
      end
    end
  end
end

module Heathen
  module Encoders
    module Concerns::Libreoffice

      # returns a Tempfile instance.
      # calling method is responsible for closing/unlinking
      def libreoffice(source_file, extension = :pdf)
        executioner.execute(
          'soffice',
          '--headless',
          '--convert-to', extension.to_s,
          '--outdir', File.dirname(source_file),
          source_file )

        if executioner.last_exit_status == 0
          file = File.new( source_file.gsub(/\.[^.]*$/, ".#{extension.to_s}" ) )
          return file
        else
          return nil
        end

      end
    end
  end
end

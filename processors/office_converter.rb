module Heathen
  module Processors
    class OfficeConverter

      MIME_TYPES = [
        'application/zip', # For DOCX files.
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation'
      ]

      attr_reader :app

      class << self
        def valid_mime_type?(mime_type)
          return MIME_TYPES.include?(mime_type)
        end
      end

      def initialize(app)
        @app = app
      end

      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def office_to_pdf(temp_object)
        if content = to_pdf(temp_object.path)
          [
            content,
            {
              name:      [ temp_object.basename, 'pdf' ].join('.'),
              mime_type: "application/pdf"
            }
          ]
        else
          raise Heathen::NotConverted.new({
            temp_object:    temp_object,
            action:         'office_to_pdf',
            original_error: nil
          })
        end
      end

      private

        # returns a Tempfile instance.
        # calling method is responsible for closing/unlinking
        def to_pdf(source)

          executioner = Heathen::Executioner.new(app.converter.log)

          file = Tempfile.new('/tmp/heathen')
          file.chmod 0666

          temp_name = [ file.path, 'pdf' ].join('.')

          FileUtils.ln(file.path, temp_name)

          if app.development?
            executioner.execute("ruby", "#{app.root}/bin/libreoffice-stub.rb", source, temp_name)
          else
            executioner.execute('python', "#{app.root}/bin/DocumentConverter.py", source, temp_name)
          end

          FileUtils.rm(temp_name)

          file.close

          if executioner.last_exit_status == 0
            return file
          else
            file.unlink
            return nil
          end
        end
    end
  end
end

module Heathen
  module Encoders
    class Office < Base

      MIME_TYPES = [
        'application/zip', # For DOCX files.
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation'
      ]

      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def encode(temp_object, format, args = { })

        unless format == :pdf && self.class.valid_mime_type?(temp_object.meta[:mime_type])
          throw :unable_to_handle
        end

        if content = to_pdf(temp_object.path)
          [ content, meta(temp_object, :pdf, 'application/pdf') ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'office_to_pdf',
            original_error: nil
          })
        end
      end

      private

        # returns a Tempfile instance.
        # calling method is responsible for closing/unlinking
        def to_pdf(source)

          file = Tempfile.new("#{app.storage_root}/tmp/heathen")
          file.chmod 0666

          temp_name = [ file.path, 'pdf' ].join('.')

          FileUtils.ln(file.path, temp_name)

          if app.development?
            executioner.execute("ruby", "#{app.root}/bin/libreoffice-stub.rb",
                                app.ooo_host, app.ooo_port, source, temp_name)
          else
            executioner.execute('python', "#{app.root}/bin/DocumentConverter.py",
                                app.ooo_host, app.ooo_port, source, temp_name)
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

module Heathen
  module Processors
    class OfficeConverter < ::Heathen::Processors::Base

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
      def office_to_pdf(temp_object, args = { } )
        if content = to_pdf(temp_object.path)
          [ content, mime(temp_object, :pdf, 'application/pdf') ]
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

          executioner = Heathen::Executioner.new(app.converter.log)

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

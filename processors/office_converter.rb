module Heathen
  module Processors
    class OfficeConverter

      def initialize(app)
        @app = app
      end

      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def office_to_pdf(temp_object)
         [
           to_pdf(temp_object.tempfile.path),
           {
             name: [ temp_object.basename, 'pdf' ].join('.'),
             mime_type: "application/pdf"
           }
         ]
      end

      private

        # returns a Tempfile instance.
        # calling method is responsible for closing/unlinking
        def to_pdf(source, *args)

          executioner = Heathen::Executioner.new(@app.converter.log)

          Tempfile.new('/tmp/heathen').tap do |file|
            file.chmod 0666

            temp_name = [ file.path, 'pdf' ].join('.')

            FileUtils.ln(file.path, temp_name)

            if @app.development?
              executioner.execute("ruby", "#{@app.root}/bin/stub.rb", source, temp_name)
            else
              executioner.execute('python', "#{@app.root}/bin/DocumentConverter.py", source, temp_name)
            end

            FileUtils.rm(temp_name)

            file.close
          end
        end
    end
  end
end

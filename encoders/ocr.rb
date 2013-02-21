module Heathen
  module Encoders
    class Ocr < Base

      include Heathen::Utils
      extend Heathen::Utils

      MIME_TYPES = [ 'image/tiff' ]

      class << self
        def encodes?(job)
          super && present?(job.meta[:pages])
        end
      end

      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def encode(temp_object, format, args = { })

        pages = temp_object.meta[:pages]

        unless format == :pdf && self.class.valid_mime_type?(temp_object.meta[:mime_type]) && present?(pages)
          throw :unable_to_handle
        end

        if content = to_pdf(temp_object, pages: pages)
          cleanup(pages)
          temp_object.meta.delete(:pages)
          [ content, meta(temp_object, :pdf, "application/pdf") ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'tiff_to_pdf',
            original_error: nil
          })
        end
      end

      private

        def to_pdf(source, args = { })
          pages       = args[:pages].map { |page| page.basename.to_s }
          dir         = args[:pages].first.dirname.to_s
          result_file = source.path.gsub(/tiff?$/, "pdf")

          begin
            executioner.execute('ruby', "#{app.root}/bin/patched_pdfbeads.rb", "--bg-compression", 'JPG', "-o", result_file, *pages, dir: dir)

            file = File.open(result_file, "r")
            file.close

            if executioner.last_exit_status == 0
              return file
            else
              file.unlink
              return nil
            end
          rescue
            return nil
          end
        end

        def cleanup(pages)
          pages.each do |page|
            html = Pathname(page.to_s.gsub(/tiff?$/, "html"))
            page.unlink
            html.unlink
          end
        end
    end
  end
end

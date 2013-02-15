module Heathen
  module Processors
    class TiffConverter < Base

      MIME_TYPES = [ 'image/tiff' ]

       def tiff_to_html( temp_object, args = { } )
        if content = to_html(temp_object.path, args)
          [ temp_object, meta(temp_object, :tiff, "image/tiff", hocr: temp_object.path.to_s.gsub(/tif$/, "html")) ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'tiff_to_html',
            original_error: nil
          })
        end
      end

      #
      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def tiff_to_pdf( temp_object)
        if content = to_pdf(temp_object, temp_object.meta[:hocr])
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
        def to_pdf(source, meta )
          begin
            result_file = File.basename(source.path).gsub(/tif$/, "pdf")
            executioner = Heathen::Executioner.new(app.converter.log)

            executioner.execute('pdfbeads', "--bg-compression", 'JPG', "-o", result_file, File.basename(source.path), dir: File.dirname(source.path))

            file = File.open(File.dirname(source.path) + "/" + result_file, "r")
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

        def to_html(source, args = { } )

		  params = []
		  params << "-l #{args[:language]}" if args[:language]
		  params << "hocr"

          tesseract(source, "html", params, true)

        end


        def tesseract(source, format, params = [ ], include_source=false)

          executioner = Heathen::Executioner.new(app.converter.log)

          args = [source, source.gsub(/\.tif$/, "")] + params + [app.root + "/config/tesseract_hocr_config.txt"]
          begin
            executioner.execute('tesseract', *args)

            if executioner.last_exit_status == 0
              return true
            else
              return nil
            end
          rescue
            return nil
          end

        end
    end
  end
end

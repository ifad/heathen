module Heathen
  module Processors
    class TiffConverter < Base

      MIME_TYPES = [ 'image/tiff' ]

      def tiff_split( temp_object )
        if content = split(temp_object.path)
          [ temp_object, meta(temp_object, :tiff, "image/tiff", pages: content) ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'tiff_to_html',
            original_error: nil
          })
        end
      end

      def tiff_to_html( temp_object, args = { } )
        hocrs = temp_object.meta[:pages].collect do |page|
          if content = to_html(page, args)
            page.gsub(/tif$/, "html")
          else
            raise Heathen::NotConverted.new({
                 temp_object: temp_object,
                      action: 'tiff_to_html',
              original_error: nil
            })
          end
        end

        [ temp_object, meta(temp_object, :tiff, "image/tiff", pages: temp_object.meta[:pages], hocrs: hocrs) ]
      end

      #
      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def tiff_to_pdf( temp_object )
        if content = to_pdf(temp_object)
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
        def split(source)
          begin
            base_tmp = "#{app.storage_root}/tmp/#{File.basename(source).gsub(/\.tif$/i, "_")}"

            executioner = Heathen::Executioner.new(app.converter.log)
            executioner.execute('convert', '-quiet', '-scene', '0', source, base_tmp + "%d.tif")

            if executioner.last_exit_status == 0
              return Dir[base_tmp + "*.tif"]
            else
              return nil
            end
          rescue
            return nil
          end
        end

        def to_pdf( source )
          pages       = source.meta[:pages].map{|page| File.basename(page)}
          dir         = File.dirname(source.meta[:pages].first)
          result_file = source.path.gsub(/tif$/, "pdf")

          begin
            executioner = Heathen::Executioner.new(app.converter.log)

            executioner.execute('ruby', "#{app.root}/bin/patched_pdfbeads.rb", "--bg-compression", 'JPG', "-o", result_file, *pages, dir: dir)

            file = File.open(result_file, "r")
            file.close
            debugger

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

        def to_html( source, args = { } )

		  params = []
		  params << "-l #{args[:language]}" if args[:language]
		  params << "hocr"

          tesseract(source, "html", params, true)

        end


        def tesseract(source, format, params = [ ], include_source=false)

          executioner = Heathen::Executioner.new(app.converter.log)

          args = [source, source.gsub(/\.tif$/, "")] + params + [app.root + "/config/tesseract_hocr.conf"]
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

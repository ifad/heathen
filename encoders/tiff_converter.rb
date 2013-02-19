module Heathen
  module Encoders
    class TiffConverter < Base

      MIME_TYPES = [ 'image/tiff' ]

      class << self

        # tiff converter doesn't actually encode anything directly,
        # but it's used internally for ocr
        def encodes?(job)
          false
        end
      end

      def tiff_split(temp_object)
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

      def tiff_to_html(temp_object, args = { })
        pages = temp_object.meta[:pages].collect { |page| to_html(page, args) }
        hocrs = temp_object.meta[:pages].collect { |page| page.gsub(/tif$/, "html") }

        executioner = Heathen::Executioner.new(app.converter.log)
        executioner.quartering(pages)

        [ temp_object, meta(temp_object, :tiff, "image/tiff", pages: temp_object.meta[:pages], hocrs: hocrs) ]
      end

      #
      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def tiff_to_pdf(temp_object)
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
            executioner.execute('convert', '-quiet', '-scene', '0', source, base_tmp + "%05d.tif")

            if executioner.last_exit_status == 0
              return Dir[base_tmp + "*.tif"]
            else
              return nil
            end
          rescue
            return nil
          end
        end

        def to_html(source, args = { })

          params = []
          params << "-l #{args[:language]}" if args[:language]
          params << "hocr"

          [ "tesseract", source, source.gsub(/\.tif$/, "")] + params + [app.root + "/config/tesseract_hocr.conf" ]

        end

        def to_pdf(source)
          pages       = source.meta[:pages].map { |page| File.basename(page) }
          dir         = File.dirname(source.meta[:pages].first)
          result_file = source.path.gsub(/tif$/, "pdf")

          begin
            executioner = Heathen::Executioner.new(app.converter.log)

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
    end
  end
end

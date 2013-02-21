module Heathen
  module Processors
    class Ocr < Base

      def ocr(temp_object, args = { })

        unless temp_object.meta[:format] == :tiff
          throw :unable_to_handle
        end

        pages = ocr_pages(temp_object).map { |str| Pathname(str) }

        commands = pages.map do |page|
          to_html(page, language: temp_object.meta[:language])
        end

        executioner.quartering(commands)

        [ temp_object, temp_object.meta.merge(pages: pages) ]
      end

      private

        def ocr_pages(temp_object, args = { })
          split(Pathname(temp_object.path)).tap do |pages|
            throw :unable_to_handle unless pages
          end
        end

        def split(source)
          begin
            base = app.temp_storage_root + source.basename.to_s.gsub(/\.tiff?$/i, "_")

            executioner.execute('convert', '-quiet', '-scene', '0', source.to_s, base.to_s + "%05d.tif")

            if executioner.last_exit_status == 0
              return Dir[base.to_s + "*.tif"]
            else
              return nil
            end
          rescue
            return nil
          end
        end

        def to_html(source, args = { })
          params = [ ]
          params << "-l #{args[:language]}" if args[:language]
          params << "hocr"
          params << app.root + "/config/tesseract_hocr.conf"

          [ "tesseract", source, source.to_s.gsub(/\.tiff?$/, "") ] + params
        end
    end
  end
end

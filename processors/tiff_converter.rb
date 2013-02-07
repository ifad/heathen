require 'nokogiri'

module Heathen
  module Processors
    class TiffConverter < Base

      MIME_TYPES = [ 'image/tiff' ]

      # return a [ content, meta ] pair, as expcted
      # by dragonfly
      def tiff_to_txt( temp_object, args = { } )
        if content = to_txt(temp_object.path, args)
          [ content, meta(temp_object, :txt, "text/plain") ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'tiff_to_txt',
            original_error: nil
          })
        end
      end

      def tiff_to_html( temp_object, args = { } )
        if content = to_html(temp_object.path, args)
          [ content, meta(temp_object, :html, "text/html") ]
        else
          raise Heathen::NotConverted.new({
               temp_object: temp_object,
                    action: 'tiff_to_html',
            original_error: nil
          })
        end
      end

      private

        def to_txt(source, args = { } )

		  params = args[:language] ? ["-l #{args[:language]}"] : []

          tesseract(source, "txt", params)

        end

        def to_html(source, args = { } )

		  params = []
		  params << "-l #{args[:language]}" if args[:language]
		  params << "hocr"

          file = tesseract(source, "html", params, true)

        end

        def tesseract(source, format, params = [ ], include_source=false)

          executioner = Heathen::Executioner.new(app.converter.log)

          temp_name = app.storage_root + "tmp" + source.split("/").last

          args = [source, temp_name] + params
          begin
            executioner.execute('tesseract', *args)

            result_file = temp_name.to_s + ".#{format}"

            attach(result_file, source) if include_source

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

        def attach(file, source)
          doc = Nokogiri::HTML(IO.read(file))

          css = Nokogiri::XML::Node.new "style", doc
          css["type"] = "text/css"
          css.content = %{
            .img {background-image: url(data:image/tiff;base64,#{Base64.strict_encode64 IO.read(source)});}
          }

          doc.at_css('head').add_child css

          img = Nokogiri::XML::Node.new "div", doc
          img["class"] = "img"

          doc.at_css('body').add_child img

          f = File.open(file, "w")
          f.puts doc.to_html
          f.close
        end
    end
  end
end

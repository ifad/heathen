module Heathen
  module Encoders

    module Concerns::Wkhtmltopdf

      def wkhtmltopdf(source)
        executioner.execute(Heathen::App.wkhtmltopdf,
          *_wkhtmltopdf_options(source),
          source,
          '-', # print results on stdout
          :binary => true)

        if executioner.last_exit_status == 0 && executioner.stdout.size > 0
          executioner.stdout
        end
      end

      protected
        def _wkhtmltopdf_options(source)
          html = Nokogiri.parse(File.read(source))
          defl = [
            '--page-size',     'Letter',
            '--margin-top',    '0.75in',
            '--margin-right',  '0.75in',
            '--margin-bottom', '0.75in',
            '--margin-left',   '0.75in',
            '--encoding',      'UTF-8'
          ]

          attrs = html.xpath("//meta[starts-with(@name, 'heathen')]").inject({}) do |h, meta|
            name = meta.attributes['name'].value.sub(/^heathen/, '-')

            h.merge(name => meta.attributes['content'].value)
          end

          attrs.inject(defl){ |d, (k,v)| d << [k, v] }.flatten
        end

    end

  end
end

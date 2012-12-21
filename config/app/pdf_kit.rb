require 'pdfkit'

module Heathen
  module Config
    module App
      class PDFKit
        def self.configure(app)
          path = `which wkhtmltopdf`

          unless path
            raise "wkhtmltopdf not found"
          end

          ::PDFKit.configuration.wkhtmltopdf = path
        end
      end
    end
  end
end

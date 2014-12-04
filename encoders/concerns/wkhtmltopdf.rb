module Heathen
  module Encoders

    module Concerns::Wkhtmltopdf

      def wkhtmltopdf(source)
        executioner.execute(Heathen::App.wkhtmltopdf,
          '--page-size', 'Letter',
          '--margin-top',    '0.75in',
          '--margin-right',  '0.75in',
          '--margin-bottom', '0.75in',
          '--margin-left',   '0.75in',
          '--encoding',      'UTF-8',
          source,
          '-', # print results on stdout
          :binary => true)

        if executioner.last_exit_status == 0 && executioner.stdout.size > 0
          executioner.stdout
        end
      end

    end

  end
end

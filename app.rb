$: << File.expand_path(".")

require 'sinatra/base'
require 'yajl'
require 'config'
require 'executioner'
require 'inquisitor'

module Heathen

  PROCESSORS = %w{
    office_to_pdf
  }

  class App < Sinatra::Base

    Config.configure(self)

    get '/' do
      %{
        <h4>Convert the Heathens!</h4>
        <form action="#{url('/convert')}" method="POST" enctype="multipart/form-data">
          <div>
            <label>File:</label>
            <input type="file" name="file"/>
          </div>
          <div>
            <label>Action:</label>
            <select name="action">
              <option value="office_to_pdf">Office to PDF</option>
            </select>
          </div>
          <hr />
          <input type="submit" value="Convert" />
        </form>
      }
    end

    post '/convert' do

      return 400 unless PROCESSORS.include?(params[:action])

      url_base = url('/')
      job      = Inquisitor.new(converter).find(params[:file])

      if url_base.end_with?('/')
        url_base.chop!
      end

      Yajl::Encoder.encode({
        original:  job.url(host: url_base),
        converted: job.process(params[:action]).url(host: url_base)
      })
    end

    get '/*' do
      converter.call(env)
    end
  end
end

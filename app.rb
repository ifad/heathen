$: << File.expand_path(".")

require 'sinatra/base'
require 'yajl'
require 'heathen'
require 'config'
require 'executioner'
require 'inquisitor'

module Heathen

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

      unless Heathen::PROCESSORS.include?(params[:action])
        return 400
      end

      inquisitor = Inquisitor.new(converter, params[:action])
      url_base  = url('/')
      job       = inquisitor.find(params[:file])

      unless job
        return 400
      end

      if url_base.end_with?('/')
        url_base.chop!
      end

      status  200
      headers "Content-type" => "application/json"

      Yajl::Encoder.encode({
        original:  job.url(host: url_base),
        converted: job.process(params[:action]).url(host: url_base)
      })
    end

    get '/*' do
      begin
        converter.call(env)
      rescue Heathen::NotConverted => e
        status 500
        headers "Content-type" => "application/json"
        body   Yajl::Encoder.encode({
          error: "Unable to convert",
          action: e.action,
          name:   e.temp_object.name
        })
      end
    end
  end
end

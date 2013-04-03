$: << File.expand_path(".")

require 'sinatra/base'
require 'yajl'
require 'heathen'
require 'config'
require 'executioner'
require 'inquisitor'
require 'utils'

module Heathen

  class App < Sinatra::Base

    Config.configure(self)

    helpers do
      include Heathen::Utils
      def json_response(data, code = 200, options = { })
        data.merge!(params) if data.has_key?(:error)
        status  code
        headers "Content-type" => "application/json"
        body    Yajl::Encoder.encode(data.merge(options))
      end
    end

    get '/' do
      erb :index
    end

    post '/convert' do

      action = params[:action]

      unless present?(params[:url]) || present?(params[:file])
        if request.accept.include?("application/json")
          return json_response({
            error: "Invalid parameters: 'file' or 'url' required",
            action: action
          }, 400)
        else
          redirect(url('/'))
        end
      end

      unless ACTIONS.include?(action)
        return json_response({
          error: "Unsupported action",
          supported_actions: Heathen::ACTIONS,
          action: action
        }, 400)
      end

      inquisitor = Inquisitor.new(converter, params)
      url_base   = url('/').gsub(/\/$/, '')

      job, convertable = inquisitor.job

      response = { original:  job.url(host: url_base) }

      if convertable
        response.merge!({
          converted: (job.respond_to?(action) ? job.send(action) : job.encode(:pdf)).url(host: url_base)
        })
      end

      json_response(response)

    end

    get '/*' do
      begin
        converter.call(env)
      rescue Heathen::NotConverted => e
        json_response({
             error: "Unable to convert",
            action: e.action,
              name: e.temp_object.name
        }, 500)
      end
    end
  end
end

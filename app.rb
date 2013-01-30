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

    helpers do
      def json_response(data, code = 200)
		data.merge!(params) if data.has_key?(:error)

        status  code
        headers "Content-type" => "application/json"
        body    Yajl::Encoder.encode(data)
      end

	  def build_job job, action
		args = extract_args(action)

        (job.respond_to?(action) ? job.send(action, args) : job.process(action, args))
	  end

	  def extract_args action
		args = {}

		case action
		when "ocr", "tiff_to_txt", "tiff_to_html"
		  args[:language] = params[:language] if params[:language]
		end

		args
	  end
    end

    get '/' do
      erb :index
    end

    post '/convert' do

      action   = params[:action]

      unless Heathen::PROCESSORS.include?(action)
        return json_response({
             error: "Unsupported action",
            action: action
        }, 400)
      end

      inquisitor = Inquisitor.new(converter, params)
      url_base   = url('/')
      job        = inquisitor.job

      unless job
        return json_response({
             error: 'Action not supported for file',
            action: action
        }, 400)
      end

      if url_base.end_with?('/')
        url_base.chop!
      end

      json_response({
        original:  job.url(host: url_base),
        converted: build_job(job, action).url(host: url_base)
      })
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

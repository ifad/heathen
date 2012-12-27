require 'digest/sha2'

module Heathen
  # checks if the uploaded file has already been processed,
  # and returns an identical dragonfly job, or a new job
  class Inquisitor

    attr_reader :redis, :converter, :params

    def initialize(converter, params)
      @redis     = Heathen::App.redis
      @converter = converter
      @params    = params
    end

    def can_convert?(job)
      case params[:action]
        when 'office_to_pdf'
          Processors::OfficeConverter.valid_mime_type?(job.mime_type)

        when 'html_to_pdf', 'url_to_pdf'
          Processors::HtmlConverter.valid_mime_type?(job.mime_type)
      end
    end

    def job

      job = nil
      key = content_hash

      if serialized = redis[key]
        job = converter.job_class.deserialize(serialized, converter)
      else
        job = make_job

        unless can_convert?(job)
          return nil
        end

        job.meta.merge!(meta_data)

        uid = job.store
        job = converter.fetch(uid)

        redis[key] = job.serialize
      end

      job
    end

    private

      def content_hash
        if file = params[:file]
          Digest::SHA2.file(file.fetch(:tempfile)).hexdigest

        elsif url = params[:url]
          Digest::SHA2.hexdigest(url)
        end
      end

      def make_job
        if file = params[:file]
          converter.new_job(file.fetch(:tempfile), name: file.fetch(:filename))

        elsif url = params[:url]
          # for now, force text/html for all urls
          converter.fetch_url(url).tap { |j| j.meta[:format] = :html }
        end
      end

      def meta_data
        if file = params[:file]
          { name: file.fetch(:filename) }

        elsif url = params[:url]
          { url: url }
        end
      end
  end
end

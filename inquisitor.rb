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
      job.image? || Encoders.can_encode?(job)
    end

    def job

      job = make_job
      key = content_hash(job)

      if serialized = redis[key]
        job = converter.job_class.deserialize(serialized, converter)

      else
        job.meta.merge!(meta_data.merge(:mime_type => job.mime_type))

        uid = job.store
        job = converter.fetch(uid)

        redis[key] = job.serialize
      end

      [job, can_convert?(job)]
    end

    private

      def content_hash(job)
        Digest::SHA2.file(job.path).hexdigest
      end

      def make_job
        if file = params[:file]
          converter.log.info "\n\n\nfile: #{file.inspect}"
          converter.new_job(file.fetch(:tempfile), name: file.fetch(:filename))

        elsif url = params[:url]
          converter.fetch_url(url)
        end
      end

      def meta_data
        md            = { }
        md[:language] = params[:language]              if params[:language]
        md[:name]     = params[:file].fetch(:filename) if params[:file]
        md[:url]      = params[:url]                   if params[:url]

        md
      end
  end
end

require 'digest/sha2'

module Heathen
  # checks if the uploaded file has already been processed,
  # and returns an identical dragonfly job, or a new job
  class Inquisitor

    attr_reader :redis
    attr_reader :converter

    def initialize(converter, action)
      @redis     = Heathen::App.redis
      @converter = converter
      @action    = action
    end

    def can_convert?(job)
      case @action
        when 'office_to_pdf'
          Processors::OfficeConverter.valid_mime_type?(job.mime_type)
        when 'html_to_pdf'
          Processors::HtmlConverter.valid_mime_type?(job.mime_type)
      end
    end

    def find(file)

      job = nil
      key = content_hash(file[:tempfile])

      if serialized = redis[key]
        job = converter.job_class.deserialize(serialized, converter)
      else
        job = converter.new_job(file[:tempfile], name: file[:filename])

        unless can_convert?(job)
          return nil
        end

        uid = job.store

        job = converter.fetch(uid)
        redis[key] = job.serialize
      end

      job
    end

    private

      def content_hash(file)
        Digest::SHA2.file(file).hexdigest
      end
  end
end

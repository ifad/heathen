require 'app'
# All very funny - using filemagic to get the content type, as mime-types uses the filename
# extension to derive content type, but then using mime-types to generate the output
# file extension
require 'filemagic'
require 'filemagic/ext'
require 'mime/types'

module AutoHeathen
  class Converter
    attr_reader :logger

    def initialize opts={}
      @logger = opts[:logger] || Logger.new(nil)
    end

    # Constructs converted filename, using preferred extension for the content's content_type
    # useful if you need to name your converted content
    def converted_filename filename, content
      type = MIME::Types[content.content_type.gsub(/;.*/,'')].first
      "#{File.basename(filename,File.extname(filename))}.#{type ? type.preferred_extension : 'unknown'}"
    end

    # Returns the correct conversion action based on the content type
    # @raise RuntimeError if there is no conversion action for the content type
    def get_action content_type
      ct = content_type.gsub(/;.*/, '')
      op = {
        'application/pdf' => 'ocr',
        'text/html' => 'pdf',
        'application/zip' => 'pdf',
        'application/msword' => 'pdf',
        'application/vnd.oasis.opendocument.text' => 'pdf',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'pdf',
        'application/vnd.ms-excel' => 'pdf',
        'application/vnd.ms-office' => 'pdf',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'pdf',
        'application/vnd.ms-powerpoint' => 'pdf',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'pdf',
      }[ct]
      op = 'ocr' if ! op && ct.start_with?('image/')
      raise "Conversion from #{ct} is not supported" unless op
      op
    end

    # Converts the given file content according to the action and language
    # @return the body of the converted file
    def convert action, language, filename, input_content
      raise "Invalid action: #{action}" unless Heathen::ACTIONS.include? action
      logger.debug "  converting #{filename} (#{input_content.content_type}) using action #{action}"
      converter = Heathen::App.converter
      job = converter.new_job input_content, name: filename
      job.meta.merge!( mime_type: job.mime_type, language: language )
      raise "Unable to convert #{filename} using action #{action}" unless can_convert?(job)
      job = job.respond_to?(action.to_sym) ? job.send(action.to_sym) : job.encode(:pdf)
      job = job.apply
      data = job.data
      return converted_filename(filename,data), data
    end

    protected

    def can_convert? job
      job.mime_type == 'application/pdf' || job.image? || Heathen::Encoders.can_encode?(job)
    end

  end
end

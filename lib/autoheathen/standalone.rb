require 'mail'
require 'heathen-client'
require 'yaml'
require 'logger'
require 'haml'
require 'filemagic'
require 'filemagic/ext'

module AutoHeathen
  class Standalone
    attr_reader :cfg

    # Constructs the processor
    # @param cfg a hash of configuration settings:
    #    mode:             :summary                       Processing mode, one of :summary, :directory, :return_to_sender, :email
    #    language:         'en'                           Language the document is in
    #    verbose:          false                          If true, will log debug output
    #    heathen_base_uri: 'http://localhost:9292'        Base URI for heathen requests
    #    logger:           nil                            Optional logger object
    def initialize cfg={}
      @cfg = {   # defaults
        language:         'en',
        verbose:          false,
        heathen_base_uri: 'http://localhost:9292',
        logger:           nil,
      }
      if cfg[:config_file] && File.exist?(cfg[:config_file])
        @cfg.merge! symbolize_keys(YAML::load_file cfg[:config_file])
      end
      @cfg.merge! cfg  # non-file opts have precedence
      @logger = @cfg[:logger] || Logger.new(STDOUT)
      @logger.level = @cfg[:verbose] ? Logger::DEBUG : Logger::INFO
    end

    # Returns true if the given content type is valid for processing
    # @param content_type e.g. "image/jpeg"
    def get_operation content_type
      # We could take this from Inquisitor#can_convert?, and Encoders.can_encode?, but I'm not 
      # too keen to drag them into this script. Instead, just choose from a restricted set of
      # content types.
      ct = content_type.gsub(/;.*/, '')
      op = {
	'application/pdf' => 'ocr',
	'text/html' => 'doc',
	'application/zip' => 'doc',
	'application/msword' => 'doc',
	'application/vnd.oasis.opendocument.text' => 'doc',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'doc',
        'application/vnd.ms-excel' => 'doc',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'doc',
        'application/vnd.ms-powerpoint' => 'doc',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'doc',
      }[ct]
      op = 'ocr' if ! op && ct.start_with?('image/')
      raise "Conversion from #{ct} is not supported" unless op
      op
    end

    # Encodes the given file, yielding the converted document content in a block
    # @param filename The name of a file containing the email
    # @return nothing important
    def process_file filename, &block
      process_content File.read(filename), filename, &block
    end

    # Encodes the given IO, yielding the converted document content in a block
    # @param io An IO object, from which will be read the email
    # @return nothing important
    def process_io io, filename, &block
      process_content io.read, filename, &block
    end

    def process content, filename, &block
      # icky - decode the whole body just to read the first few bytes
      # double-icky - use FileMagic's extension to String
      content_type = content.mime_type

      op = cfg[:operation] || get_operation(content_type)
      logger.debug "Sending '#{op}' conversion request to Heathen, content-type: #{content_type}"
      opts = {
        language: @cfg[:language],
        file: AttachmentIO.new(content,filename),
        original_filename: filename,
        multipart: true,
      }
      resp = heathen_client.convert(op,opts)
      if resp.error?
        raise "Unable to convert file: #{resp.error}"
      else
        resp.get do |data|
          new_filename = converted_filename filename
          yield data,new_filename
        end
      end
      nil
    end

    def converted_filename filename
      File.basename(filename,File.extname(filename)) + '.pdf'
    end

    # Convenience constructor for heathen client
    def heathen_client
      Heathen::Client.new base_uri: @cfg[:heathen_base_uri]
    end

    # Convenience method to return logger
    def logger
      @logger
    end

    # Opens and reads a file, first given the filename, then tries from the project base directory
    def read_file filename
      f = filename
      unless File.exist? f
        f = Pathname.new(__FILE__).realpath.parent.parent.parent + f
      end
      File.read f
    end

    def symbolize_keys(hash)
      hash.inject({}){|result, (key, value)|
        new_key = key.is_a?(String) ? key.to_sym : key
        new_value = value.is_a?(Hash) ? symbolize_keys(value) : value
        result[new_key] = new_value
        result
      }
    end
  end

  # RestClient (used by Heathen client) doesn't play very well with StringIO, so this wee
  # class provides the needful
  class AttachmentIO < StringIO
    def initialize content, filename
      @filename = filename
      super(content)
    end
    def path
      @filename
    end
  end
end



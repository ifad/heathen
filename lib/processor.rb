require 'mail'
require 'heathen-client'
require 'yaml'
require 'logger'
require 'haml'

module AutoHeathen
  class Processor
    # Constructs the processor
    # @param cfg a hash of configuration settings:
    #    mode:             :summary                       Processing mode, one of :summary, :directory, :return_to_sender, :email
    #    operation:        'ocr'                          Conversion operation, one of 'ocr', 'pdf', 'doc'
    #    language:         'en'                           Language the document is in
    #    email:            nil                            Email to send response to (if mode == :email)
    #    from:             'autoheathen'                  Who to say the email is from
    #    directory:        nil                            Directory to save converted files to (if mode == :directory)
    #    verbose:          false                          If true, will log debug output
    #    heathen_scheme:   'http'                         URI scheme for heathen server requests (http or https)
    #    heathen_host:     'localhost'                    Location of the heathen server
    #    heathen_port:     9292                           Port the heathen server is listening on
    #    mail_host:        'localhost'                    Mail relay host for responses (mode in [:return_to_sender,:email]
    #    mail_port:        25                             Mail relay port (ditto)
    #    logger:           nil                            Optional logger object
    #    text_template:    'config/response.text.haml'    Template for text part of response email (mode in [:return_to_sender,:email])
    #    html_template:    'config/response.html.haml'    Template for HTML part of response email (ditto)
    def initialize cfg={}
      @cfg = {   # defaults
        mode:             :summary,
        operation:        'ocr',
        language:         'en',
        email:            nil,
        from:             'autoheathen',
        directory:        nil,
        verbose:          false,
        heathen_scheme:   'http', # or https
        heathen_host:     'localhost',
        heathen_port:     9292,
        mail_host:        'localhost',
        mail_port:        25,
        logger:           nil,
        text_template:    'config/response.text.haml',
        html_template:    'config/response.html.haml',
      }
      if cfg[:config_file] && File.exist?(cfg[:config_file])
        @cfg.merge! YAML::load_file cfg[:config_file]
      end
      @cfg.merge! cfg  # non-file opts have precedence
      @logger = @cfg[:logger] || Logger.new(STDOUT)
      @logger.level = @cfg[:verbose] ? Logger::DEBUG : Logger::INFO
    end

    # Returns true if the given content type is valid for processing
    # @param content_type e.g. "image/jpeg"
    def valid_content_type? content_type
      # TODO
      #[ 'application/docx' ].include? content_type
      true
    end

    # Processes the given email, submits attachments to the Heathen server, delivers responses as configured
    # @param file The name of a file containing the email
    # @return nothing important
    def process_file file
      process File.read(file)
    end

    # Processes the given email, submits attachments to the Heathen server, delivers responses as configured
    # @param io An IO object, from which will be read the email
    # @return nothing important
    def process_io io
      process io.read
    end

    # Processes the given email, submits attachments to the Heathen server, delivers responses as configured
    # @param input A string containing the encoded email (suitable to be decoded using Mail.read(input)
    # @return nothing important
    def process input
      email = Mail.read_from_string input
      documents = []

      logger.info "From: #{email.from[0]} Subject: (#{email.subject}) Files: #{email.attachments.map(&:filename).join(',')}"

      #
      # Submit the attachments to heathen
      #
      email.attachments.each do |attachment|
        next unless valid_content_type? attachment.content_type
        logger.debug "Sending conversion request for #{attachment.filename} to Heathen"
        opts = {
          language: @cfg[:language],
          file: AttachmentIO.new(attachment),
          original_filename: attachment.filename,
          multipart: true,
        }
        begin
          heathen_client.convert(@cfg[:operation],opts).get do |data|
            filename = attachment.filename
            filename = File.basename(filename,File.extname(filename)) + '.pdf'
            logger.debug "Conversion received: #{filename}"
            documents << { orig_filename: attachment.filename, filename: filename, content: data, error: false }
          end
        rescue StandardError => e
          documents << { orig_filename: attachment.filename, filename: nil, content: nil, error: e.message }
        end
      end

      #
      # Deliver the converted documents
      #
      case @cfg[:mode]
        when :directory
          deliver_directory email, documents
        when :email
          deliver_email email, documents
      end

      #
      # Summarise the processing
      #
      logger.info "Results of conversion"
      documents.each do |doc|
        if doc[:content].nil?
          logger.info "  #{doc[:orig_filename]} was not converted (#{doc[:error]}) "
        else
          logger.info "  #{doc[:orig_filename]} was converted successfully"
        end
      end

      nil
    end

    # Write documents to directory
    def deliver_directory email, documents
      logger.debug "Writing response files to #{@cfg[:directory]}/"
      dir = Pathname.new @cfg[:directory]
      documents.each do |doc|
        next if doc[:content].nil?
        File.open( dir + doc[:filename], 'wb' ) do |f|
          f.write doc[:content]
          logger.debug "  #{doc[:orig_filename]} -> #{doc[:filename]}"
        end
      end
      logger.debug "Files were written to #{@cfg[:directory]}"
    end

    # Send documents to email
    def deliver_email email, documents
      send_to = @cfg[:email] == :return_to_sender ? email.from : @cfg[:email]
      logger.debug "Sending response mail to #{send_to}"
      cfg = @cfg # stoopid Mail scoping
      me = self # stoopid stoopid
      mail = Mail.new do
        from      cfg[:from]
        to        send_to
        subject   "Re: #{email.subject}"
        documents.each do |doc|
          next if doc[:content].nil?
          add_file filename: doc[:filename], content: doc[:content]
        end
        text_part do
          s = Haml::Engine.new( me.read_file cfg[:text_template] ).render(Object.new, to: send_to, documents: documents, cfg: cfg)
          body s
        end
        html_part do
          content_type 'text/html; charset=UTF-8'
          s = Haml::Engine.new( me.read_file cfg[:html_template] ).render(Object.new, to: send_to, documents: documents, cfg: cfg)
          body s
        end
      end
      mail.delivery_method :smtp, address: @cfg[:mail_host], port: @cfg[:mail_port]
      mail.deliver!

      logger.debug "Files were emailed to #{send_to}"
    end

    # Convenience constructor for heathen client
    def heathen_client
      base_uri = "#{@cfg[:heathen_scheme]}://#{@cfg[:heathen_host]}:#{@cfg[:heathen_port]}"
      Heathen::Client.new base_uri: base_uri
    end

    def logger
      @logger
    end

    def read_file filename
      f = filename
      unless File.exist? f
        f = Pathname.new(__FILE__).realpath.parent.parent + f
      end
      File.read f
    end
  end

  # RestClient (used by Heathen client) doesn't play very well with StringIO, so this wee
  # class provides the needful
  class AttachmentIO < StringIO
    def initialize attachment
      @filename = attachment.filename
      super(attachment.body.to_s)
    end
    def path
      @filename
    end
  end
end



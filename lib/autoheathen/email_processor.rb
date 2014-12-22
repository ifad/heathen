require 'mail'
require 'yaml'
require 'logger'
require 'haml'
# for content-type
require 'filemagic'
require 'filemagic/ext'

module AutoHeathen
  class EmailProcessor
    include Config

    attr_reader :cfg, :logger

    # Constructs the processor
    # @param cfg a hash of configuration settings:
    #    deliver:          true                           If false, email will not be actually sent (useful for testing)
    #    email:            nil                            Email to send response to (if mode == :email)
    #    from:             'autoheathen'                  Who to say the email is from
    #    mail_host:        'localhost'                    Mail relay host for responses (mode in [:return_to_sender,:email]
    #    mail_port:        25                             Mail relay port (ditto)
    #    text_template:    'config/response.text.haml'    Template for text part of response email (mode in [:return_to_sender,:email])
    #    html_template:    'config/response.html.haml'    Template for HTML part of response email (ditto)
    #    logger:           nil                            Optional logger object
    def initialize cfg={}, config_file=nil
      @cfg = load_config( {   # defaults
          deliver:          true,
          language:         'en',
          from:             'autoheathen',
          email:            nil,
          verbose:          false,
          mail_host:        'localhost',
          mail_port:        25,
          logger:           nil,
          text_template:    'config/autoheathen.text.haml',
          html_template:    'config/autoheathen.html.haml',
        }, config_file, cfg )
      @logger = @cfg[:logger] || Logger.new(nil)
      @logger.level = @cfg[:verbose] ? Logger::DEBUG : Logger::INFO
    end

    def process_rts email
      process email, email.from, true
    end

    # Processes the given email, submits attachments to the Heathen server, delivers responses as configured
    # @param input A string containing the encoded email (suitable to be decoded using Mail.read(input)
    # @return a hash of the decoded attachments (or the reason why they could not be decoded)
    def process email, mail_to, is_rts=false
      documents = []

      unless email.has_attachments?
        logger.info "From: #{email.from} Subject: (#{email.subject}) Files: no attachments"
        return
      end

      logger.info "From: #{email.from} Subject: (#{email.subject}) Files: #{email.attachments.map(&:filename).join(',')}"

      #
      # Convert the attachments
      #
      email.attachments.each do |attachment|
        begin
          converter = AutoHeathen::Converter.new( { logger: logger } )
          input_source = attachment.body.decoded
          action = converter.get_action input_source.content_type
          converted_filename, data = converter.convert action, @cfg[:language], attachment.filename, input_source
          documents << { orig_filename: attachment.filename, filename: converted_filename, content: data, error: false }
        rescue StandardError => e
          documents << { orig_filename: attachment.filename, filename: nil, content: nil, error: e.message }
        end
      end

      #
      # deliver the results
      #
      deliver_email email, documents, mail_to, is_rts

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

      documents
    end

    # Send documents to email
    def deliver_email email, documents, mail_to, is_rts
      cc_list = email.cc && email.cc.size > 0 ? email.cc : nil
      cc_list -= email.to if cc_list # Prevent autoheathen infinite loop!
      logger.info "Sending response mail to #{mail_to}"
      mail = Mail.new
      mail.from is_rts ? @cfg[:from] : email.from
      mail.to mail_to
      # CCs to the original email will get a copy of the converted files as well
      mail.cc cc_list if cc_list
      # Don't prepend yet another Re:
      mail.subject "#{'Re: ' unless email.subject.start_with? 'Re:'}#{email.subject}"
      # Construct received path
      # TODO: is this in the right order?
      #rcv = "by localhost(autoheathen); #{Time.now.strftime '%a, %d %b %Y %T %z'}"
      #[email.received,rcv].flatten.each { |rec| mail.received rec.to_s }
      mail.return_path email.return_path ? email.return_path
      mail.header['X-Received'] = email.header['X-Received'] if email.header['X-Received']
      documents.each do |doc|
        next if doc[:content].nil?
        mail.add_file filename: doc[:filename], content: doc[:content]
      end
      cfg = @cfg # stoopid Mail scoping
      me = self # stoopid Mail scoping
      mail.text_part do
        s = Haml::Engine.new( me.read_file cfg[:text_template] ).render(Object.new, to: mail_to, documents: documents, cfg: cfg)
        body s
      end
      mail.html_part do
        content_type 'text/html; charset=UTF-8'
        s = Haml::Engine.new( me.read_file cfg[:html_template] ).render(Object.new, to: mail_to, documents: documents, cfg: cfg)
        body s
      end
      mail.delivery_method :smtp, address: @cfg[:mail_host], port: @cfg[:mail_port]
      deliver mail
    end

    # Convenience method allowing us to stub out actual mail delivery in RSpec
    def deliver mail
      if @cfg[:deliver]
        mail.deliver!
        logger.debug "Files were emailed to #{mail.to}"
      else
        logger.debug "Files would have been emailed to #{mail.to}, but #{self.class.name} is configured not to"
      end
    end

    # Opens and reads a file, first given the filename, then tries from the project base directory
    def read_file filename
      f = filename
      unless File.exist? f
        f = Pathname.new(__FILE__).realpath.parent.parent.parent + f
      end
      File.read f
    end
  end
end



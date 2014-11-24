require 'spec_helper'
require 'autoheathen/processor'

describe AutoHeathen::Processor do
  before :all do
    @email = Mail.new do
      from 'mrblobby'
      to 'autoheathen'
      subject 'Convert: please'
      add_file (support_path + 'test1.doc').to_s
      add_file (support_path + 'poem1.jpg').to_s
    end
    @email_to_s = @email.to_s
  end
  before :each do
    @cfg = {
      logger: Logger.new('/dev/null'),
      config_file: 'spec/support/autoheathen.yml',
    }
    @hc_mock = double(Heathen::Client)
    @hc_mock_class = class_double(Heathen::Client)
    allow(Heathen::Client).to receive(:new).with(anything).and_return @hc_mock
    @mail_mock = class_double(Mail)
    @mail_mock_class = class_double(Mail)
    allow(@mail_mock_class).to receive(:new).and_yield(@mail_mock).and_return(@mail_mock)

    @poem_sample = 'This is a poem'
  end

  it 'initializes' do
    cfg = {
      mode: :directory,
      logger: Logger.new('/dev/null'),
      config_file: 'spec/support/autoheathen.yml',
    }
    p = AutoHeathen::Processor.new cfg
    expect(p.cfg).to be_a Hash
    expect(p.cfg[:mode]).to eq :directory
    expect(p.cfg[:logger]).to_not be_nil
    expect(p.logger).to be_a Logger
    expect(p.logger.debug?).to be false
    expect(p.cfg[:operation]).to eq 'pdf' # from config file
  end

  it 'validates content types' do
    p = AutoHeathen::Processor.new @cfg
    expect(p.valid_content_type? 'application/pdf').to be true
    expect(p.valid_content_type? 'application/msword').to be true
    expect(p.valid_content_type? 'foobar').to be false
  end

  it 'processes content' do
    p = AutoHeathen::Processor.new @cfg.merge( { mode: :summary, operation: 'ocr' } )
    allow(p).to receive(:heathen_client).and_return(@hc_mock)
    expect(@hc_mock).to receive(:convert) do |operation,opts|
      expect(operation).to eq 'ocr'
      expect(opts[:language]).to eq 'en'
      expect(opts[:file]).to be_a AutoHeathen::AttachmentIO
      expect(opts[:original_filename]).to eq 'test1.doc'
      expect(opts[:multipart]).to be true
      raise_error "Not good"
   end
    expect(@hc_mock).to receive(:convert) do |operation,opts|
      expect(operation).to eq 'ocr'
      expect(opts[:language]).to eq 'en'
      expect(opts[:file]).to be_a AutoHeathen::AttachmentIO
      expect(opts[:original_filename]).to eq 'poem1.jpg'
      expect(opts[:multipart]).to be true
      @hc_mock
    end
    expect(@hc_mock).to receive(:get).and_yield(@poem_sample)
   p.process @email
  end

  it 'processes email as string' do
    p = AutoHeathen::Processor.new @cfg.merge( { mode: :summary, operation: 'ocr' } )
    allow(p).to receive(:heathen_client).and_return(@hc_mock)
    expect(@hc_mock).to receive(:convert).with( String, Hash ).and_raise("Not good")
    expect(@hc_mock).to receive(:convert).with( String, Hash ).and_return(@hc_mock)
    expect(@hc_mock).to receive(:get).and_yield(@poem_sample)
    p.process_string @email_to_s
  end

  it 'processes files' do
    tmpfile = Tempfile.new 'foo'
    begin
      tmpfile.write @email_to_s
      tmpfile.close
      p = AutoHeathen::Processor.new @cfg.merge( { mode: :summary, operation: 'ocr' } )
      allow(p).to receive(:heathen_client).and_return(@hc_mock)
      expect(@hc_mock).to receive(:convert).with( String, Hash ).and_raise("Not good")
      expect(@hc_mock).to receive(:convert).with( String, Hash ).and_return(@hc_mock)
      expect(@hc_mock).to receive(:get).and_yield(@poem_sample)
      p.process_file tmpfile.path
    ensure
      tmpfile.unlink
    end
  end

  it 'processes IOs' do
    # using tempfile because StringIO is not a subclass of IO, but a duck-type
    tmpfile = Tempfile.new 'foo'
    begin
      tmpfile.write @email_to_s
      tmpfile.close
      p = AutoHeathen::Processor.new @cfg
      io = File.open tmpfile
      allow(p).to receive(:heathen_client).and_return(@hc_mock)
      expect(@hc_mock).to receive(:convert).with(String, Hash).and_raise("Not good")
      expect(@hc_mock).to receive(:convert).with(String, Hash).and_return(@hc_mock)
      expect(@hc_mock).to receive(:get).and_yield(@poem_sample)
      p.process_io io
    ensure
      tmpfile.unlink
    end
  end

  it 'delivers to directory' do
    dir = 'autoheathen.foo'
    begin
      FileUtils.rm_rf dir
      Dir.mkdir dir
      p = AutoHeathen::Processor.new @cfg.merge( { mode: :directory, directory: dir, operation: 'ocr' } )
      allow(p).to receive(:heathen_client).and_return(@hc_mock)
      expect(@hc_mock).to receive(:convert).with(String, Hash).and_raise("Not good")
      expect(@hc_mock).to receive(:convert).with(String, Hash).and_return(@hc_mock)
      expect(@hc_mock).to receive(:get).and_yield(@poem_sample)
      p.process @email
      expect( Dir.glob "#{dir}/*" ).to eq [ "#{dir}/poem1.pdf" ]
    ensure
      FileUtils.rm_rf dir
    end
  end

  it 'delivers to email' do
    @mail_mock = class_double(Mail)
    allow(@mail_mock).to receive(:new).and_return @mail_mock
    p = AutoHeathen::Processor.new @cfg.merge( { mode: :email, email: 'mrfishy', operation: 'ocr' } )
    expect(@hc_mock).to receive(:convert).with(String, Hash).and_raise("Not good")
    expect(@hc_mock).to receive(:convert).with(String, Hash).and_return(@hc_mock)
    expect(@hc_mock).to receive(:get).and_yield(@poem_sample)
    expect(p).to receive(:deliver) do |mail|
      expect(mail.from).to eq ['noreply@ifad.org']
      expect(mail.to).to eq ['mrfishy']
      expect(mail.subject).to eq "Re: Convert: please"
      expect(mail.attachments.size).to eq 1
      expect(mail.text_part.decoded.size).to be > 0
      expect(mail.html_part.decoded.size).to be > 0
      expect(mail.delivery_method.settings[:port]).to eq 25
      expect(mail.delivery_method.settings[:address]).to eq 'localhost'
    end
    p.process @email
  end

  it 'returns to sender' do
    @mail_mock = class_double(Mail)
    allow(@mail_mock).to receive(:new).and_return @mail_mock
    p = AutoHeathen::Processor.new @cfg.merge( { mode: :return_to_sender, operation: 'ocr' } )
    expect(@hc_mock).to receive(:convert).with(String, Hash).and_raise("Not good")
    expect(@hc_mock).to receive(:convert).with(String, Hash).and_return(@hc_mock)
    expect(@hc_mock).to receive(:get).and_yield(@poem_sample)
    expect(p).to receive(:deliver) do |mail|
      expect(mail.from).to eq ['noreply@ifad.org']
      expect(mail.to).to eq @email.from
      expect(mail.subject).to eq "Re: Convert: please"
    end
    p.process @email
  end

  it 'generates a heathen client' do
    p = AutoHeathen::Processor.new @cfg
    expect(p.heathen_client).to eq @hc_mock
  end

  it 'returns a logger' do
    p = AutoHeathen::Processor.new @cfg
    expect(p.logger).to be_a Logger
  end

  it 'reads a file' do
    p = AutoHeathen::Processor.new @cfg
    expect(p.read_file 'spec/support/autoheathen.yml').to be_a String
  end
end

describe AutoHeathen::AttachmentIO do
  it 'initialises' do
  end

  it 'implements path' do
  end
end

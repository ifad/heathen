require 'spec_helper'
require 'autoheathen'

describe AutoHeathen::EmailProcessor do
  before :all do
    @processor = AutoHeathen::EmailProcessor.new( {}, support_path+'autoheathen.yml' )
    @email = Mail.read( support_path + 'test1.eml' )
    @email.to [ 'bob@localhost.localdomain' ]
    @email.from [ 'bob@deviant.localdomain' ]
    @email.cc [ 'mrgrumpy', 'marypoppins', 'bob@localhost.localdomain' ]
    @email.return_path [ 'jblackman@debian.localdomain' ]
    @email.header['X-Received'] = 'misssilly'

    @poem_sample = 'This is a poem'
  end

  it 'initializes' do
    expect(@processor.cfg).to be_a Hash
    expect(@processor.logger).to be_a Logger
    expect(@processor.cfg[:from]).to eq 'noreply@ifad.org' # from config file
    expect(@processor.cfg[:mail_host]).to_not be_nil
    expect(@processor.cfg[:mail_port]).to_not be_nil
    expect(@processor.cfg[:text_template]).to_not be_nil
    expect(@processor.cfg[:html_template]).to_not be_nil
  end

  it 'processes email' do
    to_address = 'bob@localhost'
    expect(@processor).to receive(:deliver) do |mail|
      expect(mail.from).to eq @email.from
      expect(mail.to).to eq [to_address]
      expect(mail.subject).to eq "Re: Fwd: Convert: please"
      expect(mail.attachments.size).to eq 1
      expect(mail.text_part.decoded.size).to be > 0
      expect(mail.html_part.decoded.size).to be > 0
      expect(mail.delivery_method.settings[:port]).to eq 25
      expect(mail.delivery_method.settings[:address]).to eq 'localhost'
      expect(mail.cc).to eq [ 'mrgrumpy', 'marypoppins' ] # Test to exclude bob@localhost.localdomain
      #expect(mail.received).to be_a Array
      #expect(mail.received.size).to eq 2
      expect(mail.return_path).to eq 'jblackman@debian.localdomain'
      expect(mail.header['X-Received'].to_s).to eq 'misssilly'
    end
    @processor.process @email, to_address
  end

  it 'returns to sender' do
    expect(@processor).to receive(:deliver) do |mail|
      expect(mail.from).to eq ['noreply@ifad.org']
      expect(mail.to).to eq @email.from
      expect(mail.subject).to eq "Re: Fwd: Convert: please"
      expect(mail.attachments.size).to eq 1
      expect(mail.text_part.decoded.size).to be > 0
      expect(mail.html_part.decoded.size).to be > 0
      expect(mail.delivery_method.settings[:port]).to eq 25
      expect(mail.delivery_method.settings[:address]).to eq 'localhost'
      expect(mail.cc).to eq [ 'mrgrumpy', 'marypoppins' ] # Test to exclude bob@localhost.localdomain
      #expect(mail.received).to be_a Array
      #expect(mail.received.size).to eq 2
      expect(mail.return_path).to eq 'jblackman@debian.localdomain'
      expect(mail.header['X-Received'].to_s).to eq 'misssilly'
    end
    @processor.process_rts @email
  end

  it 'reads a file' do
    expect(@processor.read_file 'spec/support/autoheathen.yml').to be_a String
  end
end

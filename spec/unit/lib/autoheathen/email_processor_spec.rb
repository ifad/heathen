require 'spec_helper'
require 'autoheathen'

describe AutoHeathen::EmailProcessor do
  before :each do
    @email_blacklist_cc = 'leg.heathen@localhost'
    @processor = AutoHeathen::EmailProcessor.new( {
        cc_blacklist: [ 'wikilex@ifad.org' ],
      }, support_path+'autoheathen.yml' )
    @email_to = 'bob@localhost.localdomain'
    @email = Mail.read( support_path + 'test1.eml' )
    @email.to [ @email_to ]
    @email.from [ 'bob@deviant.localdomain' ]
    @email.cc [ 'mrgrumpy', 'marypoppins', @email_to, 'wikilex@ifad.org' ]
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

  it 'sends email onwards' do
    to_address = 'bob@foober'
    expect(@processor).to receive(:deliver) do |mail|
      expect(mail.from).to eq @email.from
      expect(mail.to).to eq [to_address]
      expect(mail.subject).to eq "Fwd: Convert: please"
      expect(mail.attachments.size).to eq 1
      expect(mail.delivery_method.settings[:port]).to eq 25
      expect(mail.delivery_method.settings[:address]).to eq 'localhost'
      expect(mail.cc).to eq [ 'mrgrumpy', 'marypoppins' ] # Test to exclude @email_to & blacklist
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
      expect(mail.cc).to eq [ 'mrgrumpy', 'marypoppins' ] # Test to exclude @email_to & blacklist
      #expect(mail.received).to be_a Array
      #expect(mail.received.size).to eq 2
      expect(mail.return_path).to eq 'jblackman@debian.localdomain'
      expect(mail.header['X-Received'].to_s).to eq 'misssilly'
    end
    @processor.process_rts @email
  end

  it 'blacklist-addrs from CC list in onwards' do
    expect(@processor).to receive(:deliver) do |mail|
      expect(mail.cc).to eq [] # Test to exclude bob@localhost.localdomain when it's the only cc
    end
    @email.cc 'bob@localhost.localdomain'
    @processor.process @email, 'bob@doofus'
  end

  it 'blacklist-addres from CC list in rts' do
    expect(@processor).to receive(:deliver) do |mail|
      expect(mail.cc).to eq [] # Test to exclude @email_to when it's the only cc
    end
    @email.cc @email_to
    @processor.process_rts @email
  end

  it 'reads a file' do
    expect(@processor.read_file 'spec/support/autoheathen.yml').to be_a String
  end
end

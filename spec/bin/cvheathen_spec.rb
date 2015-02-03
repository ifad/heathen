require 'filemagic/ext'
require 'tmpdir'
require 'spec_helper'

describe 'cvheathen' do
  let(:scratch_in) { Dir.mktmpdir 'heathen_test_' }
  let(:scratch_out) { Dir.mktmpdir 'heathen_test_' }
  let(:oo_word) { support_path+'ooword.odt' }
  let(:cvheathen) { (BASE + 'bin' + 'cvheathen').to_s }

  def exec_cvheathen
    system( cvheathen, '-v', '-i', scratch_in, '-o', scratch_out )
  end

  after do
    FileUtils.rm_rf scratch_in
    FileUtils.rm_rf scratch_out
  end

  it 'converts libreoffice to pdf' do
    FileUtils.cp oo_word, scratch_in
    expect( exec_cvheathen ).to eq true
    outfile = Pathname.new(scratch_out) + oo_word.basename.to_s.gsub( '.odt', '.pdf' )
    expect(File.exist? outfile).to eq true
    s = File.read(outfile,500)
    expect(s.mime_type).to eq 'application/pdf; charset=binary'
  end
end

require 'spec_helper'
require 'autoheathen'
require 'logger'

describe AutoHeathen::Converter do
  before :all do
    @converter = AutoHeathen::Converter.new
    @standard_encoded = "<?xml?><root/>"
  end

  it 'converts filenames' do
    expect( @converter.converted_filename 'registration/fred.pdf', @standard_encoded ).to eq 'fred.xml'
  end

  it 'validates content types' do
    expect(@converter.get_action 'image/tiff').to eq 'ocr'
    expect(@converter.get_action 'application/pdf; charset=utf-8').to eq 'ocr'
    expect(@converter.get_action 'application/msword').to eq 'pdf'
    expect{@converter.get_action 'foobar'}.to raise_error(RuntimeError)
  end

  it 'converts do' do
    content = File.read( support_path + 'quickfox.jpg' )
    filename, content = @converter.convert 'ocr', 'en', 'quickfox.jpg', content
    expect( filename ).to eq 'quickfox.pdf'
    expect( content ).not_to be_nil
  end
end

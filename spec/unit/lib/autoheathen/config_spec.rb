require 'spec_helper'
require 'autoheathen'
require 'tempfile'

describe AutoHeathen::Config do
  before :all do
    @clazz = Class.new
    @clazz.include AutoHeathen::Config
  end
  before :each do
    @obj = @clazz.new
    @tempfile = Tempfile.new 'spectest'
  end

  after :each do
    @tempfile.unlink
  end

  it "loads config with no defaults" do
    cfg = @obj.load_config nil, nil, { 'cow' => 'overcow', :rat => 'overrat' }
    expect( cfg ).to eq( {
      cow: 'overcow',
      rat: 'overrat',
    } )
  end

  it "loads config from all sources" do
    defaults = { 'foo' => 'fooble', :bar => 'barble', 'bob' => 'bobble', :cow => 'cowble', :rat => 'ratble' }
    @tempfile.write( {
      'bob' => 'filebob',
      'roger' => 'fileroger',
    }.to_yaml )
    @tempfile.close
    cfg = @obj.load_config defaults, @tempfile.path, { 'cow' => 'overcow', :rat => 'overrat' }
    expect( cfg[:foo] ).to eq 'fooble'
    expect( cfg[:bar] ).to eq 'barble'
    expect( cfg[:bob] ).to eq 'filebob'
    expect( cfg[:roger] ).to eq 'fileroger'
    expect( cfg[:cow] ).to eq 'overcow'
    expect( cfg[:rat] ).to eq 'overrat'
  end

  it "symbolizes keys" do
    in_hash = {
      :dog => 'doggle',
      'cat' => 'cattle',
      'horse' => {
        'duck' => :duckle,
        'fish' => 'fishle',
        'eagle' => [ 'the', 'quick', 'brown', 'fox' ]
      }
    }
    hash = @obj.symbolize_keys in_hash
    expect( hash ).to eq( {
      dog: 'doggle',
      cat: 'cattle',
      horse: {
        duck: :duckle,
        fish: 'fishle',
        eagle: [ 'the', 'quick', 'brown', 'fox' ]
      }
    } )
  end
end

require_relative '../lib/unobtainium/config'

describe ::Unobtainium::Config do
  before :each do
    @data_path = File.join(File.dirname(__FILE__), 'data')
  end

  it "loads a yaml config with a top-level hash correctly" do
    config = File.join(@data_path, 'hash.yml')
    cfg = ::Unobtainium::Config.load_config(config)

    expect(cfg["foo"]).to eql "bar"
    expect(cfg["baz"]).to eql "quux"
  end

  it "loads a yaml config with a top-level array correctly" do
    config = File.join(@data_path, 'array.yaml')
    cfg = ::Unobtainium::Config.load_config(config)

    expect(cfg["config"]).to eql %w(foo bar)
  end

  it "merges a hashed config correctly" do
    config = File.join(@data_path, 'hashmerge.yml')
    cfg = ::Unobtainium::Config.load_config(config)

    expect(cfg["asdf"]).to eql 1
    expect(cfg["foo.bar"]).to eql "baz"
    expect(cfg["foo.quux"]).to eql [1, 42]
    expect(cfg["foo.baz"]).to eql 3.14
    expect(cfg["blargh"]).to eql false
  end
end

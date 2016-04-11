require 'spec_helper'
require_relative '../lib/unobtainium/pathed_hash'

describe ::Unobtainium::PathedHash do
  describe "#initialize" do
    it "can be constructed without values" do
      ph = ::Unobtainium::PathedHash.new
      expect(ph.empty?).to eql true
    end

    it "can be constructed with values" do
      ph = ::Unobtainium::PathedHash.new(foo: 42)
      expect(ph.empty?).to eql false
      expect(ph[:foo]).to eql 42
    end
  end

  describe "Hash-like" do
    it "responds to Hash functions" do
      ph = ::Unobtainium::PathedHash.new
      [:invert, :delete, :fetch].each do |meth|
        expect(ph.respond_to?(meth)).to eql true
      end
    end

    it "can be used like a hash" do
      ph = ::Unobtainium::PathedHash.new(foo: 42)
      inverted = ph.invert
      expect(inverted.empty?).to eql false
      expect(inverted[42]).to eql :foo
    end
  end

  it "can recursively read entries via a path" do
    sample = {
      "foo" => 42,
      "bar" => {
        "baz" => "quux",
        "blah" => [1, 2],
      }
    }
    ph = ::Unobtainium::PathedHash.new(sample)

    expect(ph["foo"]).to eql 42
    expect(ph["bar.baz"]).to eql "quux"
    expect(ph["bar.blah"]).to eql [1, 2]

    expect(ph["nope"]).to eql nil
    expect(ph["bar.nope"]).to eql nil
  end

  it "can recursively write entries via a path" do
    ph = ::Unobtainium::PathedHash.new
    ph["foo.bar"] = 42
    expect(ph["foo.bar"]).to eql 42
  end

  it "has the same string representation as the hash it's initialized from" do
    h = { foo: 42 }
    ph = ::Unobtainium::PathedHash.new(h)
    expect(ph.to_s).to eql h.to_s
  end
end

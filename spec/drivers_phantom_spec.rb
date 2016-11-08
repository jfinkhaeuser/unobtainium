require 'spec_helper'
require_relative '../lib/unobtainium/drivers/phantom'


class SeleniumMock
  def test
    return "selenium"
  end

  def selenium_only
    return "selenium"
  end
end

class AppiumMock
  def test
    return "appium"
  end

  def appium_only
    return "appium"
  end

  def start_driver
    return SeleniumMock.new
  end
end

describe ::Unobtainium::Drivers::Phantom do
  let(:tester) { ::Unobtainium::Drivers::Phantom }

  context "#matches?" do
    it "matches all known aliases" do
      aliases = [:phantomjs, :headless, :phantom]
      aliases.each do |name|
        expect(tester.matches?(name)).to be_truthy
      end
    end

    it "does not match unknown names" do
      unknown = [:foo, :bar, :appium, :selenium, :ios]
      unknown.each do |name|
        expect(tester.matches?(name)).to be_falsey
      end
    end
  end

  context "#ensure_preconditions" do
    it "will succeed because development dependencies include requirements" do
      expect { tester.ensure_preconditions(:label, nil) }.not_to raise_error
    end

    it "would fail if requirements were not met" do
      allow_any_instance_of(Object).to receive(:require) do |context, name|
        if name == 'phantomjs'
          raise LoadError
        end
      end
      expect { tester.ensure_preconditions(:label, nil) }.to raise_error(LoadError)
    end
  end

  context "#resolve_options" do
    it "normalizes labels" do
      ::Unobtainium::Drivers::Phantom::LABELS.each do |normalized, aliases|
        ([normalized] + aliases).each do |label|
          returned_label, _ = tester.resolve_options(label, nil)
          expect(returned_label).to eql normalized
        end
      end
    end

    context "phantomjs options" do
      it "prefers the string if both :phantomjs and 'phantomjs' are given" do
        opts = {
          phantomjs: { scheme: 123 },
          'phantomjs' => { scheme: 42},
        }

        resolved = nil
        expect { _, resolved = tester.resolve_options(:phantomjs, opts) }.not_to raise_error
        expect(resolved['phantomjs.scheme']).to eql 42
      end

      it "uses :url if that is given" do
        opts = {
          url: 'http://localhost:1234',
        }

        _, resolved = tester.resolve_options(:phantomjs, opts)
        expect(resolved[:phantomjs]).not_to be_nil
        expect(resolved['phantomjs.scheme']).to eql 'http'
        expect(resolved['phantomjs.host']).to eql 'localhost'
        expect(resolved['phantomjs.port']).to eql 1234
        expect(resolved['url']).to eql 'http://localhost:1234'
      end

      it "prefers :phantomjs over :url" do
        opts = {
          url: 'http://localhost:1234',
          phantomjs: {
            port: 8888
          },
        }

        _, resolved = tester.resolve_options(:phantomjs, opts)
        expect(resolved[:phantomjs]).not_to be_nil
        expect(resolved['phantomjs.scheme']).to eql 'http'
        expect(resolved['phantomjs.host']).to eql 'localhost'
        expect(resolved['phantomjs.port']).to eql 8888
        expect(resolved['url']).to eql 'http://localhost:8888'
      end

      it "defaults to 'http' and 'localhost' and a free port" do
        allow(tester).to receive(:scan) { |*args| [9134] }
        _, resolved = tester.resolve_options(:phantomjs, nil)
        expect(resolved[:phantomjs]).not_to be_nil
        expect(resolved['phantomjs.scheme']).to eql 'http'
        expect(resolved['phantomjs.host']).to eql 'localhost'
        expect(resolved['phantomjs.port']).to eql 9134
        expect(resolved['url']).to eql 'http://localhost:9134'
      end

      it "raises an error when no free port could be found" do
        allow(tester).to receive(:scan) { |*args| [] }
        expect { tester.resolve_options(:phantomjs, nil) }.to raise_error(RuntimeError)
      end
    end
  end
end

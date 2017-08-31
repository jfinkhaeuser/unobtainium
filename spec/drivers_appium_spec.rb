require 'spec_helper'
require_relative '../lib/unobtainium/drivers/appium'

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

describe ::Unobtainium::Drivers::Appium do
  let(:tester) { ::Unobtainium::Drivers::Appium }

  context "#matches?" do
    it "matches all known aliases" do
      aliases = %i[ios iphone ipad android]
      aliases.each do |name|
        expect(tester.matches?(name)).to be_truthy
      end
    end

    it "does not match unknown names" do
      unknown = %i[foo bar appium phantomjs headless]
      unknown.each do |name|
        expect(tester.matches?(name)).to be_falsey
      end
    end
  end

  context ::Unobtainium::Drivers::Appium::DriverProxy do
    let(:appium_driver) { AppiumMock.new }

    it "prefers appium if compatibility is not desired" do
      proxy = ::Unobtainium::Drivers::Appium::DriverProxy.new(appium_driver, false)

      expect(proxy.respond_to?(:test)).to be_truthy
      expect(proxy.respond_to?(:selenium_only)).to be_truthy
      expect(proxy.respond_to?(:appium_only)).to be_truthy

      expect(proxy.test).to eql "appium"
      expect(proxy.selenium_only).to eql "selenium"
      expect(proxy.appium_only).to eql "appium"
    end

    it "prefers selenium if compatibility is desired" do
      proxy = ::Unobtainium::Drivers::Appium::DriverProxy.new(appium_driver, true)

      expect(proxy.respond_to?(:test)).to be_truthy
      expect(proxy.respond_to?(:selenium_only)).to be_truthy
      expect(proxy.respond_to?(:appium_only)).to be_truthy

      expect(proxy.test).to eql "selenium"
      expect(proxy.selenium_only).to eql "selenium"
      expect(proxy.appium_only).to eql "appium"
    end

    it "fails if an undefined method is called" do
      proxy = ::Unobtainium::Drivers::Appium::DriverProxy.new(appium_driver, true)
      expect(proxy.respond_to?(:undefined_method)).to be_falsy
      expect { proxy.undefined_method }.to raise_error(NoMethodError)

      proxy = ::Unobtainium::Drivers::Appium::DriverProxy.new(appium_driver, false)
      expect(proxy.respond_to?(:undefined_method)).to be_falsy
      expect { proxy.undefined_method }.to raise_error(NoMethodError)
    end
  end

  context "#ensure_preconditions" do
    it "will succeed because development dependencies include requirements" do
      expect { tester.ensure_preconditions(:label, nil) }.not_to raise_error
    end

    it "would fail if requirements were not met" do
      allow_any_instance_of(Object).to receive(:require).and_raise(LoadError)
      expect { tester.ensure_preconditions(:label, nil) }.to raise_error(LoadError)
    end
  end

  context "#resolve_options" do
    it "normalizes labels" do
      ::Unobtainium::Drivers::Appium::LABELS.each do |normalized, aliases|
        ([normalized] + aliases).each do |label|
          returned_label, _ = tester.resolve_options(label, nil)
          expect(returned_label).to eql normalized
        end
      end
    end

    context "capabilities merging" do
      let(:caps1) { { foo: 42 } }
      let(:caps2) { { foo: 123 } }
      let(:caps3) { { foo: "bar" } }

      it "creates :caps from :desired_capabilities" do
        _, resolved = tester.resolve_options(:ios, desired_capabilities: caps1)

        expect(resolved[:caps]).not_to be_nil
        expect(resolved[:caps][:foo]).to eql 42
        expect(resolved[:desired_capabilites]).to be_nil
      end

      it "creates :caps from 'desired_capabilities'" do
        _, resolved = tester.resolve_options(:ios, 'desired_capabilities' => caps1)

        expect(resolved[:caps]).not_to be_nil
        expect(resolved[:caps][:foo]).to eql 42
        expect(resolved['desired_capabilities']).to be_nil
      end

      it "merges :caps with :desired_capabilities" do
        opts = {
          desired_capabilities: caps1,
          caps: caps2
        }
        _, resolved = tester.resolve_options(:ios, opts)

        expect(resolved[:caps]).not_to be_nil
        expect(resolved[:caps][:foo]).to eql 123
        expect(resolved[:desired_capabilities]).to be_nil
      end

      it "merges :caps with 'desired_capabilities'" do
        opts = {
          'desired_capabilities' => caps1,
          caps: caps2,
        }
        _, resolved = tester.resolve_options(:ios, opts)

        expect(resolved[:caps]).not_to be_nil
        expect(resolved[:caps][:foo]).to eql 123
        expect(resolved['desired_capabilities']).to be_nil
      end

      it "merges :caps with :desired_capabilities and 'desired_capabilities'" do
        opts = {
          'desired_capabilities' => caps1,
          desired_capabilites: caps2,
          caps: caps3,
        }
        _, resolved = tester.resolve_options(:ios, opts)

        expect(resolved[:caps]).not_to be_nil
        expect(resolved[:caps][:foo]).to eql 'bar'
        expect(resolved[:desired_capabilities]).to be_nil
        expect(resolved['desired_capabilities']).to be_nil
      end
    end

    it "adds a normalized platform name" do
      _, resolved = tester.resolve_options(:iphone, nil)

      expect(resolved['caps.platformName']).to eql 'ios'
    end

    context "appium URL" do
      it "uses 'url' when nothing else is given" do
        _, resolved = tester.resolve_options(:iphone, url: 'test')
        expect(resolved['url']).to eql 'test'
        expect(resolved['appium_lib.server_url']).to eql 'test'
      end

      it "prefers 'appium_lib.server_url' to 'url'" do
        opts = {
          url: 'test1',
          appium_lib: {
            server_url: 'test2',
          },
        }
        _, resolved = tester.resolve_options(:iphone, opts)
        expect(resolved['url']).to eql 'test1'
        expect(resolved['appium_lib.server_url']).to eql 'test2'
      end

      it "does not set anything if nothing is given" do
        _, resolved = tester.resolve_options(:iphone, nil)
        expect(resolved['url']).to be_nil
        expect(resolved['appium_lib.server_url']).to be_nil
      end
    end

    context "browser matching" do
      it "does nothing if no browser is requested" do
        _, resolved = tester.resolve_options(:iphone, nil)
        expect(resolved['caps.browserName']).to be_nil
      end

      it "does nothing if no browser match is found" do
        _, resolved = tester.resolve_options(:iphone, browser: :chrome)
        expect(resolved['caps.browserName']).to be_nil

        _, resolved = tester.resolve_options(:iphone, browser: :safari)
        expect(resolved['caps.browserName']).to be_nil
      end

      it "supplements browserName for chrome on android" do
        _, resolved = tester.resolve_options(:android, browser: :chrome)
        expect(resolved['caps.browserName']).to eql 'Chrome'
      end

      it "raises instead of overwriting explicit options" do
        opts = {
          browser: :chrome,
          caps: {
            platformName: :android,
            browserName: 'Something Else',
          }
        }
        expect { tester.resolve_options(:android, opts) }.to \
          raise_error(ArgumentError)
      end

      it "silently ignores identical options" do
        opts = {
          browser: :chrome,
          caps: {
            platformName: :android,
            browserName: 'Chrome',
          }
        }
        resolved = nil
        expect { _, resolved = tester.resolve_options(:android, opts) }.not_to \
          raise_error
        expect(resolved['caps.browserName']).to eql 'Chrome'
      end
    end
  end
end

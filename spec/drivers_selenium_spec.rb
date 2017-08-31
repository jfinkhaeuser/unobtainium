require 'spec_helper'
require_relative '../lib/unobtainium/drivers/selenium'

describe ::Unobtainium::Drivers::Selenium do
  let(:tester) { ::Unobtainium::Drivers::Selenium }

  context "#matches?" do
    it "matches all known aliases" do
      aliases = %i[
        firefox ff internet_explorer internetexplorer explorer
        ie safari chrome chromium
      ]
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
      ::Unobtainium::Drivers::Selenium::LABELS.each do |normalized, aliases|
        ([normalized] + aliases).each do |label|
          returned_label, _ = tester.resolve_options(label, nil)
          if normalized == :chromium
            expect(returned_label).to eql :chrome # chromedriver
          else
            expect(returned_label).to eql normalized
          end
        end
      end
    end

    context "capabilities merging" do
      let(:caps1) { { foo: 42 } }
      let(:caps2) { { foo: 123 } }
      let(:caps3) { { foo: "bar" } }

      it "creates :desired_capabilites from :caps" do
        _, resolved = tester.resolve_options(:chrome, caps: caps1)

        expect(resolved[:desired_capabilities]).not_to be_nil
        expect(resolved[:desired_capabilities][:foo]).to eql 42
        expect(resolved[:caps]).to be_nil
      end

      it "creates :desired_capabilites from 'caps'" do
        _, resolved = tester.resolve_options(:chrome, 'caps' => caps1)

        expect(resolved[:desired_capabilities]).not_to be_nil
        expect(resolved[:desired_capabilities][:foo]).to eql 42
        expect(resolved['caps']).to be_nil
      end

      it "merges :desired_capabilites with :caps" do
        opts = {
          caps: caps1,
          desired_capabilities: caps2,
        }
        _, resolved = tester.resolve_options(:chrome, opts)

        expect(resolved[:desired_capabilities]).not_to be_nil
        expect(resolved[:desired_capabilities][:foo]).to eql 123
        expect(resolved[:caps]).to be_nil
      end

      it "merges :desired_capabilites with 'caps'" do
        opts = {
          'caps' => caps1,
          desired_capabilities: caps2,
        }
        _, resolved = tester.resolve_options(:chrome, opts)

        expect(resolved[:desired_capabilities]).not_to be_nil
        expect(resolved[:desired_capabilities][:foo]).to eql 123
        expect(resolved['caps']).to be_nil
      end

      it "merges :desired_capabilites with :caps and 'caps'" do
        opts = {
          'caps' => caps1,
          caps: caps2,
          desired_capabilities: caps3,
        }
        _, resolved = tester.resolve_options(:chrome, opts)

        expect(resolved[:desired_capabilities]).not_to be_nil
        expect(resolved[:desired_capabilities][:foo]).to eql 'bar'
        expect(resolved[:caps]).to be_nil
        expect(resolved['caps']).to be_nil
      end
    end

    context ":chromium" do
      it "supplements a binary when one is found" do
        # Ensure a test result
        allow_any_instance_of(Object).to receive(:require) {}
        allow(File).to receive(:which) { '/path/to/binary' }

        label, resolved = tester.resolve_options(:chromium, nil)

        expect(resolved[:desired_capabilities]["chromeOptions"]["binary"]).to \
          eql '/path/to/binary'
        expect(label).to eql :chrome
      end

      it "returns the label and options unaltered when no binary is found" do
        # Ensure a test result
        allow_any_instance_of(Object).to receive(:require) {}
        allow(File).to receive(:which) { nil }

        label, resolved = tester.resolve_options(:chromium, nil)

        expect(resolved[:desired_capabilities]["chromeOptions"]).to be_nil
        expect(label).to eql :chromium
      end

      it "does not overwrite binaries if they are set" do
        # Ensure a test result
        allow_any_instance_of(Object).to receive(:require) {}
        allow(File).to receive(:which) { '/path/to/binary' }

        opts = {
          desired_capabilities: {
            chromeOptions: {
              binary: 'test',
            },
          },
        }
        label, resolved = tester.resolve_options(:chromium, opts)

        expect(resolved[:desired_capabilities]["chromeOptions"]["binary"]).to \
          eql 'test'
        expect(label).to eql :chrome
      end
    end

    context "fixing options" do
      it "symbolies option keys" do
        opts = {
          "foo" => "bar",
          baz: 42,
        }
        _, resolved = tester.resolve_options(:chromium, opts)

        expect(resolved["foo"]).to be_nil
        expect(resolved[:foo]).to eql "bar"
        expect(resolved["baz"]).to be_nil
        expect(resolved[:baz]).to eql 42
      end
    end
  end
end

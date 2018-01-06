require 'spec_helper'

describe ConfigModel do

  class DefaultModel < ConfigModel
    key(:default) { 'true' }
    key(:secondary) { 'foobar' }
  end

  describe "#default_value" do
    it 'prefers Environment Variables to provided defaults' do
      ENV['DEFAULT'] = 'false'

      shipping = DefaultModel.new
      expect(shipping.default).to eq 'false'
    end
  end

  describe "#create" do
    it 'from ENV variable for factory' do
      ENV['DEFAULT_MODEL'] = 'from_yaml'

      shipping = DefaultModel.create
      expect(shipping.default).to eq 'foo'
    end

    it 'overrides factory with data passed in by Hash' do
      ENV['DEFAULT_MODEL'] = 'from_yaml'

      shipping = DefaultModel.create(secondary: 'foo')
      expect(shipping.secondary).to eq 'foo'
    end
  end
end
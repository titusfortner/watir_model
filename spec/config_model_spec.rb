require 'spec_helper'

describe ConfigModel do

  it 'prefers Environment Variables to provided defaults' do
    ENV['DEFAULT'] = 'false'
    class DefaultModel < ConfigModel
      boolean(:default) { 'true' }
    end

    shipping = DefaultModel.new
    expect(shipping.default).to be_a FalseClass
  end

end

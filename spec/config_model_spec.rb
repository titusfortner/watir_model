require 'spec_helper'

describe ConfigModel do

  it 'prefers Environment Variables to provided defaults' do
    ENV['DEFAULT'] = 'false'
    class DefaultModel < ConfigModel
      key(:default) { 'true' }
    end

    shipping = DefaultModel.new
    expect(shipping.default).to eq 'false'
  end

end

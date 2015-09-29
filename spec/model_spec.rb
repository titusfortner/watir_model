lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'model'

describe Model do

  class AddressModel < Model
    key(:street1) {'11800 Domain Blvd'}
    key(:street2)
    key(:city)    {'Austin'}
    key(:state)   {'TX'}
    key(:zip)     {'78758'}
  end

  it 'should be usable without needing to pass anything to it' do
    address = AddressModel.new
    expect(address.street1).to eql '11800 Domain Blvd'
    expect(address.city).to eql 'Austin'
    expect(address.state).to eql 'TX'
    expect(address.zip).to eql '78758'
  end

  it 'should allow keys with no default values' do
    address = AddressModel.new
    expect(address.street2).to eql nil
  end

  it 'should allow values to be set when initialized' do
    address = AddressModel.new(street1: '1101 Fifth St')
    expect(address.street1).to eql '1101 Fifth St'
  end

  it 'should allow values to be set after initialized' do
    address = AddressModel.new
    address.street1 = '1101 Fifth St'
    expect(address.street1).to eql '1101 Fifth St'
  end

  it 'should track its keys in the order defined' do
    address = AddressModel.new
    expect(address.keys).to eql [:street1, :street2, :city, :state, :zip]
  end

  it 'should fail if undefined keys are used' do
    address = AddressModel.new
    expect{address.street}.to raise_error(NoMethodError)
    expect{AddressModel.new(street: '1101 Fifth St')}.to raise_error(ArgumentError, 'unknown keyword: street')
    expect{AddressModel.new(a: 'hi', b: 'hello')}.to raise_error(ArgumentError, 'unknown keywords: a, b')
  end

  it 'should be able to be updated' do
    address = AddressModel.new
    address.zip = '02134'
    expect(address.zip).to eql '02134'
  end

  require 'faker'
  class UserModel < Model
    key(:first) {Faker::Name.first_name}
    key(:last)  {Faker::Name.last_name}
    key(:email) {"#{first}.#{last}@devmail.company.com"}
  end

  it 'should allow default value blocks to reference other default values' do
    user = UserModel.new
    expect(user.email).to eql "#{user.first}.#{user.last}@devmail.company.com"
  end

  it 'should allow default value blocks to reference other assigned values' do
    user = UserModel.new(first: 'Peidong', last: 'Yang')
    expect(user.email).to eql "Peidong.Yang@devmail.company.com"
  end

end
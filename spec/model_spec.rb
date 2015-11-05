lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'model'

describe Model do

  class AddressModel < Model
    key(:street1) { '11800 Domain Blvd' }
    key(:street2)
    key(:city) { 'Austin' }
    key(:state) { 'TX' }
    key(:zip) { '78758' }
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

  it 'should allow default values to be removed' do
    address1 = AddressModel.new(zip: nil)
    expect(address1.zip).to eql nil
    address2 = AddressModel.new
    address2.zip = nil
    expect(address2.zip).to eql nil
  end

  it 'should track its keys in the order defined' do
    address = AddressModel.new
    expect(address.keys).to eql [:street1, :street2, :city, :state, :zip]
  end

  it 'should fail if undefined keys are used' do
    address = AddressModel.new
    expect { address.street }.to raise_error(NoMethodError)
    expect { AddressModel.new(street: '1101 Fifth St') }.to raise_error(ArgumentError, 'unknown keyword: street')
    expect { AddressModel.new(a: 'hi', b: 'hello') }.to raise_error(ArgumentError, 'unknown keywords: a, b')
  end

  require 'faker'
  class UserModel < Model
    key(:first) { Faker::Name.first_name }
    key(:last) { Faker::Name.last_name }
    key(:email) { "#{first}.#{last}@devmail.company.com" }
  end

  it 'should allow default value blocks to reference other default values' do
    user = UserModel.new
    expect(user.email).to eql "#{user.first}.#{user.last}@devmail.company.com"
  end

  it 'should allow default value blocks to reference other assigned values' do
    user = UserModel.new(first: 'Peidong', last: 'Yang')
    expect(user.email).to eql "Peidong.Yang@devmail.company.com"
  end

  it 'should allow a second key definition to replace a previous definition' do
    class SimpleModel < Model
      key(:slot) { 'first' }
      key(:slot) { 'second' }
    end
    simple = SimpleModel.new
    expect(simple.keys).to eql [:slot]
    expect(simple.slot).to eql 'second'
  end

  class OwnerModel < UserModel
    key(:email) { "#{first}.#{last}@owner.company.com" }
    key(:address) { '5210 Paseo de Pablo' }
  end

  it 'should inherit keys' do
    owner = OwnerModel.new
    expect(owner.keys).to eql [:first, :last, :email, :address]
  end

  it 'should inherit defaults' do
    owner = OwnerModel.new
    expect(owner.email).to eql "#{owner.first}.#{owner.last}@owner.company.com"
  end

  it 'should allow access to keys using hash syntax' do
    user = UserModel.new(first: 'Ken')
    expect(user[:first]).to eql 'Ken'
  end

  it 'should know whether two models are equal' do
    user1 = UserModel.new(first: 'Kartik', last: 'Chandran')
    user2 = UserModel.new(first: 'Kartik', last: 'Chandran')
    expect(user1).to eql user2
  end

  it 'should not find a model equal to its subset' do
    UserModel.key(:id)
    user1 = UserModel.new(first: 'Kartik', last: 'Chandran')
    user2 = UserModel.new(id: 1, first: 'Kartik', last: 'Chandran')
    expect(user1).to_not eql user2
    expect(user2).to_not eql user1
  end

end

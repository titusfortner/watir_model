require 'spec_helper'

describe WatirModel do

  class AddressModel < WatirModel
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

  it 'should allow values to be set with keys as Strings' do
    address = AddressModel.new('street1' => '1101 Fifth St')
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

  it 'should fail if undefined keys are defined' do
    expect { AddressModel.new(:street => '1101 W Fifth St') }.to raise_error(ArgumentError, 'unknown keyword: street')
  end

  require 'faker'
  class UserModel < WatirModel
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
    class SimpleModel < WatirModel
      key(:slot) { 'first' }
      key(:slot) { 'second' }
    end
    simple = SimpleModel.new
    expect(simple.keys).to eql [:slot]
    expect(simple.slot).to eql 'second'
  end

  describe '#convert' do
    it 'creates a new model as a subset of a hash' do
      user_data = {first: 'Peidong', last: 'Yang', foo: 'foo', bar: 'bar'}
      user = UserModel.convert(user_data)

      expect(user.first).to eq 'Peidong'
      expect { user.foo }.to raise_error(NoMethodError)
      expect { user.bar }.to raise_error(NoMethodError)
    end

    it 'allows additional attributes to be accessed' do
      user_data = {first: 'Billy', last: 'Shakespere', foo: 'foo', bar: 'bar', foobar: 'foobar'}
      user = UserModel.convert(user_data, :foo, :bar)

      expect(user.first).to eq 'Billy'
      expect(user.foo).to eq 'foo'
      expect(user.bar).to eq 'bar'
      expect { user.foobar }.to raise_error(NoMethodError)
    end

    it 'only adds accessors to single instance' do
      user_data = {first: 'Billy', last: 'Shakespere', foo: 'foo', bar: 'bar'}
      UserModel.convert(user_data, :foo, :bar)
      user = UserModel.new
      expect { user.foo }.to raise_error(NoMethodError)
    end

    it 'accepts keys as Strings' do
      user_data = {'first' => 'Peidong'}
      user = UserModel.convert(user_data)

      expect(user.first).to eq 'Peidong'
    end
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

  it 'should not find a watir_model equal to its subset' do
    UserModel.key(:id)
    user1 = UserModel.new(first: 'Kartik', last: 'Chandran')
    user2 = UserModel.new(id: 1, first: 'Kartik', last: 'Chandran')
    expect(user1).to_not eql user2
    expect(user2).to_not eql user1
  end

  it 'can update model values with a hash' do
    address = AddressModel.new
    address.update(street1: '1101 Fifth St',
                   street2: 'Suite 300')
    expect(address.street1).to eql '1101 Fifth St'
    expect(address.street2).to eql 'Suite 300'
  end

  class ShippingModel < WatirModel
    key(:updated_at) { '2016-02-15' }
    key(:city) { 'Anchorage' }
    key(:state) { 'AK' }
    key(:postal) { 99530-9998 }
    key(:fedex_score) { '1' }
    key(:default) { 'true' }
    key(:postage) { '22.22' }
  end

  it 'coverts watir model to hash' do
    test_hash = {
        test_array: [1, 2, 3, 4, 5],
        test_value: 'value',
        test_model: {
            value: 'value'
        },
        test_hash: {
            t1: '1', t2: [1, 2, 3, 4, 5], t3: { value: 'value' }, t4: { a1: { value: 'value' } }
        }
    }

    class TestModel < WatirModel
      key(:value) { 'value' }
    end

    class TestClass < WatirModel
      key(:test_array) { [1,2,3,4,5,] }
      key(:test_value) { 'value' }
      key(:test_model) { TestModel.new }
      key(:test_hash)  { { t1: '1', t2: test_array, t3: test_model, t4: { a1: test_model } } }
    end

    test_data = TestClass.new.to_hash

    expect(test_data[:test_array]).to be_an Array
    expect(test_data[:test_value]).to be_a  String
    expect(test_data).to be_a  Hash
    expect(test_data[:test_hash]).to  be_a  Hash
    expect(test_data).to eql(test_hash)
  end

end

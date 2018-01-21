require 'spec_helper'

describe WatirModel do

  class Address < WatirModel
    key(:street1, api: :street_address, data_type: String) { '11800 Domain Blvd' }
    key(:street2)
    key(:city) { 'Austin' }
    key(:state) { 'TX' }
    key(:zip) { '78758' }
  end

  it 'should be usable without needing to pass anything to it' do
    address = Address.new
    expect(address.street1).to eql '11800 Domain Blvd'
    expect(address.city).to eql 'Austin'
    expect(address.state).to eql 'TX'
    expect(address.zip).to eql '78758'
  end

  it 'should allow keys with no default values' do
    address = Address.new
    expect(address.street2).to eql nil
  end

  it 'should allow values to be set when initialized' do
    address = Address.new(street1: '1101 Fifth St')
    expect(address.street1).to eql '1101 Fifth St'
  end

  it 'should allow values to be set with keys as Strings' do
    address = Address.new('street1' => '1101 Fifth St')
    expect(address.street1).to eql '1101 Fifth St'
  end

  it 'should allow values to be set after initialized' do
    address = Address.new
    address.street1 = '1101 Fifth St'
    expect(address.street1).to eql '1101 Fifth St'
  end

  it 'should allow default values to be removed' do
    address1 = Address.new(zip: nil)
    expect(address1.zip).to eql nil
    address2 = Address.new
    address2.zip = nil
    expect(address2.zip).to eql nil
  end

  it 'should track its keys in the order defined' do
    address = Address.new
    expect(address.keys).to eql [:street1, :street2, :city, :state, :zip]
  end

  it 'should fail if undefined keys are used' do
    address = Address.new
    expect { address.street }.to raise_error(NoMethodError)
    expect { Address.new(street: '1101 Fifth St') }.to raise_error(ArgumentError, 'unknown keyword: street')
    expect { Address.new(a: 'hi', b: 'hello') }.to raise_error(ArgumentError, 'unknown keywords: a, b')
  end

  it 'should fail if undefined keys are defined' do
    expect { Address.new(:street => '1101 W Fifth St') }.to raise_error(ArgumentError, 'unknown keyword: street')
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
      user_data = {first: 'Peidong', last: 'Yang', email: 'a@b.com', foo: 'foo', bar: 'bar'}
      user = UserModel.convert(user_data)

      expect(user.first).to eq 'Peidong'
      expect { user.foo }.to raise_error(NoMethodError)
      expect { user.bar }.to raise_error(NoMethodError)
    end

    it 'allows additional attributes to be accessed' do
      user_data = {first: 'Billy', last: 'Shakespere', email: 'a@b.com', foo: 'foo', bar: 'bar', foobar: 'foobar'}
      user = UserModel.convert(user_data, :foo, :bar)

      expect(user.first).to eq 'Billy'
      expect(user.foo).to eq 'foo'
      expect(user.bar).to eq 'bar'
      expect { user.foobar }.to raise_error(NoMethodError)
    end

    it 'only adds accessors to single instance' do
      user_data = {first: 'Billy', last: 'Shakespere', email: 'a@b.com', foo: 'foo', bar: 'bar'}
      UserModel.convert(user_data, :foo, :bar)
      user = UserModel.new
      expect { user.foo }.to raise_error(NoMethodError)
    end

    it 'accepts keys as Strings' do
      user_data = {'first' => 'Peidong', last: 'Shakespere', email: 'a@b.com'}
      user = UserModel.convert(user_data)

      expect(user.first).to eq 'Peidong'
    end

    it 'raises exception if converting a Hash that is missing keys' do
      user_data = {first: 'Billy', last: 'Shakespere'}
      msg = "Can not convert Hash to Model when keys with default values are missing"
      expect { UserModel.convert(user_data) }.to raise_exception(StandardError, msg)
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
    address = Address.new
    address.update(street1: '1101 Fifth St',
                   street2: 'Suite 300')
    expect(address.street1).to eql '1101 Fifth St'
    expect(address.street2).to eql 'Suite 300'
  end

  class ShippingAddress < WatirModel
    key(:updated_at) { '2016-02-15' }
    key(:city) { 'Anchorage' }
    key(:state) { 'AK' }
    key(:postal) { '99530-9998' }
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
            t1: '1', t2: [1, 2, 3, 4, 5], t3: {value: 'value'}, t4: {a1: {value: 'value'}}
        }
    }

    class TestModel < WatirModel
      key(:value) { 'value' }
    end

    class TestClass < WatirModel
      key(:test_array) { [1, 2, 3, 4, 5,] }
      key(:test_value) { 'value' }
      key(:test_model) { TestModel.new }
      key(:test_hash) { {t1: '1', t2: test_array, t3: test_model, t4: {a1: test_model}} }
    end

    test_data = TestClass.new.to_h

    expect(test_data[:test_array]).to be_an Array
    expect(test_data[:test_value]).to be_a String
    expect(test_data).to be_a Hash
    expect(test_data[:test_hash]).to be_a Hash
    expect(test_data[:test_model]).to be_a Hash
    expect(test_data).to eql(test_hash)
  end

  class TypeExample < WatirModel
    key(:name, data_type: String) { 'Roger' }
    key(:time, data_type: Time) { Time.now }
    key(:datetime, data_type: DateTime) { DateTime.now }
    key(:number, data_type: Integer) { 4 }
    key(:floating, data_type: Float) { 4.0 / 3 }
    key(:exists, data_type: :boolean) { false }
    key(:weekday, data_type: Symbol) { :monday }
    key(:whoops, data_type: Symbol) { 'string' }
    key(:default) { 'whatevs' }
    key(:hashing, data_type: Hash)
    key(:list, data_type: Array)
    key(:modeling, data_type: ShippingAddress)
  end

  describe 'Types' do
    it 'converts Symbol to String' do
      te = TypeExample.new(name: :foo)
      expect(te.name).to be_a String
    end

    it 'converts String to Time' do
      te = TypeExample.new(time: "2017-01-06 22:14:33 -0600")
      expect(te.time).to be_a Time
    end

    it 'converts String to DateTime' do
      te = TypeExample.new(datetime: "2017-01-06T21:50:44-06:00")
      expect(te.datetime).to be_a DateTime
    end

    it 'converts String to Integer' do
      te = TypeExample.new(number: '372.0')
      expect(te.number).to be_a Integer
    end

    it 'converts String to Float' do
      te = TypeExample.new(floating: '372.0')
      expect(te.floating).to be_a Float
    end

    it 'converts String to Boolean' do
      te = TypeExample.new(exists: 'true')
      expect(te.exists).to be_a TrueClass
    end

    it 'converts String to Symbol' do
      te = TypeExample.new(weekday: 'tuesday')
      expect(te.weekday).to be_a Symbol
    end

    it 'raises exception if unable to convert' do
      expect { TypeExample.new(exists: 7) }.to raise_error(TypeError)
    end

    it 'converts mismatched default value' do
      expect(TypeExample.new.whoops).to be_a Symbol
    end

    it 'converts json to hash' do
      json = {foo: :bar}.to_json
      te = TypeExample.new(hashing: json)
      expect(te.hashing).to be_a Hash
    end

    it 'converts json to array' do
      json = [:foo, :bar].to_json
      te = TypeExample.new(list: json)
      expect(te.list).to be_a Array
    end

    it 'converts a hash to a Watir Model' do
      sm = ShippingAddress.new.to_h
      te = TypeExample.new(modeling: sm)
      expect(te.modeling).to be_a WatirModel
    end
  end

  describe 'Factory' do
    it 'initializes model from data in yml' do
      address = Address.alaska
      expect(address.street1).to eql '11800 Domain Blvd'
      expect(address.city).to eql 'Anchorage'
      expect(address.state).to eql 'AK'
      expect(address.zip).to eql '99501'
    end

    it 'raises exception when requested data is not present in the file' do
      msg = "Factory 'oregon' does not exist in 'config/data/address.yml'"
      expect { Address.oregon }.to raise_exception ArgumentError, msg
    end

    it 'raises exception when requested file does not exist' do
      msg = "undefined method `oregon' for ShippingAddress:Class"
      expect { ShippingAddress.oregon }.to raise_exception NoMethodError, msg
    end

    it 'sets default directory for yaml' do
      begin
        WatirModel.yml_directory = 'config/alternate'
        msg = "Factory 'oregon' does not exist in 'config/alternate/address.yml'"
        expect { Address.oregon }.to raise_exception ArgumentError, msg
      ensure
        WatirModel.yml_directory = nil
      end
    end

    class SubTypeExample < TypeExample
      key(:modeling, data_type: Address) { 'alaska' }
    end

    it 'loads default type information from factory' do
      address = SubTypeExample.new.modeling
      expect(address.city).to eql 'Anchorage'
      expect(address.state).to eql 'AK'
      expect(address.zip).to eql '99501'
    end
  end

  class APIAddress < WatirModel
    key(:street1, api: :street_address) { '11800 Domain Blvd' }
    key(:street2, api: :secondary_address) { 'Apt 7' }
    key(:city) { 'Austin' }
    key(:state) { 'TX' }
    key(:zip, api: :postal_code) { '78758' }
  end

  describe '#to_api' do
    it 'converts' do
      required_api = {street_address: '11800 Domain Blvd',
                      secondary_address: 'Apt 7',
                      city: 'Austin',
                      state: 'TX',
                      postal_code: '78758'}.to_json

      api_address = APIAddress.new
      expect(JSON.parse api_address.to_api).to eq JSON.parse required_api
    end

    it 'equates values from any api' do
      api = {street_address: '123 Main',
             secondary_address: 'Apt 7',
             city: 'Austin',
             state: 'TX',
             postal_code: '78758'}.to_json

      addr1 = APIAddress.convert(JSON.parse api)
      addr2 = APIAddress.new(street_address: '123 Main')
      expect(addr1).to eql addr2
    end

    it 'does not store api as key' do
      addr = APIAddress.new(street_address: '123 Main')
      expect(addr.street1).to eq '123 Main'
      expect { addr.street_address }.to raise_exception NoMethodError, /undefined method `street_address'/
    end
  end
end

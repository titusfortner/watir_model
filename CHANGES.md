### 0.5.1 (unreleased)

* deprecate `#to_hash` in favor of more correct `#to_h`
* remove support for key `:aliases` 

### 0.5.0 (2017-12-29)

* prevent `#convert` when default values won't be used

### 0.4.6 (2017-12-29)

* support for `#to_json`
* fix bug in `#convert_type` for Dates and Times

### 0.4.5 (2017-12-29)

* support for `:data_type` to include `Date`
* fix bug in `#data_from_yaml` conditional

### 0.4.4 (2017-12-28)

* fix bug for `#factory_file` dealing with namespaces

### 0.4.3 (2017-12-28)

* support for `#to_hash` to work with nested models

### 0.4.2 (2017-12-27)

* support for `:api` and `#to_api` for outputting JSON with alternate keys

### 0.4.1 (2017-12-26)

* support for key aliases to work with `#convert`

### 0.4.0 (2017-12-24)

* support for `:data_type` parameter to allow conversion and enforcement of key types
* support for data defaults pulled from yaml files
* support for referencing yaml defaults during initialization
* support for key aliases to support comparing same values from different sources

### 0.3.1 (2017-05-19)

* initialize and convert Model using Hash with keys as Strings

### 0.3.0 (2016-12-31)

* move ENV variable override into ConfigModel subclass
* remove support for specifying data types
* implement #convert method

### 0.2.3 (2016-12-22)

* Support for #to_hash

### 0.2.2 (2016-02-15)

* fork from https://github.com/bret/model
* rename model to watir_model
* support for specifying data types
* ENV variables override supplied defaults in Model

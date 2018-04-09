# unobtainium
*Obtain the unobtainable: test code covering multiple platforms*

Unobtainium wraps [Selenium](https://github.com/SeleniumHQ/selenium) and
[Appium](https://github.com/appium/ruby_lib) in a simple driver abstraction
so that test code can more easily cover:

  - Desktop browsers
  - Mobile browsers
  - Mobile apps

The gem also wraps [PhantomJS](http://phantomjs.org/) for headless testing.

Some additional useful functionality for the maintenance of test suites is
also added.

[![Gem Version](https://badge.fury.io/rb/unobtainium.svg)](https://badge.fury.io/rb/unobtainium)
[![Build status](https://travis-ci.org/jfinkhaeuser/unobtainium.svg?branch=master)](https://travis-ci.org/jfinkhaeuser/unobtainium)

# Usage

You can use unobtainium on its own, or use it as part of a
[cucumber](https://cucumber.io/) test suite.

[![Unobtainium Demonstration](http://img.youtube.com/vi/82pYWG5uTnM/0.jpg)](http://www.youtube.com/watch?v=82pYWG5uTnM)

Unobtainium's functionality is in standalone classes, but it's all combined in
the `Unobtainium::World` module.

- The `Runtime` class is a singleton and a `Hash`-like container (but simpler),
  that destroys all of its contents at the end of a script, calling custom
  destructors if required. That allows for clean teardown and avoids everything
  having to implement the Singleton pattern itself.
- The `Driver` class, of course, wraps either of Appium or Selenium drivers:

    ```ruby
    drv = Driver.create(:firefox) # uses Selenium and Firefox
    drv = Driver.create(:android) # uses Appium (browser or device)
    drv = Driver.create(:phantomjs) # use Selenium and PhantomJS

    drv.navigate.to "..." # delegates to Selenium or Appium
    ```

See the documentation on [configuration features](docs/CONFIGURATION.md) for
details on configuration.

## World

The World module combines all of the above by providing a simple entry point
for everything:

- `World.config_file` can be set to the path of a config file to be loaded,
  defaulting to `config/config.yml`.
- `World#config` is a `Config` instance containing the above file's contents.
- `World#driver` returns a Driver, initialized to the settings contained in
  the configuration file.

For a simple usage example of the World module, see the [cuke](./cuke)
subdirectory (used with cucumber).

## Configuration File

The configuration file knows two configuration variables:

- `driver` is expected to be a string, specifying the driver to use as if it
  was passed to `Driver.create` (see above), e.g. "android", "chrome", etc.
- `drivers` (note the trailing s) is a Hash. Under each key you can nest an
  options hash you might otherwise pass to `Driver.create` as the second
  parameter.

See the documentation on [configuration features](docs/CONFIGURATION.md) for
details.

# Development

- [driver development](docs/DRIVERS.md)
- [driver module development](docs/DRIVER_MODULES.md)

# Additional Drivers

- [unobtainium-nokogiri](https://github.com/jfinkhaeuser/unobtainium-nokogiri) is
  a nokogiri-based driver for entirely browserless access to XML and HTML files
  and pages.
- [unobtainium-faraday](https://github.com/jfinkhaeuser/unobtainium-faraday) is
  a faraday-based driver for dealing with RESTish APIs.
- [unobtainium-kramdown](https://github.com/jfinkhaeuser/unobtainium-kramdown) is
  an open-uri-based driver for dealing with Markdown structured text.

# Driver Modules

- [unobtainium-multifind](https://github.com/jfinkhaeuser/unobtainium-multifind)
  is a module providing a `#multifind` function for searching for multiple elements
  at the same time.
- [unobtainium-multiwait](https://github.com/jfinkhaeuser/unobtainium-multiwait)
  based on `multifind`, simplifies waiting for an element to appear.
  
# Integrations

- [unobtainium-cucumber](https://github.com/jfinkhaeuser/unobtainium-cucumber)
  integrates with [cucumber](https://cucumber.io), specifically providing some
  convenient functionality such as automatic screenshot taking on failures.

# Credits
This gem is inspired by [LapisLazuli](https://github.com/spriteCloud/lapis-lazuli),
but vastly less complex, and aims to stay so.

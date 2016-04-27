# Drivers

Drivers are used to access web pages and their content. Since unobtainium is
designed to be primarily a wrapper for Selenium and Appium, the built-in
drivers provide roughly the same API, but there is no strict requirement for
this.

Driver implementations are classes which are required to have a number of
class methods, described below. No requirements on instance methods are made.

# Required Class Methods

The class methods required by unobtainium are as follows:

- `matches?` accepting a String or Symbol label, as passed by the user to
  `Driver#create`. Must return true if the driver implementation matches this
  label, i.e. if this driver implementation is to be used when the user
  specifies this particular label.
  Note that multiple driver implementations can match the same label; the order
  of preference is an implementation detail.
- *[optional]* `resolve_options` accepting the label and options passed to
  `Driver#create` by the user (defaulting to an empty hash). The function must
  return the label and options again, however should normalize the label (see
  below) and supplement any options with default values, etc.
- `ensure_preconditions` accepting the label, and options.
  The method should be used to require any necessary code, and raise errors if
  any other preconditions are not met. See the section on dynamic loading as
  well.
- Finally, `create` accepting the label and options should return an instance
  of a driver class matching both parameters.

# Optional Instance Methods

- `destroy` gets invoked by `Runtime` at exit, if `World#driver` is used to
  create the instance. It can be used to tear down the driver instance cleanly.

# Label Normalization & Configuration Resolution

The built-in drivers respond to many different labels, some of which are
aliases for a *normalized* label. For example, you can specify `:headless`,
which is an alias for `:phantomjs`.

Label normalization should return `:phantomjs` in the example above.

The main goal behind configuration resolution is to provide a way for driver
implementations to translate configuration keys into a form better suited to
the implementation.

For example, the Selenium driver symbolizes keys, because `selenium-webdriver`
requires symbol keys. On the other hand, the [configuration](./CONFIGURATION.md)
system produces String keys only.

But you can use this step also to expand shortcut options. The Appium implentation
allows you to more simply specify some mobile browsers, expanding this into
capabilities required by Appium itself.

# Instance Management

The `World#driver` function registers driver implementations with `Runtime` to
be destroyed at exit.

In order to allow multiple driver instances for e.g. multi-browser testing, but
simultaneously manage instances as described above, the normalized label and
resolved configuration (see above) are used to generate unique keys.

The basic principle is that `World#driver` will be called multiple times in a
test suite. If it is invoked twice with the same parameters, the same instance
should be returned. Parameterless invocations should always return the same
instance, as defined by the configuration. For the pattern inclined reader, this
is an implementation of the [flyweight pattern](https://en.wikipedia.org/wiki/Flyweight_pattern).

Therefore, `resolve_options` should return identical results for two invocations
with *semantically* identical input.

# Dynamic Loading

In order not to create hard dependencies in unobtainium on specific versions of
Selenium, Appium and PhantomJS, these dependencies are only required when
`ensure_preconditions` is being invoked. That lets users decide which versions
to require, and skip libraries they do not use.

Your driver implementation does not have to follow the same pattern, unless you
want to see it merged into unobtainium itself.

# Registering an Implementation

When you have written your class to conform to the above API, all that is left
to do is to register it with unobtainium:

```ruby
class MyDriver
  # implementatin
end # class MyDriver

::Unobtainium::Driver.register_implementation(MyDriver, __FILE__)
```

The second path parameter should always be set to `__FILE__`. It is used to
ensure that if your library is included multiple times, the driver does not
get registered more than once. On the other hand, a different implementation
with the same class name would raise an error when `register_implementation`
is invoked.

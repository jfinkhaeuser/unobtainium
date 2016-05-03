# Driver Modules

Driver modules are a way for extending drivers from other gems. It really is
little more than a glorified version of Ruby's `extend` mechanism, but fairly
convenient.

Suppose you're using any of the built-in drivers with the Selenium API. That
API is fairly verbose when it comes to e.g. handling waiting for an element to
appear. You have to create a `Wait` object and use it to loop over `#find_element`
until a timeout occurs or the latter returns an element.

Much simpler to just have a `#wait` method, no?

```ruby
module WaitModule
  def wait
    # some clever implementation
  end # wait
end # module WaitModule
```

You can just extend the driver that unobtainium returns, of course:

```ruby
drv = driver(:firefox)
drv.extend(WaitModule)
```

However, you will have to do this for every driver you instanciate. So let's
simplify this a bit.

## Module Registration

Instead of having to extend every driver yourself, unobtainium allows you to
register your `WaitModule` with the `Driver` class, and unobtainium takes care
of the extension for you:

```ruby
::Unobtainium::Driver.register_module(WaitModule, __FILE__)
drv = driver(:firefox)
drv.respond_to?(:wait) # => true
```

## Module Matching

The only problem with the above is that our hypothetical `#wait` function relies
heavily on the driver behaving like Selenium, having e.g. a `#find_element`
function. So unobtainium also allows your module implementation to decide whether
it wants to extend a particular driver instance or not.

```ruby
module WaitModule
  class << self
    def matches?(impl)
      # Only extend drivers with (at least) a `#find_element` method.
      impl.respond_to?(:find_element)
    end
  end # class << self

  def wait
    # some clever implementation
  end # wait
end # module WaitModule
```

In fact, `#matches?` is a mandatory method for module implementations.

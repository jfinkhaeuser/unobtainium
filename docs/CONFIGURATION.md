# Configuration

The `Config` class, and it's major user, the `World.config` method make using
complex configuration files in your project easier.

## Basic Configuration Features

### Pathed Access

`Config` is a `Hash` with pathed access. Take a nested structure such as this
as an example:

```yaml
---
foo:
  bar: baz
```

Instead of accessing `config['foo']['bar']`, you can instead use a path such
as `config['foo.bar']`. The major benefit is that if *any* of the path components
does not exist, nil is returned (and the behaviour is equivalent to other access
methods such as `:fetch`, etc.)

Similarly you can use this type of access for writing: `config['baz.quux'] = 42`
will create both the `baz` hash, and it's child the `quux` key.

### Configuration Loading

If you're using `World.config`, configuration is automatically loaded at the
time it's first invoked from the location specified by `World.config_file`, which
defaults to `config/config.yml`.

This is equivalent to invoking `Config.load_config` with that location manually.

### Local Configuration Overrides

For the example file of `config/config.yml`, if a file with the same path and
name, and the name postfix `-local` exists (i.e. `config/config-local.yml`), that
file will also be loaded. It's keys will be recursively added to the keys from the
main configuration file, overwriting only leaves, not entire hashes.

Example:

```yaml
# config/config.yml
---
foo:
  bar: 42
  baz: quux

# config/config-local.yml
---
something: else
foo:
  baz: override

# result
---
something: else
foo:
  bar: 42
  baz: override
```

### Configuration Extension

An additional feature of the `Config` class is that you can extend individual
hashes with values from other hashes.

```yaml
---
root:
  foo: bar
derived:
  baz: quux
  extends: root
```

This results in:

```yaml
---
root:
  foo: bar
derived:
  baz: quux
  foo: bar
  base: root
```

**Notes:**

- This feature means that `extends` and `base` are reserved configuration keys!
- Multiple levels of extension are supported. The `base` keyword will *always
  name the root-most element*, not the immediate ancestor.
- Extending from multiple bases is not supported.
- Extending from nonexistent bases is supported; all that happens is that the
  `base` key is set.

### Environment Variable Override

Given a configuration path, any environment variable with the same name (change
path to upper case letters and replace `.` with `_`, e.g. `foo.bar` becomes
`FOO_BAR`) overrides the values in the configuration file.

If the environment variable is parseable as JSON, then that parsed JSON will
**replace** the original configuration path (i.e. it will not be merged).

## Configuration Values Interpreted by World

- The `driver` path specifies which driver to use; the value shold be a label
  recognized by the `Driver.create` method.
- The `drivers` (plural) path contains options for the different drivers. Each
  driver configuration is nested under a key matching a `Driver.create` label,
  e.g.
  ```yaml
  ---
  drivers:
    firefox:
      some: option
  ```
- The `at_end` path specifies what should be done with the driver when the
  script ends. Possible values are `close` and `quit`, and the default is `quit`.

## Driver Configurations

You can create quite complex driver configurations with the above features, for
very convenient test suite development.

### Select Driver

Typically, you will configure all drivers in use by your test suite in the
`drivers` section of the configuration file. Then, use the `DRIVER` environment
variable to override/set which driver to use:

```bash
$ DRIVER=chrome bundle exec my_tests
```

### Mobile

When running mobile test suites, (Appium)[https://github.com/appium/appium]
requires that you identify the app and/or device you want to run tests against.

That typically means specifying parts of a configuration that is applicable to
any user of the test code, and specifying parts that are applicable only to an
individual.

Use the local configuration override to achieve this split:

```yaml
# config/config.yml
---
drivers:
  android:
    caps:
      platformName: android
      ...

# config/config-local.yml
---
drivers:
  android:
    caps:
      deviceName: deadbeef
```

### Browser/Device Farms

The tests can be run on device/browser farms. Typically you only need to
configure drivers, much like for mobile testing. The following example
is for (TestingBot)[https://testingbot.com]. Note that each farm expects
different configuration keys for selecting browsers and for authentication.

```yaml
# config/config.yml
drivers:
  remote:
    url: "http://hub.testingbot.com:4444/wd/hub"
    desired_capabilities:
      platform: "WIN8"
      browserName: "chrome"
      version: "35"
```

It's good practice to keep authentication data out of the github repository,
so the TestingBot API key and secret should live only in `config/config-local.yml`.

```yaml
# config/config-local.yml
drivers:
  remote:
    desired_capabilities:
      api_key: "1ceb00da"
      api_secret: "cefaedfe"
```

Then run:

```bash
$ DRIVER=remote bundle exec cucumber
```

### Complex Configurations

With device/browser farms in particular, you typically do not want to use a
single `remote` configuration, but rather one for each remote browser or
device you want to use in testing. This is possible with the configuration
extension mechanism:

```yaml
# config/config.yml
---
drivers:
  remote:
    url: "http://hub.testingbot.com:4444/wd/hub"
  remote_win8_chrome:
    extends: remote
    desired_capabilities:
      platform: "WIN8"
      browserName: "chrome"
      version: "35"

# config/config-local.yml
---
drivers:
  remote:
    desired_capabilities:
      api_key: "1ceb00da"
      api_secret: "cefaedfe"
```

As noted in the section on the extension mechanism, the `extends` keyword
gets replaced with a `base` keyword that contains the *root-most* element.
In this case, `drivers.remote_win8_chrome.base` becomes `remote`, but even if
you had a `drivers.remote_win8_chrome38` section that overrides the desired
chrome version, `drivers.remote_win8_chrome38.base` would still become
`remote`.

The `World.config` method makes use of this, and replaces the driver label
you specified with the `driver` path or `DRIVER` environment variable with
this `base` value. The effect is that you can give your driver configuration
sections any name, as long as they're eventually extended by a section with
a key that `Driver.create` recognizes.

Thus, the following starts Chrome 35 on Windows 8 on TestingBot:

```bash
$ DRIVER=remote_win8_chrome bundle exec my_test
```

# Kwork

Kwork is a library for building business transactions in Ruby designed to:

- Be written in a declarative and chainable way.
- Decouple individual operations from business transactions.
- Injecting operations for testing purposes or reusability.
- Be used with different result types (e.g. `Kwork::Result`,
  `Dry::Monads::Result`, `Dry::Monads::Maybe`...).
- Provide transactional safety for different database adapters (e.g.,
  `ROM`, `ActiveRecord`...).
- Provide profiling information for each step of the transaction.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kwork', github: 'nebulab/kwork'
```

And then execute:

    $ bundle install

## Usage

```ruby
require "kwork"

class AddUser
  include Kwork

  def call
    user = step create_user
    step build_email(user)
  end

  private

  def create_user
    success(
      Struct.new(:id, :name).new(1, "Alice")
    )
  end

  def build_email(user)
    success(
      "Hello #{user.name}!"
    )
  end
end

case AddUser.new.()
in Kwork::Result::Success[message]
  puts message
in Kwork::Result::Failure[error]
  puts error
end # => "Hello Alice!"
```

The key concept to understand is how successful operations are chained. The
`#create_user` method above returns a user instance wrapped within a
`Kwork::Result::Success` type. However, when the operation is run within the
block, the result is unwrapped and the user instance is passed as an argument to
the `#build_email` method.

When we execute the transaction, we pattern match on the result type and
extract the final result of the whole transaction.

Imagine that the `#create_user` method failed instead:

```ruby
require "kwork"

class AddUser
  include Kwork

  def call
    user = step create_user
    step build_email(user)
  end

  private

  def create_user
    failure(
      "User already exists!"
    )
  end

  def build_email(user)
    success(
      "Hello #{user.name}!"
    )
  end
end

case AddUser.new.()
in Kwork::Result::Success[message]
  puts message
in Kwork::Result::Failure[error]
  puts error
end # => "User already exists!"
```

Notice how the transaction was short-circuited and the `#build_email` method
was never called.

### Result adapters

Kwork transactions can work with any result type as long as an adapter is available. By default, it'll use a [`Kwork::Result`](lib/kwork/result.rb), which already provides a lot of features to access and transform the wrapped values. However, others adapters are shipped OOTB and you can also create your own.

#### dry-monad's result type

You need to add [dry-monads](https://dry-rb.org/gems/dry-monads/1.6/) to your `Gemfile` to use it:

```ruby
require "kwork"

class AddUser
  include Kwork[
    adapter: :result
  ]

  def call
    user = step create_user
    step build_email(user)
  end

  private

  def create_user
    success(
      Struct.new(:id, :name).new(1, "Alice")
    )
  end

  def build_email(user)
    success(
      "Hello #{user.name}!"
    )
  end
end

result = AddUser.new.()
puts result.class #=> Dry::Monads::Result::Success
puts result.value! #=> "Hello Alice!"
```

#### dry-monad's maybe type

You need to add [dry-monads](https://dry-rb.org/gems/dry-monads/1.6/) to your `Gemfile` to use it:

```ruby
require "kwork"

class AddUser
  include Kwork[
    adapter: :maybe
  ]

  def call
    user = step create_user
    step build_email(user)
  end

  private

  def create_user
    failure(
      "User already exists!"
    )
  end

  def build_email(user)
    success(
      "Hello #{user.name}!"
    )
  end
end

result = AddUser.new.()
puts result.class #=> Dry::Monads::Maybe::None
```

#### Custom adapters

A custom adapter can be very easily created. You only need to provide an interface responding to both `#from_kwork_result` and `#to_kwork_result`. Take a look at how [the ones for dry-monads](lib/kwork/adapters/dry_monads/) are implemented for inspiration.

```ruby
module MyAdapter
  # ...
end

class AddUser
  include Kwork[
    adapter: MyAdapter
  ]
  # ...
end
```

### Extensions

More often than not, a business transaction needs to be wrapped within a database transaction. To support this use case, Kwork gives you the ability to extend the transaction callback so you can wrap it with your own code. A couple of extensions are shipped by default, but you can easily build your own.

#### ROM

You need to add [rom](https://rom-rb.org/) to your `Gemfile` to use it. When this extension is used, the Kwork transaction is wrapped within a database transaction, which is rolled back in the case of returning a failure.

```ruby
require "kwork"
require "kwork/extensions/rom"

rom = # ROM container

class AddUser
  include Kwork[
    extension: Kwork::Extensions::ROM[rom, :default] # :default is the name of the gateway
  ]
  # ...
end
```

#### ActiveRecord

On a Rails application, you can use the ActiveRecord extension. The raw Kwork transaction will be wrapped within a database transaction, and it'll be rolled back in case of returning a failure.

```ruby
require "kwork"
require "kwork/extensions/active_record"

class AddUser
  include Kwork[
    extension: Kwork::Extensions::ActiveRecord
  ]
  # ...
end
```

#### Custom extensions

Custom extensions are just anything responding to `#call` accepting the Kwork transaction callback. You only need to ensure that you respond the result of executing that callback. Take into account that the callback will return an instance of `Kwork::Result`, regardless of the adapter in use. That ensures fully operability with any result type.

```ruby
require "kwork"

MyExtension = lambda do |callback|
 callback.().tap do |result|
   do_something if result.success?
 end
end

class AddUser
  include Kwork[
    extension: MyExtension
  ]
  # ...
end
```

### Using Transactable

Through the `#pipe` method, you can use [transactable operations](https://alchemists.io/projects/transactable).

### Decoupling operations

It's a good practice to decouple operations from the transaction test for
better reusability and testing. That plays very well with dependency injection
of operations in the [dry-rb](https://dry-rb.org/) ecosystem:

```ruby
require "kwork"

class AddUser
  include Import["operations.create_user", "operations.build_email"]
  
  def call
    user = step create_user
    step build_email(user)
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kwork. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/kwork/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Kwork project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/kwork/blob/master/CODE_OF_CONDUCT.md).

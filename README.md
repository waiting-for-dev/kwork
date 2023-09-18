# Kwork

Kwork is a library for building business transactions in Ruby designed to:

- Be written in a declarative and chainable way.
- Decouple individual operations from business transactions.
- Injecting operations for testing purposes or reusability.
- Be used with different result types (e.g. `Kwork::Result`,
  `Dry::Monads::Result`, `Dry::Monads::Maybe`...).
- Provide transactional safety for different database adapters (e.g.,
  `ROM`, `ActiveRecord`...).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kwork', github: 'waiting-for-dev/kwork'
```

And then execute:

    $ bundle install

## Usage

Using [`dry-auto_inject`](https://dry-rb.org/gems/dry-auto_inject/1.0/) & [`dry-monads`](https://dry-rb.org/gems/dry-monads/1.6/).

```ruby
require "kwork"

class CheckOutOrder
  include Kwork[adapter: :result]
  include Deps[:update_line_items, :update_order, :calculate_best_prices, :enqueue_order_completed_email]
  
  def call(order_id, attrs)
    attrs = step validate(attrs)
    line_items = step update_line_items.(order_id, attrs[:line_items])
    order = step update_order.(order_id, attrs.except(:line_items))
    
    step calculate_best_prices.(order:, line_items:)
    step enqueue_order_completed_email.(order)
    
    success(order)
  end
  
  private
  
  def validate(attrs)
    # ...
  end
end

include Dry::Monads[:result]

case CheckoutOrder.new
in Success[message]
  puts message
in Failure[error]
  puts error
end
```

### Advanced usage

You can leverage [transactable](https://alchemists.io/projects/transactable) to elegantly use the Railway pattern for data transformation or the whole transactional workflow. For now, it only works with `Dry::Monads::Result` adapter:

```ruby
class CreateUser
  include Kwork[adapter: :result]
  include Deps["user_repo", "validate_user"]
  include Dry::Monads[:result]
  
  DEFAULT_USER_ATTRS = {
    country: :us,
    currency: :usd
  }

  def call(user_attrs)
    user = pipe user_attrs,
      merge(DEFAULT_USER_ATTRS),
      method(:validate_user)

    step create_user(user)
  end

  private

  def create_user(user)
    Success(user_repo.create(user))
  end
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kwork. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/kwork/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Kwork project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/kwork/blob/master/CODE_OF_CONDUCT.md).

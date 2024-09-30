# Action Cable Next

This gem provides the functionality of the _server adapterization_ PR: [rails/rails#50979](https://github.com/rails/rails/pull/50979).

See the PR description for more information on the purpose of this refactoring.

## Usage

Add this line to your application's Gemfile **before Rails or Action Cable**:

```ruby
gem "actioncable-next"

gem "rails", "~> 7.0"
```

Then, you can use Action Cable as before. Under the hood, the new implementation would be used.

### RSpec support

This gem also includes the corresponding patch for RSpec Rails (see [PR](https://github.com/palkan/rspec-rails/pull/1)). You MUST activate it explicitly
by adding the following line to your `spec/rails_helper.rb`:

```ruby
# after rspec-rails is loaded
require "rspec/rails"
require "action_cable/next/rspec"
```

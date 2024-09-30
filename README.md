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

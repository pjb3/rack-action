# Rack::Action

Rack action is a small, simple framework for generating Rack responses.  A basic rack action looks like this:

    require 'rack/action'

    class MyAction < Rack::Action
      def respond
        "Hello, World!"
      end
    end

    run MyAction

See the docs for Rack::Action for more details

## Installation

Add this line to your application's Gemfile:

    gem 'rack-action'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-action

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# Rack::Action

Rack::Action is a small, simple framework for generating [Rack][rack] responses.

## Installation

Add this line to your application's Gemfile:

    gem 'rack-action'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-action

## Usage

Rack::Action provides functionality to generate a Rack response. To use Rack::Action, you should subclass Rack::Action and provide your own implementation of `respond`. The simplest Rack action is
one that just returns a string from respond:

```ruby
require 'rack/action'

class MyAction < Rack::Action
  def respond
    "Hello, World!"
  end
end

run MyAction
```

The class itself is a rack app, so the previous code example is a valid
rackup file. Rack::Action is meant to be used with one action per
page/endpoint in your application, so it is typically used in conjuction
with something like [Rack::Router][rack-router], which would look something like this:

```ruby
require 'rack/action'
require 'rack/router'

class FooAction < Rack::Action
  def respond
    "foo"
  end
end

class BarAction < Rack::Action
  def respond
    "bar"
  end
end

router = Rack::Router.new do
  get "/foo" => FooAction
  get "/bar" => BarAction
end

run router
```

Rack::Action makes an instance of [Rack::Request][rack-req] and [Rack::Response][rack-res] available
which can be used to set headers, cookies, etc.

```ruby
class ArticleAction < Rack::Action
  def respond
    article = Article.find(params["id"])
    response['Content-Type'] = "application/json"
    article.to_json
  end
end
```

Because responding with JSON is so common, Rack::Action will automatically convert the response to JSON unless the response is a String or an Array. Therefore, the following code snippet provides the same result as the previous:

```ruby
class ArticleAction < Rack::Action
  def respond
    Article.find(params["id"])
  end
end
```

You can use before filters to do things before respond is called:

```ruby
class AccountAction < Rack::Action
  before_filter :load_current_user

  def load_current_user
    @current_user = User.find(params["id"])
  end

  def respond
    "Welcome Back, #{@current_user.name}"
  end
end
```

and you can of course share functionality across actions with inheritance:

```ruby
class ApplicationAction < Rack::Action
  before_filter :login_required

  def login_required
    redirect_to "/login" unless logged_in?
  end
end

class PublicAction < ApplicationAction
  skip_before_filter :login_required

  def respond
    "Hello"
  end
end

class PrivateAction < ApplicationAction
  def respond
    "It's A Secret To Everybody."
  end
end
```

Before filters will execute in the order they are defined. If a before
filter writes to the response, subsequent filters will not be executed
and the respond method will not be executed. As long as no before filters
write to the response, subsequent filters and the respond
method will be called.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[rack]: http://rack.github.com/
[rack-req]: http://rubydoc.info/gems/rack/Rack/Request
[rack-res]: http://rubydoc.info/gems/rack/Rack/Response
[rack-router]: https://github.com/pjb3/rack-router

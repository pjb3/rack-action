require 'rack_action'
require 'rack_test'

class Rack::ActionTest < RackTest

  def test_default_respond
    app = Class.new(Rack::Action)

    response = get app, "/"
    assert_equal 200, response.status
    assert_equal Rack::Action::DEFAULT_RESPONSE.length, response.length
    assert_equal 'text/html', response["Content-Type"]
    assert_equal [Rack::Action::DEFAULT_RESPONSE], response.body
  end

  def test_custom_respond
    app = Class.new(Rack::Action) do
      def respond
        "bananas"
      end
    end

    response = get app, "/"

    assert_equal 200, response.status
    assert_equal 7, response.length
    assert_equal 'text/html', response["Content-Type"]
    assert_equal ['bananas'], response.body
  end

  def test_json_respond
    app = Class.new(Rack::Action) do
      def respond
        json :hello => "world"
      end
    end
    expected = %{{"hello":"world"}}

    response = get app, "/"

    assert_equal 200, response.status
    assert_equal expected.length, response.length
    assert_equal 'application/json', response["Content-Type"]
    assert_equal [expected], response.body
  end

  def test_pretty_json_respond
    app = Class.new(Rack::Action) do
      def respond
        pretty_json :hello => "world"
      end
    end
    expected = %{{
  "hello": "world"
}}

    response = get app, "/"

    assert_equal 200, response.status
    assert_equal expected.length.to_s, response["Content-Length"]
    assert_equal 'application/json', response["Content-Type"]
    assert_equal [expected], response.body
  end

  def test_before_filter_set_instance_variable
    app = Class.new(Rack::Action) do
      def respond
        @message
      end

      def set_message
        @message = "Hello, World!"
      end
    end
    app.before_filter :set_message

    response = get app, "/"

    assert_equal 200, response.status
    assert_equal ["Hello, World!"], response.body
  end

  def test_before_filter_set_response
    app = Class.new(Rack::Action) do
      def respond
        fail "respond should not be called if a before filter sets the response"
      end

      def set_response
        response.write "test"
      end
    end
    app.before_filter :set_response

    response = get app, "/"

    assert_equal 200, response.status
    assert_equal ["test"], response.body
  end

  def test_redirect
    app = Class.new(Rack::Action) do
      def respond
        fail "respond should not be called if a before filter sets the response"
      end

      def login_required
        redirect_to "/login"
      end
    end
    app.before_filter :login_required

    response = get app, "/"

    assert_equal 302, response.status
    assert_equal "http://example.com/login", response["Location"]
  end

  def test_redirect_non_default_port
    app = Class.new(Rack::Action) do
      def respond
        fail "respond should not be called if a before filter sets the response"
      end

      def login_required
        redirect_to "/login"
      end
    end
    app.before_filter :login_required

    response = get app, "/", "SERVER_PORT" => "3000"

    assert_equal 302, response.status
    assert_equal "http://example.com:3000/login", response["Location"]
  end

  def test_redirect_non_default_port_option
    app = Class.new(Rack::Action) do
      def respond
        fail "respond should not be called if a before filter sets the response"
      end

      def login_required
        redirect_to "/login", :port => 3000
      end
    end
    app.before_filter :login_required

    response = get app, "/"

    assert_equal 302, response.status
    assert_equal "http://example.com:3000/login", response["Location"]
  end

  def test_secure_redirect
    app = Class.new(Rack::Action) do
      def respond
        fail "respond should not be called if a before filter sets the response"
      end

      def login_required
        redirect_to "/login"
      end
    end
    app.before_filter :login_required

    response = get app, "/", "SERVER_PORT" => "443", "rack.url_scheme" => "https"

    assert_equal 302, response.status
    assert_equal "https://example.com/login", response["Location"]
  end

  def test_redirect_absolute_url
    app = Class.new(Rack::Action) do
      def respond
        fail "respond should not be called if a before filter sets the response"
      end

      def login_required
        redirect_to "http://test.com/login"
      end
    end
    app.before_filter :login_required

    response = get app, "/"

    assert_equal 302, response.status
    assert_equal "http://test.com/login", response["Location"]
  end

end

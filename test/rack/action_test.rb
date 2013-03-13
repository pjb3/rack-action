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

  def test_documentation
    charge = Class.new do

    end
    app = Class.new(Rack::Action) do

      documentation = {
        :name => "foo",
        :description => "bar",
        :params => [
          {
            :name => :amount,
            :type => :integer,
            :required => true
          }
        ]
      }

      documentation do
        name "Creating a new charge (charging a credit card)"
        description "To charge a credit card, you create a new charge object. If your API key is in test mode, the supplied card won't actually be charged, though everything else will occur as if in live mode. (Stripe assumes that the charge would have completed successfully)"

        params do


          integer :amount,
            :required => true,
            :doc => "A positive integer in cents representing how much to charge the card. The minimum amount is 50 cents."

          string :currency,
            :required => true,
            :doc => "3-letter ISO code for currency."

          integer :customer,
            :note => "either customer or card is required, but not both",
            :doc => " The ID of an existing customer that will be charged in this request."

          object :card,
            :note => "either card or customer is required, but not both"
            :doc => "A card to be charged. The card can either be a token, like the ones returned by Stripe.js, or a dictionary containing a user's credit card details, with the options described below. Although not all information is required, the extra info helps prevent fraud." do
            string :number, :required => true, :doc => "The card number, as a string without any separators."
            string :exp_month, :required => true, :doc => "Two digit number representing the card's expiration month."
            string :exp_year, :required => true, :doc => "Two or four digit number representing the card's expiration year."
            string :cvc, :note => "highly recommended", :doc => "Card security code"
            string :name, :doc => "Cardholder's full name."
            string :address_line1
            string :address_line2
            string :address_city
            string :address_zip
            string :address_state
            string :address_country
          end

          string :description,
            :note => "default is null",
            :doc => "An arbitrary string which you can attach to a charge object. It is displayed when in the web interface alongside the charge. It's often a good idea to use an email address as a description for tracking later."

          integer :application_fee,
            :doc => %{A fee in cents that will be applied to the charge and transferred to the application owner's Stripe account. The request must be made with an OAuth key in order to take an application fee. For more information, see the application fees <a href="https://stripe.com/docs/connect/collecting-fees">documentation</a>.}

        end

        response 200, "The charge succeeded" do
          object :charge, :type => Charge
        end
      end
    end
  end

end

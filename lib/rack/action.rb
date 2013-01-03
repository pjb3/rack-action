require 'time'
require 'json'
require 'rack'
require 'rack/filters'

module Rack
  # Rack::Action provides functionality to generate a Rack response.
  # To use Rack::Action, you should subclass Rack::Action and provide
  # your own implementation of {#respond}.  The simplest Rack action is
  # one that just returns a string from respond:
  #
  #     require 'rack/action'
  #
  #     class MyAction < Rack::Action
  #       def respond
  #         "Hello, World!"
  #       end
  #     end
  #
  #     run MyAction
  #
  # The class itself is a rack app, so the previous code example is a valid
  # rackup file. Rack::Action is meant to be used with one action per
  # page/endpoint in your application, so it is typically used in conjuction
  # with something like Rack::Router, which would look something like this:
  #
  #     require 'rack/action'
  #     require 'rack/router'
  #
  #     class FooAction < Rack::Action
  #       def respond
  #         "foo"
  #       end
  #     end
  #
  #     class BarAction < Rack::Action
  #       def respond
  #         "bar"
  #       end
  #     end
  #
  #     router = Rack::Router.new do
  #       get "/foo" => FooAction
  #       get "/bar" => BarAction
  #     end
  #
  #     run router
  #
  # Rack::Action makes an instance of Rack::Request and Rack::Response available
  # which can be used to set headers, cookies, etc.
  #
  #     class ArticleAction < Rack::Action
  #       def respond
  #         article = Article.find(params["id"])
  #         response['Content-Type'] = "text/xml"
  #         article.to_xml
  #       end
  #     end
  #
  # You can use before filters to do things before respond is called:
  #
  #     class AccountAction < Rack::Action
  #       before_filter :load_current_user
  #
  #       def load_current_user
  #         @current_user = User.find(params["id"])
  #       end
  #
  #       def respond
  #         "Welcome Back, #{@current_user.name}"
  #       end
  #     end
  #
  # and you can of course share functionality across actions with inheritance:
  #
  #     class ApplicationAction < Rack::Action
  #       before_filter :login_required
  #
  #       def login_required
  #         redirect_to "/login" unless logged_in?
  #       end
  #     end
  #
  #     class PublicAction < ApplicationAction
  #       skip_before_filter :login_required
  #
  #       def respond
  #         "Hello"
  #       end
  #     end
  #
  #     class PrivateAction < ApplicationAction
  #       def respond
  #         "It's A Secret To Everybody."
  #       end
  #     end
  #
  # Before filters will execute in the order they are defined.  If a before
  # filter writes to the response, subsequent filters will not be executed
  # and the respond method will not be executed.  As long as no before filters
  # write to the response, execution of subsequent filters and the respond
  # method will be called.
  class Action
    extend Filters

    # @private
    RACK_ROUTE_PARAMS = 'route.route_params'.freeze
    # @private
    CONTENT_TYPE = 'Content-Type'.freeze
    # @private
    APPLICATION_JSON = 'application/json'.freeze
    # @private
    LOCATION = 'Location'.freeze
    # @private
    DEFAULT_RESPONSE = "Default Rack::Action Response"

    # This implements the Rack interface
    #
    # @param [Hash] env The Rack environment
    # @return [Array<Numeric, Hash, #each>] A Rack response
    def self.call(env)
      new(env).call
    end

    attr_accessor :env, :request, :response, :params

    def initialize(env)
      @env = env
    end

    def request
      @request ||= Rack::Request.new(env)
    end

    def response
      @response ||= Rack::Response.new
    end

    def params
      @params ||= request.params.merge(env[RACK_ROUTE_PARAMS] || {})
    end

    # This is the main method responsible for generating a Rack response.
    # You typically won't need to override this method or call it directly.
    # First this will run the before filters for this action.
    # If none of the before filters generate a response, this will call
    # {#respond} to generate a response.
    # All after filters for this action are called once the response
    # is genenated.  Finally the response is returned.
    #
    # @return [Array<Numeric, Hash, #each>] A Rack response
    def call
      run_before_filters
      run_respond
      run_after_filters
      finish_response
    end

    # This is the main method that you should override in your action.
    # You can either write to the response during this method, or simply
    # return a string, which will be written to the response if the
    # response is still empty after this is called.
    #
    # @return [String] The Rack response or a String
    def respond
      DEFAULT_RESPONSE
    end

    # This is a convenience method that sets the Content-Type headers
    # and writes the JSON String to the response.
    #
    # @param [Hash] data The data
    # @return [String] The JSON
    def json(data)
      response[CONTENT_TYPE] = APPLICATION_JSON
      response.write JSON.generate(data)
    end

    # This is a convenience method that sets the Content-Type headers
    # and writes the pretty-formatted JSON String to the response.
    #
    # @param [Hash] data The data
    # @return [String] The JSON
    def pretty_json(data)
      response[CONTENT_TYPE] = APPLICATION_JSON
      response.write JSON.pretty_generate(data)
    end

    # This is a convenience method that forms an absolute URL based on the
    # url parameter, which can be a relative or absolute URL, and then
    # sets the headers and the body appropriately to do a 302 redirect.
    #
    # @see #absolute_url
    # @return [String] The absolute url
    def redirect_to(url, options={})
      full_url = absolute_url(url, options)
      response[LOCATION] = full_url
      response.status = 302
      response.write ''
      full_url
    end

    # Generate an absolute url from the url.  If the url is already
    # an absolute url, this will return it unchanged.
    #
    # @param [String] url The URL
    # @param [Hash] options The options to use to generate the absolute URL
    # @option options [true, false] :https If https should be used,
    #   uses rack.url_scheme from the Rack env to determine the default
    # @option options [String] :host The host to use,
    #   uses SERVER_NAME form the Rack env for the default
    # @option options [String, Numeric] :port The port to use,
    #   users SERVER_PORT from the Rack env for the default
    # @return [String] The absolute url
    def absolute_url(url, options={})
      URL.new(env, url, options).to_absolute
    end

    protected
    def run_before_filters
      self.class.before_filters.each do |filter|
        send(filter)
        return unless response.empty?
      end
    end

    def run_respond
      return if !response.empty?
      body = respond
      if response.empty?
        response.write body
      else
        body
      end
    end

    def run_after_filters
      self.class.after_filters.each do |filter|
        send(filter)
      end
    end

    def finish_response
      response.finish
    end

    # @private
    class URL
      HTTPS = 'https'.freeze
      HTTP_PREFIX = 'http://'.freeze
      HTTPS_PREFIX = 'https://'.freeze
      ABSOLUTE_URL_REGEX = /\Ahttps?:\/\//
      RACK_URL_SCHEME = 'rack.url_scheme'
      SERVER_NAME = 'SERVER_NAME'.freeze
      SERVER_PORT = 'SERVER_PORT'.freeze
      DEFAULT_HTTP_PORT = 80
      DEFAULT_HTTPS_PORT = 443

      attr_accessor :env, :url, :https, :host, :port

      def initialize(env, url, options={})
        @env = env
        @url = url.to_s
        @options = options || {}
        @https = options.fetch(:https, env[RACK_URL_SCHEME] == HTTPS)
        @host = options.fetch(:host, env[SERVER_NAME])
        @port = Integer(options.fetch(:port, env[SERVER_PORT]))
      end

      def to_absolute
        if url =~ ABSOLUTE_URL_REGEX
          url
        else
          absolute_url = [prefix]
          absolute_url << (port == default_port ? host : "#{host}:#{port}")
          absolute_url << url
          ::File.join(*absolute_url)
        end
      end

      def prefix
        https ? HTTPS_PREFIX : HTTP_PREFIX
      end

      def default_port
        https ? DEFAULT_HTTPS_PORT : DEFAULT_HTTP_PORT
      end
    end

  end
end

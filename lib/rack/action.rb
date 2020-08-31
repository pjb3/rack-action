require "time"
require "json"
require "rack"
require_relative "filters"

class Rack::Action
  VERSION = "0.6.0".freeze

  extend Rack::Filters

  # @private
  RACK_ROUTE_PARAMS = "rack.route_params".freeze
  # @private
  CONTENT_TYPE = "Content-Type".freeze
  # @private
  HTTP_ACCEPT = "HTTP_ACCEPT".freeze
  # @private
  TEXT_HTML = "text/html".freeze
  # @private
  APPLICATION_JSON = "application/json".freeze
  # @private
  LOCATION = "Location".freeze
  # @private
  DEFAULT_RESPONSE = "Default Rack::Action Response".freeze
  # @private
  RACK_INPUT = "rack.input".freeze

  # This implements the Rack interface
  #
  # @param [Hash] env The Rack environment
  # @return [Array<Numeric, Hash, #each>] A Rack response
  def self.call(env)
    new(env).call
  end

  attr_accessor :env
  attr_writer :request, :response, :params

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
    @params ||= begin
      p = request.params.merge(env[RACK_ROUTE_PARAMS] || {})
      if request.content_type.to_s.include?(APPLICATION_JSON)
        body = env[RACK_INPUT].read
        env[RACK_INPUT].rewind
        p.merge!(self.class.json_serializer.load(body)) if body.present?
      end
      p.respond_to?(:with_indifferent_access) ? p.with_indifferent_access : p
    end
  end

  def format
    if params[:format]
      params[:format]
    elsif env[HTTP_ACCEPT] == APPLICATION_JSON
      "json"
    else
      "html"
    end
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
    log_call
    set_default_headers
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
  # @param [Hash] options The options
  # @option options [Fixnum] :status The response status code
  # @return [String] The JSON
  def json(data={}, options={})
    response[CONTENT_TYPE] = APPLICATION_JSON
    response.status = options[:status] if options.has_key?(:status)
    response.write self.class.json_serializer.dump(data)
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
    respond_with 302
    full_url
  end

  # Convenience method to return a 404
  def not_found
    respond_with 404
  end

  # Convenience method to return a 403
  def forbidden
    respond_with 403
  end

  # This is a convenience method to set the response code and
  # set the response so that it stops respond process.
  #
  # @param [Fixnum] status_code The HTTP status code to use in the response
  def respond_with(status_code)
    response.status = status_code
    response.write ""
    nil
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

  def log_call
    logger&.debug do
      "#{self.class} #{request.env["REQUEST_METHOD"]} format: #{format.inspect}, params: #{params.inspect}"
    end
  end

  def set_default_headers
    response[CONTENT_TYPE] = TEXT_HTML
  end

  def run_before_filters
    self.class.before_filters.each do |filter|
      logger&.debug "Running #{filter} before filter"
      send(filter)
      unless response.empty?
        logger&.debug "#{filter} responded, halting filter chain"
        return
      end
    end
  end

  def run_respond
    return unless response.empty?

    body = respond

    if response.empty?
      if body.is_a?(String) || body.is_a?(Array)
        response.write body
      else
        json body
      end
    else
      body
    end
  end

  def run_after_filters
    self.class.after_filters.each do |filter|
      logger&.debug "Running #{filter} after filter"
      send(filter)
    end
  end

  def finish_response
    response.finish
  end

  def logger
    self.class.logger
  end

  class << self
    attr_writer :logger
    attr_writer :json_serializer

    def logger
      if defined? @logger
        @logger
      else
        @logger = superclass.logger if superclass.respond_to?(:logger)
      end
    end

    def json_serializer
      if defined? @json_serializer
        @json_serializer
      else
        @json_serializer =
          if superclass.respond_to?(:json_serializer)
            superclass.json_serializer
          else
            JSON
          end
      end
    end
  end

  # @private
  class URL
    HTTPS = "https".freeze
    HTTP_PREFIX = "http://".freeze
    HTTPS_PREFIX = "https://".freeze
    ABSOLUTE_URL_REGEX = %r{\Ahttps?://}.freeze
    RACK_URL_SCHEME = "rack.url_scheme".freeze
    SERVER_NAME = "SERVER_NAME".freeze
    SERVER_PORT = "SERVER_PORT".freeze
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

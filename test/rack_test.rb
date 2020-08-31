require "test/unit"
require "stringio"
require "logger"
require "fileutils"

if ENV["RACK_ACTION_TEST_LOGGER"].to_s.downcase == "stdout"
  Rack::Action.logger = Logger.new(STDOUT)
elsif ENV["RACK_ACTION_TEST_LOGGER"]
  log_file = File.expand_path(ENV["RACK_ACTION_TEST_LOGGER"])
  FileUtils.mkdir_p File.dirname(log_file)
  Rack::Action.logger = Logger.new(log_file)
end

class RackTest < Test::Unit::TestCase
  DEFAULT_HOST = "example.com".freeze
  DEFAULT_PORT = 80

  DEFAULT_ENV = {
    "SCRIPT_NAME" => "",
    "QUERY_STRING" => "",
    "SERVER_NAME" => DEFAULT_HOST,
    "SERVER_PORT" => DEFAULT_PORT.to_s,
    "HTTP_HOST" => DEFAULT_HOST,
    "HTTP_ACCEPT" => "*/*",
    "rack.input" => StringIO.new,
    "rack.url_scheme" => "http"
  }.freeze

  def default_env
    DEFAULT_ENV
  end

  def request(app, method, path, env={})
    resp = app.call(DEFAULT_ENV.merge({
      "REQUEST_METHOD" => method.to_s.upcase,
      "PATH_INFO" => path
    }.merge(env)
                                     )
                   )
    resp.is_a?(Rack::Response) ? resp : Rack::Response.new(resp[2], resp[0], resp[1])
  end

  def get(app, path, env={})
    request(app, :get, path, env)
  end
end

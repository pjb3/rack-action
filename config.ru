require 'rack-action'

app = Class.new(Rack::Action) do
  def respond
    pretty_json env.except("rack.input", "rack.errors")
  end
end

run app

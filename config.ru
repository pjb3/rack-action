require_relative "lib/rack/action"

app = Class.new(Rack::Action) do
  def respond
    json env.reject{|k, _| k == "rack.input" || k == "rack.errors" }
  end
end

run app

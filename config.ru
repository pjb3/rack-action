require_relative "lib/rack/action"

app = Class.new(Rack::Action) do
  def respond
    env.reject{|k, _| ["rack.input", "rack.errors"].include?(k) }
  end
end

run app

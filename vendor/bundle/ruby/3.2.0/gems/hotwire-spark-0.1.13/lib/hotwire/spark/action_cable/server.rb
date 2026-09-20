class Hotwire::Spark::ActionCable::Server < ActionCable::Server::Base
  def initialize
    config = ::ActionCable::Server::Base.config.dup
    config.connection_class = -> { ::ActionCable::Connection::Base }
    super(config: config)
  end
end

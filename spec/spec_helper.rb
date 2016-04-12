require "bundler/setup"
Bundler.require(:default, :test)

require 'celluloid/io'

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}

RSpec.configure do |config|

  config.order = 'random'
end

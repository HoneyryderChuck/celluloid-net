require 'celluloid/io'
require 'net/ftp'

module Celluloid::BufferedExtensions
  def initialize(io)
    if Celluloid::IO.evented?
      super(Celluloid::IO::Socket.try_convert(io))
    else
      super
    end
  end
end

Net::FTP::BufferedSocket.send :prepend, Celluloid::BufferedExtensions  


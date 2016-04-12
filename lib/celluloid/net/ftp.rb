require 'timeout/extensions'
require 'celluloid/io'
require 'celluloid/net/timeout'
require 'net/ftp'

module Celluloid::FTPExtensions
  module BufferedExtensions
    def initialize(io)
      if Celluloid::IO.evented?
        super(Celluloid::IO::Socket.try_convert(io))
      else
        super
      end
    end
  end
end

Net::FTP::BufferedSocket.send :prepend, Celluloid::FTPExtensions::BufferedExtensions  


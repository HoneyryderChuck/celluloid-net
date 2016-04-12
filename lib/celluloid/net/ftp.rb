require 'timeout/extensions'
require 'celluloid/io'
require 'net/ftp'

module Celluloid::FTPExtensions
  module BufferedIOExtension
    def initialize(io)
      if Celluloid::IO.evented?
        super(Celluloid::IO::Socket.try_convert(io))
      else
        super
      end
    end
  end
end

Net::FTP::BufferedSocket.send :prepend, Celluloid::FTP::BufferedExtensions  


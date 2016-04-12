require 'timeout/extensions'
require 'celluloid/io'
require 'net/smtp'

module Celluloid
  module SMTPExtensions
    def tcp_socket(*args)
      if Celluloid::IO.evented?
        Celluloid::IO::TCPSocket.open(*args)
      else
        super
      end
    end

    def ssl_socket(*args)
       if Celluloid::IO.evented?
        Celluloid::IO::SSLSocket.open(*args)
      else
        super
      end
    end
  end
end

Net::SMTP.send :prepend, Celluloid::SMTPExtensions


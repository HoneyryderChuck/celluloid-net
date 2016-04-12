require 'spec_helper'
require 'celluloid/net/smtp'

RSpec.describe Net::SMTP do

  it "connects using a celluloid io socket" do
    within_io_actor do
      smtp = Net::SMTP.new 'localhost', 25
    
      expect(smtp.tcp_socket('localhost', 25)).to be_a(Celluloid::IO::TCPSocket)
    end
  end

end

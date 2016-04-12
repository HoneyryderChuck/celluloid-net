require "spec_helper"
require "celluloid/net/ftp"
require "ostruct"
require "stringio"

RSpec.describe Net::FTP do
  SERVER_ADDR = "127.0.0.1"
 
  # patching to easen tests
  class Net::FTP
    def sock ; @sock ; end
    class BufferedSocket
      def io ; @io ; end
    end
  end


  before do
    @thread = nil
  end

  after do
    if @thread
      @thread.join
    end
  end

  describe "#connect" do

    it "handles failed connection" do
      server = create_ftp_server { |sock|
        sock.print("421 Service not available, closing control connection.\r\n")
      }
      begin
        ftp = Net::FTP.new
        expect{ ftp.connect(SERVER_ADDR, server.port) }.to raise_error(Net::FTPTempError)
      ensure
        ftp.close if ftp
        server.close
      end
    end

    it "connects with a celluloid io socket" do
      commands = []
      server = create_ftp_server { |sock|
        sock.print("200 Switching to Binary mode.\r\n")
      }
      within_io_actor do
        begin
          begin
            ftp = Net::FTP.new
            ftp.connect(SERVER_ADDR, server.port)
            expect(ftp).not_to be_closed
            expect(ftp.sock).to be_a(Net::FTP::BufferedSocket)
            expect(ftp.sock.io).to be_a(Celluloid::IO::TCPSocket)
          ensure
            ftp.close if ftp
          end
        ensure
          server.close
        end
      end
    end
  end


  def create_ftp_server(sleep_time = nil)
    server = TCPServer.new(SERVER_ADDR, 0)
    @thread = Thread.start do
      if sleep_time
        sleep(sleep_time)
      end
      sock = server.accept
      begin
        yield(sock)
        sock.shutdown(Socket::SHUT_WR)
        sock.read unless sock.eof?
      ensure
        sock.close
      end
    end
    def server.port
      addr[1]
    end
    return server
  end
end

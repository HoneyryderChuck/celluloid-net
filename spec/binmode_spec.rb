require_relative '../lib/celluloid/net/telnet'

RSpec.describe Celluloid::Net::Telnet do
  let(:socket) { double("Telnet Socket") }
  let(:telnet) { Celluloid::Net::Telnet.new("Proxy" => socket) }
  before(:each) do
    allow(socket).to receive(:kind_of?).with(IO).and_return(true)
    allow(socket).to receive(:kind_of?).with(Net::Telnet).and_return(false)
  end

  describe "Celluloid::Net::Telnet#binmode when passed no arguments or nil" do
    it "returns the current Binmode value" do
      expect(telnet.binmode).to be_falsey
      expect(telnet.binmode(nil)).to be_falsey
      telnet.binmode = true
      expect(telnet.binmode).to be_truthy
    end
  end
  
  describe "Net::Telnet#binmode when passed [true]" do
    it "returns true" do
      expect(telnet.binmode(true)).to be_truthy
    end
  
    it "sets the Binmode to true" do
      telnet.binmode(true)
      expect(telnet.binmode).to be_truthy
    end
  end
  
  describe "Celluloid::Net::Telnet#binmode when passed [false]" do
  
    it "returns false" do
      expect(telnet.binmode(false)).to be_falsey
    end
  
    it "sets the Binmode to false" do
      telnet.binmode(false)
      expect(telnet.binmode).to be_falsey
    end
  end
  
  
  describe "Net::Telnet#binmode when passed [Object]" do
  
    it "raises an ArgumentError" do
      expect { telnet.binmode(Object.new) }.to raise_error(ArgumentError)
      expect { telnet.binmode("") }.to raise_error(ArgumentError)
      expect { telnet.binmode(:sym) }.to raise_error(ArgumentError)
    end
  
    it "does not change the Binmode" do
      mode = telnet.binmode
      telnet.binmode(Object.new) rescue nil
      expect(telnet.binmode).to eq(mode)
    end
  end
  
  describe "Net::Telnet#binmode= when passed [true]" do
  
    it "returns true" do
      expect(telnet.binmode = true).to be_truthy
    end
  
    it "sets the Binmode to true" do
      telnet.binmode = true
      expect(telnet.binmode).to be_truthy
    end
  end
  
  describe "Net::Telnet#binmode= when passed [false]" do
  
    it "returns false" do
      expect(telnet.binmode = false).to be_falsey
    end
  
    it "sets the Binmode to false" do
      telnet.binmode = false
      expect(telnet.binmode).to be_falsey
    end
  end
  
  describe "Net::Telnet#binmode when passed [Object]" do
  
    it "raises an ArgumentError" do
      expect { telnet.binmode = Object.new }.to raise_error(ArgumentError)
      expect { telnet.binmode = "" }.to raise_error(ArgumentError)
      expect { telnet.binmode = nil }.to raise_error(ArgumentError)
      expect { telnet.binmode = :sym }.to raise_error(ArgumentError)
    end
  
    it "does not change the Binmode" do
      telnet.binmode = true
      (telnet.binmode = Object.new) rescue nil
      expect(telnet.binmode).to be_truthy
    end
  end
end

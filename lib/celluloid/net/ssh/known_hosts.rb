# frozen_string_literal: true
require 'thread'
require 'strscan'
require 'openssl'
require 'base64'
require 'net/ssh/buffer'
require 'monitor'

module Celluloid
  module Net
  module SSH
    # this module's purpose is to provide a known-hosts implementation which plays well with the celluloid-io reactor.
    # the original implementation in net-ssh traverses all the known hosts files (global and user) looking for a fingerprint to match.
    # at the end of it all (default lenient strategy), if the fingerprint isn't stored, it appends it to the user known hosts file.
    # It does this for every host. 
    #
    # Even after patching net-ssh to work with celluloid-io, one might trip in this landmine. Fortunately, since 3.1, net-ssh allows one
    # to add a known-hosts module. This mode has to #search_for (and #add for the lenient strategy to work).
    #
    # This known hosts module is only for the secure strategy (which means, if you don't find a fingerprint, you fail immediately). It works around
    # the issues of file descriptor exhaustion by caching one open file descriptor for each known hosts file. For every lookup, it:
    #
    # * tries to find the fingerprint in the cache
    # * if not found, rewinds the file descriptor and looks from the top. 
    # * cache the known host key look ups, and returns.
    #
    # this operation is thread-safe, and this object should be central to the reactor. File operations block the reactor, and that's why we keep them at
    # a minimum. If not, your life will be full of broken PIPEs.
    # @note: the file descriptors remain open. If you don't need the known hosts module anymore, call #close, or you'll leak descriptors.  
    #
    class KnownHosts
      SUPPORTED_TYPE = ::Net::SSH::KnownHosts::SUPPORTED_TYPE
      # support net-ssh parameters. all keys are from there. 
      def initialize(options, which=:all)
        files = []

        # attention: switching order!! privileging global, which is set by system, over the others
        if which == :all || which == :global
          files += Array(options[:global_known_hosts_file] || %w(/etc/ssh/ssh_known_hosts /etc/ssh/ssh_known_hosts2))
        end

        if which == :all || which == :user
          files += Array(options[:user_known_hosts_file] || %w(~/.ssh/known_hosts ~/.ssh/known_hosts2))
        end

        @seekers = files.map{ |f| FileSeeker.new(f) }
      end

      # to test non-shared usage mode. WARNING: this is not to be used in production!
      def self.search_for(host, options={})
        new(options).search_for(host, options)
      end

      def search_for(host, options={})
        # try to keep the basic structure...
        ::Net::SSH::HostKeys.new(search_in(@seekers, host), host, self, options)
      end


      def add(*args)
        raise NotImplementedError, "#add is not implemented, nor it will, as keys must but added out-of-band"
      end

      def close
        @seekers.each(&:close)
      end

      private


      def search_in(seekers, host)
        seekers.flat_map { |s| s.keys_for(host) }
      end


      # this module aims at providing a better strategy at looking for host keys
      # * it caches them in an hash 
      # * one key for each of the host_as_string pairs, different arrays, same objects
      # * key not unpacked until really needed
      # * file handler remains open. Always downseek, cache everything, until it is found.
      #   * on subsequent seeks, first check if cached, otherwise continue down-seek. Do not rewind. 
      class FileSeeker

        attr_reader :path, :keys
        def initialize(hosts_file_path)
          @path  = File.expand_path(hosts_file_path)
          # stores the list of host keys by host
          @keys = {}
          @keys.extend(MonitorMixin)
          @file = nil
        end

        def keys_for(host)
          return [] unless @file || File.readable?(@path) # if file is already open or path is readable, ignore this condition

          entries = host.split(/,/)

          @keys.synchronize { 
            _, keys = @keys.find { |k, _| entries.include?(k) }
            # try to return first possibly cached
            (keys || keys_in_file_for(entries)).map(&:unpack!)
          }
        end

        def close
          @keys.synchronize do
            @file.close
            @keys.clear
          end if @file
        end
  
        private

        def append_key(host, key)
          (@keys[host] ||= []) << key
        end

        # this method is assumed to run under a mutex. 
        def keys_in_file_for(entries)
          @file ||= File.open(@path)

          scanner = StringScanner.new("")
          # for hostlist hash verification
          hostlist_hash = nil
          @file.each_line do |line|
            # skip commented 
            scanner.string = line
            scanner.skip(/\s*/)
            next if scanner.match?(/$|#/)

            linehosts = scanner.scan(/\S+/)
            hostlist = linehosts.split(/,/)

            # read key
            scanner.skip(/\s*/)
            type = scanner.scan(/\S+/)
            next unless SUPPORTED_TYPE.include?(type)
            scanner.skip(/\s*/)
            key = HostKey.new(scanner.rest)
            # save the key for each possible host
            hostlist.each { |h| append_key(h, key) }

            # calling #known_host_hash? may recalculate hmac entries.size number of times
            found = entries.all? { |entry| hostlist.include?(entry) } || begin
              hostlist_hash = hostlist.first if (is_known_host = known_host_hash?(hostlist, entries))
              is_known_host
            end

            break if found
          end
          @keys[entries.first] || @keys[hostlist_hash] || []
        end

        # Indicates whether one of the entries matches an hostname that has been
        # stored as a HMAC-SHA1 hash in the known hosts.
        def known_host_hash?(hostlist, entries)
          if hostlist.size == 1 && hostlist.first =~ /\A\|1(\|.+){2}\z/
            chunks = hostlist.first.split(/\|/)
            salt = Base64.decode64(chunks[2])
            digest = OpenSSL::Digest.new('sha1')
            entries.each do |entry|
              hmac = OpenSSL::HMAC.digest(digest, salt, entry)
              return true if Base64.encode64(hmac).chomp == chunks[3]
            end
          end
          false
        end


        class HostKey
          def initialize(unpacked_key)
            @unpacked = false
            @key = unpacked_key
          end

          def unpack!
            return @key if @unpacked
            @key = ::Net::SSH::Buffer.new(@key.unpack("m*").first).read_key
            @unpacked = true
            @key
          end
        end
      end
    end

  end
  end
end

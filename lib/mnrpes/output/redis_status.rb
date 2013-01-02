class MNRPES
  class Output
    class Redis_status
      def initialize
        require 'rubygems'
        require 'redis'
        require 'redis/objects'
        require 'redis/hash_key'

        config = MCollective::Config.instance

        @host = config.pluginconf.fetch("mnrpes.redis.host", "127.0.0.1")
        @port = Integer(config.pluginconf.fetch("mnrpes.redis.host", 6380))

        connect
      end

      def connect
        @redis = Redis.new(:host => @host, :port => @port)
      end

      def process(result)
        raise "No data received" unless result

        data = result[:body][:data]
        check = data[:command].gsub(/^check_/, "")

        hash = Redis::HashKey.new("status %s %s" % [result[:senderid], check])

        old_exitcode = hash["exitcode"]

        hash["host"] ||= result[:senderid]
        hash["check"] ||= check
        hash["exitcode"] = data[:exitcode]
        hash["lastcheck"] = Time.now.utc.to_i
        hash["output"] = data[:output].chomp
        hash["prefdata"] = data[:perfdata]

        if old_exitcode == data[:exitcode].to_s
          hash.incr("count", 1)
        else
          hash["count"] = 1
        end
      end
    end
  end
end

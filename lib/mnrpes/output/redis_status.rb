class MNRPES
  class Output
    # An output that maintains a status view of received results
    # in the Redis key-value store
    #
    # You need the redis and redis-objects gem installed to use this.
    #
    # The results will be maintained in Redis::HashKey instances with
    # names matching "check $hostname $checkname" like "check devco.net load"
    # and the data there in will be:
    #
    #     {"exitcode"=>"0",
    #      "count"=>"1",
    #      "lastcheck"=>"1357165874",
    #      "check"=>"totalprocs",
    #      "host"=>"devco.net",
    #      "output"=>"PROCS OK: 179 processes",
    #      "prefdata"=>""}
    #
    # This shows the current status of the host and for how many checks in
    # a row it held that status, if as here the status transition from 0 to
    # 1 the count will reset to 1 and it will then forever increment till the
    # next status change.
    #
    # In future we'll publish a notification of a change via Redis pub-sub so
    # downstream systems like alerters can get notified of a state change and
    # act accordingly
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

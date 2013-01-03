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
    # You can configure this output to publish a message to redis pubsub for
    # any check that has a status of > 0 and for any status change from one
    # state to another.
    #
    # To get these messages published you should first configure the pubsub
    # target:
    #
    #    plugin.mnrpes.redis.publish_target = monitor
    #
    # Messages with status > 0 will cause a message to be published to
    # monitor.issues while any state change will cause a message to be
    # published to monitor.state_change
    #
    # The state_change message will be a JSON string:
    #
    #     {"host" => "host.example.net",
    #      "check" => "load",
    #      "lastcheck" => 1357172058,
    #      "exitcode" => 1,
    #      "previous_exitcode" => 0}
    #
    # The issues message will be a JSON string, the count will be how many
    # times the check has been in this particular problem state:
    #
    #     {"host" => "host.example.net",
    #      "check" => "load",
    #      "lastcheck" => 1357172058,
    #      "exitcode" => 1,
    #      "count" => 3}
    class Redis_status
      def initialize
        require 'redis'
        require 'redis/objects'
        require 'redis/hash_key'
        require 'json'

        config = MCollective::Config.instance

        @host = config.pluginconf.fetch("mnrpes.redis.host", "127.0.0.1")
        @port = Integer(config.pluginconf.fetch("mnrpes.redis.host", 6379))
        @publish_target = config.pluginconf.fetch("mnrpes.redis.publish_target", nil)

        connect
      end

      def connect
        Redis.current = Redis.new(:host => @host, :port => @port)
      end

      def notify_state_change(host, check, lastcheck, previous_exitcode, exitcode)
        target = [@publish_target, "state_change"].join(".")
        msg = {"host" => host, "check" => check, "lastcheck" => lastcheck, "exitcode" => exitcode, "previous_exitcode" => previous_exitcode}.to_json

        publish(target, msg)
      end

      def notify_problem(host, check, lastcheck, exitcode, count)
        target = [@publish_target, "issues"].join(".")
        msg = {"host" => host, "check" => check, "lastcheck" => lastcheck, "exitcode" => exitcode, "count" => count}.to_json

        publish(target, msg)
      end

      def publish(target, msg)
        Redis.current.publish(target, msg)
      end

      def process(result)
        raise "No data received" unless result

        data = result[:body][:data]
        check = data[:command].gsub(/^check_/, "")
        last_check = Time.now.utc.to_i

        hash = Redis::HashKey.new("status %s %s" % [result[:senderid], check])

        old_exitcode = hash["exitcode"]

        hash["host"] ||= result[:senderid]
        hash["check"] ||= check
        hash["exitcode"] = data[:exitcode]
        hash["lastcheck"] = last_check
        hash["output"] = data[:output].chomp
        hash["prefdata"] = data[:perfdata]

        if old_exitcode == data[:exitcode].to_s
          hash.incr("count", 1)
        else
          hash["count"] = 1

          # publish for a state change but not if the old state was unknown
          notify_state_change(result[:senderid], check, last_check, old_exitcode, data[:exitcode]) if @publish_target && old_exitcode
        end

        notify_problem(result[:senderid], check, last_check, data[:exitcode], hash["count"]) if data[:exitcode] > 0 && @publish_target
      end
    end
  end
end

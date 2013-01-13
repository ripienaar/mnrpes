require 'redis'

class MNRPES
  class Output
    # An Output that writes received checks to Flapjack.
    #
    # Flapjack consumes a queue of events in Redis, you have to configure
    # the Redis host, port and db in your mcollective client file:
    #
    #    plugin.mnrpes.flapjack.redis_host = localhost
    #    plugin.mnrpes.flapjack.redis_port = 6379
    #    plugin.mnrpes.flapjack.redis_db = 6
    #
    # These settings should line up with your Flapjack Redis config.
    #
    # You can now just set the Flapjack output as one of the listed outputs:
    #
    #    plugin.mnrpes.processors = flapjack,stdout
    class Flapjack
      def initialize
        config = MCollective::Config.instance

        ropt = {}
        ropt["host"] = config.pluginconf.fetch("mnrpes.flapjack.redis_host", "localhost")
        ropt["port"] = Integer(config.pluginconf.fetch("mnrpes.flapjack.redis_port", "6379"))
        ropt["db"] = Integer(config.pluginconf.fetch("mnrpes.flapjack.redis_db", "6"))

        @redis = Redis.new(ropt)
      end

      def status_for_code(code)
        case code
          when 0
            "ok"
          when 1
            "warning"
          when 2
            "critical"
          else
            "unknown"
        end
      end

      def process(result)
        raise "No data received" unless result

        data = result[:body][:data]

        event = {
          'entity'      => result[:senderid],
          'check'       => data[:command].gsub("check_", ""),
          'type'        => 'service',
          'state'       => status_for_code(data[:exitcode]),
          'summary'     => data[:output].chomp,
          'timestamp'   => Integer(result[:msgtime])
        }

        Log.debug("Publishing %s" % event.inspect)

        @redis.rpush 'events', event.to_json
      rescue => e
        raise "Could not publish event to Redis: %s: %s: %s" % [e.backtrace.first, e.class, e]
      end
    end
  end
end

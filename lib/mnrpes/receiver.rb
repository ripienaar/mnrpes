class MNRPES
  class Receiver
    def initialize(command, destination)
      @command_file = command

      connect
      subscribe(destination)
    end

    def connect
      @connector = MCollective::PluginManager["connector_plugin"]
      @connector.connect
    end

    def subscribe(destination)
      Log.info("Subscribing to #{destination}")
      @connector.connection.subscribe(destination)
    end

    def receive_and_submit
      loop do
        begin
          receive do |result|
            data = result[:body][:data]

            unless data[:perfdata] == ""
              output = "%s|%s" % [data[:output], data[:perfdata]]
            else
              output = data[:output]
            end

            passive_check = "[%d] PROCESS_SERVICE_CHECK_RESULT;%s;%s;%d;%s" % [result[:msgtime], result[:senderid], data[:command].gsub("check_", ""), data[:exitcode], output]

            Log.info("Submitting passive data to nagios: #{passive_check}")
            File.open(@command_file, "w") {|nagios| nagios.puts passive_check }
          end
        rescue => e
          STDERR.puts "Could not write to #{@command_file}: %s: %s" % [e.class, e.to_s]
        end
      end
    end

    def receive
      message = @connector.receive

      # messages will be replies from daemons so set
      # the message up correctly and decode it via the
      # security providers
      message.type = :reply
      message.decode!

      yield(message.payload)
    end
  end
end

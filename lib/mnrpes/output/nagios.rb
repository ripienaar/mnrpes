class MNRPES
  class Output
    class Nagios
      def initialize
        @config = MCollective::Config.instance

        @command_file = config.pluginconf.fetch("mnrpes.nagios.command_file", "/var/log/nagios/rw/nagios.cmd")
      end

      def process(data)
        raise "No data received" unless data

        unless data[:perfdata] == ""
          output = "%s|%s" % [data[:output], data[:perfdata]]
        else
          output = data[:output]
        end

        passive_check = "[%d] PROCESS_SERVICE_CHECK_RESULT;%s;%s;%d;%s" % [result[:msgtime], result[:senderid], data[:command].gsub("check_", ""), data[:exitcode], output]

        Log.info("Submitting passive data to nagios: #{passive_check}")
        File.open(@command_file, "w") {|nagios| nagios.puts passive_check }
      rescue => e
        raise "Could not write to command file '%s': %s: %s" % [@command_file, e.class, e]
      end
    end
  end
end

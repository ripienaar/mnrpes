class MNRPES
  class Receiver
    def initialize(processor, destination)
      @processor = load_processor(processor)

      connect
      subscribe(destination)
    end

    def load_processor(processor)
      require 'mnrpes/output/%s' % processor

      MNRPES::Output.const_get(processor.capitalize).new
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
            @processor.process(result)
          end
        rescue => e
          Log.error "Could process received data: %s: %s" % [e.class, e.to_s]
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

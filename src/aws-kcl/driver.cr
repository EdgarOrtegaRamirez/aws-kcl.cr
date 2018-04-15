module AWS
  module KCL
    # Error raised if the {Driver} received an input action that it
    # could not parse or it could not handle.
    class MalformedActionException < Exception
    end

    # Entry point for a KCL application in Crystal.
    #
    # Implementers of KCL applications in Crystal should instantiate this
    # class and invoke the {#run} method to start processing records.
    class Driver
      # @param processor [RecordProcessor] A record processor
      #   to use for processing a shard.
      # @param input [IO] An `IO`-like object to read input lines from.
      # @param output [IO] An `IO`-like object to write output lines to.
      # @param error [IO] An `IO`-like object to write error lines to.
      def initialize(@record_processor : RecordProcessor, input : IO = STDIN, output : IO = STDOUT, error : IO = STDERR)
        @io_proxy = IOProxy.new(input, output, error)
        @checkpointer = DefaultCheckpointer.new(@io_proxy)
      end

      # Starts this KCL process's main loop.
      def run : Nil
        action = @io_proxy.read_action
        while action
          process_action(action)
          action = @io_proxy.read_action
        end
      end

      # Parses an input action and invokes the appropriate method of the
      # record processor and handles any resulting exceptions by writing
      # to the error stream.
      #
      # @param action [Action] An Action object that represents an action to take with
      #   appropriate attributes, as retrieved from {IOProxy#read_action}, e.g.
      #
      #   - `{"action":"initialize","shardId":"shardId-123"}`
      #   - `{"action":"processRecords","records":[{"data":"bWVvdw==","partitionKey":"cat","sequenceNumber":"456"}]}`
      #   - `{"action":"shutdown","reason":"TERMINATE"}`
      # @raise [MalformedActionException] if the action is missing expected attributes.
      private def process_action(action : Action) : Nil
        case action
        when InitializeAction
          @record_processor.init_processor(action.shard_id)
        when ProcessRecordsAction
          @record_processor.process_records(action.records, @checkpointer)
        when ShutdownAction
          @record_processor.shutdown(@checkpointer, action.reason)
        when ShutdownRequestedAction
          @record_processor.shutdown_requested(@checkpointer)
        else
          raise MalformedActionException.new("Received an action which couldn't be understood. Action was '#{action}'")
        end
        @io_proxy.write_action("status", { "responseFor" => action.action })
      rescue processor_error : Exception
        # We don't know what the client's code could raise and we have
        # no way to recover if we let it propagate up further. We will
        # mimic the KCL and pass over client errors. We print their
        # stack trace to STDERR to help them notice and debug this type
        # of issue.
        @io_proxy.write_error(processor_error)
      end
    end
  end
end

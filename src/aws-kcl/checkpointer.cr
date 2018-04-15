module AWS
  module KCL
    # Error class used for wrapping exception names passed through the
    # input stream.
    class CheckpointerException < Exception
      def initialize(message : String)
        super(message)
      end
    end

    # A checkpointer class which allows you to make checkpoint requests.
    #
    # A checkpoint marks a point in a shard where you've successfully
    # processed to. If this processor fails or loses its lease to that
    # shard, another processor will be started either by this
    # {https://github.com/awslabs/amazon-kinesis-client/blob/master/src/main/java/com/amazonaws/services/kinesis/multilang/package-info.java MultiLangDaemon}
    # or a different instance and resume at the most recent checkpoint
    # in this shard.
    abstract class Checkpointer
      # Checkpoints at a particular sequence number you provide or if `nil`
      # was passed, the checkpoint will be at the end of the most recently
      # delivered list of records.
      #
      # @param sequence_number [String, Nil] The sequence number to checkpoint at
      #   or `nil` if you want to checkpoint at the farthest record.
      # @raise [CheckpointerException] if the {https://github.com/awslabs/amazon-kinesis-client/blob/master/src/main/java/com/amazonaws/services/kinesis/multilang/package-info.java MultiLangDaemon}
      #   returned a response indicating an error, or if the checkpointer
      #   encountered unexpected input.
      abstract def checkpoint(sequence_number : String?) : Nil
    end

    # Default implementation of the {Checkpointer} abstract class.
    class DefaultCheckpointer < Checkpointer
      def initialize(@io_proxy : IOProxy)
      end

      # (see Checkpointer#checkpoint)
      def checkpoint(sequence_number : String?) : Nil
        @io_proxy.write_action("checkpoint", {"sequenceNumber" => sequence_number})
        # Consume the response action
        action = @io_proxy.read_action
        # Happy response is expected to be of the form:
        #   `{"action":"checkpoint","checkpoint":"<seq-number>"}`
        # Error response would look like the following:
        #   `{"action":"checkpoint","checkpoint":"<seq-number>","error":"<error-type>"}`
        if action && action.is_a?(CheckpointAction)
          raise CheckpointerException.new(action.error) if action.error_present?
        else
          # We are in an invalid state. We will raise a checkpoint exception
          # to the RecordProcessor indicating that the KCL app is in
          # an invalid state. See KCL documentation for description of this
          # exception. Note that the documented guidance is that this exception
          # is NOT retriable so the client code should exit (see
          # https://github.com/awslabs/amazon-kinesis-client/tree/master/src/main/java/com/amazonaws/services/kinesis/clientlibrary/exceptions)
          raise CheckpointerException.new("InvalidStateException")
        end
      end
    end
  end
end

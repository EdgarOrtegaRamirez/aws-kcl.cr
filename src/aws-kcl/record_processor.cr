module AWS
  module KCL
    # Base class for implementing a record processor.
    #
    # A `RecordProcessor` processes a shard in a stream. See {https://github.com/awslabs/amazon-kinesis-client/blob/master/src/main/java/com/amazonaws/services/kinesis/clientlibrary/interfaces/IRecordProcessor.java the corresponding KCL interface}.
    # Its methods will be called as follows:
    #
    # 1. {#init_processor} will be called once
    # 2. {#process_records} will be called zero or more times
    # 3. {#shutdown} will be called if this {https://github.com/awslabs/amazon-kinesis-client/blob/master/src/main/java/com/amazonaws/services/kinesis/multilang/package-info.java MultiLangDaemon}
    #    instance loses the lease to this shard
    abstract class RecordProcessor
      # Called once by a `Process` before any calls to process_records.
      #
      # @param shard_id [String] The shard id that this processor is going to be working on.
      abstract def init_processor(shard_id : String) : Nil

      # Called by a `Driver` with a list of records to be processed and a `Checkpointer`
      # which accepts sequence numbers from the records to indicate where in the stream
      # to checkpoint.
      #
      # @param records [Array<Hash>] A list of records that are to be processed. A record
      #   looks like:
      #
      #   ```
      #   {"data":"<base64 encoded string>","partitionKey":"someKey","sequenceNumber":"1234567890"}
      #   ```
      #
      #   Note that `data` attribute is a base64 encoded string. You can use `Base64.decode_string`
      #   in the `base64` module to get the original data as a string.
      # @param checkpointer [Checkpointer] A checkpointer which accepts a sequence
      #   number or no parameters.
      abstract def process_records(records : Array(Hash(String, String)), checkpointer : Checkpointer) : Nil

      # Called by a `Driver` instance to indicate that this record processor
      # should shutdown. After this is called, there will be no more calls to
      # any other methods of this record processor.
      #
      # @param checkpointer [Checkpointer] A checkpointer which accepts a sequence
      #   number or no parameters.
      # @param reason [String] The reason this record processor is being shutdown,
      #   can be either `TERMINATE` or `ZOMBIE`.
      #
      #   - If `ZOMBIE`, clients should not checkpoint because there is possibly
      #     another record processor which has acquired the lease for this shard.
      #   - If `TERMINATE` then `checkpointer.checkpoint()` (without parameters)
      #     should be called to checkpoint at the end of the shard so that this
      #     processor will be shutdown and new processor(s) will be created to
      #     for the child(ren) of this shard.
      abstract def shutdown(checkpointer : Checkpointer, reason : String) : Nil

      # Called by a `Driver` instance to indicate that this record processor
      # is requesting a shutdown.
      #
      # @param checkpointer [Checkpointer] A checkpointer which accepts a sequence
      #   number or no parameters.
      abstract def shutdown_requested(checkpointer : Checkpointer) : Nil
    end
  end
end

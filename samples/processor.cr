require "../src/aws-kcl"

class MyProcessor < AWS::KCL::RecordProcessor
  def initialize
    pp "INIT COMPLETE"
  end

  def init_processor(shard_id : String) : Nil
    pp shard_id
  end

  def process_records(records : Array(Hash(String, String)), checkpointer : AWS::KCL::Checkpointer) : Nil
    pp records
  end

  def shutdown(checkpointer : AWS::KCL::Checkpointer, reason : String) : Nil
    pp reason
  end

  def shutdown_requested(checkpointer : AWS::KCL::Checkpointer) : Nil
    pp checkpointer
  end
end

# Start the main processing loop
record_processor = MyProcessor.new
driver = AWS::KCL::Driver.new(record_processor)
driver.run

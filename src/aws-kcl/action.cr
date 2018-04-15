require "json"

module AWS
  module KCL
    abstract struct Action; end

    struct InitializeAction < Action
      JSON.mapping(
        action: { type: String },
        shard_id: { type: String, key: "shardId" }
      )
    end

    struct ProcessRecordsAction < Action
      JSON.mapping(
        action: { type: String },
        records: { type: Array(Hash(String, String)) }
      )
    end

    struct ShutdownAction < Action
      JSON.mapping(
        action: { type: String },
        reason: { type: String }
      )
    end

    struct ShutdownRequestedAction < Action
      JSON.mapping(
        action: { type: String },
        reason: { type: String }
      )
    end

    struct CheckpointAction < Action
      JSON.mapping(
        action: { type: String },
        checkpoint: { type: String },
        error: { type: String, nilable: true, presence: true }
      )
    end
  end
end

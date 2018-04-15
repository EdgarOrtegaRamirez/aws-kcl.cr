module AWS
  module KCL
    # Internal class used by {Driver} and {Checkpointer} to communicate
    # with the the {https://github.com/awslabs/amazon-kinesis-client/blob/master/src/main/java/com/amazonaws/services/kinesis/multilang/package-info.java MultiLangDaemon} via the input and output streams.
    class IOProxy
      # @param input [IO, #read_line] An `IO`-like object to read input lines from (e.g. `STDIN`).
      # @param output [IO] An `IO`-like object to write output lines to (e.g. `STDOUT`).
      # @param error [IO] An `IO`-like object to write error lines to (e.g. `STDERR`).
      def initialize(@input : IO = STDIN, @output : IO = STDOUT, @error : IO = STDERR)
      end

      # Reads one line from the input IO, strips it from any
      # leading/trailing whitespaces, skipping empty lines.
      #
      # @return [String, nil] The line read from the input IO or `nil`
      #   if end of stream was reached.
      def read_line : String?
        loop do
          line = @input.read_line.strip
          return line unless line.empty?
        end
      rescue IO::EOFError
        nil
      end

      # Reads a line and decodes it as a message from the {https://github.com/awslabs/amazon-kinesis-client/blob/master/src/main/java/com/amazonaws/services/kinesis/multilang/package-info.java MultiLangDaemon}.
      #
      # @return [AWS::KCL::Action | Nil] A Action hash representing the contents of the line, e.g.
      #   `InitializeAction({"action" => "initialize", "shardId" => "shardId-000001"})`
      def read_action : Action | Nil
        line = read_line
        return unless line
        action = JSON.parse(line)
        case action["action"].as_s
        when "initialize"
          InitializeAction.from_json(line)
        when "processRecords"
          ProcessRecordsAction.from_json(line)
        when "shutdown"
          ShutdownAction.from_json(line)
        when "shutdownRequested"
          ShutdownRequestedAction.from_json(line)
        when "checkpoint"
          CheckpointAction.from_json(line)
        end
      end

      # Writes a line to the output stream. The line is preceded and followed by a
      # new line because other libraries could be writing to the output stream as
      # well (e.g. some libs might write debugging info to `STDOUT`) so we would
      # like to prevent our lines from being interlaced with other messages so
      # the MultiLangDaemon can understand them.
      #
      # @param line [String] A line to write to the output stream, e.g.
      #   `{"action":"status","responseFor":"<someAction>"}`
      def write_line(line : String) : Nil
        @output.puts("\n#{line}\n")
        @output.flush
      end

      # Writes a line to the error file.
      #
      # @param error [String] An error message
      def write_error(error : String) : Nil
        @error.puts("#{error}\n")
        @error.flush
      end

      # Writes a line to the error file.
      #
      # @param error [Exception] An exception
      def write_error(exception : Exception) : Nil
        error = "#{exception.class}: #{exception.message}"
        error += "\n\t#{exception.backtrace.join("\n\t")}" if exception.backtrace?
        @error.puts("#{error}\n")
        @error.flush
      end

      # Writes a response action to the {https://github.com/awslabs/amazon-kinesis-client/blob/master/src/main/java/com/amazonaws/services/kinesis/multilang/package-info.java MultiLangDaemon},
      # in JSON of the form:
      #   `{"action":"<action>","detail1":"value1",...}`
      # where the details depend on the type of the action. See {https://github.com/awslabs/amazon-kinesis-client/blob/master/src/main/java/com/amazonaws/services/kinesis/multilang/package-info.java MultiLangDaemon documentation} for more infortmation.
      #
      # @param action [String] The action name that will be put into the output JSON's `action` attribute.
      # @param details [Hash(String, String)] Additional key-value pairs to be added to the action response.
      def write_action(action : String, details : Hash(String, String) = Hash.new(String, String)) : Nil
        response = {"action" => action}.merge(details)
        write_line(response.to_json)
      end
    end
  end
end

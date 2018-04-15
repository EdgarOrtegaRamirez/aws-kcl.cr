# AWS KCL

This package provides an interface to the Amazon Kinesis Client Library's (KCL)
MultiLangDaemon for the Crystal language. Developers can use the Amazon KCL to
build distributed applications that process streaming data reliably at scale.
The Amazon KCL takes care of many of the complex tasks associated with
distributed computing, such as load-balancing across multiple instances,
responding to instance failures, checkpointing processed records, and reacting
to changes in stream volume. This package wraps and manages the interaction
with the MultiLangDaemon which is part of the Amazon KCL for Java so that
developers can focus on implementing their record processor executable.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  aws-kcl:
    github: edgarortegaramirez/aws-kcl
```

## Usage

```crystal
require "aws-kcl"

class SampleRecordProcessor < AWS::KCL::RecordProcessor
  def init_processor(shard_id : String) : Nil
    # initialize
  end

  def process_records(records : Array(Hash(String, String)), checkpointer : AWS::KCL::Checkpointer) : Nil
    # process batch of records
  end

  def shutdown(checkpointer : AWS::KCL::Checkpointer, reason : String) : Nil
    # cleanup
  end
end

# Start the main processing loop
record_processor = SampleRecordProcessor.new
driver = KCL::Driver.new(record_processor)
driver.run
```

```
$ cd samples/
$ crystal build --release processor.cr
$ /Library/Java/JavaVirtualMachines/jdk-10.jdk/Contents/Home/bin/java -classpath jars/amazon-kinesis-client-1.9.0.jar:jars/aws-java-sdk-cloudwatch-1.11.311.jar:jars/aws-java-sdk-core-1.11.311.jar:jars/aws-java-sdk-dynamodb-1.11.311.jar:jars/aws-java-sdk-kinesis-1.11.311.jar:jars/aws-java-sdk-kms-1.11.311.jar:jars/aws-java-sdk-s3-1.11.311.jar:jars/commons-codec-1.11.jar:jars/commons-lang-2.6.jar:jars/commons-logging-1.2.jar:jars/guava-18.0.jar:jars/httpclient-4.5.5.jar:jars/httpcore-4.4.9.jar:jars/jackson-annotations-2.6.0.jar:jars/jackson-core-2.6.6.jar:jars/jackson-databind-2.6.6.jar:jars/jackson-dataformat-cbor-2.6.6.jar:jars/joda-time-2.9.9.jar:jars/protobuf-java-3.5.1.jar:/Users/your-user/proyect-path com.amazonaws.services.kinesis.multilang.MultiLangDaemon kcl.properties
```

## Contributing

1. Fork it ( https://github.com/edgarortegaramirez/aws-kcl/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[EdgarOrtegaRamirez]](https://github.com/EdgarOrtegaRamirez) Edgar Ortega - creator, maintainer

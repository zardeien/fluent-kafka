require 'poseidon'

class KafkaOutput < Fluent::Output
  # First, register the plugin. NAME is the name of this plugin
  # and identifies the plugin in the configuration file.
  Fluent::Plugin.register_output('kafka', self)

  # config_param defines a parameter. You can refer a parameter via @path instance variable
  # Without :default, a parameter is required.
  config_param :path, :string
  config_param :topic, :string

  # This method is called before starting.
  # 'conf' is a Hash that includes configuration parameters.
  # If the configuration is invalid, raise Fluent::ConfigError.
  def configure(conf)
    super

    # You can also refer raw parameter via conf[name].
    @path = conf['path'].split(",")
    @topic = conf['topic']
  end

  # This method is called when starting.
  # Open sockets or files here.
  def start
    super
    @producer = Poseidon::Producer.new(@path, @topic)
  end

  # This method is called when shutting down.
  # Shutdown the thread and close sockets or files here.
  def shutdown
    super
    @producer.shutdown
  end

  # This method is called when an event reaches to Fluentd.
  # Convert the event to a raw string.
  def format(tag, time, record)
    [tag, time, record].to_json + "\n"
    ## Alternatively, use msgpack to serialize the object.
    # [tag, time, record].to_msgpack
  end

  # This method is called every flush interval. Write the buffer chunk
  # to files or databases here.
  # 'chunk' is a buffer chunk that includes multiple formatted
  # events. You can use 'data = chunk.read' to get all events and
  # 'chunk.open {|io| ... }' to get IO objects.
  #
  # NOTE! This method is called by internal thread, not Fluentd's main thread. So IO wait doesn't affect other plugins.
  def emit(tag, es, chain)
    chain.next
    es.each do |time,record|
      message = []
      message << Poseidon::MessageToSend.new(@topic, record.to_json)
      @producer.send_messages(message)
    end
  end

  ## Optionally, you can use chunk.msgpack_each to deserialize objects.
  #def write(chunk)
  #  chunk.msgpack_each {|(tag,time,record)|
  #  }
  #end
end
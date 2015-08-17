require 'cassandra'

class DRA
  attr_reader :session

  class KeyNameUndefined < StandardError; end

  def initialize(hosts, keyspace, compute_handlers = {})
    cluster = Cassandra.cluster(hosts: hosts)
    @session = cluster.connect(keyspace)
  end

  def get(computer, collection_options = [])
    options = computer.zip_with_key(collection_options)

    content = fetch_content(computer.table_name, options.keys)

    missing_content = compute_missing_data(computer, options, content.keys)

    persist(computer.table_name, missing_content, computer.ttl)

    content.merge(missing_content)
  end

  private

  def fetch_content(table_name, keys)
    statement = "select keyname, content from #{table_name} where keyname in :keys;"
    args = { table_name: table_name, keys: keys }
    result = session.execute(session.prepare(statement), arguments: args)

    result.each_with_object({}) do |row, h|
      h[row.fetch('keyname')] = row.fetch('content')
    end
  end

  def compute_missing_data(computer, options, existing_keys)
    missing_keys = options.keys - existing_keys
    missing_keys.each_with_object({}) do |key, result|
      result[key] = computer.compute(options.fetch(key))
    end.select { |k,v| missing_keys.include?(k) }
  end

  def persist(table_name, data, ttl)
    return if data.values.any? { |val| val == :compute_not_defined }

    statement = "insert into #{table_name}(keyname, content) values (:keyname, :content) using ttl #{ttl};"
    prepared_statement = session.prepare(statement)
    data.each do |key, content|
      args = { keyname: key, content: content }
      session.execute_async(prepared_statement, arguments: args)
    end
  end

  module Computer
    def key_name(options)
      fail KeyNameUndefined, 'Please define the key_name'
    end

    def compute(args)
      :compute_not_defined
    end

    def ttl
      3600
    end

    def table_name
      "dra_#{name.downcase}"
    end

    def zip_with_key(collection)
      collection.each_with_object({}) do |opts, result|
        result[key_name(opts)] = opts
      end
    end
  end
end

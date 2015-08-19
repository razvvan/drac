[![Build Status](https://travis-ci.org/dawanda/drac.svg?branch=master)](https://travis-ci.org/dawanda/drac)

# Data Retreival Accelerator - [Cassandra](https://cassandra.apache.org/) based caching mechanism

## Setup

First, get Cassandra.

```
docker run --name some-cassandra -d cassandra -p 9042:9042
docker run --rm -it --link some-cassandra:cassandra cassandra cqlsh cassandra
cqlsh> CREATE KEYSPACE somekeyspace
  WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };

```



## Usage

```
require 'drac'
drac = Drac.new(['192.168.99.100'], 'somekeyspace')

module TestDataSourceCache
  extend Drac::Computer

  def self.key_name(opts)
    "foo_#{opts.fetch(:id)}"
  end

  def self.compute(opts)
    sleep(3)
    "something with #{opts.fetch(:id)}"
  end

  def self.ttl
    30
  end
end
drac.create_tables([TestDataSourceCache])

drac.get(TestDataSourceCache, [{ id: 23 }])
drac.get(TestDataSourceCache, [{ id: 23 }])
```

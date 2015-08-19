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
Drac.new(['192.168.99.100'], 'somekeyspace')
```

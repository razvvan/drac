require 'drac'

module TestDataSourceCache
  extend Drac::Computer

  def self.key_name(opts)
    "foo_#{opts.fetch(:id)}"
  end

  def self.compute(opts)
    "something with #{opts.fetch(:id)}"
  end

  def self.ttl
    1
  end
end

module ReadOnlyDataSource
  extend Drac::Computer
end

RSpec.describe "Drac with real data" do
  let(:prepared_statement) { double('prepared_statement') }
  let(:session) { double('session', prepare: prepared_statement) }
  let(:cluster) { double('cluster', connect: session) }
  let(:drac) { Drac.new(['some-hostname'], 'some-keyspace') }

  before do
    expect(Cassandra).to receive(:cluster).with(hosts: ['some-hostname']) { cluster }
  end

  context 'reading' do
    it 'reads one key from cassandra' do
      opts = { arguments: { table_name: 'drac_testdatasourcecache', keys: ['foo_12'] } }
      expect(session).to receive(:execute).with(prepared_statement, opts).
        and_return([{ 'keyname' => 'foo_12', 'content' => 'bar' }])

      result = drac.get(TestDataSourceCache, [{ id: 12 }])
      expect(result).not_to be_empty
    end

    it 'reads many keys' do
      opts = { arguments: { table_name: 'drac_testdatasourcecache', keys: ['foo_12', 'foo_13'] } }
      expect(session).to receive(:execute).with(prepared_statement, opts).
        and_return([
          { 'keyname' => 'foo_12', 'content' => 'bar' },
          { 'keyname' => 'foo_13', 'content' => 'bar' }
        ])

      result = drac.get(TestDataSourceCache, [{ id: 12 }, { id: 13 }])
      expect(result.count).to eq 2
    end
  end

  context 'writing' do
    before do
      expect(session).to receive(:execute) { [] }
    end

    it "computes the value if it doesn't exist" do
      expect(session).to receive(:execute_async)

      result = drac.get(TestDataSourceCache, [{ id: 42 }])
      expect(result.count).to eq 1
      expect(result.values.first).to eq 'something with 42'
    end

    it "also persists the value" do
      expect(session).to receive(:execute_async).
        with(prepared_statement, { arguments: { keyname: 'foo_43', content: 'something with 43' } })

      result = drac.get(TestDataSourceCache, [{ id: 43 }])

      expect(result.count).to eq 1
      expect(result.values.first).to eq 'something with 43'
    end

    it 'adds a default ttl' do
      expect(session).to receive(:prepare).with(/select/).once
      expect(session).to receive(:prepare).with(/insert.*ttl 1/).once
      expect(session).to receive(:execute_async)
      drac.get(TestDataSourceCache, [{ id: 44 }])
    end
  end

  describe ReadOnlyDataSource do
    it "fails if you don't have a keyname defined" do
      expect { drac.get(described_class, [{ id: 12 }]) }.
        to raise_error(Drac::KeyNameUndefined)
    end

    it "should not persist if `compute` is undefined" do
      expect(session).to receive(:execute) { [] }
      allow(ReadOnlyDataSource).to receive(:key_name) { 'foo' }

      expect(session).not_to receive(:execute_async)

      drac.get(described_class, [{ id: 12 }])
    end
  end
end

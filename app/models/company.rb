include Benchmark

class Company
  include Mongoid::Document
  include Tire::Model::Search
  include Tire::Model::Callbacks

  field :name, type: String
  field :email, type: String
  field :phone, type: String
  field :address, type: String
  field :city, type: String
  field :country, type: String
  field :description, type: String

  attr_accessible :name, :email, :city, :country, :address, :phone, :description

  mapping do
    indexes :name,   type: 'string'
    indexes :email,  type: 'string'
    indexes :city,   :type => 'string', :index => :not_analyzed
    indexes :country,type: 'string'
  end

  def to_indexed_json
    to_json(methods: [:name, :email, :city, :country])
  end

  def self.advance_search(q)
    Company.tire.search do
      query { string q }
      facet 'city' do
        terms :city
      end
      sort { by :city, 'desc' }
    end
  end

  def self.bench_advance
    Benchmark.benchmark(CAPTION, 7, FORMAT) do |x|
      a = []
      100.times do
        q = Faker::Company.name
        i = x.report("Process #{i}") {
          (1..10).map{
            Thread.new do
              Company.search(q)
            end
          }.each(&:join)
        }
        a << i
      end
      [a.inject(:+), a.inject(:+)/a.size]
    end

    # puts result
  end

  def self.bench
    result = Benchmark.measure do
      (1..10).map{
        Thread.new do
          Company.advance_search("moore")
        end
      }.each(&:join)
    end

    puts result
  end

  def self.bench_query
    Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |x|
      a = []
      100.times do |i|
        q = Faker::Company.name
        i = x.report("Process #{i}") {
          Company.advance_search(q)
        }
        a << i
      end
      [a.inject(:+), a.inject(:+)/a.size]
    end
  end
end

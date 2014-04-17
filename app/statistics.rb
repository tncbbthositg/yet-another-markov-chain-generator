require 'pg'

class Statistics
  DATABASE_NAME = ENV['database'] || 'markov_chain'
  
  class << self
    def database_name
      DATABASE_NAME
    end

    def execute_query(query, parameters = nil)
      Enumerator.new do |yielder|
        execute_statement(query, parameters) do |results| 
          results.each { |row| yielder << row }
        end
      end
    end
    
    def execute_statement(statement, parameters = nil)
      within_transaction do |statistics| 
        statistics.execute_statement(statement, parameters) do |results|
          yield results if block_given?
        end
      end
    end    
    
    def within_transaction
      connection = PGconn.open dbname: database_name
      begin
        connection.transaction do
          yield Statistics.new connection
        end
      ensure
        connection.close
      end
    end        
    
    def find_source(file_name)
      self.execute_query("SELECT * FROM source;").first
    end
  end
  
  def initialize(connection)
    @connection = connection
  end
  
  def execute_query(query, parameters = nil)
    Enumerator.new do |yielder|
      execute_statement(query, parameters) do |results|
        results.each { |row| yielder << row }
      end
    end
  end
  
  def execute_statement(statement, parameters = nil)
    @connection.exec(statement) do |results|
      yield results if block_given?
    end
  end
end
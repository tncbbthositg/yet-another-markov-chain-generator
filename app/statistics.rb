require 'pg'

class Statistics
  DATABASE_NAME = ENV['database'] || 'markov_chain'
  
  class << self
    def database_name
      DATABASE_NAME
    end

    def execute_query(query, *parameters)
      Enumerator.new do |yielder|
        execute_statement(query, *parameters) do |results| 
          results.each { |row| yielder << row }
        end
      end
    end
    
    def execute_statement(statement, *parameters)
      within_transaction do |statistics| 
        statistics.execute_statement(statement, *parameters) do |results|
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
      self.execute_query("SELECT * FROM source WHERE file_name = $1;", file_name).first
    end
  end
  
  def initialize(connection)
    @connection = connection
  end
  
  def execute_query(query, *parameters)
    Enumerator.new do |yielder|
      execute_statement(query, *parameters) do |results|
        results.each { |row| yielder << row }
      end
    end
  end
  
  def execute_statement(statement, *parameters)
    @connection.exec_params(statement, parameters) do |results|
      yield results if block_given?
    end
  end
  
  def write_word(source, word)
    execute_statement("INSERT INTO word (source_id, word, count, is_first, is_last) VALUES ($1, $2, $3, $4, $5);", 
      source["id"], word[:word], word[:count], word[:is_first], word[:is_last])
  end
end
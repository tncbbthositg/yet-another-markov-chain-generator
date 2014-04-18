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
    
    def get_starting_word(source)
      self.execute_query('SELECT * FROM word WHERE source_id = $1 AND is_first = true ORDER BY RANDOM() LIMIT 1;', source["id"]).first
    end

    def get_next_word(word)
      pair = get_next_word_pair word
      self.execute_query('SELECT * FROM word WHERE id = $1', pair["next_word_id"]).first
    end
    
    private
    def get_next_word_pair(word)
      pairs = self.execute_query('SELECT * FROM pair WHERE current_word_id = $1;', word["id"])
      pair_count = pairs.inject(0) { |result, pair| result + pair["count"].to_i }
      p = Random.rand pair_count

      pairs.each do |pair|
        p -= pair["count"].to_i
        return pair if p < 0
      end
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
  
  def write_pair(source, pair)
    execute_statement("
      INSERT INTO pair (current_word_id, next_word_id, count)
      SELECT 
        (SELECT id FROM word WHERE word = $2 AND source_id = $1) AS current_word_id, 
        (SELECT id FROM word WHERE word = $3 AND source_id = $1) AS next_word_id,
        $4
      ", 
      source["id"], pair[:current_word], pair[:next_word], pair[:count])
  end  
end
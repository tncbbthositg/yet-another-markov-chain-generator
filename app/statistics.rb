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
    
    def find_sources(*file_names)
      self.execute_query("SELECT * FROM source WHERE file_name = ANY(string_to_array($1, ','));", file_names.join(','))
    end
    
    def get_starting_word(*sources)
      source_ids = map_source_ids sources
      self.execute_query("SELECT * FROM word WHERE source_id = ANY(string_to_array($1, ',')::INT[]) AND is_first = true ORDER BY RANDOM() LIMIT 1;", source_ids).first
    end

    def get_next_word(word, *sources)
      pair = get_next_word_pair word, *sources
      self.execute_query('SELECT * FROM word WHERE id = $1', pair["next_word_id"]).first
    end
    
    private
    def get_next_word_pair(word, *sources)
      source_ids = map_source_ids(sources)
      pairs = self.execute_query('
        SELECT * FROM pair WHERE current_word_id IN (
          SELECT id FROM word 
          WHERE word = $1 
            AND source_id = ANY(string_to_array($2, \',\')::INT[]));', word["word"], source_ids)
      pair_count = pairs.inject(0) { |result, pair| result + pair["pair_frequency"].to_i }
      p = Random.rand pair_count

      pairs.each do |pair|
        p -= pair["pair_frequency"].to_i
        return pair if p < 0
      end
    end
    
    def map_source_ids(sources)
      source_ids = sources.map {|source| source["id"]}.join(',')
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
  
  def execute_prepared_statement(name, *parameters)
    @connection.exec_prepared(name, parameters) do |results|
      yield results if block_given?
    end
  end
  
  def write_word(source, word)
    @prepared_word = @prepared_word || @connection.prepare("insert_word", 'INSERT INTO word (source_id, word, count, is_first, is_last) VALUES ($1, $2, $3, $4, $5);')
    execute_prepared_statement('insert_word', source["id"], word[:word], word[:count], word[:is_first], word[:is_last])
  end
  
  def write_pair(source, pair)
    @prepared_pair = @prepared_pair || @connection.prepare("insert_pair", "
      INSERT INTO pair (current_word_id, next_word_id, count, pair_frequency)
      SELECT 
        (SELECT id FROM word WHERE word = $2 AND source_id = $1) AS current_word_id, 
        (SELECT id FROM word WHERE word = $3 AND source_id = $1) AS next_word_id,
        $4, $5
      ")

    execute_prepared_statement('insert_pair', source["id"], pair[:current_word], pair[:next_word], pair[:count], pair[:pair_frequency])
  end  
end
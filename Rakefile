Dir[File.join(File.dirname(__FILE__), 'app', '*.rb')].each {|file| require file }

DATABASE_NAME = Statistics.database_name

namespace :db do
  desc "ensure database #{DATABASE_NAME} exists"
  task :ensure do
    puts "Ensuring database #{DATABASE_NAME} is present."
    matches = `psql -l | grep #{DATABASE_NAME} | wc -l`.to_i > 0
    Rake::Task['db:create'].invoke if !matches
  end
  
  desc "recreate database #{DATABASE_NAME}"
  task :recreate do
    puts "Recreating database #{DATABASE_NAME}."
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
  end
  
  desc "create database #{DATABASE_NAME}"
  task :create do
    puts "Creating database #{DATABASE_NAME}."
    `createdb #{DATABASE_NAME}`

    Statistics.within_transaction do |statistics|
      statistics.execute_statement 'CREATE TABLE source (id SERIAL NOT NULL UNIQUE, file_name VARCHAR(128) NOT NULL UNIQUE);'

      statistics.execute_statement '      
        CREATE TABLE word (
          id SERIAL NOT NULL UNIQUE, 
          source_id INT NOT NULL REFERENCES source(id) ON DELETE CASCADE,
          word VARCHAR(128) NOT NULL, 
          count INT NOT NULL,
          is_first BOOLEAN NOT NULL,
          is_last BOOLEAN NOT NULL
        );'

      statistics.execute_statement 'CREATE INDEX ON word (word);'

      statistics.execute_statement '
        CREATE TABLE pair (
          id SERIAL NOT NULL UNIQUE, 
          current_word_id INT NOT NULL REFERENCES word(id) ON DELETE CASCADE, 
          next_word_id INT NOT NULL REFERENCES word(id) ON DELETE CASCADE,
          count INT NOT NULL,
          pair_frequency INT NOT NULL
        );'
    end
  end
  
  desc "drop database #{DATABASE_NAME}"
  task :drop do
    puts "Dropping datbase #{DATABASE_NAME}."
    `dropdb #{DATABASE_NAME} --if-exists`
  end
end    

namespace :learning do
  desc "parse file with provided name"
  task :parse, [:file_name] => ["db:ensure"] do |t, args|
    filename = args[:file_name]

    puts "Looking for data source for #{filename}."
    source = Statistics.find_sources(filename).first
    next if !source.nil?

    puts "Parsing #{filename}."

    parser = Parser.new(filename)

    Statistics.within_transaction do |statistics|
      source = statistics.execute_query("INSERT INTO source (file_name) VALUES ($1) RETURNING *;", filename).first
      parser.words.each {|w| statistics.write_word source, w}
      parser.pairs.each {|p| statistics.write_pair source, p}
    end
  end
  
  desc "clear data from provided source"
  task :clear, [:file_name] => ["db:ensure"] do |t, args|
    filename = args[:file_name]
    source = Statistics.find_sources(filename).first
    next if source.nil?

    puts "Clearing data for #{filename}."
    Statistics.execute_statement "DELETE FROM source WHERE id = $1;", source["id"]
  end
end

desc "generate markov chain"
task :generate, [:file_names] do |t, args|
  filenames = args[:file_names].split(/\s+/)
  puts "Generating Markov chain for #{filenames}."

  filenames.each do |name| 
    task = Rake::Task['learning:parse']
    task.invoke(name)
    task.reenable
  end
  sources = Statistics.find_sources(filenames).to_a

  builder = Builder.new(*sources)
  puts builder.build_sentence
end  
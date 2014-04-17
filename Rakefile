Dir[File.join(File.dirname(__FILE__), 'app', '*.rb')].each {|file| require file }

DATABASE_NAME = Statistics.database_name

namespace :db do
  desc "ensure database #{DATABASE_NAME} exists"
  task :ensure do
    matches = `psql -l | grep #{DATABASE_NAME} | wc -l`.to_i > 0
    Rake::Task['db:create'].invoke if !matches
  end
  
  desc "recreate database #{DATABASE_NAME}"
  task :recreate do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
  end
  
  desc "create database #{DATABASE_NAME}"
  task :create do
    `createdb #{DATABASE_NAME}`
    Statistics.execute_statement 'CREATE TABLE source (id SERIAL, file_name VARCHAR(128) NOT NULL UNIQUE);'
  end
  
  desc "drop database #{DATABASE_NAME}"
  task :drop do
    puts `dropdb #{DATABASE_NAME} --if-exists`
  end
end    

namespace :learning do
  desc "parse file with provided name"
  task :parse, [:file_name] => ["db:ensure"] do |t, args|
    filename = args[:file_name]
    source = Statistics.find_source filename
    next if !source.nil?

    Statistics.within_transaction do |statistics|
      source = statistics.execute_query("INSERT INTO source (file_name) VALUES ('test') RETURNING *;", filename).first
      Parser.new(filename).parse
    end
  end
  
  desc "clear data from provided source"
  task :clear, [:file_name] => ["db:ensure"] do |t, args|
    filename = args[:file_name]
    source = Statistics.find_source filename
    next if source.nil?

    Statistics.within_transaction do |statistics|
      statistics.execute_statement "DELETE FROM source WHERE id = $1;", [source[:id]]
      statistics.execute_statement "DELETE FROM source WHERE id = $1;", [source[:id]]
    end
  end
end
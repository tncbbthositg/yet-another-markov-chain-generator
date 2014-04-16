Dir[File.join(File.dirname(__FILE__), 'app', '*.rb')].each {|file| require file }

DATABASE_NAME = ENV['database'] || 'markov_chain'

namespace :db do
  desc "ensure database #{DATABASE_NAME} exists"
  task :ensure do
    matches = `psql -l | grep #{DATABASE_NAME} | wc -l`.to_i > 0
    Rake::Task['db:recreate'].invoke if !matches
  end
  
  desc "recreate database #{DATABASE_NAME}"
  task :recreate do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
  end
  
  desc "create database #{DATABASE_NAME}"
  task :create do
    `createdb #{DATABASE_NAME}`
  end
  
  desc "drop database #{DATABASE_NAME}"
  task :drop do
    puts `dropdb #{DATABASE_NAME} --if-exists`
  end
end    

namespace :learning do
  desc "parse file with provided name"
  task :parse, :file_name do |t, args|
    filename = args[:file_name]
    
    Parser.new(filename).parse
  end
end
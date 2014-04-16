require_relative 'app/parser'

namespace :learning do
  desc "parse file with provided name"
  task :parse, :file_name do |t, args|
    filename = args[:file_name]
    
    Parser.new(filename).parse
  end
end
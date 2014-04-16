require 'pg'

class Statistics
  def test
    connection = PGconn.open dbname: 'colin_demo'
    connection.exec("SELECT * FROM even") do |results|
      results.each {|row| puts row}
    end
    connection.close
  end
end
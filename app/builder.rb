require_relative 'statistics'

class Builder
  def initialize(*sources)
    @sources = sources
  end
  
  def build_sentence
    source = @sources.first
    words = [] << Statistics.get_starting_word(source)
    while words.last["is_last"] != 't'
      words << Statistics.get_next_word(words.last)
    end
    words.map {|word| word["word"]}.join(" ")
  end
end
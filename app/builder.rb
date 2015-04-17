require_relative 'statistics'

class Builder
  COLORS = ['1;36', '1;32', '1;35', '1;33', '1;35', '1;31']

  def initialize(*sources)
    sources.each_with_index { |source, index| source[:color] = COLORS[index] }
    sources.each { |source| puts colorize(source, source[:color])} if ENV['DEBUG']
    @source_colors = sources.inject({}) { |result, source| result[source["id"]] = source[:color]; result }
    @sources = sources
  end

  def build_sentence
    words = [] << Statistics.get_starting_word(*@sources)

    while words.last["is_last"] != 't'
      words << Statistics.get_next_word(words.last, *@sources)
    end

    if ENV['DEBUG']
      words = words.map {|word| colorize(word["word"], @source_colors[word["source_id"]])}
    else
      words = words.map{ |word| word["word"] }
    end

    words.join(" ")
  end

  private
  def colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end
end
class Parser
  SENTENCE_PUNCTUATION = /[?.!]"?$/
  
  attr_reader :words
  
  def initialize(filename)
    @words = parse(filename)
  end
  
  private
  def parse(filename)
    words = {}
    last_word = nil
    
    File.open(filename, 'r') do |file|
      text = file.read

      text.split.each do |s|
        word = words[s] || { count: 0, word: s, is_first: false, is_last: false }
        word[:count] += 1
        word[:is_first] = true if last_word.nil?
        words[s] = word

        if s =~ SENTENCE_PUNCTUATION 
          word[:is_last] = true
          last_word = nil
        else
          last_word = s
        end
      end
    end
    
    words.values
  end
end
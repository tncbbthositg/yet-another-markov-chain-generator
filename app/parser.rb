class Parser
  SENTENCE_PUNCTUATION = /[?.!]"?$/
  
  attr_reader :words
  attr_reader :pairs
  
  def initialize(filename)
    parse(filename)
  end
  
  private
  def parse(filename)
    words = {}
    pairs = {}
    previous_word = nil
    
    File.open(filename, 'r') do |file|
      text = file.read

      text.split.each do |s|
        words[s] = word = words[s] || { count: 0, word: s, is_first: false, is_last: false }
        word[:count] += 1
        
        if previous_word.nil?
          word[:is_first] = true
        else
          key = [previous_word, s]
          pairs[key] = pair = pairs[key] || { count: 0, current_word: previous_word, next_word: s }
          pair[:count] += 1
        end
          
        if s =~ SENTENCE_PUNCTUATION 
          word[:is_last] = true
          previous_word = nil
        else
          previous_word = s
        end
      end
    end
    
    @words = words.values
    @pairs = pairs.values
  end
end
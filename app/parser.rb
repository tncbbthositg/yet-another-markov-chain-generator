class Parser
  SENTENCE_PUNCTUATION = /[?.!]"?$/

  attr_reader :words
  attr_reader :pairs

  def initialize(filename)
    parse(filename)
  end

  private
  def parse(filename)
    $stdout.sync = true

    words = {}
    pairs = {}
    previous_word = nil

    puts "Opening file #{filename}."
    File.open(filename, 'r') do |file|
      text = file.read.force_encoding("ISO-8859-1").encode("utf-8", replace: nil)
      text = text.gsub(/(Mrs?)./, '\1')
      current_word_count = 0;

      puts "Analyzing words!"
      text.split.each do |current_word|
        words[current_word] = word = words[current_word] || { count: 0, word: current_word, is_first: false, is_last: false }
        word[:count] += 1

        if previous_word.nil?
          word[:is_first] = true
        else
          key = [previous_word, current_word]
          pairs[key] = pair = pairs[key] || { count: 0, current_word: previous_word, next_word: current_word }
          pair[:count] += 1
        end

        if current_word =~ SENTENCE_PUNCTUATION
          word[:is_last] = true
          previous_word = nil
        else
          previous_word = current_word
        end

        current_word_count += 1
        print '.' if current_word_count % 100 == 0
      end
    end
    puts "\nClosed file #{filename}."

    puts "Computing pair frequencies."
    add_pair_frequency(pairs.values)
    puts "Finished computing pair frequencies"

    @words = words.values
    @pairs = pairs.values
  end

  def add_pair_frequency(pairs)
    pairs.group_by { |pair| pair[:current_word] }.each do |word, pairs|
      total_frequency = pairs.inject(0) { |result, pair| result + pair[:count] }
      pairs.each { |pair| pair[:pair_frequency] = pair[:count] * 1.0 / total_frequency }
    end
  end
end
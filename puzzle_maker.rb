require 'yaml'

class FreeBee
  VOWELS = %w(A E I O U)
  
  def self.vowel_count(array_of_chars)
    array_of_chars.count { |char| VOWELS.include?(char) }
  end

  private
  # imports a scrabble dictionary and generates a free_bee dictionary for creating a word list
  def self.import
    @dictionary = File.readlines("data/scrabble_words.txt", chomp: true) # text file of scarbble dictionary
    free_bee_words = @dictionary.select { |word| word.size >= 4 && word.chars.uniq.size <= 7 }
    File.write("data/free_bee_words.yaml", free_bee_words)
  end
  
  # a panagram is a word that has seven unique letters
  # select only words that are valid panagrams
  def self.select_panagrams
    available_panagrams = @dictionary.select do |word|
                            characters = word.chars.uniq
                            characters.size == 7 && !characters.any?(/X/) 
                          end

    File.write("data/available_panagrams.yaml", available_panagrams)
  end
  
  # generate puzzle combos based uniq and valid panagrams
  # select only puzzle combos that contain exactly two vowels
  def self.generate_combos
    available_panagrams = YAML.load_file("data/available_panagrams.yaml")

    @puzzle_combos = available_panagrams.map { |word| word.chars.uniq.sort }.uniq
    @puzzle_combos.select! { |puzzle| vowel_count(puzzle) == 2 }

    File.write("data/puzzle_combos.yaml", @puzzle_combos)
  end

  public
  # for a given puzzle select words that satisfy the puzzle i.e. all letters in the word are contained within
  def self.gram?(combo, word)
    word.chars.all? { |letter| combo.include?(letter) }
  end

  # sample a puzzle from the list of puzzle_combost and generate a word list
  # where each word is a solution to the puzzle
  def self.generate_puzzle
    available_words = YAML.load_file("data/free_bee_words.yaml")
    puzzle_combo = YAML.load_file("data/puzzle_combos.yaml").sample
    free_bee = { letters: puzzle_combo, words: [] }
    available_words.each do |word|
      free_bee[:words] << word if gram?(puzzle_combo, word)
    end
    free_bee
  end

  def self.puzzle_score(words)
    words.inject(0) do |sum, word|
      sum + (( word.length - 3 ) / 1.5).to_i
    end
  end

  def self.new_puzzle
    free_bee = generate_puzzle
    key = free_bee[:letters].sample

    free_bee[:key] = [ free_bee[:letters].delete(key) ]
    free_bee[:words].select! { |word| word.include?(key) }
    free_bee[:score] = puzzle_score(free_bee[:words]) 

    free_bee
  end
end

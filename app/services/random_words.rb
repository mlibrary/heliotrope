# frozen_string_literal: true

class RandomWords
  def noun
    rvalue = @nouns.pop
    @nouns << rvalue
    rvalue
  end

  def adj
    rvalue = @adjs.pop
    @adjs << rvalue
    rvalue
  end

  def initialize
    @nouns = Queue.new
    loop do
      begin
        noun = RandomWord.nouns.next
      rescue StandardError
        noun = nil
      end
      break unless noun
      @nouns << noun
    end

    @adjs = Queue.new
    loop do
      begin
        adj = RandomWord.adjs.next
      rescue StandardError
        adj = nil
      end
      break unless adj
      @adjs << adj
    end
  end
end

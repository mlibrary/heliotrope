# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RandomWords do
  subject(:random_words) { described_class.new }

  # Fails in Travis CI because multiple threads are required.
  xit { expect(random_words.noun).not_to be nil }
  xit { expect(random_words.adj).not_to be nil }
end

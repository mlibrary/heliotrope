require 'spec_helper'

class Example
  private def foo; end
end

describe Example do

  describe 'without the private shared context' do
    it 'cannot test private methods' do
      expect{subject.foo}.to raise_error NoMethodError
    end
  end

  describe 'with the private shared context', :private do
    it 'can test private methods' do
      expect{subject.foo}.not_to raise_error
    end
  end

end

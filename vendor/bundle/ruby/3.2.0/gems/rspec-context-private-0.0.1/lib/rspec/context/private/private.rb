RSpec.shared_context 'private', private: true do

  before :all do
    described_class.class_eval do
      @original_private_instance_methods = private_instance_methods
      public *@original_private_instance_methods
    end
  end

  after :all do
    described_class.class_eval do
      private *@original_private_instance_methods
    end
  end

end

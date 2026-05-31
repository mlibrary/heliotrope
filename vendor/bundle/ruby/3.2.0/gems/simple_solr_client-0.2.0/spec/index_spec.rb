require 'minitest_helper'

describe "Basic indexing/" do

  before do
    @core = TempCore.instance.core('index_spec')
    @core.clear
  end


  it "clears" do
    @core.number_of_documents.must_equal 0
  end

  it "adds" do
    @core.add_docs({:id=>1, :name_s=>"Bill"}).commit
    @core.number_of_documents.must_equal 1
  end

  it "deletes by query" do
    @core.add_docs({:id=>1, :name_s=>"Bill"})
    @core.add_docs({:id=>2, :name_s=>"Mike"})
    @core.commit
    @core.number_of_documents.must_equal 2
    @core.delete('name_s:Mike').commit
    @core.number_of_documents.must_equal 1
  end


end


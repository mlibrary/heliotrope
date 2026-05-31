require 'minitest_helper'

describe "Schema" do

  SS = SimpleSolrClient::Schema # convenience

  before do
    @core   = TempCore.instance.core('schema_spec')
    @schema = @core.schema
  end

  describe "the id field" do
    it "finds it" do
      @schema.field('id').name.must_equal 'id'
    end

    it "has a type name of string" do
      @schema.field('id').type_name.must_equal 'string'
    end

    it "has the string type" do
      @schema.field('id').type.must_equal @schema.field_type('string')
    end

    it "matches on exact match" do
      @schema.field('id').matches('id').must_equal true
    end

    it "doesn't match on inexact match" do
      @schema.field('id').matches('testid').must_equal false
    end

  end

  describe "the _i dynamic field" do
    it "finds it" do
      @schema.dynamic_field('*_i').wont_be_nil
    end

    it "has type int" do
      @schema.dynamic_field("*_i").type.must_equal @schema.field_type('int')
    end

    it 'matches appropriates' do
      dfield  = @schema.dynamic_field('*_i')
      dfield.matches('test_i').must_equal true
      dfield.matches('test_s_i').must_equal true
      dfield.matches('test_i_s').must_equal false
    end

    it "is found when looking for a match" do
      dfield  = @schema.dynamic_field('*_i')
      results = @schema.resulting_fields("year_i")
      results.size.must_equal 1
      results.first.type.must_equal dfield.type
    end

  end

  describe "add/delete field" do
    it "allows us to add a field" do
      @schema.add_field SS::Field.new(:name => 'new_field', :type_name => 'string')
      @schema.write
      @core.reload
      @schema.field('new_field').wont_be_nil
    end

    it "allows us to drop a field" do
      @schema.add_field SS::Field.new(:name => 'new_field', :type_name => 'string')
      @schema.write
      @core.reload
      @schema.field('new_field').wont_be_nil
      @schema.drop_field('new_field')
      @schema.write
      @schema = @core.reload.schema
      @schema.fields.map(&:name).wont_include 'new_field'
    end


  end

  describe 'Dynamic Fields' do
    it "adds a dfield" do
      @schema.add_dynamic_field SS::DynamicField.new(:name => '*_test_i', :type_name => 'string', :stored => true)
      @schema.write
      @schema = @core.reload.schema
      @schema.dynamic_field('*_test_i').wont_be_nil
    end

    it "prefers longer dfield names when determining resulting_fields" do
      @schema.add_dynamic_field SS::DynamicField.new(:name => '*_test_i', :type_name => 'string', :stored => true)
      @schema.write
      @schema = @core.reload.schema
      rf = @schema.resulting_fields('bill_test_i')
      rf.size.must_equal 1
      rf.first.type.name.must_equal 'string'
    end

    it "prefers explicity-defined fields to dynamic fields" do
      @schema.add_field SS::Field.new(:name=>'explicit_i', :type_name=>'string')
      @schema.write
      @schema = @core.reload.schema
      rf = @schema.resulting_fields('explicit_i')
      rf.size.must_equal 1
      rf.first.type.name.must_equal 'string'
    end


  end


end


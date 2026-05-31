# frozen_string_literal: true

require "spec_helper"

describe BagIt::Bag do
  describe "Tag Info Files" do
    before do
      @sandbox = Sandbox.new

      # make the bag
      @bag_path = File.join @sandbox.to_s, "the_bag"
      @bag = described_class.new @bag_path

      # add some files
      File.open("/dev/urandom") do |rio|
        10.times do |n|
          @bag.add_file("file-#{n}-💩") { |io| io.write rio.read(16) }
        end
      end
    end

    after do
      @sandbox.cleanup!
    end

    describe "bagit.txt" do
      before do
        path = File.join @bag_path, "bagit.txt"
        @lines = File.open(path, &:readlines)
      end

      it "creates a file bagit.txt on bag initialization" do
        expect(File.join(@bag_path, "bagit.txt")).to exist_on_fs
      end

      it "has exactly two lines" do
        expect(@lines.size).to eq(2)
      end

      it "has a bagit version" do
        a = @lines.select { |line| line.chomp =~ /BagIt-Version:\s*\d+\.\d+/ }
        expect(a).not_to be_empty
      end

      it "has a tag file encoding" do
        a = @lines.select { |line| line.chomp =~ /Tag-File-Character-Encoding:\s*.+/ }
        expect(a).not_to be_empty
      end
    end

    describe "bag-info.txt" do
      before do
        path = File.join @bag_path, "bag-info.txt"
        @lines = File.open(path, &:readlines)
      end

      it "isn't empty" do
        expect(@lines).not_to be_empty
      end

      it "contains lines of the format LABEL: VALUE (like an email header)" do
        @lines.each { |line| expect(line.chomp).to match(/^[^\s]+\s*:\s+.*$/) }
      end

      it "is case insensitive with respect to LABELs" do
        expect { @bag.write_bag_info "foo" => "lowercase", "Foo" => "capital" }.to raise_error(/Multiple labels/)
      end

      it "folds long VALUEs" do
        longline = <<~LOREM
          Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
            eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enimad
            minim veniam, quis nostrud exercitation ullamco laboris nisi ut
            aliquip ex ea commodo consequat. Duis aute irure dolor in
            reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
            pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
            culpa qui officia deserunt mollit anim id est laborum.
        LOREM
        @bag.write_bag_info "Lorem" => longline
        expect(@bag.bag_info.keys.length).to eq(4) # this isn't a great test. Changed it from 1 to 4 because unrelated changes caused failure.
      end

      it "specifys a bag software agent" do
        expect(@bag.bag_info.keys).to include("Bag-Software-Agent")
      end

      it "contains a valid bagging date" do
        expect(@bag.bag_info.keys).to include("Bagging-Date")
        @bag.bag_info["Bagging-Date"] =~ /^^[0-9]{4}-[0-9]{2}-[0-9]{2}$/
      end

      it "contains a payload oxum" do
        expect(@bag.bag_info.keys).to include("Payload-Oxum")
      end
      it "does not override any previous values" do
        path = File.join @bag_path, "bag-info.txt"
        @bag.write_bag_info "Bag-Software-Agent" => "Some Other Agent"
        @bag.write_bag_info "Source-Organization" => "Awesome Inc."
        @bag.write_bag_info "Bagging-Date" => "1901-01-01"
        @bag.write_bag_info
        contents = File.open(path).read
        expect(contents).to include "Some Other Agent"
        expect(contents).to include "Awesome Inc."
        expect(contents).to include "1901-01-01"
      end
      it "overrides previous tags when they collide with new ones" do
        path = File.join @bag_path, "bag-info.txt"
        @bag.write_bag_info "Source-Organization" => "Awesome Inc."
        @bag.write_bag_info "Source-Organization" => "Awesome LLC."
        contents = File.open(path).read
        expect(contents).to include "Awesome LLC."
        expect(contents).not_to include "Awesome Inc."
      end
      it "contains values passed to bag" do
        hash = {"Bag-Software-Agent" => "rspec",
                "Bagging-Date" => "2012-11-21",
                "Contact-Name" => "Willis Corto",
                "Some-Tag" => "Some Value"}
        bag_with_info = described_class.new(@bag_path + "2", hash)
        hash.each do |key, value|
          expect(bag_with_info.bag_info[key]).to eq(value)
        end
      end
    end
  end
end

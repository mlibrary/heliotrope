# frozen_string_literal: true

require "spec_helper"

describe BagIt::Bag do
  describe "Tag Specs" do
    before do
      @sandbox = Sandbox.new

      # make the bag
      @bag_path = File.join @sandbox.to_s, "the_bag"
      @bag = described_class.new(@bag_path)

      # add some files
      File.open("/dev/urandom") do |rio|
        10.times do |n|
          @bag.add_file("file-#{n}-💩") { |io| io.write rio.read(16) }
          @bag.add_tag_file("tag-#{n}") { |io| io.write rio.read(16) }
        end
      end
    end

    after do
      @sandbox.cleanup!
    end
    describe "#add_tag_file" do
      it "allows addition of tag files via io" do
        @bag.add_tag_file("foo") { |io| io.puts "all alone" }
        expect(File.join(@bag_path, "foo")).to exist_on_fs
      end
      it "allows addition of bag files within directories using io" do
        @bag.add_tag_file("fedora/foo") { |io| io.puts "all alone" }
        expect(File.join(@bag_path, "fedora", "foo")).to exist_on_fs
      end
      it "allows addition of deep tag files" do
        @bag.add_tag_file("fedora/foo/newfoo/deep") { |io| io.puts "woah that's deep" }
        expect(File.join(@bag_path, "fedora", "foo", "newfoo", "deep")).to exist_on_fs
      end
      it "does not allow overwriting of tag files" do
        expect { @bag.add_tag_file("tag-0") { |io| io.puts "overwrite!" } }.to raise_error(RuntimeError)
      end
      it "allows addition of tag files via copy" do
        src_path = File.join @sandbox.to_s, "somefile"
        File.open(src_path, "w") { |io| io.puts "something" }
        @bag.add_tag_file("foo", src_path) { |io| io.puts "all alone" }
        expect(File.join(@bag_path, "foo")).to exist_on_fs
      end
    end
    describe "#remove_tag_file" do
      it "raises an error when removing non existant files" do
        expect { @bag.remove_tag_file("file-x") }.to raise_error(RuntimeError)
      end
    end
    describe "#delete_tag_file" do
      it "raises an error when deleting non existant tag files" do
        expect { @bag.delete_tag_file("file-x") }.to raise_error(RuntimeError)
      end
    end
  end
end

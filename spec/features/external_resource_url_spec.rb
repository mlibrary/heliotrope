# frozen_string_literal: true

require 'rails_helper'

describe "external resource url" do
  subject { FileSet.new }

  it "deletes all whitespace in before_validation callback" do
    subject.external_resource_url = "\u00A0   https://www.example.com   \u00A0"
    subject.save!
    expect(subject.external_resource_url).to eq "https://www.example.com"
  end

  it "validates URLs" do
    subject.external_resource_url = "https://www.example.com"
    expect(subject.valid?).to eq true
    subject.external_resource_url = "blah-blah-stuff"
    expect(subject.valid?).to eq false
  end
end

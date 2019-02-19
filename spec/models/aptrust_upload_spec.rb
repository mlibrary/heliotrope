# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AptrustUpload, type: :model do
  subject { described_class.new(noid: "Anything", bag_status: 0, s3_status: 0, apt_status: 0) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is not valid without a noid" do
    subject.noid = nil
    expect(subject).not_to be_valid
  end

  it "is not valid without a bag_status" do
    subject.bag_status = nil
    expect(subject).not_to be_valid
  end

  it "is not valid without a s3_status" do
    subject.s3_status = nil
    expect(subject).not_to be_valid
  end

  it "is not valid without an apt_status" do
    subject.apt_status = nil
    expect(subject).not_to be_valid
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe Monograph do
  let(:monograph) { described_class.new }
  let(:date) { DateTime.now }
  let(:umich) { build(:press, subdomain: 'umich') }

  it "has date_published" do
    monograph.date_published = [date]
    expect(monograph.date_published).to eq [date]
  end

  it 'can set the press with a string' do
    monograph.press = umich.subdomain
    expect(monograph.press).to eq umich.subdomain
  end

  it 'must have a press' do
    mono = described_class.new
    expect(mono.valid?).to eq false
    expect(mono.errors.messages[:press]).to eq ['You must select a press.']
  end

  it "sets the creator field from creator_family_name, creator_given_name and contributor" do
    m = described_class.new
    m.creator_family_name = 'Man'
    m.creator_given_name = 'Rocket'
    m.contributor = ['Boop, Betty', 'Love, Thomas']
    # set title and press to pass save validation
    m.title = ["Ol' Timey Creator Settin' Test Monograph"]
    m.press = 'umich'
    m.save!
    expect(m.creator).to eq ['Man, Rocket', 'Boop, Betty', 'Love, Thomas']
  end

  it "sets the creator field from primary_editor_family_name, primary_editor_given_name and editor" do
    m = described_class.new
    m.primary_editor_family_name = 'Smith'
    m.primary_editor_given_name = 'John'
    m.editor = ['Sue, Peggy', 'Jones, Tom']
    # set title and press to pass save validation
    m.title = ["Ol' Timey Creator-from-editor-settin Test Monograph"]
    m.press = 'umich'
    m.save!
    expect(m.creator).to eq ['Smith, John', 'Sue, Peggy', 'Jones, Tom']
  end

  it "sets the creator field from combined creator/contributor/editor data, with creators first" do
    m = described_class.new
    m.creator_family_name = 'Man'
    m.creator_given_name = 'Rocket'
    m.contributor = ['Boop, Betty', 'Love, Thomas']
    m.primary_editor_family_name = 'Smith'
    m.primary_editor_given_name = 'John'
    m.editor = ['Sue, Peggy', 'Jones, Tom']
    # set title and press to pass save validation
    m.title = ["Ol' Timey Creator-from-heliotrope-creators-and-editors-settin Test Monograph"]
    m.press = 'umich'
    m.save!
    expect(m.creator).to eq ['Man, Rocket', 'Boop, Betty', 'Love, Thomas', 'Smith, John', 'Sue, Peggy', 'Jones, Tom']
  end
end

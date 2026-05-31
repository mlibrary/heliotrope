# frozen_string_literal: true
require "spec_helper"
describe ActiveTriples::Repositories do
  subject { ActiveTriples::Repositories }

  after(:each) do
    subject.clear_repositories!
    subject.add_repository :default, RDF::Repository.new
    subject.add_repository :vocabs, RDF::Repository.new
  end

  describe '#add_repositories' do
    it 'should accept a new repository' do
      subject.add_repository :name, RDF::Repository.new
      expect(subject.repositories).to include :name
    end

    it 'should throw an error if passed something that is not a repository' do
      expect{subject.add_repository :name, :not_a_repo}
        .to raise_error ArgumentError
    end
  end

  describe '#clear_repositories!' do
    it 'should empty the repositories list' do
      subject.clear_repositories!
      expect(subject.repositories).to be_empty
    end
  end

  describe '#has_subject?' do

    let(:resource2) do
      DummyResource2.new(2)
    end

    before do
      class DummyResource1
        include ActiveTriples::RDFSource
        configure :base_uri => "http://example.org/r1/",
                  :type => RDF::URI("http://example.org/SomeClass"),
                  :repository => :repo1
      end
      class DummyResource2
        include ActiveTriples::RDFSource
        configure :base_uri => "http://example.org/r2/",
                  :type => RDF::URI("http://example.org/SomeClass"),
                  :repository => :repo2
      end
      class DummyResource3
        include ActiveTriples::RDFSource
        configure :base_uri => "http://example.org/r3/",
                  :type => RDF::URI("http://example.org/SomeClass"),
                  :repository => :repo3
      end
      ActiveTriples::Repositories.add_repository :repo1, RDF::Repository.new
      ActiveTriples::Repositories.add_repository :repo2, RDF::Repository.new
      ActiveTriples::Repositories.add_repository :repo3, RDF::Repository.new

      DummyResource1.new('1').persist!
      DummyResource2.new('2').persist!
      DummyResource3.new('3').persist!

    end
    after do
      DummyResource1.new('1').destroy!
      DummyResource2.new('2').destroy!
      DummyResource3.new('3').destroy!

      Object.send(:remove_const, "DummyResource1") if Object
      Object.send(:remove_const, "DummyResource2") if Object
      Object.send(:remove_const, "DummyResource3") if Object
      ActiveTriples::Repositories.clear_repositories!
    end

    context 'when checking only one named repository' do
      context 'and rdf_subject exists in the repository' do
        it 'should return true' do
          expect(ActiveTriples::Repositories
                  .has_subject?(resource2.rdf_subject,:repo2))
            .to be_truthy
        end
      end

      context 'and rdf_subject exists in another repository' do
        it 'should return false' do
          expect(ActiveTriples::Repositories
                  .has_subject?(resource2.rdf_subject,:repo1))
            .to be_falsey
        end
      end

      context 'and rdf_subject does not exists in any repository' do
        it 'should return false' do
          expect(ActiveTriples::Repositories
                  .has_subject?("#{resource2.rdf_subject}_NOEXIST",:repo1))
            .to be_falsey
        end
      end
    end

    context 'when checking all repositories' do
      context 'and rdf_subject exists in one repository' do
        it 'should return true' do
          expect(ActiveTriples::Repositories
                  .has_subject?(resource2.rdf_subject))
            .to be_truthy
        end
      end

      context 'and rdf_subject does not exists in any repository' do
        it 'should return false' do
          expect(ActiveTriples::Repositories
                  .has_subject?("#{resource2.rdf_subject}_NOEXIST"))
            .to be_falsey
        end
      end
    end
  end
end

require 'spec_helper'

describe Ldp::Resource do
  subject { Ldp::Resource.new(mock_client, path) }

  let(:conn_stubs) do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.head('/bad_request_resource') { [400] }  # HEAD requests do not have message bodies.
      stub.get('/bad_request_resource') { [400, {}, "The namespace prefix (fooooooo) has not been registered"] }
      stub.head('/not_found_resource') { [404] }
      stub.get('/not_found_resource') { [404] }
      stub.head('/a_new_resource') { [404] }
      stub.head('/a_resource') { [200] }
      stub.get('/a_resource') { [200] }
    end
  end

  let(:mock_conn) do
    test = Faraday.new do |builder|
      builder.adapter :test, conn_stubs do |stub|
      end
    end
  end

  let :mock_client do
    Ldp::Client.new mock_conn
  end

  describe "#get" do
    context "when the resource is not in repository" do
      let(:path) { '/not_found_resource' }
      it "should raise an error" do
        expect{ subject.get }.to raise_error Ldp::NotFound
      end
    end
    context "when the request is bad" do
      let(:path) { '/bad_request_resource' }
      it "should return a meaningful error message" do
        # Ensures that failed head requests rerun as a GET request in order to get a meaningful error message
        expect{ subject.head }.to raise_error Ldp::BadRequest, "The namespace prefix (fooooooo) has not been registered"
      end
      it "should raise an error with error message" do
        expect{ subject.get }.to raise_error Ldp::BadRequest, "The namespace prefix (fooooooo) has not been registered"
      end
    end

    context "when the resource is in the repository" do
      let(:path) { '/a_resource' }
      it "should get the response" do
        expect(subject.get).to be_kind_of Ldp::Response
      end
    end
  end

  describe "#new?" do
    context "with an object not in the repository" do
      let(:path) { '/not_found_resource' }
      it "should be true" do
        expect(subject).to be_new
      end
    end

    context "with an object in the repository" do
      let(:path) { '/a_resource' }
      it "should be false" do
        expect(subject).to_not be_new
      end
    end
  end

  describe "#head" do
    context "with an object not in the repository" do
      let(:path) { '/not_found_resource' }
      it "should be true" do
        expect(subject.head).to eq Ldp::None
      end

      it "should cache requests" do
        expect(subject.client).to receive(:head).and_raise(Ldp::NotFound).once
        2.times { subject.head }
      end
    end
  end

  describe "#create" do
    let(:path) { '/a_new_resource' }
    context "with a subject uri" do
      let(:conn_stubs) do
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.head(path) { [404] }
          stub.put(path) { [200, {'Last-Modified' => 'Tue, 22 Jul 2014 02:23:32 GMT' }] }
        end
      end

      context "and without a base path" do
        it "should post an RDF graph" do
          subject.content = "xyz"
          subject.save
        end
      end

      context "and with a base path" do
        let(:base_path) { '/foo' }

        subject { Ldp::Resource.new(mock_client, path, nil, base_path) }

        it "should ignore the base path" do
          subject.content = "xyz"
          subject.save
        end
      end
    end

    context "without a subject" do
      context "and with a base path" do
        let(:base_path) { '/foo' }

        let(:conn_stubs) do
          Faraday::Adapter::Test::Stubs.new do |stub|
            stub.post(base_path) { [200, {'Last-Modified' => 'Tue, 22 Jul 2014 02:23:32 GMT' }] }
          end
        end

        subject { Ldp::Resource.new(mock_client, nil, nil, base_path) }

        it "should post an RDF graph" do
          subject.content = "xyz"
          subject.save
        end
      end

    end
  end

  describe "#update" do
    let(:path) { '/a_new_resource' }
    let(:conn_stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.put(path, nil, {'Content-Type' => 'application/xml', "Content-Length"=>"0" }) { [200] }
      end
    end

    it "should pass headers" do
      subject.update do |req|
        req.headers = {'Content-Type' => 'application/xml' }
      end
    end
  end
end

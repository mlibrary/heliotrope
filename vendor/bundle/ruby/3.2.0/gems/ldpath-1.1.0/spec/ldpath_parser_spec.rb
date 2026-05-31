require 'spec_helper'
require 'pp'
require 'parslet/convenience'
describe Ldpath::Parser do
  subject { Ldpath::Parser.new }
  context ".parse" do
    describe "doc" do
      it "should parse line-oriented data" do
        subject.doc.parse " \n \n"
      end
    end

    describe "eol" do
      it 'may be a \n character' do
        subject.eol.parse("\n")
      end

      it 'may be a \n\r' do
        subject.eol.parse("\n\r")
      end
    end

    describe "eof" do
      it "is the eof" do
        subject.eof.parse ""
      end
    end

    describe "wsp" do
      it "may be a space" do
        subject.wsp.parse " "
      end

      it "may be a tab" do
        subject.wsp.parse "\t"
      end

      it "may be a multiline comment" do
        subject.wsp.parse "/* xyz */"
      end

      it "may be a single line comment" do
        subject.wsp.parse "# xyz"
      end
    end

    describe "directive" do
      it "may be a namespace declaration" do
        subject.directive.parse "@prefix x : <info:x> ;"
      end

      it "may be a graph" do
        subject.directive.parse "@graph test:context, foo:ctx, test:bar ;"
      end

      it "may be a filter" do
        subject.directive.parse "@filter is-a test:Context ;"
      end
    end

    describe "prefixID" do
      it "should parse prefix mappings" do
        subject.prefixID.parse "@prefix x : <info:x> ;"
      end

      it "should parse the null prefix" do
        subject.prefixID.parse "@prefix : <info:x> ;"
      end
    end

    describe "statement" do
      it "may be a mapping" do
        subject.statement.parse "id = . ;"
      end
    end

    describe "iri" do
      it "may be an iriref" do
        result = subject.iri.parse "<info:x>"
        expect(result[:iri]).to eq "info:x"
      end

      it "may be a prefixed name" do
        result = subject.iri.parse "info:x"
        expect(result[:iri][:prefix]).to eq "info"
        expect(result[:iri][:localName]).to eq "x"
      end
    end

    describe "identifier" do
      it "must start with an alphanumeric character" do
        subject.identifier.parse "a"
        subject.identifier.parse "J"
      end

      it "may have additional alphanumeric characters" do
        subject.identifier.parse "aJ0_.-"
      end

      it "may not end in a dot" do
        expect { subject.identifier.parse "aJ0_.-." }.to raise_error
      end
    end

    describe "string" do
      it "is the content between \"" do
        subject.string.parse '"abc"'
      end

      it "should handle escaped characters" do
        subject.string.parse '"a\"b"'
      end

      it "should handle single quoted strings" do
        subject.string.parse "'abc'"
      end

      it "should handle long strings" do
        str = <<-EOF
          """
           xyz
          """
        EOF

        subject.string.parse str.strip
      end

      it "should handle long single-quoted strings" do
        str = <<-EOF
          '''
           xyz
          '''
        EOF

        subject.string.parse str.strip
      end
    end

    describe "node" do
      it "may be a uri" do
        subject.node.parse "info:x"
      end

      it "may be a literal" do
        subject.node.parse '"a"'
      end

      it "may be a typed literal" do
        subject.node.parse '"a"^^info:x'
      end

      it "may be a language literal" do
        subject.node.parse '"a"@en'
      end

      it "may be a numeric literal" do
        subject.node.parse '123'
      end

      it "may be a decimal literal" do
        subject.decimal.parse '0.123'
      end

      it "may be a boolean literal" do
        subject.node.parse 'true'
      end
    end

    describe "selectors" do
      it "should parse mappings" do
        subject.parse("xyz = . ;\n")
      end

      it "should parse wildcards" do
        subject.parse("xyz = * ;\n")
      end

      it "should parse reverse properties" do
        subject.parse("xyz = ^info:a ;\n")
      end

      it "should parse uri mappings" do
        subject.parse("xyz = <info:a> ;\n")
      end

      it "should parse path mappings" do
        subject.mapping.parse("xyz = info:a / info:b :: a:b;")
      end

      it "should parse path selectors" do
        subject.selector.parse("info:a / info:b")
      end

      it "recursive_path_selector" do
        subject.recursive_path_selector.parse("(foo:go)*")
      end

      it "function_selector" do
        subject.selector.parse('fn:concat(foaf:givename," ",foaf:surname)')
      end

      it "tap_selector" do
        subject.selector.parse('?<__autocomplete>fn:predicates()')
      end

      it "loose_selector" do
        subject.selector.parse('~<info:a>')
      end

      it "negated property selector" do
        subject.selector.parse('!<info:a>')
      end
    end

    describe "tests" do
      it "should pass a simple property test" do
        subject.selector.parse('.[info:a]')
      end

      it "should pass a property test with '&'" do
        subject.selector.parse('.[info:a & info:b]')
      end

      it "should pass a property test with '|'" do
        subject.selector.parse('.[info:a | info:b]')
      end
    end

    describe "integration tests" do
      it "should parse a simple example" do
        tree = subject.parse <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
topic = <http://xmlns.com/foaf/0.1/primaryTopic> :: xsd:string ;
EOF
        expect(tree.length).to eq 2
        expect(tree.first).to include :prefixID
        expect(tree.first[:prefixID]).to include id: 'dcterms'
        expect(tree.first[:prefixID]).to include iri: 'http://purl.org/dc/terms/'
        expect(tree.last).to include :mapping
        expect(tree.last[:mapping]).to include name: 'topic'
        expect(tree.last[:mapping]).to include :selector
      end

      it "should parse the foaf example" do
        subject.parse File.read(File.expand_path(File.join(__FILE__, "..", "fixtures", "foaf_example.program")))
      end

      it "should parse the program.ldpath" do
        subject.parse File.read(File.expand_path(File.join(__FILE__, "..", "fixtures", "program.ldpath")))
      end

      it "should parse the namespaces.ldpath" do
        subject.parse File.read(File.expand_path(File.join(__FILE__, "..", "fixtures", "namespaces.ldpath")))
      end
    end
  end
end

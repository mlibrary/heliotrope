# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ObjectLookupService do
  describe '#clean_isbns' do
    context "ISBN parameter contains a single ISBN" do
      let(:isbn) { '978-0-307-80123-1 (ebook)' }
      it 'extracts the clean/numeric ISBN value' do
        expect(described_class.clean_isbns(isbn)).to eq(['9780307801231'])
      end
    end

    context "ISBN parameter contains several ISBNs" do
      let(:isbn) { '978-0-307-80123-1 (ebook); 978-0-307-80123-2 (paper); 978-0-307-80123-3 (hardcover)' }

      it 'extracts all of the clean/numeric ISBNs' do
        expect(described_class.clean_isbns(isbn)).to eq(['9780307801231', '9780307801232', '9780307801233'])
      end
    end
  end

  context 'object-finding methods' do
    let(:file_set) { create(:file_set, id: '000000000') }
    let!(:michigan_monograph) { create(:monograph, id: '111111111', press: 'michigan',
                                      isbn: ['978-0-307-80123-1 (ebook)',
                                             '978-0-307-80123-2 (paper)']) }
    let!(:heb_monograph) { create(:monograph, id: '222222222', press: 'heb', identifier: ['heb_id: heb11111.0001.001'],
                                 isbn: ['978-0-307-80123-1 (ebook)',
                                        '978-0-307-80123-2 (paper)',
                                        '978-0-307-80123-3 (hardcover)']) }
    # Monographs will be found using the cleaned value in `identifier_ssim` regardless of whitespace and namespacing
    let!(:heb_monograph_no_space_in_heb_id_namespace) { create(:monograph, id: '333333333', press: 'heb',
                                                               identifier: ['heb_id:heb22222.0001.001']) }

    describe '#matches_for_csv_row' do
      context 'matches by NOID' do
        it 'can match nothing' do
          matches, identifier_used = described_class.matches_for_csv_row(CSV::Row.new(['NOID'], ['blah']))
          expect(matches.count).to eq(0)
          expect(identifier_used).to eq('NOID')
        end

        it 'can match a distinct FileSet' do
          matches, identifier_used = described_class.matches_for_csv_row(CSV::Row.new(['NOID'], [file_set.id]))
          expect(matches.count).to eq(1)
          expect(matches.first).to eq(file_set)
          expect(identifier_used).to eq('NOID')
        end

        it 'can match a distinct Monograph' do
          matches, identifier_used = described_class.matches_for_csv_row(CSV::Row.new(['NOID'], [michigan_monograph.id]))
          expect(matches.count).to eq(1)
          expect(matches.first).to eq(michigan_monograph)
          expect(identifier_used).to eq('NOID')
        end
      end

      context "matches by Identifier (HEB ID) within Press 'heb'" do
        it 'can match nothing' do
          matches, identifier_used = described_class.matches_for_csv_row(CSV::Row.new(['Press', 'Identifier(s)'], ['heb', 'heb_id: heb99999.0001.001']))
          expect(matches.count).to eq(0)
          expect(identifier_used).to eq('HEB IDs heb99999.0001.001')
        end

        it "will match a Monograph even if the `heb_id:` namespace is not followed by a space" do
          matches, identifier_used = described_class.matches_for_csv_row(CSV::Row.new(['Press', 'Identifier(s)'], ['heb', 'heb_id: heb22222.0001.001']))
          expect(matches.count).to eq(1)
          expect(identifier_used).to eq('HEB IDs heb22222.0001.001')
        end

        it 'can match a distinct Monograph' do
          matches, identifier_used = described_class.matches_for_csv_row(CSV::Row.new(['Press', 'Identifier(s)'], ['heb', 'heb_id: heb11111.0001.001']))
          expect(matches.count).to eq(1)
          expect(matches.first).to eq(heb_monograph)
          expect(identifier_used).to eq('HEB IDs heb11111.0001.001')
        end
      end

      describe 'matches by ISBN(s)' do
        context 'with a Press provided' do
          it 'can match nothing' do
            matches, identifier_used = described_class.matches_for_csv_row(CSV::Row.new(['Press', 'ISBN(s)'], ['heb', '978-0-307-80123-9']))
            expect(matches.count).to eq(0)
            expect(identifier_used).to eq("ISBN(s) 9780307801239, restricted to Press 'heb'")
          end

          it 'can match a distinct Monograph' do
            matches, identifier_used = described_class.matches_for_csv_row(CSV::Row.new(['Press', 'ISBN(s)'], ['heb', '978-0-307-80123-1']))
            expect(matches.count).to eq(1)
            expect(matches.first).to eq(heb_monograph)
            expect(identifier_used).to eq("ISBN(s) 9780307801231, restricted to Press 'heb'")
          end
        end

        context 'with no Press provided' do
          it 'can match nothing' do
            matches, identifier_used = described_class.matches_for_csv_row(CSV::Row.new(['ISBN(s)'], ['978-0-307-80123-9']))
            expect(matches.count).to eq(0)
            expect(identifier_used).to eq("ISBN(s) 9780307801239")
          end

          it 'can match multiple ISBN-sharing Monographs across Presses' do
            matches, identifier_used = described_class.matches_for_csv_row(CSV::Row.new(['ISBN(s)'], ['978-0-307-80123-1']))
            expect(matches.count).to eq(2)
            expect(matches).to contain_exactly(heb_monograph, michigan_monograph)
            expect(identifier_used).to eq("ISBN(s) 9780307801231")
          end
        end
      end

      context 'no useful identifier on row' do
        it 'returns no results' do
          matches, identifier_used = described_class.matches_for_csv_row(CSV::Row.new(['blah'], ['blah']))
          expect(matches.count).to eq(0)
          expect(identifier_used).to eq('no suitable identifier found')
        end
      end
    end

    describe '#matches' do
      context 'matches by NOID' do
        it 'can match nothing' do
          matches = described_class.matches('blahblah0')
          expect(matches.count).to eq(0)
        end

        it 'can match FileSets' do
          matches = described_class.matches(file_set.id)
          expect(matches.count).to eq(1)
          expect(matches.first).to eq(file_set)
        end

        it 'can match a distinct Monograph' do
          matches = described_class.matches(michigan_monograph.id)
          expect(matches.count).to eq(1)
          expect(matches.first).to eq(michigan_monograph)
        end
      end

      context "matches by Identifier (HEB ID) within Press 'heb'" do
        it 'can match nothing' do
          matches = described_class.matches('heb99999.0001.001')
          expect(matches.count).to eq(0)
        end

        it "will match a Monograph even if the `heb_id:` namespace is not followed by a space" do
          matches = described_class.matches('heb22222.0001.001')
          expect(matches.count).to eq(1)
        end

        it 'can match a distinct Monograph' do
          matches = described_class.matches('heb11111.0001.001')
          expect(matches.count).to eq(1)
          expect(matches.first).to eq(heb_monograph)
        end
      end

      context 'matches by ISBN(s)' do
        context 'with a Press provided' do
          it 'can match nothing' do
            matches = described_class.matches('978-0-307-80123-9', 'michigan')
            expect(matches.count).to eq(0)
          end

          it 'can match a distinct Monograph with dashes in the ISBN' do
            matches = described_class.matches('978-0-307-80123-1', 'michigan')
            expect(matches.count).to eq(1)
            expect(matches.first).to eq(michigan_monograph)
          end

          it 'can match a distinct Monograph with a typical ISBN-named file' do
            matches = described_class.matches('9780307801231_cover_image.jpg', 'michigan')
            expect(matches.count).to eq(1)
            expect(matches.first).to eq(michigan_monograph)
          end
        end

        context 'with no Press provided' do
          it 'can match nothing' do
            matches = described_class.matches('978-0-307-80123-9')
            expect(matches.count).to eq(0)
          end

          it 'can return multiple matches when ISBNs are shared across presses' do
            matches = described_class.matches('978-0-307-80123-1')
            expect(matches.count).to eq(2)
            expect(matches).to contain_exactly(heb_monograph, michigan_monograph)
          end

          it 'can match Monographs when passed a typical ISBN-named file' do
            matches = described_class.matches('9780307801231_cover_image.jpg')
            expect(matches.count).to eq(2)
            expect(matches.first).to eq(michigan_monograph)
          end
        end
      end
    end
  end
end

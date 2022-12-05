# frozen_string_literal: true

require 'rails_helper'
require 'import'

describe Import::Importer do
  let(:public_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:private_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
  let(:press) { create(:press, subdomain: 'umich') }
  let(:importer) { described_class.new(root_dir: root_dir, press: press.subdomain, visibility: importer_visibility,
                                       monograph_id: reimport_monograph_id, quiet: true) }

  before do
    # Don't print status messages during specs
    allow($stdout).to receive(:puts)
  end

  describe '#run' do
    before do
      stub_out_redis
    end

    describe "Object visibility (publication status) when importing a new Monograph" do
      let(:reimport_monograph_id) { nil }

      context "No 'Published?' column present in CSV" do
        let(:root_dir) { File.join(fixture_path, 'csv', 'import_visibility', 'importing', 'no_visibility_column') }

        context "No visibility set on importer object" do
          let(:importer_visibility) { nil }

          it "imports the monograph and FileSet with the default private visibility" do
            expect { importer.run }
              .to change(Monograph, :count)
                    .by(1)
                    .and(change(FileSet, :count)
                           .by(8))

            monograph = Monograph.first
            f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

            expect(monograph.title).to eq ["Non Visibility Settin’ CSV Monograph"]
            expect(monograph.visibility).to eq 'restricted'
            expect(f1.visibility).to eq 'restricted'
            expect(f2.visibility).to eq 'restricted'
            expect(f3.visibility).to eq 'restricted'
            expect(f4.visibility).to eq 'restricted'
            expect(f5.visibility).to eq 'restricted'
            expect(f6.visibility).to eq 'restricted'
            expect(f7.visibility).to eq 'restricted'
            expect(f8.visibility).to eq 'restricted'
          end
        end

        context "Public visibility set on importer object" do
          let(:importer_visibility) { public_vis }

          it "imports the monograph and FileSet with the requested public visibility" do
            expect { importer.run }
              .to change(Monograph, :count)
                    .by(1)
                    .and(change(FileSet, :count)
                           .by(8))

            monograph = Monograph.first
            f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

            expect(monograph.title).to eq ["Non Visibility Settin’ CSV Monograph"]
            expect(monograph.visibility).to eq 'open'
            expect(f1.visibility).to eq 'open'
            expect(f2.visibility).to eq 'open'
            expect(f3.visibility).to eq 'open'
            expect(f4.visibility).to eq 'open'
            expect(f5.visibility).to eq 'open'
            expect(f6.visibility).to eq 'open'
            expect(f7.visibility).to eq 'open'
            expect(f8.visibility).to eq 'open'
          end
        end

        context "Private visibility set on importer object" do
          let(:importer_visibility) { private_vis }

          it "imports the monograph and FileSet with the requested private visibility" do
            expect { importer.run }
              .to change(Monograph, :count)
                    .by(1)
                    .and(change(FileSet, :count)
                           .by(8))

            monograph = Monograph.first
            f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

            expect(monograph.title).to eq ["Non Visibility Settin’ CSV Monograph"]
            expect(monograph.visibility).to eq 'restricted'
            expect(f1.visibility).to eq 'restricted'
            expect(f2.visibility).to eq 'restricted'
            expect(f3.visibility).to eq 'restricted'
            expect(f4.visibility).to eq 'restricted'
            expect(f5.visibility).to eq 'restricted'
            expect(f6.visibility).to eq 'restricted'
            expect(f7.visibility).to eq 'restricted'
            expect(f8.visibility).to eq 'restricted'
          end
        end
      end

      context "'Published?' column present in CSV" do
        context 'Monograph is marked as published in CSV' do
          let(:root_dir) { File.join(fixture_path, 'csv', 'import_visibility', 'importing', 'visibility_column', 'published_monograph') }

          # For easier reference, CSV values look like this:
          #
          # File Name,	       Title,	                           External Resource URL,	Published?
          # ://:MONOGRAPH://:, Visibility Settin’ CSV Monograph,		                    true
          #                  , External Resource FileSet 1,	     http://www.blah.com/1,	true
          #                  , External Resource FileSet 2,	     http://www.blah.com/2,	true
          #                  , External Resource FileSet 3,	     http://www.blah.com/3,	blah
          #                  , External Resource FileSet 4,	     http://www.blah.com/4,	false
          #                  , External Resource FileSet 5,	     http://www.blah.com/5,	false
          #                  , External Resource FileSet 6,	     http://www.blah.com/6,
          #                  , External Resource FileSet 7,	     http://www.blah.com/7, false
          #                  , External Resource FileSet 8,	     http://www.blah.com/8,	true

          context "No visibility set on importer object" do
            let(:importer_visibility) { nil }

            it "imports the monograph and FileSet with the correct visibility" do
              expect { importer.run }
                .to change(Monograph, :count)
                      .by(1)
                      .and(change(FileSet, :count)
                             .by(8))

              monograph = Monograph.first
              f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

              expect(monograph.title).to eq ["Visibility Settin’ CSV Monograph"]
              expect(monograph.visibility).to eq 'open'
              expect(f1.visibility).to eq 'open'
              expect(f2.visibility).to eq 'open'
              expect(f3.visibility).to eq 'open' # 'blah' was discarded by RowData.field_values() and thus the Monograph's visibility was used, as is usual...
              # see https://github.com/mlibrary/heliotrope/blob/da67ef66a7de84065be6953a39d7122a529248c7/app/overrides/hyrax/file_set_ordered_members_actor_overrides.rb#L14
              expect(f4.visibility).to eq 'restricted'
              expect(f5.visibility).to eq 'restricted'
              expect(f6.visibility).to eq 'open' # same treatment as 'blah' above, and all instances where the FileSet attributes contain no visibility keys
              expect(f7.visibility).to eq 'restricted'
              expect(f8.visibility).to eq 'open'
            end
          end

          context "Public visibility set on importer object" do
            let(:importer_visibility) { public_vis }

            it "imports the monograph and FileSet with the correct visibility" do
              expect { importer.run }
                .to change(Monograph, :count)
                      .by(1)
                      .and(change(FileSet, :count)
                             .by(8))

              monograph = Monograph.first
              f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

              expect(monograph.title).to eq ["Visibility Settin’ CSV Monograph"]
              expect(monograph.visibility).to eq 'open'
              expect(f1.visibility).to eq 'open'
              expect(f2.visibility).to eq 'open'
              expect(f3.visibility).to eq 'open'
              expect(f4.visibility).to eq 'open'
              expect(f5.visibility).to eq 'open'
              expect(f6.visibility).to eq 'open'
              expect(f7.visibility).to eq 'open'
              expect(f8.visibility).to eq 'open'
            end
          end

          context "Private visibility set on importer object" do
            let(:importer_visibility) { private_vis }

            it "imports the monograph and FileSet with the correct visibility" do
              expect { importer.run }
                .to change(Monograph, :count)
                      .by(1)
                      .and(change(FileSet, :count)
                             .by(8))

              monograph = Monograph.first
              f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

              expect(monograph.title).to eq ["Visibility Settin’ CSV Monograph"]
              expect(monograph.visibility).to eq 'restricted'
              expect(f1.visibility).to eq 'restricted'
              expect(f2.visibility).to eq 'restricted'
              expect(f3.visibility).to eq 'restricted'
              expect(f4.visibility).to eq 'restricted'
              expect(f5.visibility).to eq 'restricted'
              expect(f6.visibility).to eq 'restricted'
              expect(f7.visibility).to eq 'restricted'
              expect(f8.visibility).to eq 'restricted'
            end
          end
        end

        context 'Monograph is marked as draft in CSV' do
          let(:root_dir) { File.join(fixture_path, 'csv', 'import_visibility', 'importing', 'visibility_column', 'draft_monograph') }

          # For easier reference, CSV values look like this:
          #
          # File Name,	       Title,	                           External Resource URL,	Published?
          # ://:MONOGRAPH://:, Visibility Settin’ CSV Monograph,		                    false
          #                  , External Resource FileSet 1,	     http://www.blah.com/1,	true
          #                  , External Resource FileSet 2,	     http://www.blah.com/2,	true
          #                  , External Resource FileSet 3,	     http://www.blah.com/3,	blah
          #                  , External Resource FileSet 4,	     http://www.blah.com/4,	false
          #                  , External Resource FileSet 5,	     http://www.blah.com/5,	false
          #                  , External Resource FileSet 6,	     http://www.blah.com/6,
          #                  , External Resource FileSet 7,	     http://www.blah.com/7, false
          #                  , External Resource FileSet 8,	     http://www.blah.com/8,	true

          context "No visibility set on importer object" do
            let(:importer_visibility) { nil }

            it "imports the monograph and FileSet with the correct visibility" do
              expect { importer.run }
                .to change(Monograph, :count)
                      .by(1)
                      .and(change(FileSet, :count)
                             .by(8))

              monograph = Monograph.first
              f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

              expect(monograph.title).to eq ["Visibility Settin’ CSV Monograph"]
              expect(monograph.visibility).to eq 'restricted'
              expect(f1.visibility).to eq 'open'
              expect(f2.visibility).to eq 'open'
              expect(f3.visibility).to eq 'restricted' # 'blah' was discarded by RowData.field_values() and thus the Monograph's visibility was used, as is usual...
              # see https://github.com/mlibrary/heliotrope/blob/da67ef66a7de84065be6953a39d7122a529248c7/app/overrides/hyrax/file_set_ordered_members_actor_overrides.rb#L14
              expect(f4.visibility).to eq 'restricted'
              expect(f5.visibility).to eq 'restricted'
              expect(f6.visibility).to eq 'restricted' # same treatment as 'blah' above, and all instances where the FileSet attributes contain no visibility keys
              expect(f7.visibility).to eq 'restricted'
              expect(f8.visibility).to eq 'open'
            end
          end

          context "Public visibility set on importer object" do
            let(:importer_visibility) { public_vis }

            it "imports the monograph and FileSet with the correct visibility" do
              expect { importer.run }
                .to change(Monograph, :count)
                      .by(1)
                      .and(change(FileSet, :count)
                             .by(8))

              monograph = Monograph.first
              f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

              expect(monograph.title).to eq ["Visibility Settin’ CSV Monograph"]
              expect(monograph.visibility).to eq 'open'
              expect(f1.visibility).to eq 'open'
              expect(f2.visibility).to eq 'open'
              expect(f3.visibility).to eq 'open'
              expect(f4.visibility).to eq 'open'
              expect(f5.visibility).to eq 'open'
              expect(f6.visibility).to eq 'open'
              expect(f7.visibility).to eq 'open'
              expect(f8.visibility).to eq 'open'
            end
          end

          context "Private visibility set on importer object" do
            let(:importer_visibility) { private_vis }

            it "imports the monograph and FileSet with the correct visibility" do
              expect { importer.run }
                .to change(Monograph, :count)
                      .by(1)
                      .and(change(FileSet, :count)
                             .by(8))

              monograph = Monograph.first
              f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

              expect(monograph.title).to eq ["Visibility Settin’ CSV Monograph"]
              expect(monograph.visibility).to eq 'restricted'
              expect(f1.visibility).to eq 'restricted'
              expect(f2.visibility).to eq 'restricted'
              expect(f3.visibility).to eq 'restricted'
              expect(f4.visibility).to eq 'restricted'
              expect(f5.visibility).to eq 'restricted'
              expect(f6.visibility).to eq 'restricted'
              expect(f7.visibility).to eq 'restricted'
              expect(f8.visibility).to eq 'restricted'
            end
          end
        end
      end
    end

    describe "Object visibility (publication status) when 'reimporting' to an existing Monograph" do
      let(:reimport_monograph) { create(:monograph, title: ['Blah'], press: 'umich', visibility: reimport_monograph_visibility) }
      let(:reimport_monograph_id) { reimport_monograph.id }

      before do
        # trigger the let so Monograph to import to isn't created with each `importer.run`
        reimport_monograph
      end

      context "No 'Published?' column present in CSV" do
        let(:root_dir) { File.join(fixture_path, 'csv', 'import_visibility', 'reimporting', 'no_visibility_column') }

        context "No visibility set on importer object" do
          let(:importer_visibility) { nil }
          let(:reimport_monograph_visibility) { public_vis }

          it "imports the Monograph and FileSets with the existing Monograph's visibility" do
            expect { importer.run }
              .to change(Monograph, :count)
                    .by(0)
                    .and(change(FileSet, :count)
                           .by(8))

            monograph = Monograph.first
            f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

            expect(monograph.title).to eq ['Blah']
            expect(monograph.visibility).to eq 'open'
            expect(f1.visibility).to eq 'open'
            expect(f2.visibility).to eq 'open'
            expect(f3.visibility).to eq 'open'
            expect(f4.visibility).to eq 'open'
            expect(f5.visibility).to eq 'open'
            expect(f6.visibility).to eq 'open'
            expect(f7.visibility).to eq 'open'
            expect(f8.visibility).to eq 'open'
          end
        end

        context "Public visibility set on importer object" do
          let(:importer_visibility) { public_vis }
          let(:reimport_monograph_visibility) { private_vis }

          it "imports the Monograph and FileSets with the existing Monograph's visibility" do
            expect { importer.run }
              .to change(Monograph, :count)
                    .by(0)
                    .and(change(FileSet, :count)
                           .by(8))

            monograph = Monograph.first
            f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

            expect(monograph.title).to eq ['Blah']
            expect(monograph.visibility).to eq 'restricted'
            expect(f1.visibility).to eq 'restricted'
            expect(f2.visibility).to eq 'restricted'
            expect(f3.visibility).to eq 'restricted'
            expect(f4.visibility).to eq 'restricted'
            expect(f5.visibility).to eq 'restricted'
            expect(f6.visibility).to eq 'restricted'
            expect(f7.visibility).to eq 'restricted'
            expect(f8.visibility).to eq 'restricted'
          end
        end

        context "Private visibility set on importer object" do
          let(:importer_visibility) { private_vis }
          let(:reimport_monograph_visibility) { public_vis }

          it "imports the Monograph and FileSets with the existing Monograph's visibility" do
            expect { importer.run }
              .to change(Monograph, :count)
                    .by(0)
                    .and(change(FileSet, :count)
                           .by(8))

            monograph = Monograph.first
            f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

            expect(monograph.title).to eq ['Blah']
            expect(monograph.visibility).to eq 'open'
            expect(f1.visibility).to eq 'open'
            expect(f2.visibility).to eq 'open'
            expect(f3.visibility).to eq 'open'
            expect(f4.visibility).to eq 'open'
            expect(f5.visibility).to eq 'open'
            expect(f6.visibility).to eq 'open'
            expect(f7.visibility).to eq 'open'
            expect(f8.visibility).to eq 'open'
          end
        end
      end

      context "'Published?' column present in CSV" do
        context 'Monograph is marked as published in CSV' do
          let(:root_dir) { File.join(fixture_path, 'csv', 'import_visibility', 'reimporting', 'visibility_column', 'published_monograph') }

          # For easier reference, CSV values look like this:
          #
          # File Name,	       Title,	                           External Resource URL,	Published?
          # ://:MONOGRAPH://:, Visibility Settin’ CSV Monograph,		                    true
          #                  , External Resource FileSet 1,	     http://www.blah.com/1,	true
          #                  , External Resource FileSet 2,	     http://www.blah.com/2,	true
          #                  , External Resource FileSet 3,	     http://www.blah.com/3,	blah
          #                  , External Resource FileSet 4,	     http://www.blah.com/4,	false
          #                  , External Resource FileSet 5,	     http://www.blah.com/5,	false
          #                  , External Resource FileSet 6,	     http://www.blah.com/6,
          #                  , External Resource FileSet 7,	     http://www.blah.com/7, false
          #                  , External Resource FileSet 8,	     http://www.blah.com/8,	true

          context "No visibility set on importer object" do
            let(:importer_visibility) { nil }
            let(:reimport_monograph_visibility) { private_vis }

            it "imports the Monograph and FileSets with the existing Monograph's visibility" do
              expect { importer.run }
                .to change(Monograph, :count)
                      .by(0)
                      .and(change(FileSet, :count)
                             .by(8))

              monograph = Monograph.first
              f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

              expect(monograph.title).to eq ['Blah']
              expect(monograph.visibility).to eq 'restricted'
              expect(f1.visibility).to eq 'restricted'
              expect(f2.visibility).to eq 'restricted'
              expect(f3.visibility).to eq 'restricted'
              expect(f4.visibility).to eq 'restricted'
              expect(f5.visibility).to eq 'restricted'
              expect(f6.visibility).to eq 'restricted'
              expect(f7.visibility).to eq 'restricted'
              expect(f8.visibility).to eq 'restricted'
            end
          end

          context "Public visibility set on importer object" do
            let(:importer_visibility) { public_vis }
            let(:reimport_monograph_visibility) { private_vis }

            it "imports the Monograph and FileSets with the existing Monograph's visibility" do
              expect { importer.run }
                .to change(Monograph, :count)
                      .by(0)
                      .and(change(FileSet, :count)
                             .by(8))

              monograph = Monograph.first
              f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

              expect(monograph.title).to eq ['Blah']
              expect(monograph.visibility).to eq 'restricted'
              expect(f1.visibility).to eq 'restricted'
              expect(f2.visibility).to eq 'restricted'
              expect(f3.visibility).to eq 'restricted'
              expect(f4.visibility).to eq 'restricted'
              expect(f5.visibility).to eq 'restricted'
              expect(f6.visibility).to eq 'restricted'
              expect(f7.visibility).to eq 'restricted'
              expect(f8.visibility).to eq 'restricted'
            end
          end

          context "Private visibility set on importer object" do
            let(:importer_visibility) { private_vis }
            let(:reimport_monograph_visibility) { public_vis }

            it "imports the Monograph and FileSets with the existing Monograph's visibility" do
              expect { importer.run }
                .to change(Monograph, :count)
                      .by(0)
                      .and(change(FileSet, :count)
                             .by(8))

              monograph = Monograph.first
              f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

              expect(monograph.title).to eq ['Blah']
              expect(monograph.visibility).to eq 'open'
              expect(f1.visibility).to eq 'open'
              expect(f2.visibility).to eq 'open'
              expect(f3.visibility).to eq 'open'
              expect(f4.visibility).to eq 'open'
              expect(f5.visibility).to eq 'open'
              expect(f6.visibility).to eq 'open'
              expect(f7.visibility).to eq 'open'
              expect(f8.visibility).to eq 'open'
            end
          end
        end

        context 'Monograph is marked as draft in CSV' do
          let(:root_dir) { File.join(fixture_path, 'csv', 'import_visibility', 'reimporting', 'visibility_column', 'draft_monograph') }

          # For easier reference, CSV values look like this:
          #
          # File Name,	       Title,	                           External Resource URL,	Published?
          # ://:MONOGRAPH://:, Visibility Settin’ CSV Monograph,		                    false
          #                  , External Resource FileSet 1,	     http://www.blah.com/1,	true
          #                  , External Resource FileSet 2,	     http://www.blah.com/2,	true
          #                  , External Resource FileSet 3,	     http://www.blah.com/3,	blah
          #                  , External Resource FileSet 4,	     http://www.blah.com/4,	false
          #                  , External Resource FileSet 5,	     http://www.blah.com/5,	false
          #                  , External Resource FileSet 6,	     http://www.blah.com/6,
          #                  , External Resource FileSet 7,	     http://www.blah.com/7, false
          #                  , External Resource FileSet 8,	     http://www.blah.com/8,	true

          context "No visibility set on importer object" do
            let(:importer_visibility) { nil }
            let(:reimport_monograph_visibility) { public_vis }

            it "imports the Monograph and FileSets with the existing Monograph's visibility" do
              expect { importer.run }
                .to change(Monograph, :count)
                      .by(0)
                      .and(change(FileSet, :count)
                             .by(8))

              monograph = Monograph.first
              f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a
              pp 'ASDFASDFASDF'
              expect(monograph.title).to eq ['Blah']
              expect(monograph.visibility).to eq 'open'
              expect(f1.visibility).to eq 'open'
              expect(f2.visibility).to eq 'open'
              expect(f3.visibility).to eq 'open'
              expect(f4.visibility).to eq 'open'
              expect(f5.visibility).to eq 'open'
              expect(f6.visibility).to eq 'open'
              expect(f7.visibility).to eq 'open'
              expect(f8.visibility).to eq 'open'
            end
          end

          context "Public visibility set on importer object" do
            let(:importer_visibility) { public_vis }
            let(:reimport_monograph_visibility) { private_vis }

            it "imports the Monograph and FileSets with the existing Monograph's visibility" do
              expect { importer.run }
                .to change(Monograph, :count)
                      .by(0)
                      .and(change(FileSet, :count)
                             .by(8))

              monograph = Monograph.first
              f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

              expect(monograph.title).to eq ['Blah']
              expect(monograph.visibility).to eq 'restricted'
              expect(f1.visibility).to eq 'restricted'
              expect(f2.visibility).to eq 'restricted'
              expect(f3.visibility).to eq 'restricted'
              expect(f4.visibility).to eq 'restricted'
              expect(f5.visibility).to eq 'restricted'
              expect(f6.visibility).to eq 'restricted'
              expect(f7.visibility).to eq 'restricted'
              expect(f8.visibility).to eq 'restricted'
            end
          end

          context "Private visibility set on importer object" do
            let(:importer_visibility) { private_vis }
            let(:reimport_monograph_visibility) { public_vis }

            it "imports the Monograph and FileSets with the existing Monograph's visibility" do
              expect { importer.run }
                .to change(Monograph, :count)
                      .by(0)
                      .and(change(FileSet, :count)
                             .by(8))

              monograph = Monograph.first
              f1, f2, f3, f4, f5, f6, f7, f8 = monograph.ordered_members.to_a

              expect(monograph.title).to eq ['Blah']
              expect(monograph.visibility).to eq 'open'
              expect(f1.visibility).to eq 'open'
              expect(f2.visibility).to eq 'open'
              expect(f3.visibility).to eq 'open'
              expect(f4.visibility).to eq 'open'
              expect(f5.visibility).to eq 'open'
              expect(f6.visibility).to eq 'open'
              expect(f7.visibility).to eq 'open'
              expect(f8.visibility).to eq 'open'
            end
          end
        end
      end
    end
  end
end

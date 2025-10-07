# frozen_string_literal: true

require 'rails_helper'

describe DlpsInstitution do
  describe '#find' do
    subject { described_class.new.find(request_attributes) }

    let(:request_attributes) { {} }

    it { is_expected.to eq [] }

    context 'request_attributes' do
      let(:request_attributes) { { dlpsInstitutionId: ids, identity_provider: entity_id } }
      let(:ids) { }
      let(:entity_id) { }

      it { is_expected.to eq [] }

      context 'institutions' do
        let(:institution_1) { create(:institution, identifier: '1', entity_id: 'entity_1') }
        let!(:institution_1_affiliation_1) { create(:institution_affiliation, institution_id: institution_1.id, dlps_institution_id: institution_1.identifier, affiliation: 'member') }
        let(:institution_2) { create(:institution, identifier: '2', entity_id: 'entity_2') }
        let!(:institution_2_affiliation_1) { create(:institution_affiliation, institution_id: institution_2.id, dlps_institution_id: institution_2.identifier, affiliation: 'member') }

        context 'ip_based' do
          let(:ids) { [institution_2.identifier] }
          let(:entity_id) { 'entity_id' }

          it { is_expected.to eq [institution_2] }
        end

        context 'shib' do
          let(:ids) { ['ids'] }
          let(:entity_id) { institution_1.entity_id }

          it { is_expected.to eq [institution_1] }
        end

        context 'both' do
          let(:ids) { [institution_1.identifier, institution_2.identifier] }
          let(:entity_id) { institution_1.entity_id }

          it { is_expected.to eq [institution_1, institution_2] }
        end
      end

      context 'institutions with more real world data' do
        # Sometimes it's easier for me to understand what's going on if there's data closer to the real thing
        let!(:um_institution_1) { create(:institution, identifier: '1', name: 'University of Michigan, Ann Arbor', entity_id: 'https://shibboleth.umich.edu/idp/shibboleth') }
        let!(:um_institution_2) { create(:institution, identifier: '2', name: 'University of Michigan, Dearborn', entity_id: 'https://shibboleth.umich.edu/idp/shibboleth') }
        let!(:um_institution_3) { create(:institution, identifier: '3', name: 'University of Michigan, Flint', entity_id: 'https://shibboleth.umich.edu/idp/shibboleth') }
        let!(:um_institution_4) { create(:institution, identifier: '490', name: 'University of Michigan, Library Information Technology and MPublishing') }

        let!(:um_institution_1_affiliation_1) { create(:institution_affiliation, institution_id: um_institution_1.id, dlps_institution_id: um_institution_1.identifier, affiliation: 'member') }
        let!(:um_institution_2_affiliation_1) { create(:institution_affiliation, institution_id: um_institution_2.id, dlps_institution_id: um_institution_2.identifier, affiliation: 'member') }
        let!(:um_institution_3_affiliation_1) { create(:institution_affiliation, institution_id: um_institution_3.id, dlps_institution_id: um_institution_3.identifier, affiliation: 'member') }
        let!(:um_institution_4_affiliation_1) { create(:institution_affiliation, institution_id: um_institution_4.id, dlps_institution_id: um_institution_4.identifier, affiliation: 'member') }

        context 'ip based' do
          let(:ids) { [um_institution_1.identifier, um_institution_4.identifier] }
          let(:entity_id) { '' } # this represents no shib auth

          it "is 1 and 490 because those are the two dlpsInstitutionIds we passed in" do
            expect(subject.count).to eq 2
            expect(subject).to eq [um_institution_1, um_institution_4]
          end
        end

        context 'shib only' do
          let(:ids) { [] } # this represents no ip based auth
          let(:entity_id) { um_institution_1.entity_id }

          it "is all three campuses because they share the same entity_id, but not 490 because it has no entity_id" do
            expect(subject.count).to eq 3
            expect(subject).to eq [um_institution_1, um_institution_2, um_institution_3]
          end
        end

        context 'both' do
          let(:ids) { [um_institution_1.identifier, um_institution_4.identifier] }
          let(:entity_id) { um_institution_1.entity_id }

          it "is all three campuses with entity_ids and also 490 because of the IP based auth" do
            expect(subject.count).to eq 4
            # We get IP auth matches first, then shib matches
            expect(subject).to eq [um_institution_1, um_institution_4, um_institution_2, um_institution_3]
          end
        end
      end

      context "HELIO-4210: Johns Hopkins University" do
        let(:institution) { create(:institution, identifier: '296', name: 'Johns Hopkins University', entity_id: 'urn:mace:incommon:johnshopkins.edu') }
        let(:affiliation_1) { create(:institution_affiliation, institution_id: institution.id, dlps_institution_id: '296', affiliation: 'member') }
        let(:affiliation_2) { create(:institution_affiliation, institution_id: institution.id, dlps_institution_id: '296', affiliation: 'walk-in') }
        let(:affiliation_3) { create(:institution_affiliation, institution_id: institution.id, dlps_institution_id: '2395', affiliation: 'alum') }

        context 'shib' do
          let(:ids) { ['ids'] }
          let(:entity_id) { institution.entity_id }

          it { is_expected.to eq [institution] }
        end

        context 'ip based, alum' do
          let(:ids) { [affiliation_3.dlps_institution_id] }
          let(:entity_id) { 'entity_id' }

          it { is_expected.to eq [institution] }
        end

        context 'ip based, member' do
          let(:ids) { [affiliation_1.dlps_institution_id] }
          let(:entity_id) { 'entity_id' }

          it { is_expected.to eq [institution] }
        end

        context 'ip based, multiple dlps ids' do
          let(:ids) { [affiliation_1.dlps_institution_id, affiliation_3.dlps_institution_id] }
          let(:entity_id) { 'entity_id' }

          it { is_expected.to eq [institution] }
        end
      end

      # HELIO-4961
      context 'Security Domains' do
        before do
          allow(Flipflop).to receive(:use_shib_security_domain_logic?).and_return(true)
        end

        context 'Without IPAuth' do
          context 'When there are no Shib provided security domains' do
            context 'without matching entityID Fulcrum Institions' do
              let(:request_attributes) do
                {
                  dlpsInstitutionId: ids,
                  identity_provider: entity_id,
                  eduPersonScopedAffiliation: []
                }
              end
              let(:ids) { [] } # this represents no ip based auth
              let(:entity_id) { 'entity_id' }

              it "retrns an empty array because there are no matching institutions" do
                expect(subject).to eq []
              end
            end

            context 'with matching entityID Fulcrum Institutions but none have security domains' do
              let(:institution_1) { create(:institution, identifier: '1', name: 'InstOne', entity_id: 'https://numbers.edu/shib') }
              let(:institution_2) { create(:institution, identifier: '2', name: 'InstTwo', entity_id: 'https://numbers.edu/shib') }
              let!(:institution_1_affiliation_1) { create(:institution_affiliation, institution_id: institution_1.id, dlps_institution_id: institution_1.identifier, affiliation: 'member') }
              let!(:institution_2_affiliation_1) { create(:institution_affiliation, institution_id: institution_2.id, dlps_institution_id: institution_2.identifier, affiliation: 'member') }

              let(:request_attributes) do
                {
                  dlpsInstitutionId: ids,
                  identity_provider: entity_id,
                  eduPersonScopedAffiliation: []
                }
              end
              let(:ids) { [] } # this represents no ip based auth
              let(:entity_id) { institution_1.entity_id }

              it "returns all the entity_id matching institutions because no security domains were given" do
                expect(subject.count).to eq 2
                expect(subject).to eq [institution_1, institution_2]
              end
            end
          end

          context 'When there are Shib provided security domains' do
            context "And there are matching entityID Fulcrum Institutions, but none have security domains" do
              let(:institution_1) { create(:institution, identifier: '1', name: 'InstOne', entity_id: 'https://numbers.edu/shib') }
              let(:institution_2) { create(:institution, identifier: '2', name: 'InstTwo', entity_id: 'https://numbers.edu/shib') }
              let!(:institution_1_affiliation_1) { create(:institution_affiliation, institution_id: institution_1.id, dlps_institution_id: institution_1.identifier, affiliation: 'member') }
              let!(:institution_2_affiliation_1) { create(:institution_affiliation, institution_id: institution_2.id, dlps_institution_id: institution_2.identifier, affiliation: 'member') }

              let(:request_attributes) do
                {
                  dlpsInstitutionId: ids,
                  identity_provider: entity_id,
                  eduPersonScopedAffiliation: []
                }
              end
              let(:ids) { [] } # this represents no ip based auth
              let(:entity_id) { institution_1.entity_id }

              it "returns all the entity_id matching institutions because no security domains were given" do
                expect(subject.count).to eq 2
                expect(subject).to eq [institution_1, institution_2]
              end
            end

            context "And there are matching entityID Fulcrum Institutions, and all have security domains" do
              let(:institution_1) { create(:institution, identifier: '1', name: 'InstOne', entity_id: 'https://numbers.edu/shib', security_domain: 'campus_a.numbers.edu') }
              let(:institution_2) { create(:institution, identifier: '2', name: 'InstTwo', entity_id: 'https://numbers.edu/shib', security_domain: 'campus_b.bumbers.edu') }
              let!(:institution_1_affiliation_1) { create(:institution_affiliation, institution_id: institution_1.id, dlps_institution_id: institution_1.identifier, affiliation: 'member') }
              let!(:institution_2_affiliation_1) { create(:institution_affiliation, institution_id: institution_2.id, dlps_institution_id: institution_2.identifier, affiliation: 'member') }

              let(:request_attributes) do
                {
                  dlpsInstitutionId: ids,
                  identity_provider: entity_id,
                  eduPersonScopedAffiliation: ["member@campus_a.numbers.edu"]
                }
              end
              let(:ids) { [] } # this represents no ip based auth
              let(:entity_id) { institution_1.entity_id }

              it "returns only the institution that matches the security domain" do
                expect(subject.count).to eq 1
                expect(subject).to eq [institution_1]
              end
            end

            context "And there are matching entityID Fulcrum Institutions, but only some have security domains" do
              let(:institution_1) { create(:institution, identifier: '1', name: 'InstOne', entity_id: 'https://numbers.edu/shib') }
              let(:institution_2) { create(:institution, identifier: '2', name: 'InstTwo', entity_id: 'https://numbers.edu/shib', security_domain: 'campus_b.numbers.edu') }
              let!(:institution_1_affiliation_1) { create(:institution_affiliation, institution_id: institution_1.id, dlps_institution_id: institution_1.identifier, affiliation: 'member') }
              let!(:institution_2_affiliation_1) { create(:institution_affiliation, institution_id: institution_2.id, dlps_institution_id: institution_2.identifier, affiliation: 'member') }

              # In https://mlit.atlassian.net/browse/HELIO-4961?focusedCommentId=368252
              # This is Senario 2
              context "When the request has a security domain that matches the Institution that has a security domain" do
                let(:request_attributes) do
                  {
                    dlpsInstitutionId: ids,
                    identity_provider: entity_id,
                    eduPersonScopedAffiliation: ["member@campus_b.numbers.edu"] # campus B
                  }
                end
                let(:ids) { [] } # this represents no ip based auth
                let(:entity_id) { institution_1.entity_id }

                it "returns the institution that matches the security domain" do
                  expect(subject.count).to eq 1
                  expect(subject).to eq [institution_2] # campus B
                end
              end

              # This is the case where we (Fulcrum staff) added a security domain for one institution, but forgot
              # to add it for all of them. In this case, we ignore security domains and use entity_id only.
              # In https://mlit.atlassian.net/browse/HELIO-4961?focusedCommentId=368252
              # This is Scenario 1
              context "When the request has a security domain that does not match the institution that has a security domain" do
                let(:request_attributes) do
                  {
                    dlpsInstitutionId: ids,
                    identity_provider: entity_id,
                    eduPersonScopedAffiliation: ["member@campus_a.numbers.edu"] # campus A and we don't have this security domain in our records
                  }
                end
                let(:ids) { [] } # this represents no ip based auth
                let(:entity_id) { institution_1.entity_id }

                it "returns all the entity_id matching institutions because the security domain did not match" do
                  expect(subject.count).to eq 2
                  expect(subject).to eq [institution_1, institution_2] # campus A and B
                end
              end

              # In https://mlit.atlassian.net/browse/HELIO-4961?focusedCommentId=368252
              # this is Scenario 3
              # "Campus C has never had a license so Fulcrum never created an Institution record for them"
              context "But this Institution, even though it has a matching entityID, is not in Fulcrum's Institutions table ie: not a subscriber" do
                let(:request_attributes) do
                  {
                    dlpsInstitutionId: ids,
                    identity_provider: entity_id,
                    eduPersonScopedAffiliation: ["member@campus_c.numbers.edu"] # This campus does not exist in our records
                  }
                end
                let(:ids) { [] } # this represents no ip based auth
                let(:entity_id) { institution_1.entity_id }

                it "returns any entity_id matching institutions" do
                  # We should deny access because campus_c is not in our records
                  # but we've decided to allow access to any institution that matches the entity_id
                  # as we have historically done
                  expect(subject.count).to eq 2
                  expect(subject).to eq [institution_1, institution_2]
                end
              end
            end
          end
        end
      end
    end
  end
end

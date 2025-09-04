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

      context "HELIO-4961 with security domains" do
        # HELIO-4961 With this change, if a shib user has a security domain that matches an institution, we use that institution.
        # We will only use Instititions that match the security domain, and ignore other institutions that match only by entity_id.
        let!(:institution_1) { create(:institution, identifier: '1', name: 'University of Michigan, Ann Arbor', entity_id: 'https://shibboleth.umich.edu/idp/shibboleth', security_domain: 'annarbor.umich.edu') }
        let!(:institution_2) { create(:institution, identifier: '2', name: 'University of Michigan, Dearborn', entity_id: 'https://shibboleth.umich.edu/idp/shibboleth', security_domain: 'dearborn.umich.edu') }
        let!(:institution_3) { create(:institution, identifier: '3', name: 'University of Michigan, Flint', entity_id: 'https://shibboleth.umich.edu/idp/shibboleth', security_domain: 'flint.umich.edu') }
        let!(:institution_4) { create(:institution, identifier: '490', name: 'University of Michigan, Library Information Technology and MPublishing') }

        let!(:institution_1_affiliation_1) { create(:institution_affiliation, institution_id: institution_1.id, dlps_institution_id: institution_1.identifier, affiliation: 'member') }
        let!(:institution_2_affiliation_1) { create(:institution_affiliation, institution_id: institution_2.id, dlps_institution_id: institution_2.identifier, affiliation: 'member') }
        let!(:institution_3_affiliation_1) { create(:institution_affiliation, institution_id: institution_3.id, dlps_institution_id: institution_3.identifier, affiliation: 'member') }
        let!(:institution_4_affiliation_1) { create(:institution_affiliation, institution_id: institution_4.id, dlps_institution_id: institution_4.identifier, affiliation: 'member') }

        context "ip based only" do
          let(:request_attributes) do
            {
              dlpsInstitutionId: ids,
              identity_provider: entity_id,
              eduPersonScopedAffiliation: []
            }
          end
          let(:ids) { [1, 490] }
          let(:entity_id) { '' } # this represents no shib auth

          it "has no security domain info, so order is based on dlpsInstitutionId only" do
            expect(subject.count).to eq 2
            expect(subject).to eq [institution_1, institution_4]
          end
        end

        context 'shib only, but the user has no annarbor security domain, so all are equal' do
          let(:request_attributes) do
            {
              dlpsInstitutionId: ids,
              identity_provider: entity_id,
              eduPersonScopedAffiliation: []
            }
          end
          let(:ids) { [] } # this represents no ip based auth
          let(:entity_id) { institution_1.entity_id }

          it "is all three campuses because they share the same entity_id, but not 490 because it has no entity_id" do
            expect(subject.count).to eq 3
            expect(subject).to eq [institution_1, institution_2, institution_3]
          end
        end

        context 'IP based and shib with a security_domain' do
          let(:request_attributes) do
            {
              dlpsInstitutionId: ids,
              identity_provider: entity_id,
              eduPersonScopedAffiliation: ["staff@annarbor.umich.edu", "member@annarbor.umich.edu", "employee@annarbor.umich.edu", "alum@annarbor.umich.edu", "member@umich.edu", "staff@umich.edu", "employee@umich.edu", "alum@umich.edu"]
            }
          end
          let(:ids) { [institution_4.identifier] } # only the LIT IP here
          let(:entity_id) { 'https://shibboleth.umich.edu/idp/shibboleth' }

          it "has ip based instituitions, followed by any security domain matching shib institutions" do
            expect(subject.count).to eq 2
            expect(subject).to eq [institution_4, institution_1]
          end
        end

        context "with two shib security domains" do
          let(:request_attributes) do
            {
              dlpsInstitutionId: ids,
              identity_provider: entity_id,
              eduPersonScopedAffiliation: ["member@dearborn.umich.edu", "member@annarbor.umich.edu", "member@umich.edu", "staff@umich.edu", "employee@umich.edu", "alum@umich.edu"]
            }
          end
          let(:ids) { [institution_4.identifier] } # only the LIT IP here
          let(:entity_id) { 'https://shibboleth.umich.edu/idp/shibboleth' }

          it "has ip based instituitions, followed by any security domain matching shib institutions" do
            expect(subject.count).to eq 3
            expect(subject).to eq [institution_4, institution_1, institution_2]
          end
        end
      end

      context "HELIO-4961 security domains with South Carolina" do
        let(:institution_1) { create(:institution, identifier: '1446', name: 'SC Beaufort', entity_id: 'https://idp.sc.edu/entity', security_domain: '80000014.sc.edu') }
        let(:institution_2) { create(:institution, identifier: '567', name: 'SC Columbia (main campus)', entity_id: 'https://idp.sc.edu/entity', security_domain: 'sc.edu') }
        let(:institution_3) { create(:institution, identifier: '1152', name: 'SC Lancaster', entity_id: 'https://idp.sc.edu/entity', security_domain: '72504401.sc.edu') }
        let(:institution_4) { create(:institution, identifier: '1153', name: 'SC Salkehatchie', entity_id: 'https://idp.sc.edu/entity', security_domain: '72504402.sc.edu') }
        let(:institution_5) { create(:institution, identifier: '1154', name: 'SC Sumter', entity_id: 'https://idp.sc.edu/entity', security_domain: '72504403.sc.edu') }
        let(:institution_6) { create(:institution, identifier: '1155', name: 'SC Union', entity_id: 'https://idp.sc.edu/entity', security_domain: '72504405.sc.edu') }

        let!(:institution_1_affiliation_1) { create(:institution_affiliation, institution_id: institution_1.id, dlps_institution_id: institution_1.identifier, affiliation: 'member') }
        let!(:institution_2_affiliation_1) { create(:institution_affiliation, institution_id: institution_2.id, dlps_institution_id: institution_2.identifier, affiliation: 'member') }
        let!(:institution_2_affiliation_2) { create(:institution_affiliation, institution_id: institution_2.id, dlps_institution_id: institution_2.identifier, affiliation: 'alum') }
        let!(:institution_3_affiliation_1) { create(:institution_affiliation, institution_id: institution_3.id, dlps_institution_id: institution_3.identifier, affiliation: 'member') }
        let!(:institution_4_affiliation_1) { create(:institution_affiliation, institution_id: institution_4.id, dlps_institution_id: institution_4.identifier, affiliation: 'member') }
        let!(:institution_5_affiliation_1) { create(:institution_affiliation, institution_id: institution_5.id, dlps_institution_id: institution_5.identifier, affiliation: 'member') }
        let!(:institution_6_affiliation_1) { create(:institution_affiliation, institution_id: institution_6.id, dlps_institution_id: institution_6.identifier, affiliation: 'member') }

        context "ip based only simple example" do
          let(:request_attributes) do
            {
              dlpsInstitutionId: ids,
              identity_provider: entity_id,
              eduPersonScopedAffiliation: []
            }
          end
          let(:ids) { [institution_1.identifier] }
          let(:entity_id) { '' } # this represents no shib auth

          it "has no security domain info, so order is based on dlpsInstitutionId only" do
            expect(subject.count).to eq 1
            expect(subject).to eq [institution_1]
          end
        end

        context "shib entity_id only" do
          let(:request_attributes) do
            {
              dlpsInstitutionId: ids,
              identity_provider: entity_id,
              eduPersonScopedAffiliation: ['']
            }
          end
          let(:ids) { [] } # this represents no ip based auth
          let(:entity_id) { institution_2.entity_id }

          it "returns all campuses because they share the same entity_id" do
            expect(subject.count).to eq 6
            expect(subject).to eq [institution_1, institution_2, institution_3, institution_4, institution_5, institution_6]
          end
        end

        context "shib entity_id and security domain" do
          let(:request_attributes) do
            {
              dlpsInstitutionId: ids,
              identity_provider: entity_id,
              eduPersonScopedAffiliation: ["member@72504402.sc.edu"] # Salkehatchie campus
            }
            let(:ids) { [] } # this represents no ip based auth
            let(:entity_id) { institution_1.entity_id } # all campuses share the same entity_id

            it "returns only the Salkehatchie Instituion" do
              expect(subject.count).to eq 6
              expect(subject).to eq [institution_4]
            end
          end
        end

        context "a user from one campus IP based, but logged in via shib from another campus" do
          let(:request_attributes) do
            {
              dlpsInstitutionId: ids,
              identity_provider: entity_id,
              eduPersonScopedAffiliation: ["member@72504401.sc.edu"] # Lancaster campus
            }
          end
          let(:ids) { [institution_2.identifier] } # Columbia (main campus)
          let(:entity_id) { institution_3.entity_id } # all campuses share the same entity_id

          it "Columbia first by IPAuth followed by Lancaster entity_id/security domain match" do
            expect(subject.count).to eq 2
            # IP based first, then shib matching security domain
            expect(subject).to eq [institution_2, institution_3] # Columbia then Lancaster
          end
        end
      end

      context "some institutions with a common entity_id have a security domain, some don't" do
        let(:institution_1) { create(:institution, identifier: '1446', name: 'SC Beaufort', entity_id: 'https://idp.sc.edu/entity', security_domain: '80000014.sc.edu') }
        let(:institution_2) { create(:institution, identifier: '567', name: 'SC Columbia (main campus)', entity_id: 'https://idp.sc.edu/entity', security_domain: 'sc.edu') }
        let(:institution_3) { create(:institution, identifier: '1152', name: 'SC Lancaster', entity_id: 'https://idp.sc.edu/entity') }
        let(:institution_4) { create(:institution, identifier: '1153', name: 'SC Salkehatchie', entity_id: 'https://idp.sc.edu/entity') }

        let!(:institution_1_affiliation_1) { create(:institution_affiliation, institution_id: institution_1.id, dlps_institution_id: institution_1.identifier, affiliation: 'member') }
        let!(:institution_2_affiliation_1) { create(:institution_affiliation, institution_id: institution_2.id, dlps_institution_id: institution_2.identifier, affiliation: 'member') }
        let!(:institution_3_affiliation_1) { create(:institution_affiliation, institution_id: institution_3.id, dlps_institution_id: institution_3.identifier, affiliation: 'member') }
        let!(:institution_4_affiliation_1) { create(:institution_affiliation, institution_id: institution_4.id, dlps_institution_id: institution_4.identifier, affiliation: 'member') }

        context "with an entity_id match and no security domain" do
          let(:request_attributes) do
            {
              dlpsInstitutionId: ids,
              identity_provider: entity_id,
              eduPersonScopedAffiliation: ['']
            }
          end
          let(:ids) { [] } # this represents no ip based auth
          let(:entity_id) { institution_1.entity_id } # all campuses share the same entity_id

          it "returns all campuses because they share the same entity_id and no security domain was given" do
            expect(subject.count).to eq 4
            expect(subject).to eq [institution_1, institution_2, institution_3, institution_4]
          end
        end

        context "with an entity_id match and a security domain that matches one of the institutions" do
          let(:request_attributes) do
            {
              dlpsInstitutionId: ids,
              identity_provider: entity_id,
              eduPersonScopedAffiliation: ["member@sc.edu"]
            }
          end
          let(:ids) { [] } # this represents no ip based auth
          let(:entity_id) { institution_1.entity_id } # all campuses share the same

          it "returns only the institution that matches the security domain" do
            expect(subject.count).to eq 1
            expect(subject).to eq [institution_2] # Columbia
          end
        end

        context "with an entity_id match and a security domain that doesn't match any of the institutions" do
          let(:request_attributes) do
            {
              dlpsInstitutionId: ids,
              identity_provider: entity_id,
              eduPersonScopedAffiliation: ["member@unknown.sc.edu"]
            }
          end
          let(:ids) { [] } # this represents no ip based auth
          let(:entity_id) { institution_1.entity_id } # all campuses share the same entity_id

          it "returns nothing because the security domain doesn't match any institution" do
            expect(subject.count).to eq 0
            expect(subject).to eq []
          end
        end

        # There are probably some differences in how Michigan and South Carolina handle security domains.
        # For Michigan, my shib credentials include both a general @umich.edu affiliation and a more specific @annarbor.umich.edu security domain.
        #
        # ["member@annarbor.umich.edu", "member@annarbor.umich.edu", "member@umich.edu", "staff@umich.edu", "employee@umich.edu", "alum@umich.edu"]
        #
        # For South Carolina, Columbia campus has a security domain of @sc.edu which could be a problem if their users have a eduPersonScopedAffiliation
        # that looks like michigan's. It would mix Michigan's general and specific. Here we'd have someone from the Beaufort campus, but ALSO with a general
        # @sc.edu affiliation. So this can't be right, right? I don't have a way to check.
        #
        # ["member@80000014.sc.edu", "member@sc.edu"]
        #
        # So I have to assume that SC user's shib eduPersonScopedAffiliation are NOT like Michigan's, but if they were, we'd get a situation
        # where a user from Beaufort would also get collections that only Columbia has subscribed to.
        context "with a 'default' security domain match" do
          let(:request_attributes) do
            {
              dlpsInstitutionId: ids,
              identity_provider: entity_id,
              eduPersonScopedAffiliation: ["member@80000014.sc.edu", "member@sc.edu"]
           }
          end
          let(:ids) { [] } # this represents no ip based auth
          let(:entity_id) { institution_1.entity_id } # all campuses share the same

          it "returns both Beaufort (80000014.sc.edu) and Columbia (sc.edu) because both match security domains" do
            expect(subject.count).to eq 2
            expect(subject).to eq [institution_1, institution_2] # Beaufort then Columbia
          end
        end
      end
    end
  end
end

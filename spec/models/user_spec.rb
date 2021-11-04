# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  it { is_expected.to be_a Actorable }

  describe '#user_key' do
    subject { user.user_key }

    let(:user) { described_class.new(email: 'foo@example.com') }

    it { is_expected.to eq 'foo@example.com' }
  end

  describe '#identity' do
    let(:user) { described_class.new }

    context 'for a new user' do
      it 'is an empty hash' do
        expect(user.identity).to eq({})
      end
    end

    it 'allows read and write' do
      attrs = { user_eid: 'user@domain' }
      user.identity = attrs
      expect(user.identity).to eq attrs
    end
  end

  describe "#total_file_views" do
    subject { user.total_file_views }

    let(:user) { create(:user) }

    it { is_expected.to eq 0 }
  end

  describe '#presses' do
    subject { user.presses }

    let(:press1) { create(:press) }
    let(:press2) { create(:press) }
    let(:press3) { create(:press) }
    let(:user) { create(:user) }

    before do
      create(:role, resource: press1, user: user, role: 'admin')
      create(:role, resource: press2, user: user, role: 'admin')
    end

    it { is_expected.to eq [press1, press2] }
  end

  describe '#guest' do
    subject { described_class.guest(user_key: email) }

    let(:email) { 'wolverine@umich.edu' }

    it { is_expected.to be_a_kind_of(described_class) }

    it { is_expected.to be_an_instance_of(Guest) }

    it { expect(subject.email).to eq(email) }
  end

  describe '#groups' do
    let(:press1) { create(:press, subdomain: 'red') }
    let(:press2) { create(:press, subdomain: 'blue') }
    let(:press3) { create(:press, subdomain: 'yellow') }

    let(:admin) { create(:user) }
    let(:editor) { create(:user) }
    let(:analyst) { create(:user) }
    let(:platform_admin) { create(:platform_admin) }

    before do
      Press.delete_all
      Role.delete_all
      create(:role, resource: press1, user: admin, role: 'admin')
      create(:role, resource: press2, user: editor, role: 'editor')
      create(:role, resource: press3, user: analyst, role: 'analyst')
    end

    it "returns the right groups for users" do
      expect(admin.groups).to eq ["red_admin"]
      expect(editor.groups).to eq ["blue_editor"]
      expect(analyst.groups).to eq ["yellow_analyst"]
      expect(platform_admin.groups).to eq ["blue_admin", "blue_analyst", "blue_editor", "red_admin", "red_analyst", "red_editor", "yellow_admin", "yellow_analyst", "yellow_editor", "admin"]
    end
  end

  context 'roles' do
    let(:user) { create(:user) }

    before { Role.delete_all }

    it { expect(user.role?).to be false }

    context 'role' do
      let(:user) { create(:platform_admin) }

      it { expect(user.role?).to be true }

      context '#press_roles' do
        it { expect(user.press_role?).to be false }
        it { expect(user.press_roles).to be_empty }
        it { expect(user.admin_roles).to be_empty }
        it { expect(user.editor_roles).to be_empty }
        it { expect(user.analyst_roles).to be_empty }

        context '#admin_roles' do
          let(:user) { create(:press_admin) }

          it { expect(user.press_role?).to be true }
          it { expect(user.press_roles).not_to be_empty }
          it { expect(user.admin_roles).not_to be_empty }
          it { expect(user.editor_roles).to be_empty }
          it { expect(user.analyst_roles).to be_empty }
        end

        context '#editor_roles' do
          let(:user) { create(:press_editor) }

          it { expect(user.press_role?).to be true }
          it { expect(user.press_roles).not_to be_empty }
          it { expect(user.admin_roles).to be_empty }
          it { expect(user.editor_roles).not_to be_empty }
          it { expect(user.analyst_roles).to be_empty }
        end

        context "#analyst_roles" do
          let(:user) { create(:press_analyst) }

          it { expect(user.press_role?).to be true }
          it { expect(user.press_roles).not_to be_empty }
          it { expect(user.admin_roles).to be_empty }
          it { expect(user.editor_roles).to be_empty }
          it { expect(user.analyst_roles).not_to be_empty }
        end
      end
    end
  end

  describe "#analyst_presses" do
    let(:press1) { create(:press) }
    let(:press2) { create(:press) }

    let(:user) { create(:user) }
    let(:superuser) { create(:platform_admin) }

    before do
      Press.delete_all
      Role.delete_all
      create(:role, resource: press1, user: user, role: 'analyst')
      create(:role, resource: press2, user: user, role: 'admin')
    end

    it 'returns the presses that this user is an analyst for' do
      expect(user.analyst_presses).to eq [press1]
      expect(superuser.analyst_presses).to eq [press1, press2]
    end
  end

  describe '#editor_presses' do
    let(:press1) { create(:press) }
    let(:press2) { create(:press) }

    let(:user) { create(:user) }
    let(:superuser) { create(:platform_admin) }

    before do
      Press.delete_all
      Role.delete_all
      create(:role, resource: press1, user: user, role: 'editor')
      create(:role, resource: press2, user: user, role: 'admin')
    end

    it 'returns the presses that this user is an editor for' do
      expect(user.editor_presses).to eq [press1]
      expect(superuser.editor_presses).to eq [press1, press2]
    end
  end

  describe '#admin_presses' do
    let(:press1) { create(:press) }
    let(:press2) { create(:press) }

    let(:user) { create(:user) }
    let(:superuser) { create(:platform_admin) }

    before do
      Press.delete_all
      Role.delete_all
      create(:role, resource: press1, user: user, role: 'editor')
      create(:role, resource: press2, user: user, role: 'admin')
    end

    it 'returns the presses that this user is an admin for' do
      expect(user.admin_presses).to eq [press2]
      expect(superuser.admin_presses).to eq [press1, press2]
    end
  end

  describe '#platform_admin?' do
    subject { user.platform_admin? }

    context "when a platform admin" do
      let(:user) { create(:platform_admin) }

      it { is_expected.to be true }
    end

    context "when a press admin" do
      let(:user) { create(:press_admin) }

      it { is_expected.to be false }
    end
  end

  describe '#developer?' do
    subject { user.developer? }

    let(:user) { build(:user) }

    it { is_expected.to be false }

    context 'when incognito' do
      before { allow(Incognito).to receive(:developer?).with(user).and_return true }

      it { is_expected.to be true }
    end
  end

  describe '#token' do
    subject { user.token }

    let(:user) { build(:user) }

    it { is_expected.to eq(JsonWebToken.encode(email: user.email, pin: user.encrypted_password)) }
  end

  describe '#tokenize!' do
    let(:user) { build(:user) }

    it do
      old_token = user.token
      user.tokenize!
      expect(user.token).not_to eq(old_token)
      expect(user.token).to eq(JsonWebToken.encode(email: user.email, pin: user.encrypted_password))
    end
  end

  describe '#identifier' do
    subject { user.identifier }

    let(:user) { build(:user) }

    it { is_expected.to be user.user_key }
  end

  describe '#name' do
    subject { user.name }

    let(:user) { build(:user, display_name: display_name) }
    let(:display_name) { 'display_name' }

    it { is_expected.to eq display_name }

    context 'blank display name' do
      let(:display_name) { }

      it { is_expected.to eq user.identifier }
    end
  end

  describe '#individual' do
    subject { user.individual }

    let(:user) { build(:user, email: 'wolverine@umich.edu') }

    it { is_expected.to be nil }

    context 'individual' do
      before { allow(Greensub::Individual).to receive(:find_by).with(email: user.email).and_return 'individual' }

      it { is_expected.to eq 'individual' }

      context 'sudo actor' do
        before do
          allow(Incognito).to receive(:sudo_actor?).with(user).and_return true
          allow(Incognito).to receive(:sudo_actor_individual).with(user).and_return 'sudo_individual'
        end

        it { is_expected.to eq 'sudo_individual' }
      end
    end
  end

  describe '#institutions' do
    subject { user.institutions }

    let(:user) { build(:user) }

    it { is_expected.to eq [] }

    context 'dlps institution' do
      let(:dlps_institution) { double('dlps_institution') }

      before { allow(Services.dlps_institution).to receive(:find).and_return ['institution'] }

      it { is_expected.to contain_exactly('institution') }

      context 'sudo actor' do
        before do
          allow(Incognito).to receive(:sudo_actor?).with(user).and_return true
          allow(Incognito).to receive(:sudo_actor_institution).with(user).and_return 'sudo_institution'
        end

        it { is_expected.to contain_exactly('sudo_institution') }
      end
    end
  end

  describe '#affiliations' do
    subject { user.affiliations(institution) }

    let(:user) { build(:user) }
    let(:institution) { build(:institution, id: 100) }
    let(:member_affiliation) { build(:institution_affiliation, institution: institution, dlps_institution_id: 101, affiliation: 'member') }
    let(:alum_affiliation) { build(:institution_affiliation, institution: institution, dlps_institution_id: 102, affiliation: 'alum') }
    let(:walk_in_affiliation) { build(:institution_affiliation, institution: institution, dlps_institution_id: 103, affiliation: 'walk-in') }
    let(:institutions) { [] }

    before { allow(user).to receive(:institutions).and_return institutions }

    it { is_expected.to eq [] }

    context 'institution' do
      let(:institutions) { [institution] }

      it { is_expected.to eq [] }

      context 'dlps institution affiliation' do
        before { allow(Services.dlps_institution_affiliation).to receive(:find).and_return [member_affiliation] }

        it { is_expected.to contain_exactly(member_affiliation) }

        context 'when sudo actor' do
          before do
            allow(Incognito).to receive(:sudo_actor?).with(user).and_return true
            allow(Incognito).to receive(:sudo_actor_institution_affiliation).with(user).and_return walk_in_affiliation
          end

          it { is_expected.to contain_exactly(walk_in_affiliation) }
        end
      end
    end
  end

  it '#grants?' do
    user = create(:user)
    product = create(:product)
    expect(user.grants?).to be false

    Authority.grant!(user, Checkpoint::Credential::Permission.new(:read), product)
    expect(user.grants?).to be true

    Authority.revoke!(user, Checkpoint::Credential::Permission.new(:read), product)
    expect(user.grants?).to be false
  end

  describe '#agent_type' do
    subject { user.agent_type }

    let(:user) { build(:user) }

    it { is_expected.to eq :User }
  end

  describe '#agent_id' do
    subject { user.agent_id }

    let(:user) { build(:user) }

    it { is_expected.to be user.id }
  end
end

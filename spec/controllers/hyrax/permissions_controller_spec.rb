# frozen_string_literal: true

# pulled from here, and altered to show we run SequentialVisibilityCopyAndInheritPermissionsJob on copy_access (HELIO-4325)
# https://github.com/samvera/hyrax/blob/4c1a99a6a52c973781dff090c2c98c044ea65e42/spec/controllers/hyrax/permissions_controller_spec.rb#L1

require 'rails_helper'

RSpec.describe Hyrax::PermissionsController, type: :controller do
  # https://relishapp.com/rspec/rspec-rails/docs/controller-specs/engine-routes-for-controllers
  routes { Hyrax::Engine.routes }


  let(:user) { FactoryBot.create(:user) }

  before do
    ActiveJob::Base.queue_adapter = :test
    sign_in user
  end

  after { ActiveJob::Base.queue_adapter = :resque }

  context 'with legacy AF models' do
    describe '#confirm_access' do
      let(:monograph) { create(:monograph, user: user) }


      it 'draws the page' do
        get :confirm_access, params: { id: monograph }
        expect(response).to be_successful
      end
    end

    describe '#copy' do
      let(:monograph) { create(:monograph, user: user) }

      it 'adds a worker to the queue' do
        expect { post :copy, params: { id: monograph } }
          .to have_enqueued_job(VisibilityCopyJob)
                .with(monograph)

        expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_monograph_path(monograph, locale: 'en')
        expect(flash[:notice]).to eq 'Updating file permissions. This may take a few minutes. You may want to refresh your browser or return to this record later to see the updated file permissions.'
      end
    end

    describe '#copy_access' do
      let(:monograph) { FactoryBot.create(:monograph_with_one_file, user: user) }

      it 'adds VisibilityCopyJob to the queue' do
        expect { post :copy_access, params: { id: monograph } }
          .not_to have_enqueued_job(VisibilityCopyJob)
                .with(monograph)

        expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_monograph_path(monograph, locale: 'en')
        expect(flash[:notice]).to eq 'Updating file access levels. This may take a few minutes. ' \
                                     'You may want to refresh your browser or return to this record ' \
                                     'later to see the updated file access levels.'
      end

      it 'adds InheritPermisionsJob to the queue' do
        expect { post :copy_access, params: { id: monograph } }
          .not_to have_enqueued_job(InheritPermissionsJob)
                .with(monograph)
      end

      # HELIOTROPE: this is the crux of adding the spec, we've combined the above jobs into one to force them to...
      # run in series
      it 'adds SequentialVisibilityCopyAndInheritPermissionsJob to the queue' do
        expect { post :copy_access, params: { id: monograph } }
          .to have_enqueued_job(SequentialVisibilityCopyAndInheritPermissionsJob)
                    .with(monograph)

        expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_monograph_path(monograph, locale: 'en')
        expect(flash[:notice]).to eq 'Updating file access levels. This may take a few minutes. ' \
                                     'You may want to refresh your browser or return to this record ' \
                                     'later to see the updated file access levels.'
      end
    end
  end
end

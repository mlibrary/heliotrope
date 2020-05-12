# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "fulcrum-dev@umich.edu"
  layout 'mailer'
end

# frozen_string_literal: true

module PressHelper
  READER_FONT_STYLESHEET = 'https://fonts.googleapis.com/css?family=Open+Sans:300,400,400i,600,600i,700'

  # Keep the original import order, including fonts shared by several themes.
  PRESS_FONT_STYLESHEETS = {
    %w[heb fia belin ncid].freeze => 'https://use.typekit.net/rqe4rki.css',
    %w[ahpi gabii].freeze => 'https://fonts.googleapis.com/css?family=Cardo|Lato:300,400&display=swap',
    %w[atg].freeze => 'https://fonts.googleapis.com/css?family=Open+Sans:400,400i,700,700i|Roboto:400,400i,700,700i&display=swap',
    %w[bigten].freeze => 'https://use.typekit.net/leo4nka.css',
    %w[boydellandbrewer].freeze => 'https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,200..800&family=Caladea:ital,wght@0,400;0,700;1,400;1,700&family=Noto+Sans:ital,wght@0,100..900;1,100..900&display=swap',
    %w[indiana].freeze => 'https://fonts.iu.edu/style.css?family=BentonSans:regular,bold|GeorgiaPro:regular',
    %w[livedplaces].freeze => 'https://fonts.googleapis.com/css2?family=Aleo:ital,wght@0,300..700;1,300..700&family=Montserrat:ital,wght@0,300..700;1,300..700&display=swap',
    %w[michigan michelt].freeze => 'https://use.typekit.net/hfw0vui.css',
    %w[mps democraticfutures fia belin].freeze => 'https://fonts.googleapis.com/css2?family=Crimson+Text:ital,wght@0,400;0,700;1,400;1,700&family=Muli:ital,wght@0,400;0,700;1,400;1,700&display=swap',
    %w[a2ru].freeze => 'https://fonts.googleapis.com/css?family=Rubik:300,400,400i,500,500i&display=swap',
    %w[um-pccn].freeze => 'https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,400;0,700;1,400;1,700&display=swap',
    %w[seas].freeze => 'https://fonts.googleapis.com/css2?family=Montserrat:ital,wght@0,300;0,400;0,600;1,300;1,400;1,600&display=swap',
    %w[rekihaku].freeze => [READER_FONT_STYLESHEET, 'https://fonts.googleapis.com/css?family=Roboto+Mono'].freeze,
    %w[vermont].freeze => 'https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Roboto:ital,wght@0,400;0,500;0,700;1,400;1,500;1,700&display=swap',
    %w[westminster].freeze => 'https://use.typekit.net/fsc5ebl.css'
  }.freeze

  mattr_accessor :press_presenter

  def press_presenter
    @press_presenter ||= if defined?(@press.subdomain)
                           PressPresenter.for(@press.subdomain)
                         elsif defined?(@presenter.subdomain)
                           PressPresenter.for(@presenter.subdomain)
                         elsif defined?(@presenter.parent.subdomain)
                           PressPresenter.for(@presenter.parent.subdomain)
                         else
                           # This will be the null object
                           PressPresenter.for(nil)
                         end
  end

  def press_font_stylesheets(reader: false)
    stylesheets = []
    if press_presenter.present?
      typekit_id = press_presenter.typekit
      stylesheets << "https://use.typekit.net/#{typekit_id}.css" if typekit_id.present?

      subdomains = press_presenter.press_subdomains
      PRESS_FONT_STYLESHEETS.each do |themes, urls|
        stylesheets.concat(Array(urls)) if (themes & subdomains).any?
      end
    end
    stylesheets << READER_FONT_STYLESHEET if reader
    stylesheets.uniq
  end
end

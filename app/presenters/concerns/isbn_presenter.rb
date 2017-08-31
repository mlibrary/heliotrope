# frozen_string_literal: true

module ISBNPresenter
  extend ActiveSupport::Concern

  def isbn?
    isbn_hardcover? || isbn_paper? || isbn_ebook?
  end

  def isbn_hardcover?
    return false unless defined? isbn
    isbn.present?
  end

  def isbn_hardcover
    isbn if defined? isbn
  end

  def isbn_paper?
    return false unless defined? isbn_paper
    isbn_paper.present?
  end

  def isbn_ebook?
    return false unless defined? isbn_ebook
    isbn_ebook.present?
  end
end

module ApplicationHelper
  def contributors_string(contributors)
    if !contributors.empty?
      conjunction = contributors.count == 1 ? ' and ' : ', '
      conjunction + contributors.to_sentence
    else
      ''
    end
  end
end

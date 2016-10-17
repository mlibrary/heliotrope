module ApplicationHelper
  def contributors_string(contributors)
    if !contributors.empty?
      conjunction = contributors.count == 1 ? ' and ' : ', '
      conjunction + contributors.to_sentence
    else
      ''
    end
  end

  def external_resource?(asset)
    asset.external_resource.first == 'yes' ? true : false
  end

  def external_resource_linked_image(asset)
    link_to image_tag('/image-service/' + asset.id + '/full/540,/0/default.jpg', alt: asset.alt_text), asset.ext_url_doi_or_handle.first, target: "_blank"
  end
end

module ApplicationHelper
  def manage_assets_btn_text
    if @presenter.human_readable_type == 'Monograph'
      t("manage_assets.monograph_link_text")
    else
      t("manage_assets.section_link_text")
    end
  end
end

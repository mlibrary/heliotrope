module RecordsHelperBehavior
  def model_label(key)
    I18n.t("hydra_editor.form.model_label.#{key}", default: key.to_s.humanize)
  end

  def object_type_options
    @object_type_options ||= HydraEditor.models.inject({}) do |h, model|
      label = model_label(model)
      h["#{label[0].upcase}#{label[1..-1]}"] = model
      h
    end
  end

  def render_edit_field_partial(field_name, locals)
    collection = locals[:f].object.model_name.collection
    render_edit_field_partial_with_action(collection, field_name, locals)
  end

  def record_form_action_url(record)
    router = respond_to?(:hydra_editor) ? hydra_editor.routes.url_helpers : self
    record.persisted? ? router.record_path(record) : router.records_path
  end

  def new_record_title
    I18n.t('hydra_editor.new.title') % model_label(params[:type])
  end

  def edit_record_title
    I18n.t('hydra_editor.edit.title') % render_record_title
  end

  def render_record_title
    Array(form.title).first
  end

protected

  # This finds a partial based on the record_type and field_name
  # if no partial exists for the record_type it tries using "records" as a default
  def render_edit_field_partial_with_action(record_type, field_name, locals)
    partial = find_edit_field_partial(record_type, field_name)
    render partial, locals.merge(key: field_name)
  end

  def find_edit_field_partial(record_type, field_name)
    ["#{record_type}/edit_fields/_#{field_name}", "records/edit_fields/_#{field_name}",
     "#{record_type}/edit_fields/_default", 'records/edit_fields/_default'].find do |partial|
      logger.debug "Looking for edit field partial #{partial}"
      return partial.sub(/\/_/, '/') if partial_exists?(partial)
    end
  end

  def partial_exists?(partial)
    lookup_context.find_all(partial).any?
  end
end

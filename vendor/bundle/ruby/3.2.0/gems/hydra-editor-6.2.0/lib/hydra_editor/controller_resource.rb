class HydraEditor::ControllerResource < CanCan::ControllerResource
  def find_resource
    ActiveFedora::Base.find(id_param)
  end

  def resource_class
    raise HydraEditor::InvalidType, 'Lost the type' unless has_valid_type?
    type_param.constantize
  end

  def has_valid_type?
    HydraEditor.valid_model? type_param
  end

  def type_param
    @params[:type]
  end
end

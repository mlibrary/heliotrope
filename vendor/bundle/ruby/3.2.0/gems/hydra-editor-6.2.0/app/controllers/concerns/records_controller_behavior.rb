module RecordsControllerBehavior
  extend ActiveSupport::Concern

  included do
    include Hydra::Controller::ControllerBehavior
    load_and_authorize_resource only: [:new, :edit, :update, :create], instance_name: resource_instance_name

    rescue_from HydraEditor::InvalidType do
      render 'records/choose_type'
    end
    helper_method :form
  end

  module ClassMethods
    def cancan_resource_class
      HydraEditor::ControllerResource
    end
    def resource_instance_name
      name.sub('Controller', '').underscore.split('/').last.singularize
    end
  end

  def new
    @form = build_form
    render 'records/new'
  end

  def edit
    @form = build_form
    render 'records/edit'
  end

  def create
    set_attributes
    respond_to do |format|
      if resource.save
        format.html { redirect_to redirect_after_create, notice: 'Object was successfully created.' }
        format.json { render json: object_as_json, status: :created, location: redirect_after_create }
      else
        format.html { new }
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    set_attributes
    respond_to do |format|
      if resource.save
        format.html { redirect_to redirect_after_update, notice: 'Object was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { edit }
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

protected

  def object_as_json
    resource.to_json
  end

  # Override this method if you want to set different metadata on the object
  def set_attributes
    resource.attributes = collect_form_attributes
  end

  def collect_form_attributes
    form_class.model_attributes(raw_attributes)
  end

  def raw_attributes
    params[ActiveModel::Naming.singular(resource)]
  end

  # Override to redirect to an alternate location after create
  def redirect_after_create
    main_app.solr_document_path resource
  end

  # Override to redirect to an alternate location after update
  def redirect_after_update
    main_app.solr_document_path resource
  end

  def has_valid_type?
    HydraEditor.models.include? params[:type]
  end

  def build_form
    form_class.new(resource)
  end

  def form_class
    @form_class ||= form_name.constantize
  rescue NameError
    raise NameError, "Unable to find a #{form_name} class"
  end

  def form_name
    if resource_instance_name == 'record'
      if params[:id]
        "#{resource.class.name}Form"
      elsif has_valid_type?
        "#{params[:type]}Form"
      else
        'RecordForm'
      end
    else
      "#{resource_instance_name.camelize}Form"
    end
  end

  def form
    @form
  end

  def resource
    get_resource_ivar
  end

  # Get resource ivar based on the current resource controller.
  #
  def get_resource_ivar # :nodoc:
    instance_variable_get("@#{resource_instance_name}")
  end

  def resource_instance_name
    self.class.resource_instance_name
  end
end

# frozen_string_literal: true
# Handles RBS attr_reader, attr_writer, and attr_accessor declarations.
#
# Registers one or two {YARD::CodeObjects::MethodObject} instances (reader
# and/or writer) with @return / @param tags derived from the RBS type.
class YARD::Handlers::RBS::AttributeHandler < YARD::Handlers::RBS::Base
  handles :attr_reader, :attr_writer, :attr_accessor

  process do
    attr_name  = statement.name
    rbs_type   = statement.attr_rbs_type
    yard_types = rbs_type ? YARD::Handlers::RBS::MethodHandler.rbs_type_to_yard_types(rbs_type) : nil
    mscope     = statement.visibility == :class ? :class : :instance

    case statement.type
    when :attr_reader
      register_reader(attr_name, yard_types, mscope)
    when :attr_writer
      register_writer(attr_name, yard_types, mscope)
    when :attr_accessor
      register_reader(attr_name, yard_types, mscope)
      register_writer(attr_name, yard_types, mscope)
    end
  end

  private

  def register_reader(name, types, scope)
    obj = register MethodObject.new(namespace, name, scope)
    if types && !obj.has_tag?(:return)
      obj.add_tag YARD::Tags::Tag.new(:return, '', types)
    end
    obj
  end

  def register_writer(name, types, scope)
    obj = register MethodObject.new(namespace, "#{name}=", scope)
    if types && !obj.has_tag?(:param)
      obj.add_tag YARD::Tags::Tag.new(:param, '', types, "value")
    end
    obj
  end
end

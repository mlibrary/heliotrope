# frozen_string_literal: true

desc 'Convert File_Set components to their parent Monograph components'
namespace :heliotrope do
  task :checkpoint_component_converter => :environment do
    def identifier(component)
      child = Sighrax.factory(component.noid)
      parent = child.parent
      identifier = component.identifier
      if ValidationService.valid_noid?(identifier)
        parent.noid
      elsif ValidationService.valid_noid?(HandleService.noid(identifier))
        parent.noid
      else
        identifier
      end
    end

    def merge_components(monograph_component, component)
      destroy_flag = true
      save_flag = true
      component_identifier = identifier(component)
      if ValidationService.valid_noid?(monograph_component.identifier) && ValidationService.valid_noid?(component_identifier)
        if monograph_component.identifier == component_identifier
          save_flag = false
        else
          puts "ERROR: merge of components with different parent noids aborted!!! '#{monograph_component.identifier}' != '#{component_identifier}'"
          destroy_flag = false
          save_flag = false
        end
      elsif ValidationService.valid_noid?(monograph_component.identifier)
        monograph_component.identifier = component_identifier
      elsif ValidationService.valid_noid?(component_identifier)
        save_flag = false
      else
        if monograph_component.identifier == component_identifier
          save_flag = false
        elsif monograph_component.identifier.length < component_identifier.length
          save_flag = false
        elsif component_identifier.length < monograph_component.identifier.length
          monograph_component.identifier = component_identifier
        else
          puts "ERROR: merge of components with ambiguous identifiers aborted!!! '#{monograph_component.identifier}' <> '#{component_identifier}'."
          destroy_flag = false
          save_flag = false
        end
      end
      if destroy_flag
        component.products.each do |product|
          product.components.delete(component)
          unless monograph_component.products.include?(product)
            puts "WARNING: merge of components has different product, adding #{product.identifier}."
            monograph_component.products << product
            save_flag = true
          end
        end
        component.destroy!
      end
      if save_flag
        monograph_component.save!
        monograph_component.reload
      end
      puts "merge: #{monograph_component.id}, #{monograph_component.noid}, #{monograph_component.identifier}, #{monograph_component.name}"
      monograph_component
    end

    def convert_component(component)
      child = Sighrax.factory(component.noid)
      parent = child.parent
      component.identifier = identifier(component)
      component.name = parent.title[0,128]
      component.noid = parent.noid
      component.save!
      component.reload
      puts "convert: #{component.id}, #{component.noid}, #{component.identifier}, #{component.name}"
      component
    end

    puts 'heliotrope:checkpoint_component_converter start'
    Component.all.each do |component|
      child = Sighrax.factory(component.noid)
      next unless child.is_a?(Sighrax::Asset)
      parent = child.parent
      monograph_component = Component.find_by(noid: parent.noid)
      if monograph_component.present?
        merge_components(monograph_component, component)
      else
        convert_component(component)
      end
    end
    puts 'heliotrope:checkpoint_component_converter fin'
  end
end

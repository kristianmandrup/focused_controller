require 'focused_controller/focused_action'

module FocusedController
  module Macros
    def action_parent clazz
      @default_focused_action ||= clazz
    end

    def get_action_parent
      @default_focused_action ||= ::FocusedAction
    end

    # Usage:
    # focused_action :index do
    #   run do
    #     redirect_to root_path
    #   end
    # end

    # focused_action :index, ServiceAction do
    #   run do
    #     service_for :index
    #   end
    # end
    def focused_action name, parent = nil, &block
      container_modules = self.name.split('::')
      clazz_name = name.to_s.camelize
      parent ||= get_action_parent
      clazz = parent ? Class.new(parent) : Class.new
      self.const_set clazz_name, clazz
      if block_given?
        self.const_get(clazz_name).class_eval &block      
      else
        self.const_get(clazz_name).class_eval do
          def run
            puts "Focused action: #{clazz_name}"
          end
        end
      end
    end
  end
end

class Module
  def use_focused_macros
    extend FocusedController::Macros
  end    
end

require 'focused_controller/focused_action'

module FocusedController
  module Macros
    def action_parent clazz
      @default_action_parent ||= clazz
    end

    def get_action_parent
      @default_action_parent ||= ::FocusedAction
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
      clazz_name = name.to_s.camelize      
      clazz = Class.new(parent || get_action_parent)
      self.const_set clazz_name, clazz
      if block_given?
        self.const_get(clazz_name).class_eval &block
      end
    end
  end
end

class Module
  def use_focused_macros
    extend FocusedController::Macros
  end    
end

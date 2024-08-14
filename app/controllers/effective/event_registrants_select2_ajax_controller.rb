module Effective
  class EventRegistrantsSelect2AjaxController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::Select2AjaxController

    def users
      authorize! :users, Effective::EventRegistrant

      collection = current_user.class.all

      respond_with_select2_ajax(collection, skip_authorize: true) do |user|
        data = { first_name: user.first_name, last_name: user.last_name, email: user.email }

        { 
          id: user.to_param, 
          text: user.try(:to_select2) || to_select2(user),
          data: data
        }
      end
    end

  end
end

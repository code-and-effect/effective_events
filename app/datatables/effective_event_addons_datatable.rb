# Used on the Event Registrations Addons step

class EffectiveEventAddonsDatatable < Effective::Datatable
  datatable do

    col :event_product, search: :string, label: 'Product' do |er|
      [
        er.event_product.to_s,
        (content_tag(:span, 'Archived', class: 'badge badge-warning') if er.event_product&.archived?)
      ].compact.join('<br>').html_safe
    end

    col :price, as: :price

    col :archived, visible: false

    # col :notes
    # no actions_col
  end

  collection do
    scope = Effective::EventAddon.deep.all

    if event.present?
      scope = scope.where(event: event)
    end

    if event_registration.present?
      scope = scope.where(event_registration_id: event_registration)
    end

    scope
  end

  def event
    @event ||= if attributes[:event_id]
      Effective::Event.find(attributes[:event_id])
    end
  end

  def event_registration
    @event_registration ||= if attributes[:event_registration_id]
      EffectiveEvents.EventRegistration.find_by_id(attributes[:event_registration_id])
    end
  end

end

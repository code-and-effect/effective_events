class Admin::EffectiveEventRegistrationsDatatable < Effective::Datatable
  datatable do
    order :created_at

    col :token, visible: false

    col :created_at, label: 'Created', visible: false
    col :updated_at, label: 'Updated', visible: false

    col :submitted_at, label: 'Submitted', visible: false, as: :date

    col :event, search: :string
    col :owner

    col :event_registrants, search: :string
    col :event_addons, search: :string
    col :orders, label: 'Order'

    actions_col
  end

  collection do
    EffectiveEvents.EventRegistration.all.deep.done
  end

end

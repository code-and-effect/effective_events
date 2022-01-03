module Admin
  class EffectiveEventsDatatable < Effective::Datatable
    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :title
      col :start_at
      col :end_at
      col :registration_start_at
      col :registration_end_at
      col :early_bird_end_at

      col :event_tickets
      col :event_registrants

      actions_col
    end

    collection do
      Effective::Event.deep.all
    end

  end
end

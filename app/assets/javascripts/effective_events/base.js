// For the Ticket Details screen
$(document).on('select2:select', '[data-event-registrant-user-search]', function(event) {
  var data = event.params.data['data'];
  var $form = $(event.currentTarget).closest('.event-registrant-user-fields')

  // Set the organization_id
  $form.find('input[type="hidden"][name$="[organization_id]"]').val(data.organization_id || '')
  $form.find('input[type="hidden"][name$="[organization_type]"]').val(data.organization_type || '')

  // Disable everything else
  $form.find('input[name$="[first_name]"]').val(data.first_name || '').prop('disabled', true)
  $form.find('input[name$="[last_name]"]').val(data.last_name || '').prop('disabled', true)
  $form.find('input[name$="[email]"]').val(data.email || '').prop('disabled', true)

  $form.find('select[name$="[organization_id]"]').val(data.organization_id || '').trigger('change').prop('disabled', true)
  $form.find('input[name$="[company]"]').val(data.company || '').prop('disabled', true)
});

$(document).on('select2:unselect', '[data-event-registrant-user-search]', function(event) {
  var $form = $(event.currentTarget).closest('.event-registrant-user-fields')

  // Unset the organization_id
  $form.find('input[type="hidden"][name$="[organization_id]"]').val('')
  $form.find('input[type="hidden"][name$="[organization_type]"]').val('')

  // Enable everything else
  $form.find('input[name$="[first_name]"]').val('').prop('disabled', false)
  $form.find('input[name$="[last_name]"]').val('').prop('disabled', false)
  $form.find('input[name$="[email]"]').val('').prop('disabled', false)

  $form.find('select[name$="[organization_id]"]').val('').trigger('change').prop('disabled', false)
  $form.find('input[name$="[company]"]').val('').prop('disabled', false)
});

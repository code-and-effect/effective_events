// For the Ticket Details screen
$(document).on('select2:select', '[data-event-registrant-user-search]', function(event) {
  var data = event.params.data['data'];
  var $form = $(event.currentTarget).closest('.event-registrant-user-fields')

  $form.find('[name$="[first_name]"]').val(data.first_name || '').prop('readonly', true)
  $form.find('[name$="[last_name]"]').val(data.last_name || '').prop('readonly', true)
  $form.find('[name$="[email]"]').val(data.email || '').prop('readonly', true)
  $form.find('[name$="[company]"]').val(data.company || '').prop('readonly', true)
});

$(document).on('select2:unselect', '[data-event-registrant-user-search]', function(event) {
  var $form = $(event.currentTarget).closest('.event-registrant-user-fields')

  $form.find('[name$="[first_name]"]').val('').prop('readonly', false)
  $form.find('[name$="[last_name]"]').val('').prop('readonly', false)
  $form.find('[name$="[email]"]').val('').prop('readonly', false)
  $form.find('[name$="[company]"]').val('').prop('readonly', false)
});

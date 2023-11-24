module EffectiveEventsTestHelper

  def sign_in(user = create_user!)
    login_as(user, scope: :user); user
  end

  def as_user(user, &block)
    sign_in(user); yield; logout(:user)
  end

  def create_user!
    build_user.tap { |user| user.save! }
  end

  def build_user
    @user_index ||= 0
    @user_index += 1

    User.new(
      email: "user#{@user_index}@example.com",
      password: 'rubicon2020',
      password_confirmation: 'rubicon2020',
      first_name: 'Test',
      last_name: 'User'
    )
  end

  def build_user_with_address
    user = build_user()

    user.addresses.build(
      addressable: user,
      category: 'billing',
      full_name: 'Test User',
      address1: '1234 Fake Street',
      city: 'Victoria',
      state_code: 'BC',
      country_code: 'CA',
      postal_code: 'H0H0H0'
    )

    user.save!
    user
  end

  # assert_email :new_user_sign_up
  # assert_email :new_user_sign_up, to: 'newuser@example.com'
  # assert_email from: 'admin@example.com'
  def assert_email(action = nil, to: nil, from: nil, subject: nil, body: nil, message: nil, count: nil, &block)
    retval = nil

    if block_given?
      before = ActionMailer::Base.deliveries.length
      retval = yield

      difference = (ActionMailer::Base.deliveries.length - before)

      if count.present?
        assert (difference == count), "(assert_email) Expected #{count} email to have been delivered, but #{difference} were instead"
      else
        assert (difference > 0), "(assert_email) Expected at least one email to have been delivered"
      end
    end

    if (action || to || from || subject || body).nil?
      assert ActionMailer::Base.deliveries.present?, message || "(assert_email) Expected email to have been delivered"
      return retval
    end

    actions = ActionMailer::Base.instance_variable_get(:@mailer_actions)

    ActionMailer::Base.deliveries.each do |message|
      matches = true

      matches &&= (actions.include?(action.to_s)) if action
      matches &&= (Array(message.to).include?(to)) if to
      matches &&= (Array(message.from).include?(from)) if from
      matches &&= (message.subject == subject) if subject
      matches &&= (message.body == body) if body

      return retval if matches
    end

    expected = [
      ("action: #{action}" if action),
      ("to: #{to}" if to),
      ("from: {from}" if from),
      ("subject: #{subject}" if subject),
      ("body: #{body}" if body),
    ].compact.to_sentence

    assert false, message || "(assert_email) Expected email with #{expected} to have been delivered"
  end

end

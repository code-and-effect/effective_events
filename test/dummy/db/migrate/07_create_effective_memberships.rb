class CreateEffectiveMemberships < ActiveRecord::Migration[6.0]
  def change

    # Categories
    create_table :categories do |t|
      t.string :category_type       # Individual or Organization

      t.string :title
      t.string :category            # Freeform

      t.integer :position

      # Applicants
      t.boolean :can_apply_new, default: false
      t.boolean :can_apply_existing, default: false
      t.boolean :can_apply_restricted, default: false
      t.text :can_apply_restricted_ids

      t.integer :applicant_fee
      t.integer :applicant_reinstatement_fee
      t.text :applicant_wizard_steps

      t.string :applicant_cpd_step_requirement
      t.integer :min_applicant_educations
      t.integer :min_applicant_experiences_months
      t.integer :min_applicant_references
      t.integer :min_applicant_endorsements
      t.integer :min_applicant_equivalences
      t.integer :min_applicant_courses
      t.integer :min_applicant_files

      t.integer :min_applicant_reviews
      t.text :applicant_review_wizard_steps

      t.integer :prorated_jan
      t.integer :prorated_feb
      t.integer :prorated_mar
      t.integer :prorated_apr
      t.integer :prorated_may
      t.integer :prorated_jun
      t.integer :prorated_jul
      t.integer :prorated_aug
      t.integer :prorated_sep
      t.integer :prorated_oct
      t.integer :prorated_nov
      t.integer :prorated_dec

      # Renewals
      t.text :fee_payment_wizard_steps
      t.string :fee_payment_cpd_step_requirement

      t.boolean :create_renewal_fees, default: false
      t.integer :renewal_fee

      t.boolean :create_early_fees, default: false
      t.integer :early_fee

      t.boolean :create_late_fees, default: false
      t.integer :late_fee

      t.boolean :create_not_in_good_standing, default: false

      t.string :qb_item_name
      t.boolean :tax_exempt, default: false

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :categories, :title
    add_index :categories, :position

    # Statuses
    create_table :statuses do |t|
      t.string :status_type         # Individual or Organization

      t.string :title
      t.string :status              # Freeform

      t.integer :position

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :statuses, :title
    add_index :statuses, :position

    # Memberships
    create_table :memberships do |t|
      t.integer :owner_id
      t.string :owner_type

      t.text :title

      t.string :number
      t.integer :number_as_integer

      t.date :joined_on
      t.date :registration_on
      t.date :fees_paid_period
      t.date :fees_paid_through_period

      t.string :owner_name
      t.string :token

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :memberships, [:owner_id, :owner_type], unique: true
    add_index :memberships, :number

    # Membership Categories Join table
    create_table :membership_categories do |t|
      t.integer :category_id
      t.string :category_type

      t.integer :membership_id
      t.string :membership_type

      t.string :title

      t.datetime :updated_at
      t.datetime :created_at
    end

    # Membership Statuses Join table
    create_table :membership_statuses do |t|
      t.integer :status_id
      t.string :status_type

      t.integer :membership_id
      t.string :membership_type

      t.string :title

      t.datetime :updated_at
      t.datetime :created_at
    end

    # Membership Histories
    create_table :membership_histories do |t|
      t.integer :owner_id
      t.string :owner_type

      t.text :title

      t.text :categories
      t.text :category_ids

      t.text :statuses
      t.text :status_ids

      t.date :start_on
      t.date :end_on

      t.string :number

      t.boolean :removed, default: false

      t.text :notes

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :membership_histories, [:owner_id, :owner_type]
    add_index :membership_histories, :start_on

    # Organizations
    create_table :organizations do |t|
      t.string    :email

      t.string    :title

      t.string    :phone
      t.string    :fax
      t.string    :website

      t.string    :category
      t.text      :notes

      t.integer   :roles_mask
      t.boolean   :archived, default: false

      t.integer   :representatives_count, default: 0

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :organizations, :title

    # Representatives
    create_table :representatives do |t|
      t.integer :organization_id
      t.string :organization_type

      t.string :title

      t.integer :user_id
      t.string :user_type

      t.integer :roles_mask
      t.boolean :display_on_directory, :boolean, default: false

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :representatives, [:organization_id, :organization_type]
    add_index :representatives, [:user_id, :user_type]

    # Applicants
    create_table :applicants do |t|
      t.string :applicant_type
      t.string :stream
      t.string :token

      t.text :title

      t.integer :user_id
      t.string :user_type

      t.integer :organization_id
      t.string :organization_type

      t.integer :category_id
      t.string :category_type

      t.integer :from_category_id
      t.string :from_category_type

      t.integer :from_status_id
      t.string :from_status_type

      # Acts as Statused
      t.string :status
      t.text :status_steps

      # Acts as Wizard
      t.text :wizard_steps

      # Dates
      t.datetime :submitted_at
      t.datetime :completed_at
      t.datetime :reviewed_at
      t.datetime :approved_at

      # Declined
      t.datetime :declined_at
      t.text :declined_reason

      # Missing
      t.datetime :missing_info_at
      t.text :missing_info_reason

      # Applicant Educations
      t.text :applicant_educations_details

      # Applicant Experiences
      t.integer :applicant_experiences_months
      t.text :applicant_experiences_details

      # Transcripts
      t.date :transcripts_received_on
      t.string :transcripts_status
      t.text :transcripts_details

      # Additional Information
      t.text :additional_information

      # Flagged
      t.boolean :flagged, default: false
      t.datetime :flagged_at
      t.text :flagged_reason

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :applicants, [:user_id, :user_type]
    add_index :applicants, [:organization_id, :organization_type]
    add_index :applicants, :status
    add_index :applicants, :token

    # Applicant Educations
    create_table :applicant_educations do |t|
      t.integer :applicant_id
      t.string :applicant_type

      t.date :start_on
      t.date :end_on

      t.string :institution
      t.string :location

      t.string :degree_obtained

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :applicant_educations, :applicant_id
    add_index :applicant_educations, :start_on

    # Applicant Experiences
    create_table :applicant_experiences do |t|
      t.integer :applicant_id
      t.string :applicant_type

      t.string :level
      t.integer :months

      t.date :start_on
      t.date :end_on

      t.string :position
      t.string :employer

      t.boolean :still_work_here, default: false
      t.integer :percent_worked

      t.text :tasks_performed

      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index :applicant_experiences, :applicant_id
    add_index :applicant_experiences, :start_on

    # Applicant References
    create_table :applicant_references do |t|
      t.integer :applicant_id
      t.string :applicant_type

      t.string :name
      t.string :email
      t.string :phone
      t.string :known
      t.string :relationship

      t.string :status
      t.text :status_steps

      t.string :title
      t.string :company

      t.boolean :regulated_professional, default: false
      t.string :regulated_professional_title
      t.string :regulated_professional_number

      t.text :work_history
      t.boolean :reservations
      t.text :reservations_reason
      t.string :recommendation
      t.text :recommendation_reason
      t.boolean :accept_declaration

      t.string :token
      t.datetime :last_notified_at

      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index :applicant_references, :applicant_id
    add_index :applicant_references, :token

    # Applicant Endorsements
    create_table :applicant_endorsements do |t|
      t.integer :applicant_id
      t.string :applicant_type

      t.integer :endorser_id
      t.string :endorser_type

      t.string :title

      t.boolean :unknown_member, default: false
      t.string :endorser_email
      t.string :name
      t.string :phone

      t.string :status
      t.text :status_steps

      t.text :notes
      t.boolean :accept_declaration

      t.string :token
      t.datetime :last_notified_at

      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index :applicant_endorsements, :applicant_id
    add_index :applicant_endorsements, :token

    # Applicant Equivalences
    create_table :applicant_equivalences do |t|
      t.integer :applicant_id
      t.string :applicant_type

      t.string :name

      t.date :start_on
      t.date :end_on

      t.text :notes

      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index :applicant_equivalences, :applicant_id

    # Applicant Courses
    create_table :applicant_course_areas do |t|
      t.string :title
      t.integer :position

      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :applicant_course_names do |t|
      t.integer :applicant_course_area_id

      t.string :title
      t.integer :position

      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :applicant_courses do |t|
      t.integer :applicant_course_area_id
      t.integer :applicant_course_name_id

      t.integer :applicant_id
      t.string :applicant_type

      t.string  :title
      t.integer :amount

      t.string  :code
      t.text    :description

      t.datetime :created_at
      t.datetime :updated_at
    end

    # Applicant Reviews
    create_table :applicant_reviews do |t|
      t.string :token

      t.integer :applicant_id
      t.string :applicant_type

      t.integer :reviewer_id
      t.string :reviewer_type

      t.text :title

      # Acts as Statused
      t.string :status
      t.text :status_steps

      # Acts as Wizard
      t.text :wizard_steps

      # Dates
      t.datetime :submitted_at

      # Recommendation
      t.string :recommendation
      t.text :comments

      # Steps
      t.boolean :conflict_of_interest
      t.boolean :education_accepted
      t.boolean :course_amounts_accepted
      t.boolean :courses_accepted
      t.boolean :experience_accepted
      t.boolean :references_accepted
      t.boolean :files_accepted

      t.timestamps
    end

    # Fees
    create_table :fees do |t|
      t.integer :category_id
      t.string :category_type

      t.integer :from_category_id
      t.string :from_category_type

      t.integer :with_status_id
      t.string :with_status_type

      t.string :fee_type
      t.string :checkout_type

      t.integer :purchased_order_id
      t.datetime :purchased_at

      t.integer :owner_id
      t.string :owner_type

      t.integer :parent_id
      t.string :parent_type

      t.date :period
      t.date :late_on
      t.date :not_in_good_standing_on

      t.string :title
      t.integer :price

      t.string :qb_item_name
      t.boolean :tax_exempt, default: false

      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index :fees, :fee_type
    add_index :fees, :purchased_order_id
    add_index :fees, :category_id

    add_index :fees, [:owner_id, :owner_type]
    add_index :fees, [:parent_id, :parent_type]

    # Fee Payments
    create_table :fee_payments do |t|
      t.string :token

      t.integer :user_id
      t.string :user_type

      t.integer :organization_id
      t.string :organization_type

      t.integer :category_id
      t.string :category_type

      t.integer :with_status_id
      t.string :with_status_type

      t.date :period

      # Acts as Statused
      t.string :status
      t.text :status_steps

      # Acts as Wizard
      t.text :wizard_steps

      # Dates
      t.datetime :submitted_at

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :fee_payments, [:user_id, :user_type]
    add_index :fee_payments, [:organization_id, :organization_type]
    add_index :fee_payments, :status
    add_index :fee_payments, :token

    # Documents
    create_table :documents do |t|
      t.integer :owner_id
      t.string :owner_type

      t.string :title
      t.string :category
      t.boolean :display_to_owner

      t.text :notes

      t.timestamps
    end

  end
end

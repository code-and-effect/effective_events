# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 101) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "address1"
    t.string "address2"
    t.integer "addressable_id"
    t.string "addressable_type"
    t.string "category", limit: 64
    t.string "city"
    t.string "country_code"
    t.datetime "created_at", precision: nil
    t.string "full_name"
    t.string "postal_code"
    t.string "state_code"
    t.datetime "updated_at", precision: nil
    t.index ["addressable_id"], name: "index_addresses_on_addressable_id"
    t.index ["addressable_type", "addressable_id"], name: "index_addresses_on_addressable_type_and_addressable_id"
  end

  create_table "applicant_course_areas", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", precision: nil
  end

  create_table "applicant_course_names", force: :cascade do |t|
    t.integer "applicant_course_area_id"
    t.datetime "created_at", precision: nil
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", precision: nil
  end

  create_table "applicant_courses", force: :cascade do |t|
    t.integer "amount"
    t.integer "applicant_course_area_id"
    t.integer "applicant_course_name_id"
    t.integer "applicant_id"
    t.string "applicant_type"
    t.string "code"
    t.datetime "created_at", precision: nil
    t.text "description"
    t.string "title"
    t.datetime "updated_at", precision: nil
  end

  create_table "applicant_educations", force: :cascade do |t|
    t.integer "applicant_id"
    t.string "applicant_type"
    t.datetime "created_at", precision: nil
    t.string "degree_obtained"
    t.date "end_on"
    t.string "institution"
    t.string "location"
    t.date "start_on"
    t.datetime "updated_at", precision: nil
    t.index ["applicant_id"], name: "index_applicant_educations_on_applicant_id"
    t.index ["start_on"], name: "index_applicant_educations_on_start_on"
  end

  create_table "applicant_endorsements", force: :cascade do |t|
    t.boolean "accept_declaration"
    t.integer "applicant_id"
    t.string "applicant_type"
    t.datetime "created_at", precision: nil
    t.string "endorser_email"
    t.integer "endorser_id"
    t.string "endorser_type"
    t.datetime "last_notified_at", precision: nil
    t.string "name"
    t.text "notes"
    t.string "phone"
    t.string "status"
    t.text "status_steps"
    t.string "title"
    t.string "token"
    t.boolean "unknown_member", default: false
    t.datetime "updated_at", precision: nil
    t.index ["applicant_id"], name: "index_applicant_endorsements_on_applicant_id"
    t.index ["token"], name: "index_applicant_endorsements_on_token"
  end

  create_table "applicant_equivalences", force: :cascade do |t|
    t.integer "applicant_id"
    t.string "applicant_type"
    t.datetime "created_at", precision: nil
    t.date "end_on"
    t.string "name"
    t.text "notes"
    t.date "start_on"
    t.datetime "updated_at", precision: nil
    t.index ["applicant_id"], name: "index_applicant_equivalences_on_applicant_id"
  end

  create_table "applicant_experiences", force: :cascade do |t|
    t.integer "applicant_id"
    t.string "applicant_type"
    t.datetime "created_at", precision: nil
    t.string "employer"
    t.date "end_on"
    t.string "level"
    t.integer "months"
    t.integer "percent_worked"
    t.string "position"
    t.date "start_on"
    t.boolean "still_work_here", default: false
    t.text "tasks_performed"
    t.datetime "updated_at", precision: nil
    t.index ["applicant_id"], name: "index_applicant_experiences_on_applicant_id"
    t.index ["start_on"], name: "index_applicant_experiences_on_start_on"
  end

  create_table "applicant_references", force: :cascade do |t|
    t.boolean "accept_declaration"
    t.integer "applicant_id"
    t.string "applicant_type"
    t.string "company"
    t.datetime "created_at", precision: nil
    t.string "email"
    t.string "known"
    t.datetime "last_notified_at", precision: nil
    t.string "name"
    t.string "phone"
    t.string "recommendation"
    t.text "recommendation_reason"
    t.boolean "regulated_professional", default: false
    t.string "regulated_professional_number"
    t.string "regulated_professional_title"
    t.string "relationship"
    t.boolean "reservations"
    t.text "reservations_reason"
    t.string "status"
    t.text "status_steps"
    t.string "title"
    t.string "token"
    t.datetime "updated_at", precision: nil
    t.text "work_history"
    t.index ["applicant_id"], name: "index_applicant_references_on_applicant_id"
    t.index ["token"], name: "index_applicant_references_on_token"
  end

  create_table "applicant_reviews", force: :cascade do |t|
    t.integer "applicant_id"
    t.string "applicant_type"
    t.text "comments"
    t.boolean "conflict_of_interest"
    t.boolean "course_amounts_accepted"
    t.boolean "courses_accepted"
    t.datetime "created_at", null: false
    t.boolean "education_accepted"
    t.boolean "experience_accepted"
    t.boolean "files_accepted"
    t.string "recommendation"
    t.boolean "references_accepted"
    t.integer "reviewer_id"
    t.string "reviewer_type"
    t.string "status"
    t.text "status_steps"
    t.datetime "submitted_at", precision: nil
    t.text "title"
    t.string "token"
    t.datetime "updated_at", null: false
    t.text "wizard_steps"
  end

  create_table "applicants", force: :cascade do |t|
    t.text "additional_information"
    t.text "applicant_educations_details"
    t.text "applicant_experiences_details"
    t.integer "applicant_experiences_months"
    t.string "applicant_type"
    t.datetime "approved_at", precision: nil
    t.integer "category_id"
    t.string "category_type"
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "declined_at", precision: nil
    t.text "declined_reason"
    t.boolean "flagged", default: false
    t.datetime "flagged_at", precision: nil
    t.text "flagged_reason"
    t.integer "from_category_id"
    t.string "from_category_type"
    t.integer "from_status_id"
    t.string "from_status_type"
    t.datetime "missing_info_at", precision: nil
    t.text "missing_info_reason"
    t.integer "organization_id"
    t.string "organization_type"
    t.datetime "reviewed_at", precision: nil
    t.string "status"
    t.text "status_steps"
    t.string "stream"
    t.datetime "submitted_at", precision: nil
    t.text "title"
    t.string "token"
    t.text "transcripts_details"
    t.date "transcripts_received_on"
    t.string "transcripts_status"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "user_type"
    t.text "wizard_steps"
    t.index ["organization_id", "organization_type"], name: "index_applicants_on_organization_id_and_organization_type"
    t.index ["status"], name: "index_applicants_on_status"
    t.index ["token"], name: "index_applicants_on_token"
    t.index ["user_id", "user_type"], name: "index_applicants_on_user_id_and_user_type"
  end

  create_table "cart_items", force: :cascade do |t|
    t.integer "cart_id"
    t.datetime "created_at", null: false
    t.integer "purchasable_id"
    t.string "purchasable_type"
    t.integer "quantity"
    t.string "unique"
    t.datetime "updated_at", null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["purchasable_id"], name: "index_cart_items_on_purchasable_id"
    t.index ["purchasable_type", "purchasable_id"], name: "index_cart_items_on_purchasable_type_and_purchasable_id"
  end

  create_table "carts", force: :cascade do |t|
    t.integer "cart_items_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "user_type"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "applicant_cpd_step_requirement"
    t.integer "applicant_fee"
    t.integer "applicant_reinstatement_fee"
    t.text "applicant_review_wizard_steps"
    t.text "applicant_wizard_steps"
    t.boolean "can_apply_existing", default: false
    t.boolean "can_apply_new", default: false
    t.boolean "can_apply_restricted", default: false
    t.text "can_apply_restricted_ids"
    t.string "category"
    t.string "category_type"
    t.boolean "create_early_fees", default: false
    t.boolean "create_late_fees", default: false
    t.boolean "create_not_in_good_standing", default: false
    t.boolean "create_renewal_fees", default: false
    t.datetime "created_at", precision: nil
    t.integer "early_fee"
    t.string "fee_payment_cpd_step_requirement"
    t.text "fee_payment_wizard_steps"
    t.integer "late_fee"
    t.integer "min_applicant_courses"
    t.integer "min_applicant_educations"
    t.integer "min_applicant_endorsements"
    t.integer "min_applicant_equivalences"
    t.integer "min_applicant_experiences_months"
    t.integer "min_applicant_files"
    t.integer "min_applicant_references"
    t.integer "min_applicant_reviews"
    t.integer "position"
    t.integer "prorated_apr"
    t.integer "prorated_aug"
    t.integer "prorated_dec"
    t.integer "prorated_feb"
    t.integer "prorated_jan"
    t.integer "prorated_jul"
    t.integer "prorated_jun"
    t.integer "prorated_mar"
    t.integer "prorated_may"
    t.integer "prorated_nov"
    t.integer "prorated_oct"
    t.integer "prorated_sep"
    t.string "qb_item_name"
    t.integer "renewal_fee"
    t.boolean "tax_exempt", default: false
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.index ["position"], name: "index_categories_on_position"
    t.index ["title"], name: "index_categories_on_title"
  end

  create_table "customers", force: :cascade do |t|
    t.string "active_card"
    t.datetime "created_at", null: false
    t.string "payment_method_id"
    t.string "status"
    t.string "stripe_customer_id"
    t.integer "subscriptions_count", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "user_type"
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.boolean "display_to_owner"
    t.text "notes"
    t.integer "owner_id"
    t.string "owner_type"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "bcc"
    t.text "body"
    t.string "cc"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "from"
    t.string "subject"
    t.string "template_name"
    t.datetime "updated_at", null: false
  end

  create_table "event_addons", force: :cascade do |t|
    t.boolean "archived", default: false
    t.datetime "created_at", null: false
    t.boolean "created_by_admin", default: false
    t.string "email"
    t.integer "event_id"
    t.integer "event_product_id"
    t.integer "event_registration_id"
    t.string "event_registration_type"
    t.string "first_name"
    t.string "last_name"
    t.text "notes"
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "price"
    t.integer "purchased_order_id"
    t.datetime "updated_at", null: false
    t.index ["event_product_id"], name: "index_event_addons_on_event_product_id"
    t.index ["event_registration_id"], name: "index_event_addons_on_event_registration_id"
  end

  create_table "event_notifications", force: :cascade do |t|
    t.string "bcc"
    t.text "body"
    t.string "category"
    t.string "cc"
    t.datetime "completed_at", precision: nil
    t.string "content_type"
    t.datetime "created_at", precision: nil
    t.integer "event_id"
    t.string "from"
    t.integer "reminder"
    t.datetime "started_at", precision: nil
    t.string "subject"
    t.datetime "updated_at", precision: nil
    t.index ["event_id"], name: "index_event_notifications_on_event_id"
  end

  create_table "event_products", force: :cascade do |t|
    t.boolean "archived", default: false
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.integer "event_id"
    t.integer "position"
    t.integer "price"
    t.string "qb_item_name"
    t.boolean "tax_exempt", default: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_products_on_event_id"
    t.index ["position"], name: "index_event_products_on_position"
  end

  create_table "event_registrants", force: :cascade do |t|
    t.boolean "archived", default: false
    t.boolean "blank_registrant", default: false
    t.datetime "cancelled_at", precision: nil
    t.string "company"
    t.datetime "created_at", null: false
    t.boolean "created_by_admin", default: false
    t.string "email"
    t.integer "event_id"
    t.integer "event_registration_id"
    t.string "event_registration_type"
    t.integer "event_ticket_id"
    t.string "first_name"
    t.string "last_name"
    t.string "member_or_non_member_choice"
    t.text "notes"
    t.string "number"
    t.integer "organization_id"
    t.string "organization_type"
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "price"
    t.boolean "promoted", default: false
    t.integer "purchased_order_id"
    t.datetime "registered_at", precision: nil
    t.text "response1"
    t.text "response2"
    t.text "response3"
    t.datetime "selected_at", precision: nil
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "user_type"
    t.boolean "waitlisted", default: false
    t.index ["archived"], name: "index_event_registrants_on_archived"
    t.index ["event_registration_id"], name: "index_event_registrants_on_event_registration_id"
    t.index ["event_ticket_id"], name: "index_event_registrants_on_event_ticket_id"
    t.index ["registered_at"], name: "index_event_registrants_on_registered_at"
  end

  create_table "event_registrations", force: :cascade do |t|
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil
    t.integer "event_id"
    t.integer "owner_id"
    t.string "owner_type"
    t.string "status"
    t.text "status_steps"
    t.datetime "submitted_at", precision: nil
    t.string "token"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "user_type"
    t.text "wizard_steps"
    t.index ["owner_id", "owner_type"], name: "index_event_registrations_on_owner_id_and_owner_type"
    t.index ["status"], name: "index_event_registrations_on_status"
    t.index ["token"], name: "index_event_registrations_on_token"
  end

  create_table "event_ticket_selections", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "event_registration_id"
    t.string "event_registration_type"
    t.string "event_ticket_id"
    t.integer "quantity"
    t.datetime "updated_at", precision: nil
    t.index ["event_registration_id"], name: "index_event_ticket_selections_on_event_registration_id"
  end

  create_table "event_tickets", force: :cascade do |t|
    t.boolean "archived", default: false
    t.integer "capacity"
    t.string "category"
    t.datetime "created_at", null: false
    t.boolean "display_capacity", default: false
    t.integer "early_bird_price"
    t.integer "event_id"
    t.boolean "guest_of_member", default: false
    t.integer "guest_of_member_price"
    t.integer "member_price"
    t.integer "non_member_price"
    t.integer "position"
    t.string "qb_item_name"
    t.text "question1"
    t.boolean "question1_required", default: false
    t.text "question2"
    t.boolean "question2_required", default: false
    t.text "question3"
    t.boolean "question3_required", default: false
    t.boolean "tax_exempt", default: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.boolean "waitlist", default: false
    t.index ["event_id"], name: "index_event_tickets_on_event_id"
    t.index ["title"], name: "index_event_tickets_on_title"
  end

  create_table "events", force: :cascade do |t|
    t.boolean "allow_blank_registrants", default: false
    t.boolean "authenticate_user", default: false
    t.string "category"
    t.datetime "created_at", null: false
    t.boolean "delayed_payment", default: false
    t.date "delayed_payment_date"
    t.datetime "early_bird_end_at", precision: nil
    t.datetime "end_at", precision: nil
    t.integer "event_addons_count", default: 0
    t.integer "event_registrants_count", default: 0
    t.boolean "external_registration", default: false
    t.string "external_registration_url"
    t.boolean "legacy_draft", default: false
    t.datetime "published_end_at", precision: nil
    t.datetime "published_start_at", precision: nil
    t.datetime "registration_end_at", precision: nil
    t.datetime "registration_start_at", precision: nil
    t.integer "roles_mask"
    t.string "slug"
    t.datetime "start_at", precision: nil
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["end_at"], name: "index_events_on_end_at"
    t.index ["title"], name: "index_events_on_title"
  end

  create_table "fee_payments", force: :cascade do |t|
    t.integer "category_id"
    t.string "category_type"
    t.datetime "created_at", precision: nil
    t.integer "organization_id"
    t.string "organization_type"
    t.date "period"
    t.string "status"
    t.text "status_steps"
    t.datetime "submitted_at", precision: nil
    t.string "token"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "user_type"
    t.integer "with_status_id"
    t.string "with_status_type"
    t.text "wizard_steps"
    t.index ["organization_id", "organization_type"], name: "index_fee_payments_on_organization_id_and_organization_type"
    t.index ["status"], name: "index_fee_payments_on_status"
    t.index ["token"], name: "index_fee_payments_on_token"
    t.index ["user_id", "user_type"], name: "index_fee_payments_on_user_id_and_user_type"
  end

  create_table "fees", force: :cascade do |t|
    t.integer "category_id"
    t.string "category_type"
    t.string "checkout_type"
    t.datetime "created_at", precision: nil
    t.string "fee_type"
    t.integer "from_category_id"
    t.string "from_category_type"
    t.date "late_on"
    t.date "not_in_good_standing_on"
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "parent_id"
    t.string "parent_type"
    t.date "period"
    t.integer "price"
    t.datetime "purchased_at", precision: nil
    t.integer "purchased_order_id"
    t.string "qb_item_name"
    t.boolean "tax_exempt", default: false
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.integer "with_status_id"
    t.string "with_status_type"
    t.index ["category_id"], name: "index_fees_on_category_id"
    t.index ["fee_type"], name: "index_fees_on_fee_type"
    t.index ["owner_id", "owner_type"], name: "index_fees_on_owner_id_and_owner_type"
    t.index ["parent_id", "parent_type"], name: "index_fees_on_parent_id_and_parent_type"
    t.index ["purchased_order_id"], name: "index_fees_on_purchased_order_id"
  end

  create_table "item_names", force: :cascade do |t|
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.string "name"
    t.datetime "updated_at", precision: nil
    t.index ["name", "archived"], name: "index_item_names_on_name_and_archived"
  end

  create_table "membership_categories", force: :cascade do |t|
    t.integer "category_id"
    t.string "category_type"
    t.datetime "created_at", precision: nil
    t.integer "membership_id"
    t.string "membership_type"
    t.string "title"
    t.datetime "updated_at", precision: nil
  end

  create_table "membership_histories", force: :cascade do |t|
    t.text "categories"
    t.text "category_ids"
    t.datetime "created_at", precision: nil
    t.date "end_on"
    t.text "notes"
    t.string "number"
    t.integer "owner_id"
    t.string "owner_type"
    t.boolean "removed", default: false
    t.date "start_on"
    t.text "status_ids"
    t.text "statuses"
    t.text "title"
    t.datetime "updated_at", precision: nil
    t.index ["owner_id", "owner_type"], name: "index_membership_histories_on_owner_id_and_owner_type"
    t.index ["start_on"], name: "index_membership_histories_on_start_on"
  end

  create_table "membership_statuses", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "membership_id"
    t.string "membership_type"
    t.integer "status_id"
    t.string "status_type"
    t.string "title"
    t.datetime "updated_at", precision: nil
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.date "fees_paid_period"
    t.date "fees_paid_through_period"
    t.date "joined_on"
    t.string "number"
    t.integer "number_as_integer"
    t.integer "owner_id"
    t.string "owner_name"
    t.string "owner_type"
    t.date "registration_on"
    t.text "title"
    t.string "token"
    t.datetime "updated_at", precision: nil
    t.index ["number"], name: "index_memberships_on_number"
    t.index ["owner_id", "owner_type"], name: "index_memberships_on_owner_id_and_owner_type", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "order_id"
    t.integer "price"
    t.integer "purchasable_id"
    t.string "purchasable_type"
    t.integer "quantity"
    t.boolean "tax_exempt"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["purchasable_id"], name: "index_order_items_on_purchasable_id"
    t.index ["purchasable_type", "purchasable_id"], name: "index_order_items_on_purchasable_type_and_purchasable_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "amount_owing"
    t.string "billing_first_name"
    t.string "billing_last_name"
    t.string "billing_name"
    t.string "cc"
    t.datetime "created_at", null: false
    t.boolean "delayed_payment", default: false
    t.date "delayed_payment_date"
    t.text "delayed_payment_intent"
    t.datetime "delayed_payment_purchase_ran_at", precision: nil
    t.text "delayed_payment_purchase_result"
    t.integer "delayed_payment_total"
    t.string "email"
    t.text "note"
    t.text "note_internal"
    t.text "note_to_buyer"
    t.integer "organization_id"
    t.string "organization_type"
    t.integer "parent_id"
    t.string "parent_type"
    t.text "payment"
    t.string "payment_card"
    t.string "payment_provider"
    t.datetime "purchased_at", precision: nil
    t.integer "purchased_by_id"
    t.string "purchased_by_type"
    t.string "status"
    t.text "status_steps"
    t.integer "subtotal"
    t.integer "surcharge"
    t.decimal "surcharge_percent", precision: 6, scale: 3
    t.integer "surcharge_tax"
    t.integer "tax"
    t.decimal "tax_rate", precision: 6, scale: 3
    t.integer "total"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "user_type"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.boolean "archived", default: false
    t.string "category"
    t.datetime "created_at", precision: nil
    t.string "email"
    t.string "fax"
    t.text "notes"
    t.string "phone"
    t.integer "representatives_count", default: 0
    t.integer "roles_mask"
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.string "website"
    t.index ["title"], name: "index_organizations_on_title"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "price"
    t.integer "purchased_order_id"
    t.string "qb_item_name"
    t.boolean "tax_exempt", default: false
    t.datetime "updated_at", null: false
  end

  create_table "representatives", force: :cascade do |t|
    t.boolean "boolean", default: false
    t.datetime "created_at", precision: nil
    t.boolean "display_on_directory", default: false
    t.integer "organization_id"
    t.string "organization_type"
    t.integer "roles_mask"
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "user_type"
    t.index ["organization_id", "organization_type"], name: "index_representatives_on_organization_id_and_organization_type"
    t.index ["user_id", "user_type"], name: "index_representatives_on_user_id_and_user_type"
  end

  create_table "statuses", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "position"
    t.string "status"
    t.string "status_type"
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.index ["position"], name: "index_statuses_on_position"
    t.index ["title"], name: "index_statuses_on_title"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "customer_id"
    t.string "description"
    t.string "interval"
    t.string "name"
    t.integer "quantity"
    t.string "status"
    t.string "stripe_plan_id"
    t.string "stripe_subscription_id"
    t.integer "subscribable_id"
    t.string "subscribable_type"
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_subscriptions_on_customer_id"
    t.index ["subscribable_id"], name: "index_subscriptions_on_subscribable_id"
    t.index ["subscribable_type", "subscribable_id"], name: "index_subscriptions_on_subscribable_type_and_subscribable_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at", precision: nil
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "roles_mask"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end

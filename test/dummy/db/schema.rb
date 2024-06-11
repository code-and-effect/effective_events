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

ActiveRecord::Schema.define(version: 101) do

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "addressable_type"
    t.integer "addressable_id"
    t.string "category", limit: 64
    t.string "full_name"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state_code"
    t.string "country_code"
    t.string "postal_code"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["addressable_id"], name: "index_addresses_on_addressable_id"
    t.index ["addressable_type", "addressable_id"], name: "index_addresses_on_addressable_type_and_addressable_id"
  end

  create_table "applicant_course_areas", force: :cascade do |t|
    t.string "title"
    t.integer "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "applicant_course_names", force: :cascade do |t|
    t.integer "applicant_course_area_id"
    t.string "title"
    t.integer "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "applicant_courses", force: :cascade do |t|
    t.integer "applicant_course_area_id"
    t.integer "applicant_course_name_id"
    t.integer "applicant_id"
    t.string "applicant_type"
    t.string "title"
    t.integer "amount"
    t.string "code"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "applicant_educations", force: :cascade do |t|
    t.integer "applicant_id"
    t.string "applicant_type"
    t.date "start_on"
    t.date "end_on"
    t.string "institution"
    t.string "location"
    t.string "degree_obtained"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["applicant_id"], name: "index_applicant_educations_on_applicant_id"
    t.index ["start_on"], name: "index_applicant_educations_on_start_on"
  end

  create_table "applicant_endorsements", force: :cascade do |t|
    t.integer "applicant_id"
    t.string "applicant_type"
    t.integer "endorser_id"
    t.string "endorser_type"
    t.string "title"
    t.boolean "unknown_member", default: false
    t.string "endorser_email"
    t.string "name"
    t.string "phone"
    t.string "status"
    t.text "status_steps"
    t.text "notes"
    t.boolean "accept_declaration"
    t.string "token"
    t.datetime "last_notified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["applicant_id"], name: "index_applicant_endorsements_on_applicant_id"
    t.index ["token"], name: "index_applicant_endorsements_on_token"
  end

  create_table "applicant_equivalences", force: :cascade do |t|
    t.integer "applicant_id"
    t.string "applicant_type"
    t.string "name"
    t.date "start_on"
    t.date "end_on"
    t.text "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["applicant_id"], name: "index_applicant_equivalences_on_applicant_id"
  end

  create_table "applicant_experiences", force: :cascade do |t|
    t.integer "applicant_id"
    t.string "applicant_type"
    t.string "level"
    t.integer "months"
    t.date "start_on"
    t.date "end_on"
    t.string "position"
    t.string "employer"
    t.boolean "still_work_here", default: false
    t.integer "percent_worked"
    t.text "tasks_performed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["applicant_id"], name: "index_applicant_experiences_on_applicant_id"
    t.index ["start_on"], name: "index_applicant_experiences_on_start_on"
  end

  create_table "applicant_references", force: :cascade do |t|
    t.integer "applicant_id"
    t.string "applicant_type"
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "known"
    t.string "relationship"
    t.string "status"
    t.text "status_steps"
    t.string "title"
    t.string "company"
    t.boolean "regulated_professional", default: false
    t.string "regulated_professional_title"
    t.string "regulated_professional_number"
    t.text "work_history"
    t.boolean "reservations"
    t.text "reservations_reason"
    t.string "recommendation"
    t.text "recommendation_reason"
    t.boolean "accept_declaration"
    t.string "token"
    t.datetime "last_notified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["applicant_id"], name: "index_applicant_references_on_applicant_id"
    t.index ["token"], name: "index_applicant_references_on_token"
  end

  create_table "applicant_reviews", force: :cascade do |t|
    t.string "token"
    t.integer "applicant_id"
    t.string "applicant_type"
    t.integer "reviewer_id"
    t.string "reviewer_type"
    t.text "title"
    t.string "status"
    t.text "status_steps"
    t.text "wizard_steps"
    t.datetime "submitted_at"
    t.string "recommendation"
    t.text "comments"
    t.boolean "conflict_of_interest"
    t.boolean "education_accepted"
    t.boolean "course_amounts_accepted"
    t.boolean "courses_accepted"
    t.boolean "experience_accepted"
    t.boolean "references_accepted"
    t.boolean "files_accepted"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "applicants", force: :cascade do |t|
    t.string "applicant_type"
    t.string "stream"
    t.string "token"
    t.text "title"
    t.integer "user_id"
    t.string "user_type"
    t.integer "organization_id"
    t.string "organization_type"
    t.integer "category_id"
    t.string "category_type"
    t.integer "from_category_id"
    t.string "from_category_type"
    t.integer "from_status_id"
    t.string "from_status_type"
    t.string "status"
    t.text "status_steps"
    t.text "wizard_steps"
    t.datetime "submitted_at"
    t.datetime "completed_at"
    t.datetime "reviewed_at"
    t.datetime "approved_at"
    t.datetime "declined_at"
    t.text "declined_reason"
    t.datetime "missing_info_at"
    t.text "missing_info_reason"
    t.text "applicant_educations_details"
    t.integer "applicant_experiences_months"
    t.text "applicant_experiences_details"
    t.date "transcripts_received_on"
    t.string "transcripts_status"
    t.text "transcripts_details"
    t.text "additional_information"
    t.boolean "flagged", default: false
    t.datetime "flagged_at"
    t.text "flagged_reason"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["organization_id", "organization_type"], name: "index_applicants_on_organization_id_and_organization_type"
    t.index ["status"], name: "index_applicants_on_status"
    t.index ["token"], name: "index_applicants_on_token"
    t.index ["user_id", "user_type"], name: "index_applicants_on_user_id_and_user_type"
  end

  create_table "cart_items", force: :cascade do |t|
    t.integer "cart_id"
    t.string "purchasable_type"
    t.integer "purchasable_id"
    t.string "unique"
    t.integer "quantity"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["purchasable_id"], name: "index_cart_items_on_purchasable_id"
    t.index ["purchasable_type", "purchasable_id"], name: "index_cart_items_on_purchasable_type_and_purchasable_id"
  end

  create_table "carts", force: :cascade do |t|
    t.integer "user_id"
    t.string "user_type"
    t.integer "cart_items_count", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "category_type"
    t.string "title"
    t.string "category"
    t.integer "position"
    t.boolean "can_apply_new", default: false
    t.boolean "can_apply_existing", default: false
    t.boolean "can_apply_restricted", default: false
    t.text "can_apply_restricted_ids"
    t.integer "applicant_fee"
    t.integer "applicant_reinstatement_fee"
    t.text "applicant_wizard_steps"
    t.string "applicant_cpd_step_requirement"
    t.integer "min_applicant_educations"
    t.integer "min_applicant_experiences_months"
    t.integer "min_applicant_references"
    t.integer "min_applicant_endorsements"
    t.integer "min_applicant_equivalences"
    t.integer "min_applicant_courses"
    t.integer "min_applicant_files"
    t.integer "min_applicant_reviews"
    t.text "applicant_review_wizard_steps"
    t.integer "prorated_jan"
    t.integer "prorated_feb"
    t.integer "prorated_mar"
    t.integer "prorated_apr"
    t.integer "prorated_may"
    t.integer "prorated_jun"
    t.integer "prorated_jul"
    t.integer "prorated_aug"
    t.integer "prorated_sep"
    t.integer "prorated_oct"
    t.integer "prorated_nov"
    t.integer "prorated_dec"
    t.text "fee_payment_wizard_steps"
    t.string "fee_payment_cpd_step_requirement"
    t.boolean "create_renewal_fees", default: false
    t.integer "renewal_fee"
    t.boolean "create_early_fees", default: false
    t.integer "early_fee"
    t.boolean "create_late_fees", default: false
    t.integer "late_fee"
    t.boolean "create_not_in_good_standing", default: false
    t.string "qb_item_name"
    t.boolean "tax_exempt", default: false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["position"], name: "index_categories_on_position"
    t.index ["title"], name: "index_categories_on_title"
  end

  create_table "customers", force: :cascade do |t|
    t.integer "user_id"
    t.string "user_type"
    t.string "stripe_customer_id"
    t.string "payment_method_id"
    t.string "active_card"
    t.string "status"
    t.integer "subscriptions_count", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.integer "owner_id"
    t.string "owner_type"
    t.string "title"
    t.string "category"
    t.boolean "display_to_owner"
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "template_name"
    t.string "subject"
    t.string "from"
    t.string "bcc"
    t.string "cc"
    t.string "content_type"
    t.text "body"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "event_addons", force: :cascade do |t|
    t.integer "event_id"
    t.integer "event_product_id"
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "event_registration_id"
    t.string "event_registration_type"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.text "notes"
    t.integer "purchased_order_id"
    t.integer "price"
    t.boolean "archived", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "event_notifications", force: :cascade do |t|
    t.bigint "event_id"
    t.string "category"
    t.integer "reminder"
    t.string "from"
    t.string "subject"
    t.text "body"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["event_id"], name: "index_event_notifications_on_event_id"
  end

  create_table "event_products", force: :cascade do |t|
    t.integer "event_id"
    t.string "title"
    t.integer "capacity"
    t.integer "price"
    t.string "qb_item_name"
    t.boolean "tax_exempt", default: false
    t.integer "position"
    t.boolean "archived", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "event_registrants", force: :cascade do |t|
    t.integer "event_id"
    t.integer "event_ticket_id"
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "event_registration_id"
    t.string "event_registration_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "company"
    t.string "number"
    t.text "notes"
    t.boolean "blank_registrant", default: false
    t.boolean "member_registrant", default: false
    t.boolean "waitlisted", default: false
    t.boolean "promoted", default: false
    t.datetime "registered_at"
    t.text "response1"
    t.text "response2"
    t.text "response3"
    t.integer "purchased_order_id"
    t.integer "price"
    t.boolean "archived", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "event_registrations", force: :cascade do |t|
    t.string "token"
    t.integer "event_id"
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "status"
    t.text "status_steps"
    t.text "wizard_steps"
    t.datetime "submitted_at"
    t.datetime "completed_at"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["owner_id", "owner_type"], name: "index_event_registrations_on_owner_id_and_owner_type"
    t.index ["status"], name: "index_event_registrations_on_status"
    t.index ["token"], name: "index_event_registrations_on_token"
  end

  create_table "event_tickets", force: :cascade do |t|
    t.integer "event_id"
    t.string "title"
    t.integer "capacity"
    t.boolean "waitlist", default: false
    t.string "category"
    t.integer "regular_price"
    t.integer "member_price"
    t.integer "early_bird_price"
    t.text "question1"
    t.text "question2"
    t.text "question3"
    t.string "qb_item_name"
    t.boolean "tax_exempt", default: false
    t.integer "position"
    t.boolean "archived", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "events", force: :cascade do |t|
    t.string "title"
    t.string "category"
    t.string "slug"
    t.boolean "draft", default: false
    t.datetime "published_at"
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "registration_start_at"
    t.datetime "registration_end_at"
    t.datetime "early_bird_end_at"
    t.integer "event_registrants_count", default: 0
    t.integer "event_addons_count", default: 0
    t.boolean "external_registration", default: false
    t.string "external_registration_url"
    t.boolean "allow_blank_registrants", default: false
    t.integer "roles_mask"
    t.boolean "authenticate_user", default: false
    t.boolean "delayed_payment", default: false
    t.date "delayed_payment_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["end_at"], name: "index_events_on_end_at"
    t.index ["title"], name: "index_events_on_title"
  end

  create_table "fee_payments", force: :cascade do |t|
    t.string "token"
    t.integer "user_id"
    t.string "user_type"
    t.integer "organization_id"
    t.string "organization_type"
    t.integer "category_id"
    t.string "category_type"
    t.integer "with_status_id"
    t.string "with_status_type"
    t.date "period"
    t.string "status"
    t.text "status_steps"
    t.text "wizard_steps"
    t.datetime "submitted_at"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["organization_id", "organization_type"], name: "index_fee_payments_on_organization_id_and_organization_type"
    t.index ["status"], name: "index_fee_payments_on_status"
    t.index ["token"], name: "index_fee_payments_on_token"
    t.index ["user_id", "user_type"], name: "index_fee_payments_on_user_id_and_user_type"
  end

  create_table "fees", force: :cascade do |t|
    t.integer "category_id"
    t.string "category_type"
    t.integer "from_category_id"
    t.string "from_category_type"
    t.integer "with_status_id"
    t.string "with_status_type"
    t.string "fee_type"
    t.string "checkout_type"
    t.integer "purchased_order_id"
    t.datetime "purchased_at"
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "parent_id"
    t.string "parent_type"
    t.date "period"
    t.date "late_on"
    t.date "not_in_good_standing_on"
    t.string "title"
    t.integer "price"
    t.string "qb_item_name"
    t.boolean "tax_exempt", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["category_id"], name: "index_fees_on_category_id"
    t.index ["fee_type"], name: "index_fees_on_fee_type"
    t.index ["owner_id", "owner_type"], name: "index_fees_on_owner_id_and_owner_type"
    t.index ["parent_id", "parent_type"], name: "index_fees_on_parent_id_and_parent_type"
    t.index ["purchased_order_id"], name: "index_fees_on_purchased_order_id"
  end

  create_table "membership_categories", force: :cascade do |t|
    t.integer "category_id"
    t.string "category_type"
    t.integer "membership_id"
    t.string "membership_type"
    t.string "title"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  create_table "membership_histories", force: :cascade do |t|
    t.integer "owner_id"
    t.string "owner_type"
    t.text "title"
    t.text "categories"
    t.text "category_ids"
    t.text "statuses"
    t.text "status_ids"
    t.date "start_on"
    t.date "end_on"
    t.string "number"
    t.boolean "removed", default: false
    t.text "notes"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["owner_id", "owner_type"], name: "index_membership_histories_on_owner_id_and_owner_type"
    t.index ["start_on"], name: "index_membership_histories_on_start_on"
  end

  create_table "membership_statuses", force: :cascade do |t|
    t.integer "status_id"
    t.string "status_type"
    t.integer "membership_id"
    t.string "membership_type"
    t.string "title"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "owner_id"
    t.string "owner_type"
    t.text "title"
    t.string "number"
    t.integer "number_as_integer"
    t.date "joined_on"
    t.date "registration_on"
    t.date "fees_paid_period"
    t.date "fees_paid_through_period"
    t.string "owner_name"
    t.string "token"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["number"], name: "index_memberships_on_number"
    t.index ["owner_id", "owner_type"], name: "index_memberships_on_owner_id_and_owner_type", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id"
    t.string "purchasable_type"
    t.integer "purchasable_id"
    t.string "name"
    t.integer "quantity"
    t.integer "price"
    t.boolean "tax_exempt"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["purchasable_id"], name: "index_order_items_on_purchasable_id"
    t.index ["purchasable_type", "purchasable_id"], name: "index_order_items_on_purchasable_type_and_purchasable_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "user_id"
    t.string "user_type"
    t.integer "organization_id"
    t.string "organization_type"
    t.integer "parent_id"
    t.string "parent_type"
    t.string "status"
    t.text "status_steps"
    t.datetime "purchased_at"
    t.integer "purchased_by_id"
    t.string "purchased_by_type"
    t.text "note"
    t.text "note_to_buyer"
    t.text "note_internal"
    t.string "billing_name"
    t.string "email"
    t.string "cc"
    t.text "payment"
    t.string "payment_provider"
    t.string "payment_card"
    t.decimal "tax_rate", precision: 6, scale: 3
    t.decimal "surcharge_percent", precision: 6, scale: 3
    t.integer "subtotal"
    t.integer "tax"
    t.integer "amount_owing"
    t.integer "surcharge"
    t.integer "surcharge_tax"
    t.integer "total"
    t.boolean "delayed_payment", default: false
    t.date "delayed_payment_date"
    t.text "delayed_payment_intent"
    t.integer "delayed_payment_total"
    t.datetime "delayed_payment_purchase_ran_at"
    t.text "delayed_payment_purchase_result"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "email"
    t.string "title"
    t.string "phone"
    t.string "fax"
    t.string "website"
    t.string "category"
    t.text "notes"
    t.integer "roles_mask"
    t.boolean "archived", default: false
    t.integer "representatives_count", default: 0
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["title"], name: "index_organizations_on_title"
  end

  create_table "products", force: :cascade do |t|
    t.integer "purchased_order_id"
    t.string "name"
    t.integer "price"
    t.boolean "tax_exempt", default: false
    t.string "qb_item_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "representatives", force: :cascade do |t|
    t.integer "organization_id"
    t.string "organization_type"
    t.string "title"
    t.integer "user_id"
    t.string "user_type"
    t.integer "roles_mask"
    t.boolean "display_on_directory", default: false
    t.boolean "boolean", default: false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["organization_id", "organization_type"], name: "index_representatives_on_organization_id_and_organization_type"
    t.index ["user_id", "user_type"], name: "index_representatives_on_user_id_and_user_type"
  end

  create_table "statuses", force: :cascade do |t|
    t.string "status_type"
    t.string "title"
    t.string "status"
    t.integer "position"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["position"], name: "index_statuses_on_position"
    t.index ["title"], name: "index_statuses_on_title"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "customer_id"
    t.integer "subscribable_id"
    t.string "subscribable_type"
    t.string "stripe_plan_id"
    t.string "stripe_subscription_id"
    t.string "name"
    t.string "description"
    t.string "interval"
    t.integer "quantity"
    t.string "status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["customer_id"], name: "index_subscriptions_on_customer_id"
    t.index ["subscribable_id"], name: "index_subscriptions_on_subscribable_id"
    t.index ["subscribable_type", "subscribable_id"], name: "index_subscriptions_on_subscribable_type_and_subscribable_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "email", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "roles_mask"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end

#!/bin/bash

# Script to organize Supabase migrations into folders

MIGRATIONS_DIR="/Users/muhammadali3000/development/Star_Sitter/starsitters-backend/supabase/migrations"

# Schema migrations (tables, types, enums, helpers)
echo "Moving schema migrations..."
mv "$MIGRATIONS_DIR/20260209100006_marketplace.sql" "$MIGRATIONS_DIR/00_schema/006_marketplace.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100007_time_wages.sql" "$MIGRATIONS_DIR/00_schema/007_time_wages.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100008_chat.sql" "$MIGRATIONS_DIR/00_schema/008_chat.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100009_wallet.sql" "$MIGRATIONS_DIR/00_schema/009_wallet.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100010_notifications.sql" "$MIGRATIONS_DIR/00_schema/010_notifications.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100011_admin_audit.sql" "$MIGRATIONS_DIR/00_schema/011_admin_audit.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100012_helpers.sql" "$MIGRATIONS_DIR/00_schema/012_helpers.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100013_immutability.sql" "$MIGRATIONS_DIR/00_schema/013_immutability.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100014_sitter_aggregates.sql" "$MIGRATIONS_DIR/00_schema/014_sitter_aggregates.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100020_admin_schema.sql" "$MIGRATIONS_DIR/00_schema/015_admin_schema.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260516100000_sitter_emergency_contact.sql" "$MIGRATIONS_DIR/00_schema/016_sitter_emergency_contact.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260516200000_sitter_home_address.sql" "$MIGRATIONS_DIR/00_schema/017_sitter_home_address.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517000200_fix_wage_effective_today.sql" "$MIGRATIONS_DIR/00_schema/018_fix_wage_effective_today.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517000300_course_material_paths_storage.sql" "$MIGRATIONS_DIR/00_schema/019_course_material_paths_storage.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517000700_hardening_indexes.sql" "$MIGRATIONS_DIR/00_schema/020_hardening_indexes.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517000800_clock_out_duration_constraint.sql" "$MIGRATIONS_DIR/00_schema/021_clock_out_duration_constraint.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517001100_profile_preferences_columns.sql" "$MIGRATIONS_DIR/00_schema/022_profile_preferences_columns.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517001200_course_questions_column.sql" "$MIGRATIONS_DIR/00_schema/023_course_questions_column.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517001400_cert_docs_mime_restriction.sql" "$MIGRATIONS_DIR/00_schema/024_cert_docs_mime_restriction.sql" 2>/dev/null

# RLS migrations
echo "Moving RLS migrations..."
mv "$MIGRATIONS_DIR/20260209100015_rls_policies.sql" "$MIGRATIONS_DIR/01_rls/001_rls_policies.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260215131000_fix_admin_users_rls_recursion.sql" "$MIGRATIONS_DIR/01_rls/002_fix_admin_users_rls_recursion.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260215133000_break_jobs_family_profiles_rls_cycle.sql" "$MIGRATIONS_DIR/01_rls/003_break_jobs_family_profiles_rls_cycle.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260516000000_fix_jobs_application_hire_rls_cycle.sql" "$MIGRATIONS_DIR/01_rls/004_fix_jobs_application_hire_rls_cycle.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260512120000_jobs_sitter_application_hire_select.sql" "$MIGRATIONS_DIR/01_rls/005_jobs_sitter_application_hire_select.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100023_admin_table_rls.sql" "$MIGRATIONS_DIR/01_rls/006_admin_table_rls.sql" 2>/dev/null

# Function/RPC migrations
echo "Moving function migrations..."
mv "$MIGRATIONS_DIR/20260209100016_rpcs.sql" "$MIGRATIONS_DIR/02_functions/001_rpcs.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100022_admin_rpcs_extended.sql" "$MIGRATIONS_DIR/02_functions/002_admin_rpcs_extended.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260215132000_is_admin_functions_bypass_rls.sql" "$MIGRATIONS_DIR/02_functions/003_is_admin_functions_bypass_rls.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100024_auth_user_profiles.sql" "$MIGRATIONS_DIR/02_functions/004_auth_user_profiles.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100025_admin_list_jobs.sql" "$MIGRATIONS_DIR/02_functions/005_admin_list_jobs.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517000500_family_direct_hire_rpc.sql" "$MIGRATIONS_DIR/02_functions/006_family_direct_hire_rpc.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517000000_admin_list_jobs_location.sql" "$MIGRATIONS_DIR/02_functions/007_admin_list_jobs_location.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517000100_sitter_submit_review.sql" "$MIGRATIONS_DIR/02_functions/008_sitter_submit_review.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260513100000_cert_document_rpc_courses_seed_rls_tighten.sql" "$MIGRATIONS_DIR/02_functions/009_cert_document_rpc_courses_seed_rls_tighten.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517000600_jobs_required_certifications.sql" "$MIGRATIONS_DIR/02_functions/010_jobs_required_certifications.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517000900_mark_all_notifications_read.sql" "$MIGRATIONS_DIR/02_functions/011_mark_all_notifications_read.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517001000_enforce_geofence_hard_block.sql" "$MIGRATIONS_DIR/02_functions/012_enforce_geofence_hard_block.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517001300_guardian_consent_rate_limit.sql" "$MIGRATIONS_DIR/02_functions/013_guardian_consent_rate_limit.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260522000002_sitter_create_guardian_consent_rpc.sql" "$MIGRATIONS_DIR/02_functions/014_sitter_create_guardian_consent_rpc.sql" 2>/dev/null

# Trigger migrations
echo "Moving trigger migrations..."
mv "$MIGRATIONS_DIR/20260209100017_service_grants.sql" "$MIGRATIONS_DIR/03_triggers/001_service_grants.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100018_realtime_publication.sql" "$MIGRATIONS_DIR/03_triggers/002_realtime_publication.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100019_storage_buckets.sql" "$MIGRATIONS_DIR/03_triggers/003_storage_buckets.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260209100021_job_timeline_trigger.sql" "$MIGRATIONS_DIR/03_triggers/004_job_timeline_trigger.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260210120000_realtime_marketplace.sql" "$MIGRATIONS_DIR/03_triggers/005_realtime_marketplace.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260211140000_admin_week2_notifications_certs.sql" "$MIGRATIONS_DIR/03_triggers/006_admin_week2_notifications_certs.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260211160000_reports_settings_family_cert_rpcs.sql" "$MIGRATIONS_DIR/03_triggers/007_reports_settings_family_cert_rpcs.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260211170000_clock_geofence_family_notification.sql" "$MIGRATIONS_DIR/03_triggers/008_clock_geofence_family_notification.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260215120000_admin_revenue_onboarding_wage_prefs.sql" "$MIGRATIONS_DIR/03_triggers/009_admin_revenue_onboarding_wage_prefs.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260215150000_clock_out_wage_rules_admin_ledger.sql" "$MIGRATIONS_DIR/03_triggers/010_clock_out_wage_rules_admin_ledger.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260514100000_db_webhooks.sql" "$MIGRATIONS_DIR/03_triggers/011_db_webhooks.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260517000400_secure_webhook_secret.sql" "$MIGRATIONS_DIR/03_triggers/012_secure_webhook_secret.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260518000001_fix_webhook_trigger_nonblocking.sql" "$MIGRATIONS_DIR/03_triggers/013_fix_webhook_trigger_nonblocking.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260518000002_fix_auth_trigger_dob.sql" "$MIGRATIONS_DIR/03_triggers/014_fix_auth_trigger_dob.sql" 2>/dev/null

# Seed/data migrations
echo "Moving seed migrations..."
mv "$MIGRATIONS_DIR/20260516300000_seed_test_sitter_accounts.sql" "$MIGRATIONS_DIR/04_seed/001_seed_test_sitter_accounts.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260518000003_admin_bootstrap_signup.sql" "$MIGRATIONS_DIR/04_seed/002_admin_bootstrap_signup.sql" 2>/dev/null
mv "$MIGRATIONS_DIR/20260519000001_claim_sitter_role.sql" "$MIGRATIONS_DIR/04_seed/003_claim_sitter_role.sql" 2>/dev/null

echo "✅ Migration organization complete!"
echo ""
echo "Summary:"
echo "  00_schema/: $(ls -1 /Users/muhammadali3000/development/Star_Sitter/starsitters-backend/supabase/migrations/00_schema/ | wc -l) files"
echo "  01_rls/: $(ls -1 /Users/muhammadali3000/development/Star_Sitter/starsitters-backend/supabase/migrations/01_rls/ | wc -l) files"
echo "  02_functions/: $(ls -1 /Users/muhammadali3000/development/Star_Sitter/starsitters-backend/supabase/migrations/02_functions/ | wc -l) files"
echo "  03_triggers/: $(ls -1 /Users/muhammadali3000/development/Star_Sitter/starsitters-backend/supabase/migrations/03_triggers/ | wc -l) files"
echo "  04_seed/: $(ls -1 /Users/muhammadali3000/development/Star_Sitter/starsitters-backend/supabase/migrations/04_seed/ | wc -l) files"

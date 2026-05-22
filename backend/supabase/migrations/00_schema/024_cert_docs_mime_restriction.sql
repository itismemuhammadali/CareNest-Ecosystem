-- S12 + B6: Restrict cert-docs bucket to safe MIME types and enforce file size limit.
-- Content-Disposition: attachment is enforced via ?download=true on signed URLs (see CertificationsRepository).
update storage.buckets
set
  allowed_mime_types = array['image/jpeg', 'image/png', 'application/pdf'],
  file_size_limit = 10485760  -- 10 MB
where name = 'cert-docs';

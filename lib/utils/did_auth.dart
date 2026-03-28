/// D-ID Studio provides the API key already formatted as `Basic <value>` or
/// as a raw `username:password` string meant to be used directly after "Basic ".
///
/// D-ID docs: paste the key as-is after "Basic " — do NOT re-encode it.
/// The key from Studio is already in the correct format.
String? didBasicAuthorizationHeader(String? rawKey) {
  final raw = rawKey?.trim();
  if (raw == null || raw.isEmpty) return null;
  // Use the key exactly as provided from D-ID Studio — no additional encoding.
  return 'Basic $raw';
}

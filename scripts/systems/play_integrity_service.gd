extends Node
## Play Integrity API hook — STUB (STEP 4 anti-tamper, FINAL HARDENING PASS).
##
## Honest scope, stated once here rather than at every call site: Android's
## Play Integrity API lets a SERVER verify a request genuinely came from an
## unmodified install of this app on a genuine device (not an emulator, a
## repackaged APK, or a rooted device with the save file hand-edited). This
## project has no server — docs/HONEST_ASSESSMENT.md and
## docs/KNOWN_ISSUES.md both already say so — so there is nothing on the
## other end to send a token TO. A client-only "integrity check" that never
## reaches a server proves nothing; this stub does not pretend otherwise.

signal integrity_checked(result: Dictionary)

## Always returns a stub verdict — never a real attestation. A real
## integration replaces the body of this function with a call into the
## Play Integrity SDK plugin's requestIntegrityToken(nonce); everything
## else here (the signal, is_available()) stays the same shape.
func request_integrity_token(nonce: String = "") -> void:
	integrity_checked.emit({
		"verdict": "STUB_NO_SERVER",
		"platform": OS.get_name(),
		"has_real_attestation": false,
		"nonce": nonce,
	})

## False until a real SDK plugin + backend exist. Callers should treat
## "unavailable" as the permanent, honest default for this build, not a
## transient condition to retry.
func is_available() -> bool:
	return false

# Mandatory file picker and import contract

**Status: MANDATORY / RELEASE-BLOCKING.** Applies to **every existing and future app** owned or maintained under `soum91`, on iPhone, iPad, Apple Watch companion flows, macOS, Windows, Android, and other platforms. This is an engineering requirement for Codex, Claude, humans, workflows, and other code assistants. Apps without file import today must apply it to any future picker, browser, import, export or upload feature.

## Incident to prevent

The OS Files picker opens, lists real IPA files, but tapping one does nothing: no selection callback, no import, no error. A picker that opens is **not** a working importer.

## Non-negotiable behavior

1. **Make file selection work end to end.** Tapping a valid file must deliver the picked URL or handle to the app, dismiss the picker, stage the bytes, validate them, and report the result. Never silently ignore a selection.
2. **Use the native platform picker and accepted types correctly.** On iOS, prefer `UIDocumentPickerViewController` or `.fileImporter` configured with tested `UTType` values. Do not depend exclusively on restrictive/dynamic `.ipa` and `.tipa` UTTypes that can leave visible files unselectable. Use broad `.item` where needed, then validate the actual extension and contents. Match platform file provider semantics.
3. **Handle security scope and staged copies correctly.** On selection, acquire security-scoped access where required, coordinate file access when needed, copy to an app-owned staging directory, and only then release scope. Do not use temporary provider URLs after access is released.
4. **Never delete files before asynchronous consumers finish.** Keep the staged file until the importer, signer, unzipper, or installer calls back with success/failure. Do not let `onDisappear`, a sheet dismissal, or parallel UI state invalidate a working import. Do not report success when only a background task was queued.
5. **Avoid presentation conflicts.** Prevent overlapping sheets, inert overlays, stale `isPresented` bindings, double pickers, delegate lifetime loss, and repeated taps while importing. Handle cancellation and allow re-opening.
6. **Handle edge cases.** Test On My iPhone, Downloads, iCloud Drive / cloud providers, spaces, parentheses, Unicode filenames, repeated selection of the same file, a second different file, nonmatching extensions, unavailable cloud files, expired or revoked permissions, and large files.
7. **Make errors actionable.** Show an error if the delegate never reports a valid selection, security-scoped access fails, copying fails, validation rejects the file, or the import fails. Provide usable diagnostic export without exposing credentials.
8. **Preserve a working implementation.** Reuse and test existing known-good picker components rather than replacing them during unrelated UI redesigns. A build that compiles is not proof that the picker works.

## Required test and release gate

- Exercise the real device UI: **open Files → navigate to Downloads → tap a valid IPA → receive callback → stage, inspect/import and show success**.
- Repeat with the same file and a different file; cancel once; try an invalid file; verify errors are visible; check cloud-provider and filename cases.
- Use automated unit/integration tests for type acceptance, URL handling, security scope, asynchronous lifetime, and error reporting **in addition to**, not instead of, a real-device test.
- For watchOS companion workflows, verify the iPhone picker completes *before* signing, provisioning, or Watch transfer; prove the app arrives on both destinations where promised.
- If real-device testing is unavailable, **mark this feature UNVERIFIED and do not claim the bug is fixed**. No release notes saying “picker fixed” without evidence from the end-to-end flow.
- Treat any regression (file displayed but not selectable, tap produces no callback, import silently stalls, staging disappears prematurely) as a **release blocker**.

## Policy propagation

Every existing repository must reference this file from root `AGENTS.md`; new app repositories must include equivalent mandatory instructions in their root `AGENTS.md` (and `CLAUDE.md` if present), plus relevant tests. Do not delete or weaken this contract. Preserve project-specific instructions alongside it.

Canonical source: https://github.com/soum91/tweaks/blob/main/MANDATORY_FILE_PICKER.md

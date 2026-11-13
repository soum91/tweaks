# Changelog

## USBKeys 0.1.6 (7)

- Mirror the signed upstream fix for HID control allocation tokens and IN/OUT completion callbacks, with separate interrupt transfer counters. Source commit: soum91/daybreak@87a9994185d3b83622853c743eba1e153414233c.
- Replace frozen local Daybreak and USBKeys source indexes with their live upstream indexes so the hourly job can discover future versions.
- Target iPhone input remains unverified.

## 2026-11-13

- Created the canonical `soum91/tweaks` Sileo repository.
- Consolidated seven verified rootless package artifacts and their APT indexes.
- Added an hourly verified catalog refresh workflow.

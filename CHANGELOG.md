# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Sprint 69 ending 2017-09-18

### Added
- Created the 'validate' to provider Lenovo [(#76)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/76)

### Fixed
- Fixed the filter of the  event catcher [(#78)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/78)

## Sprint 68 ending 2017-09-04

### Added
- Change device_type from 'ethernet port' to 'physical_port' [(#73)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/73)

## Sprint 67 ending 2017-08-21

### Added
- Add provider support for additional power operations [(#69)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/69)

### Fixed
- Fix refresh PhysicalServer subclass error [(#70)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/70)

## Sprint 66 ending 2017-08-07

### Added
- Discover ip address and name server of the physical infra provider [(#68)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/68)
- Create provider discovery feature. [(#61)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/61)

## Fine-1

### Added
- Change the source name of the Lenovo's provider and add the physical server identify into event hash [(#38)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/38)
- Parse provider and save processor and memory infomation [(#39)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/39)
- Refresh is parsing the follow new properties; health_state, power_state, vendor [(#40)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/40)

### Removed
- The method "name" in physical server class was removed since it was causing inconsistency when trying show a Physical server's name in the UI and in the REST API as well [(#41)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/41)

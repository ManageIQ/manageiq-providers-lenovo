# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Unreleased as of Sprint 72 ending 2017-10-30

### Added
- Add support for applying a config pattern [(#95)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/95)
- Adds console_supported methods to launch LXCA console [(#91)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/91)

## Unreleased as of Sprint 70 ending 2017-10-02

### Added
- Update the uid_ems to the uuid of the endpoint [(#84)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/84)
- Add event_id to the event parser and change the query for refresh event [(#82)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/82)

### Fixed
- Fix the lenovo's event_catcher [(#83)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/83)
- Fix to switch connection type [(#79)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/79)

## Unreleased as of Sprint 69 ending 2017-09-18

### Added
- Created the 'validate' to provider Lenovo [(#76)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/76)

### Fixed
- Fixed the filter of the  event catcher [(#78)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/78)

## Unreleased as of Sprint 68 ending 2017-09-04

### Added
- Change device_type from 'ethernet port' to 'physical_port' [(#73)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/73)

## Unreleased as of Sprint 67 ending 2017-08-21

### Added
- Add provider support for additional power operations [(#69)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/69)

### Fixed
- Fix refresh PhysicalServer subclass error [(#70)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/70)

## Unreleased as of Sprint 66 ending 2017-08-07

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

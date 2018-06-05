# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Unreleased as of Sprint 87 - 2018-06-04

### Fixed
- Fixing authentication status update [(#191)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/191)

## Unreleased as of Sprint 86 - 2018-05-21

### Fixed
- Fixing error while trying to refresh a provider with invalid credentials [(#176)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/176)
- camelize the power state column [(#171)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/171)
- Fix bug when portInfo was null [(#168)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/168)

## Gaprindashvili-3 released 2018-05-15

### Fixed
- Fixing the network devices and ports parser [(#155)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/155)
- searches the hardware resource for a relationship [(#93)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/93)

## Unreleased as of Sprint 84 - 2018-04-23

### Added
- Using firmware parser at storage parser [(#158)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/158)
- Moving strings to dictionary and cleaning up empty and malformatted strings [(#157)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/157)
- Parsing partNumber for Physical Servers [(#156)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/156)
- Parse Physical Chassis [(#149)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/149)
- Parsing pci_device and vlan info to ports [(#142)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/142)
- Adding parsing steps for switches [(#132)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/132)
- Migrate model display names from locale/en.yml to plugin [(#126)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/126)

## Unreleased as of Sprint 83 - 2018-04-09

### Added
- Parsing physical rack [(#147)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/147)

## Unreleased as of Sprint 82 - 2018-03-26

### Added
- Leaving the disk capacity blank if the LXCA doesn't provide this information [(#141)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/141)

## Unreleased as of Sprint 80 - 2018-02-26

### Fixed
- AssetDetails should be AssetDetail [(#125)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/125)

## Gaprindashvili-1 - Released 2018-01-31

### Added
- Update the uid_ems to the uuid of the endpoint [(#84)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/84)
- Add event_id to the event parser and change the query for refresh event [(#82)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/82)
- Created the 'validate' to provider Lenovo [(#76)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/76)
- Change device_type from 'ethernet port' to 'physical_port' [(#73)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/73)
- Add provider support for additional power operations [(#69)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/69)
- Discover ip address and name server of the physical infra provider [(#68)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/68)
- Create provider discovery feature. [(#61)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/61)
- Add support for onboard network devices [(#105)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/105)

### Fixed
- Fix exception handing for credential validation on raw_connect [(#108)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/108)
- Supporting differents identify leds name of physical servers on refresh [(#115)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/115)
- Fix the lenovo's event_catcher [(#83)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/83)
- Fix to switch connection type [(#79)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/79)
- Fixed the filter of the  event catcher [(#78)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/78)
- Fix refresh PhysicalServer subclass error [(#70)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/70)

### Removed
- Remove old Lenovo provider objects [(#112)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/112)
- Removed unnecessary https protocol from hostname URI [(#97)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/97)

## Fine-1

### Added
- Change the source name of the Lenovo's provider and add the physical server identify into event hash [(#38)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/38)
- Parse provider and save processor and memory infomation [(#39)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/39)
- Refresh is parsing the follow new properties; health_state, power_state, vendor [(#40)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/40)

### Removed
- The method "name" in physical server class was removed since it was causing inconsistency when trying show a Physical server's name in the UI and in the REST API as well [(#41)](https://github.com/ManageIQ/manageiq-providers-lenovo/pull/41)

## Initial changelog created

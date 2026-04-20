import React, { useState, useCallback } from "react";
import PropTypes from "prop-types";
import { Grid, Column, ClickableTile } from "@carbon/react";
import { BareMetalServer, Checkmark } from "@carbon/react/icons";
import FirmwareCheckListField from "./firmware_check_list_field.jsx";
import "../../style/firmware-update-field.scss";

const FirmwareField = ({ physicalServerData, name, onChange }) => {
  const [navItemSelected, setNavItemSelected] = useState({});
  const [selectedServerId, setSelectedServerId] = useState(
    physicalServerData?.[0]?.id || null
  );

  const updateNavItem = useCallback((id, firmwareName, checked) => {
    setNavItemSelected((prevNavItemSelected) => {
      const updatedNavItemSelected = { ...prevNavItemSelected };
      const values = updatedNavItemSelected[id] || {};
      values[firmwareName] = checked;
      updatedNavItemSelected[id] = values;

      // Notify parent component of changes if onChange prop is provided
      if (onChange) {
        // Check if any firmware is selected
        const hasSelection = Object.keys(updatedNavItemSelected).some(serverId => {
          const serverFirmwares = updatedNavItemSelected[serverId];
          return Object.values(serverFirmwares).some(isChecked => isChecked);
        });
        
        // Convert navItemSelected to the format expected by the parent
        const firmwareField = {};
        Object.keys(updatedNavItemSelected).forEach(serverId => {
          const selectedFirmwares = [];
          Object.keys(updatedNavItemSelected[serverId]).forEach(firmwareName => {
            if (updatedNavItemSelected[serverId][firmwareName]) {
              selectedFirmwares.push(firmwareName);
            }
          });
          if (selectedFirmwares.length > 0) {
            firmwareField[serverId] = selectedFirmwares;
          }
        });
        
        onChange(firmwareField, hasSelection);
      }

      return updatedNavItemSelected;
    });
  }, [onChange]);

  const hasSelectedFirmware = useCallback((id) => {
    if (navItemSelected.hasOwnProperty(id)) {
      return Object.values(navItemSelected[id]).includes(true);
    }
    return false;
  }, [navItemSelected]);

  const handleServerClick = useCallback((serverId) => {
    setSelectedServerId(serverId);
  }, []);

  if (!physicalServerData?.length) {
    return null;
  }

  const selectedServer = physicalServerData.find(server => server.id === selectedServerId);

  return (
    <div className="firmware-field-container">
      <Grid fullWidth narrow>
        <Column lg={6} md={4} sm={4} className="firmware-servers-column">
          <h4 className="firmware-section-title">{__('Physical Servers')}</h4>
          <div className="firmware-server-list">
            {physicalServerData.map((physicalServer) => {
              const hasSelection = hasSelectedFirmware(physicalServer.id);
              const isSelected = physicalServer.id === selectedServerId;
              return (
                <ClickableTile
                  key={physicalServer.id}
                  className={`firmware-server-tile ${isSelected ? 'selected' : ''}`}
                  onClick={() => handleServerClick(physicalServer.id)}
                >
                  <div className="firmware-server-tile-content">
                    <BareMetalServer />
                    <span className="firmware-server-name">{physicalServer.name}</span>
                    {hasSelection && <Checkmark size={16} className="firmware-checkmark" />}
                  </div>
                </ClickableTile>
              );
            })}
          </div>
        </Column>
        <Column lg={10} md={4} sm={4} className="firmware-details-column">
          {selectedServer && (
            <div className="firmware-details-content">
              <h4 className="firmware-section-title">{selectedServer.name}</h4>
              <FirmwareCheckListField
                updateNavItem={updateNavItem}
                firmwareData={selectedServer.firmwares}
                parentName={name}
                serverID={selectedServer.id}
                selectedFirmwares={navItemSelected[selectedServer.id] || {}}
              />
            </div>
          )}
        </Column>
      </Grid>
    </div>
  );
};

FirmwareField.propTypes = {
  physicalServerData: PropTypes.array.isRequired,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
};

export default FirmwareField;

// Made with Bob

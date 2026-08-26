import React, { useState, useCallback } from "react";
import { Grid, Column, ClickableTile } from "@carbon/react";
import { BareMetalServer, Checkmark } from "@carbon/react/icons";
import FirmwareCheckListField from "./firmware_check_list_field";
import type {
  PhysicalServerDataType,
  FirmwareFieldType,
} from "../common_types";
import "../../style/firmware-update-field.scss";

type NavItemSelectedType = Record<string, Record<string, boolean>>;

type FirmwareFieldProps = {
  physicalServerData: PhysicalServerDataType[];
  name: string;
  onChange?: (value: FirmwareFieldType, isValid: boolean) => void;
};

const FirmwareField: React.FC<FirmwareFieldProps> = ({
  physicalServerData,
  name,
  onChange,
}) => {
  const [navItemSelected, setNavItemSelected] = useState<NavItemSelectedType>(
    {},
  );
  const [selectedServerId, setSelectedServerId] = useState<string | null>(
    physicalServerData?.[0]?.id || null,
  );

  const updateNavItem = useCallback(
    (id: string, firmwareName: string, checked: boolean) => {
      setNavItemSelected((prevNavItemSelected) => {
        const updatedNavItemSelected = { ...prevNavItemSelected };
        const values = updatedNavItemSelected[id] || {};
        values[firmwareName] = checked;
        updatedNavItemSelected[id] = values;

        // Notify parent component of changes if onChange prop is provided
        if (onChange) {
          // Convert navItemSelected to the format expected by the parent
          const firmwareField: FirmwareFieldType = {};
          Object.keys(updatedNavItemSelected).forEach((serverId) => {
            const selectedFirmwares: string[] = [];
            Object.keys(updatedNavItemSelected[serverId]).forEach(
              (firmwareName) => {
                if (updatedNavItemSelected[serverId][firmwareName]) {
                  selectedFirmwares.push(firmwareName);
                }
              },
            );
            if (selectedFirmwares.length > 0) {
              firmwareField[serverId] = selectedFirmwares;
            }
          });
          // Check if any firmware is selected
          const hasSelection = Object.keys(firmwareField).length > 0;

          onChange(firmwareField, hasSelection);
        }

        return updatedNavItemSelected;
      });
    },
    [onChange],
  );

  const hasSelectedFirmware = useCallback(
    (id: string): boolean => {
      if (navItemSelected.hasOwnProperty(id)) {
        return Object.values(navItemSelected[id]).includes(true);
      }
      return false;
    },
    [navItemSelected],
  );

  const handleServerClick = useCallback((serverId: string) => {
    setSelectedServerId(serverId);
  }, []);

  if (!physicalServerData?.length) {
    return null;
  }

  const selectedServer = physicalServerData.find(
    (server) => server.id === selectedServerId,
  );

  return (
    <div className="firmware-field-container">
      <Grid fullWidth narrow>
        <Column lg={6} md={4} sm={4} className="firmware-servers-column">
          <h4 className="firmware-section-title">{__("Physical Servers")}</h4>
          <div className="firmware-server-list">
            {physicalServerData.map((physicalServer) => {
              const hasSelection = hasSelectedFirmware(physicalServer.id);
              const isSelected = physicalServer.id === selectedServerId;
              return (
                <ClickableTile
                  key={physicalServer.id}
                  className={`firmware-server-tile ${isSelected ? "selected" : ""}`}
                  onClick={() => handleServerClick(physicalServer.id)}
                >
                  <div className="firmware-server-tile-content">
                    <BareMetalServer />
                    <span className="firmware-server-name">
                      {physicalServer.name}
                    </span>
                    {hasSelection && (
                      <Checkmark size={16} className="firmware-checkmark" />
                    )}
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

export default FirmwareField;

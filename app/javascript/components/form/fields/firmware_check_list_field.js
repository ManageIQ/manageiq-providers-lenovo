import React from "react";
import PropTypes from "prop-types";
import { Checkbox, FormGroup } from "@carbon/react";

const FirmwareCheckListField = ({ firmwareData, parentName, updateNavItem, serverID, selectedFirmwares }) => {
  const handleChange = (event, firmwareName) => {
    updateNavItem(serverID, firmwareName, event.target.checked);
  };

  return (
    <FormGroup legendText={__('Firmwares')}>
      {firmwareData.map((firmware) => {
        const isChecked = selectedFirmwares && selectedFirmwares[firmware.name] === true;
        return (
          <Checkbox
            key={firmware.name}
            id={`${parentName}-${serverID}-${firmware.name}`}
            labelText={firmware.name}
            checked={isChecked}
            onChange={(event) => handleChange(event, firmware.name)}
          />
        );
      })}
    </FormGroup>
  );
};

FirmwareCheckListField.propTypes = {
  firmwareData: PropTypes.array.isRequired,
  parentName: PropTypes.string.isRequired,
  updateNavItem: PropTypes.func.isRequired,
  serverID: PropTypes.string.isRequired,
  selectedFirmwares: PropTypes.object,
};

export default FirmwareCheckListField;

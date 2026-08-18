import React from "react";
import { Checkbox, FormGroup } from "@carbon/react";
import type { FirmwareType } from "../common_types";

type FirmwareCheckListFieldProps = {
  firmwareData: FirmwareType[];
  parentName: string;
  updateNavItem: (
    serverID: string,
    firmwareName: string,
    checked: boolean,
  ) => void;
  serverID: string;
  selectedFirmwares?: Record<string, boolean>;
};

const FirmwareCheckListField: React.FC<FirmwareCheckListFieldProps> = ({
  firmwareData,
  parentName,
  updateNavItem,
  serverID,
  selectedFirmwares,
}) => {
  const handleChange = (
    event: React.ChangeEvent<HTMLInputElement>,
    firmwareName: string,
  ) => {
    updateNavItem(serverID, firmwareName, event.target.checked);
  };

  return (
    <FormGroup legendText={__("Firmwares")}>
      {firmwareData.map((firmware) => {
        const isChecked = selectedFirmwares?.[firmware?.name] || false;
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

export default FirmwareCheckListField;

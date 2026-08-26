import React, { useState, useMemo } from "react";
import { MultiSelect } from "@carbon/react";
import type { OptionType } from "../common_types";

type MultiSelectItemType = {
  id: string;
  label: string;
  value: string;
};

type MultiSelectChangeDataType = {
  selectedItems: MultiSelectItemType[];
};

type PhysicalServerFieldProps = {
  physicalServerData: OptionType[];
  disabled: boolean;
  onChange?: (value: string[], isValid: boolean) => void;
};

const PhysicalServerField: React.FC<PhysicalServerFieldProps> = ({
  physicalServerData,
  disabled,
  onChange,
}) => {
  const [touched, setTouched] = useState(false);
  const [pristine, setPristine] = useState(true);
  const [valid, setValid] = useState(false);
  const [selectedItems, setSelectedItems] = useState<MultiSelectItemType[]>([]);

  const getValidationState = () => {
    if (valid) {
      return true;
    } else if (touched && pristine) {
      return false;
    } else if (!pristine && !valid) {
      return false;
    }
    return true;
  };

  const handleChange = (data: MultiSelectChangeDataType) => {
    const selectedValues = data?.selectedItems?.map((item) => item.id);
    const isValid = selectedValues.length > 0;

    setValid(isValid);
    setPristine(false);
    setSelectedItems(data.selectedItems);

    // Call parent onChange if provided
    if (onChange) {
      onChange(selectedValues, isValid);
    }
  };

  const handleClick = () => {
    setTouched(true);
  };

  const serverItems = useMemo(() => {
    return physicalServerData.map((server) => ({
      id: server.value,
      label: server.label,
      value: server.value,
    }));
  }, [physicalServerData]);

  return (
    <div onClick={handleClick}>
      <MultiSelect
        id="selectServer"
        titleText={__("Physical Server")}
        label={__("Choose a Server")}
        items={serverItems}
        itemToString={(item) => (item ? item.label : "")}
        disabled={disabled}
        onChange={handleChange}
        initialSelectedItems={selectedItems}
        invalid={!getValidationState()}
        invalidText={__("Please select at least one server")}
      />
    </div>
  );
};

export default PhysicalServerField;

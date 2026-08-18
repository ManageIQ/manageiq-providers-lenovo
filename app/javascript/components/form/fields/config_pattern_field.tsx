import React, { useState } from "react";
import { Select, SelectItem } from "@carbon/react";
import type { OptionType } from "../common_types";

type ConfigPatternFieldProps = {
  configPatternData: OptionType[];
  name: string;
  onChange?: (value: string, isValid: boolean) => void;
  updateChildren?: (value: string) => void;
};

const ConfigPatternField: React.FC<ConfigPatternFieldProps> = ({
  configPatternData,
  name,
  onChange,
  updateChildren,
}) => {
  const [touched, setTouched] = useState(false);
  const [value, setValue] = useState("");
  const [valid, setValid] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const newValue = e.target.value;
    const isValid = newValue !== "placeholder-item" && newValue !== "";

    setValue(newValue);
    setValid(isValid);

    // Always call updateChildren to refresh the server list, passing the value
    if (updateChildren) {
      updateChildren(newValue);
    }

    // Call parent onChange if provided
    if (onChange) {
      onChange(newValue, isValid);
    }
  };

  const handleClick = () => {
    setTouched(true);
  };

  const patternComponentOptions = configPatternData.map((pattern) => {
    return (
      <SelectItem
        key={pattern.value as string}
        value={pattern.value as string}
        text={pattern.label}
      />
    );
  });

  return (
    <Select
      id="selectPattern"
      labelText={__("Config Pattern")}
      name={name}
      value={value}
      onChange={handleChange}
      onClick={handleClick}
      invalid={touched && !valid}
      invalidText={__("Please select a pattern")}
    >
      <SelectItem value="placeholder-item" text={__("Choose a pattern")} />
      {patternComponentOptions}
    </Select>
  );
};

export default ConfigPatternField;

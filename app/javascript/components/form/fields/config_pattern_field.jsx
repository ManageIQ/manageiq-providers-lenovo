import React, { useState } from "react";
import PropTypes from "prop-types";
import { Select, SelectItem } from "@carbon/react";

const ConfigPatternField = ({ configPatternData, name, onChange, updateChildren }) => {
  const [touched, setTouched] = useState(false);
  const [value, setValue] = useState("");
  const [valid, setValid] = useState(false);

  const handleChange = (e) => {
    const newValue = e.target.value;
    const isValid = newValue !== 'placeholder-item' && newValue !== '';
    
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
    return <SelectItem key={pattern.value} value={pattern.value} text={pattern.label} />
  });

  return (
    <Select
      id="selectPattern"
      labelText={__('Config Pattern')}
      name={name}
      value={value}
      onChange={handleChange}
      onClick={handleClick}
      invalid={touched && !valid}
      invalidText={__('Please select a pattern')}>
      <SelectItem value="placeholder-item" text={__('Choose a pattern')} />
      {patternComponentOptions}
    </Select>
  );
};

ConfigPatternField.propTypes = {
  configPatternData: PropTypes.array.isRequired,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  updateChildren: PropTypes.func,
};

export default ConfigPatternField;

import React, { useState, useMemo } from "react";
import PropTypes from "prop-types";
import { MultiSelect } from "@carbon/react";

const PhysicalServerField = ({ physicalServerData, name, disabled, onChange }) => {
  const [touched, setTouched] = useState(false);
  const [pristine, setPristine] = useState(true);
  const [valid, setValid] = useState(false);
  const [selectedItems, setSelectedItems] = useState([]);

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

  const handleChange = (data) => {
    const selectedValues = data.selectedItems.map(item => item.id);
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
        titleText={__('Physical Server')}
        label={__('Choose a Server')}
        items={serverItems}
        itemToString={(item) => (item ? item.label : '')}
        disabled={disabled}
        onChange={handleChange}
        initialSelectedItems={selectedItems}
        invalid={!getValidationState()}
        invalidText={__('Please select at least one server')}
      />
    </div>
  );
};

PhysicalServerField.propTypes = {
  physicalServerData: PropTypes.array.isRequired,
  name: PropTypes.string.isRequired,
  disabled: PropTypes.bool.isRequired,
  onChange: PropTypes.func,
};

export default PhysicalServerField;

import React from "react";
import PropTypes from "prop-types";
import { MultiSelect } from "@carbon/react";

class PhysicalServerField extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      touched: false,
      pristine: true,
      valid: false,
      selectedItems: []
    };

    this.handleChange = this.handleChange.bind(this);
  }

  getValidationState() {
    let {valid, pristine, touched} = this.state;
    if (valid) {
      return true;
    } else if (touched && pristine) {
      return false;
    } else if (!pristine && !valid) {
      return false;
    }
    return true;
  }

  handleChange = (data) => {
    const selectedValues = data.selectedItems.map(item => item.id);
    const isValid = selectedValues.length > 0;
    
    this.setState({
      valid: isValid,
      pristine: false,
      selectedItems: data.selectedItems
    });

    // Call parent onChange if provided
    if (this.props.onChange) {
      this.props.onChange(selectedValues, isValid);
    }
  };

  onClick = () => {
    this.setState({touched: true})
  };

  render() {
    const serverItems = this.props.physicalServerData.map((server) => ({
      id: server.value,
      label: server.label,
      value: server.value,
    }));

    return (
      <div onClick={this.onClick}>
        <MultiSelect
          id="selectServer"
          titleText={__('Physical Server')}
          label={__('Choose a Server')}
          items={serverItems}
          itemToString={(item) => (item ? item.label : '')}
          disabled={this.props.disabled}
          onChange={this.handleChange}
          initialSelectedItems={this.state.selectedItems}
          invalid={!this.getValidationState()}
          invalidText={__('Please select at least one server')}
        />
      </div>
    );
  }
}

PhysicalServerField.propTypes = {
  physicalServerData: PropTypes.array.isRequired,
  name: PropTypes.string.isRequired,
  disabled: PropTypes.bool.isRequired,
  onChange: PropTypes.func,
};

export default PhysicalServerField;

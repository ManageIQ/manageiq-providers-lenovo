import React from "react";
import PropTypes from "prop-types";
import { Select, SelectItem } from "@carbon/react";

class ConfigPatternField extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      touched: false,
      value: "",
      valid: false
    };

    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(e) {
    let value = e.target.value;
    const isValid = value !== 'placeholder-item' && value !== '';
    
    this.setState({
      value: value,
      valid: isValid
    });

    // Always call updateChildren to refresh the server list, passing the value
    if (this.props.updateChildren) {
      this.props.updateChildren(value);
    }

    // Call parent onChange if provided
    if (this.props.onChange) {
      this.props.onChange(value, isValid);
    }
  }

  onClick = () => {
    this.setState({touched: true})
  };

  render() {
    const patternComponentOptions = this.props.configPatternData.map((pattern) => {
      return <SelectItem key={pattern.value} value={pattern.value} text={pattern.label} />
    });

    return (
      <Select
        id="selectPattern"
        labelText={__('Config Pattern')}
        name={this.props.name}
        value={this.state.value}
        onChange={this.handleChange}
        onClick={this.onClick}
        invalid={this.state.touched && !this.state.valid}
        invalidText={__('Please select a pattern')}>
        <SelectItem value="placeholder-item" text={__('Choose a pattern')} />
        { patternComponentOptions }
      </Select>
    );
  }
}

ConfigPatternField.propTypes = {
  configPatternData: PropTypes.array.isRequired,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  updateChildren: PropTypes.func,
};

export default ConfigPatternField;

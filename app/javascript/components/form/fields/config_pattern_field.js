import React from "react";
import PropTypes from "prop-types";
import {ControlLabel, FormControl, FormGroup} from "react-bootstrap";

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

  getValidationState() {
    let {valid, touched} = this.state;
    if (valid) {
      return "success";
    }else if (touched) {
      return "warning";
    }
   }

  handleChange(e) {
    let value = e.target.value;
    if (!! this.props.updateChildren) {
      this.props.updateChildren(value);
    }

    this.setState({
      value: value,
      valid: e.target.validity.valid
    });
  }

  onClick = () => {
    this.setState({touched: true})
  };

  componentDidMount() {
    $(".selectpicker").selectpicker();
  }

  render() {
    const patternComponentOptions = this.props.configPatternData.map((pattern) => {
      return <option key={pattern.value} value={pattern.value}>{pattern.label}</option>
    });

    return (
      <FormGroup
        controlId="selectPattern"
        validationState={this.getValidationState()}>
          <ControlLabel>{__('Config Pattern')}</ControlLabel>
          <div onClick={this.onClick}>
            <FormControl
              componentClass="select"
              className="selectpicker"
              name={this.props.name}
              value={this.state.value}
              title={__('Choose a pattern')}
              onChange={this.handleChange}>
              { patternComponentOptions }
            </FormControl>
          </div>
      </FormGroup>
    );
  }
}

ConfigPatternField.propTypes = {
  configPatternData: PropTypes.array.isRequired,
  name: PropTypes.string.isRequired,
};

export default ConfigPatternField;

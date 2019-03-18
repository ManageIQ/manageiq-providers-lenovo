import React from "react";
import PropTypes from "prop-types";
import {ControlLabel, FormControl, FormGroup} from "react-bootstrap";

class PhysicalServerField extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      touched: false,
      pristine: true,
      valid: false
    };

    this.handleChange = this.handleChange.bind(this);
  }

  getValidationState() {
    let {valid, pristine, touched} = this.state;
    if (valid) {
      return "success";
    }else if (touched && pristine) {
      return "warning";
    }else if (!pristine && !valid){
      return "error";
    }
  }

  handleChange(e) {
    const selectedOptions = $(e.target).val();
    this.setState({
      valid: !!selectedOptions,
      pristine: false
    });
  }

  onClick = () => {
    this.setState({touched: true})
  };

  componentDidMount() {
    $(".selectpicker").selectpicker();
  }

  componentDidUpdate() {
    $(".selectpicker").selectpicker("refresh");
  }

  render() {
    const serverComponentOptions = this.props.physicalServerData.map((server) => {
      return <option data-icon="pficon pficon-server" key={server.value} value={server.value}>{server.label}</option>;
    });

    return (
      <FormGroup
        controlId="selectServer"
        validationState={this.getValidationState()}>
          <ControlLabel>{__('Physical Server')}</ControlLabel>
          <div onClick={this.onClick}>
            <FormControl
              disabled={this.props.disabled}
              componentClass="select"
              className="selectpicker"
              name={this.props.name}
              multiple
              data-live-search="true"
              data-selected-text-format="count"
              data-actions-box="true"
              title={__('Choose a Server')}
              onChange={this.handleChange}>
              { serverComponentOptions }
            </FormControl>
          </div>
      </FormGroup>
    );
  }
}

PhysicalServerField.propTypes = {
  physicalServerData: PropTypes.array.isRequired,
  name: PropTypes.string.isRequired,
  disabled: PropTypes.bool.isRequired,
};

export default PhysicalServerField;

import React from "react";
import PropTypes from "prop-types";
import {Checkbox, ControlLabel, FormGroup} from "react-bootstrap";

class FirmwareCheckListField extends React.Component {

  constructor(props) {
    super(props);
    this.state = {};

    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(event) {
    const target = event.target;
    this.props.updateNavItem(target.value, target.labels[0].textContent, target.checked)
  }

  render() {
    const firmwareCheckList = this.props.firmwareData.map((firmware) => {
      return(
        <Checkbox
          key={firmware.name}
          value={this.props.serverID}
          onChange={this.handleChange}
          name={this.props.parentName}>
          {firmware.name}
        </Checkbox>
      )
    });

    return (
      <FormGroup>
        <ControlLabel>{__('Firmwares')}</ControlLabel>
        {firmwareCheckList}
      </FormGroup>
    );
  }
}

FirmwareCheckListField.propTypes = {
  firmwareData: PropTypes.array.isRequired,
  parentName: PropTypes.string.isRequired,
  updateNavItem: PropTypes.func.isRequired,
  serverID: PropTypes.string.isRequired,
};

export default FirmwareCheckListField;

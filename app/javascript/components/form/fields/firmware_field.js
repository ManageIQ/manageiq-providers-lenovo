import React from "react";
import PropTypes from "prop-types";
import {
  Col,
  ControlLabel,
  Nav,
  NavItem,
  Row,
  Tab,
} from "react-bootstrap";
import FirmwareCheckListField from "./firmware_check_list_field";
import "../../style/firmware-update-field.css";

class FirmwareField extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      navItemSelected: {},
    };

  }

  updateNavItem = (id, firmwareName, checked) => {
    let navItemSelected= this.state.navItemSelected;
    let values = navItemSelected[id] || {};
    values[firmwareName] = checked;
    navItemSelected[id] = values;
    this.setState({navItemSelected})
  };

  hideNavItem = (id) => {
    let navItemSelected= this.state.navItemSelected;
    if (navItemSelected.hasOwnProperty(id)) {
      return !Object.values(navItemSelected[id]).includes(true);
    }
    return true;
  };


  render() {
    const serverNavItens = this.props.physicalServerData.map((physicalServer) => {
      const visibility = this.hideNavItem(physicalServer.id) ? "invisible" : "visible";
      return(
        <NavItem
          eventKey={physicalServer.id}
          key={physicalServer.id}>
          <div className="media">
            <div className="media-left">
              <i className="pficon pficon-server serverIcon"/>
              {physicalServer.name}
            </div>
            <div className="media-right">
              <i className={"fa fa-check " + visibility}/>
            </div>

          </div>
        </NavItem>
      )
    });
    const firmwareTabPane = this.props.physicalServerData.map((physicalServer) => {
      return(
        <Tab.Pane
          key={physicalServer.id}
          eventKey={physicalServer.id}>
          <h4>{physicalServer.name}</h4>
          <FirmwareCheckListField
            updateNavItem={this.updateNavItem}
            firmwareData={physicalServer.firmwares}
            parentName={this.props.name}
            serverID={physicalServer.id}/>
        </Tab.Pane>
      )
    });

    return (
      <div>
        <Tab.Container id="left-tabs-firmware" defaultActiveKey={this.props.physicalServerData[0].id}>
          <Row className="clearfix tabRow">
            <Col sm={4} className="serversCol">
              <ControlLabel>{__('Physical Servers')}</ControlLabel>
              <Nav bsStyle="pills" stacked>
                {serverNavItens}
              </Nav>
            </Col>
            <Col sm={8} className="firmwaresCol">
              <Tab.Content animation>
                {firmwareTabPane}
              </Tab.Content>
            </Col>
          </Row>
        </Tab.Container>
      </div>
    );
  }
}

FirmwareField.propTypes = {
  physicalServerData: PropTypes.array.isRequired,
  name: PropTypes.string.isRequired,
};

export default FirmwareField;

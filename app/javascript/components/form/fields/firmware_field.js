import React from "react";
import PropTypes from "prop-types";
import { Grid, Column, ClickableTile } from "@carbon/react";
import { BareMetalServer, Checkmark } from "@carbon/react/icons";
import FirmwareCheckListField from "./firmware_check_list_field.js";
import "../../style/firmware-update-field.scss";

class FirmwareField extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      navItemSelected: {},
      selectedServerId: props.physicalServerData?.[0]?.id || null,
    };

  }

  updateNavItem = (id, firmwareName, checked) => {
    let navItemSelected= this.state.navItemSelected;
    let values = navItemSelected[id] || {};
    values[firmwareName] = checked;
    navItemSelected[id] = values;
    this.setState({navItemSelected}, () => {
      // Notify parent component of changes if onChange prop is provided
      if (this.props.onChange) {
        // Check if any firmware is selected
        const hasSelection = Object.keys(navItemSelected).some(serverId => {
          const serverFirmwares = navItemSelected[serverId];
          return Object.values(serverFirmwares).some(isChecked => isChecked);
        });
        
        // Convert navItemSelected to the format expected by the parent
        const firmwareField = {};
        Object.keys(navItemSelected).forEach(serverId => {
          const selectedFirmwares = [];
          Object.keys(navItemSelected[serverId]).forEach(firmwareName => {
            if (navItemSelected[serverId][firmwareName]) {
              selectedFirmwares.push(firmwareName);
            }
          });
          if (selectedFirmwares.length > 0) {
            firmwareField[serverId] = selectedFirmwares;
          }
        });
        
        this.props.onChange(firmwareField, hasSelection);
      }
    });
  };

  hasSelectedFirmware = (id) => {
    let navItemSelected= this.state.navItemSelected;
    if (navItemSelected.hasOwnProperty(id)) {
      return Object.values(navItemSelected[id]).includes(true);
    }
    return false;
  };

  handleServerClick = (serverId) => {
    this.setState({ selectedServerId: serverId });
  };

  render() {
    const { physicalServerData } = this.props;
    const { selectedServerId } = this.state;

    if (!physicalServerData?.length === 0) {
      return null;
    }

    const selectedServer = physicalServerData.find(server => server.id === selectedServerId);

    return (
      <div className="firmware-field-container">
        <Grid fullWidth narrow>
          <Column lg={6} md={4} sm={4} className="firmware-servers-column">
            <h4 className="firmware-section-title">{__('Physical Servers')}</h4>
            <div className="firmware-server-list">
              {physicalServerData.map((physicalServer) => {
                const hasSelection = this.hasSelectedFirmware(physicalServer.id);
                const isSelected = physicalServer.id === selectedServerId;
                return (
                  <ClickableTile
                    key={physicalServer.id}
                    className={`firmware-server-tile ${isSelected ? 'selected' : ''}`}
                    onClick={() => this.handleServerClick(physicalServer.id)}
                  >
                    <div className="firmware-server-tile-content">
                      <BareMetalServer />
                      <span className="firmware-server-name">{physicalServer.name}</span>
                      {hasSelection && <Checkmark size={16} className="firmware-checkmark" />}
                    </div>
                  </ClickableTile>
                );
              })}
            </div>
          </Column>
          <Column lg={10} md={4} sm={4} className="firmware-details-column">
            {selectedServer && (
              <div className="firmware-details-content">
                <h4 className="firmware-section-title">{selectedServer.name}</h4>
                <FirmwareCheckListField
                  updateNavItem={this.updateNavItem}
                  firmwareData={selectedServer.firmwares}
                  parentName={this.props.name}
                  serverID={selectedServer.id}
                  selectedFirmwares={this.state.navItemSelected[selectedServer.id] || {}}
                />
              </div>
            )}
          </Column>
        </Grid>
      </div>
    );
  }
}

FirmwareField.propTypes = {
  physicalServerData: PropTypes.array.isRequired,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
};

export default FirmwareField;

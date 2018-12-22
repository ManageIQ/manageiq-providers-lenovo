import React from "react";
import PropTypes from "prop-types";
import {connect} from "react-redux";
import URI from "urijs";
import LenovoForm from "./form/lenovo_form";
import FirmwareField from "./form/fields/firmware_field";


const API = window.API;

const applyFirmwareUpdate = (values) =>{

  const firmwareField = values['firmwareField'];

  const resources = Object.keys(firmwareField).map(id => ({
    href: `${window.location.origin}/api/physical_servers/${id}`,
    firmware_names: firmwareField[id]
  }));

  API.post("/api/physical_servers/", {
    action: "apply_firmware_update_ansible",
    resources: resources,
   });
};

const getPhysicalServerData = (providerID) => {
  const uri = new URI("/api/physical_servers/?")
    .query({
      "attributes": "id,name,hardware.firmwares",
      "expand": "resources",
      "filter[]": `ems_id=${providerID}`
    });
  return API.get(uri).then((data) => data.resources.map(resource => ({
    id: resource.id,
    name: resource.name,
    firmwares: resource.hardware.firmwares,
  })));
};

class FirmwareUpdateFormProvider extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      physicalServerList: [],
      values: {},
      fieldsDataLoading: {
        physicalServerLoading: true,
      },
    };
  }

  updateFieldsDataLoading = (name, status) => {
    const fieldsDataLoading= this.state.fieldsDataLoading;
    fieldsDataLoading[name]=status;
    return fieldsDataLoading;
  };

  updateValues = (values) => {
    this.setState({values});
  };

  componentDidMount() {
    this.props.dispatch({
      type: "FormButtons.init",
      payload: {
        newRecord: true,
        pristine: true,
        addClicked: () => {
          applyFirmwareUpdate(this.state.values);
        },
      },
    });
    this.props.dispatch({
      type: "FormButtons.customLabel",
      payload: "Apply",
    });
    getPhysicalServerData(ManageIQ.record.recordId).then((physicalServerList) => {
      this.setState(
        {physicalServerList,
         fieldsDataLoading: this.updateFieldsDataLoading("physicalServerLoading", false),
        });
    });
  }

  render() {
    return (
      <LenovoForm
        fieldsDataLoading={this.state.fieldsDataLoading}
        handleValues={this.updateValues}
        dispatch={this.props.dispatch}>
        <FirmwareField
          name="firmwareField"
          validate={true}
          physicalServerData={this.state.physicalServerList}/>
      </LenovoForm>
    )
  }
}

FirmwareUpdateFormProvider.propTypes = {
  dispatch: PropTypes.func.isRequired,
};

export default connect()(FirmwareUpdateFormProvider);

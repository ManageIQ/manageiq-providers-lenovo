import React from "react";
import PropTypes from "prop-types";
import {connect} from "react-redux";
import LenovoForm from "./form/lenovo_form";
import PhysicalServerField from "./form/fields/physical_server_field";
import ConfigPatternField from "./form/fields/config_pattern_field";

const API = window.API;

const applyPattern = (values) =>{
  const resources = values["physicalServerField"].map(href => (
    {
      href: href,
      pattern_id: values["configPatternField"]
    }));
  API.post("/api/physical_servers/", {
    action: "apply_config_pattern_ansible",
    resources: resources,
   });
};

const getPhysicalServerData = (providerID, patternID) => {
  const uri = `/api/physical_servers?attributes=name,href&expand=resources&filter[]=ems_id=${providerID}`;
  return API.get(uri).then((data) => data.resources.map(resource => ({
    value: resource.href,
    label: resource.name,
  })));
};

const getConfigPatternData = (providerID) => {
  const uri = `/api/customization_scripts?attributes=manager_ref,name&expand=resources&filter[]=type='ManageIQ::Providers::Lenovo::PhysicalInfraManager::ConfigPattern'&filter[]=manager_id=${providerID}`;
  return API.get(uri).then((data) => data.resources.map(resource => ({
    value: resource.manager_ref,
    label: resource.name,
  })));
};

class ApplyConfigPatternFormProvider extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      configPatternList: [],
      physicalServerList: [],
      physicalServerFieldDisabled: true,
      values: {},
      fieldsDataLoading: {
        configPatternLoading: true,
      },
    };
  }

  updateFieldsDataLoading = (name, status) => {
    const fieldsDataLoading= this.state.fieldsDataLoading;
    fieldsDataLoading[name]=status;
    return fieldsDataLoading;
  };

  componentDidMount() {
    this.props.dispatch({
      type: "FormButtons.init",
      payload: {
        newRecord: true,
        pristine: true,
        addClicked: () => {
          applyPattern(this.state.values);
        },
      },
    });
    this.props.dispatch({
      type: "FormButtons.customLabel",
      payload: "Apply",
    });
    getConfigPatternData(ManageIQ.record.recordId)
      .then((configPatternList) => this.setState(
        {
          configPatternList: configPatternList,
          fieldsDataLoading: this.updateFieldsDataLoading("configPatternLoading", false),
        }
      ));
  };

  updateValues = (values) => {
    this.setState({values});
  };

  updateServers = (resourceID) => {
    getPhysicalServerData(ManageIQ.record.recordId, resourceID)
      .then(physicalServerList => this.setState({ physicalServerList: physicalServerList, physicalServerFieldDisabled: false }));
  };

  render() {
    return (
      <LenovoForm
        fieldsDataLoading={this.state.fieldsDataLoading}
        handleValues={this.updateValues}
        dispatch={this.props.dispatch}>
        <ConfigPatternField
          name="configPatternField"
          validate={true}
          updateChildren={this.updateServers}
          configPatternData={this.state.configPatternList}/>
        <PhysicalServerField
          validate={true}
          name="physicalServerField"
          physicalServerData={this.state.physicalServerList}
          disabled={this.state.physicalServerFieldDisabled}/>
      </LenovoForm>
    )
  }
}

ApplyConfigPatternFormProvider.propTypes = {
  dispatch: PropTypes.func.isRequired,
};

export default connect()(ApplyConfigPatternFormProvider);
